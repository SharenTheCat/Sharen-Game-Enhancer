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
    local c = m.area.camera
    local pos = gVec3fZero()

    object_pos_to_vec3f(pos, o)

    o.oFaceAngleYaw = angle_to_point(pos, c.pos)
    o.oFaceAnglePitch = pitch_to_point(pos, c.pos)
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
local vert_star_spawn = function(o)
    if gSGELocalSettings.newCartoonStars then
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
    if gSGELocalSettings.newCartoonStars then
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
spawn_hurt_particles = function(m, yaw, count)
    if gSGELocalSettings.hpEffects > 2 then return end
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