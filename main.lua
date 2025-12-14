-- name: Sharen's Game Enhancer
-- description: A total re-do of a mayority of Mario's animations, complete with extra flairs such as open hands, dynamic body movement and more! \n\nAuthor, Code, Animations: Sharen \nDeath Jingle extracted and isolated by eros71 from M&L: SS + BM

-- optimization
local hook_mod_menu_checkbox, math_fmod, smlua_anim_util_set_animation, hook_event, math_min, math_abs, lerp =
hook_mod_menu_checkbox, math.fmod, smlua_anim_util_set_animation, hook_event, math.min, math.abs, math.lerp

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

gNearestStar = nil
gLightDarken = 2
gTalkPrompt = false

local SOUND_CRUSHED = audio_sample_load("crushed.mp3")
local SOUND_FROZEN = audio_sample_load("frozen.mp3")
local SOUND_INTO_ABYSS = audio_sample_load("into_abyss.mp3")
local SOUND_MARIO_HIT = audio_sample_load("mario_hit.mp3")

---@param m MarioState
local play_custom_anim = function(m, name, accel)
    if accel == nil then
        accel = 0x10000
    end

    m.marioObj.header.gfx.animInfo.animAccel = accel

    if (smlua_anim_util_get_current_animation_name(m.marioObj) ~= name or m.marioObj.header.gfx.animInfo.animID ~= -1) then
        --Hopefully prevents dynos packs with animations from messing stuff up, also sets the frame to 0
        set_character_animation(m, CHAR_ANIM_CREDITS_TAKE_OFF_CAP)
    end

    -- jank may occur without this line
    m.marioObj.header.gfx.animInfo.animID = -1

    smlua_anim_util_set_animation(m.marioObj, name)
end

-- custom actions

sBattleStanceTimer = 0

local act_battle_stance = function(m)
    if check_common_idle_cancels(m) ~= 0 then
        return 1
    end

    if not gPlayerSyncTable[m.playerIndex].newAnims then
        return set_mario_action(m, ACT_IDLE, 0)
    end

    if m.playerIndex ~= 0 then
        m.actionArg = 1
    elseif ((m.input & INPUT_IN_POISON_GAS) ~= 0 or m.quicksandDepth > 30 or sBattleStanceTimer <= 0) and is_anim_at_end(m) ~= 0 then
        m.actionArg = 2
    end

    if m.actionArg == 0 then
        play_custom_anim(m, "MARIO_ANIM_BATTLE_STANCE_START")
        if is_anim_at_end(m) ~= 0 then
            m.actionArg = 1
        end
    elseif m.actionArg == 1 then
        play_custom_anim(m, "MARIO_ANIM_BATTLE_STANCE")
    else
        play_custom_anim(m, "MARIO_ANIM_BATTLE_STANCE_STOP")
        if is_anim_at_end(m) ~= 0 then
            return set_mario_action(m, ACT_IDLE, 0)
        end
    end

    stationary_ground_step(m)

    return 0
end

local act_rollout_land = function(m)
    if check_common_landing_cancels(m, 0) ~= 0 then
        return 1
    end

    stationary_ground_step(m)
    play_custom_anim(m, "MARIO_ANIM_ROLLOUT_LAND")
    if is_anim_at_end(m) ~= 0 then
        return set_mario_action(m, ACT_IDLE, 0)
    end
    return 0
end

--- @param m MarioState
local act_looking = function(m)
    if check_common_idle_cancels(m) ~= 0 then
        return 1
    end

    m.actionTimer = m.actionTimer + 1

    if m.actionTimer > 200 then
        m.actionTimer = 0
    end

    -- m.marioObj.header.gfx.animInfo.curAnim.flags = m.marioObj.header.gfx.animInfo.curAnim.flags & ~ANIM_FLAG_FORWARD

    if m.actionArg == 1 then
        set_mario_animation(m, MARIO_ANIM_IDLE_HEAD_LEFT)
        set_anim_to_frame(m, m.marioObj.header.gfx.animInfo.animFrame - 1)
        if m.marioObj.header.gfx.animInfo.animFrame <= 0 then
            m.actionArg = 0
        end
    elseif m.actionArg == 3 then
        set_mario_animation(m, MARIO_ANIM_IDLE_HEAD_CENTER)
        if is_anim_at_end(m) ~= 0 then
            m.actionArg = 0
        end
    else
        set_mario_animation(m, MARIO_ANIM_FIRST_PERSON)

        if m.marioBodyState.headAngle.x == 0 and m.marioBodyState.headAngle.y == 0 and
        (math.fmod(m.marioObj.header.gfx.animInfo.animFrame, 30) == 0 or m.actionArg == 2) then
            set_mario_action(m, ACT_IDLE, 0)
        end
    end

    stationary_ground_step(m)

    return 0
