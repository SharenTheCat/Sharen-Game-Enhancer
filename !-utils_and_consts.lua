local math_max, math_min, math_floor = math.max, math.min, math.floor

deg_to_hex = function(x)
    if not x then return end
    return x * 0x10000 / 360
end

hex_to_deg = function(x)
    if not x then return end
    return x * 360 / 0x10000
end

clamp = function(x, min, max)
    return math_min(max, math_max(min, x))
end

in_between = function(x, min, max, included)
    if included then
        if x >= min and x <= max then
            return true
        end
    end

    if x > min and x < max then
        return true
    end

    return false
end

s16 = function(x)
    x = (math_floor(x) & 0xFFFF)
    if x >= 32768 then return x - 65536 end
    return x
end

lerp = function(min, max, p)
    return min + (max - min) * p
end

bezier_ease = function(t)
    return t ^ 2 * (3 - 2 * t)
end

ease_in = function(t, pow)
    return t ^ pow
end

ease_out = function(t, pow)
    return 1 - (1 - t) ^ pow
end

ease_in_out_quad = function(t)
    if t < 0.5 then
        return 2 * t ^ 2
    end
    t = t - 0.5
    return 2 * t * (1 - t) + 0.5
end

switch = function(case, table, ...)
    if table[case] then
        return table[case](...)
    else
        return table["default"] and table["default"]() or nil
    end
end

particle_spawn_circle = function(current, total, randOffset)
    local angleOffset = randOffset == 0 and 0 or (random_float() * deg_to_hex(randOffset)) - deg_to_hex(randOffset / 2)
    return deg_to_hex(360) / total * current + angleOffset
end

angle_to_point = function(from, to)
    local a = to.x - from.x
    local c = to.z - from.z

    local angle = atan2s(c, a)

    return angle
end

pitch_to_point = function(from, to)
    local a = to.x - from.x
    local c = to.z - from.z
    a = math.sqrt(a * a + c * c)

    local b = -to.y
    local d = -from.y

    return atan2s(a, b - d)
end

obj_get_slope = function(o)
    local x = sins(o.oMoveAngleYaw) * 5
    local z = coss(o.oMoveAngleYaw) * 5

    o.oFloorHeight = find_floor_height(o.oPosX, o.oPosY, o.oPosZ)

    local frontFloorY = find_floor_height(o.oPosX + x, o.oPosY + 100, o.oPosZ + z)
    local backFloorY = find_floor_height(o.oPosX - x, o.oPosY + 100, o.oPosZ - z)

    local frontFloorDelta = frontFloorY - o.oFloorHeight
    local backFloorDelta = o.oFloorHeight - backFloorY

    if frontFloorDelta ^ 2 < backFloorDelta ^ 2 then
        return atan2s(5, frontFloorDelta)
    else
        return atan2s(5, backFloorDelta)
    end
end

is_mario_invisible = function(m)
    local flags = m.marioObj.header.gfx.node.flags
    if flags & GRAPH_RENDER_INVISIBLE ~= 0 or flags & GRAPH_RENDER_ACTIVE == 0 then
        return true
    end
    return false
end

---@param o Object
is_very_important = function(o)
    if o == nil then return nil end
    if get_id_from_behavior(o.behavior) == bowserKeyNewID or o.oInteractionSubtype & INT_SUBTYPE_GRAND_STAR ~= 0 then
        return true
    end
    return false
end

color_lerp = function(min, max, p, mult)
    local result = {r = 0, g = 0, b = 0}
    if mult == nil then mult = 1 end
    p = clamp(p, 0, 1) * mult

    result.r = math_floor(lerp(min.r, max.r, p))
    result.g = math_floor(lerp(min.g, max.g, p))
    result.b = math_floor(lerp(min.b, max.b, p))

    return result
end

invert_color = function(color)
    local result = {r = 0, g = 0, b = 0}

    result.r = 0xFF - color.r
    result.g = 0xFF - color.g
    result.b = 0xFF - color.b

    return result
end

get_shade = function(m)
    local result = {r = 0, g = 0, b = 0}

    result.r = m.marioBodyState.shadeR
    result.g = m.marioBodyState.shadeG
    result.b = m.marioBodyState.shadeB

    return result
end

set_shade = function(m, color)
    m.marioBodyState.shadeR = color.r
    m.marioBodyState.shadeG = color.g
    m.marioBodyState.shadeB = color.b
end

gNearestStar = nil
gStarDist = 0
gLightDarken = 2
gTalkPrompt = false
gWaitedForLightsOnOtherMods = false

ACT_BATTLE_STANCE = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY | ACT_FLAG_IDLE | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_FLAG_PAUSE_EXIT)
ACT_ROLLOUT_LAND = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_FLAG_PAUSE_EXIT)
ACT_LOOKING = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY | ACT_FLAG_IDLE | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_FLAG_PAUSE_EXIT)
ACT_INTO_ABYSS = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_INTANGIBLE)
ACT_FROZEN_WATER = allocate_mario_action(ACT_GROUP_SUBMERGED | ACT_FLAG_STATIONARY | ACT_FLAG_WATER_OR_TEXT | ACT_FLAG_SWIMMING | ACT_FLAG_SWIMMING_OR_FLYING | ACT_FLAG_INTANGIBLE)
ACT_FROZEN = allocate_mario_action(ACT_GROUP_CUTSCENE | ACT_FLAG_AIR | ACT_FLAG_INTANGIBLE)
ACT_BURNT = allocate_mario_action(ACT_GROUP_CUTSCENE | ACT_FLAG_AIR | ACT_FLAG_INTANGIBLE)

OBJ_LOOKING_RANGE = 1000

TEMPERATURE_MAX_VALUE = 120

DEATH_TEXT_DURATION = 2.1 * 30

STAR_ENV_MAX_DIST = 1200
IMPORTANT_ENV_MAX_DIST = 2000

CELEB_STAR_ACT_JUMP_TO_CENTER = 2
CELEB_STAR_ACT_LEAVE = 3

CUTSCENE_SGE_DEATH = 251

SOUND_CLAPPING = audio_sample_load("clapping.mp3")

E_MODEL_BURN_SMOKE_FIX = smlua_model_util_get_id("burn_smoke_fix_geo")
E_MODEL_SMOKE_TRANSPARENT = smlua_model_util_get_id("smoke_transparency_geo")
E_MODEL_RAINBOW_SPARKLE = smlua_model_util_get_id("rainbow_sparkle_geo")
E_MODEL_LIGHT_RAY = smlua_model_util_get_id("light_ray_geo")
E_MODEL_RAINBOW_RING = smlua_model_util_get_id("light_shine_geo")
E_MODEL_ASH_PILE = smlua_model_util_get_id("ash_pile_geo")
E_MODEL_SPOTLIGHT = smlua_model_util_get_id("spotlight_geo")