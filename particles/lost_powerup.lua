---@param o Object
local lost_power_init = function(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE

    o.oForwardVel = -16
end

---@param o Object
local lost_power_loop = function(o)
    cur_obj_move_xz_using_fvel_and_yaw()
    o.oVelY = o.oVelY - o.oGravity
    cur_obj_move_y_with_terminal_vel()

    o.oForwardVel = o.oForwardVel * 0.945

    cur_obj_update_floor_height()

    if o.oFloorHeight >= o.oPosY and o.oVelY < 0 then
        o.oVelY = o.oVelY * -0.95
    end

    obj_find_wall(o.oPosX + o.oVelX, o.oPosY, o.oPosZ + o.oVelZ, o.oVelX, o.oVelZ)

    o.oFaceAnglePitch = o.oFaceAnglePitch + deg_to_hex(-35)

    if o.oTimer >= 16 then
        spawn_mist_particles()
        obj_mark_for_deletion(o)
    end
end

local id_bhvLostPowerUp = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, lost_power_init, lost_power_loop)

---@param m MarioState
local get_cap_model = function(m)
    local e = gMarioEnhance[m.playerIndex]
    local c = m.character
    local model = E_MODEL_MARIOS_CAP
    local hadWing = e.prevFlags & MARIO_WING_CAP ~= 0
    local hadMetal = e.prevFlags & MARIO_METAL_CAP ~= 0

    if c.type ~= CT_MARIO then
        model = E_MODEL_LUIGIS_CAP + (c.type - 1) * 5
    end
    if hadWing then
        if c.type == CT_MARIO then
            model = E_MODEL_MARIOS_WING_CAP
        else
            model = model + 2
        end
    end
    if hadMetal then
        if c.type == CT_MARIO then
            if hadWing then
                model = E_MODEL_MARIOS_WINGED_METAL_CAP
            else
                model = E_MODEL_MARIOS_METAL_CAP
            end
        elseif model ~= E_MODEL_TOADS_WING_CAP then
            model = model + 1
        end
    end
    if c.type > 2 then
        model = model - 1
    end
    return model
end

local SOUND_MENU_POWERUP = SOUND_ARG_LOAD(SOUND_BANK_MENU, 0x17, 0xFF, (SOUND_DISCRETE | SOUND_LOWER_BACKGROUND_MUSIC))

local SOUND_MENU_POWERDOWN = SOUND_ARG_LOAD(SOUND_BANK_MENU, 0x16, 0xFF, (SOUND_DISCRETE | SOUND_LOWER_BACKGROUND_MUSIC))

local powerUpGlowTimer = 0

---@param m MarioState
spawn_powerup_particles_and_sounds = function(m)
    local e = gMarioEnhance[m.playerIndex]
    local effectSetting = gSGELocalSettings.powerUpEffects
    local soundSetting = gSGELocalSettings.powerUpSounds

    if ((m.flags & MARIO_SPECIAL_CAPS > e.prevFlags & MARIO_SPECIAL_CAPS) or
    (not e.prevRiddenObj and m.riddenObj and get_id_from_behavior(m.riddenObj.behavior) == koopaShellNewID)) then
        if soundSetting <= 2 then
            play_sound_with_freq_scale(SOUND_MENU_POWERUP, gGlobalSoundSource, 1.3)
        end
        if m.playerIndex == 0 and effectSetting <= 2 then
            powerUpGlowTimer = 90
        end
    end

    if m.playerIndex == 0 and powerUpGlowTimer > 0 then
        if powerUpGlowTimer > 60 or math.fmod(powerUpGlowTimer, 15) == 0 then
            set_mario_particle_flags(m, PARTICLE_SPARKLES, 0)
        end
        powerUpGlowTimer = powerUpGlowTimer - 1
    end

    if m.flags & MARIO_SPECIAL_CAPS < e.prevFlags & MARIO_SPECIAL_CAPS then
        local hadMetal = e.prevFlags & MARIO_METAL_CAP ~= 0
        local hadVanish = e.prevFlags & MARIO_VANISH_CAP ~= 0
        local model = get_cap_model(m)

        if (effectSetting - 1) & 1 == 0 then
            spawn_non_sync_object(id_bhvLostPowerUp, model, m.marioBodyState.headPos.x, m.marioBodyState.headPos.y + 50,
            m.marioBodyState.headPos.z, function(o)
                o.globalPlayerIndex = network_global_index_from_local(m.playerIndex)

                o.oOpacity = hadVanish and 150 or 255
                o.oGravity = hadMetal and 4 or 1.5
                o.oVelY = hadMetal and 36 or 20
            end)
        end

        if (soundSetting - 1) & 1 == 0 then
            play_sound_with_freq_scale(SOUND_MENU_POWERDOWN, gGlobalSoundSource, 1.2)
        end
    end

    if e.prevRiddenObj and not m.riddenObj and get_id_from_behavior(e.prevRiddenObj.behavior) == koopaShellNewID then
        if (effectSetting - 1) & 1 == 0 then
            spawn_non_sync_object(id_bhvLostPowerUp, E_MODEL_KOOPA_SHELL, m.pos.x, m.pos.y + 20, m.pos.z, function(o)
                o.oGravity = 3.4
                o.oVelY = 40
            end)
        end

        if (soundSetting - 1) & 1 == 0 then
            play_sound_with_freq_scale(SOUND_MENU_POWERDOWN, gGlobalSoundSource, 1.2)
        end
    end
end