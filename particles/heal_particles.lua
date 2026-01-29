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

---@param m MarioState
spawn_heal_particles = function(m)
    if (gSGELocalSettings.hpEffects - 1) & 1 ~= 0 then return end

    if m.healCounter > 0 and (m.health < 0x880 or m.hurtCounter > 0) and m.health > 0xFF then
        spawn_non_sync_object(id_bhvHealEffect, E_MODEL_HEART, m.pos.x, m.pos.y, m.pos.z, function(o)

            o.oMoveAngleYaw = random_float() * deg_to_hex(360)

            o.oVelX = 54 * sins(o.oMoveAngleYaw)
            o.oVelZ = 54 * coss(o.oMoveAngleYaw)

            o.globalPlayerIndex = m.marioObj.globalPlayerIndex
        end)
    end
end