end

--- @param m MarioState
local act_squished = function(m)
    if m == nil then
        return true
    end

    local spaceUnderCeil = m.ceilHeight - m.floorHeight < 0 and 0 or m.ceilHeight - m.floorHeight
    local surfAngle
    local underSteepSurf = false

    if m.actionState == 0 then
        if spaceUnderCeil > 160 then
            m.squishTimer = 0
            m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags | GRAPH_RENDER_ACTIVE
            set_mario_action(m, ACT_IDLE, 0)
            return 0
        end

        m.squishTimer = 0xFF

        if spaceUnderCeil >= 10.1 then
            local squishAmount = spaceUnderCeil / 160
            vec3f_set(m.marioObj.header.gfx.scale, 2.0 - squishAmount, squishAmount, 2.0 - squishAmount)
        else
            if (gSGOLocalSettings.damageSounds - 1) & 1 == 0 then
                audio_sample_play(SOUND_CRUSHED, m.pos, 2)
            end
            if (m.flags & MARIO_METAL_CAP) == 0 and m.invincTimer == 0 then
                m.hurtCounter = m.hurtCounter + ((m.flags & MARIO_CAP_ON_HEAD) ~= 0 and 12 or 18)

                local sound = m.health - m.hurtCounter * 64 < 0x100 and CHAR_SOUND_DYING or CHAR_SOUND_WHOA

                if not gSGOLocalSettings.miscThings then
                    sound = CHAR_SOUND_ATTACKED
                end

                play_character_sound(m, sound)
            end

            vec3f_set(m.marioObj.header.gfx.scale, 1.8, 0.05, 1.8)
            queue_rumble_data_mario(m, 10, 80)
            m.actionState = 1
        end
    elseif m.actionState == 1 then
        if spaceUnderCeil >= 30 then
            m.actionState = 2
        end
    elseif m.actionState == 2 then
        m.actionTimer = m.actionTimer + 1

        if m.actionTimer >= 15 then
            if m.health < 0x100 then
                if m.playerIndex ~= 0 then
                    m.health = 0x100
                end
                if m.actionTimer == 30 and gSGOLocalSettings.miscThings then
                    common_death_handler(m, m.marioObj.header.gfx.animInfo.animID, m.marioObj.header.gfx.animInfo.animFrame)
                elseif not gSGOLocalSettings.miscThings then
                    --why... does coopdx do this instead of simply making mario dissapear?
                    drop_and_set_mario_action(m, ACT_DEATH_ON_BACK, 0)
                    m.squishTimer = 0
                end
            elseif m.hurtCounter == 0 then
                m.squishTimer = 30
                m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags | GRAPH_RENDER_ACTIVE
                set_mario_action(m, ACT_IDLE, 0)
            end
        end
    end

    if gSGOLocalSettings.miscThings then
        m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags & ~GRAPH_RENDER_HAS_ANIMATION
    else
        set_mario_animation(m, CHAR_ANIM_A_POSE)
    end

    if m.floor ~= nil and m.floor.normal.y < 0.5 then
        surfAngle = atan2s(m.floor.normal.z, m.floor.normal.x)
        underSteepSurf = true
    end

    if m.ceil ~= nil and m.ceil.normal.y > -0.5 then
        surfAngle = atan2s(m.ceil.normal.z, m.ceil.normal.x)
        underSteepSurf = true
    end

    if underSteepSurf then
        m.vel.x = sins(surfAngle) * 10.0
        m.vel.y = 0
        m.vel.z = coss(surfAngle) * 10.0

        local step = perform_ground_step(m)

        if step == GROUND_STEP_LEFT_GROUND then
            m.squishTimer = 0
            set_mario_action(m, ACT_IDLE, 0)
            return 0
        end
    end

    m.actionArg = m.actionArg + 1

    if m.actionArg > 225 and (m.actionArg & 1) ~= 0 and gSGOLocalSettings.miscThings then
        m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags & ~GRAPH_RENDER_ACTIVE
    else
        m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags | GRAPH_RENDER_ACTIVE
    end

    if m.actionArg > 300 then
        if m.playerIndex ~= 0 then
            m.health = 0x100
        else
            if gSGOLocalSettings.miscThings then
                m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags | GRAPH_RENDER_ACTIVE
                m.hurtCounter = 255
                m.actionState = 2
                play_character_sound_if_no_flag(m, CHAR_SOUND_DYING, MARIO_MARIO_SOUND_PLAYED)
            else
                m.health = 0xFF
                m.hurtCounter = 0
                common_death_handler(m, m.marioObj.header.gfx.animInfo.animID, m.marioObj.header.gfx.animInfo.animFrame)
                set_mario_action(m, ACT_DISAPPEARED, 0)
            end
        end
    end

    stop_and_set_height_to_floor(m)
    return 0
