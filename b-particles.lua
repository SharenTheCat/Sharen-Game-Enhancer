local particle_spawn_circle = function(current, total, randOffset)
    local angleOffset = randOffset == 0 and 0 or (random_float() * deg_to_hex(randOffset)) - deg_to_hex(randOffset / 2)
    return deg_to_hex(360) / total * current + angleOffset
end

---@param o Object
local burn_smoke_init = function(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE

    obj_set_billboard(o)
    o.oGraphYOffset = 50

    if o.oBehParams == 0 then
        cur_obj_set_pos_relative(o.parentObj, 0, 0, -30)
        o.oMoveAngleYaw = (o.parentObj.oMoveAngleYaw + 0x7000) + random_float() * 8192.0
    elseif o.oBehParams == 1 then
        o.oMoveAngleYaw = random_u16()
    else
        obj_translate_xz_random(o, 60)
    end

    if gSGOLocalSettings.newSmoke then
        if o.oBehParams ~= 2 then
            o.oForwardVel = random_float() * 3 + 1
        end
        o.oOpacity = 0xFF
        o.oVelY = math.random(3, 6)

        obj_set_model_extended(o, E_MODEL_BURN_SMOKE_FIX)
    else
        o.oAnimState = 4
        o.oVelY = 8

        if o.oBehParams ~= 2 then
            o.oForwardVel = random_float() * 2 + 0.5
        end
    end
end

---@param o Object
local burn_smoke_loop = function(o)
    if not gSGOLocalSettings.newSmoke then
        if o.oTimer <= 24 then
            o.oPosY  = o.oPosY + o.oVelY
            -- uhhhh... isnt oAngleVelYaw undefnided?
            o.oMoveAngleYaw = o.oMoveAngleYaw + o.oAngleVelYaw
        else
            obj_mark_for_deletion(o)
        end
    else
        o.oPosY = o.oPosY + o.oVelY
        o.oVelY = o.oVelY + random_float()

        if o.oTimer >= 8 then
            obj_scale(o, o.header.gfx.scale.x + 0.05)
            o.oOpacity = o.oOpacity - 0x10
        end

        if o.oOpacity <= 0 then
            obj_mark_for_deletion(o)
        end
    end

    if o.oForwardVel > 0 then
        o.oForwardVel = o.oForwardVel * 0.996
    end

    cur_obj_move_xz_using_fvel_and_yaw()
end

hook_behavior(id_bhvBlackSmokeMario, OBJ_LIST_UNIMPORTANT, true, burn_smoke_init, burn_smoke_loop)

---@param o Object
local land_dust_init = function(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE

    o.oGravity = random_float() * 0.4 + 0.1
    o.oAnimState = 0

    obj_set_billboard(o)
end

---@param o Object
local land_dust_loop = function(o)
    o.oVelX = o.oForwardVel * sins(o.oMoveAngleYaw) * coss(o.oMoveAnglePitch)
    o.oVelY = o.oForwardVel * sins(o.oMoveAnglePitch)
    o.oVelZ = o.oForwardVel * coss(o.oMoveAngleYaw) * coss(o.oMoveAnglePitch)

    o.oFloorHeight = find_floor_height(o.oPosX, o.oPosY, o.oPosZ)

    obj_move_xyz(o, o.oVelX, o.oVelY, o.oVelZ)

    o.oPosY = math.max(o.oPosY, o.oFloorHeight + 5)

    o.oForwardVel = math.max(o.oForwardVel - 1, 0)

    if o.oBehParams == 1 then
        if o.oTimer >= 4 then
            o.oAnimState = o.oAnimState + 1
            obj_scale(o, o.header.gfx.scale.x - 0.2)
            if o.header.gfx.scale.x <= 0 then
                obj_mark_for_deletion(o)
            end
        end
    else
        local scaleGain = o.oBehParams2ndByte == 1 and 0.12 or 0.06
        local opacityLoss = o.oBehParams2ndByte == 1 and 14 or 7
        obj_scale(o, o.header.gfx.scale.x + scaleGain)
        o.oOpacity = o.oOpacity - opacityLoss
        o.oAction = o.oOpacity > 180 and 6 or 6 - math.floor(o.oOpacity / 30)

        if o.oOpacity <= 0 then
            obj_mark_for_deletion(o)
        end
    end
end

--if you use geo_update_layer_transparency, oAnimState stops working, this circunvents that
--its dumb, its stupid, i hate it, yes, but it works
geo_switch_anim_using_action = function(node, matStackIndex)
    local o = geo_get_current_object()
    local n = cast_graph_node(node)

    if o.oAction >= n.parameter then
        o.oAction = 0
    end

    n.selectedCase = o.oAction

    return
end

local id_bhvLandDust = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, land_dust_init, land_dust_loop)

local spawnedDustTimer = 0

---@param o Object
local mist_spawner_init = function(o)
    local m = gMarioStates[o.parentObj.globalPlayerIndex]

    m.marioObj.oActiveParticleFlags = m.marioObj.oActiveParticleFlags & ~ACTIVE_PARTICLE_DUST
    cur_obj_disable_rendering()

    if gSGOLocalSettings.newDust then
        if spawnedDustTimer == 0 then
            spawn_non_sync_object(id_bhvLandDust, E_MODEL_SMOKE_TRANSPARENT, m.pos.x, m.pos.y + 2, m.pos.z, function(smoke)
                local random = random_float()
                local speedFactor = math.min(m.forwardVel, 70)

                if math.abs(speedFactor) >= 50 then
                    smoke.oBehParams2ndByte = 1
                end

                smoke.oMoveAngleYaw = m.faceAngle.y + deg_to_hex(150) + random_float() * deg_to_hex(60)

                smoke.oForwardVel = speedFactor / 4 + 6 * random

                smoke.oOpacity = 80 + math.abs(speedFactor) * random * 1.2

                obj_scale_random(smoke, 0.35, 0.3)
            end)

            if m.playerIndex == 0 then
                spawnedDustTimer = 2
            end
        end
    else
        spawn_non_sync_object(id_bhvWhitePuff1, E_MODEL_MIST, o.oPosX, o.oPosY, o.oPosZ, nil)
        spawn_non_sync_object(id_bhvWhitePuff2, E_MODEL_SMOKE, o.oPosX, o.oPosY, o.oPosZ, nil)
    end

    obj_mark_for_deletion(o)
end

hook_behavior(id_bhvMistParticleSpawner, OBJ_LIST_DEFAULT, true, mist_spawner_init, nil)

---@param o Object
local hurt_star_init = function(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE

    o.oAnimState = 4
    o.oAngleVelRoll = random_float() * deg_to_hex(25) + deg_to_hex(8)
    o.oGravity = 4
end

---@param o Object
local hurt_star_loop = function(o)
    local m = gMarioStates[0]
    o.oFaceAngleYaw = m.area.camera.yaw
    o.oFaceAnglePitch = gLakituState.oldPitch
    o.oFaceAngleRoll = o.oFaceAngleRoll + o.oAngleVelRoll

    cur_obj_move_xz_using_fvel_and_yaw()
    o.oVelY = o.oVelY - o.oGravity
    cur_obj_move_y_with_terminal_vel()

    o.oForwardVel = o.oForwardVel * 0.98

    cur_obj_update_floor_height()

    if o.oFloorHeight >= o.oPosY and o.oVelY < 0 then
        o.oVelY = o.oVelY * -0.8
    end

    obj_find_wall(o.oPosX + o.oVelX, o.oPosY, o.oPosZ + o.oVelZ, o.oVelX, o.oVelZ)

    if o.oTimer >= o.oBehParams then
        obj_scale(o, o.header.gfx.scale.x - 0.05)
        if o.header.gfx.scale.x <= 0 then
            obj_mark_for_deletion(o)
        end
    end
end

local id_bhvHurtStar = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, hurt_star_init, hurt_star_loop)

---@param o Object
local heal_effect_init = function(o)
    local m = gMarioStates[network_local_index_from_global(o.globalPlayerIndex)]
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE

    obj_scale_random(o, 0.3, 0.5)
    o.oGravity = random_float() * 6 + 14
    o.oAngleVelYaw = random_float() * deg_to_hex(15) + deg_to_hex(20)

    o.oPosX = o.oVelX + m.pos.x
    o.oPosY = o.oVelY + m.pos.y
    o.oPosZ = o.oVelZ + m.pos.z

    o.oFaceAnglePitch = 0
    o.oFaceAngleRoll = 0

    o.header.gfx.shadowInvisible = true
end

---@param o Object
local heal_effect_loop = function(o)
    local m = gMarioStates[network_local_index_from_global(o.globalPlayerIndex)]

    o.oPosX = o.oVelX + m.pos.x
    o.oPosY = o.oVelY + m.pos.y
    o.oPosZ = o.oVelZ + m.pos.z

    o.oVelY = o.oVelY + o.oGravity

    o.oFaceAngleYaw = o.oFaceAngleYaw + o.oAngleVelYaw

    if o.oTimer >= 8 then
        obj_scale(o, o.header.gfx.scale.x - 0.1)
        if o.header.gfx.scale.x <= 0 then
            obj_mark_for_deletion(o)
        end
    end
end

local id_bhvHealEffect = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, heal_effect_init, heal_effect_loop)

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

