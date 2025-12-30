local SOUND_CUSTOM_STAR_ENV = audio_sample_load("star_twinkle.mp3")
local STAR_SOUND_DURATION = math.floor(1.2 * 30)
local sSoundTimer = 0

local sCurSkyboxColor = {0xFF, 0xFF, 0xFF}
sDefaultAmbientColor = {r = 0xFF, g = 0xFF, b = 0xFF}
gWaitedForLightsOnOtherMods = false
local sLightIntensities = {}

local ambient_color_is_default = function()
    if (sDefaultAmbientColor.r == 0x7F and sDefaultAmbientColor.g == 0x7F and sDefaultAmbientColor.b == 0x7F) then
        return true
    end
    return false
end

local handle_star_env_effects = function()
    local m = gMarioStates[0]
    local soundSetting = gSGOLocalSettings.twinklyStars

    if not gWaitedForLightsOnOtherMods then
        gWaitedForLightsOnOtherMods = true
    else
        if ambient_color_is_default() then
            le_set_ambient_color(0xFF, 0xFF, 0xFF)
        end
    end

    if gLightDarken < 1 then
        for i = 0, 2 do
            set_skybox_color(i, sCurSkyboxColor[i + 1] * gLightDarken)
        end

        le_set_ambient_color(sDefaultAmbientColor.r * gLightDarken, sDefaultAmbientColor.g * gLightDarken, sDefaultAmbientColor.b * gLightDarken)

        for i = 0, LE_MAX_LIGHTS do
            if (not gSpotlightLightID or i ~= gSpotlightLightID) and (not gNearestStar or i ~= gNearestStar.oLightID) and le_light_exists(i) and sLightIntensities[i] then
                le_set_light_intensity(i, sLightIntensities[i] * gLightDarken)
            end
        end
    elseif gLightDarken ~= 2 then
        for i = 0, 2 do
            set_skybox_color(i, sCurSkyboxColor[i + 1])
        end

        le_set_ambient_color(sDefaultAmbientColor.r, sDefaultAmbientColor.g, sDefaultAmbientColor.b)

        for i = 0, LE_MAX_LIGHTS do
            if (not gSpotlightLightID or i ~= gSpotlightLightID) and (not gNearestStar or i ~= gNearestStar.oLightID) and le_light_exists(i) and sLightIntensities[i] then
                le_set_light_intensity(i, sLightIntensities[i])
            end
        end

        if m.health > 0xFF and gDeathActs[m.action] == nil then
            gLightDarken = 2
        end
    else
        for i = 0, 2 do
            sCurSkyboxColor[i - 1] = get_skybox_color(i)
        end

        le_get_ambient_color(sDefaultAmbientColor)

        if math.fmod(get_global_timer(), 60) == 0 then
            for i = 0, LE_MAX_LIGHTS do
                if (not gSpotlightLightID or i ~= gSpotlightLightID) and le_light_exists(i) then
                    sLightIntensities[i] = le_get_light_intensity(i)
                end
            end
        end
    end

    if gNearestStar then
        local behavior = get_id_from_behavior(gNearestStar.behavior)
        local important = is_very_important(gNearestStar)
        local distMax = not important and STAR_ENV_MAX_DIST or IMPORTANT_ENV_MAX_DIST
        if gNearestStar.activeFlags & ACTIVE_FLAG_DEACTIVATED ~= 0 or sStarDist > distMax then
            gNearestStar = nil
        end

        local elegibleForNoise = 3
        if behavior == starNewID or behavior == grandStarNewID then
            elegibleForNoise = 0
        elseif behavior == spawnedStarNewID or behavior == spawnedStarNoExitNewID then
            elegibleForNoise = 2
        end

        if gNearestStar.oAction >= elegibleForNoise and (soundSetting == 1 or (soundSetting == 2 and important)) then
            if sSoundTimer > STAR_SOUND_DURATION then
                audio_sample_play(SOUND_CUSTOM_STAR_ENV, gNearestStar.header.gfx.pos, 0.75)
                sSoundTimer = 0
                seq_player_lower_volume(SEQ_PLAYER_LEVEL, 20, 100)
            else
                sSoundTimer = sSoundTimer + 1
            end

            if m.health > 0xFF and gDeathActs[m.action] == nil then
                if gLightDarken > 1 then gLightDarken = 1 end
                local starPos = {x = gNearestStar.oPosX, y = gNearestStar.oPosY, z = gNearestStar.oPosZ}
                local dist = vec3f_dist(m.pos, starPos)
                local min = not important and 0.5 or 0.2
                gLightDarken = approach_f32(gLightDarken, clamp(((dist - (distMax * 0.25)) / (distMax - (distMax * 0.325))), min, 1), 0.0325, 0.0325)
            end
        end
    else
        if sSoundTimer < STAR_SOUND_DURATION then
            audio_sample_stop(SOUND_CUSTOM_STAR_ENV)
            sSoundTimer = STAR_SOUND_DURATION
            seq_player_unlower_volume(SEQ_PLAYER_LEVEL, 20)
        end
        if m.health > 0xFF and gDeathActs[m.action] == nil and gLightDarken < 1 then
            gLightDarken = gLightDarken + 0.0325
        end
        sStarDist = 0
    end