end

---@param m MarioState
local act_reading_sign = function(m)
    if m.playerIndex ~= 0 then
        set_mario_animation(m, MARIO_ANIM_FIRST_PERSON)
        return 0
    end
    local mObj = m.marioObj

    play_sound_if_no_flag(m, SOUND_ACTION_READ_SIGN, MARIO_ACTION_SOUND_PLAYED)

    switch(m.actionState, {
        [0] = function()
            local speed = 5
            local goalPosX = m.pos.x + mObj.oMarioReadingSignDPosX
            local goalPosZ = m.pos.z + mObj.oMarioReadingSignDPosZ

            m.area.camera.cutscene = CUTSCENE_READ_MESSAGE
            enable_time_stop_if_alone()

            set_mario_anim_with_accel(m, MARIO_ANIM_START_TIPTOE, speed / 4 * 0x10000)
            play_step_sound(m, 10, 22)

            m.actionTimer = m.actionTimer + 1

            m.faceAngle.y = atan2s(goalPosZ - mObj.header.gfx.pos.z, goalPosX - mObj.header.gfx.pos.x)

            mObj.header.gfx.pos.x = approach_f32(mObj.header.gfx.pos.x, goalPosX, speed, speed)
            mObj.header.gfx.pos.z = approach_f32(mObj.header.gfx.pos.z, goalPosZ, speed, speed)

                                                                                            --failsafe
            if (mObj.header.gfx.pos.x == goalPosX and mObj.header.gfx.pos.z == goalPosZ) or m.actionTimer >= 45 then
                m.actionState = 1
                m.actionTimer = 0
                vec3f_copy(m.pos, mObj.header.gfx.pos)
            end
        end,
        [1] = function()
            local goalAngle = m.usedObj and atan2s(m.usedObj.oPosZ - m.pos.z, m.usedObj.oPosX - m.pos.x) or m.faceAngle.y

            set_mario_animation(m, MARIO_ANIM_FIRST_PERSON)
            m.faceAngle.y = goalAngle - approach_f32(s16(goalAngle - m.faceAngle.y), 0, 0x800, 0x800)
            if m.faceAngle.y == goalAngle then
                if m.usedObj then
                    create_dialog_inverted_box(m.usedObj.oBehParams2ndByte)
                end
                m.actionState = 2
            end
        end,
        [2] = function()
            if m.area.camera.cutscene == 0 then
                disable_time_stop()
                set_mario_action(m, ACT_IDLE, 0)
            end
        end,
    })

    vec3f_set(mObj.header.gfx.angle, 0, m.faceAngle.y, 0)
    return 0
end

---@param m MarioState
local act_death_on_back = function(m)
    local s = gPlayerSyncTable[m.playerIndex]
    local deathWarp = s.newAnims and 60 or 54
    local soundFrame = s.newAnims and 48 or 40
    local marioSound = s.newAnims and 14 or 0
    local frame = common_death_handler(m, CHAR_ANIM_DYING_ON_BACK, deathWarp)

    if frame >= marioSound then
        play_character_sound_if_no_flag(m, CHAR_SOUND_DYING, MARIO_ACTION_SOUND_PLAYED)
    end
    if frame == soundFrame then
        play_mario_heavy_landing_sound(m, SOUND_ACTION_TERRAIN_BODY_HIT_GROUND)
    end
    return 0
end

