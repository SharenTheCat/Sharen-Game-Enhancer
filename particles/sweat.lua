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