end

local sPlayedBuzz = false

local SOUND_DEATH_BUZZ = audio_sample_load("death_buzz.mp3")

local sHasModHiddenHud = false

gDeathActs = {
    [ACT_STANDING_DEATH] = function(m)
        if gPlayerSyncTable[0].newAnims then
            return m.marioObj.header.gfx.animInfo.animFrame >= 110
        else 
            return m.marioObj.header.gfx.animInfo.animFrame >= 90
        end
    end,
    [ACT_DEATH_ON_BACK] = function(m)
        return m.marioObj.header.gfx.animInfo.animFrame >= 62
    end,
    [ACT_DEATH_ON_STOMACH] = function(m)
        return is_anim_at_end(m) ~= 0
    end,
    [ACT_DROWNING] = function(m)
        return m.marioObj.header.gfx.animInfo.animID == CHAR_ANIM_DROWNING_PART2 and
        m.marioObj.header.gfx.animInfo.animFrame >= m.marioObj.header.gfx.animInfo.curAnim.loopEnd * 0.25
    end,
    [ACT_WATER_DEATH] = function(m)
        return is_anim_at_end(m) ~= 0
    end,
    [ACT_CAUGHT_IN_WHIRLPOOL] = function(m)
        return m.actionTimer >= 16
    end,
    [ACT_SUFFOCATION] = function(m)
        return is_anim_at_end(m) ~= 0
    end,
    [ACT_ELECTROCUTION] = function(m)
        return is_anim_at_end(m) ~= 0
    end,
    [ACT_QUICKSAND_DEATH] = function(m)
        return is_anim_at_end(m) ~= 0
    end,
    [ACT_EATEN_BY_BUBBA] = function(m)
        return true
    end,
    [ACT_INTO_ABYSS] = function(m)
        return m.actionTimer >= 45
    end,
    [ACT_FROZEN_WATER] = function(m)
        return m.actionTimer >= 45
    end,
    [ACT_FROZEN] = function(m)
        return m.actionTimer >= 65
    end,
    [ACT_BURNT] = function(m)
        return m.actionState >= 2 and m.actionTimer >= 20
    end
}

local sSpecialSpotlightTriggers = {
    [ACT_STANDING_DEATH] = function(m)
        return m.marioObj.header.gfx.animInfo.animFrame >= 62
    end,
    [ACT_DEATH_ON_BACK] = function(m)
        return m.marioObj.header.gfx.animInfo.animFrame >= 20
    end,
    [ACT_DEATH_ON_STOMACH] = function(m)
        return m.marioObj.header.gfx.animInfo.animFrame >= 22
    end,
    [ACT_DROWNING] = function(m)
        return m.marioObj.header.gfx.animInfo.animID == CHAR_ANIM_DROWNING_PART2 or m.marioObj.header.gfx.animInfo.animFrame >= 70
    end,
    [ACT_SQUISHED] = function(m)
        return m.actionState == 2 or (m.actionArg >= 300 and not gSGOLocalSettings.miscThings)
    end,
    [ACT_INTO_ABYSS] = function(m)
        return false
    end,
    [ACT_FROZEN_WATER] = function(m)
        return m.actionTimer >= 25
    end,
    [ACT_BURNT] = function(m)
        return m.actionState >= 1
    end,
}

local emphazasise_death = function()
    local m = gMarioStates[0]
    if sSpecialSpotlightTriggers[m.action] then
        return switch(m.action, sSpecialSpotlightTriggers, m)
    elseif gDeathActs[m.action] then
        return true
    end
    return false
end