---@param m MarioState
local act_death_on_stomach = function(m)
    local s = gPlayerSyncTable[m.playerIndex]
    local deathWarp = s.newAnims and 64 or 37
    local soundFrame = s.newAnims and 68 or 37
    local soundFrame2 = s.newAnims and 78
    local frame = common_death_handler(m, CHAR_ANIM_DYING_ON_STOMACH, deathWarp)

    play_character_sound_if_no_flag(m, CHAR_SOUND_DYING, MARIO_ACTION_SOUND_PLAYED)

    if frame == soundFrame or frame == soundFrame2 then
        play_mario_heavy_landing_sound(m, SOUND_ACTION_TERRAIN_BODY_HIT_GROUND)
    end
    return 0
end

---@param m MarioState
local act_standing_death = function(m)
    if m.input & INPUT_IN_POISON_GAS ~= 0 then
        return set_mario_action(m, ACT_SUFFOCATION, 0)
    end

    local s = gPlayerSyncTable[m.playerIndex]
    local deathWarp = s.newAnims and 94 or 80
    local landSoundFrame = s.newAnims and 94 or 77
    local landSoundFrame2 = s.newAnims and 104
    local frame = common_death_handler(m, CHAR_ANIM_DYING_FALL_OVER, deathWarp)

    play_character_sound_if_no_flag(m, CHAR_SOUND_DYING, MARIO_ACTION_SOUND_PLAYED)

    if frame == landSoundFrame or frame == landSoundFrame2 then
        play_mario_landing_sound(m, SOUND_ACTION_TERRAIN_BODY_HIT_GROUND)
    elseif s.newAnims and (frame == 19 or frame == 48) then
        if (m.flags & MARIO_METAL_CAP) ~= 0 then
            play_sound_and_spawn_particles(m, SOUND_ACTION_METAL_STEP, 0)
        else
            play_sound_and_spawn_particles(m, SOUND_ACTION_TERRAIN_STEP, 0)
        end
    end

    return 0
end

--- @param m MarioState
local act_into_abyss = function(m)
    local mGfx = m.marioObj.header.gfx

    set_mario_animation(m, MARIO_ANIM_AIRBORNE_ON_STOMACH)

    if m.flags & MARIO_UNKNOWN_18 == 0 then
        play_character_sound(m, CHAR_SOUND_WAAAOOOW)
        m.flags = m.flags | MARIO_UNKNOWN_18
    end

    mario_set_forward_vel(m, m.forwardVel * 0.988)

    m.actionTimer = m.actionTimer + 1

    m.faceAngle.x = m.faceAngle.x + m.angleVel.x
    m.faceAngle.z = m.faceAngle.z + m.angleVel.z

    mGfx.pos.x = mGfx.pos.x + m.vel.x
    m.vel.y = m.vel.y - 4
    mGfx.pos.y = mGfx.pos.y + m.vel.y
    mGfx.pos.z = mGfx.pos.z + m.vel.z

    mGfx.angle.x = m.faceAngle.x
    mGfx.angle.z = m.faceAngle.z

    m.marioBodyState.handState = MARIO_HAND_OPEN

    return 0
end

--- @param m MarioState
local act_frozen_water = function(m)
    local mGfx = m.marioObj.header.gfx

    m.vel.y = approach_f32(m.vel.y, 4, 0.25, 0.25)
    mario_set_forward_vel(m, m.forwardVel * 0.92)

    m.faceAngle.x = approach_f32(m.faceAngle.x, 0, deg_to_hex(0.3), deg_to_hex(0.3))
    m.faceAngle.z = approach_f32(m.faceAngle.z, 0, deg_to_hex(0.3), deg_to_hex(0.3))

    local step = perform_water_step(m)

    if mGfx.angle.x > 0 then
        mGfx.pos.y = mGfx.pos.y + 60 * sins(mGfx.angle.x) * sins(mGfx.angle.x)
        mGfx.angle.x = mGfx.angle.x * 10 / 8
    elseif mGfx.angle.x < 0 then
        mGfx.angle.x = mGfx.angle.x * 6 / 10
    end

    if m.pos.y >= m.waterLevel - 80 then
        m.actionState = m.actionState + 1
        mGfx.pos.y = mGfx.pos.y + 10 * math.sin(m.actionState * 0.08)
        mGfx.angle.z = mGfx.angle.z + deg_to_hex(2) * math.sin(m.actionState * 0.12)
    else
        m.actionState = 0
    end

    local savedPos = m.pos.y
    local savedFakePos = {x = mGfx.pos.x, y = mGfx.pos.y, z = mGfx.pos.z}
    local savedAngle = {x = mGfx.angle.x, y = mGfx.angle.y, z = mGfx.angle.z}
    local savedSpeed = {x = m.vel.x, y = m.vel.y, z = m.vel.z}

    m.actionTimer = m.actionTimer + 1

    if m.actionTimer >= 45 then
        common_death_handler(m, m.marioObj.header.gfx.animInfo.animID, m.marioObj.header.gfx.animInfo.animFrame)
        m.pos.y = savedPos
        vec3f_copy(mGfx.pos, savedFakePos)
        vec3f_copy(mGfx.angle, savedAngle)
        vec3f_copy(m.vel, savedSpeed)
    end

    play_custom_anim(m, "MARIO_ANIM_FROZEN_IN_WATER")

    m.marioBodyState.eyeState = MARIO_EYES_DEAD
    float_surface_gfx(m)
    set_swimming_at_surface_particles(m, PARTICLE_WAVE_TRAIL)

    if step == WATER_STEP_HIT_FLOOR then
        m.vel.y = 0
    end

    return 0