---@param o Object
local bhv_sweat_init = function(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE | OBJ_FLAG_MOVE_XZ_USING_FVEL
    obj_set_billboard(o)

    o.oForwardVel = random_float() * 5 + 5
    o.oVelY = random_float() * 15 + 5
    obj_scale_random(o, 1.5, 0.5)
    o.oMoveAngleYaw = random_u16()
end

---@param o Object
local bhv_sweat_loop = function(o)
    local waterLevel = find_water_level(o.oPosX, o.oPosZ)
    local floorHeight = find_floor_height(o.oPosX, o.oPosY + 15, o.oPosZ)

    o.oVelY = o.oVelY - 4
    o.oPosY = o.oPosY + o.oVelY

    if o.oVelY < 0 then
        if waterLevel > o.oPosY then
            spawn_non_sync_object(id_bhvWaterDropletSplash, E_MODEL_SMALL_WATER_SPLASH, o.oPosX, o.oPosY, o.oPosZ, function(splash)
                vec3f_set(splash.header.gfx.pos, o.oPosX, o.oPosY, o.oPosZ)
            end)

            obj_mark_for_deletion(o)
        elseif o.oTimer > 7 or floorHeight >= o.oPosY then
            obj_mark_for_deletion(o)
        end
    end
end

local id_bhvSweat = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, bhv_sweat_init, bhv_sweat_loop)

