-- optimization
local hook_mod_menu_checkbox, math_fmod, smlua_anim_util_set_animation, hook_event, math_min, math_abs, lerp =
hook_mod_menu_checkbox, math.fmod, smlua_anim_util_set_animation, hook_event, math.min, math.abs, math.lerp

require "objects/koopa_shell"

gMarioEnhance = {}

for i = 0, MAX_PLAYERS - 1 do
    gMarioEnhance[i] = {}
    local e = gMarioEnhance[i]
    local s = gPlayerSyncTable[i]

    e.torsoAngle = {x = 0, y = 0, z = 0}
    e.prevForwardVel = 0
    e.prevVelY = 0
    e.scaleGoal = 0
    e.currScale = 0
    e.animState = 0

    e.resettedShade = true
    e.curPalette = {}
    e.temperature = 0
    e.resettedPalette = true
    e.grounded = true
    e.jumpDustTimer = 0
    e.wetLevel = 0
    e.wetTimer = 0
    e.prevFlags = 0
    e.prevRiddenObj = nil

    for j = 0, PLAYER_PART_MAX - 1 do
        table.insert(e.curPalette, {r = 0, g = 0, b = 0})
    end

    s.lookAngleYaw = nil
    s.lookAnglePitch = nil
end

SQUASH_AND_STRETCH_MULT = 0.0016

local SOUND_MARIO_HIT = audio_sample_load("mario_hit.mp3")

------------------------------------
--------  HELPER FUNCTIONS  --------
------------------------------------

---@param m MarioState
local active_player = function(m)
    local np = gNetworkPlayers[m.playerIndex]
    if m.playerIndex == 0 then
        return true
    end
    if not np.connected then
        return false
    end
    if np.currCourseNum ~= gNetworkPlayers[0].currCourseNum then
        return false
    end
    if np.currActNum ~= gNetworkPlayers[0].currActNum then
        return false
    end
    if np.currLevelNum ~= gNetworkPlayers[0].currLevelNum then
        return false
    end
    if np.currAreaIndex ~= gNetworkPlayers[0].currAreaIndex then
        return false
    end
    return true
end

local object_facing_mario = function(m, o, range)
    local dx = m.pos.x - o.oPosX
    local dz = m.pos.z - o.oPosZ

    local angleToMario = atan2s(dz, dx)
    local dAngle = s16(angleToMario - o.oMoveAngleYaw)

    if in_between(dAngle, -range, range, true) then
        return true
    end
    return false
end

local can_mario_talk = function(m, o)
    if o.oInteractionSubtype & INT_SUBTYPE_NPC == 0 and o.oInteractionSubtype & INT_SUBTYPE_SIGN == 0 then
        return false
    end

    if m.action & ACT_FLAG_IDLE ~= 0 then
        return true
    end
    if m.action == ACT_WALKING then
        local anim = m.marioObj.header.gfx.animInfo.animID
        if o.oInteractionSubtype & INT_SUBTYPE_NPC ~= 0 or anim == 0x80 or anim == 0x7F or anim == 0x6C then
            return true
        end
    end

    return false
end

----------------------------------
--------  OBJECT LOOKING  --------
----------------------------------

--- @param o Object
local obj_is_interesting = function(o)
    local np = gNetworkPlayers[0]
    local lookAtTypes = INTERACT_STAR_OR_KEY | INTERACT_GRABBABLE | INTERACT_KOOPA | INTERACT_TEXT | INTERACT_KOOPA_SHELL | INTERACT_CAP

    if o.oInteractType & lookAtTypes ~= 0 or (obj_is_coin(o) and o.oDamageOrCoinValue > 1) or obj_is_mushroom_1up(o) or
    obj_is_exclamation_box(o) or (get_id_from_behavior(o.behavior) == id_bhvMario and o.globalPlayerIndex ~= np.globalIndex) then
        return true
    end

    return false
end