end

--- @param m MarioState
local act_frozen = function(m)
    mario_set_forward_vel(m, m.forwardVel * 0.98)

    local savedPos = m.pos.y
    local savedSpeed = { forward = m.forwardVel, y = m.vel.y }

    m.actionTimer = m.actionTimer + 1

    if m.actionTimer >= 65 then
        common_death_handler(m, m.marioObj.header.gfx.animInfo.animID, m.marioObj.header.gfx.animInfo.animFrame)
        m.pos.y = savedPos
        m.forwardVel = savedSpeed.forward
        m.vel.y = savedSpeed.y
    end

    m.marioBodyState.eyeState = MARIO_EYES_DEAD

    set_mario_animation(m, MARIO_ANIM_FIRE_LAVA_BURN)

    if m.marioObj.header.gfx.animInfo.animFrame >= 25 then
        m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags & ~GRAPH_RENDER_HAS_ANIMATION
    end

    local step = perform_air_step(m, 0)
    if step == AIR_STEP_HIT_WALL then
        mario_bonk_reflection(m, 1)
    elseif step == AIR_STEP_LANDED then
        if m.vel.y <= -20 then
            play_mario_heavy_landing_sound(m, SOUND_ACTION_TERRAIN_BODY_HIT_GROUND)
            m.vel.y = m.vel.y * -0.4
        else
            m.vel.y = 0
            m.pos.y = m.floorHeight
            if not in_between(m.forwardVel, -3, 3, true) then
                play_sound(SOUND_MOVING_TERRAIN_SLIDE + m.terrainSoundAddend, m.marioObj.header.gfx.cameraToObject)
                set_mario_particle_flags(m, PARTICLE_DUST, 0)
            end
        end
    end

    return 0
end

