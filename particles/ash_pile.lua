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