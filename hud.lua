local SECTION_NAME = 0
local SECTION_COLOR = 1
local SECTION_DESC = 2
local SECTION_CONTENT = 3

local OPTION_TYPE_TOGGLE = 0
local OPTION_TYPE_SLIDER = 1
local OPTION_TYPE_MULTIPLE = 2

local OPTION_NAME = 0
local OPTION_VALUE = 1
local OPTION_TYPE = 2
local OPTION_DESC = 3
local OPTION_PROPERTIES = 4

local saveFile = mod_storage_exists("newAnims")

local load_bool_from_save = function(key)
    if not saveFile then return true end
    return mod_storage_load_bool(key)
end

local load_number_from_save = function(key)
    if not saveFile then return false end
    return mod_storage_load_number(key)
end

local sMenuTable = {
    {
        [SECTION_NAME] = "Animations & Body Effects",
        [SECTION_COLOR] = {r = 0xFF, g = 0x7C, b = 0x20},
        [SECTION_DESC] = "Configure how Mario moves around and what happens to his body on certain circumstances.",
        [SECTION_CONTENT] = {
            {
                [OPTION_NAME] = "New Animations",
                [OPTION_VALUE] = load_bool_from_save("newAnims"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, Mario will use the new animations.",
            },
            {
                [OPTION_NAME] = "Fix Rolling Pivot",
                [OPTION_VALUE] = load_bool_from_save("fixRoll"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, Mario's pivot is located around his torso instead of his feet while in the rolling animation. (If it STILL looks wrong with this enabled, disable this option, as some other mod is probably trying to fix this as well).",
            },
            {
                [OPTION_NAME] = "Look at Objects",
                [OPTION_VALUE] = load_bool_from_save("objLook"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, Mario will look at nearby points of interest.",
            },
            {
                [OPTION_NAME] = "Move while Straining",
                [OPTION_VALUE] = load_bool_from_save("airStrafeMove"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, Mario will move his torso according to the control stick as well as look where he's headed at while in the air.",
            },
            {
                [OPTION_NAME] = "Dynamic Diving Pitch",
                [OPTION_VALUE] = load_bool_from_save("divePitch"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, Mario points to the direction his velocity is moving him while diving.",
            },
            {
                [OPTION_NAME] = "Squash and Stretch",
                [OPTION_VALUE] = load_number_from_save("squashStretch") or 1,
                [OPTION_TYPE] = OPTION_TYPE_SLIDER,
                [OPTION_DESC] = "Sets how strongly should Mario stretch or squash when he jumps or lands, respectively.",
                [OPTION_PROPERTIES] = {
                    0,
                    2,
                },
            },
            {
                [OPTION_NAME] = "Color Body on Damage",
                [OPTION_VALUE] = load_bool_from_save("colorBody"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, Mario's palette will change if he's burning, freezing or gets shocked.",
            },
            {
                [OPTION_NAME] = "Red Tint on Low HP",
                [OPTION_VALUE] = load_bool_from_save("lowHpTint"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, Mario will have a flactuating red tint applied while at 2 HP or below.",
            },
            {
                [OPTION_NAME] = "Soak Clothes",
                [OPTION_VALUE] = load_bool_from_save("soak"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, Mario's clothes will turn visibly wet if they're soaked in water.",
            },
            {
                [OPTION_NAME] = "Fluctuating Transparency",
                [OPTION_VALUE] = load_number_from_save("vanishEffect") or 1,
                [OPTION_TYPE] = OPTION_TYPE_SLIDER,
                [OPTION_DESC] = "Sets how much should Mario's transparency fluctuate while wearing the Vanish Cap.",
                [OPTION_PROPERTIES] = {
                    0,
                    1.5,
                },
            },
        },
    },
    {
        [SECTION_NAME] = "Particles",
        [SECTION_COLOR] = {r = 0x5B, g = 0x74, b = 0xFF},
        [SECTION_DESC] = "Change how should many of the new particles behave.",
        [SECTION_CONTENT] = {
            {
                [OPTION_NAME] = "Land Particles",
                [OPTION_VALUE] = load_number_from_save("landDust") or 1,
                [OPTION_TYPE] = OPTION_TYPE_MULTIPLE,
                [OPTION_DESC] = "Set whetever landing should spawn particles. Normal stands for dust particles that spawn when you land at all, Hard stands for little stars that spawn if you land after falling long enough to take damage.",
                [OPTION_PROPERTIES] = {
                    "Both",
                    "Only Normal",
                    "Only Hard",
                    "None",
                },
            },
            {
                [OPTION_NAME] = "Jump Particles",
                [OPTION_VALUE] = load_bool_from_save("jumpDust"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, dust will trail behind Mario whenever he jumps.",
            },
            {
                [OPTION_NAME] = "Wall Hit Particles",
                [OPTION_VALUE] = load_bool_from_save("wallDust"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, dust will appear whenever Mario hits a wall.",
            },
            {
                [OPTION_NAME] = "Walk Particles",
                [OPTION_VALUE] = load_bool_from_save("walkDust"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, dust will appear everytime Mario takes a step.",
            },
            {
                [OPTION_NAME] = "Improved Dust",
                [OPTION_VALUE] = load_bool_from_save("newDust"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, enhances the typical dust particle that spawns when you start running or slide around.",
            },
            {
                [OPTION_NAME] = "Improved Burning Smoke",
                [OPTION_VALUE] = load_bool_from_save("newSmoke"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, enhances the black smoke that spawns when Mario is burning.",
            },
            {
                [OPTION_NAME] = "Frame Perfect Particles",
                [OPTION_VALUE] = load_bool_from_save("framePerfectEffect"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, rainbow sparkles will appear whenever you perform a frame perfect action, like a dustless recover or firstie.",
            },
            {
                [OPTION_NAME] = "HP Related Particles",
                [OPTION_VALUE] = load_number_from_save("hpEffects") or 1,
                [OPTION_TYPE] = OPTION_TYPE_MULTIPLE,
                [OPTION_DESC] = "Set if particles should spawn whenever you take damage or heal, or both.",
                [OPTION_PROPERTIES] = {
                    "Both",
                    "Only on Damage",
                    "Only on Heal",
                    "None",
                },
            },
            {
                [OPTION_NAME] = "Shiny Collectables",
                [OPTION_VALUE] = load_number_from_save("shinyStars") or 1,
                [OPTION_TYPE] = OPTION_TYPE_MULTIPLE,
                [OPTION_DESC] = "Set if Stars, Bowser Keys, and the Grand Star should shine radiantly.",
                [OPTION_PROPERTIES] = {
                    "All",
                    "Only Keys and Grand Star",
                    "None",
                }
            },
            {
                [OPTION_NAME] = "Power-Up Related Particles",
                [OPTION_VALUE] = load_number_from_save("powerUpEffects") or 1,
                [OPTION_TYPE] = OPTION_TYPE_MULTIPLE,
                [OPTION_DESC] = "Set if Mario should sparkle after obtaining a power-up, and/or the power-up should fly off once its lost.",
                [OPTION_PROPERTIES] = {
                    "Both",
                    "Only on Obtain",
                    "Only on Lose",
                    "None",
                }
            },
            {
                [OPTION_NAME] = "Improved Little Stars",
                [OPTION_VALUE] = load_bool_from_save("newCartoonStars"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, enhances the little stars that appear whenever Mario hits a wall too hard or does a Ground Pound.",
            },
        },
    },
    {
        [SECTION_NAME] = "Sound Effects and Music",
        [SECTION_COLOR] = {r = 0x32, g = 0xE5, b = 0x32},
        [SECTION_DESC] = "Enable or disable various sounds added, as well as some small music effects.",
        [SECTION_CONTENT] = {
            {
                [OPTION_NAME] = "Power-Up Related Sounds",
                [OPTION_VALUE] = load_number_from_save("powerUpSounds") or 1,
                [OPTION_TYPE] = OPTION_TYPE_MULTIPLE,
                [OPTION_DESC] = "Set if the classic power-up and power-down should play whenever you obtain or lose a power-up.",
                [OPTION_PROPERTIES] = {
                    "Both",
                    "Only Power-Up",
                    "Only Power-Down",
                    "None",
                },
            },
            {
                [OPTION_NAME] = "Woosh Sounds on Jump",
                [OPTION_VALUE] = load_bool_from_save("jumpSounds"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, a subtle wooshing noise will sound when Mario jumps high enough.",
            },
            {
                [OPTION_NAME] = "Windy Sound on Far Fall",
                [OPTION_VALUE] = load_bool_from_save("fallSound"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, a windy sound will play if Mario falls long enough to take damage or is launched off a cannon.",
            },
            {
                [OPTION_NAME] = "Twinkling Stars",
                [OPTION_VALUE] = load_number_from_save("twinklyStars") or 1,
                [OPTION_TYPE] = OPTION_TYPE_MULTIPLE,
                [OPTION_DESC] = "Sets if Stars, and the Grand Star should make a twinkling sound while Mario is near.",
                [OPTION_PROPERTIES] = {
                    "All",
                    "Only Grand Star",
                    "None",
                },
            },
            {
                [OPTION_NAME] = "Damage Sounds",
                [OPTION_VALUE] = load_number_from_save("damageSounds") or 1,
                [OPTION_TYPE] = OPTION_TYPE_MULTIPLE,
                [OPTION_DESC] = "Sets if an impact sound should play when Mario is damaged and/or a crushing sound if he's crushed.",
                [OPTION_PROPERTIES] = {
                    "Both",
                    "Only on Damage",
                    "Only on Crush",
                    "None",
                },
            },
            {
                [OPTION_NAME] = "Death Buzz",
                [OPTION_VALUE] = load_bool_from_save("deadBuzz"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, the classic death buzz will play whenever Mario dies.",
            },
            {
                [OPTION_NAME] = "Distort Music on Low HP",
                [OPTION_VALUE] = load_number_from_save("lowHpMusic") or 1,
                [OPTION_TYPE] = OPTION_TYPE_SLIDER,
                [OPTION_DESC] = "Sets how much should the music be distorted if Mario is at 2 HP or less.",
                [OPTION_PROPERTIES] = {
                    0,
                    1,
                },
            },
            {
                [OPTION_NAME] = "Slow Music if Crouched",
                [OPTION_VALUE] = load_number_from_save("crouchSlowMusic") or 0.1,
                [OPTION_TYPE] = OPTION_TYPE_SLIDER,
                [OPTION_DESC] = "Sets how much should the music slow down when Mario is crouched.",
                [OPTION_PROPERTIES] = {
                    0,
                    0.2,
                },
            },
            {
                [OPTION_NAME] = "Ramp Up Power-Up Music",
                [OPTION_VALUE] = load_bool_from_save("powerupMusicRampUp"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, the power-up theme will speed up and increase its pitch when the special cap is about to run out.",
            },
            {
                [OPTION_NAME] = "Play Sleep Music",
                [OPTION_VALUE] = load_bool_from_save("sleepyMusic"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, the Pirahna Plant's Lullaby will play while Mario sleeps (and so will while near other sleeping players!).",
            },
        },
    },
    {
        [SECTION_NAME] = "Miscellaneous",
        [SECTION_COLOR] = {r = 0xE5, g = 0x32, b = 0xE5},
        [SECTION_DESC] = "Covers uncategorized, mostly random stuff.",
        [SECTION_CONTENT] = {
            {
                [OPTION_NAME] = "Collectibles Darken World",
                [OPTION_VALUE] = load_number_from_save("starsDarkenWorld") or 2,
                [OPTION_TYPE] = OPTION_TYPE_MULTIPLE,
                [OPTION_DESC] = "Sets whetever Stars, Bowser Keys, and the Grand Star should darken the world when Mario is near.",
                [OPTION_PROPERTIES] = {
                    "All",
                    "Only Keys and Grand Star",
                    "None",
                },
            },
            {
                [OPTION_NAME] = "Death Cutscenes",
                [OPTION_VALUE] = load_number_from_save("deathScene") or 1,
                [OPTION_TYPE] = OPTION_TYPE_MULTIPLE,
                [OPTION_DESC] = "Sets if the Too Bad! sequence should trigger or not, as well as if the new death animations should be used.",
                [OPTION_PROPERTIES] = {
                    "Too Bad and Custom Deaths",
                    "Only Custom Deaths",
                    "Neither",
                },
            },
            {
                [OPTION_NAME] = "Talk Pop-up",
                [OPTION_VALUE] = load_bool_from_save("talkPopUp"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, a small pop-up will appear over Mario if he's able to talk to an NPC or read a sign.",
            },
            {
                [OPTION_NAME] = "Misc. Minor Changes",
                [OPTION_VALUE] = load_bool_from_save("miscThings"),
                [OPTION_TYPE] = OPTION_TYPE_TOGGLE,
                [OPTION_DESC] = "If enabled, fixes various small little quirks, like ground pounding while sidefliping, and adds some small little things.",
            },
        },
    },
}

gSGOLocalSettings = {}

local sMenuOpen = false
local sCurrSection = 1
local sCurrColor = {r = 0, g = 0, b = 0, a = 0}
local sCurrOption = nil
local sScroll = nil
local sMenuInput = 0
local sStickCooldown = 0
local sStickCooldownDiminish = 0
local sDesc
local sShake = {x = 0, y = 0}

local update_settings = function()
    local s = gPlayerSyncTable[0]

    gSGOLocalSettings = {
        objLook = sMenuTable[1][SECTION_CONTENT][3][OPTION_VALUE],
        divePitch = sMenuTable[1][SECTION_CONTENT][5][OPTION_VALUE],
        squashStretch = sMenuTable[1][SECTION_CONTENT][6][OPTION_VALUE],
        lowHpTint = sMenuTable[1][SECTION_CONTENT][8][OPTION_VALUE],
        soak = sMenuTable[1][SECTION_CONTENT][9][OPTION_VALUE],
        vanishEffect = sMenuTable[1][SECTION_CONTENT][10][OPTION_VALUE],

        landDust = sMenuTable[2][SECTION_CONTENT][1][OPTION_VALUE],
        jumpDust = sMenuTable[2][SECTION_CONTENT][2][OPTION_VALUE],
        wallDust = sMenuTable[2][SECTION_CONTENT][3][OPTION_VALUE],
        walkDust = sMenuTable[2][SECTION_CONTENT][4][OPTION_VALUE],
        newDust = sMenuTable[2][SECTION_CONTENT][5][OPTION_VALUE],
        newSmoke = sMenuTable[2][SECTION_CONTENT][6][OPTION_VALUE],
        framePerfectEffect = sMenuTable[2][SECTION_CONTENT][7][OPTION_VALUE],
        hpEffects = sMenuTable[2][SECTION_CONTENT][8][OPTION_VALUE],
        shinyStars = sMenuTable[2][SECTION_CONTENT][9][OPTION_VALUE],
        powerUpEffects = sMenuTable[2][SECTION_CONTENT][10][OPTION_VALUE],
        newCartoonStars = sMenuTable[2][SECTION_CONTENT][11][OPTION_VALUE],

        powerUpSounds = sMenuTable[3][SECTION_CONTENT][1][OPTION_VALUE],
        jumpSounds = sMenuTable[3][SECTION_CONTENT][2][OPTION_VALUE],
        fallSound = sMenuTable[3][SECTION_CONTENT][3][OPTION_VALUE],
        twinklyStars = sMenuTable[3][SECTION_CONTENT][4][OPTION_VALUE],
        damageSounds = sMenuTable[3][SECTION_CONTENT][5][OPTION_VALUE],
        deadBuzz = sMenuTable[3][SECTION_CONTENT][6][OPTION_VALUE],
        lowHpMusic = sMenuTable[3][SECTION_CONTENT][7][OPTION_VALUE],
        crouchSlowMusic = sMenuTable[3][SECTION_CONTENT][8][OPTION_VALUE],
        powerupMusicRampUp = sMenuTable[3][SECTION_CONTENT][9][OPTION_VALUE],
        sleepyMusic = sMenuTable[3][SECTION_CONTENT][10][OPTION_VALUE],

        starsDarkenWorld = sMenuTable[4][SECTION_CONTENT][1][OPTION_VALUE],
        deathScene = sMenuTable[4][SECTION_CONTENT][2][OPTION_VALUE],
        talkPopUp = sMenuTable[4][SECTION_CONTENT][3][OPTION_VALUE],
        miscThings = sMenuTable[4][SECTION_CONTENT][4][OPTION_VALUE],
    }

    s.newAnims = sMenuTable[1][SECTION_CONTENT][1][OPTION_VALUE]
    s.fixRoll = sMenuTable[1][SECTION_CONTENT][2][OPTION_VALUE]
    s.airStrafeMove = sMenuTable[1][SECTION_CONTENT][4][OPTION_VALUE]
    s.colorBody = sMenuTable[1][SECTION_CONTENT][7][OPTION_VALUE]
end

local save_settings = function()
    mod_storage_save_bool("newAnims", sMenuTable[1][SECTION_CONTENT][1][OPTION_VALUE])
    mod_storage_save_bool("fixRoll", sMenuTable[1][SECTION_CONTENT][2][OPTION_VALUE])
    mod_storage_save_bool("objLook", sMenuTable[1][SECTION_CONTENT][3][OPTION_VALUE])
    mod_storage_save_bool("airStrafeMove", sMenuTable[1][SECTION_CONTENT][4][OPTION_VALUE])
    mod_storage_save_bool("divePitch", sMenuTable[1][SECTION_CONTENT][5][OPTION_VALUE])
    mod_storage_save_number("squashStretch", sMenuTable[1][SECTION_CONTENT][6][OPTION_VALUE])
    mod_storage_save_bool("colorBody", sMenuTable[1][SECTION_CONTENT][7][OPTION_VALUE])
    mod_storage_save_bool("lowHpTint", sMenuTable[1][SECTION_CONTENT][8][OPTION_VALUE])
    mod_storage_save_bool("soak", sMenuTable[1][SECTION_CONTENT][9][OPTION_VALUE])
    mod_storage_save_number("vanishEffect", sMenuTable[1][SECTION_CONTENT][10][OPTION_VALUE])

    mod_storage_save_number("landDust", sMenuTable[2][SECTION_CONTENT][1][OPTION_VALUE])
    mod_storage_save_bool("jumpDust", sMenuTable[2][SECTION_CONTENT][2][OPTION_VALUE])
    mod_storage_save_bool("wallDust", sMenuTable[2][SECTION_CONTENT][3][OPTION_VALUE])
    mod_storage_save_bool("walkDust", sMenuTable[2][SECTION_CONTENT][4][OPTION_VALUE])
    mod_storage_save_bool("newDust", sMenuTable[2][SECTION_CONTENT][5][OPTION_VALUE])
    mod_storage_save_bool("newSmoke", sMenuTable[2][SECTION_CONTENT][6][OPTION_VALUE])
    mod_storage_save_bool("framePerfectEffect", sMenuTable[2][SECTION_CONTENT][7][OPTION_VALUE])
    mod_storage_save_number("hpEffects", sMenuTable[2][SECTION_CONTENT][8][OPTION_VALUE])
    mod_storage_save_number("shinyStars", sMenuTable[2][SECTION_CONTENT][9][OPTION_VALUE])
    mod_storage_save_number("powerUpEffects", sMenuTable[2][SECTION_CONTENT][10][OPTION_VALUE])
    mod_storage_save_bool("newCartoonStars", sMenuTable[2][SECTION_CONTENT][11][OPTION_VALUE])

    mod_storage_save_number("powerUpSounds", sMenuTable[3][SECTION_CONTENT][1][OPTION_VALUE])
    mod_storage_save_bool("jumpSounds", sMenuTable[3][SECTION_CONTENT][2][OPTION_VALUE])
    mod_storage_save_bool("fallSound", sMenuTable[3][SECTION_CONTENT][3][OPTION_VALUE])
    mod_storage_save_number("twinklyStars", sMenuTable[3][SECTION_CONTENT][4][OPTION_VALUE])
    mod_storage_save_number("damageSounds", sMenuTable[3][SECTION_CONTENT][5][OPTION_VALUE])
    mod_storage_save_bool("deadBuzz", sMenuTable[3][SECTION_CONTENT][6][OPTION_VALUE])
    mod_storage_save_number("lowHpMusic", sMenuTable[3][SECTION_CONTENT][7][OPTION_VALUE])
    mod_storage_save_number("crouchSlowMusic", sMenuTable[3][SECTION_CONTENT][8][OPTION_VALUE])
    mod_storage_save_bool("powerupMusicRampUp", sMenuTable[3][SECTION_CONTENT][9][OPTION_VALUE])
    mod_storage_save_bool("sleepyMusic", sMenuTable[3][SECTION_CONTENT][10][OPTION_VALUE])

    mod_storage_save_number("starsDarkenWorld", sMenuTable[4][SECTION_CONTENT][1][OPTION_VALUE])
    mod_storage_save_number("deathScene", sMenuTable[4][SECTION_CONTENT][2][OPTION_VALUE])
    mod_storage_save_bool("talkPopUp", sMenuTable[4][SECTION_CONTENT][3][OPTION_VALUE])
    mod_storage_save_bool("miscThings", sMenuTable[4][SECTION_CONTENT][4][OPTION_VALUE])
end

update_settings()

---@param m MarioState
handle_menu_inputs = function(m)
    if not sMenuOpen then return end
    sMenuInput = m.controller.buttonPressed
    m.controller.buttonPressed = 0
    m.controller.stickX = 0
    m.controller.stickY = 0
    m.controller.stickMag = 0

    if sStickCooldown <= 0 then
        if math.abs(m.controller.rawStickX) >= 32 then
            if m.controller.rawStickX >= 32 then
                sMenuInput = sMenuInput | R_JPAD
            elseif m.controller.rawStickX <= -32 then
                sMenuInput = sMenuInput | L_JPAD
            end

            sStickCooldown = math.max(6 * math.min(sStickCooldownDiminish, 1), 0)
        elseif math.abs(m.controller.rawStickY) >= 32 then
            if m.controller.rawStickY >= 32 then
                sMenuInput = sMenuInput | U_JPAD
            elseif m.controller.rawStickY <= -32 then
                sMenuInput = sMenuInput | D_JPAD
            end

            sStickCooldown = 6
            sStickCooldownDiminish = 2
        end
    end

    if sStickCooldown >= -2 then
        sStickCooldown = sStickCooldown - 1
    else
        sStickCooldownDiminish = 2
    end
end

local get_centered_offset = function(text, scale)
    return (djui_hud_measure_text(text) * scale) / 2
end

local print_outlined_text = function(text, x, y, scale, fontColor, outlineColor, offset, alpha)
    djui_hud_set_color(outlineColor.r, outlineColor.g, outlineColor.b, alpha)
    djui_hud_print_text(text, x - offset, y, scale)
    djui_hud_print_text(text, x + offset, y, scale)
    djui_hud_print_text(text, x, y - offset, scale)
    djui_hud_print_text(text, x, y + offset, scale)
    djui_hud_set_color(fontColor.r, fontColor.g, fontColor.b, alpha)
    djui_hud_print_text(text, x, y, scale)
end

local OPTION_RECT_WIDTH = 540
local COLOR_BLACK = {r = 0, g = 0, b = 0}

local render_individual_option = function(text, x, y, scale, bgColor, optionNum, option, alpha)
    local recWidth = OPTION_RECT_WIDTH * scale
    local recHeight = 80 * scale
    local outlineThick = 12

    local color = {r = 0x50, g = 0x50, b = 0x50}
    local fontColor = COLOR_BLACK

    if optionNum == sCurrOption then
        color = bgColor
        fontColor = {r = 0xFF, g = 0xFF, b = 0xFF}
        x = x + sShake.x
        y = y + sShake.y
    end

    -- shadow
    djui_hud_set_color(0, 0, 0, alpha / 2)
    djui_hud_render_rect(x - outlineThick + 8, y - outlineThick + 8, recWidth + outlineThick * 2, recHeight + outlineThick * 2)

    -- outline
    djui_hud_set_color(fontColor.r, fontColor.g, fontColor.b, alpha)
    djui_hud_render_rect(x - outlineThick, y - outlineThick, recWidth + outlineThick * 2, recHeight + outlineThick * 2)

    -- background rectangle
    djui_hud_set_color(color.r, color.g, color.b, alpha)
    djui_hud_render_rect(x, y, recWidth, recHeight)

    -- text
    djui_hud_set_color(fontColor.r, fontColor.g, fontColor.b, alpha)
    djui_hud_print_text(text, x + 20 * scale, y + 22 * scale, scale)

    -- option value
    if option[OPTION_TYPE] == OPTION_TYPE_TOGGLE then
        local colorMult = 0.25
        local optionColor = option[OPTION_VALUE] and {r = 0, g = 0xFF, b = 0} or {r = 0xFF, g = 0, b = 0}
        local optionX = option[OPTION_VALUE] and 100 or 20

        djui_hud_set_color(COLOR_BLACK.r, COLOR_BLACK.g, COLOR_BLACK.b, alpha)
        djui_hud_render_rect(x + recWidth - (23 + 80) * scale, y + 27 * scale, (80 + 6) * scale, 26 * scale)
        djui_hud_render_rect(x + recWidth - (23 + optionX) * scale, y + 22 * scale, 36 * scale, 36 * scale)

        if optionNum == sCurrOption then
            colorMult = 1
        end

        djui_hud_set_color(optionColor.r / 2 * colorMult, optionColor.g / 2 * colorMult, optionColor.b / 2 * colorMult, alpha)
        djui_hud_render_rect(x + recWidth - (20 + 80) * scale, y + 30 * scale, 80 * scale, 20 * scale)

        djui_hud_set_color(optionColor.r * colorMult, optionColor.g * colorMult, optionColor.b * colorMult, alpha)
        djui_hud_render_rect(x + recWidth - (20 + optionX) * scale, y + 25 * scale, 30 * scale, 30 * scale)

    elseif option[OPTION_TYPE] == OPTION_TYPE_SLIDER then
        local colorMult = optionNum == sCurrOption and 1 or 0.25
        local value = option[OPTION_VALUE]
        local min, max = option[OPTION_PROPERTIES][1], option[OPTION_PROPERTIES][2]
        local sliderMaxWidth = 160
        local sliderWidth = sliderMaxWidth * ((value - min) / (max - min))

        djui_hud_render_rect(x + recWidth - (23 + sliderMaxWidth) * scale, y + 27 * scale, (sliderMaxWidth + 6) * scale, 26 * scale)

        djui_hud_set_color(0xFF * colorMult, 0xFF * colorMult, 0, alpha)
        djui_hud_render_rect(x + recWidth - (20 + sliderMaxWidth) * scale, y + 30 * scale, sliderWidth * scale, 20 * scale)

        if optionNum == sCurrOption then
            local text = tostring(math.floor(value * 100)) .. "%"
            djui_hud_set_color(0, 0, 0, alpha)
            djui_hud_print_text(text, x + recWidth - (20 + sliderMaxWidth + djui_hud_measure_text(text)) / 2 * scale, y + 22 * scale,
            scale)
        end

    else
        local optionText = option[OPTION_PROPERTIES][option[OPTION_VALUE]]

        if optionNum == sCurrOption then
            optionText = string.format("< %s >", optionText)
        end

        djui_hud_set_color(fontColor.r, fontColor.g, fontColor.b, alpha)
        djui_hud_print_text(optionText, x + recWidth - (20 + djui_hud_measure_text(optionText)) * scale, y + 22 * scale, scale)
    end
end

local option_scroll = function(current, dir, min, max)
    current = current + dir

    if current < min then
        current = max
    elseif current > max then
        current = min
    end

    return current
end

local render_option_menu = function()
    if sMenuOpen then
        sCurrColor.a = math.min(sCurrColor.a + 0xFF / 20, 0xFF)
    else
        sCurrColor.a = math.max(sCurrColor.a - 0xFF / 10, 0)
    end

    djui_hud_set_resolution(RESOLUTION_DJUI)

    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()
    local screenCenterX = screenWidth / 2
    local screenCenterY = screenHeight / 2
    local alpha = sCurrColor.a
    local xDir = 0
    local yDir = 0

    if sMenuInput & U_JPAD ~= 0 then
        yDir = -1
        sShake.y = -12
        play_sound(SOUND_MENU_MESSAGE_NEXT_PAGE, gGlobalSoundSource)
    elseif sMenuInput & D_JPAD ~= 0 then
        yDir = 1
        sShake.y = 12
        play_sound(SOUND_MENU_MESSAGE_NEXT_PAGE, gGlobalSoundSource)
    end

    if sMenuInput & R_JPAD ~= 0 then
        xDir = 1
        sShake.x = 12
    elseif sMenuInput & L_JPAD ~= 0 then
        xDir = -1
        sShake.x = -12
    end

    sShake.x = approach_s32(sShake.x, 0, 1, 1)
    sShake.y = approach_s32(sShake.y, 0, 1, 1)

    if sMenuInput & START_BUTTON ~= 0 or (sMenuInput & B_BUTTON ~= 0 and not sCurrOption) then
        local s = gPlayerSyncTable[0]
        sMenuOpen = false
        sMenuInput = 0
        update_settings()
        save_settings()
        stop_secondary_music(60)
        play_sound(SOUND_MENU_HAND_DISAPPEAR, gGlobalSoundSource)
        if not sHasModHiddenHud then
            hud_show()
        end
    end

    djui_hud_set_color(sCurrColor.r, sCurrColor.g, sCurrColor.b, alpha / 2)
    djui_hud_render_rect(0, 0, screenWidth + 2, screenHeight + 2)

    local bgColor = sMenuTable[sCurrSection][SECTION_COLOR]

    if not sCurrOption then
        sCurrSection = option_scroll(sCurrSection, yDir, 1, #sMenuTable)

        sDesc = sMenuTable[sCurrSection][SECTION_DESC]

        sCurrColor.r = math.max(sCurrColor.r - bgColor.r / 20, 0)
        sCurrColor.g = math.max(sCurrColor.g - bgColor.g / 20, 0)
        sCurrColor.b = math.max(sCurrColor.b - bgColor.b / 20, 0)

        djui_hud_set_font(FONT_RECOLOR_HUD)

        for i = 1, 4 do
            local text = sMenuTable[i][SECTION_NAME]
            local scale = 3.5
            local x = screenCenterX - get_centered_offset(text, scale)
            local y = screenCenterY + 125 * (i - 2.75)
            local color = {r = 0x80, g = 0x80, b = 0x80}
            local outlineColor = {r = 0, g = 0, b = 0}

            if i == sCurrSection then
                color = sMenuTable[i][SECTION_COLOR]
                outlineColor = {r = 0xFF, g = 0xFF, b = 0xFF}
                y = y + sShake.y
            end
            print_outlined_text(text, x, y, scale, color, outlineColor,
            3, alpha)
        end

        if sMenuInput & A_BUTTON ~= 0 then
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, gGlobalSoundSource)
            sCurrOption = 1
            sScroll = 1
        end
    else
        local section = sMenuTable[sCurrSection]
        local maxOptions = #section[SECTION_CONTENT]

        sCurrOption = option_scroll(sCurrOption, yDir, 1, maxOptions)

        local selectedOption = section[SECTION_CONTENT][sCurrOption]

        sCurrColor.r = math.min(sCurrColor.r + bgColor.r / 20, bgColor.r / 2)
        sCurrColor.g = math.min(sCurrColor.g + bgColor.g / 20, bgColor.g / 2)
        sCurrColor.b = math.min(sCurrColor.b + bgColor.b / 20, bgColor.b / 2)

        local approach = math.abs(sCurrOption - sScroll) > 1 and 0.75 or 0.25
        sScroll = approach_f32(sScroll, sCurrOption, approach, approach)

        sDesc = selectedOption[OPTION_DESC]

        djui_hud_set_font(FONT_NORMAL)

        for i = 1, maxOptions do
            local scale = 1.5 * (8 - math.abs(i - sScroll)) / 8
            local y = screenCenterY + 175 * (i - sScroll) - 50 * scale
            if in_between(y, -100, screenHeight, false) then
                local option = section[SECTION_CONTENT][i]
                local text = option[OPTION_NAME]
                local widthOffset = OPTION_RECT_WIDTH * scale / 2

                render_individual_option(text, screenCenterX - widthOffset, y, scale, bgColor, i, option, alpha)
            end
        end

        if selectedOption[OPTION_TYPE] == OPTION_TYPE_TOGGLE and sMenuInput & (L_JPAD | R_JPAD | A_BUTTON) ~= 0 then
            selectedOption[OPTION_VALUE] = not selectedOption[OPTION_VALUE]
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, gGlobalSoundSource)

        elseif selectedOption[OPTION_TYPE] == OPTION_TYPE_SLIDER then
            local add = (sStickCooldownDiminish <= -5 and 0.05 or 0.01) * xDir
            local min = selectedOption[OPTION_PROPERTIES][1]
            local max = selectedOption[OPTION_PROPERTIES][2]

            selectedOption[OPTION_VALUE] = clamp(selectedOption[OPTION_VALUE] + add, min, max)

            sStickCooldownDiminish = math.max(sStickCooldownDiminish - 0.1, -5)

            if xDir ~= 0 and in_between(selectedOption[OPTION_VALUE] + add, min, max, true) then
                play_sound(SOUND_MENU_REVERSE_PAUSE, gGlobalSoundSource)
            end

        elseif selectedOption[OPTION_TYPE] == OPTION_TYPE_MULTIPLE then
            selectedOption[OPTION_VALUE] = option_scroll(selectedOption[OPTION_VALUE], xDir, 1, #selectedOption[OPTION_PROPERTIES])
            if xDir ~= 0 then
                play_sound(SOUND_MENU_CLICK_FILE_SELECT, gGlobalSoundSource)
            end
        end

        --[[
        local scrollBarX = screenCenterX + OPTION_RECT_WIDTH - 40
        local scrollBarY = 180
        local scrollBarHeight = screenHeight - scrollBarY * 2

        djui_hud_set_color(0, 0, 0, alpha)
        djui_hud_render_rect(scrollBarX, scrollBarY, 30, scrollBarHeight)

        local scrollSegmentY = scrollBarY + (scrollBarHeight / maxOptions) * sScroll - 5
        local scrollSegmentHeight = scrollBarHeight / maxOptions - 10

        djui_hud_set_color(0xFF, 0xFF, 0xFF, alpha)
        djui_hud_render_rect(scrollBarX + 5, scrollSegmentY - scrollSegmentHeight, 20, scrollSegmentHeight)
        ]]--

        if sMenuInput & B_BUTTON ~= 0 then
            play_sound(SOUND_MENU_HAND_DISAPPEAR, gGlobalSoundSource)
            sCurrOption = nil
            sScroll = nil
        end
    end

    djui_hud_set_font(FONT_NORMAL)

    djui_hud_set_color(sCurrColor.r, sCurrColor.g, sCurrColor.b, alpha * 0.8)

    local headerHeight = 90
    local headerText = "Sharen's Game Overhaul Mod Menu"
    local headerScale = 2

    djui_hud_render_rect(0, 0, screenWidth + 2, headerHeight)

    local descHeight = 90
    local descScale = 1
    local finalDesc = {sDesc}
    local descLength = sDesc:len()

    -- this code checks if the description's graphical length surpases the margins on the edges of the screen its supposed to be contained in
    -- if it is, it cuts the description up to the last letter where it begins surpassing its bounds and puts the remainder on a new line
    for i = 1, descLength do
        local current = sDesc:sub(1, i)
        local currChar = sDesc:sub(i, i)
        local nextChar = sDesc:sub(i + 1, i + 1)

        -- we subtract 1 from descLength to prevent the game trying to split off the ending period
        if djui_hud_measure_text(current) > math.floor(screenWidth * 0.86) and i < descLength - 1 then
            -- exclude the space
            if currChar == " " then
                finalDesc[#finalDesc] = sDesc:sub(1, i - 1)

            elseif nextChar == " " or currChar == "," then
                finalDesc[#finalDesc] = current

            elseif nextChar == "," then
                finalDesc[#finalDesc] = current .. nextChar

            else
                finalDesc[#finalDesc] = current .. "-"
            end
            sDesc = sDesc:sub(i + 1)
            table.insert(finalDesc, sDesc)
            descHeight = descHeight + 60
        end
    end

    djui_hud_render_rect(0, screenHeight - descHeight, screenWidth + 2, descHeight + 2)

    djui_hud_set_color(0xFF, 0xFF, 0xFF, alpha)

    djui_hud_print_text(headerText, screenCenterX - get_centered_offset(headerText, headerScale), headerHeight - 40 * headerScale, headerScale)

    for i = 1, #finalDesc do
        djui_hud_print_text(finalDesc[i], screenCenterX - get_centered_offset(finalDesc[i], descScale), (screenHeight - descHeight + 30) +
        60 * (i - 1), descScale)
    end
end

local sTextState = {}
local sDeathText = "TOO BAD!"
gDeathTextTimer = 0

local SOUND_DEATH_JINGLE = audio_sample_load("death_jingle.mp3")

for i = 1, string.len(sDeathText) do
    sTextState[i] = {}
    local l = sTextState[i]

    l.pos = {x = 0, y = 0}
    l.velY = 0
    l.alpha = 0
end

local render_death_text = function()
    if gDeathTextTimer == 1 then
        audio_sample_play(SOUND_DEATH_JINGLE, gLakituState.pos, 0.5)
    end

    gDeathTextTimer = gDeathTextTimer + 1
    djui_hud_set_font(FONT_HUD)

    for i = 1, string.len(sDeathText) do
        local l = sTextState[i]
        local scale = 2.2
        local extraFrames = 4 * i
        local posGoal = gDeathTextTimer < DEATH_TEXT_DURATION + extraFrames and djui_hud_get_screen_height() / 2 - 8 * scale or
        djui_hud_get_screen_height() + 40
        local xOffset = djui_hud_measure_text(sDeathText) * scale / 2
        local letter = string.sub(sDeathText, i, i)

        l.alpha = math.min(l.alpha + 20, 255)

        l.pos.x = djui_hud_get_screen_width() / 2 + djui_hud_measure_text(string.sub(sDeathText, 1, i - 1)) * scale

        if l.alpha > 0 then
            l.pos.y = l.pos.y + l.velY

            if l.pos.y < posGoal then
                l.velY = l.velY + 1
            else
                l.velY = l.velY / -3

                if l.velY > -2 then
                    l.velY = 0
                end

                if l.pos.y > posGoal then
                    l.pos.y = posGoal
                    if i == string.len(sDeathText) and gDeathTextTimer >= DEATH_TEXT_DURATION then
                        gDeathTextTimer = 0
                    end
                end
            end

            djui_hud_set_color(0, 0, 0, math.max(l.alpha * 0.5, 0))

            djui_hud_print_text(letter, l.pos.x + 2 - xOffset, l.pos.y + 2, scale)

            djui_hud_set_color(0xFF, 0xFF, 0xFF, math.max(l.alpha, 0))

            djui_hud_print_text(letter, l.pos.x - xOffset, l.pos.y, scale)
        end
    end
end

local reset_death_text = function()
    for i = 1, string.len(sDeathText) do
        local l = sTextState[i]

        l.pos = {x = 0, y = -25}
        l.velY = 16
        l.alpha = 0 - 40 * i
    end
end

local sTalkPromptTimer = 0
local sTalkPromptText = "You should never see this text in game lol"

local SOUND_PROMPT_SHOW = audio_sample_load("talk_popup.mp3")

---@param m MarioState
local talk_popup = function(m)
    if not gSGOLocalSettings.talkPopUp then return end
    local headPos = m.marioBodyState.headPos

    local screenPos = {x = headPos.x, y = headPos.y + 110, z = headPos.z}
    local printPos = {x = 0, y = 0, z = 0}
    djui_hud_world_pos_to_screen_pos(screenPos, printPos)

    if gTalkPrompt then
        if sTalkPromptTimer == 0 then
            audio_sample_play(SOUND_PROMPT_SHOW, m.area.camera.pos, 1)
            sTalkPromptText = gTalkPrompt == 1 and "Talk" or "Read"
        end
        if sTalkPromptTimer <= 10 then
            sTalkPromptTimer = sTalkPromptTimer + 1
        else
            sTalkPromptTimer = 25
        end
    end

    if sTalkPromptTimer > 0 then
        djui_hud_set_font(FONT_NORMAL)

        local scale = sTalkPromptTimer <= 10 and math.sin(sTalkPromptTimer * 0.25) * 1.5 or 0.9
        local color = 0xFF
        local bButtonTex = get_texture_info("b_button")
        if get_os_name() == "Android" then
            bButtonTex = get_texture_info("texture_touch_b")
        end

        if not gTalkPrompt then
            sTalkPromptTimer = sTalkPromptTimer - 1
            color = 0xA0
        end

        djui_hud_set_color(color, color, color, 0xFF)
        djui_hud_print_text(sTalkPromptText, printPos.x - djui_hud_measure_text(sTalkPromptText) * scale / 2 / 1.5,
        printPos.y - 56 * scale / 1.5, scale / 1.5)
        djui_hud_render_texture(bButtonTex, printPos.x - 8 * scale, printPos.y - 16 * scale, scale, scale)
    end
end

local sBlackBarTimer = 0
local BLACK_BAR_APPEAR_TIMER = 24
local BLACK_BAR_MAX_WIDTH = 18

local render_scenematic_black_bars = function()
    local m = gMarioStates[0]
    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()

    if sBlackBarTimer > 0 then
        local blackBarHeight = BLACK_BAR_MAX_WIDTH * ease_out(sBlackBarTimer / BLACK_BAR_APPEAR_TIMER, 3)
        djui_hud_set_color(0, 0, 0, 0xFF)

        djui_hud_render_rect(-2, -2, screenWidth + 2, blackBarHeight)
        djui_hud_render_rect(-2, screenHeight - blackBarHeight, screenWidth + 2, blackBarHeight)
    end

    if m.area.camera and m.area.camera.cutscene == CUTSCENE_SGO_DEATH then
        sBlackBarTimer = math.min(sBlackBarTimer + 1, 20)
    else
        sBlackBarTimer = math.max(sBlackBarTimer - 1, 0)
    end
end

local debug = true

hook_event(HOOK_ON_HUD_RENDER, function()
    local m = gMarioStates[0]
    local e = gMarioEnhance[0]

    if sCurrColor.a > 0 or sMenuOpen then
        render_option_menu()
    end

    djui_hud_set_resolution(RESOLUTION_N64)

    if gDeathTextTimer > 0 then
        render_death_text()
    else
        reset_death_text()
    end

    talk_popup(m)
    render_scenematic_black_bars()

    if m.controller.buttonPressed & D_JPAD ~= 0 then
        debug = not debug
    end

    if debug then
        local s = gPlayerSyncTable[0]
        local screenRightEdge = djui_hud_get_screen_width()
        local animName = smlua_anim_util_get_current_animation_name(m.marioObj)
        local debugInfo = {
            {"animID = ", animName == nil and m.marioObj.header.gfx.animInfo.animID or animName},
            {"animState = ", e.animState},
            {"animFrame = ", m.marioObj.header.gfx.animInfo.animFrame},
            {"animAccel = ", m.marioObj.header.gfx.animInfo.animAccel / 0x10000},
            {"camDist = ", sCamDist},
            {"camYaw = ", hex_to_deg(sCamYaw)},
            {"camPitch = ", hex_to_deg(sCamPitch)}
        }

        djui_hud_set_font(FONT_NORMAL)
        djui_hud_set_color(255, 255, 255, 255)
        for i = 1, #debugInfo do
            local scale = 0.3
            local text = debugInfo[i][1] .. tostring(debugInfo[i][2])
            local textX = screenRightEdge - 20 - djui_hud_measure_text(text) * scale

            djui_hud_print_text(text, textX, 35 + 15 * i, scale)
        end
    end
end)

hook_event(HOOK_ON_MODS_LOADED, function()
    sHasModHiddenHud = hud_is_hidden()
end)

hook_chat_command("sgo", "- Opens Sharen's Game Overhaul's mod menu.", function()
    sMenuOpen = true
    sCurrSection = 1
    sCurrOption = nil
    sScroll = nil
    sCurrColor = {r = 0, g = 0, b = 0, a = 0}
    play_secondary_music(SEQ_MENU_FILE_SELECT, 0, 255, 60)
    play_sound(SOUND_MENU_HAND_APPEAR, gGlobalSoundSource)
    hud_hide()
    return true
end)