-- optimization
local math_min, approach_f32, atan2s, set_anim_to_frame, smlua_anim_util_set_animation, is_anim_past_frame, play_sound, deg_to_hex, clamp, in_between, s16, analog_stick_held_back, sweat, math_abs, math_fmod, math_max, math_floor, math_sin, lerp =
math.min, approach_f32, atan2s, set_anim_to_frame, smlua_anim_util_set_animation, is_anim_past_frame, play_sound, deg_to_hex, clamp, in_between, s16, analog_stick_held_back, sweat, math.abs, math.fmod, math.max, math.floor, math.sin, lerp

-- i dont use the MARIO_ANIM constants here so that i can know which number belongs to which animation in the animations file
local registeredAnims = {
    [194] = true, -- first person
    [195] = true, -- idle 1
    [196] = true, -- idle 2
    [197] = true, -- idle 3
    [114] = true, -- run
    [72] = true, -- walk
    [15] = true, -- skid
    [16] = true, -- skid end
    [188] = true, -- turn around
    [189] = true, -- turn around end
    [77] = true, -- jump
    [78] = true, -- jump land
    [80] = true, -- double jump rise
    [76] = true, -- double jump fall
    [75] = true, -- double jump land
    [193] = true, -- triple jump
    [192] = true, -- triple jump land
    [4] = true, -- backflip
    [191] = true, -- sideflip
    [190] = true, -- sideflip land
    [86] = true, -- freefall
    [87] = true, -- freefall land
    [152] = true, -- crouch
    [150] = true, -- crouch end
    [151] = true, -- crouch start
    [19] = true, -- long jump
    [17] = true, -- long jump land
    [20] = true, -- slow long jump
    [18] = true, -- slow long jump land
    [153] = true, -- crouch waddle (orignally crawling)
    [155] = true, -- crouch waddle start
    [154] = true, -- crouch waddle "end"
    [203] = true, -- wall jump
    [204] = true, -- wall slide
    [103] = true, -- punch 1 start
    [105] = true, -- punch 1 end
    [104] = true, -- punch 2 start
    [106] = true, -- punch 2 end
    [102] = true, -- ground kick
    [79] = true, -- air kick
    [136] = true, -- dive
    [137] = true, -- belly sliding
    [111] = true, -- forward roll
    [112] = true, -- backward roll
    [90] = true, -- dive get up
    [145] = true, -- butt slide
    [143] = true, -- butt slide end
    [144] = true, -- butt slide to freefall
    [60] = true, -- ground pound start
    [61] = true, -- ground pound fall
    [58] = true, -- ground pound land
    [59] = true, -- ground pound flying start
    [140] = true, -- slide kick
    [141] = true, -- slide kick get up
    [83] = true, -- slide kick to freefall
    [116] = true, -- backward low knockback
    [117] = true, -- forward low knockback
    [2] = true, -- backward air knockback
    [45] = true, -- forward air knockback
    [123] = true, -- backward medium knockback
    [138] = true, -- ground bonk (has no animation of its own, reuses animation above)
    [124] = true, -- forward medium knockback
    [1] = true, -- backward hard knockback
    [44] = true, -- forward hard knockback
    [41] = true, -- lava boost
    [40] = true, -- lava boost land
    [51] = true, -- ledge idle
    [52] = true, -- ledge climb fast
    [0] = true, -- ledge climb slow
    [28] = true, -- ledge climb down
    [3] = true, -- death on back
    [46] = true, -- death on stomach
    [71] = true, -- land on shell
    [74] = true, -- jump riding shell
    [109] = true, -- start riding shell
    [50] = true, -- standing death
    [205] = true, -- star dance
    [206] = true, -- star dance end
}

---@param m MarioState
local turn_mario_head_pitch = function(m, angle, min, max)
    local s = gPlayerSyncTable[m.playerIndex]
    local mBody = m.marioBodyState

    mBody.headAngle.x = approach_f32(mBody.headAngle.x, clamp(angle, deg_to_hex(min), deg_to_hex(max)),
    deg_to_hex(12), deg_to_hex(12))

    if not in_between(angle, deg_to_hex(min - 20), deg_to_hex(max + 20), true) then
        if angle < 0 then
            mBody.eyeState = MARIO_EYES_LOOK_UP
        else
            mBody.eyeState = MARIO_EYES_LOOK_DOWN
        end
    end
end

---@param m MarioState
local turn_mario_head_yaw = function(m, angle, min, max)
    local s = gPlayerSyncTable[m.playerIndex]
    local mBody = m.marioBodyState

    mBody.headAngle.y = approach_f32(mBody.headAngle.y, clamp(angle, deg_to_hex(min), deg_to_hex(max)),
    deg_to_hex(12), deg_to_hex(12))

    if not in_between(angle, deg_to_hex(min - 25), deg_to_hex(max + 25), true) then
        if angle < 0 then
            mBody.eyeState = MARIO_EYES_LOOK_LEFT
        else
            mBody.eyeState = MARIO_EYES_LOOK_RIGHT
        end
    end
end

