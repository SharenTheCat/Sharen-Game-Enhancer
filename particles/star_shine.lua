---@param o Object
local light_ray_init = function(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE

    o.oAngleVelRoll = deg_to_hex(4)
end

---@param o Object
local light_ray_loop = function(o)
    local percent = o.oTimer / o.oBehParams
    local yOffset = 0
    local scaleMult = 1
    local inBowserLevel = (gNetworkPlayers[0].currLevelNum == LEVEL_BOWSER_1 or gNetworkPlayers[0].currLevelNum == LEVEL_BOWSER_2)

    if get_id_from_behavior(o.parentObj.behavior) == bowserKeyNewID then
        yOffset = 165 / 2
        scaleMult = 2.5
    elseif inBowserLevel then
        yOffset = 165 / 4
        scaleMult = 2.5
    end

    local m = gMarioStates[0]
    o.oFaceAngleYaw = m.area.camera.yaw
    o.oFaceAnglePitch = gLakituState.oldPitch
    o.oFaceAngleRoll = o.oFaceAngleRoll + o.oAngleVelRoll

    o.oPosX = o.parentObj.header.gfx.pos.x
    o.oPosY = o.parentObj.header.gfx.pos.y + 10 * o.parentObj.header.gfx.scale.x - yOffset
    o.oPosZ = o.parentObj.header.gfx.pos.z

    o.oOpacity = 0xA0 * percent + 0x16
    obj_scale(o, 0.5 * percent * o.parentObj.header.gfx.scale.x * scaleMult)

    if o.oSubAction == 0 then
        if percent >= 1 then
            o.oSubAction = 1
        end
    else
        o.oTimer = o.oTimer - 2
        if percent <= 0 then
            o.oSubAction = 0
            o.oBehParams = math.random(20, 80)
        end
    end

    if o.parentObj.activeFlags == ACTIVE_FLAG_DEACTIVATED then
        obj_mark_for_deletion(o)
    end
end

local id_bhvLightRay = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, light_ray_init, light_ray_loop)

---@param o Object
local light_glow_init = function(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    obj_set_billboard(o)
end

---@param o Object
local light_glow_loop = function(o)
    local duration = 40
    local percent = math.sin(o.oTimer * (1 / duration)) * 0.5 + 0.5
    local yOffset = 0
    local scaleMult = 1
    local inBowserLevel = (gNetworkPlayers[0].currLevelNum == LEVEL_BOWSER_1 or gNetworkPlayers[0].currLevelNum == LEVEL_BOWSER_2)

    if get_id_from_behavior(o.parentObj.behavior) == bowserKeyNewID then
        yOffset = 165 / 2
        scaleMult = 2.5
    elseif inBowserLevel then
        yOffset = 165 / 4
        scaleMult = 2.5
    end

    obj_scale(o, (0.75 + 0.25 * percent) * o.parentObj.header.gfx.scale.x * scaleMult)

    o.oOpacity = 0x18 + 0x14 * (1 - percent)

    local m = gMarioStates[0]

    o.oPosX = o.parentObj.header.gfx.pos.x
    o.oPosY = o.parentObj.header.gfx.pos.y - yOffset
    o.oPosZ = o.parentObj.header.gfx.pos.z

    if o.parentObj.activeFlags == ACTIVE_FLAG_DEACTIVATED then
        obj_mark_for_deletion(o)
    end
end

local id_bhvLightGlow = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, light_glow_init, light_glow_loop)

---@param o Object
spawn_rays = function(o)
    local rayCount = 5
    for i = 1, rayCount do
        spawn_non_sync_object(id_bhvLightRay, E_MODEL_LIGHT_RAY, o.header.gfx.pos.x, o.header.gfx.pos.y, o.header.gfx.pos.z, function(ray)
            ray.parentObj = o
            ray.oFaceAngleRoll = particle_spawn_circle(i, rayCount, 0)
            ray.oOpacity = 0
            obj_scale(ray, 0)
            ray.oBehParams = math.random(20, 80)
        end)
    end
    spawn_non_sync_object(id_bhvLightGlow, E_MODEL_RAINBOW_RING, o.header.gfx.pos.x, o.header.gfx.pos.y, o.header.gfx.pos.z, function(ring)
            ring.parentObj = o
    end)
end