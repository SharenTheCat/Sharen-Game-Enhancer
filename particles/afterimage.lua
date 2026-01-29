---@param o Object
local rainbow_spark_init = function(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE

    o.oAnimState = math.random(0, 7)

    obj_set_billboard(o)
end

---@param o Object
local rainbow_spark_loop = function(o)
    if o.oTimer & 1 ~= 0 then
        o.oAnimState = o.oAnimState + 1
    end

    if o.oTimer >= 3 then
        obj_scale(o, o.header.gfx.scale.x - 0.08)
        if o.header.gfx.scale.x <= 0 then
            obj_mark_for_deletion(o)
        end
    end
end

local id_bhvRainbowSpark = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, rainbow_spark_init, rainbow_spark_loop)

local sRestoreBodyState = nil
gAfterImageData = {}
gSpawnAfterImage = false
local AFTERIMAGE_DURATION = 12

local COLOR_RED = {r = 0xFF, g = 0x40, b = 0x40}
local COLOR_ORANGE = {r = 0xFF, g = 0x66, b = 0x40}
local COLOR_YELLOW = {r = 0xFF, g = 0xC6, b = 0x51}
local COLOR_GREEN = {r = 0x40, g = 0xE2, b = 0x40}
local COLOR_BLUE = {r = 0x4A, g = 0x50, b = 0xFF}
local COLOR_PURPLE = {r = 0xB0, g = 0x40, b = 0xFF}
local SHIFT_DURATION = 6

local COLOR_WHITE = {r = 0xFF, g = 0xFF, b = 0xFF}

local get_rainbow_color = function(time)
    local time = math.fmod(time, SHIFT_DURATION * 6)
    local result = {r = 0, g = 0, b = 0}

    if time < SHIFT_DURATION then
        result = color_lerp(COLOR_RED, COLOR_ORANGE, time / SHIFT_DURATION)

    elseif time < SHIFT_DURATION * 2 then
        result = color_lerp(COLOR_ORANGE, COLOR_YELLOW, (time - SHIFT_DURATION) / SHIFT_DURATION)

    elseif time < SHIFT_DURATION * 3 then
        result = color_lerp(COLOR_YELLOW, COLOR_GREEN, (time - SHIFT_DURATION * 2) / SHIFT_DURATION)

    elseif time < SHIFT_DURATION * 4 then
        result = color_lerp(COLOR_GREEN, COLOR_BLUE, (time - SHIFT_DURATION * 3) / SHIFT_DURATION)

    elseif time < SHIFT_DURATION * 5 then
        result = color_lerp(COLOR_BLUE, COLOR_PURPLE, (time - SHIFT_DURATION * 4) / SHIFT_DURATION)

    elseif time < SHIFT_DURATION * 6 then
        result = color_lerp(COLOR_PURPLE, COLOR_RED, (time - SHIFT_DURATION * 5) / SHIFT_DURATION)
    end

    return result
end

---@param o Object
local afterimage_init = function(o)
    local gfx = o.header.gfx
    local anim = gfx.animInfo
    local ai = gAfterImageData[o.oBehParams]

    o.header.gfx.shadowInvisible = true
    o.hookRender = 1

    vec3f_copy(gfx.pos, ai.pos)
    vec3f_copy(gfx.angle, ai.angle)
    vec3f_copy(gfx.scale, ai.scale)

    if type(ai.animID) == "string" then
        smlua_anim_util_set_animation(o, ai.animID)
    else
        anim.curAnim = get_mario_vanilla_animation(ai.animID)
    end
    anim.animFrame = ai.animFrame
    anim.animFrameAccelAssist = ai.animFrameAccelAssist
    anim.animYTrans = ai.animYTrans
end

---@param o Object
local afterimage_loop = function(o)
    local gfx = o.header.gfx
    local anim = gfx.animInfo
    local ai = gAfterImageData[o.oBehParams]

    anim.animFrame = ai.animFrame
    anim.animFrameAccelAssist = ai.animFrameAccelAssist
    anim.animYTrans = ai.animYTrans

    if not ai or o.oTimer >= AFTERIMAGE_DURATION then
        gAfterImageData[o.oBehParams] = nil
        obj_mark_for_deletion(o)
    end
end

local id_bhvAfterImage = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, afterimage_init, afterimage_loop)