---@param m MarioState
local change_palette_and_shading = function(m)
    if is_mario_invisible(m) then return end
    local e = gMarioEnhance[m.playerIndex]
    local s = gPlayerSyncTable[m.playerIndex]
    local np = gNetworkPlayers[m.playerIndex]
    local globalTimer = get_global_timer()
    local notInLLL = not (level_is_vanilla_level(LEVEL_LLL) and np.currLevelNum == LEVEL_LLL)
    local mGfx = m.marioObj.header.gfx

    local burntActions = {
        [ACT_BURNING_GROUND] = 0,
        [ACT_BURNING_JUMP] = 0,
        [ACT_BURNING_FALL] = 0,
        [ACT_SHOCKED] = 0,
        [ACT_LAVA_BOOST] = (m.area.terrainType & TERRAIN_MASK) ~= TERRAIN_SNOW and 0 or false,
        [ACT_BURNT] = 1,
    }

    -- just do this once to ensure it doesnt fuck over mods that already set the shade
    if not e.resettedShade then
        set_shade(m, {r = 0xFF / 2, g = 0xFF / 2, b = 0xFF / 2})
        e.resettedShade = true
    end

    local curShade = get_shade(m)

    if m.health < 0x300 and gSGOLocalSettings.lowHpTint then
        local sinMult = m.health < 0x200 and 0.1 or 0.06
        local lerpPercent = m.health > 0xFF and math_sin(globalTimer * sinMult) * 0.5 + 0.5 or 1
        curShade = color_lerp(curShade, {r = 0xD0, g = 0x30, b = 0x30}, lerpPercent)

        set_shade(m, curShade)
        e.resettedShade = false
    end

    if (burntActions[m.action] and s.colorBody) or burntActions[m.action] == 1 then
        local add = e.temperature < 0 and 8 or 4
        e.temperature = math_min(e.temperature + add, TEMPERATURE_MAX_VALUE)

    elseif ((m.area.terrainType & TERRAIN_MASK) == TERRAIN_SNOW and
    (m.action == ACT_LAVA_BOOST or (m.action & ACT_GROUP_MASK) == ACT_GROUP_SUBMERGED) and s.colorBody) or m.action == ACT_FROZEN then
        local sub = e.temperature > 0 and 4 or 2
        e.temperature = math_max(e.temperature - sub, -TEMPERATURE_MAX_VALUE)
    else
        local sub = m.waterLevel - m.pos.y >= 50 and 3 or 1
        local add = e.wetLevel >= 0.45 and 0.5 or 1
        e.temperature = approach_f32(e.temperature, 0, add, sub)
    end

    if gSGOLocalSettings.soak then
        local x = m.marioBodyState.headPos.x - mGfx.pos.x
        local z = m.marioBodyState.headPos.z - mGfx.pos.z
        local topDirOffset = 50 * sins(atan2s(math.sqrt(x ^ 2 + z ^ 2), m.marioBodyState.headPos.y - mGfx.pos.y))

        local modelTop = m.marioBodyState.headPos.y + topDirOffset - mGfx.pos.y
        local wetPercentage = (m.waterLevel - mGfx.pos.y) / modelTop

         -- what this and the billion variables above are doing is roughly take your charater's current height and determining how much of their
        -- body has been in water by comparing it to the water level, this means is that for example, more of your body will get soaked if you
        -- crouch while standing in shallow water or if your character is just smaller than mario
        if mGfx.pos.y + (modelTop * e.wetLevel) <= m.waterLevel and notInLLL and m.waterLevel > gLevelValues.floorLowerLimit then
            e.wetLevel = math_max(math_min(wetPercentage, 1), e.wetLevel)
            e.wetTimer = 7 * 30
        elseif e.wetTimer > 0 then
            e.wetTimer = e.wetTimer - 1
        elseif e.wetLevel > 0 then
            e.wetLevel = math_max(e.wetLevel - 0.005, 0)
        end

        if e.wetLevel > 0 and math_fmod(globalTimer, 7) == 0 then
            local spawnYPos = mGfx.pos.y + (modelTop * e.wetLevel) * random_float()
            if spawnYPos > m.waterLevel then
                spawn_non_sync_object(id_bhvWetDroplet, E_MODEL_WHITE_PARTICLE_SMALL, mGfx.pos.x, spawnYPos, mGfx.pos.z, function(o)
                    local offset = random_float() * 10 + 25
                    o.oMoveAngleYaw = random_u16()

                    o.oVelX = offset * sins(o.oMoveAngleYaw)
                    o.oVelY = spawnYPos - m.pos.y
                    o.oVelZ = offset * coss(o.oMoveAngleYaw)

                    o.globalPlayerIndex = gNetworkPlayers[m.playerIndex].globalIndex
                end)
            end
        end
    elseif e.wetLevel > 0 then
        e.wetLevel = 0
        e.wetTimer = 0
    end

    if m.action ~= ACT_SHOCKED and m.action ~= ACT_WATER_SHOCKED then
        if (e.temperature ~= 0 or e.wetLevel > 0) and m.marioBodyState.modelState & MODEL_STATE_METAL == 0 then
            local wetColor = {r = 0, g = 0, b = 0x10}
            local tempColor = {r = 0xBC, g = 0xBC, b = 0xFF}

            if e.temperature > 0 then
                tempColor = {r = 0, g = 0, b = 0}
                local frequency = e.temperature < 30 and 4 or 10
                if math_fmod(globalTimer, frequency) == 0 and m.action ~= ACT_BURNT and m.particleFlags & PARTICLE_FIRE == 0 then
                    spawn_non_sync_object(id_bhvBlackSmokeMario, E_MODEL_BURN_SMOKE, mGfx.pos.x, mGfx.pos.y + 30 * random_float(), mGfx.pos.z,
                    function(o)
                        o.oBehParams = 1
                        o.parentObj = m.marioObj
                    end)
                end
            end

            local wetColorCond = {
                [SHOES] = {min = 0.02, max = 0.08},
                [GLOVES] = {min = 0.4, max = 0.46},
                [PANTS] = {min = 0.1, max = 0.56},
                [SHIRT] = {min = 0.48, max = 0.56},
                [HAIR] = {min = 0.69, max = 0.72},
                [CAP] = {min = 0.91, max = 0.95},
                [EMBLEM] = {min = 0.91, max = 0.95},
            }

            for i = 0, PLAYER_PART_MAX - 1 do
                local color = e.curPalette[i]
                local cond = wetColorCond[i]

                if e.temperature ~= 0 then
                    local max = (m.action == ACT_FROZEN or m.action == ACT_FROZEN_WATER or m.action == ACT_BURNT) and 1 or 0.75
                    color = color_lerp(color, tempColor, math_abs(e.temperature) / 30, max)
                end

                if cond ~= nil and e.wetLevel >= cond.min then
                    local curDif = e.wetLevel - cond.min
                    local maxDif = cond.max - cond.min
                    color = color_lerp(color, wetColor, curDif / maxDif, 0.25)
                end

                network_player_set_override_palette_color(np, i, color)
                local shade = color_lerp(curShade, tempColor, math_abs(e.temperature) / 30, 0.65)
                set_shade(m, shade)
            end
            e.resettedPalette = false
            e.resettedShade = false

        else
            if not e.resettedPalette then
                network_player_reset_override_palette(np)
                e.resettedPalette = true
            elseif math_fmod(globalTimer, 30) == 0 then
                for i = 0, PLAYER_PART_MAX - 1 do
                    e.curPalette[i] = network_player_get_override_palette_color(np, i)
                end
            end
        end
    elseif s.colorBody then
        for i = 0, PLAYER_PART_MAX - 1 do
            color = (globalTimer & 4) ~= 0 and invert_color(e.curPalette[i]) or e.curPalette[i]
            set_shade(m, {r = 0xFF, g = 0xFF, b = 0x40})
            network_player_set_override_palette_color(np, i, color)
            e.resettedPalette = false
            e.resettedShade = false
        end
    end
end

local sAllowFlailAnims = {
    [MARIO_ANIM_SINGLE_JUMP] = true,
    ["JUMP_FALL"] = true,
    ["JUMP_LEFTIE"] = true,
    ["JUMP_FALL_LEFTIE"] = true,
    ["STEEP_JUMP"] = true,
    [MARIO_ANIM_DOUBLE_JUMP_FALL] = true,
    [MARIO_ANIM_TRIPLE_JUMP] = true,
    [MARIO_ANIM_BACKFLIP] = true,
    [MARIO_ANIM_SLIDEFLIP] = true,
    [MARIO_ANIM_SLIDEJUMP] = true,
    ["FIRSTIE"] = true,
    [MARIO_ANIM_FAST_LONGJUMP] = true,
    [MARIO_ANIM_SLOW_LONGJUMP] = true,
    [MARIO_ANIM_GENERAL_FALL] = true,
    [MARIO_ANIM_FALL_FROM_SLIDE] = true,
    [MARIO_ANIM_FALL_FROM_SLIDE_KICK] = true,
    [MARIO_ANIM_AIR_KICK] = true,
}

