---@param o Object
local drown_bubble_init = function(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE

    bhv_bubble_wave_init()
    obj_set_billboard(o)
    o.oWaterObjUnkFC = o.oWaterObjUnkFC * 2
    o.oWaterObjUnk100 = o.oWaterObjUnk100 * 2
end

---@param o Object
local drown_bubble_loop = function(o)
    o.oForwardVel = o.oForwardVel * 0.84
    cur_obj_move_xz_using_fvel_and_yaw()

    if o.oVelY < -2 then
        o.oVelY = o.oVelY * 0.84
    else
        o.oVelY = o.oVelY + 0.28
    end
    o.oPosY = o.oPosY + o.oVelY

    o.oPosX = o.oPosX - 2.5 + 5 * random_float()
    o.oPosZ = o.oPosZ - 2.5 + 5 * random_float()

    bhv_small_water_wave_loop()
end

id_bhvDrownBubble = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, true, drown_bubble_init, drown_bubble_loop)