---@param o Object
local wet_droplet_init = function(o)
    local m = gMarioStates[network_local_index_from_global(o.globalPlayerIndex)]
    local mGfx = m.marioObj.header.gfx

    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    obj_set_billboard(o)

    obj_scale_random(o, 1.5, 0.5)

    o.oPosX = mGfx.pos.x + o.oVelX
    o.oPosY = mGfx.pos.y + o.oVelY
    o.oPosZ = mGfx.pos.z + o.oVelZ
end

---@param o Object
local wet_droplet_loop = function(o)
    local m = gMarioStates[network_local_index_from_global(o.globalPlayerIndex)]
    local waterLevel = find_water_level(o.oPosX, o.oPosZ)
    local floorHeight = find_floor_height(o.oPosX, o.oPosY + 15, o.oPosZ)
    local mGfx = m.marioObj.header.gfx

    if o.oTimer <= 7 and o.oPosY > mGfx.pos.y and o.oPosY < m.pos.y + 160 then
        o.oGravity = o.oGravity - 0.5

        o.oPosX = mGfx.pos.x + o.oVelX
        o.oPosY = mGfx.pos.y + o.oVelY + o.oGravity
        o.oPosZ = mGfx.pos.z + o.oVelZ
    else
        o.oGravity = o.oGravity - 3

        o.oPosY = o.oPosY + o.oGravity
    end

    if o.oGravity < 0 then
        if waterLevel > o.oPosY then
            spawn_non_sync_object(id_bhvWaterDropletSplash, E_MODEL_SMALL_WATER_SPLASH, o.oPosX, o.oPosY, o.oPosZ, function(splash)
                vec3f_set(splash.header.gfx.pos, o.oPosX, o.oPosY, o.oPosZ)
            end)

            obj_mark_for_deletion(o)
        elseif o.oTimer > 7 or floorHeight >= o.oPosY then
            obj_mark_for_deletion(o)
        end
    end
end

id_bhvWetDroplet = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, wet_droplet_init, wet_droplet_loop)

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
local lost_power_init = function(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE

    o.oForwardVel = -16
end

---@param o Object
local lost_power_loop = function(o)
    cur_obj_move_xz_using_fvel_and_yaw()
    o.oVelY = o.oVelY - o.oGravity
    cur_obj_move_y_with_terminal_vel()

    o.oForwardVel = o.oForwardVel * 0.945

    cur_obj_update_floor_height()

    if o.oFloorHeight >= o.oPosY and o.oVelY < 0 then
        o.oVelY = o.oVelY * -0.95
    end

    obj_find_wall(o.oPosX + o.oVelX, o.oPosY, o.oPosZ + o.oVelZ, o.oVelX, o.oVelZ)

    o.oFaceAnglePitch = o.oFaceAnglePitch + deg_to_hex(-35)

    if o.oTimer >= 16 then
        spawn_mist_particles()
        obj_mark_for_deletion(o)
    end
end

local id_bhvLostPowerUp = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, lost_power_init, lost_power_loop)