---@param m MarioState
local handle_body_rotation = function(m, id)
    local s = gPlayerSyncTable[m.playerIndex]
    local e = gMarioEnhance[m.playerIndex]
    local frame = m.marioObj.header.gfx.animInfo.animFrame
    local mBody = m.marioBodyState
    local mGfx = m.marioObj.header.gfx
    local fallDist = m.peakHeight - m.pos.y

    local skipStrafeMove = id == "FAR_FALL"

    local lookOnStrafeActs = {
        [ACT_JUMP] = true,
        [ACT_DOUBLE_JUMP] = true,
        [ACT_TRIPLE_JUMP] = frame >= 28,
        [ACT_BACKFLIP] = frame >= 28,
        [ACT_WALL_KICK_AIR] = true,
        [ACT_LONG_JUMP] = true,
        [ACT_SIDE_FLIP] = frame >= 18,
        [ACT_FREEFALL] = true,
        [ACT_FORWARD_ROLLOUT] = m.actionState == 2,
        [ACT_BACKWARD_ROLLOUT] = m.actionState == 2,
        [ACT_JUMP_KICK] = frame >= 9,
        [ACT_DIVE] = true,
        [ACT_BUTT_SLIDE_AIR] = true,
        [ACT_SLIDE_KICK] = true,
    }

    local lookAnims = {
        [MARIO_ANIM_RUNNING] = true,
        ["FAST_RUN"] = true,
        [MARIO_ANIM_WALKING] = true,
        [MARIO_ANIM_TIPTOE] = true,
        [MARIO_ANIM_START_TIPTOE] = true,
        [MARIO_ANIM_WALK_PANTING] = true,
        [MARIO_ANIM_SKID_ON_GROUND] = true,
        [MARIO_ANIM_TURNING_PART1] = not s.newAnims,
        [MARIO_ANIM_STOP_SKID] = true,
        [MARIO_ANIM_LAND_FROM_SINGLE_JUMP] = true,
        [MARIO_ANIM_LAND_FROM_DOUBLE_JUMP] = true,
        [MARIO_ANIM_GENERAL_LAND] = true,
        [MARIO_ANIM_SLIDEFLIP_LAND] = true,
        [MARIO_ANIM_TRIPLE_JUMP_LAND] = true,
        [MARIO_ANIM_GROUND_POUND_LANDING] = true,
        [MARIO_ANIM_STOP_SLIDE] = true,
        -- this minus one represents actual custom animations, like say, battle stance, or the dive rollout land
        [-1] = m.action == ACT_BATTLE_STANCE or m.action == ACT_ROLLOUT_LAND,
    }

    mBody.allowPartRotation = 1

    if m.action == ACT_SQUISHED then
        return
    end

    local headRotX = 0
    local headRotY = 0
    local headRotZ = 0
    local minAngle = -65
    local maxAngle = 65

    local torsoRotX = 0
    local torsoRotY = 0
    local torsoRotZ = 0
    local torsoRotSpeed = 2

    local intendedDYaw = s16(m.intendedYaw - m.faceAngle.y)

    if s.lookAngleYaw ~= nil and ((m.action == ACT_LOOKING and m.actionArg == 0) or lookAnims[id]) then
        headRotX = s.lookAnglePitch
        headRotY = s.lookAngleYaw
        if m.action == ACT_BATTLE_STANCE and (m.actionArg < 2 or frame < 5) then
            maxAngle = 30
        elseif id == MARIO_ANIM_LAND_FROM_SINGLE_JUMP and frame < 9 then
            minAngle = -18
        end
    elseif ((m.action & ACT_FLAG_BUTT_OR_STOMACH_SLIDE) ~= 0 or m.action == ACT_DIVE_SLIDE or m.action == ACT_SLIDE_KICK_SLIDE) and
    s.newAnims then
        headRotY = atan2s(m.vel.z, m.vel.x) ~= 0 and s16(atan2s(m.vel.z, m.vel.x) - m.faceAngle.y) or 0
    end

    if lookOnStrafeActs[m.action] and s.airStrafeMove then
        if m.action ~= ACT_DIVE then
            if not skipStrafeMove then
                minAngle = (id == MARIO_ANIM_SINGLE_JUMP and frame <= 13) and -15 or -60
                maxAngle = (id == "JUMP_LEFTIE") and 15 or 60
                headRotY = atan2s(m.vel.z, m.vel.x) ~= 0 and s16(atan2s(m.vel.z, m.vel.x) - m.faceAngle.y) or 0
            end

            torsoRotX = math_min(s16(6144 * (m.intendedMag / 32) * coss(intendedDYaw)) * 0.4, 0)
            torsoRotZ = s16(-4096 * (m.intendedMag / 32) * sins(intendedDYaw)) * 0.4

            headRotX = -mBody.torsoAngle.x
            headRotZ = -mBody.torsoAngle.z
        else
            headRotY = atan2s(m.vel.z, m.vel.x) ~= 0 and s16(atan2s(m.vel.z, m.vel.x) - m.faceAngle.y) or 0
            minAngle = -40
            maxAngle = 40

            torsoRotY = s16(-4096 * (m.intendedMag / 32) * sins(intendedDYaw)) * 0.4
        end
    end

    if s.newAnims then
        if m.action == ACT_WALKING and m.actionTimer == 3 then
            torsoRotX = deg_to_hex(12)
            torsoRotSpeed = 1
            if not s.lookAnglePitch or s.lookAnglePitch == 0 then
                headRotX = headRotX - mBody.torsoAngle.x * 0.6
            end

            if m.intendedMag - m.forwardVel > 14 and m.forwardVel - e.prevForwardVel < 0.07 and m.quicksandDepth <= 0 then
                torsoRotX = deg_to_hex(38)
                torsoRotSpeed = e.torsoAngle.x > deg_to_hex(28) and 0.75 or 4.5
                headRotX = deg_to_hex(16)
                headRotY = 0
            elseif m.forwardVel > 33 then
                torsoRotX = 0
                torsoRotSpeed = 3.5
            elseif m.forwardVel < 28 then
                torsoRotX = deg_to_hex(28)
                torsoRotSpeed = 4.5
            end

            m.marioObj.oMarioWalkingPitch = -find_floor_slope(m, 0)
            mGfx.angle.x = m.marioObj.oMarioWalkingPitch + mBody.torsoAngle.x * 0.25

        elseif m.action == ACT_BUTT_SLIDE or m.action == ACT_HOLD_BUTT_SLIDE then
            torsoRotX = s16(5461.3335 * m.intendedMag / 32 * coss(intendedDYaw))
            torsoRotZ = -s16(5461.3335 * m.intendedMag / 32 * sins(intendedDYaw))
            torsoRotSpeed = 7.5

            headRotX = -mBody.torsoAngle.x * 0.45
        elseif m.action == ACT_RIDING_SHELL_GROUND then
            local diffYaw = (m.faceAngle.y - m.twirlYaw)
            local sideAngle = s16(m.faceAngle.y + deg_to_hex(-90))
            local offset = 45

            torsoRotX = -clamp(s16(diffYaw * m.forwardVel / 16), -0x1400, 0x1D00)
            torsoRotY = -torsoRotX
            if not in_between(diffYaw, deg_to_hex(-8), deg_to_hex(8), true) then
                torsoRotSpeed = 5.5
            end

            maxAngle = 20
            headRotX = -mBody.torsoAngle.x * 0.3
            headRotY = -mBody.torsoAngle.y
            headRotZ = -mBody.torsoAngle.x

            mGfx.angle.z = mBody.torsoAngle.x * 0.5

            mGfx.pos.x = m.pos.x + offset * sins(mGfx.angle.z) * sins(sideAngle)
            mGfx.pos.y = m.pos.y + offset * coss(mGfx.angle.z) + m.riddenObj.oGraphYOffset
            mGfx.pos.z = m.pos.z + offset * sins(mGfx.angle.z) * coss(sideAngle)
        elseif id == "FAR_FALL" then
            local angle = (fallDist >= 3000 and m.vel.y < -55) and -30 or 15
            headRotX = deg_to_hex(angle)
        end
    end

    turn_mario_head_yaw(m, headRotY, minAngle, maxAngle)
    turn_mario_head_pitch(m, headRotX, -40, 40)
    mBody.headAngle.z = approach_f32(mBody.headAngle.z, headRotZ, deg_to_hex(12), deg_to_hex(12))

    e.torsoAngle.x = approach_f32(e.torsoAngle.x, torsoRotX, deg_to_hex(torsoRotSpeed), deg_to_hex(torsoRotSpeed))
    e.torsoAngle.y = approach_f32(e.torsoAngle.y, torsoRotY, deg_to_hex(torsoRotSpeed), deg_to_hex(torsoRotSpeed))
    e.torsoAngle.z = approach_f32(e.torsoAngle.z, torsoRotZ, deg_to_hex(torsoRotSpeed), deg_to_hex(torsoRotSpeed))

    if not ((m.action == ACT_WALKING or m.action == ACT_RIDING_SHELL_GROUND) and not s.newAnims) then
        mBody.torsoAngle.x = e.torsoAngle.x
    end
    mBody.torsoAngle.y = e.torsoAngle.y
    if not (m.action == ACT_RIDING_SHELL_GROUND and not s.newAnims) and m.action ~= ACT_WALKING then
        mBody.torsoAngle.z = e.torsoAngle.z
    end