local handle_death_text = function()
    local m = gMarioStates[0]
    local c = gLakituState
    local prevPos = m.pos.y
    local prevYVel = m.vel.y
    local canBubble = (mario_can_bubble(m) and m.numLives > 0) or m.action == ACT_BUBBLED
    local tooBad = gSGOLocalSettings.deathScene == 1
    local bubba

    if m.action == ACT_EATEN_BY_BUBBA then
        bubba = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvBubba)
    end

    local focus = bubba and bubba.header.gfx.pos or m.marioObj.header.gfx.pos

    if gDeathActs[m.action] or (m.health - 64 * m.hurtCounter < 0x100 and m.action ~= ACT_BUBBLED) then
        if not canBubble and tooBad then
            fade_volume_scale(0, 0, 30)
        end
    end

    if (m.health <= 0xFF or gDeathActs[m.action]) then
        if not sPlayedBuzz then
            if not canBubble and tooBad then
                hud_hide()
            end
            if gSGOLocalSettings.deadBuzz then
                audio_sample_play(SOUND_DEATH_BUZZ, c.pos, 0.5)
            end
            spawn_non_sync_object(id_bhvSpotlight, E_MODEL_SPOTLIGHT, m.pos.x, m.pos.y + 520, m.pos.z, function(o)
                o.globalPlayerIndex = m.marioObj.globalPlayerIndex
            end)
            sPlayedBuzz = true
        end

        if emphazasise_death() then
            gLightDarken = clamp(gLightDarken - 0.05, 0.1, 1)
        end

    elseif m.health > 0xFF and not gDeathActs[m.action] and sPlayedBuzz then
        if not sHasModHiddenHud then
            hud_show()
        end
        sPlayedBuzz = false
        gLightDarken = 1
    end

    if (switch(m.action, gDeathActs, m) or (m.action == ACT_SQUISHED and m.actionTimer >= 30)) and not canBubble and tooBad then
        if gDeathTextTimer == 0 then
            gDeathTextTimer = 1
        end

        if gDeathTextTimer >= DEATH_TEXT_DURATION and m.action ~= ACT_INTO_ABYSS and m.action ~= ACT_FROZEN_WATER and m.action ~= ACT_BURNT then
            common_death_handler(m, m.marioObj.header.gfx.animInfo.animID, m.marioObj.header.gfx.animInfo.animFrame)
            m.vel.y = prevYVel
            m.pos.y = prevPos
            m.marioObj.header.gfx.pos.y = prevPos - m.quicksandDepth
        end
    end
end

sCamPos = {x = 0, y = 0, z = 0}
sFocusPos = {x = 0, y = 0, z = 0}
sCamDist = 0
sCamYaw = 0
sCamPitch = 0
sMoveDivisor = 1

sSGOCutsceneDuration = 0
local sMaxDuration = 0

local sGoalCamDist = 0
local sGoalCamYaw = 0
local sGoalCamPitch = 0
local sGoalFocusPos = {x = 0, y = 0, z = 0}

local vec3f_approach_asymptotic = function(current, goal, mult)
    current.x = approach_f32_asymptotic(current.x, goal.x, mult)
    current.y = approach_f32_asymptotic(current.y, goal.y, mult)
    current.z = approach_f32_asymptotic(current.z, goal.z, mult)
end

local set_cam_pos = function(x, y, z)
    sCamPos.x = x
    sCamPos.y = y
    sCamPos.z = z
end

local cam_orbit = function()
    set_cam_pos(sFocusPos.x + sCamDist * sins(s16(sCamYaw + 0x8000)) * coss(sCamPitch),
    sFocusPos.y + sCamDist * sins(sCamPitch),
    sFocusPos.z + sCamDist * coss(s16(sCamYaw + 0x8000)) * coss(sCamPitch))
end

local set_focus_pos = function(x, y, z)
    sFocusPos.x = x
    sFocusPos.y = y
    sFocusPos.z = z
end

local set_goal_focus_pos = function(x, y, z)
    sGoalFocusPos.x = x
    sGoalFocusPos.y = y
    sGoalFocusPos.z = z
end