--- @param m MarioState
--- @param o Object
local obj_within_looking_range = function(m, o)
    local lookPoint = {x = o.oPosX, y = o.oPosY + o.hitboxHeight * 0.65, z = o.oPosZ}
    local pos = m.marioBodyState.headPos

    local pitch = pitch_to_point(pos, lookPoint) - m.marioObj.header.gfx.angle.x
    local yaw = s16(angle_to_point(pos, lookPoint) - m.faceAngle.y)
    local castYaw = yaw + m.marioObj.header.gfx.angle.y
    local objDist = dist_between_objects(m.marioObj, o)

    local ray = collision_find_surface_on_ray(pos.x, pos.y, pos.z, OBJ_LOOKING_RANGE * sins(castYaw) * coss(-pitch),
    OBJ_LOOKING_RANGE * sins(-pitch), OBJ_LOOKING_RANGE * coss(castYaw) * coss(-pitch))

    if math.abs(pitch) <= deg_to_hex(90) and math.abs(yaw) <= deg_to_hex(100) and objDist <= OBJ_LOOKING_RANGE then
        if (ray ~= nil and vec3f_dist(pos, ray.hitPos) < objDist and (ray.surface.object == nil or ray.surface.object ~= o)) then
            return false
        end
        return true
    end

    return false
end

---@param o Object
local obj_is_visible = function(o)
    if o.activeFlags == ACTIVE_FLAG_DEACTIVATED or o.header.gfx.node.flags & GRAPH_RENDER_ACTIVE == 0 or
    o.header.gfx.node.flags & GRAPH_RENDER_INVISIBLE ~= 0 then
        return false
    end

    return true
end

---------------------------------------
--------  SOUND RELATED MISC.  --------
---------------------------------------

local sSleepMusic = false

---@param m MarioState
local play_sleep_music = function(m)
    local o = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvPiranhaPlantBubble)

    if o ~= nil and dist_between_objects(m.marioObj, o) < 1000 then
        return
    end

    o = obj_get_next_with_same_behavior_id(m.marioObj)
    local m2 = nil
    if o ~= nil then
        m2 = gMarioStates[network_local_index_from_global(o.globalPlayerIndex)]
    end

    if m.action == ACT_SLEEPING or (m2 ~= nil and m2.action == ACT_SLEEPING and vec3f_dist(m.pos, m2.pos) < 1000) then
        play_secondary_music(SEQ_EVENT_PIRANHA_PLANT, 0, 255, 1000)
        sSleepMusic = true
    elseif sSleepMusic then
        stop_secondary_music(50)
        sSleepMusic = false
    end
end

local sBaseTempo = 0
local sBasePitch = 0

local sLowHpDistortLerp = 0
local sCancelDistortTimer = 0

-- when should the current powerup's theme start to speed up
local POWERUP_RAMP_UP_POINT = 8 * 30

---@param m MarioState
local tempo_and_pitch_distort = function(m)
    local tempoMult = 1
    local pitchAdd = 0
    local lowHpDistort = gSGELocalSettings.lowHpMusic

    if m.health < 0x300 then
        sLowHpDistortLerp = approach_f32_symmetric(sLowHpDistortLerp, lowHpDistort, (lowHpDistort / 20))
    else
        sLowHpDistortLerp = approach_f32_symmetric(sLowHpDistortLerp, 0, (lowHpDistort / 20))
    end

    if sLowHpDistortLerp > 0 and lowHpDistort > 0 then
        tempoMult = tempoMult - 0.2 * sLowHpDistortLerp
        pitchAdd = (-1 + (math.sin(get_global_timer() * 0.2) * 3)) * sLowHpDistortLerp
    end

    local powerUpPentUpLerp = 1 - clamp((m.capTimer - 4 * 30) / POWERUP_RAMP_UP_POINT, 0, 1)

    if m.capTimer < POWERUP_RAMP_UP_POINT and m.capTimer > 0 and gSGELocalSettings.powerupMusicRampUp then
        tempoMult = tempoMult + 0.25 * powerUpPentUpLerp
        pitchAdd = pitchAdd + (m.capTimer < POWERUP_RAMP_UP_POINT * 0.75 and 1 or 0)
    end

    if mario_is_crouching(m) and m.action ~= ACT_START_CROUCHING then
        tempoMult = tempoMult * (1 - gSGELocalSettings.crouchSlowMusic)
    end

    if sCancelDistortTimer > 0 then
        sCancelDistortTimer = sCancelDistortTimer - 1
        sBaseTempo = sequence_player_get_tempo(SEQ_PLAYER_LEVEL)
        sBasePitch = sequence_player_get_transposition(SEQ_PLAYER_LEVEL)
    else
        sequence_player_set_tempo(SEQ_PLAYER_LEVEL, sBaseTempo * tempoMult)
        sequence_player_set_transposition(SEQ_PLAYER_LEVEL, sBasePitch + pitchAdd)
    end
