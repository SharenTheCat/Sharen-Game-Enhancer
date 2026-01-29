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
        elseif o.oTimer > 7 and floorHeight >= o.oPosY then
            obj_mark_for_deletion(o)
        end
    end
end

id_bhvWetDroplet = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, wet_droplet_init, wet_droplet_loop)