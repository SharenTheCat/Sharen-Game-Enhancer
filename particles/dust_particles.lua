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

gSpawnedDustTimer = 0

---@param o Object
local mist_spawner_init = function(o)
    local m = gMarioStates[o.parentObj.globalPlayerIndex]

    m.marioObj.oActiveParticleFlags = m.marioObj.oActiveParticleFlags & ~ACTIVE_PARTICLE_DUST
    cur_obj_disable_rendering()

    if gSGELocalSettings.newDust then
        if gSpawnedDustTimer == 0 then
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
                gSpawnedDustTimer = 2
            end
        end
    else
        spawn_non_sync_object(id_bhvWhitePuff1, E_MODEL_MIST, o.oPosX, o.oPosY, o.oPosZ, nil)
        spawn_non_sync_object(id_bhvWhitePuff2, E_MODEL_SMOKE, o.oPosX, o.oPosY, o.oPosZ, nil)
    end

    obj_mark_for_deletion(o)
end

hook_behavior(id_bhvMistParticleSpawner, OBJ_LIST_DEFAULT, true, mist_spawner_init, nil)

---@param m MarioState
spawn_land_particles = function(m)
    local e = gMarioEnhance[m.playerIndex]

    if m.floorHeight >= m.pos.y then
        if not e.grounded and (m.action & ACT_GROUP_MASK) ~= ACT_GROUP_AUTOMATIC then

            local setting = gSGELocalSettings.landDust

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
spawn_generic_jump_particles = function(m)
    local e = gMarioEnhance[m.playerIndex]

    if m.vel.y - 20 > e.prevVelY and gSGELocalSettings.jumpDust then
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
spawn_wall_particles = function(m)
    if not gSGELocalSettings.wallDust then return end
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
spawn_step_particles = function(m)
    if not gSGELocalSettings.walkDust then return end
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