end

---@param m MarioState
local vanish_cap_fluctuate = function(m)
    if gSGELocalSettings.vanishEffect == 0 then return end
    -- m.capTimer doesnt sync, so just discard the pent up effect and do the slowest flucutuation on remote players
    local powerUpPentUpLerp = m.playerIndex == 0 and clamp((m.capTimer - 4 * 30) / POWERUP_RAMP_UP_POINT, 0, 1) or 1

    if m.flags & MARIO_VANISH_CAP ~= 0 and m.flags & MARIO_TELEPORTING == 0 then
        local waveSpeed = math.floor(1 + 5 * (1 - powerUpPentUpLerp)) / 10
        m.marioBodyState.modelState = m.marioBodyState.modelState + math.sin(get_global_timer() * waveSpeed) *
        (20 + math.floor(15 * powerUpPentUpLerp)) * gSGELocalSettings.vanishEffect
    end
end

---@param m MarioState
local woosh_sound_on_jump = function(m)
    if not gSGELocalSettings.jumpSounds then return end
    local camToObj = m.marioObj.header.gfx.cameraToObject

    if (m.vel.y >= 62 and m.action ~= ACT_SHOT_FROM_CANNON) or (m.action == ACT_LONG_JUMP and m.marioObj.oMarioLongJumpIsSlow == 0) then
        play_sound_with_freq_scale(SOUND_OBJ_UNKNOWN4, camToObj, lerp(0.85, 1.56, clamp((m.vel.y - 62) / 20, 0, 1)))
    end
end

local sFallingHeight = 0

---@param m MarioState
local wind_sound_on_far_fall = function(m)
    if not gSGELocalSettings.fallSound then return end
    local camToObj = m.marioObj.header.gfx.cameraToObject

    if m.vel.y > 0 or m.floorHeight >= m.pos.y then
        sFallingHeight = m.pos.y
    end

    if m.action == ACT_SHOT_FROM_CANNON then
        play_sound_with_freq_scale(SOUND_MOVING_FLYING, camToObj, 0.48)
    elseif (m.action & ACT_FLAG_AIR) ~= 0 and sFallingHeight - m.pos.y >= 750 and m.action ~= ACT_FLYING and m.vel.y < -55 then
        play_sound_with_freq_scale(SOUND_MOVING_FLYING, camToObj, lerp(0.3, 0.52, clamp((sFallingHeight - m.pos.y - 750) / 2250, 0, 1) *
        math.min((math.abs(m.vel.y) - 55) / 20, 1.2)))
    end
end

-------------------------
--------  HOOKS  --------
-------------------------

local sLookObj = nil
local sAttentionTimer = 0
local sPrevPos = {x = 0, y = 0, z = 0}