end

---@param m MarioState
local update_mario_body = function(m, id)
    local e = gMarioEnhance[m.playerIndex]
    local s = gPlayerSyncTable[m.playerIndex]
    local frame = m.marioObj.header.gfx.animInfo.animFrame
    local mBody = m.marioBodyState

    local openHandCond = {
        [MARIO_ANIM_SKID_ON_GROUND] = true,
        [MARIO_ANIM_STOP_SKID] = frame < 14,
        [MARIO_ANIM_DOUBLE_JUMP_RISE] = frame >= 2,
        [MARIO_ANIM_DOUBLE_JUMP_FALL] = true,
        [MARIO_ANIM_TRIPLE_JUMP] = not in_between(frame, 14, 20, false),
        [MARIO_ANIM_TRIPLE_JUMP_LAND] = in_between(frame, 4, 33, false),
        [MARIO_ANIM_BACKFLIP] = not in_between(frame, 12, 27, false),
        [MARIO_ANIM_SLIDEFLIP] = not in_between(frame, 9, 16, false),
        [MARIO_ANIM_GENERAL_FALL] = true,
        [MARIO_ANIM_FAST_LONGJUMP] = true,
        [MARIO_ANIM_CROUCH_FROM_FAST_LONGJUMP] = frame < 5,
        [MARIO_ANIM_SLOW_LONGJUMP] = true,
        [MARIO_ANIM_CROUCH_FROM_SLOW_LONGJUMP] = frame < 4,
        [MARIO_ANIM_SLIDEJUMP] = frame <= 4,
        [MARIO_ANIM_START_WALLKICK] = true,
        ["FIRSTIE"] = true,
        [MARIO_ANIM_DIVE] = frame > 3,
        ["NOSEDIVE"] = true,
        [MARIO_ANIM_SLIDE_DIVE] = true,
        ["DIVE_ROLLOUT"] = true,
        ["FAST_RUN"] = true,
        [MARIO_ANIM_SLIDE] = true,
        ["SLIDE_FRONT_NEUTRAL"] = true,
        ["SLIDE_FORWARD"]  = true,
        [MARIO_ANIM_STOP_SLIDE] = frame < 9,
        [MARIO_ANIM_FALL_FROM_SLIDE] = true,
        [MARIO_ANIM_GROUND_POUND_LANDING] = frame >= 3,
        [MARIO_ANIM_TRIPLE_JUMP_GROUND_POUND] = frame <= 3,
        [MARIO_ANIM_SLIDE_KICK] = frame > 7,
        [MARIO_ANIM_CROUCH_FROM_SLIDE_KICK] = frame <= 6,
        [MARIO_ANIM_FALL_FROM_SLIDE_KICK] = true,
        [MARIO_ANIM_SOFT_BACK_KB] = frame < 17,
        [MARIO_ANIM_SOFT_FRONT_KB] = frame < 17,
        [MARIO_ANIM_BACKWARD_AIR_KB] = true,
        [MARIO_ANIM_AIR_FORWARD_KB] = true,
        [MARIO_ANIM_BACKWARD_KB] = frame < 23,
        [MARIO_ANIM_FORWARD_KB] = frame < 24,
        [MARIO_ANIM_FALL_OVER_BACKWARDS] = frame < 36,
        [MARIO_ANIM_LAND_ON_STOMACH] = frame < 19,
        [MARIO_ANIM_STAND_UP_FROM_LAVA_BOOST] = in_between(frame, 1, 9, false),
        [MARIO_ANIM_FAST_LEDGE_GRAB] = in_between(frame, 1, 7, true),
        [MARIO_ANIM_DYING_ON_BACK] = true,
        ["SPEEDKICK"] = frame >= 6,
        [MARIO_ANIM_RIDING_SHELL] = true,
        [MARIO_ANIM_JUMP_RIDING_SHELL] = true,
        ["SHELL_FALL"] = true,
        [MARIO_ANIM_START_RIDING_SHELL] = true,
        ["SHELL_SLOW"] = true,
        ["SOFT_BONK"] = true,
        ["FAR_FALL"] = true,
        [MARIO_ANIM_DYING_FALL_OVER] = frame >= 73,
        ["FREEZE_BOOST"] = frame >= 28,
        ["FREEZE_BOOST_LAND"] = frame < 9,
        ["STEEP_JUMP"] = true,
    }

    local kbEyesCond = {
        [MARIO_ANIM_SOFT_BACK_KB] = frame < 17,
        [MARIO_ANIM_SOFT_FRONT_KB] = frame < 17,
        [MARIO_ANIM_BACKWARD_AIR_KB] = true,
        [MARIO_ANIM_AIR_FORWARD_KB] = true,
        [MARIO_ANIM_BACKWARD_KB] = frame < 16,
        [MARIO_ANIM_FORWARD_KB] = frame < 16,
        [MARIO_ANIM_FALL_OVER_BACKWARDS] = frame < 30,
        [MARIO_ANIM_LAND_ON_STOMACH] = frame < 40,
    }

    if s.newAnims then
        local fallDist = m.peakHeight - m.pos.y

        --hands

        if openHandCond[id] then
            mBody.handState = MARIO_HAND_OPEN

        elseif (id == MARIO_ANIM_FALL_OVER_BACKWARDS and frame < 67) or
        (id == MARIO_ANIM_CLIMB_DOWN_LEDGE and frame < 4) or (id == MARIO_ANIM_DYING_ON_STOMACH and frame >= 40) then
            mBody.handState = MARIO_HAND_RIGHT_OPEN

        elseif id == MARIO_ANIM_STAR_DANCE then
            if in_between(frame, 28, 37, true) then
                mBody.handState = MARIO_HAND_OPEN
            elseif frame >= 56 then
                mBody.handState = MARIO_HAND_PEACE_SIGN
            else
                mBody.handState = MARIO_HAND_FISTS
            end

        elseif (id == MARIO_ANIM_RETURN_FROM_STAR_DANCE and frame <= 2) or id == "STAR_FALL" then
            mBody.handState = MARIO_HAND_PEACE_SIGN
        end

        if (id == MARIO_ANIM_SINGLE_JUMP or id == "JUMP_FALL") and in_between(frame, 3, 13, true) then
            mBody.punchState = (0 << 6) | 3
        elseif (id == "JUMP_LEFTIE" or id == "JUMP_FALL_LEFTIE") and in_between(frame, 3, 13, true) then
            mBody.punchState = (1 << 6) | 3
        end

        if id == MARIO_ANIM_FIRST_PUNCH or id == MARIO_ANIM_SECOND_PUNCH or
        ((id == MARIO_ANIM_GROUND_KICK or id == MARIO_ANIM_AIR_KICK) and frame < 2) then
            mBody.punchState = 0

        elseif id == MARIO_ANIM_FIRST_PUNCH_FAST and frame < 2 then
            mBody.punchState = (0 << 6) | 4
        elseif id == MARIO_ANIM_SECOND_PUNCH_FAST and frame < 2 then
            mBody.punchState = (1 << 6) | 4
        elseif (id == MARIO_ANIM_GROUND_KICK or id == MARIO_ANIM_AIR_KICK) and frame == 2 then
            mBody.punchState = (2 << 6) | 6
        elseif (id == "SPEEDKICK" and frame == 0) then
            mBody.punchState = (2 << 6) | 5
        end

        -- eyes

        if (id == MARIO_ANIM_IDLE_HEAD_RIGHT and in_between(frame, 4, 22, true)) or
        (id == MARIO_ANIM_CROUCHING and in_between(frame, 2, 30, true)) then
            mBody.eyeState = MARIO_EYES_LOOK_LEFT

        elseif id == MARIO_ANIM_TURNING_PART1 or (id == MARIO_ANIM_TURNING_PART2 and frame <= 4) or
        (id == MARIO_ANIM_IDLE_HEAD_LEFT and in_between(frame, 4, 22, true)) or
        (id == MARIO_ANIM_CROUCHING and in_between(frame, 31, 60, true)) or
        (id == MARIO_ANIM_SLIDE_JUMP and frame < 5) or id == MARIO_ANIM_START_WALLKICK then
            mBody.eyeState = MARIO_EYES_LOOK_RIGHT

        elseif id == MARIO_ANIM_GROUND_POUND or
        ((id == MARIO_ANIM_START_GROUND_POUND or id == MARIO_ANIM_TRIPLE_JUMP_GROUND_POUND or id == "GP_BACKWARD") and frame >= 5) or
        (id == MARIO_ANIM_START_RIDING_SHELL and frame < 23) then
            mBody.eyeState = MARIO_EYES_LOOK_DOWN
        end

        if (m.health <= 0xFF and m.action ~= ACT_DROWNING and m.action ~= ACT_BURNT) or
        m.action == ACT_SHOCKED or m.action == ACT_WATER_SHOCKED 
        or (m.action == ACT_SQUISHED and m.actionState > 0) then
            mBody.eyeState = MARIO_EYES_DEAD
        end

        if kbEyesCond[id] then
            if m.actionArg > 0 then
                mBody.eyeState = MARIO_EYES_DEAD
            else
                if id == MARIO_ANIM_LAND_ON_STOMACH or id == MARIO_ANIM_FALL_OVER_BACKWARDS then
                    mBody.eyeState = MARIO_EYES_CLOSED
                else
                    mBody.eyeState = MARIO_EYES_HALF_CLOSED
                end
            end
        else
            switch(id, {
                [MARIO_ANIM_FALL_OVER_BACKWARDS] = function()
                    if frame < 36 then
                        mBody.eyeState = MARIO_EYES_LOOK_LEFT
                    elseif frame < 42 then
                        mBody.eyeState = MARIO_EYES_LOOK_UP
                    elseif frame < 47 then
                        mBody.eyeState = MARIO_EYES_LOOK_RIGHT
                    elseif frame < 52 then
                        mBody.eyeState = MARIO_EYES_LOOK_DOWN
                    elseif in_between(frame, 52, 65, true) then
                        mBody.eyeState = MARIO_EYES_CLOSED
                    end
                end,
                [MARIO_ANIM_FIRE_LAVA_BURN] = function()
                    if frame <= 23 then
                        mBody.eyeState = MARIO_EYES_CLOSED
                    else
                        mBody.eyeState = MARIO_EYES_DEAD
                    end
                end,
                [MARIO_ANIM_SLOW_LEDGE_GRAB] = function()
                    if frame <= 12 then
                        mBody.eyeState = MARIO_EYES_CLOSED
                        sweat(m, 4)
                    end
                end,
                [MARIO_ANIM_DYING_ON_BACK] = function()
                    if frame < 25 then
                        mBody.eyeState = MARIO_EYES_HALF_CLOSED
                    elseif frame < 51 then
                        mBody.eyeState = MARIO_EYES_CLOSED
                    end
                end,
                [MARIO_ANIM_DYING_ON_STOMACH] = function()
                    if frame < 26 then
                        mBody.eyeState = MARIO_EYES_CLOSED
                    elseif frame < 60 then
                        mBody.eyeState = MARIO_EYES_HALF_CLOSED
                    end
                end,
                ["SOFT_BONK"] = function()
                    if frame < 2 then
                        mBody.eyeState = MARIO_EYES_CLOSED
                    elseif frame < 4 then
                        mBody.eyeState = MARIO_EYES_HALF_CLOSED
                    end
                end,
                ["FAR_FALL"] = function()
                    if fallDist >= 3000 and m.vel.y < -55 then
                        mBody.eyeState = MARIO_EYES_CLOSED
                        sweat(m, 8)
                    else
                        mBody.eyeState = MARIO_EYES_LOOK_DOWN
                    end
                end,
                [MARIO_ANIM_DYING_FALL_OVER] = function()
                    if frame <= 4 or in_between(frame, 17, 48, false) or in_between(frame, 69, 90, true) then
                        mBody.eyeState = MARIO_EYES_HALF_CLOSED
                    elseif frame < 90 then
                        mBody.eyeState = MARIO_EYES_CLOSED
                    end
                end,
                ["FREEZE_BOOST"] = function()
                    if frame >= 28 then
                        mBody.eyeState = MARIO_EYES_CLOSED
                    else
                        mBody.eyeState = MARIO_EYES_DEAD
                    end
                end,
            })
        end

        -- lag behind shell in the air

        if m.action == ACT_RIDING_SHELL_JUMP or m.action == m.action == ACT_RIDING_SHELL_FALL then
            m.marioObj.header.gfx.pos.y = m.marioObj.header.gfx.pos.y - math.min(0, m.vel.y) * 0.35
        end
    end

    -- dynamic pitch

    if (m.action == ACT_DIVE or m.action == ACT_SLIDE_KICK) and gSGOLocalSettings.divePitch then
        local min = (e.animState > 0 and frame > 11) and -55 or -30
        local target = clamp(atan2s(m.forwardVel, m.vel.y), deg_to_hex(min), deg_to_hex(30))

        m.faceAngle.x = approach_f32(m.faceAngle.x, target, deg_to_hex(10), deg_to_hex(3))
        m.marioObj.header.gfx.angle.x = -m.faceAngle.x
    end

    -- ground pound fixes

    if gSGOLocalSettings.miscThings then
        if m.action == ACT_GROUND_POUND then
            m.faceAngle.x = approach_f32(m.faceAngle.x, 0, deg_to_hex(6), deg_to_hex(6))
            m.faceAngle.z = approach_f32(m.faceAngle.z, 0, deg_to_hex(6), deg_to_hex(6))

            m.marioObj.header.gfx.angle.x = m.faceAngle.x
            m.marioObj.header.gfx.angle.y = m.faceAngle.y -- fixes the sideflip bug
            m.marioObj.header.gfx.angle.z = m.faceAngle.z
        elseif m.action == ACT_SLIDE_KICK_SLIDE then
            align_with_floor(m)
        end
    end

    if m.action == ACT_SIDE_FLIP and id == "FAR_FALL" then
        m.marioObj.header.gfx.angle.y = m.marioObj.header.gfx.angle.y - 0x8000
    end

    handle_body_rotation(m, id)
    change_palette_and_shading(m)
