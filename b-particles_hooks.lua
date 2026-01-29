require "particles/black_smoke"
require "particles/dust_particles"
require "particles/hurt_star"
require "particles/heal_particles"
require "particles/sweat"
require "particles/wet_droplet"
require "particles/star_shine"
require "particles/lost_powerup"
require "particles/ash_pile"
require "particles/spotlight"
require "particles/afterimage"
require "particles/drown_bubble"

local sFramePerfect = 0

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

    gSpawnAfterImage = false

    if m.action == ACT_AIR_HIT_WALL then
        spawn_wall_particles(m)
    end

    if m.action == ACT_WALL_KICK_AIR then
        if m.prevAction == ACT_AIR_HIT_WALL then
            gSpawnAfterImage = true -- firsties
        end
    end

    if m.action == ACT_FORWARD_ROLLOUT or m.action == ACT_BACKWARD_ROLLOUT or m.action == ACT_JUMP_KICK then
        if sFramePerfect == 1 then
            gSpawnAfterImage = true
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
    if gSpawnedDustTimer > 0 then
        gSpawnedDustTimer = gSpawnedDustTimer - 1
    end
    restore_body_state(m)
    spawn_frame_perfect_particles()
end