---@param o Object
local ash_pile_init = function(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    obj_scale(o, 0.25)
    o.header.gfx.scale.y = 0

    o.activeFlags = o.activeFlags | ACTIVE_FLAG_DITHERED_ALPHA
end

---@param o Object
local ash_pile_loop = function(o)
    local m = gMarioStates[network_local_index_from_global(o.parentObj.globalPlayerIndex)]
    if m.action ~= ACT_BURNT then
        obj_mark_for_deletion(o)
        return
    end

    local maxOpacity = (m.flags & MARIO_VANISH_CAP) ~= 0 and MODEL_STATE_NOISE_ALPHA - 0xFF or 0xFF

    if m.actionState == 1 then
        local t = (m.actionTimer + 1) / 24

        o.oOpacity = math.round(lerp(0, maxOpacity, t))
        o.header.gfx.scale.y = t * 0.25
    elseif m.actionState == 2 and in_between(m.actionTimer, 40, 64) then
        local t = (m.actionTimer - 39) / 24

        o.oOpacity = math.round(lerp(maxOpacity, 0, t))

        if t >= 1 then
            o.header.gfx.node.flags = o.header.gfx.node.flags | GRAPH_RENDER_INVISIBLE
        end
    end
end

id_bhvAshPile = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, ash_pile_init, ash_pile_loop)

local SPOTLIGHT_MAX_DIST = 1080
local SPOTLIGHT_LIGHT_MAX_OFFSET = 175
local SPOTLIGHT_LIGHT_RADIUS = 160
local SPOTLIGHT_LIGHT_MAX_OPACITY = 0x92

gSpotlightLightID = nil

---@param o Object
local spotlight_init = function(o)
    local m = gMarioStates[network_local_index_from_global(o.parentObj.globalPlayerIndex)]
    local mPos = m.pos

    obj_scale(o, 1.8)
    spawn_mist_particles()

    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oGraphYOffset = 40
    gSpotlightLightID = le_add_light(mPos.x, mPos.y + SPOTLIGHT_LIGHT_MAX_OFFSET, mPos.z, 0xFF, 0xFE, 0xCB, SPOTLIGHT_LIGHT_RADIUS, 2.5)
    o.header.gfx.skipInViewCheck = true
end

---@param o Object
local spotlight_loop = function(o)
    local m = gMarioStates[network_local_index_from_global(o.parentObj.globalPlayerIndex)]
    local bubba

    if m.action == ACT_EATEN_BY_BUBBA then
        bubba = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvBubba)
    end

    local mPos = bubba and bubba.header.gfx.pos or m.pos

    local xDif = mPos.x - o.oPosX
    local zDif = mPos.z - o.oPosZ

    local hipo = math.sqrt(xDif ^ 2 + zDif ^ 2)

    o.oFaceAngleYaw = atan2s(zDif, xDif)
    o.oAngleVelPitch = atan2s(hipo, (mPos.y + 80) - (o.oPosY + o.oGraphYOffset))

    local yaw = math.s16(o.oFaceAngleYaw)
    local pitch = math.s16(o.oAngleVelPitch - 0x8000)

    local dist = vec3f_dist(o.header.gfx.pos, mPos)

    if dist > SPOTLIGHT_MAX_DIST then
        local excess = SPOTLIGHT_MAX_DIST - dist
        o.oPosX = o.oPosX + excess * sins(yaw) * coss(pitch)
        o.oPosY = o.oPosY + excess * sins(pitch)
        o.oPosZ = o.oPosZ + excess * coss(yaw) * coss(pitch)
    end

    local offsetValue = math.min(dist, SPOTLIGHT_LIGHT_MAX_OFFSET)

    local offset = {
        x = offsetValue * sins(yaw) * coss(pitch),
        y = offsetValue * sins(pitch),
        z = offsetValue * coss(yaw) * coss(pitch),
    }

    o.oBowserKeyScale = dist / 400
    o.oOpacity = (SPOTLIGHT_LIGHT_MAX_OPACITY + 0x16 * math.sin(get_global_timer() * 0.04)) * math.max(1 - gLightDarken, 0)

    if gSpotlightLightID then
        le_set_light_pos(gSpotlightLightID, mPos.x + offset.x, mPos.y + offset.y, mPos.z + offset.z)
        le_set_light_radius(gSpotlightLightID, SPOTLIGHT_LIGHT_RADIUS * (dist / 400))
        le_set_light_intensity(gSpotlightLightID, o.oOpacity / (SPOTLIGHT_LIGHT_MAX_OPACITY * 0.45))
    end

    if m.health > 0xFF and gDeathActs[m.action] == nil then
        obj_mark_for_deletion(o)
        if gSpotlightLightID then
            le_remove_light(gSpotlightLightID)
        end
        gSpotlightLightID = nil
    end
