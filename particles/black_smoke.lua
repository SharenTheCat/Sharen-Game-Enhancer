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

    if gSGELocalSettings.newSmoke then
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
    if not gSGELocalSettings.newSmoke then
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