local SPOTLIGHT_MAX_DIST = 1080
local SPOTLIGHT_LIGHT_MAX_OFFSET = 175
local SPOTLIGHT_LIGHT_RADIUS = 160
local SPOTLIGHT_LIGHT_MAX_OPACITY = 0xA4

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
    o.oFaceAnglePitch = 0
    o.oFaceAngleRoll = 0
end

---@param o Object
local spotlight_loop = function(o)
    local m = gMarioStates[network_local_index_from_global(o.parentObj.globalPlayerIndex)]
    local bubba

    if m.action == ACT_EATEN_BY_BUBBA then
        bubba = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvBubba)
    end

    local mPos = bubba and bubba.header.gfx.pos or m.marioObj.header.gfx.pos

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

--[[
---@param node GraphNode
geo_spotlight_opacity = function(node, matStackIndex)
    local o = geo_get_current_object()
    local n = cast_graph_node(node)

    local ray = gfx_get_from_name("actor_Light_Ray_mesh_layer_5")
    if not ray then
        return
        djui_chat_message_create("ray not found")
    end

    local color = gfx_get_command(ray, 9)
    djui_chat_message_create(tostring(color))

    n.fnNode.node.flags = 0x500 | (n.fnNode.node.flags & 0xFF)
    gfx_set_command(color, "gsDPSetEnvColor(%i, %i, %i, %i)", 0, 0, 0, o.oOpacity)

    return
end
]]--

id_bhvSpotlight = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, spotlight_init, spotlight_loop)