end

geo_spotlight_rotate = function(node, matStackIndex)
    local o = geo_get_current_object()
    local rotN = cast_graph_node(node.next) ---@type GraphNodeScale

    rotN.rotation.z = o.oAngleVelPitch

    return
end

geo_spotlight_ray_scale = function(node, matStackIndex)
    local o = geo_get_current_object()
    local scaleN = cast_graph_node(node.next) ---@type GraphNodeScale

    scaleN.scale = o.oBowserKeyScale

    return
end

id_bhvSpotlight = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, spotlight_init, spotlight_loop)

local sRestoreBodyState = nil
gAfterImageData = {}
local sSpawnAfterImage = false
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

local init_afterimage = function(index)
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

---@param m MarioState
local restore_body_state = function(m)
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

id_bhvAfterImage = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, afterimage_init, afterimage_loop)

---@param o Object
local vert_star_spawn = function(o)
    if gSGOLocalSettings.newCartoonStars then
        local maxParticles = 6
        local m = gMarioStates[network_local_index_from_global(o.parentObj.globalPlayerIndex)]

        for i = 0, maxParticles - 1 do
            spawn_non_sync_object(id_bhvHurtStar, E_MODEL_CARTOON_STAR, o.oPosX, o.oPosY + 80, o.oPosZ, function(star)
                --small offset to prevent the stars from sometimes getting caught on a wall
                star.oPosX = m.pos.x - 1 * sins(o.oFaceAngleYaw)
                star.oPosZ = m.pos.z - 1 * coss(o.oFaceAngleYaw)

                star.oMoveAnglePitch = particle_spawn_circle(i, maxParticles, 0)

                star.oMoveAngleYaw = m.wall and atan2s(m.wall.normal.z, m.wall.normal.x) + deg_to_hex(110) or m.faceAngle.y + deg_to_hex(90)

                star.oForwardVel = 22 * coss(star.oMoveAnglePitch)
                star.oVelY = 22 * sins(star.oMoveAnglePitch)

                star.oBehParams = 7

                obj_scale(star, 0.25)
            end)
        end
    else
        bhv_tiny_star_particles_init()
    end

    o.parentObj.oActiveParticleFlags = o.parentObj.oActiveParticleFlags & ~ACTIVE_PARTICLE_V_STAR
    obj_mark_for_deletion(o)
end

hook_behavior(id_bhvVertStarParticleSpawner, OBJ_LIST_DEFAULT, true, vert_star_spawn, nil)

---@param o Object
local hor_star_spawn = function(o)
    if gSGOLocalSettings.newCartoonStars then
        local maxParticles = 8
        local m = gMarioStates[(o.parentObj.globalPlayerIndex)]
        local e = gMarioEnhance[m.playerIndex]

        for i = 0, maxParticles - 1 do
            spawn_non_sync_object(id_bhvHurtStar, E_MODEL_CARTOON_STAR, o.oPosX, o.oPosY, o.oPosZ, function(star)
                star.oMoveAngleYaw = particle_spawn_circle(i, maxParticles, 0)

                star.oBehParams = 16

                star.oForwardVel = 16
                star.oVelY = 36

                obj_scale(star, 0.25)
            end)
        end
    else
        o.activeFlags = o.activeFlags | OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
        bhv_pound_tiny_star_particle_init()
    end

    o.parentObj.oActiveParticleFlags = o.parentObj.oActiveParticleFlags & ~ACTIVE_PARTICLE_H_STAR
    obj_mark_for_deletion(o)
end

hook_behavior(id_bhvHorStarParticleSpawner, OBJ_LIST_DEFAULT, true, hor_star_spawn, nil)