end

---@param m MarioState
local squash_and_stretch = function(m)
    if gSGOLocalSettings.squashStretch == 0 then return end
    local e = gMarioEnhance[m.playerIndex]
    local scaleFactor = 0

    if m.action & ACT_FLAG_AIR ~= 0 and m.action ~= ACT_FROZEN then
        if not in_between(e.prevVelY, m.vel.y - 12, m.vel.y + 12, true) then
            -- prevent noticeable stutter when doing short hops
            if e.prevVelY / 4 == m.vel.y then
                e.scaleGoal = e.scaleGoal / 2
            else
                e.scaleGoal = math_min(math_abs(m.vel.y), 100)
                if m.vel.y > 0 then
                    e.currScale = 3
                end
            end
        end

        -- jump animations usually have 1 or 2 "prelude" frames where mario is crouched preparing to leap, so we
        -- give mario a squashing period so he stretches just as he actually leaps
        if e.currScale <= 0 then
            scaleFactor = (e.scaleGoal ^ 1.3) * SQUASH_AND_STRETCH_MULT
            e.scaleGoal = approach_f32(e.scaleGoal, 0, 8, 8)
        else
            scaleFactor = -(e.scaleGoal ^ 1.2) * SQUASH_AND_STRETCH_MULT * (e.currScale / 3)
            e.currScale = e.currScale - 1
        end
    elseif m.action & ACT_GROUP_MASK ~= ACT_GROUP_SUBMERGED and m.action & ACT_FLAG_HANGING == 0 then
        e.currScale = approach_f32(e.currScale, e.scaleGoal, 16, 10)

        if e.currScale == e.scaleGoal then
            e.scaleGoal = 0
        end

        scaleFactor = (e.currScale ^ 1.2) * SQUASH_AND_STRETCH_MULT * 0.8

        if m.action & ACT_GROUP_MASK ~= ACT_GROUP_AUTOMATIC then
            scaleFactor = -scaleFactor -- revert the squishing if you hang onto a pole or ledge
        end
    end

    if m.action == ACT_BURNT and m.actionState == 1 then
        m.marioObj.header.gfx.scale.y = 1 - 0.75 * clamp(m.actionTimer / 24, 0, 1)
    elseif m.squishTimer == 0 then
        m.marioObj.header.gfx.scale.x = 1 - scaleFactor * 0.5 * gSGOLocalSettings.squashStretch
        m.marioObj.header.gfx.scale.y = 1 + scaleFactor * gSGOLocalSettings.squashStretch
        m.marioObj.header.gfx.scale.z = 1 - scaleFactor * 0.5 * gSGOLocalSettings.squashStretch
    end