init_afterimage = function(index)
    gAfterImageData[index] = {}
    local ai = gAfterImageData[index]

    ai.pos = {x = 0, y = 0, z = 0}
    ai.angle = {x = 0, y = 0, z = 0}
    ai.scale = {x = 0, y = 0, z = 0}

    ai.torsoAngle = {x = 0, y = 0, z = 0}
    ai.headAngle = {x = 0, y = 0, z = 0}

    local m = gMarioStates[0]
    local mGfx = m.marioObj.header.gfx
    local mBody = m.marioBodyState
    local animName = smlua_anim_util_get_current_animation_name(m.marioObj)

    vec3f_copy(ai.pos, mGfx.pos)
    vec3f_copy(ai.angle, mGfx.angle)
    vec3f_copy(ai.scale, mGfx.scale)

    vec3f_copy(ai.torsoAngle, mBody.torsoAngle)
    vec3f_copy(ai.headAngle, mBody.headAngle)
    if mBody.eyeState == MARIO_EYES_BLINK then
        blinkFrame = (get_area_update_counter() >> 1) & 0x1F
        ai.eyes = ({2, 3, 2, 1, 2, 3, 2})[blinkFrame] or 1
    else
        ai.eyes = mBody.eyeState
    end
    ai.hands = mBody.handState
    ai.cap = mBody.capState
    ai.model = mBody.modelState
    ai.punch = mBody.punchState

    ai.animID = animName and animName or mGfx.animInfo.animID
    ai.animFrame = mGfx.animInfo.animFrame
    ai.animFrameAccelAssist = mGfx.animInfo.animFrameAccelAssist
    ai.animYTrans = mGfx.animInfo.animYTrans
end

local duplicate_vec3 = function(var)
    return {x = var.x, y = var.y, z = var.z}
end

---@param m MarioState
restore_body_state = function(m)
    if sRestoreBodyState then
        local mBody = m.marioBodyState
        local r = sRestoreBodyState

        vec3f_copy(mBody.torsoAngle, r.torsoAngle)
        vec3f_copy(mBody.headAngle, r.headAngle)
        mBody.eyeState = r.eyes
        mBody.handState = r.hands
        mBody.capState = r.cap
        mBody.modelState = r.model
        mBody.punchState = r.punch

        network_player_reset_override_palette(gNetworkPlayers[0])
        set_shade(m, {r = 0xFF / 2, g = 0xFF / 2, b = 0xFF / 2})

        sRestoreBodyState = nil
    end
end

---@param o Object
local render_afterimage = function(o)
    if get_id_from_behavior(o.behavior) ~= id_bhvAfterImage then return end

    local m = gMarioStates[0]
    local mBody = m.marioBodyState
    local ai = gAfterImageData[o.oBehParams]

    if not ai then return end

    sRestoreBodyState = sRestoreBodyState or {
        torsoAngle = duplicate_vec3(mBody.torsoAngle),
        headAngle = duplicate_vec3(mBody.headAngle),
        eyes = mBody.eyeState,
        hands = mBody.handState,
        cap = mBody.capState,
        model = mBody.modelState,
        punch = mBody.punchState,
    }

    vec3s_copy(mBody.torsoAngle, ai.torsoAngle)
    vec3s_copy(mBody.headAngle, ai.headAngle)
    mBody.eyeState = ai.eyes
    mBody.handState = ai.hands
    mBody.capState = ai.cap

    local transparencyMult = 1 - ease_in(o.oTimer / AFTERIMAGE_DURATION, 2)
    if ai.model & 0x100 == 0 then
        mBody.modelState = ai.model + 0x100 + 0xFF * transparencyMult
    else
        local flags = ai.model & MODEL_STATE_METAL ~= 0 and (0x100 | MODEL_STATE_METAL) or 0x100
        mBody.modelState = math.floor((ai.model & ~flags) * transparencyMult) | flags
    end

    mBody.punchState = ai.punch
    if ai.punch & 0x3F > 0 then
        mBody.punchState = ai.punch - 1
    end

    local rainbowColor = get_rainbow_color(get_global_timer() + o.oBehParams * SHIFT_DURATION)

    for i = 0, PLAYER_PART_MAX - 1 do
        local color = color_lerp(gMarioEnhance[0].curPalette[i], rainbowColor, 0.3, 1)
        network_player_set_override_palette_color(gNetworkPlayers[0], i, color)
    end

    local shadeColor = color_lerp(rainbowColor, COLOR_WHITE, 0.2, 1)
    set_shade(m, shadeColor)
end

hook_event(HOOK_ON_OBJECT_RENDER, render_afterimage)

spawn_frame_perfect_particles = function()
    if not gSGELocalSettings.framePerfectEffect then return end
    local m = gMarioStates[0]

    if gSpawnAfterImage then
        if get_global_timer() & 1 == 0 then
            local index = #gAfterImageData + 1

            init_afterimage(index)
            spawn_non_sync_object(id_bhvAfterImage, obj_get_model_id_extended(m.marioObj), m.pos.x, m.pos.y, m.pos.z, function(o)
                o.oBehParams = index
                o.globalPlayerIndex = gNetworkPlayers[0].globalIndex
            end)
        end
        if get_global_timer() & 5 == 0 then
            local xOffset = math.random(-30, 30)
            local yOffset = 100 * random_float()
            local zOffset = math.random(-30, 30)

            spawn_non_sync_object(id_bhvRainbowSpark, E_MODEL_RAINBOW_SPARKLE, m.pos.x + xOffset, m.pos.y + yOffset, m.pos.z + zOffset, function(o)
                obj_scale(o, 0.5 + 0.25 * random_float())
            end)
        end
    end
end