---@param m MarioState
local spawn_land_particles = function(m)
    local e = gMarioEnhance[m.playerIndex]

    if m.floorHeight >= m.pos.y then
        if not e.grounded and (m.action & ACT_GROUP_MASK) ~= ACT_GROUP_AUTOMATIC then

            local setting = gSGOLocalSettings.landDust

            if m.peakHeight - m.pos.y > 1150 and should_get_stuck_in_ground(m) == 0 and m.vel.y < -55 and
            m.floor.type ~= SURFACE_BURNING and m.action & ACT_GROUP_MASK ~= ACT_GROUP_SUBMERGED and
            (setting - 1) & 1 == 0 then
                m.particleFlags = m.particleFlags | PARTICLE_HORIZONTAL_STAR
            end

            if setting <= 2 then
                local absVelY = math.abs(m.vel.y)
                local maxParticles = 3 + math.floor(absVelY / 20)

                for i = 0, maxParticles - 1 do
                    local model = 0
                    if m.floor.type == SURFACE_BURNING then
                        model = (m.area.terrainType & TERRAIN_MASK) ~= TERRAIN_SNOW and E_MODEL_RED_FLAME or E_MODEL_BLUE_FLAME
                    else
                        model = E_MODEL_SMOKE_TRANSPARENT
                        if m.pos.y < m.waterLevel - 10 then
                            return
                        end
                    end

                    spawn_non_sync_object(id_bhvLandDust, model, m.pos.x, m.pos.y + 25, m.pos.z, function(o)
                        o.oMoveAngleYaw = particle_spawn_circle(i, maxParticles, 20)

                        o.oMoveAnglePitch = obj_get_slope(o)

                        if m.floor.type == SURFACE_BURNING then
                            o.oBehParams = 1

                            obj_scale_random(o, 0.6, 2.4)

                            o.oForwardVel = 16
                        else
                            o.oOpacity = math.floor(lerp(50, 140, absVelY / 75))

                            o.oForwardVel = random_float() * 6 + lerp(8, 20, absVelY / 75)

                            obj_scale_random(o, lerp(0.3, 0.7, absVelY / 75), absVelY / 225)
                        end
                    end)
                end
            end
        end

        e.grounded = true
    else
        e.grounded = false
    end
end

---@param m MarioState
local spawn_generic_jump_particles = function(m)
    local e = gMarioEnhance[m.playerIndex]

    if m.vel.y - 20 > e.prevVelY and gSGOLocalSettings.jumpDust then
        e.jumpDustTimer = math.floor(m.vel.y / 10)
    end

    if e.jumpDustTimer > 0 then
        if (m.action & ACT_FLAG_AIR) ~= 0 and m.vel.y > 0 then
            local model
            if (m.particleFlags & PARTICLE_FIRE) ~= 0 then
                model = E_MODEL_RED_FLAME
            else
                model = E_MODEL_SMOKE_TRANSPARENT
            end
            spawn_non_sync_object(id_bhvLandDust, model, m.pos.x, m.pos.y + 10, m.pos.z, function(o)
                o.oMoveAngleYaw = random_u16()

                o.oForwardVel = 4

                if (m.particleFlags & PARTICLE_FIRE) ~= 0 then
                    o.oBehParams = 1

                    obj_scale_random(o, 0.2, 0.6 + 0.2 * e.jumpDustTimer)
                else
                    o.oOpacity = 70 + 10 * e.jumpDustTimer

                    obj_scale_random(o, 0.15, 0.25 + 0.05 * e.jumpDustTimer)
                end
            end)
        end

        local loss = m.forwardVel >= 38 and 0.5 or 1

        e.jumpDustTimer = e.jumpDustTimer - loss
    end
end

---@param m MarioState
local spawn_wall_particles = function(m)
    if not gSGOLocalSettings.wallDust then return end
    local e = gMarioEnhance[m.playerIndex]
    local maxParticles = 5

    for i = 0, maxParticles - 1 do
        spawn_non_sync_object(id_bhvLandDust, E_MODEL_SMOKE_TRANSPARENT, m.pos.x, m.pos.y + 80, m.pos.z, function(o)
            o.oMoveAnglePitch = particle_spawn_circle(i, maxParticles, 30)

            o.oMoveAngleYaw = (m.wall and atan2s(m.wall.normal.z, m.wall.normal.x) or m.faceAngle.y) + deg_to_hex(90)

            o.oOpacity = 90

            o.oForwardVel = random_float() * 6 + 12

            obj_scale_random(o, 0.3, 0.5)
        end)
    end
end

---@param m MarioState
local spawn_step_particles = function(m)
    if not gSGOLocalSettings.walkDust then return end
    local frame1, frame2

    switch(m.action, {
        [ACT_WALKING] = function()
            switch(m.actionTimer, {
                [0] = function()
                    frame1, frame2 = 7, 22
                end,
                [1] = function()
                    frame1, frame2 = 14, 72
                end,
                [2] = function()
                    frame1, frame2 = 10, 49
                end,
                [3] = function()
                    frame1, frame2 = 9, 45
                end,
            })
        end,
        [ACT_HOLD_WALKING] = function()
            switch(m.actionTimer, {
                [0] = function()
                    frame1, frame2 = 12, 62
                end,
                [1] = function()
                    frame1, frame2 = 12, 62
                end,
                [2] = function()
                    frame1, frame2 = 10, 49
                end,
            })
        end,
        [ACT_HOLD_HEAVY_WALKING] = function()
            frame1, frame2 = 26, 79
        end
    })

    if not frame1 then return end

    if (is_anim_past_frame(m, frame1) ~= 0 or is_anim_past_frame(m, frame2) ~= 0) then
        set_mario_particle_flags(m, PARTICLE_DUST, 0)
    end