hook_event(HOOK_MARIO_UPDATE, function(m)
    if not active_player(m) then
        return
    end
    local e = gMarioEnhance[m.playerIndex]
    local s = gPlayerSyncTable[m.playerIndex]

    if m.playerIndex == 0 then
        local battleThemes = {
            [(4 << 8) | SEQ_EVENT_BOSS] = true,
            [SEQ_LEVEL_BOSS_KOOPA] = true,
            [SEQ_LEVEL_BOSS_KOOPA_FINAL] = true,
            [SEQ_LEVEL_KOOPA_ROAD] = true,
        }

        if (m.action == ACT_PUNCHING or m.action == ACT_MOVE_PUNCHING) or battleThemes[get_current_background_music()] then
            sBattleStanceTimer = 4.5 * 30
        elseif sBattleStanceTimer > 0 then
            sBattleStanceTimer = sBattleStanceTimer - 1
        end

        if sLookObj then
            if not obj_within_looking_range(m, sLookObj) or not obj_is_visible(sLookObj) then
                sLookObj = nil
                sAttentionTimer = 0
                s.lookAngleYaw = nil
                s.lookAnglePitch = nil
            else
                local lookPoint = {x = sLookObj.oPosX, y = sLookObj.oPosY + sLookObj.hitboxHeight * 0.65, z = sLookObj.oPosZ}

                if m.playerIndex == 0 and m.action == ACT_IDLE and m.actionState ~= 1 then
                    set_mario_action(m, ACT_LOOKING, m.actionState + 1)
                end
                sAttentionTimer = math.max(sAttentionTimer - 1, 0)
                objLookRefresh = 60

                if get_id_from_behavior(sLookObj.behavior) == id_bhvMario then
                    lookPoint.y = gMarioStates[network_local_index_from_global(sLookObj.globalPlayerIndex)].marioBodyState.headPos.y
                end

                s.lookAnglePitch = pitch_to_point(m.marioBodyState.headPos, lookPoint) - m.marioObj.header.gfx.angle.x - m.marioBodyState.torsoAngle.x * 0.65

                s.lookAngleYaw = s16(angle_to_point(m.marioBodyState.headPos, lookPoint) - m.faceAngle.y)
            end
        end

        if gSGELocalSettings.objLook then
            local objLookRefresh = 15

            local dist

            if math.fmod(get_global_timer(), objLookRefresh) == 0 and sAttentionTimer <= 0 then
                for i = 0, NUM_OBJ_LISTS - 1 do
                    local o = obj_get_first(i)
                    while o ~= nil do
                        if obj_is_interesting(o) and (dist == nil or dist_between_objects(m.marioObj, o) < dist) and
                        obj_within_looking_range(m, o) and obj_is_visible(o) then
                            sLookObj = o
                            dist = dist_between_objects(m.marioObj, o)
                            -- mario so brain rotten his attention span is only 3 seconds :sob:
                            sAttentionTimer = 90
                        end

                        o = obj_get_next(o)
                    end
                end
            end
        end

        if m.floor.type == SURFACE_DEATH_PLANE or m.floor.type == SURFACE_VERTICAL_WIND then
            if gSGELocalSettings.miscThings then
                m.marioObj.header.gfx.shadowInvisible = true
            end
            if (m.action & ACT_GROUP_MASK) ~= ACT_GROUP_CUTSCENE and m.action ~= ACT_BUBBLED and m.floor ~= nil and
            m.pos.y < m.floorHeight + 2048 and m.action ~= ACT_INTO_ABYSS and gSGELocalSettings.deathScene <= 2 then
                drop_and_set_mario_action(m, ACT_INTO_ABYSS, 0)
            end
        else
            m.marioObj.header.gfx.shadowInvisible = false
        end

        if (m.action == ACT_LAVA_BOOST and m.health <= 0xFF) then
            drop_and_set_mario_action(m, m.area.terrainType & TERRAIN_MASK == TERRAIN_SNOW and ACT_FROZEN or ACT_BURNT, 0)
        end

        --[[
        if m.controller.buttonPressed & Y_BUTTON ~= 0 then
            m.hurtCounter = 8 * 4
        end

        if m.controller.buttonPressed & X_BUTTON ~= 0 then
            m.health = 0x100
            m.hurtCounter = 0
            m.healCounter = 8 * 4
            m.area.camera.cutscene = 0
            set_mario_action(m, m.waterLevel > m.pos.y and ACT_WATER_IDLE or ACT_IDLE, 0)
        end
        ]]--

        local globalTimer = get_global_timer()
        -- only run this every once in a while for optimization, its not that necessary
        if math_fmod(globalTimer, 30) == 0 and (gSGELocalSettings.sleepyMusic or sSleepMusic) then
            play_sleep_music(m)
        end

        if m.area.camera and m.area.camera.cutscene == CUTSCENE_SGE_DEATH then
            local c = m.area.camera
            local l = gLakituState

            if sPrevPos.x ~= m.pos.x or sPrevPos.y ~= m.pos.y or sPrevPos.z ~= m.pos.z then
                local deltaPos = {
                    x = m.pos.x - sPrevPos.x,
                    y = m.pos.y - sPrevPos.y,
                    z = m.pos.z - sPrevPos.z,
                }
                vec3f_add(c.pos, deltaPos)
                vec3f_add(l.pos, deltaPos)
                vec3f_add(l.goalPos, deltaPos)

                vec3f_add(c.focus, deltaPos)
                vec3f_add(l.focus, deltaPos)
                vec3f_add(l.goalFocus, deltaPos)
            end
        end

        if gSGELocalSettings.miscThings then
            local secret = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvHiddenStarTrigger)

            if secret and obj_check_if_collided_with_object(m.marioObj, secret) ~= 0 then
                local remaining = count_objects_with_behavior(secret.behavior)

                -- Check for 1 because the secret being currently collected is still counted
                if remaining == 1 then
                    play_character_sound(m, CHAR_SOUND_HAHA_2)
                    audio_sample_play(SOUND_CLAPPING, m.area.camera.pos, 1)
                end

            end
        end

        tempo_and_pitch_distort(m)
        wind_sound_on_far_fall(m)
    end

    spawn_particles_mario_update(m)
    run_animations(m)
    vanish_cap_fluctuate(m)
