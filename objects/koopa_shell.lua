---@param o Object
local koopa_shell_tilt = function(o)
    local m = gMarioStates[o.heldByPlayerIndex]
    local s = gPlayerSyncTable[m.playerIndex]
    if m == nil or o.oAction ~= 1 or not s.newAnims then return end
    local angle = m.marioObj.header.gfx.angle.z

    o.oFaceAngleRoll = angle
    o.oGraphYOffset = 28 * math.abs(sins(angle))
end

koopaShellNewID = hook_behavior(id_bhvKoopaShell, OBJ_LIST_LEVEL, false, nil, koopa_shell_tilt)