end

local spawn_frame_perfect_particles = function()
    if not gSGOLocalSettings.framePerfectEffect then return end
    local m = gMarioStates[0]

    if sSpawnAfterImage then
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

---@param m MarioState
sweat = function(m, frequency)
    if is_mario_invisible(m) then return end
    if math.fmod(get_global_timer(), frequency) == 0 then
        -- im really picky with this shit i WANT the droplets to spawn from his head and not his neck
        local mBody = m.marioBodyState
        local offset = 40
        local spawnX = mBody.headPos.x + offset * sins(m.faceAngle.y) * coss(mBody.headAngle.x)
        local spawnY = mBody.headPos.y + offset * sins(mBody.headAngle.x)
        local spawnZ = mBody.headPos.z + offset * coss(m.faceAngle.y)  * coss(mBody.headAngle.x)

        spawn_non_sync_object(id_bhvSweat, E_MODEL_WHITE_PARTICLE_SMALL, spawnX, spawnY, spawnZ, nil)
    end
end

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

---@param m MarioState
spawn_hurt_particles = function(m, yaw, count)
    if gSGOLocalSettings.hpEffects > 2 then return end
    if is_mario_invisible(m) then return end

    for i = 1, count do
        spawn_non_sync_object(id_bhvHurtStar, E_MODEL_CARTOON_STAR, m.pos.x, m.pos.y + 45, m.pos.z, function(o)
            o.oForwardVel = 2 * count + 6
            o.oVelY = 42

            o.oMoveAngleYaw = yaw - deg_to_hex(90 / count / 2) * (count - 1) +
            deg_to_hex(90 / count) * (i - 1)

            o.oBehParams = 18

            if count & 1 ~= 0 then
                obj_scale(o, i == math.ceil(count / 2) and 0.35 or 0.22)
            else
                obj_scale(o, 0.28)
            end
        end)
    end
end

---@param m MarioState
local spawn_heal_particles = function(m)
    if (gSGOLocalSettings.hpEffects - 1) & 1 ~= 0 then return end

    if m.healCounter > 0 and (m.health < 0x880 or m.hurtCounter > 0) and m.health > 0xFF then
        spawn_non_sync_object(id_bhvHealEffect, E_MODEL_HEART, m.pos.x, m.pos.y, m.pos.z, function(o)

            o.oMoveAngleYaw = random_float() * deg_to_hex(360)

            o.oVelX = 54 * sins(o.oMoveAngleYaw)
            o.oVelZ = 54 * coss(o.oMoveAngleYaw)

            o.globalPlayerIndex = m.marioObj.globalPlayerIndex
        end)
    end
end

---@param m MarioState
local get_cap_model = function(m)
    local e = gMarioEnhance[m.playerIndex]
    local c = m.character
    local model = E_MODEL_MARIOS_CAP
    local hadWing = e.prevFlags & MARIO_WING_CAP ~= 0
    local hadMetal = e.prevFlags & MARIO_METAL_CAP ~= 0

    if c.type ~= CT_MARIO then
        model = E_MODEL_LUIGIS_CAP + (c.type - 1) * 5
    end
    if hadWing then
        if c.type == CT_MARIO then
            model = E_MODEL_MARIOS_WING_CAP
        else
            model = model + 2
        end
    end
    if hadMetal then
        if c.type == CT_MARIO then
            if hadWing then
                model = E_MODEL_MARIOS_WINGED_METAL_CAP
            else
                model = E_MODEL_MARIOS_METAL_CAP
            end
        elseif model ~= E_MODEL_TOADS_WING_CAP then
            model = model + 1
        end
    end
    if c.type > 2 then
        model = model - 1
    end
    return model
end

local SOUND_MENU_POWERUP = SOUND_ARG_LOAD(SOUND_BANK_MENU, 0x17, 0xFF, (SOUND_DISCRETE | SOUND_LOWER_BACKGROUND_MUSIC))

local SOUND_MENU_POWERDOWN = SOUND_ARG_LOAD(SOUND_BANK_MENU, 0x16, 0xFF, (SOUND_DISCRETE | SOUND_LOWER_BACKGROUND_MUSIC))

local powerUpGlowTimer = 0