end)

hook_event(HOOK_BEFORE_MARIO_UPDATE, function(m)
    local e = gMarioEnhance[m.playerIndex]
    e.prevForwardVel = m.forwardVel
    e.prevVelY = m.action & ACT_FLAG_AIR ~= 0 and m.vel.y or 0
    e.prevFlags = m.flags
    e.prevRiddenObj = m.riddenObj

    if m.action == ACT_RIDING_SHELL_GROUND then
        m.twirlYaw = m.faceAngle.y
    end

    if m.playerIndex == 0 then
        handle_menu_inputs(m)
    end

    spawn_particles_before_update(m)
end)

hook_event(HOOK_ON_SET_MARIO_ACTION, function(m)
    if not active_player(m) then
        return
    end

    local mBody = m.marioBodyState
    local e = gMarioEnhance[m.playerIndex]

    if m.action & ACT_GROUP_MASK ~= ACT_GROUP_SUBMERGED and m.prevAction & ACT_FLAG_AIR ~= 0 and m.action & ACT_FLAG_AIR == 0 then
        e.scaleGoal = math_abs(clamp(e.prevVelY, -75, 0))
        e.currScale = e.scaleGoal * 0.25
    elseif m.action & ACT_FLAG_AIR ~= 0 then
        e.currScale = 0
    end

    if m.action == ACT_JUMP then
        e.animState = 0
    end

    if m.action ~= ACT_SQUISHED then
        mBody.torsoAngle.x = 0
        mBody.torsoAngle.y = 0
        mBody.torsoAngle.z = 0

        e.torsoAngle.x = 0
        e.torsoAngle.y = 0
        e.torsoAngle.z = 0
    end

    if m.action == ACT_INTO_ABYSS then
        local rotSign = m.forwardVel ~= 0 and (m.forwardVel / math_abs(m.forwardVel)) or 1
        m.angleVel.x = random_float() * deg_to_hex(6) + deg_to_hex(18) * rotSign
        m.angleVel.z = random_float() * deg_to_hex(4) + deg_to_hex(12)
        audio_sample_play(SOUND_INTO_ABYSS, m.marioObj.header.gfx.pos, 1)
    end

    if m.action == ACT_FROZEN_WATER or m.action == ACT_FROZEN then
        audio_sample_play(SOUND_FROZEN, m.pos, 1)
    end

    if m.prevAction == ACT_SHOCKED then
        e.temperature = TEMPERATURE_MAX_VALUE
    end

    if m.action ~= ACT_INTO_ABYSS and gDeathActs[m.action] and obj_get_first_with_behavior_id(id_bhvSpotlight) == nil and not (m.numLives > 0 and mario_can_bubble(m)) and
    m.playerIndex == 0 then
        spawn_non_sync_object(id_bhvSpotlight, E_MODEL_SPOTLIGHT, m.pos.x, m.pos.y + 520, m.pos.z, function(o)
            o.globalPlayerIndex = m.marioObj.globalPlayerIndex
        end)
    end

    spawn_particles_on_set_act(m)
    woosh_sound_on_jump(m)

    if not gPlayerSyncTable[m.playerIndex].newAnims then
        return
    end

    if m.action == ACT_IDLE then
        if m.prevAction == ACT_PUNCHING then
            return set_mario_action(m, ACT_BATTLE_STANCE, 1)
        elseif sBattleStanceTimer > 24 and (m.input & INPUT_IN_POISON_GAS) == 0 and m.quicksandDepth <= 30 then
            return set_mario_action(m, ACT_BATTLE_STANCE, 0)
        elseif m.playerIndex == 0 and sLookObj and m.health >= 0x300 then
            set_mario_action(m, ACT_LOOKING, 0)
        end
    elseif m.action == ACT_WALKING then
        if m.prevAction == ACT_MOVE_PUNCHING and in_between(m.forwardVel, -2, 2, true) then
            return set_mario_action(m, ACT_BATTLE_STANCE, 1)
        end
    end
end)

