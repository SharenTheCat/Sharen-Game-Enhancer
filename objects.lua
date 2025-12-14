---@param o Object
local is_star_collected = function(o)
    if o == nil then return nil end
    local starId = o.oBehParams >> 24
    local currentLevelStarFlags = save_file_get_star_flags(get_current_save_file_num() - 1,

    (gLevelValues.useGlobalStarIds ~= 0 and (starId / 7) - 1 or gNetworkPlayers[0].currCourseNum - 1))

    if currentLevelStarFlags & (1 << (gLevelValues.useGlobalStarIds ~= 0 and math_fmod(starId, 7) or starId)) == 0 then
        return false
    end
    return true
end

local sStarDist = 0

---@param o Object
local spawn_rays_on_spawn = function(o)
    if o == nil then return nil end
    if not is_star_collected(o) or is_very_important(o) then
        o.oActiveParticleFlags = 1
        spawn_rays(o)
        local offset = is_very_important(o) and 200 or 30
        local radius = is_very_important(o) and IMPORTANT_ENV_MAX_DIST or STAR_ENV_MAX_DIST
        o.oLightID = le_add_light(o.oPosX, o.oPosY, o.oPosZ, 0xFF, 0xD0, 0, radius, 4)
    end
end

---@param o Object
local environment_effects = function(o)
    local m = gMarioStates[0]
    local c = gMarioStates[0].area.camera
    local important = is_very_important(o)
    local setting = gSGOLocalSettings.starsDarkenWorld

    if m == nil or c == nil or (setting == 2 and not important) or (setting == 3) or (is_star_collected(o) and get_id_from_behavior(o.behavior) ~= celebStarNewID) then
        return
    end

    local dist = dist_between_objects(m.marioObj, o)
    local distMax = not important and STAR_ENV_MAX_DIST or IMPORTANT_ENV_MAX_DIST

    if o.oLightID then
        local offset = is_very_important(o) and 200 or 30
        le_set_light_pos(o.oLightID, o.oPosX, o.oPosY + offset, o.oPosZ)
    end

    if dist > distMax then
        if gNearestStar == o then gNearestStar = nil end
        return
    end

    if gNearestStar == o then
        sStarDist = dist
    else
        if not gNearestStar or (sStarDist > dist and get_id_from_behavior(gNearestStar.behavior) ~= celebStarNewID) then
            gNearestStar = o
        end
    end
end