end

---@param m MarioState
local play_sounds_on_anim = function(m, id)
    local frame = m.marioObj.header.gfx.animInfo.animFrame

    local stepSoundCond = {
        [MARIO_ANIM_TRIPLE_JUMP_LAND] = is_anim_past_frame(m, 14) ~= 0,
        [MARIO_ANIM_SLOW_LAND_FROM_DIVE] = is_anim_past_frame(m, 22) ~= 0,
        [MARIO_ANIM_BACKWARD_KB] = is_anim_past_frame(m, 18) ~= 0,
        [MARIO_ANIM_FORWARD_KB] = is_anim_past_frame(m, 22) ~= 0,
        [MARIO_ANIM_SOFT_BACK_KB] = is_anim_past_frame(m, 9) ~= 0,
        [MARIO_ANIM_SOFT_FRONT_KB] = is_anim_past_frame(m, 9) ~= 0,
        [MARIO_ANIM_SLOW_LEDGE_GRAB] = is_anim_past_frame(m, 24) ~= 0 or is_anim_past_frame(m, 32) ~= 0,
        [MARIO_ANIM_RETURN_FROM_STAR_DANCE] = is_anim_past_frame(m, 18) ~= 0 or is_anim_past_frame(m, 30) ~= 0,
    }
    local landSoundCond = {
        [MARIO_ANIM_GROUND_KICK] = is_anim_past_frame(m, 14) ~= 0,
        [MARIO_ANIM_STAND_UP_FROM_LAVA_BOOST] = is_anim_past_frame(m, 7) ~= 0
    }

    local case = {
        [MARIO_ANIM_FALL_OVER_BACKWARDS] = function()
            if is_anim_past_frame(m, 12) ~= 0 then
                play_mario_heavy_landing_sound(m, SOUND_ACTION_TERRAIN_BODY_HIT_GROUND)

            elseif is_anim_past_frame(m, 32) ~= 0 then
                play_character_sound(m, CHAR_SOUND_MAMA_MIA)

            elseif is_anim_past_frame(m, 57) ~= 0 then
                if (m.flags & MARIO_METAL_CAP) ~= 0 then
                    play_sound_and_spawn_particles(m, SOUND_ACTION_METAL_JUMP, 0)
                else
                    play_sound_and_spawn_particles(m, SOUND_ACTION_TERRAIN_JUMP, 0)
                end

                -- fun fact, the hard backward kb action is already set to play this sound at this exact frame
                -- but only does if you died and got kicked back to the castle for some reason lol
            elseif is_anim_past_frame(m, 69) ~= 0 then
                play_mario_landing_sound(m, SOUND_ACTION_TERRAIN_LANDING)
            end
        end,
        [MARIO_ANIM_LAND_ON_STOMACH] = function()
            if in_between(frame, 3, 19, true) and m.forwardVel > 0 then
                play_sound_and_spawn_particles(m, SOUND_MOVING_TERRAIN_SLIDE, 0)
                set_mario_particle_flags(m, PARTICLE_DUST, 0)

            elseif is_anim_past_frame(m, 24) ~= 0 then
                play_mario_heavy_landing_sound(m, SOUND_ACTION_TERRAIN_BODY_HIT_GROUND)

            elseif is_anim_past_frame(m, 56) ~= 0 then
                m.flags = m.flags & ~(MARIO_MARIO_SOUND_PLAYED | MARIO_ACTION_SOUND_PLAYED)
                play_mario_sound(m, SOUND_ACTION_TWIRL, 0)

            elseif is_anim_past_frame(m, 68) ~= 0 then
                play_mario_landing_sound(m, SOUND_ACTION_TERRAIN_LANDING)
            end
        end,
        ["FIRSTIE"] = function()
            if is_anim_past_frame(m, 5) ~= 0 then
                play_sound(SOUND_ACTION_SPIN, m.marioObj.header.gfx.cameraToObject)
            end
        end,
        [MARIO_ANIM_SLIDE_KICK] = function()
            if is_anim_past_frame(m, 5) ~= 0 then
                play_sound(SOUND_ACTION_SPIN, m.marioObj.header.gfx.cameraToObject)
            end
        end,
        [MARIO_ANIM_SLIDE_DIVE] = function()
            if is_anim_past_frame(m, 4) ~= 0 then
                play_mario_landing_sound(m, SOUND_ACTION_TERRAIN_BODY_HIT_GROUND)
            end
        end,
        [MARIO_ANIM_SLOW_LEDGE_GRAB] = function()
            play_character_sound_if_no_flag(m, CHAR_SOUND_EEUH, MARIO_MARIO_SOUND_PLAYED)
        end,
        ["SPEEDKICK"] = function()
            if is_anim_past_frame(m, 2) ~= 0 then
                play_sound(SOUND_ACTION_SPIN, m.marioObj.header.gfx.cameraToObject)
            end
        end,
        [MARIO_ANIM_STAR_DANCE] = function()
            local spinFrames = {
                [17] = 1,
                [24] = 1.29,
                [34] = 0.82,
            }
            --spin
            if spinFrames[frame] then
                play_sound_with_freq_scale(SOUND_ACTION_SPIN, m.marioObj.header.gfx.cameraToObject, spinFrames[frame])
            --peace sign
            elseif is_anim_past_frame(m, 40) ~= 0 then
                play_mario_heavy_landing_sound(m, SOUND_ACTION_TERRAIN_LANDING)
            elseif is_anim_past_frame(m, 50) ~= 0 then
                play_sound_with_freq_scale(SOUND_ACTION_THROW, m.marioObj.header.gfx.cameraToObject, 0.73)
            end
        end,
    }

    if stepSoundCond[id] then
        if (m.flags & MARIO_METAL_CAP) ~= 0 then
            play_sound_and_spawn_particles(m, SOUND_ACTION_METAL_STEP, 0)
        else
            play_sound_and_spawn_particles(m, SOUND_ACTION_TERRAIN_STEP, 0)
        end
    elseif landSoundCond[id] then
        play_mario_heavy_landing_sound(m, SOUND_ACTION_TERRAIN_LANDING)
    else
        switch(id, case)
    end