hook_event(HOOK_BEFORE_SET_MARIO_ACTION, function(m, nextAct)
    if not active_player(m) then
        return 0
    end
    local s = gPlayerSyncTable[0]
    local customDeaths = gSGELocalSettings.deathScene <= 2

    if m.action == ACT_FORWARD_ROLLOUT and gPlayerSyncTable[m.playerIndex].newAnims and nextAct == ACT_FREEFALL_LAND_STOP and
    (m.prevAction == ACT_DIVE_SLIDE or m.prevAction == ACT_STOMACH_SLIDE) then
        return ACT_ROLLOUT_LAND
    end

    if m.area.terrainType & TERRAIN_MASK == TERRAIN_SNOW and nextAct == ACT_DROWNING and customDeaths then
        mario_stop_riding_and_holding(m)
        return ACT_FROZEN_WATER
    end

    if nextAct == ACT_STANDING_DEATH and m.action == ACT_BURNING_GROUND and customDeaths then
        return ACT_BURNT
    end

    if nextAct == ACT_DEATH_ON_STOMACH and m.marioObj.header.gfx.animInfo.animFrame < 36 and s.newAnims then
        return 1
    end
end)

local sCelebrateOnLastObjs = {
    [id_bhvHiddenBlueCoin] = true,
    [id_bhvRedCoin] = true,
    [id_bhvHiddenStarTrigger] = true,
}