---@param m MarioState
local spawn_powerup_particles_and_sounds = function(m)
    local e = gMarioEnhance[m.playerIndex]
    local effectSetting = gSGOLocalSettings.powerUpEffects
    local soundSetting = gSGOLocalSettings.powerUpSounds

    if ((m.flags & MARIO_SPECIAL_CAPS > e.prevFlags & MARIO_SPECIAL_CAPS) or
    (not e.prevRiddenObj and m.riddenObj and get_id_from_behavior(m.riddenObj.behavior) == koopaShellNewID)) then
        if soundSetting <= 2 then
            play_sound_with_freq_scale(SOUND_MENU_POWERUP, gGlobalSoundSource, 1.3)
        end
        if m.playerIndex == 0 and effectSetting <= 2 then
            powerUpGlowTimer = 90
        end
    end

    if m.playerIndex == 0 and powerUpGlowTimer > 0 then
        if powerUpGlowTimer > 60 or math.fmod(powerUpGlowTimer, 15) == 0 then
            set_mario_particle_flags(m, PARTICLE_SPARKLES, 0)
        end
        powerUpGlowTimer = powerUpGlowTimer - 1
    end

    if m.flags & MARIO_SPECIAL_CAPS < e.prevFlags & MARIO_SPECIAL_CAPS then
        local hadMetal = e.prevFlags & MARIO_METAL_CAP ~= 0
        local hadVanish = e.prevFlags & MARIO_VANISH_CAP ~= 0
        local model = get_cap_model(m)

        if (effectSetting - 1) & 1 == 0 then
            spawn_non_sync_object(id_bhvLostPowerUp, model, m.marioBodyState.headPos.x, m.marioBodyState.headPos.y + 50,
            m.marioBodyState.headPos.z, function(o)
                o.globalPlayerIndex = network_global_index_from_local(m.playerIndex)

                o.oOpacity = hadVanish and 150 or 255
                o.oGravity = hadMetal and 4 or 1.5
                o.oVelY = hadMetal and 36 or 20
            end)
        end

        if (soundSetting - 1) & 1 == 0 then
            play_sound_with_freq_scale(SOUND_MENU_POWERDOWN, gGlobalSoundSource, 1.2)
        end
    end

    if e.prevRiddenObj and not m.riddenObj and get_id_from_behavior(e.prevRiddenObj.behavior) == koopaShellNewID then
        if (effectSetting - 1) & 1 == 0 then
            spawn_non_sync_object(id_bhvLostPowerUp, E_MODEL_KOOPA_SHELL, m.pos.x, m.pos.y + 20, m.pos.z, function(o)
                o.oGravity = 3.4
                o.oVelY = 40
            end)
        end

        if (soundSetting - 1) & 1 == 0 then
            play_sound_with_freq_scale(SOUND_MENU_POWERDOWN, gGlobalSoundSource, 1.2)
        end
    end
end

sFramePerfect = 0

---@param m MarioState
spawn_particles_mario_update = function(m)
    if is_mario_invisible(m) then return end

    spawn_land_particles(m)
    spawn_generic_jump_particles(m)
    spawn_step_particles(m)
    spawn_heal_particles(m)
    spawn_powerup_particles_and_sounds(m)

    if m.playerIndex == 0 and m.action == ACT_DIVE_SLIDE then
        sFramePerfect = math.min(sFramePerfect + 1, 2) -- dustless recovers
    end
end

---@param m MarioState
spawn_particles_on_set_act = function(m)
    if is_mario_invisible(m) or m.playerIndex ~= 0 then return end
    local e = gMarioEnhance[m.playerIndex]

    sSpawnAfterImage = false

    if m.action == ACT_AIR_HIT_WALL then
        spawn_wall_particles(m)
    end

    if m.action == ACT_WALL_KICK_AIR then
        if m.prevAction == ACT_AIR_HIT_WALL then
            sSpawnAfterImage = true -- firsties
        end
    end

    if m.action == ACT_FORWARD_ROLLOUT or m.action == ACT_BACKWARD_ROLLOUT or m.action == ACT_JUMP_KICK then
        if sFramePerfect == 1 then
            sSpawnAfterImage = true
            e.animState = 64
        end
    end

    if m.action ~= ACT_MOVE_PUNCHING then
        sFramePerfect = 0
    end
end

---@param m MarioState
spawn_particles_before_update = function(m)
    if is_mario_invisible(m) or m.playerIndex ~= 0 then return end
    if (m.action == ACT_WALKING and m.controller.stickMag <= 48 and m.forwardVel >= 29) then
        sFramePerfect = math.min(sFramePerfect + 1, 2)
    end
    if spawnedDustTimer > 0 then
        spawnedDustTimer = spawnedDustTimer - 1
    end
    restore_body_state(m)
    spawn_frame_perfect_particles()
end

hook_event(HOOK_ON_OBJECT_RENDER, render_afterimage)