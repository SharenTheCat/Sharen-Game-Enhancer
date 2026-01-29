local SOUND_CRUSHED = audio_sample_load("crushed.mp3")
local SOUND_FROZEN = audio_sample_load("frozen.mp3")
local SOUND_INTO_ABYSS = audio_sample_load("into_abyss.mp3")

---@param m MarioState
local play_custom_anim = function(m, name, accel)
    if not accel then
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

----------------------------------
--------  CUSTOM ACTIONS  --------
----------------------------------

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

---------------------------------
------  OVERRIDEN ACTIONS  ------
---------------------------------

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
            if (gSGELocalSettings.damageSounds - 1) & 1 == 0 then
                audio_sample_play(SOUND_CRUSHED, m.pos, 2)
            end
            if (m.flags & MARIO_METAL_CAP) == 0 and m.invincTimer == 0 then
                m.hurtCounter = m.hurtCounter + ((m.flags & MARIO_CAP_ON_HEAD) ~= 0 and 12 or 18)

                local sound = m.health - m.hurtCounter * 64 < 0x100 and CHAR_SOUND_DYING or CHAR_SOUND_WHOA

                if not gSGELocalSettings.miscThings then
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
                if m.actionTimer == 30 and gSGELocalSettings.miscThings then
                    common_death_handler(m, m.marioObj.header.gfx.animInfo.animID, m.marioObj.header.gfx.animInfo.animFrame)
                elseif not gSGELocalSettings.miscThings then
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

    if gSGELocalSettings.miscThings then
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

    if m.actionArg > 225 and (m.actionArg & 1) ~= 0 and gSGELocalSettings.miscThings then
        m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags & ~GRAPH_RENDER_ACTIVE
    else
        m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags | GRAPH_RENDER_ACTIVE
    end

    if m.actionArg > 300 then
        if m.playerIndex ~= 0 then
            m.health = 0x100
        else
            if gSGELocalSettings.miscThings then
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

hook_mario_action(ACT_BATTLE_STANCE, act_battle_stance)
hook_mario_action(ACT_ROLLOUT_LAND, act_rollout_land)
hook_mario_action(ACT_LOOKING, act_looking)
hook_mario_action(ACT_INTO_ABYSS, act_into_abyss)
hook_mario_action(ACT_FROZEN_WATER, act_frozen_water)
hook_mario_action(ACT_FROZEN, act_frozen)
hook_mario_action(ACT_BURNT, act_burnt)

hook_mario_action(ACT_SQUISHED, act_squished)
hook_mario_action(ACT_READING_SIGN, act_reading_sign)
hook_mario_action(ACT_DEATH_ON_BACK, act_death_on_back)
hook_mario_action(ACT_DEATH_ON_STOMACH, act_death_on_stomach)
hook_mario_action(ACT_STANDING_DEATH, act_standing_death)