--- @param m MarioState
local act_burnt = function(m)
    local mGfx = m.marioObj.header.gfx
    local mBody = m.marioBodyState
    local animEnd = mGfx.animInfo.curAnim.loopEnd
    local frame = mGfx.animInfo.animFrame
    local maxOpacity = (m.flags & MARIO_VANISH_CAP) ~= 0 and MODEL_STATE_NOISE_ALPHA - 0xFF or 0xFF
    local localCamYaw = gLakituState.oldYaw - 0x8000

    m.faceAngle.y = localCamYaw
    mGfx.angle.y = m.faceAngle.y

    m.actionTimer = m.actionTimer + 1

    play_custom_anim(m, "MARIO_ANIM_BURNT")

    play_character_sound_if_no_flag(m, CHAR_SOUND_WHOA, MARIO_MARIO_SOUND_PLAYED)

    if frame >= 4 then
        mBody.handState = MARIO_HAND_OPEN
    end

    if in_between(frame, 23, 68, false) then
        mBody.eyeState = MARIO_EYES_LOOK_DOWN
    elseif frame <= 1 or in_between(frame, 4, 5, true) or in_between(frame, 68, 69, true) or in_between(frame, 72, 73, true) then
        mBody.eyeState = MARIO_EYES_HALF_CLOSED
    elseif frame < 4 or in_between(frame, 70, 71, true) then
        mBody.eyeState = MARIO_EYES_CLOSED
    else
        mBody.eyeState = MARIO_EYES_OPEN --dont blink
    end

    if m.actionTimer > animEnd + 10 and m.actionState == 0 then
        play_sound_if_no_flag(m, SOUND_OBJ_ENEMY_DEFEAT_SHRINK, MARIO_ACTION_SOUND_PLAYED)
        spawn_non_sync_object(id_bhvAshPile, E_MODEL_ASH_PILE, m.pos.x, m.pos.y, m.pos.z, function(o)
            o.oFaceAngleYaw = localCamYaw
            o.parentObj = m.marioObj
        end)

        m.actionState = m.actionState + 1
        m.actionTimer = 0

    elseif m.actionState == 1 then
        local t = clamp(m.actionTimer / 24, 0, 1)
        m.flags = m.flags | MARIO_TELEPORTING

        if t >= 1 then
            m.actionState = m.actionState + 1
            m.actionTimer = 0
        else
            m.fadeWarpOpacity = lerp(maxOpacity, 0, t)
        end

    elseif m.actionState == 2 then
        m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags | GRAPH_RENDER_INVISIBLE

        if in_between(m.actionTimer, 40, 64) then
            spawn_wind_particles(0, m.faceAngle.y + 0x4000)
            play_sound(SOUND_ENV_WIND2, m.marioObj.header.gfx.cameraToObject)
            spawn_non_sync_object(id_bhvBlackSmokeMario, E_MODEL_BURN_SMOKE, mGfx.pos.x, mGfx.pos.y - 10 * random_float() - 10, mGfx.pos.z,
            function(o)
                o.oBehParams = 2
                o.oMoveAngleYaw = m.faceAngle.y + 0x4000
                o.oForwardVel = 64
            end)

        elseif m.actionTimer >= 20 then
            local savedPos = m.pos.y

            common_death_handler(m, m.marioObj.header.gfx.animInfo.animID, m.marioObj.header.gfx.animInfo.animFrame)
            m.pos.y = savedPos
            m.marioObj.header.gfx.pos.y = savedPos
        end
    end

    return 0
end

hook_mario_action(ACT_BATTLE_STANCE, act_battle_stance)
hook_mario_action(ACT_ROLLOUT_LAND, act_rollout_land)
hook_mario_action(ACT_LOOKING, act_looking)
hook_mario_action(ACT_SQUISHED, act_squished)
hook_mario_action(ACT_READING_SIGN, act_reading_sign)
hook_mario_action(ACT_DEATH_ON_BACK, act_death_on_back)
hook_mario_action(ACT_DEATH_ON_STOMACH, act_death_on_stomach)
hook_mario_action(ACT_STANDING_DEATH, act_standing_death)
hook_mario_action(ACT_INTO_ABYSS, act_into_abyss)
hook_mario_action(ACT_FROZEN_WATER, act_frozen_water)
hook_mario_action(ACT_FROZEN, act_frozen)
hook_mario_action(ACT_BURNT, act_burnt)

-- functions

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

    local pitch = pitch_to_point(m, lookPoint) - m.marioObj.header.gfx.angle.x
    local yaw = angle_to_point(m, lookPoint)
    local castYaw = yaw + m.marioObj.header.gfx.angle.y
    local objDist = dist_between_objects(m.marioObj, o)

    local pos = m.marioBodyState.headPos
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
    if o.activeFlags & ACTIVE_FLAG_DEACTIVATED ~= 0 or o.header.gfx.node.flags & GRAPH_RENDER_ACTIVE == 0 or
    o.header.gfx.node.flags & GRAPH_RENDER_INVISIBLE ~= 0 then
        return false
    end

    return true
end

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
    local lowHpDistort = gSGOLocalSettings.lowHpMusic

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

    if m.capTimer < POWERUP_RAMP_UP_POINT and m.capTimer > 0 and gSGOLocalSettings.powerupMusicRampUp then
        tempoMult = tempoMult + 0.25 * powerUpPentUpLerp
        pitchAdd = pitchAdd + (m.capTimer < POWERUP_RAMP_UP_POINT * 0.75 and 1 or 0)
    end

    if mario_is_crouching(m) and m.action ~= ACT_START_CROUCHING then
        tempoMult = tempoMult * (1 - gSGOLocalSettings.crouchSlowMusic)
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
    if gSGOLocalSettings.vanishEffect == 0 then return end
    -- m.capTimer doesnt sync, so just discard the pent up effect and do the slowest flucutuation on remote players
    local powerUpPentUpLerp = m.playerIndex == 0 and clamp((m.capTimer - 4 * 30) / POWERUP_RAMP_UP_POINT, 0, 1) or 1

    if m.flags & MARIO_VANISH_CAP ~= 0 and m.flags & MARIO_TELEPORTING == 0 then
        local waveSpeed = math.floor(1 + 5 * (1 - powerUpPentUpLerp)) / 10
        m.marioBodyState.modelState = m.marioBodyState.modelState + math.sin(get_global_timer() * waveSpeed) *
        (20 + math.floor(15 * powerUpPentUpLerp)) * gSGOLocalSettings.vanishEffect
    end