---@param o Object
local celeb_star_init = function(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    local level = gNetworkPlayers[0].currLevelNum
    local s

    if o.parentObj then
        o.oMoveAngleYaw = o.parentObj.header.gfx.angle.y + 0x8000
        o.oHomeX = o.parentObj.header.gfx.pos.x
        o.oPosY = o.parentObj.header.gfx.pos.y + 30
        o.oHomeZ = o.parentObj.header.gfx.pos.z
        s = gPlayerSyncTable[network_local_index_from_global(o.parentObj.globalPlayerIndex)]
    end
    if s and s.newAnims then
        o.oCelebStarDiameterOfRotation = 125
        o.oVelY = 0.125
        o.oAngleVelYaw = deg_to_hex(3)
    else
        o.oCelebStarDiameterOfRotation = 100
    end
    if level == LEVEL_BOWSER_1 or level == LEVEL_BOWSER_2 then
        obj_set_model_extended(o, E_MODEL_BOWSER_KEY)
        o.oFaceAnglePitch = 0
        o.oFaceAngleRoll = 49152
        cur_obj_scale(0.1)
        o.oCelebStarUnkF4 = 1
    else
        obj_set_model_extended(o, E_MODEL_STAR)
        o.oFaceAnglePitch = 0
        o.oFaceAngleRoll = 0
        cur_obj_scale(0.4)
        o.oCelebStarUnkF4 = 0
    end

    spawn_rays(o)
    local radius = is_very_important(o) and IMPORTANT_ENV_MAX_DIST or STAR_ENV_MAX_DIST
    o.oLightID = le_add_light(o.oPosX, o.oPosY, o.oPosZ, 0xFF, 0xD0, 0, radius, 4)
end

---@param o Object
local celeb_star_spin_around_mario = function(o)
    local s = o.parentObj and gPlayerSyncTable[network_local_index_from_global(o.parentObj.globalPlayerIndex)]

    if s and s.newAnims then
        o.oVelY = math.min(o.oVelY * 1.16, 12)
        o.oAngleVelYaw = math.min(o.oAngleVelYaw * 1.125, deg_to_hex(47))

        o.oMoveAngleYaw = o.oMoveAngleYaw + o.oAngleVelYaw
        o.oFaceAngleYaw = o.oFaceAngleYaw + o.oAngleVelYaw * 1.2

        o.oCelebStarDiameterOfRotation = o.oCelebStarDiameterOfRotation + 2.5

        cur_obj_scale(0.4 + o.oTimer / 120)

        if o.oTimer == 40 then
            o.oVelY = 26
            o.oAction = CELEB_STAR_ACT_JUMP_TO_CENTER
            o.oHomeX = o.oPosX
            o.oHomeZ = o.oPosZ
            return
        elseif o.oTimer > 12 then
            spawn_non_sync_object(id_bhvCelebrationStarSparkle, E_MODEL_SPARKLES, o.oPosX, o.oPosY, o.oPosZ, nil)
        end
    else
        o.oVelY = 5
        o.oFaceAngleYaw = o.oFaceAngleYaw + 0x1000
        o.oMoveAngleYaw = o.oMoveAngleYaw + 0x2000

        if o.oTimer == 40 then
            o.oAction = CELEB_STAR_ACT_FACE_CAMERA
        elseif o.oTimer < 35 then
            spawn_non_sync_object(id_bhvCelebrationStarSparkle, E_MODEL_SPARKLES, o.oPosX, o.oPosY, o.oPosZ, nil)
            o.oCelebStarDiameterOfRotation = o.oCelebStarDiameterOfRotation + 1
        else
            o.oCelebStarDiameterOfRotation = o.oCelebStarDiameterOfRotation - 20
        end
    end

    o.oPosX = o.oHomeX + sins(o.oMoveAngleYaw) * (o.oCelebStarDiameterOfRotation / 2)
    o.oPosY = o.oPosY + o.oVelY
    o.oPosZ = o.oHomeZ + coss(o.oMoveAngleYaw) * (o.oCelebStarDiameterOfRotation / 2)
end

---@param o Object
local celeb_star_face_camera = function(o)
    local m = o.parentObj and gMarioStates[network_local_index_from_global(o.parentObj.globalPlayerIndex)]
    local s = m and gPlayerSyncTable[network_local_index_from_global(m.playerIndex)]
    local playNewAnim = s and s.newAnims

    if playNewAnim then
        if o.oTimer <= 2 then
            cur_obj_scale(0.45 + 0.6 * o.oTimer / 3)
        elseif o.oTimer <= 17 then
            cur_obj_scale(1.05 - 0.35 * ease_out((o.oTimer - 3) / 14, 2))
        end

        if o.oTimer < 10 then
            spawn_non_sync_object(id_bhvSparkleSpawn, E_MODEL_NONE, o.oPosX, o.oPosY - 20, o.oPosZ, nil)
        end

        o.activeFlags = o.activeFlags | ACTIVE_FLAG_INITIATED_TIME_STOP

        if o.oTimer >= 30 and m.action ~= ACT_STAR_DANCE_EXIT and m.action ~= ACT_STAR_DANCE_NO_EXIT and m.action ~= ACT_STAR_DANCE_WATER then
            o.oVelY = -10
            o.oAngleVelYaw = deg_to_hex(-16)
            o.oAction = CELEB_STAR_ACT_LEAVE
        end
    else
        if o.oTimer < 10 then
            if o.oCelebStarUnkF4 == 0 then
                cur_obj_scale(o.oTimer / 10)
            else
                cur_obj_scale(o.oTimer / 30)
            end
            o.oFaceAngleYaw = o.oFaceAngleYaw + 0x1000
        elseif o.parentObj then
            o.oFaceAngleYaw = o.parentObj.header.gfx.angle.y
        end

        if o.oTimer == 59 then
            obj_mark_for_deletion(o)
        end
    end
end

---@param o Object
local celeb_star_jump_to_center = function(o)
    local offset = 25
    local marioGfx = o.parentObj.header.gfx
    local goalPos = {x = marioGfx.pos.x - offset * sins(marioGfx.angle.y), z = marioGfx.pos.z - offset * coss(marioGfx.angle.y)}
    local duration = 12

    if o.oTimer <= duration then
        o.oVelY = o.oVelY - 3.78
        o.oPosY = o.oPosY + o.oVelY

        o.oPosX = lerp(o.oHomeX, goalPos.x, o.oTimer / duration)
        o.oPosZ = lerp(o.oHomeZ, goalPos.z, o.oTimer / duration)

        o.oAngleVelYaw = o.oAngleVelYaw - deg_to_hex(2.2)
        o.oFaceAngleYaw = o.oFaceAngleYaw + o.oAngleVelYaw

        cur_obj_scale(0.7 - 0.25 * ease_in(o.oTimer / duration, 2))

        spawn_non_sync_object(id_bhvSparkleSpawn, E_MODEL_NONE, o.oPosX, o.oPosY - 20, o.oPosZ, nil)
    else
        o.oPosX = goalPos.x
        o.oHomeY = o.oPosY
        o.oPosZ = goalPos.z
        o.oFaceAngleYaw = marioGfx.angle.y
        o.oAction = CELEB_STAR_ACT_FACE_CAMERA
        cur_obj_scale(0.5)
    end
end

---@param o Object
local celeb_star_leave = function(o)
    o.oVelY = o.oVelY + 1
    o.oPosY = o.oPosY + o.oVelY

    o.oAngleVelYaw = o.oAngleVelYaw + deg_to_hex(2)
    o.oFaceAngleYaw = o.oFaceAngleYaw + o.oAngleVelYaw
    spawn_non_sync_object(id_bhvSparkleSpawn, E_MODEL_NONE, o.oPosX, o.oPosY - 20, o.oPosZ, nil)

    if o.oTimer >= 75 then
        cur_obj_scale(o.header.gfx.scale.x - 0.05)
        if o.header.gfx.scale.x <= 0 then
            obj_mark_for_deletion(o)
        end
    end
end

---@param o Object
local celeb_star_loop = function(o)
    local isLocal = gMarioStates[network_local_index_from_global(o.parentObj.globalPlayerIndex)].playerIndex == 0

    switch(o.oAction, {
        [CELEB_STAR_ACT_SPIN_AROUND_MARIO] = function()
            celeb_star_spin_around_mario(o)
        end,
        [CELEB_STAR_ACT_FACE_CAMERA] = function()
            celeb_star_face_camera(o)
        end,
        [CELEB_STAR_ACT_JUMP_TO_CENTER] = function()
            celeb_star_jump_to_center(o)
        end,
        [CELEB_STAR_ACT_LEAVE] = function()
            celeb_star_leave(o)
        end,
    })

    if gSGOLocalSettings.starsDarkenWorld == 1 and isLocal then
        gNearestStar = o
    end

    environment_effects(o)
end

---@param o Object
local koopa_shell_tilt = function(o)
    local m = gMarioStates[o.heldByPlayerIndex]
    local s = gPlayerSyncTable[m.playerIndex]
    if m == nil or o.oAction ~= 1 or not s.newAnims then return end
    local angle = m.marioObj.header.gfx.angle.z

    o.oFaceAngleRoll = angle
    o.oGraphYOffset = 28 * math.abs(sins(angle))
end

starNewID = hook_behavior(id_bhvStar, OBJ_LIST_LEVEL, false, spawn_rays_on_spawn, environment_effects)
hook_behavior(id_bhvStarSpawnCoordinates, OBJ_LIST_LEVEL, false, spawn_rays_on_spawn, environment_effects)
celebStarNewID = hook_behavior(id_bhvCelebrationStar, OBJ_LIST_LEVEL, true, celeb_star_init, celeb_star_loop)
--why the fuck do exclamation boxes spawn a star with a different behavior?
spawnedStarNewID = hook_behavior(id_bhvSpawnedStar, OBJ_LIST_LEVEL, false, spawn_rays_on_spawn, environment_effects)
--and why the fuck is there a exact variant of the one above except it doesnt kick you out, was setting the subtype flag too hard?
spawnedStarNoExitNewID = hook_behavior(id_bhvSpawnedStarNoLevelExit, OBJ_LIST_LEVEL, false, spawn_rays_on_spawn, environment_effects)
grandStarNewID = hook_behavior(id_bhvGrandStar, OBJ_LIST_LEVEL, false, spawn_rays_on_spawn, environment_effects)
hook_behavior(id_bhvUkikiCageStar, OBJ_LIST_LEVEL, false, spawn_rays_on_spawn, nil)
bowserKeyNewID = hook_behavior(id_bhvBowserKey, OBJ_LIST_LEVEL, false, spawn_rays_on_spawn, environment_effects)

koopaShellNewID = hook_behavior(id_bhvKoopaShell, OBJ_LIST_LEVEL, false, nil, koopa_shell_tilt)