hook_event(HOOK_ON_INTERACT, function(m, o)
    if o.oInteractStatus & INT_STATUS_ATTACKED_MARIO ~= 0 and m.flags & MARIO_METAL_CAP == 0 then
        local yaw = mario_obj_angle_to_object(m, o)
        local dmg = o.oDamageOrCoinValue
        if m.flags & MARIO_CAP_ON_HEAD == 0 then
            dmg = dmg + math.floor((dmg + 1) / 2)
        end
        if o.oInteractType ~= INTERACT_SHOCK and gSGELocalSettings.damageSounds <= 2 then
            audio_sample_play(SOUND_MARIO_HIT, m.pos, 2)
        end
        spawn_hurt_particles(m, yaw, dmg)

        return
    end

    if o.oInteractType == INTERACT_STAR_OR_KEY then
        gNearestStar = nil
        if o.oLightID then
            le_remove_light(o.oLightID)
        end

        if not is_very_important(o) and gServerSettings.stayInLevelAfterStar == 2 and gSGELocalSettings.miscThings then
            play_character_sound(m, CHAR_SOUND_HERE_WE_GO)
            spawn_non_sync_object(id_bhvCelebrationStar, E_MODEL_STAR, o.oPosX, o.oPosY, o.oPosZ, function(star)
                star.oFaceAnglePitch = 0
                star.oFaceAngleRoll = 0
                star.parentObj = m.marioObj
                star.oBehParams = 1
            end)
        end

        return
    end

    if o.oInteractType == INTERACT_TEXT and can_mario_talk(m, o) then
        if o.oInteractionSubtype & INT_SUBTYPE_NPC ~= 0 then
            local dYaw = s16(mario_obj_angle_to_object(m, o) - m.faceAngle.y)
            if in_between(dYaw, -0x4000, 0x4000, true) then
                gTalkPrompt = 1
            end
        else
            local dYaw = s16(o.oMoveAngleYaw + 0x8000 - m.faceAngle.y)
            if object_facing_mario(m, o, 0x4000) and in_between(dYaw, -0x4000, 0x4000, true) then
                gTalkPrompt = 2
            end
        end

        return
    end

    if sCelebrateOnLastObjs[get_id_from_behavior(o.behavior)] and gSGELocalSettings.miscThings then
        local remaining = count_objects_with_behavior(o.behavior)

        -- Check for 1 because the coin being currently collected is still counted
        if remaining == 1 then
            play_character_sound(m, CHAR_SOUND_HAHA_2)
            audio_sample_play(SOUND_CLAPPING, m.area.camera.pos, 1)
        end

        return
    end
end)

hook_event(HOOK_UPDATE, function()
    handle_scenematics()
    gTalkPrompt = false
    vec3f_copy(sPrevPos, gMarioStates[0].pos)
end)

hook_event(HOOK_ON_WARP, function()
    sBattleStanceTimer = 0
    gNearestStar = nil
    gWaitedForLightsOnOtherMods = false
    for i = 1, #gAfterImageData do
        gAfterImageData[i] = nil
    end
end)

hook_event(HOOK_CHARACTER_SOUND, function(m, sound)
    if m.marioObj.header.gfx.animInfo.animFrame > 50 and m.marioObj.header.gfx.animInfo.animID == CHAR_ANIM_FALL_OVER_BACKWARDS then
        return 0
    end
    if sound == CHAR_SOUND_YAHOO and gSGELocalSettings.miscThings then
        play_character_sound_offset(m, CHAR_SOUND_YAHOO_WAHA_YIPPEE, math.fmod(math.random(3, 5), 5) << 16)
        return 0
    end
    if sound == CHAR_SOUND_YAH_WAH_HOO and m.action == ACT_STEEP_JUMP and gPlayerSyncTable[m.playerIndex].newAnims then
        play_character_sound(m, CHAR_SOUND_UH)
        return 0
    end
end)

hook_event(HOOK_ON_SEQ_LOAD, function(player, id)
    local priority = 4 << 8
    if id ~= priority | gLevelValues.metalCapSequence and id ~=priority | gLevelValues.vanishCapSequence and
    id ~= priority | gLevelValues.wingCapSequence then
        bgMusic = id
    end
    if player == SEQ_PLAYER_LEVEL then
        sCancelDistortTimer = 15
    end
end)

local sMuteStarSound = false

hook_event(HOOK_ALLOW_INTERACT, function(m, o)
    local capFlag = get_mario_cap_flag(o)
    if o.oInteractType == INTERACT_CAP and m.action ~= ACT_GETTING_BLOWN and capFlag ~= MARIO_NORMAL_CAP and (m.flags & capFlag) == 0 then
        sMuteStarSound = true
    end
end)

hook_event(HOOK_ON_PLAY_SOUND, function(sound)
    if sound == SOUND_MENU_STAR_SOUND and sMuteStarSound then
        sMuteStarSound = false
        return 0
    end
end)