end

---@param m MarioState
local woosh_sound_on_jump = function(m)
    if not gSGOLocalSettings.jumpSounds then return end
    local camToObj = m.marioObj.header.gfx.cameraToObject

    if (m.vel.y >= 62 and m.action ~= ACT_SHOT_FROM_CANNON) or (m.action == ACT_LONG_JUMP and m.marioObj.oMarioLongJumpIsSlow == 0) then
        play_sound_with_freq_scale(SOUND_OBJ_UNKNOWN4, camToObj, lerp(0.85, 1.56, clamp((m.vel.y - 62) / 20, 0, 1)))
    end
end

local sFallingHeight = 0

---@param m MarioState
local wind_sound_on_far_fall = function(m)
    if not gSGOLocalSettings.fallSound then return end
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

local sLookObj = nil
local sAttentionTimer = 0

---@param m MarioState
local mario_update = function(m)
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

                s.lookAnglePitch = pitch_to_point(m, lookPoint) - m.marioObj.header.gfx.angle.x - m.marioBodyState.torsoAngle.x * 0.65

                s.lookAngleYaw = angle_to_point(m, lookPoint)
            end
        end

        if gSGOLocalSettings.objLook then
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
            if gSGOLocalSettings.miscThings then
                m.marioObj.header.gfx.shadowInvisible = true
            end
            if (m.action & ACT_GROUP_MASK) ~= ACT_GROUP_CUTSCENE and m.action ~= ACT_BUBBLED and m.floor ~= nil and
            m.pos.y < m.floorHeight + 2048 and m.action ~= ACT_INTO_ABYSS and gSGOLocalSettings.deathScene <= 2 then
                drop_and_set_mario_action(m, ACT_INTO_ABYSS, 0)
            end
        else
            m.marioObj.header.gfx.shadowInvisible = false
        end

        if (m.action == ACT_LAVA_BOOST and m.health <= 0xFF) then
            drop_and_set_mario_action(m, m.area.terrainType & TERRAIN_MASK == TERRAIN_SNOW and ACT_FROZEN or ACT_BURNT, 0)
        end

        if m.controller.buttonDown & Y_BUTTON ~= 0 then
            m.vel.y = 10
        end

        local globalTimer = get_global_timer()
        -- only run this every once in a while for optimization, its not that necessary
        if math_fmod(globalTimer, 30) == 0 and (gSGOLocalSettings.sleepyMusic or sSleepMusic) then
            play_sleep_music(m)
        end

        tempo_and_pitch_distort(m)
        wind_sound_on_far_fall(m)
    end

    spawn_particles_mario_update(m)
    run_animations(m)
    vanish_cap_fluctuate(m)
end

hook_event(HOOK_MARIO_UPDATE, mario_update)

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
    local customDeaths = gSGOLocalSettings.deathScene <= 2

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

hook_event(HOOK_ON_INTERACT, function(m, o)
    if o.oInteractStatus & INT_STATUS_ATTACKED_MARIO ~= 0 and m.flags & MARIO_METAL_CAP == 0 then
        local yaw = mario_obj_angle_to_object(m, o)
        local dmg = o.oDamageOrCoinValue
        if m.flags & MARIO_CAP_ON_HEAD == 0 then
            dmg = dmg + math.floor((dmg + 1) / 2)
        end
        if o.oInteractType ~= INTERACT_SHOCK and gSGOLocalSettings.damageSounds <= 2 then
            audio_sample_play(SOUND_MARIO_HIT, m.pos, 2)
        end
        spawn_hurt_particles(m, yaw, dmg)
    end

    if o.oInteractType == INTERACT_STAR_OR_KEY then
        gNearestStar = nil
        if o.oLightID then
            le_remove_light(o.oLightID)
        end
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
    end
end)

hook_event(HOOK_UPDATE, function()
    handle_scenematics()
    gTalkPrompt = false
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
    if sound == CHAR_SOUND_YAHOO and gSGOLocalSettings.miscThings then
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

sMuteStarSound = false

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