end

local sSkipReset = {
    ["SPEEDKICK"] = true,
    ["NOSEDIVE"] = true,
    ["SHELL_FALL"] = true,
    ["SHELL_SLOW"] = true,
    ["SLIDE_BACK_NEUTRAL"] = true,
    ["SLIDE_FRONT_NEUTRAL"] = true,
    ["SLIDE_FORWARD"] = true,
    ["SLIDE_BACKWARD"] = true,
    ["STEEP_JUMP"] = true,
    ["JUMP_LEFTIE"] = true,
    ["JUMP_FALL_LEFTIE"] = true,
    ["JUMP_LAND_LEFTIE"] = true,
    ["JUMP_FALL"] = true,
}
sPrevId = -1

---@param m MarioState
run_animations = function(m)
    local e = gMarioEnhance[m.playerIndex]
    local s = gPlayerSyncTable[m.playerIndex]

    local animInfo = m.marioObj.header.gfx.animInfo
    local id = animInfo.animID

    if registeredAnims[id] and s.newAnims then
        local frame = animInfo.animFrame
        local fallDist = m.peakHeight - m.pos.y

        switch(id, {
        [MARIO_ANIM_SINGLE_JUMP] = function()
            if m.action == ACT_BURNING_JUMP then
                m.actionArg = 1
            elseif m.action == ACT_STEEP_JUMP then
                e.animState = 53
            elseif e.animState < 51 then
                if math.s16(gLakituState.yaw - m.faceAngle.y) < 0 then
                    e.animState = 51
                else
                    e.animState = 52
                end
            end

            if e.animState == 51 then
                id = (m.vel.y <= 0 and frame >= 9) and "JUMP_FALL_LEFTIE" or "JUMP_LEFTIE"
            elseif e.animState == 53 then
                id = "STEEP_JUMP"
            elseif (m.vel.y <= 0 and frame >= 9) then
                id = "JUMP_FALL"
            end
        end,
        [MARIO_ANIM_SLIDEJUMP] = function()
            if m.prevAction == ACT_AIR_HIT_WALL and e.animState == 0 then
                e.animState = 1
            end

            if e.animState == 1 then
                id = "FIRSTIE"
            end
        end,
        [MARIO_ANIM_RUNNING] = function()
            local effortValue = m.intendedMag > m.forwardVel and m.intendedMag or m.forwardVel
            local velDivider = m.intendedMag - m.forwardVel > 14 and 3 or 4
            local accel = effortValue / velDivider * 0xF000

            if m.action == ACT_BURNING_GROUND then
                id = "BURN_RUN"
                accel = m.forwardVel / 2.5 * 0x10000
            else
                if m.forwardVel > 33 then
                    id = "FAST_RUN"
                end

                if m.intendedMag - m.forwardVel > 14 and m.forwardVel - e.prevForwardVel < 0.07 and m.quicksandDepth <= 0 then
                    id = "RUN_STRUGGLE"
                    sweat(m, 6)
                    m.marioBodyState.eyeState = MARIO_EYES_CLOSED

                    if e.animState < 50 then
                        e.animState = e.animState + 1
                    else
                        e.animState = 28
                        play_character_sound_offset(m, CHAR_SOUND_PANTING, (math.fmod(math.random(0, 2), 3) << 16))
                    end
                else
                    e.animState = 0
                end
            end

            -- setting the accel directly without the function breaks is_anim_past_frame
            -- likely doesnt matter but idk
            set_mario_anim_with_accel(m, animInfo.animID, accel)
        end,
        [MARIO_ANIM_SLIDE] = function()
            local intendedDYaw = s16(m.intendedYaw - m.faceAngle.y)
            local playBackAnim = analog_stick_held_back(m) ~= 0 and m.intendedMag >= 12
            local playFrontAnim = in_between(intendedDYaw, deg_to_hex(-65), deg_to_hex(65), true) and m.intendedMag >= 12

            if e.animState == 0 then
                if playBackAnim or playFrontAnim then
                    e.animState = 1
                end
            elseif e.animState == 1 then
                set_anim_to_frame(m, frame - 2)
                id = playBackAnim and "SLIDE_BACK_NEUTRAL" or "SLIDE_FRONT_NEUTRAL"

                if frame <= 0 then
                    e.animState = playBackAnim and 2 or 3
                end
            elseif e.animState == 2 then
                id = "SLIDE_BACKWARD"

                if not playBackAnim then
                    e.animState = 4
                end
            elseif e.animState == 3 then
                id = "SLIDE_FORWARD"

                if not playFrontAnim then
                    e.animState = 4
                end
            else
                id = (sPrevId == "SLIDE_BACKWARD" or sPrevId == "SLIDE_BACK_NEUTRAL") and "SLIDE_BACK_NEUTRAL" or "SLIDE_FRONT_NEUTRAL"

                if is_anim_at_end(m) ~= 0 then
                    e.animState = 0
                end
            end
        end,
        [MARIO_ANIM_START_GROUND_POUND] = function()
            if m.prevAction == ACT_BACKFLIP then
                id = "GP_BACKWARD"
            end
        end,
        [MARIO_ANIM_FORWARD_SPINNING] = function()
            --check for rollout action explicitly because omm rolling breaks otherwise lol
            if (m.prevAction == ACT_DIVE_SLIDE or m.prevAction == ACT_STOMACH_SLIDE) and m.action == ACT_FORWARD_ROLLOUT and e.animState == 0 then
                e.animState = 1
            end

            if e.animState == 1 then
                id = "DIVE_ROLLOUT"
                if m.actionState ~= 0 then
                    m.actionState = 1
                end
            end
        end,
        [MARIO_ANIM_GENERAL_FALL] = function()
            if e.animState == 0 then
                if m.action == ACT_BURNING_FALL then
                    e.animState = 1
                elseif m.action == ACT_SOFT_BONK then
                    e.animState = 2
                elseif m.action == ACT_FALL_AFTER_STAR_GRAB then
                    e.animState = 3
                end
            end

            if e.animState == 1 then
                id = MARIO_ANIM_FIRE_LAVA_BURN
            elseif e.animState == 2 then
                id = "SOFT_BONK"
            elseif e.animState == 3 then
                id = "STAR_FALL"
            end
        end,
        [MARIO_ANIM_FIRE_LAVA_BURN] = function()
            if m.area.terrainType == TERRAIN_SNOW then
                id = "FREEZE_BOOST"
            end
            if m.floorHeight >= m.pos.y and m.floor.type == SURFACE_BURNING then
                set_anim_to_frame(m, 0)
            end
        end,
        [MARIO_ANIM_STAND_UP_FROM_LAVA_BOOST] = function()
            if m.area.terrainType == TERRAIN_SNOW then
                id = "FREEZE_BOOST_LAND"
            end
        end,
        [MARIO_ANIM_DIVE] = function()
            if m.playerIndex == 0 then
                if m.action == ACT_DIVE then
                    if e.animState == 1 then
                        id = "NOSEDIVE"
                    elseif (m.pos.y - m.floorHeight > 800 or m.waterLevel > m.floorHeight) and is_anim_at_end(m) ~= 0 and m.vel.y < 20 then
                        e.animState = 1
                    end
                end
            end
        end,
        [MARIO_ANIM_AIR_KICK] = function()
            if e.animState >= 64 then
                id = "SPEEDKICK"
            end
        end,
        [MARIO_ANIM_JUMP_RIDING_SHELL] = function()
            if e.animState == 3 then
                id = "SHELL_FALL"
                if m.vel.y - 20 > e.prevVelY then
                    e.animState = 0
                end
            elseif m.vel.y <= -20 and frame >= 17 then
                e.animState = 3
            end
        end,
        [MARIO_ANIM_RIDING_SHELL] = function()
            if e.animState == 1 then
                id = "SHELL_SLOW"
                if m.forwardVel > 32 or m.intendedMag > 16 then
                    if frame > animInfo.curAnim.loopStart then
                        set_anim_to_frame(m, animInfo.curAnim.loopStart)
                    elseif frame <= 1 then
                        e.animState = 2
                    else
                        set_anim_to_frame(m, frame - 2)
                    end
                end
            else
                if m.intendedMag <= 16 and m.forwardVel <= 32 and is_anim_at_end(m) ~= 0 then
                    e.animState = 1
                end
            end
        end,
        [MARIO_ANIM_START_RIDING_SHELL] = function()
            if e.animState == 1 then
                id = "SHELL_SLOW"
                if m.forwardVel > 32 or m.intendedMag > 16 then
                    if frame > animInfo.curAnim.loopStart then
                        set_anim_to_frame(m, animInfo.curAnim.loopStart)
                    elseif frame <= 1 then
                        e.animState = 2
                    else
                        set_anim_to_frame(m, frame - 2)
                    end
                end
            else
                if m.intendedMag <= 16 and m.forwardVel <= 32 and is_anim_at_end(m) ~= 0 then
                    e.animState = 1
                end
            end
        end,
        [MARIO_ANIM_GROUND_BONK] = function()
            id = MARIO_ANIM_BACKWARD_KB
        end,
        ["FREEZE_BOOST"] = function()
            if m.floorHeight >= m.pos.y and m.floor.type == SURFACE_BURNING then
                set_anim_to_frame(m, 0)
            end
        end,
        [MARIO_ANIM_LAND_FROM_SINGLE_JUMP] = function()
            if e.animState == 51 then
                id = "JUMP_LAND_LEFTIE"
            end
        end,
        })

        if sAllowFlailAnims[id] and fallDist > 950 and m.action & ACT_GROUP_MASK == ACT_GROUP_AIRBORNE then
            local accel = lerp(0x10000, 0x46000, clamp((fallDist - 950) / 2050, 0, 1))
            id = "FAR_FALL"

            animInfo.animAccel = accel
        end

        if (id == MARIO_ANIM_FORWARD_SPINNING or id == MARIO_ANIM_BACKWARD_SPINNING) and not s.fixRoll then
            return
        end

        if sPrevId ~= id and m.playerIndex == 0 then
            sPrevId = id

            local startFrame = 0

            if id == "JUMP_FALL" or id == "JUMP_FALL_LEFTIE" then
                startFrame = 9
            elseif id == MARIO_ANIM_FIRE_LAVA_BURN and m.action == ACT_BURNING_FALL then
                startFrame = 4
            elseif id == MARIO_ANIM_JUMP_RIDING_SHELL and m.action == ACT_RIDING_SHELL_FALL then
                startFrame = 5
            elseif (id == MARIO_ANIM_RIDING_SHELL or id == MARIO_ANIM_START_RIDING_SHELL) and e.animState == 2 then
                startFrame = id == MARIO_ANIM_RIDING_SHELL and 19 or 27
            elseif id == "FAR_FALL" then
                startFrame = 22 -- the reason for this 22 frame start is so that spinning sounds cant play if you fall while triple jumping, for example
            elseif id == "JUMP_LEFTIE" then
                startFrame = 1
            end

            if not sSkipReset[id] then
                e.animState = 0
            end

            frame = startFrame
            prevAnimFrame = frame
            set_anim_to_frame(m, startFrame)
        end

        if id ~= -1 then
            smlua_anim_util_set_animation(m.marioObj, "MARIO_ANIM_" .. id)
        end
        play_sounds_on_anim(m, id)

        if m.action == ACT_HARD_BACKWARD_GROUND_KB and m.health <= 0xFF and frame >= 27 then
            set_mario_action(m, ACT_DEATH_ON_BACK, 0)
        elseif m.action == ACT_HARD_FORWARD_GROUND_KB and m.health <= 0xFF and frame >= 36 then
            set_mario_action(m, ACT_DEATH_ON_STOMACH, 0)
        end

    elseif s.fixRoll and (id == MARIO_ANIM_FORWARD_SPINNING or id == MARIO_ANIM_BACKWARD_SPINNING) then
        smlua_anim_util_set_animation(m.marioObj, "MARIO_ANIM_" .. id)
    end

    update_mario_body(m, id)
    squash_and_stretch(m)
end