sDeathCutscenes = {
    [ACT_STANDING_DEATH] = function(m)
        local ZOOM_IN = 78
        sMaxDuration = 110

        sMoveDivisor = 9.2
        sGoalCamYaw = m.faceAngle.y + deg_to_hex(145)

        if sSGOCutsceneDuration < ZOOM_IN then
            sGoalCamDist = 400
            sGoalCamPitch = deg_to_hex(-6)

            set_goal_focus_pos(m.pos.x, m.pos.y + 80, m.pos.z)

            sCamDist = approach_f32_asymptotic(sCamDist, sGoalCamDist, 1 / sMoveDivisor)
            sCamPitch = approach_s16_asymptotic(sCamPitch, sGoalCamPitch, sMoveDivisor)
            vec3f_approach_asymptotic(sFocusPos, sGoalFocusPos, 1 / sMoveDivisor)
        else
            sGoalCamDist = 320
            sGoalCamPitch = deg_to_hex(8)

            set_goal_focus_pos(m.pos.x, m.pos.y + 60, m.pos.z)

            local t = ease_in_out_quad((sSGOCutsceneDuration - ZOOM_IN) / (sMaxDuration - ZOOM_IN))

            sCamDist = lerp(400, sGoalCamDist, t)
            sCamPitch = lerp(deg_to_hex(-6), sGoalCamPitch, t)

            sFocusPos.y = lerp(m.pos.y + 80, sGoalFocusPos.y, t)
        end

        sCamYaw = approach_s16_asymptotic(sCamYaw, sGoalCamYaw, sMoveDivisor)

        cam_orbit()

        set_handheld_shake(HAND_CAM_SHAKE_STAR_DANCE)
    end,
    [ACT_DEATH_ON_BACK] = function(m)
        sMaxDuration = 80

        if sSGOCutsceneDuration < 10 then
            sCamDist = 170
            sCamYaw = m.faceAngle.y + deg_to_hex(265)
            sCamPitch = deg_to_hex(2)

            cam_orbit()
            sCamPos.y = sCamPos.y + 20
        elseif sSGOCutsceneDuration < 49 then
            sMoveDivisor = 48
            sGoalCamDist = 480
            sGoalCamYaw = m.faceAngle.y + deg_to_hex(185)
            sGoalCamPitch = deg_to_hex(42)

            sCamDist = approach_f32_asymptotic(sCamDist, sGoalCamDist, 1 / sMoveDivisor)
            sCamYaw = approach_s16_asymptotic(sCamYaw, sGoalCamYaw, sMoveDivisor)
            sCamPitch = approach_s16_asymptotic(sCamPitch, sGoalCamPitch, sMoveDivisor)

            cam_orbit()
        else
            sMoveDivisor = 24
            sGoalCamDist = 1400
            sGoalCamPitch = deg_to_hex(82)

            sCamDist = math.min(sCamDist + 1.8, sGoalCamDist)
            sCamYaw = s16(sCamYaw - deg_to_hex(0.25))
            sCamPitch = approach_s16_asymptotic(sCamPitch, sGoalCamPitch, sMoveDivisor)
            cam_orbit()
        end

        set_focus_pos(m.pos.x, m.pos.y + 20, m.pos.z)
    end,
}

cam_test = function()
    local m = gMarioStates[0]
    local c = m.area.camera
    local l = gLakituState

    if not c then return end

    sCamDist = vec3f_dist(c.focus, c.pos)
    sCamYaw = angle_to_point(c.pos, c.focus)
    sCamPitch = pitch_to_point(c.pos, c.focus)

    sFocusPos = {
        x = c.focus.x,
        y = c.focus.y,
        z = c.focus.z,
    }

    if c.cutscene == CUTSCENE_SGO_DEATH then
        switch(m.action, sDeathCutscenes, m)

        if sSGOCutsceneDuration < sMaxDuration then
            sSGOCutsceneDuration = sSGOCutsceneDuration + 1
        end

        vec3f_copy(c.pos, sCamPos)
        vec3f_copy(l.pos, sCamPos)
        vec3f_copy(l.goalPos, sCamPos)

        vec3f_copy(c.focus, sFocusPos)
        vec3f_copy(l.focus, sFocusPos)
        vec3f_copy(l.goalFocus, sFocusPos)
    else
        sSGOCutsceneDuration = 0
        if sDeathCutscenes[m.action] then
            c.cutscene = CUTSCENE_SGO_DEATH
        end
    end
end

handle_scenematics = function()
    handle_death_text()
    handle_star_env_effects()
    cam_test()
end

hook_event(HOOK_ON_DEATH, function(m)
    local canBubble = mario_can_bubble(m) and m.numLives > 0

    if gDeathTextTimer < DEATH_TEXT_DURATION and (gDeathActs[m.action] ~= nil or m.action == ACT_SQUISHED or m.action == ACT_LAVA_BOOST) and
    ((not canBubble and gSGOLocalSettings.deathScene <= 2) or
    ((m.floor.type == SURFACE_DEATH_PLANE or m.floor.type == SURFACE_VERTICAL_WIND) and m.actionTimer < 45)) then
        return false
    end
end)

hook_event(HOOK_ON_LEVEL_INIT, function()
    gWaitedForLightsOnOtherMods = false
end)