  Menu = {
    Colors = {
        HeaderPink = { r = 50, g = 50, b = 50 },
        SelectedBg = { r = 50, g = 50, b = 50, a = 0.8 }
    },
    State = {},
    Settings = {
        normalNavDelay = 200,
        fastNavDelay = 120
    },
    Data = {
        Options = {}
    },
    Actions = {},
    Helpers = {}
}
Menu.State = {
    menuOpen = false,
    bypassLoaded = false,
    lastHeartbeatCheck = 0,
    menuAlpha = 0,
    selectedOption = 1,
    startIndex = 1,
    maxDisplay = 8,
    currentMenu = "MAIN",
    fullGodModeActive = false,
    semiGodModeActive = false,
    forceEngineActive = false,
    shiftBoostActive = false,
    blackHoleActive = false,
    attachPlayerActive = false,
    rampVehicleActive = false,
    easyHandlingActive = false,
    easyHandlingStrength = 0.0,
    carryActive = false,
    interactEmoteType = nil,
    sideMenuFocus = false,
    sideMenuOption = 1,
    carriedVehicle = nil,
    noclipActive = false,
    noclipSpeed = 1.0,
    freeCamCamera = nil,
    freeCamTpOnExit = false,
    throwVehicleActive = false,
    onlineFilterVehicles = false,
    soloSessionActive = false,
    shootVisionActive = false,
    shootVisionTarget = nil,
    shootVisionRadiusPx = 80.0,
    antiHeadshotActive = false,
    shootVisionLastWeapon = nil,
    lastNavTime = 0,
    menuLastSwitchTime = 0,
    Freecam = {
        active = false,
        pos = vector3(0, 0, 0),
        rot = vector3(0, 0, 0),
        original_pos = vector3(0, 0, 0),
        just_started = false,
        speedIdx = 3,
        speeds = {0.1, 0.25, 0.5, 1.0, 2.0, 5.0},
        keybind_idx = 1,
        keybinds = {
            { name = "ZQSD / SHIFT", keys = { W = 0x5A, S = 0x53, A = 0x51, D = 0x44 } },
            { name = "WASD / SHIFT", keys = { W = 0x57, S = 0x53, A = 0x41, D = 0x44 } }
        },
        options = { "Launch", "Teleport", "Shoot Vision" },
        selectedOption = 1
    }
}
local decorName = "PutinBypassTime"
pcall(DecorRegister, decorName, 3) -- 3 = Int

-- Heartbeat Check Thread (State Bag + Decorator)
Citizen.CreateThread(function()
    while true do
        Wait(1000) -- Check every second
        
        local currentTime = GetGameTimer()
        local valid = false
        
        -- 1. Legacy Global (Direct Check - Keyword: PutinBypassActive__)
        if _G.PutinBypassActive__ then 
            valid = true 
        end

        -- 2. State Bag (Cross-resource fallback)
        if not valid then
            local success, hbState = pcall(function() return LocalPlayer.state.PutinBypassHeartbeat end)
            if success and hbState and (currentTime - hbState) < 3000 then 
                valid = true 
            end
        end

        -- 3. Decorator (Deep fallback)
        if not valid then
            local ped = PlayerPedId()
            if DoesEntityExist(ped) and DecorExistOn(ped, decorName) then
                local hbDecor = DecorGetInt(ped, decorName)
                if math.abs(currentTime - hbDecor) < 3000 then 
                    valid = true 
                end
            end
        end

        Menu.State.bypassLoaded = valid
        
        -- Sync keyword for the current resource
        if valid then
            _G.PutinBypassActive__ = true
        end
    end
end)

maxDisplay = 8

selectedPlayer = nil
attachedPlayers = {}
originalCoords = {}
forceEngineActive = false
shiftBoostActive = false
attachPlayerActive = false
carryActive = false
interactEmoteType = nil
sideMenuFocus = false
sideMenuOption = 1
carriedVehicle = nil
rampVehiclesAttached = {}
freeCamActive = false
freeCamSpeed = 1.0
freeCamSpeeds = {0.1, 0.5, 1.0, 2.0, 5.0}
freeCamSpeedIdx = 3
freeCamCamera = nil
freeCamTpOnExit = false
onlineFilterVehicles = false

noclipBindKey = 0 -- F2 bind removed
isFirstLoadBinding = true
startupBindingControl = 298 -- Start with F12
startupBindingName = "F12"
Menu.Settings = {
    normalNavDelay = 200,
    fastNavDelay = 120
}

-- Binding UI State
isBindingNoclip = false
bindingActionData = nil
bindingText = ""
bindingKeyDisplay = ""
_G.UniversalKeyBinds = {} 

-- Liste noire partagée des contrôles à NE PAS détecter comme touche de menu/bind
local blockedControls = {
    [0]=true, [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [14]=true, [15]=true, [16]=true, [17]=true,
    [24]=true, [25]=true, [69]=true, [92]=true, [114]=true, [142]=true, [257]=true, [329]=true, [346]=true, -- Souris
    [30]=true, [31]=true, [32]=true, [33]=true, [34]=true, [35]=true, -- Déplacements (ZQSD)
    [18]=true, [95]=true, [176]=true, [191]=true, [201]=true, [205]=true, [215]=true, [267]=true, [282]=true, [343]=true, [345]=true, -- TOUTES les touches Entrée (Bloque le bug)
    [194]=true, [177]=true, [200]=true, [202]=true, [322]=true, -- Touches "Echap/Retour"
    [22]=true, [76]=true, [143]=true, [266]=true, [347]=true, -- Espace
    [243]=true, [245]=true, -- Console (²) et Chat (T)
    [255]=true, [306]=true, -- Parasite (Touche L)
    [244]=true, [256]=true, [301]=true -- Parasite (Touche M)
}

-- Settings Globals
_G.headerImgScaleW = 1.0
_G.headerImgScaleH = 1.0
_G.menuScale = 1.0

local lastMenuOpenPress = 0
local vkLastState = false

function Menu.Actions.ToggleDynastyMenu()
    if (GetGameTimer() - lastMenuOpenPress) < 150 then return end -- Durée de sécurité minimale (150ms)
    Menu.State.menuOpen = not Menu.State.menuOpen
    lastMenuOpenPress = GetGameTimer()
end
Menu.Keys = {
    OPEN = 298,   -- Touche F12 (Native)
    VK_OPEN = 0x7B, -- Touche F12 (Windows VK)
    SELECT = 191,
    BACK = 194,
    UP = 172,
    DOWN = 173,
    REVIVE = 73,
    CARRY = 51,
    LEFT = 174,
    RIGHT = 175
}

-- Comprehensive Control Names Map for UI Display (AZERTY FR Optimized)
_G.ControlNamesMap = {
    -- Navigation & Camera
    [0] = "NEXT CAMERA", [1] = "LOOK L/R", [2] = "LOOK U/D", [3] = "LOOK U/D", [4] = "LOOK L/R",
    [5] = "LOOK BEHIND", [6] = "SCROLL DOWN", [7] = "SCROLL UP", [8] = "LOOK UP", [9] = "LOOK DOWN", 
    [10] = "LOOK LEFT", [11] = "LOOK RIGHT", [12] = "SCROLL UP", [13] = "SCROLL DOWN",
    [14] = "SCROLL UP", [15] = "SCROLL DOWN", [16] = "SCROLL UP", [17] = "SCROLL DOWN",
    
    -- Main Actions
    [18] = "R", [19] = "ALT", [20] = "W", [21] = "L-SHIFT", [22] = "SPACE", [23] = "F",
    [24] = "MOUSE LEFT", [25] = "MOUSE RIGHT", [26] = "C", [27] = "F1", [28] = "F2", [29] = "F3",
    
    -- Movement (ZQSD for AZERTY)
    [30] = "D", [31] = "S", [32] = "Z", [33] = "S", [34] = "Q", [35] = "D",
    [36] = "L-CTRL", [37] = "TAB", [38] = "E", [39] = "C", [40] = "CAPSLOCK", 
    [41] = "L-ALT", [42] = "R-ALT", [43] = "SCROLL UP",
    
    -- Action Keys
    [44] = "A", [45] = "R", [46] = "T", [47] = "G", [48] = "Y", [49] = "U",
    [50] = "I", [51] = "E", [52] = "A", [53] = "~", [54] = "Q", [55] = "S",
    
    -- Function Keys
    [56] = "F9", [57] = "F10", [58] = "F1", [59] = "F2", [60] = "F3", [61] = "F5",
    [62] = "F6", [63] = "F7", [64] = "F8", [65] = "F9", [66] = "F10", [67] = "F11",
    [68] = "F12", [69] = "F4", [70] = "F",
    
    -- Vehicle Controls (ZQSD for AZERTY)
    [71] = "Z", [72] = "S", [73] = "X", [74] = "H", [75] = "F", [76] = "SPACE",
    [77] = "D", [78] = "Q", [79] = "Z", [80] = "R", [81] = ".", [82] = ",", 
    [83] = "=", [84] = "-", [85] = "A", [86] = "E", [87] = "PAGEUP", [88] = "PAGEDOWN",
    [89] = "A", [90] = "E",
    
    -- Arrow Keys
    [91] = "LEFT", [92] = "RIGHT", [93] = "UP", [94] = "DOWN", [95] = "ENTER",
    [96] = "LEFT", [97] = "RIGHT", [98] = "UP", [99] = "DOWN",
    
    -- System Controls
    [100] = "L-SHIFT", [101] = "L-CTRL", [102] = "L-ALT", [103] = "R-SHIFT",
    [104] = "R-CTRL", [105] = "R-ALT", [106] = "SCROLL UP", [107] = "SCROLL DOWN",
    [108] = "MOUSE LEFT", [109] = "MOUSE RIGHT", [110] = "MOUSE MIDDLE",
    
    -- More Actions
    [140] = "R", [141] = "A", [142] = "MOUSE LEFT", [143] = "Z", 
    [157] = "1", [158] = "2", [159] = "3", [160] = "4", [161] = "5", 
    [162] = "6", [163] = "7", [164] = "8", [165] = "9", 
    [166] = "F5", [167] = "F6", [168] = "F7", [169] = "F8", [170] = "F3",
    
    -- Menu Navigation & Special
    [171] = "CAPSLOCK", [172] = "HAUT", [173] = "BAS", [174] = "GAUCHE", [175] = "DROITE",
    [176] = "ENTER", [177] = "BACKSPACE", [178] = "DELETE", [179] = "HOME",
    [180] = "PAGEUP", [181] = "PAGEDOWN", [182] = "L-CTRL",
    [183] = "G", [184] = "E", [185] = "F", [186] = "V",
    [187] = "UP", [188] = "DOWN", [189] = "LEFT", [190] = "RIGHT",
    [191] = "ENTER", [192] = "TAB", [193] = "MOUSE LEFT", [194] = "BACKSPACE",
    [195] = "X", [196] = "ESC", [200] = "ESC", [201] = "ENTER", [202] = "BACKSPACE",
    [203] = "SPACE", [204] = "TAB", [205] = "ENTER", [206] = "BACKSPACE",
    
    -- Sub-Actions (ZQSD for AZERTY)
    [232] = "Z", [233] = "Z", [234] = "S", [235] = "Q", [236] = "D", [237] = "V",
    [238] = "MOUSE LEFT", [239] = "MOUSE RIGHT",
    
    -- Mouse Wheel & Multi-Input
    [240] = "SCROLL UP", [241] = "SCROLL UP", [242] = "SCROLL DOWN",
    [243] = "²", [244] = "M", [245] = "T", [246] = "Y", [247] = "U",
    [248] = "I", [249] = "N", [250] = "B", [251] = "H", [252] = "G",
    [253] = "J", [254] = "K", [255] = "L", [256] = "M",
    [257] = "MOUSE LEFT", [261] = "SCROLL UP", [262] = "SCROLL DOWN",
    [263] = "MOUSE LEFT", [264] = "MOUSE RIGHT", [265] = "MOUSE MIDDLE",
    
    -- Extended Actions
    [301] = "M", [302] = "B", [303] = "U", [304] = "P", [305] = "K",
    [306] = "L", [307] = "H", [308] = "N", [309] = "J", [310] = "O", [311] = "K",
    [312] = "I", [313] = "O", [314] = "P",
    
    -- Extended
    [266] = "SPACE", [267] = "ENTER", [268] = "BACKSPACE", 
    [274] = "LEFT", [275] = "RIGHT", [276] = "UP", [277] = "DOWN",
    
    -- Numpad
    [278] = "NUM +", [279] = "NUM -", [282] = "NUM ENTER", [284] = "NUM 0", [285] = "NUM 1",
    [334] = "NUM 6", [335] = "NUM 7", [336] = "NUM 8", [337] = "NUM 9",
    [338] = "NUM 4", [339] = "NUM 5", [340] = "NUM 1", [341] = "NUM 2",
    [342] = "NUM 3", [343] = "NUM ENTER",
    
    -- Final Keys
    [288] = "F1", [289] = "F2", [290] = "F3", [291] = "F5", [292] = "F6",
    [293] = "F7", [294] = "F8", [295] = "F9", [296] = "F10", [297] = "F11",
    [298] = "F12", [300] = "ESC", [344] = "F11", [345] = "ENTER", 
    [346] = "RETOUR", [347] = "SPACE",
    [348] = "MOUSE LEFT", [349] = "MOUSE RIGHT", [350] = "MOUSE MIDDLE",
    -- Letters (AZERTY Full)
    [244] = "M", [246] = "Y", [247] = "U", [248] = "I", [249] = "N",
    [250] = "B", [251] = "H", [252] = "G", [253] = "J", [254] = "K",
    [255] = "L", [256] = "M", [301] = "M", [302] = "B", [303] = "U",
    [304] = "P", [305] = "K", [306] = "L", [307] = "H", [308] = "N",
    [309] = "J", [310] = "O", [311] = "K", [312] = "I", [313] = "O", [314] = "P"
}

local AK_DIST = 1.0

Menu.Data = {
    Options = {
        Main = {
            "Player",
            "Online",
            "Combat",
            "Vehicle",
            "Miscellaneous",
            "Settings"
        }
    }
}
Menu.State.currentMenu = "MAIN"



function Menu.Helpers.GetPlayerOptions()
    return {
        "Full God Mode",
        "Semi God Mode",
        "Solo Session",
        "Noclip",
        "Anti Headshot",
        "Anti-Teleport",
        "Staff Mode"
    }
end

Menu.State.antiTpActive = false
Menu.State.antiHeadshotActive = false

Menu.Data.Options.Combat = {
    "Give All Weapons",
    "Remove All Weapons",
    "Shoot Vision"
}


Menu.Data.Options.Vehicle = {
    "Fix Vehicle",
    "Max Upgrade",
    "Bug Vehicle",
    "Ramp Vehicle",
    "Easy Handling",
    "Force Engine",
    "Shift Boost",
    "FOV Warp",
    "Broke Wheel",
    "Broke All"
}

-- Shoot Vision Weapon Data (La MÉGA liste des armes autorisées)
-- Shoot Vision Weapon Data
_G.ShootVisionConfig = {
    AllowedWeapons = {
        -- Pistolets
        "WEAPON_PISTOL", "WEAPON_COMBATPISTOL", "WEAPON_APPISTOL", "WEAPON_PISTOL50",
        "WEAPON_SNSPISTOL", "WEAPON_HEAVYPISTOL", "WEAPON_VINTAGEPISTOL", "WEAPON_MARKSMANPISTOL",
        "WEAPON_REVOLVER", "WEAPON_DOUBLEACTION", "WEAPON_NAVYREVOLVER", "WEAPON_CERAMICPISTOL",
        "WEAPON_GADGETPISTOL", "WEAPON_PISTOLXM3", "WEAPON_STUNGUN",
        "WEAPON_PISTOL_MK2", "WEAPON_SNSPISTOL_MK2", "WEAPON_REVOLVER_MK2",
        
        -- Fusils d'assaut
        "WEAPON_ASSAULTRIFLE", "WEAPON_CARBINERIFLE", "WEAPON_ADVANCEDRIFLE", "WEAPON_SPECIALCARBINE",
        "WEAPON_BULLPUPRIFLE", "WEAPON_COMPACTRIFLE", "WEAPON_MILITARYRIFLE", "WEAPON_HEAVYRIFLE",
        "WEAPON_TACTICALRIFLE", "WEAPON_BATTLERIFLE",
        "WEAPON_ASSAULTRIFLE_MK2", "WEAPON_CARBINERIFLE_MK2", "WEAPON_SPECIALCARBINE_MK2",
        "WEAPON_BULLPUPRIFLE_MK2",
        
        -- Snipers
        "WEAPON_SNIPERRIFLE", "WEAPON_HEAVYSNIPER", "WEAPON_MARKSMANRIFLE", "WEAPON_PRECISIONRIFLE",
        "WEAPON_HEAVYSNIPER_MK2", "WEAPON_MARKSMANRIFLE_MK2", "WEAPON_M82V2",
        
        -- SMGs (Sous-fusils)
        "WEAPON_MICROSMG", "WEAPON_SMG", "WEAPON_ASSAULTSMG", "WEAPON_COMBATPDW",
        "WEAPON_MACHINEPISTOL", "WEAPON_MINISMG", "WEAPON_TECPISTOL"
    },
    Hashes = {},
    Bones = {
        31086, -- Head
        39317, -- Neck
        24818, -- Spine3 (Chest)
        11816, -- Pelvis
        18905, -- L Hand
        57005, -- R Hand
        63934, -- L Knee
        36864, -- R Knee
        14201, -- L Foot
        52335, -- R Foot
        22711, -- L Elbow
        2992   -- R Elbow
    }
}

-- On convertit tout en Hashes une seule fois pour optimiser
for _, weaponName in ipairs(_G.ShootVisionConfig.AllowedWeapons) do
    table.insert(_G.ShootVisionConfig.Hashes, GetHashKey(weaponName))
end

-- Shoot Vision Visuals (Integrated with Susano Render Loop)
-- Note: Function consolidated at the bottom of the file for better organization.

-- Binding UI (Integrated with Susano Render Loop)
function RenderBindingUI()
    if not isBindingNoclip and not isFirstLoadBinding then return end
    if not Susano or not Susano.DrawRectFilled or not Susano.GetTextWidth then return end

    local sw, sh = GetActiveScreenResolution()
    local fontSize = 20
    local padding = 20
    
    local title = bindingActionData and bindingActionData.label or "F12 Option"
    if isFirstLoadBinding then
        title = "DYNASTY INITIALIZATION"
    end

    local text1 = isFirstLoadBinding and "Choisissez votre touche d'ouverture" or (bindingText .. " (" .. title .. ")")
    local displayKey = isFirstLoadBinding and startupBindingName or bindingKeyDisplay
    local text2 = displayKey ~= "" and ("Touche: " .. displayKey) or ""
    local text3 = "ENTRER Sauver | RETOUR Effacer | ESC Annuler"
    if isFirstLoadBinding then
        text3 = "ENTRER Valider | F12 restera actif en secours"
    end
    
    local w1 = Susano.GetTextWidth(text1, fontSize)
    local w2 = Susano.GetTextWidth(text2, fontSize + 4)
    local w3 = Susano.GetTextWidth(text3, fontSize - 4)
    
    local uiW = math.max(w1, w2, w3) + padding * 2
    local uiH = 110
    local x = (sw / 2) - (uiW / 2)
    local y = sh - uiH - 80
    if isFirstLoadBinding or isBindingNoclip then
        y = (sh / 2) - (uiH / 2) -- Centered overlay (Same as startup)
    end
    
    -- Background Glassmorphic
    Susano.DrawRectFilled(x, y, uiW, uiH, 0, 0, 0, 0.9, 0.0)
    
    local r, g, b = Menu.Colors.SelectedBg.r, Menu.Colors.SelectedBg.g, Menu.Colors.SelectedBg.b
    local a_val = Menu.Colors.SelectedBg.a or 1.0
    -- Accent Line (Dynamic)
    Susano.DrawRectFilled(x, y + uiH - 4, uiW, 4, r/255, g/255, b/255, a_val, 0.0)
    
    -- Draw Texts
    Susano.DrawText(x + (uiW - w1)/2, y + 15, text1, fontSize, 1, 1, 1, 1)
    if text2 ~= "" then
        Susano.DrawText(x + (uiW - w2)/2, y + 42, text2, fontSize + 5, r/255, g/255, b/255, 1)
    end
    Susano.DrawText(x + (uiW - w3)/2, y + 78, text3, fontSize - 4, 0.6, 0.6, 0.6, 1)
end

Menu.Data.Options.Troll = {
    "Launch V1",
    "Launch V2",
    "Teleport To Player",
    "Steal Outfit",
    "Attach Player",
    "Black Hole",
    "Spectate",
    "Bug Vehicle",
    "Bug Player",
    "Attach Anim",
    "Broke Vehicle"
}



Menu.Data.Options.Wardrobe = {
    "Reset Outfit",
    "Save Current Outfit",
    "Load Saved Outfit"
}

-- Community Outfits Data
local CommunityOutfits = {
    {
        name = "Alkaida",
        components = {
            {1, 115, 6}, -- Mask
            {3, 14, 0},  -- Arms
            {4, 119, 4}, -- Pants
            {6, 34, 0},  -- Shoes
            {8, 15, 0},  -- Tshirt
            {9, 11, 1},  -- Vest/Bproof
            {11, 310, 4} -- Torso
        },
        props = {
            {0, -1, 0}, -- Helmet (Clear)
            {1, 0, 0}   -- Glasses (Clear)
        }
    },
    {
        name = "J-Y",
        components = {
            {1, 256, 0}, -- Mask
            {3, 78, 0},  -- Arms
            {4, 16, 3},  -- Pants
            {5, 152, 0}, -- Bags (Parachute/Bag slot)
            {6, 208, 5}, -- Shoes
            {7, 180, 0}, -- Chain (Accessory)
            {8, 15, 0},  -- Tshirt
            {9, 0, 0},   -- Vest
            {11, 924, 0} -- Torso
        },
        props = {
            {0, 244, 0}, -- Helmet
            {1, 71, 0}   -- Glasses
        }
    },
    {
        name = "Ombre du rif",
        components = {
            {1, 0, 0},   -- Mask
            {2, 20, 0},  -- Hair (New)
            {3, 30, 0},  -- Arms
            {4, 142, 17}, -- Pants
            {6, 250, 0}, -- Shoes
            {8, 15, 0},  -- Tshirt
            {9, 0, 0},   -- Bproof
            {11, 0, 2}   -- Torso (variation 2)
        },
        props = {
            {0, -1, 0}   -- Helmet (Clear)
        }
    }
}
local selectedOutfitIndex = 1

function Menu.Actions.LoadOutfit(data)
    local ped = PlayerPedId()
    
    if data.components then
        for _, comp in ipairs(data.components) do
            SetPedComponentVariation(ped, comp[1], comp[2], comp[3], 0)
        end
    end
    
    if data.props then
        for _, prop in ipairs(data.props) do
            if prop[2] == -1 then
                ClearPedProp(ped, prop[1])
            else
                SetPedPropIndex(ped, prop[1], prop[2], prop[3], true)
            end
        end
    end
    
    ShowDynastyNotification("Outfit Loaded: ~b~" .. data.name)

end

function Menu.Actions.RandomOutfit()
    local ped = PlayerPedId()
    ClearAllPedProps(ped)

    -- 1. Randomize Hair & Colors
    local hairCount = GetNumberOfPedDrawableVariations(ped, 2)
    SetPedComponentVariation(ped, 2, math.random(0, math.max(0, hairCount-1)), 0, 0) -- Hair
    
    local hairColor = math.random(0, 63)
    local highlightColor = math.random(0, 63)
    SetPedHairColor(ped, hairColor, highlightColor)

    -- 2. Sync Beard & Eyebrows to Hair Color
    -- Beard (1)
    SetPedHeadOverlay(ped, 1, math.random(0, GetNumHeadOverlayValues(1)-1), 1.0) 
    SetPedHeadOverlayColor(ped, 1, 1, hairColor, highlightColor)
    -- Eyebrows (2)
    SetPedHeadOverlay(ped, 2, math.random(0, GetNumHeadOverlayValues(2)-1), 1.0)
    SetPedHeadOverlayColor(ped, 2, 1, hairColor, highlightColor)

    -- Expanded Style Data with Texture Support
    local masks = {
        {115, 6}, {256, 0}, {0, 0}, {0, 0}, {0, 0}
    }
    
    -- Safe Upper Body Combinations (Fixed Geometry, Random Texture where possible)
    -- Format: {Torso, Txt, Tshirt, Txt, Arms, Txt, Vest, Txt, Bag, Txt, Chain, Txt}
    local tops = {
        -- Alkaida (Tactical) - Fixed
        {310, 4, 15, 0, 14, 0, 11, 1, 0, 0, 0, 0},
        -- J-Y (Custom) - Fixed
        {924, 0, 15, 0, 78, 0, 0, 0, 152, 0, 180, 0},
        -- Luxe Classy (Suit) - Allow Texture Var for Jacket(11) & Pants(4)
        {32, -1, 31, 1, 4, 0, 0, 0, 0, 0, 22, 0}, 
        -- Hood (Hoodie) - Allow Texture Var
        {84, -1, 15, 0, 14, 0, 0, 0, 0, 0, 0, 0},
        -- Casual Clean (T-Shirt) - Allow Texture Var
        {4, -1, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        -- Street Dark (Arms 1) - Allow Texture Var
        {111, -1, 15, 0, 1, 0, 0, 0, 0, 0, 0, 0},
        -- Ombre du rif (New)
        {0, 2, 15, 0, 30, 0, 0, 0, 0, 0, 0, 0}
    }
    
    local pants = {
        {119, 4}, -- Alkaida
        {16, 3},  -- J-Y
        {24, -1}, -- Luxe (Random Color)
        {47, -1}, -- Hood (Random Color)
        {1, -1},  -- Casual (Random Color)
        {28, -1}, -- Street (Random Color)
        {142, 0}  -- Ombre du rif (Pants)
    }
    
    local shoes = {
        {34, 0}, {208, 5}, {10, -1}, {6, -1}, {1, -1}, {250, 0}
    }
    
    local props = {
        {-1, 0, 0, 0}, {244, 0, 71, 0}, {-1, 0, 5, -1}, {-1, 0, 2, -1}
    }

    -- Random Selections
    local m = masks[math.random(#masks)]
    local t = tops[math.random(#tops)]
    local p = pants[math.random(#pants)]
    local s = shoes[math.random(#shoes)]
    local pr = props[math.random(#props)]

    -- Helper for Random Texture
    local function getTex(compID, drawID, defaultTex)
        if defaultTex == -1 then
            local count = GetNumberOfPedTextureVariations(ped, compID, drawID)
            return math.random(0, math.max(0, count-1))
        end
        return defaultTex
    end

    -- Apply Components
    SetPedComponentVariation(ped, 1, m[1], m[2], 0)       -- Mask
    
    -- Upper Body Bundle
    local t_tex = getTex(11, t[1], t[2]) -- Randomize Torso color if allowed
    SetPedComponentVariation(ped, 11, t[1], t_tex, 0)     -- Torso
    SetPedComponentVariation(ped, 8, t[3], t[4], 0)       -- Tshirt
    SetPedComponentVariation(ped, 3, t[5], t[6], 0)       -- Arms
    SetPedComponentVariation(ped, 9, t[7], t[8], 0)       -- Vest
    SetPedComponentVariation(ped, 5, t[9], t[10], 0)      -- Bag
    SetPedComponentVariation(ped, 7, t[11], t[12], 0)     -- Chain

    -- Lower Body
    local p_tex = getTex(4, p[1], p[2])
    SetPedComponentVariation(ped, 4, p[1], p_tex, 0)      -- Pants
    
    local s_tex = getTex(6, s[1], s[2])
    SetPedComponentVariation(ped, 6, s[1], s_tex, 0)      -- Shoes

    -- Apply Props
    if pr[1] ~= -1 then 
        local pr_tex = getTex(0, pr[1], pr[2]) -- Actually prop texture logic differs, but keeping simple for now
        SetPedPropIndex(ped, 0, pr[1], pr[2], true) 
    else 
        ClearPedProp(ped, 0) 
    end
    
    if pr[3] ~= -1 then SetPedPropIndex(ped, 1, pr[3], pr[4], true) else ClearPedProp(ped, 1) end

    ShowDynastyNotification("Random Style: ~b~Expanded + V2")
end

function Menu.Helpers.GetWardrobeOptions()
    local ped = PlayerPedId()
    local hat = GetPedPropIndex(ped, 0)
    local mask = GetPedDrawableVariation(ped, 1)
    local glasses = GetPedPropIndex(ped, 1)
    local torso = GetPedDrawableVariation(ped, 11) -- Tops
    local tshirt = GetPedDrawableVariation(ped, 8) -- Undershirts
    local pants = GetPedDrawableVariation(ped, 4)
    local shoes = GetPedDrawableVariation(ped, 6)
    
    -- Format: Name: -Value-
    return {
        "Random Outfit",
        "Community Outfit: < " .. CommunityOutfits[selectedOutfitIndex].name .. " >",
        "________ Clothing ________",
        "Hat: " .. hat,
        "Mask: " .. mask,
        "Glasses: " .. glasses,
        "Torso: " .. torso,
        "Tshirt: " .. tshirt,
        "Pants: " .. pants,
        "Shoes: " .. shoes
    }
end

function Menu.Helpers.GetMiscOptions()
    local status = Menu.State.bypassLoaded and "~g~[ACTIVE]" or "~r~[INACTIVE]"
    return {
        "Bypass Status: " .. status,
        "Check Bypass",
        "Exploit Staff Menu"
    }
end

local moddedWeapons = {
    {name = "weapon_aa", display = "AA"},
    {name = "weapon_caveira", display = "Caveira"},
    {name = "weapon_SCOM", display = "SCOM"},
    {name = "weapon_mcx", display = "MCX"},
    {name = "weapon_grau", display = "Grau"},
    {name = "weapon_midasgun", display = "Midas"},
    {name = "weapon_hackingdevice", display = "Hacking Device"},
    {name = "weapon_akorus", display = "Akorus"},
    {name = "WEAPON_MIDGARD", display = "Midgard"},
    {name = "weapon_chainsaw", display = "Chainsaw"}
}

function Menu.Actions.ToggleMenuStaff()
    local targetResource = "Putin"

    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        if GetResourceState(targetResource) ~= "started" then
            local alternatives = {"mapmanager", "spawnmanager", "sessionmanager", "baseevents", "chat", "hardcap", "esextended"}
            for _, r in ipairs(alternatives) do
                if GetResourceState(r) == "started" then
                    targetResource = r
                    break
                end
            end
        end

        local codeToInject = [[
            if not GameMode then GameMode = {} end
            if not GameMode.PlayerData then GameMode.PlayerData = {} end
            GameMode.PlayerData.group = "elite"

            if ESX then
                if ESX.PlayerData then ESX.PlayerData.group = "elite" end
                if ESX.SetPlayerData then ESX.SetPlayerData('group', 'elite') end
            end

            if not AdminSystem then AdminSystem = {} end
            if not AdminSystem.Service then AdminSystem.Service = {} end
            AdminSystem.Service.enabled = true

            if type(ToggleDynastyMenu) == "function" then
                ToggleDynastyMenu("staff")
            end
        ]]

        Susano.InjectResource(targetResource, codeToInject)
    else

    end
end

-- Auto-load exploit on startup
CreateThread(function()
    Wait(2000) -- Wait for game to stabilize
    Menu.Actions.ToggleMenuStaff()
end)

-- Staff Gun 'R' Key Trigger
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, 45) then -- R Key (INPUT_RELOAD)
            local camCoords = GetGameplayCamCoord()
            local centerX, centerY = 0.5, 0.5
            local aspect = GetAspectRatio(false)
            local scale = 0.45 -- Matching FOV Warp Circle Scale
            
            local players = GetActivePlayers()
            local bestTarget = nil
            local minDistanceToCenter = scale / 2.0
            local maxDistance = 50.0 -- Staff Gun Distance: 50m
            local myPed = PlayerPedId()

            for _, player in ipairs(players) do
                local targetPed = GetPlayerPed(player)
                if DoesEntityExist(targetPed) and targetPed ~= myPed then
                    local pCoords = GetEntityCoords(targetPed)
                    local distToPlayer = #(pCoords - camCoords)
                    
                    if distToPlayer < maxDistance then
                        local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(pCoords.x, pCoords.y, pCoords.z)
                        
                        if onScreen then
                            local dx = (screenX - centerX) * aspect
                            local dy = screenY - centerY
                            local dist = math.sqrt(dx*dx + dy*dy)
                            
                            if dist < minDistanceToCenter then
                                minDistanceToCenter = dist
                                bestTarget = {
                                    id = player,
                                    serverId = GetPlayerServerId(player),
                                    name = GetPlayerName(player)
                                }
                            end
                        end
                    end
                end
            end

            if bestTarget then
                selectedPlayer = bestTarget
                Menu.State.currentMenu = "TROLL"
                Menu.State.selectedOption, Menu.State.startIndex = 1, 1
                Menu.State.menuOpen = true
                PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                ShowDynastyNotification("Target: ~g~" .. bestTarget.name)
            end
        end
    end
end)

function Menu.Actions.ToggleAntiHeadshot(enable)
    Menu.State.antiHeadshotActive = enable

    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            local susano = rawget(_G, "Susano")

            if _G.AntiDamageEnabled == nil then _G.AntiDamageEnabled = false end
            _G.AntiDamageEnabled = %s

            if not _G.AntiDamageHooksInstalled and susano and type(susano.HookNative) == "function" then
                _G.AntiDamageHooksInstalled = true

                -- Block SetEntityHealth if trying to lower health
                susano.HookNative(0x6B76DC1F3AE6E6A3, function(entity, health)
                    if _G.AntiDamageEnabled and entity == PlayerPedId() then
                        local currentHealth = GetEntityHealth(entity)
                        if health < currentHealth then
                            return false
                        end
                    end
                    return true
                end)

                -- Block ApplyDamageToPed
                susano.HookNative(0x697157CED63F18D4, function(ped, damage, armorDamage)
                    if _G.AntiDamageEnabled and ped == PlayerPedId() then
                        return false
                    end
                    return true
                end)

                -- Block HasEntityBeenDamagedByWeapon
                susano.HookNative(0xFAEE099C6F890BB8, function(entity)
                    if _G.AntiDamageEnabled and entity == PlayerPedId() then
                        return false, false, false, false, false, false, false, false
                    end
                    return true
                end)
            end

            if not _G.AntiDamageLoopStarted then
                _G.AntiDamageLoopStarted = true
                Citizen.CreateThread(function()
                    while true do
                        Wait(0)
                        if _G.AntiDamageEnabled then
                            local ped = PlayerPedId()
                            if DoesEntityExist(ped) then
                                SetPedSuffersCriticalHits(ped, false)
                                SetPedCanRagdollFromPlayerImpact(ped, false)
                            end
                        end
                    end
                end)
            end
        ]], tostring(enable)))
    else
        -- Fallback natif
        local ped = PlayerPedId()
        if DoesEntityExist(ped) then
            SetPedSuffersCriticalHits(ped, not Menu.State.antiHeadshotActive)
        end
    end

    if Menu.State.antiHeadshotActive then
        ShowDynastyNotification("Anti Damage: ~g~ON")
    else
        ShowDynastyNotification("Anti Damage: ~r~OFF")
    end
end


function Menu.Actions.GiveAllModdedWeapons()
    if not Menu.State.bypassLoaded then
        ShowDynastyNotification("~r~Bypass Required!")
        return 
    end
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then
        ShowDynastyNotification("~r~Error: Susano not available")
        return
    end

    Susano.InjectResource("any", string.format([[
        local susano = rawget(_G, "Susano")
        if susano and type(susano) == "table" and type(susano.HookNative) == "function" then
            susano.HookNative(0x3A87E44BB9A01D54, function(ped, weaponHash) return true, -1569615261 end)

            susano.HookNative(0xADF692B254977C0C, function(ped, weapon, equipNow)
                if weapon == -1569615261 then
                    return true
                end
                return true
            end)

            susano.HookNative(0xF25DF915FA38C5F3, function(ped, p1) return end)

            susano.HookNative(0x4899CB088EDF3BCC, function(ped, weaponHash, p2) return end)

            susano.HookNative(0x3795688A307E1EB6, function(ped) return false end)
            susano.HookNative(0x0A6DB4965674D243, function(ped) return -1569615261 end)
            susano.HookNative(0xC3287EE3050FB74C, function(weaponHash) return -1569615261 end)
            susano.HookNative(0x475768A975D5AD17, function(ped, p1) return false end)
            susano.HookNative(0x8DECB02F88F428BC, function(ped, weaponHash, p2) return false end)
            susano.HookNative(0x34616828CD07F1A1, function(ped) return false end)
            susano.HookNative(0x3A50753042A63901, function(ped) return false end)
            susano.HookNative(0xB2A38826EAB6BCF1, function(ped) return false end)
            susano.HookNative(0xED958C9C056BF401, function(ped) return false end)
            susano.HookNative(0x8483E98E8B888A2D, function(ped, p1) return -1569615261 end)
            susano.HookNative(0xA38DCFFCE89696FA, function(ped, weaponHash) return 0 end)
            susano.HookNative(0x7FEAD38B326B9F74, function(ped, weaponHash) return 0 end)
            susano.HookNative(0x3B390A939AF0B5FC, function(ped) return -1 end)
            susano.HookNative(0x59DE03442B6C9598, function(weaponHash) return -1569615261 end)
            susano.HookNative(0x3133B907D8B32053, function(weaponHash, componentHash) return 0.3 end)
            susano.HookNative(0x97A790315D3831FD, function(entity) return 0 end)
            susano.HookNative(0x48C2BED9180FE123, function(entity) return false end)
            susano.HookNative(0x89CF5FF3D310A0DB, function(weaponHash) return -1569615261 end)
            susano.HookNative(0x24B600C29F7F8A9E, function(ped) return false end)
            susano.HookNative(0x8483E98E8B888AE2, function(ped, p1) return -1569615261 end)
            susano.HookNative(0xCAE1DC9A0E22A16D, function(ped) return 0 end)
            susano.HookNative(0x4899CB088EDF59B8, function(ped, weaponHash) return end)
            susano.HookNative(0x2E1202248937775C, function(ped, weaponHash, ammo) return true, 9999 end)
            susano.HookNative(0x2B9EEDC07BD06B9F, function(ped, weaponHash) return 0 end)
        end

        local _GetCurrentPedWeapon = GetCurrentPedWeapon
        local _RemoveAllPedWeapons = RemoveAllPedWeapons
        local _RemoveWeaponFromPed = RemoveWeaponFromPed
        local _SetCurrentPedWeapon = SetCurrentPedWeapon

        GetCurrentPedWeapon = function(ped, ...)
            return true, GetHashKey("WEAPON_UNARMED")
        end

        RemoveAllPedWeapons = function(ped, ...) return end

        RemoveWeaponFromPed = function(ped, weapon) return end

        SetCurrentPedWeapon = function(ped, weapon, ...)
            if weapon == GetHashKey("WEAPON_UNARMED") then
                return _SetCurrentPedWeapon(ped, weapon, ...)
            end
            return
        end

        local weaponAAHash = GetHashKey("weapon_aa")
        local weaponCaveiraHash = GetHashKey("weapon_caveira")
        local weaponSCOMHash = GetHashKey("weapon_SCOM")
        local weaponMCXHash = GetHashKey("weapon_mcx")
        local weaponGrauHash = GetHashKey("weapon_grau")
        local weaponMidasHash = GetHashKey("weapon_midasgun")
        local weaponHackingHash = GetHashKey("weapon_hackingdevice")
        local weaponAkorusHash = GetHashKey("weapon_akorus")
        local weaponMidgardHash = GetHashKey("WEAPON_MIDGARD")
        local weaponChainsawHash = GetHashKey("weapon_chainsaw")
        local selfPed = PlayerPedId()

        GiveWeaponToPed(selfPed, weaponAAHash, 999, false, true)
        SetPedAmmo(selfPed, weaponAAHash, 999)
        SetWeaponDamageModifier(weaponAAHash, 0.0)

        GiveWeaponToPed(selfPed, weaponCaveiraHash, 999, false, true)
        SetPedAmmo(selfPed, weaponCaveiraHash, 999)
        SetWeaponDamageModifier(weaponCaveiraHash, 0.0)

        GiveWeaponToPed(selfPed, weaponSCOMHash, 999, false, true)
        SetPedAmmo(selfPed, weaponSCOMHash, 999)
        SetWeaponDamageModifier(weaponSCOMHash, 0.0)

        GiveWeaponToPed(selfPed, weaponMCXHash, 999, false, true)
        SetPedAmmo(selfPed, weaponMCXHash, 999)
        SetWeaponDamageModifier(weaponMCXHash, 0.0)

        GiveWeaponToPed(selfPed, weaponGrauHash, 999, false, true)
        SetPedAmmo(selfPed, weaponGrauHash, 999)
        SetWeaponDamageModifier(weaponGrauHash, 0.0)

        GiveWeaponToPed(selfPed, weaponMidasHash, 999, false, true)
        SetPedAmmo(selfPed, weaponMidasHash, 999)
        SetWeaponDamageModifier(weaponMidasHash, 0.0)

        GiveWeaponToPed(selfPed, weaponHackingHash, 999, false, true)
        SetPedAmmo(selfPed, weaponHackingHash, 999)
        SetWeaponDamageModifier(weaponHackingHash, 0.0)

        GiveWeaponToPed(selfPed, weaponAkorusHash, 999, false, true)
        SetPedAmmo(selfPed, weaponAkorusHash, 999)
        SetWeaponDamageModifier(weaponAkorusHash, 0.0)

        GiveWeaponToPed(selfPed, weaponMidgardHash, 999, false, true)
        SetPedAmmo(selfPed, weaponMidgardHash, 999)
        SetWeaponDamageModifier(weaponMidgardHash, 0.0)

        GiveWeaponToPed(selfPed, weaponChainsawHash, 999, false, true)
        SetPedAmmo(selfPed, weaponChainsawHash, 999)
        SetWeaponDamageModifier(weaponChainsawHash, 0.0)

        _SetCurrentPedWeapon(selfPed, weaponAAHash, true)

        local moddedHashes = {
            weaponAAHash, weaponCaveiraHash, weaponSCOMHash, 
            weaponMCXHash, weaponGrauHash, weaponMidasHash, 
            weaponHackingHash, weaponAkorusHash, weaponMidgardHash, 
            weaponChainsawHash
        }

        -- BLOCK DAMAGE AT SOURCE (NATIVE HOOK)
        if susano and susano.HookNative then
            susano.HookNative(0x697157CED63F18D4, function(ped, damage, p2, attacker, weaponHash)
                if attacker == PlayerPedId() then
                    for _, h in ipairs(moddedHashes) do
                        if weaponHash == h then return false end
                    end
                end
                return true
            end)
        end

        -- Persistent No-Ragdoll Loop for Targets (High Frequency)
        Citizen.CreateThread(function()
            while true do
                Wait(0)
                local playerPed = PlayerPedId()
                local currentWeapon = GetSelectedPedWeapon(playerPed)
                local isModded = false
                
                for _, hash in ipairs(moddedHashes) do
                    if currentWeapon == hash then
                        isModded = true
                        break
                    end
                end

                if isModded then
                    -- 1. Check free aim target
                    local found, target = GetEntityPlayerIsFreeAimingAt(PlayerId())
                    if not found then
                        -- 2. Check lock-on/combat target
                        target = GetPedTargetEntity(playerPed)
                        found = DoesEntityExist(target)
                    end

                    if found and DoesEntityExist(target) and IsEntityAPed(target) then
                        -- High-intensity ragdoll prevention (Targeted at real players)
                        SetEntityProofs(target, true, true, true, true, true, true, true, true)
                        SetPedCanRagdoll(target, false)
                        SetPedRagdollOnCollision(target, false)
                        SetPedConfigFlag(target, 122, true) -- CPED_CONFIG_FLAG_NoRagdoll
                        SetPedRagdollForceThreshold(target, 1000000.0)
                        SetPedCanPlayInjuryAnims(target, false)
                        SetPedFlinchAbility(target, false)
                        SetEntityCanBeDamaged(target, false)
                        SetEntityInvincible(target, true) -- Essential for avoiding client-side death sims

                        -- Force up if they manage to fall (local sync fix)
                        if IsPedRagdoll(target) or IsPedDeadOrDying(target) then
                            ClearPedTasksImmediately(target)
                        end
                    end
                end
            end
        end)

        -- BLOCK RAGDOLL NATIVES DIRECTLY
        if susano and susano.HookNative then
            local ragdollNatives = {
                0xAE99F17E24650608, -- SetPedToRagdoll
                0xD0A73719; -- SetPedToRagdollWithFall
                0x07115160; -- SetPedToRagdollWithBomb
                0x0E689C8F; -- SetPedToRagdollWithCollision
                0x0F5DF0D5; -- SetPedToRagdollWithForce
            }
            for _, native in ipairs(ragdollNatives) do
                susano.HookNative(native, function(ped, ...)
                    -- If any modded weapon is active, block ragdoll on peds
                    local playerPed = PlayerPedId()
                    local weapon = GetSelectedPedWeapon(playerPed)
                    for _, h in ipairs(moddedHashes) do
                        if weapon == h then return false end
                    end
                    return true
                end)
            end
        end
    ]]))

    ShowDynastyNotification("~g~All modded weapons given!")
end

function Menu.Actions.RemoveAllWeapons()
    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
    ShowDynastyNotification("~g~All weapons removed!")
end



function Menu.Actions.HijackTargetVehicle()
    if not selectedPlayer then
        ShowDynastyNotification("~r~No player selected")
        return
    end

    local targetServerId = selectedPlayer.serverId

    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("Putin", string.format([[
            local targetServerId = %d
            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then
                    targetPlayerId = player
                    break
                end
            end

            if targetPlayerId then
                local targetPed = GetPlayerPed(targetPlayerId)
                if DoesEntityExist(targetPed) and IsPedInAnyVehicle(targetPed, false) then
                    local veh = GetVehiclePedIsIn(targetPed, false)
                    local myPed = PlayerPedId()
                    
                    -- Request control
                    NetworkRequestControlOfEntity(veh)
                    
                    -- Spawn local ped to kick driver
                    local hash = GetHashKey("s_m_y_swat_01")
                    RequestModel(hash)
                    local timeout = 0
                    while not HasModelLoaded(hash) and timeout < 100 do Wait(10) timeout = timeout + 1 end
                    
                    local coords = GetEntityCoords(veh)
                    local ped = nil
                    
                    local susano = rawget(_G, "Susano")
                    if susano and susano.CreateSpoofedPed then
                         ped = susano.CreateSpoofedPed(26, hash, coords.x, coords.y, coords.z, 0.0, false, false)
                    else
                         ped = CreatePed(26, hash, coords.x, coords.y, coords.z, 0.0, false, false)
                    end

                    if DoesEntityExist(ped) then
                        SetEntityVisible(ped, false, 0)
                        SetEntityInvincible(ped, true)
                        SetEntityCollision(ped, false, false)
                        SetPedConfigFlag(ped, 2, true) -- Can be shot in vehicle (just in case)
                        
                        -- Force local ped into driver seat with aggressive loop
                        local timer = 0
                        while timer < 2000 do
                            -- Try to clear current driver
                            local driver = GetPedInVehicleSeat(veh, -1)
                            if driver ~= 0 and driver ~= ped then
                                ClearPedTasksImmediately(driver)
                            end
                            
                            -- Force local ped in
                            SetPedIntoVehicle(ped, veh, -1)
                            
                            -- Check success
                            if GetPedInVehicleSeat(veh, -1) == ped then 
                                -- Wait a tiny bit to ensuring sync
                                Wait(50)
                                break 
                            end
                            
                            Wait(10)
                            timer = timer + 10
                        end
                        
                        -- Delete our local ped
                        DeleteEntity(ped)
                    end
                    
                    -- Warp ourselves into the now-vacated (or conflicting) seat
                    SetPedIntoVehicle(myPed, veh, -1)
                    SetModelAsNoLongerNeeded(hash)
                else
                    -- Notification handled by menu system or silent failure
                end
            end
        ]], targetServerId))
        ShowDynastyNotification("~g~Performing hijack...")
    else
        ShowDynastyNotification("~r~Susano not available")
    end
end

-- Unused KickVehicle removed


function Menu.Actions.BugVehicle()
    if not selectedPlayer then
        ShowDynastyNotification("~r~No player selected")
        return
    end

    local targetServerId = selectedPlayer.serverId

    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("Putin", string.format([[
            local targetServerId = %d

            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then
                    targetPlayerId = player
                    break
                end
            end

            if not targetPlayerId then return end

            local targetPed = GetPlayerPed(targetPlayerId)
            if not DoesEntityExist(targetPed) or not IsPedInAnyVehicle(targetPed, false) then
                return
            end

            local targetVehicle = GetVehiclePedIsIn(targetPed, false)
            if not DoesEntityExist(targetVehicle) then return end

            CreateThread(function()
                local playerPed = PlayerPedId()
                local myCoords = GetEntityCoords(playerPed)

                local closestVeh = GetClosestVehicle(myCoords.x, myCoords.y, myCoords.z, 100.0, 0, 70)
                if not closestVeh or closestVeh == 0 then return end

                SetPedIntoVehicle(playerPed, closestVeh, -1)
                Wait(150)

                SetEntityAsMissionEntity(closestVeh, true, true)
                if NetworkGetEntityIsNetworked(closestVeh) then
                    NetworkRequestControlOfEntity(closestVeh)
                end

                SetEntityCoordsNoOffset(playerPed, myCoords.x, myCoords.y, myCoords.z, false, false, false)
                Wait(100)

                for i = 1, 30 do
                    DetachEntity(closestVeh, true, true)
                    Wait(5)
                    AttachEntityToEntityPhysically(closestVeh, targetVehicle, 0, 0, 0, 2000.0, 1460.0, 1000.0, 10.0, 88.0, 600.0, true, true, true, false, 0)
                    Wait(5)
                end
            end)
        ]], targetServerId))

        ShowDynastyNotification("~g~Bug Vehicle applied!")
    else
        ShowDynastyNotification("~r~Susano not available")
    end
end

-- Duplicate TeleportToPlayer removed

-- Duplicate ToggleSpectate removed

local fovHijackActive = false
local fovHijackKey = 0x58
local fovHijackKeyName = "X"

local dynastyNotifications = {}

function ShowDynastyNotification(text)
    -- Disabled by user request
end

function DrawDynastyNotify()
    -- Disabled by user request
end

function Menu.Helpers.DrawTextCustom(text, x, y, scale, font, r, g, b, a, center)
    SetTextFont(font or 0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, math.floor(a * (Menu.State.menuAlpha / 255)))
    if center then SetTextCentre(true) end
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

-- Legacy Player List functions removed (overwritten by optimized GetCachedPlayerList below)

function Menu.Actions.QuickRevive()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", [[
            local ped = PlayerPedId()
            if not DoesEntityExist(ped) then return end

            local maxHealth = GetEntityMaxHealth(ped)
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)

            if IsEntityDead(ped) or IsPedDeadOrDying(ped, true) then
                NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
                ped = PlayerPedId()
            end

            SetEntityHealth(ped, maxHealth)
            ClearPedBloodDamage(ped)
            ResetPedVisibleDamage(ped)
            ClearPedTasksImmediately(ped)
            FreezeEntityPosition(ped, false)
            SetEntityCollision(ped, true, true)
            SetEntityInvincible(ped, false)
            SetPedCanRagdoll(ped, false)

            Citizen.CreateThread(function()
                Wait(200)
                SetPedCanRagdoll(PlayerPedId(), true)
            end)
        ]])
        ShowDynastyNotification("~g~Revived!")
    else
        -- Fallback sans Susano
        local maxHealth = GetEntityMaxHealth(ped)
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        if IsEntityDead(ped) or IsPedDeadOrDying(ped, true) then
            NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
            ped = PlayerPedId()
        end

        SetEntityHealth(ped, maxHealth)
        ClearPedBloodDamage(ped)
        ResetPedVisibleDamage(ped)
        ClearPedTasksImmediately(ped)
        FreezeEntityPosition(ped, false)
        SetEntityCollision(ped, true, true)
        ShowDynastyNotification("~g~Revived!")
    end
end

function Menu.Actions.ToggleFullGodmode(enable)
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then
        ShowDynastyNotification("~r~Error: Susano not available")
        return
    end

    Menu.State.fullGodModeActive = enable

    if enable and Menu.State.semiGodModeActive then
        Menu.State.semiGodModeActive = false
    end

    local code = string.format([[
        local susano = rawget(_G, "Susano")

        if _G.FullGodmodeEnabled == nil then _G.FullGodmodeEnabled = false end
        _G.FullGodmodeEnabled = %s

        if not _G.FullGodmodeHooksInstalled and susano and type(susano.HookNative) == "function" then
            _G.FullGodmodeHooksInstalled = true

            susano.HookNative(0xFAEE099C6F890BB8, function(entity)
                if _G.FullGodmodeEnabled and entity == PlayerPedId() then
                    return false, false, false, false, false, false, false, false
                end
                return true
            end)


            susano.HookNative(0x6B76DC1F3AE6E6A3, function(entity, health)
                if _G.FullGodmodeEnabled and entity == PlayerPedId() then
                    local maxHealth = GetEntityMaxHealth(entity)
                    if health < maxHealth then
                        return false
                    end
                end
                return true
            end)


        end

        if not _G.FullGodmodeLoopStarted then
            _G.FullGodmodeLoopStarted = true

            Citizen.CreateThread(function()
                while true do
                    Wait(0)
                    if _G.FullGodmodeEnabled then
                        local ped = PlayerPedId()
                        if DoesEntityExist(ped) then
                            local maxHealth = GetEntityMaxHealth(ped)
                            SetEntityHealth(ped, maxHealth)
                        end
                    end
                end
            end)
        end
    ]], tostring(enable))

    Susano.InjectResource("any", code)

    if enable then

    else

    end
end

function Menu.Actions.ToggleSemiGodmode(enable)
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then
        ShowDynastyNotification("~r~Error: Susano not available")
        return
    end

    Menu.State.semiGodModeActive = enable

    if enable and Menu.State.fullGodModeActive then
        Menu.State.fullGodModeActive = false
    end

    local code = string.format([[
        local susano = rawget(_G, "Susano")

        if _G.SemiGodmodeEnabled == nil then _G.SemiGodmodeEnabled = false end
        _G.SemiGodmodeEnabled = %s

        if not _G.SemiGodmodeHooksInstalled and susano and type(susano.HookNative) == "function" then
            _G.SemiGodmodeHooksInstalled = true

            susano.HookNative(0xFAEE099C6F890BB8, function(entity)
                if _G.SemiGodmodeEnabled and entity == PlayerPedId() then
                    return false, false, false, false, false, false, false, false
                end
                return true
            end)


            susano.HookNative(0x6B76DC1F3AE6E6A3, function(entity, health)
                if _G.SemiGodmodeEnabled and entity == PlayerPedId() then
                    local maxHealth = GetEntityMaxHealth(entity)
                    if health < maxHealth then
                        return false
                    end
                end
                return true
            end)


        end

        if not _G.SemiGodmodeLoopStarted then
            _G.SemiGodmodeLoopStarted = true
            _G.LastHealth = nil

            if susano and type(susano.HookNative) == "function" then
                susano.HookNative(0xFAEE099C6F890BB8, function(entity)
                    if _G.SemiGodmodeEnabled and entity == PlayerPedId() then
                        return false, false, false, false, false, false, false, false
                    end
                    return true
                end)
            end

            Citizen.CreateThread(function()
                while true do
                    Wait(200)
                    if _G.SemiGodmodeEnabled then
                        local ped = PlayerPedId()
                        if not DoesEntityExist(ped) then goto continue end

                        local currentHealth = GetEntityHealth(ped)
                        local maxHealth = GetEntityMaxHealth(ped)

                        if currentHealth < maxHealth then
                            local regenAmount = math.min(3, maxHealth - currentHealth)
                            SetEntityHealth(ped, currentHealth + regenAmount)
                        end

                        if math.random(1, 10) == 1 then
                            ClearPedBloodDamage(ped)
                            ResetPedVisibleDamage(ped)
                        end

                        _G.LastHealth = currentHealth

                        ::continue::
                    end
                end
            end)

            Citizen.CreateThread(function()
                while true do
                    Wait(10)
                    if _G.SemiGodmodeEnabled then
                        local ped = PlayerPedId()
                        if not DoesEntityExist(ped) then goto continue end

                        local currentHealth = GetEntityHealth(ped)
                        local maxHealth = GetEntityMaxHealth(ped)

                        if _G.LastHealth and currentHealth < _G.LastHealth then
                            local damageTaken = _G.LastHealth - currentHealth
                            if damageTaken > 10 then
                                SetEntityHealth(ped, maxHealth)
                            elseif damageTaken > 5 then
                                local regenAmount = math.min(20, maxHealth - currentHealth)
                                SetEntityHealth(ped, currentHealth + regenAmount)
                            end
                        end

                        if currentHealth < (maxHealth * 0.8) then
                            local regenAmount = math.min(15, maxHealth - currentHealth)
                            SetEntityHealth(ped, currentHealth + regenAmount)
                        end

                        if currentHealth < (maxHealth * 0.5) then
                            SetEntityHealth(ped, maxHealth)
                        end

                        _G.LastHealth = currentHealth

                        ::continue::
                    end
                end
            end)
        end
    ]], tostring(enable))

    Susano.InjectResource("any", code)

    if enable then

    else

    end
end



function Menu.Actions.SoloSession()
    Menu.State.soloSessionActive = not Menu.State.soloSessionActive
    
    if Menu.State.soloSessionActive then
        NetworkStartSoloTutorialSession()
        ShowDynastyNotification("Solo Session: ~g~ON ~w~(Tutorial Mode)")
    else
        NetworkEndTutorialSession()
        ShowDynastyNotification("Solo Session: ~r~OFF")
    end
end
-- ===================================================================
-- FREE CAM SYSTEM (from free_cam.lua - Susano version)
-- ===================================================================
if type(Susano) ~= "table" then
    Susano = {}
end

Menu.State.Freecam = {
    active = false,
    pos = vector3(0, 0, 0),
    rot = vector3(0, 0, 0),
    original_pos = vector3(0, 0, 0),
    just_started = false,
    speed = 0.5,
    normal_speed = 0.5,
    fast_speed = 2.5,
    options = { "Launch", "Teleport", "Shoot Vision" },
    selectedOption = 1,
    lastScrollTime = 0,
    lastScrollValue = 0.0,
    last_click_time = 0,
    keybind_idx = 1,
    keybinds = {
        { name = "ZQSD / SHIFT", keys = { W = 0x5A, S = 0x53, A = 0x51, D = 0x44 } }, -- AZERTY
        { name = "WASD / SHIFT", keys = { W = 0x57, S = 0x53, A = 0x41, D = 0x44 } }  -- QWERTY
    }
}

local VK_W = 0x57
local VK_A = 0x41
local VK_S = 0x53
local VK_D = 0x44
local VK_Q = 0x51
local VK_E = 0x45
local VK_Z = 0x5A
local VK_SHIFT = 0x10
local VK_SPACE = 0x20
local VK_CONTROL = 0x11
local VK_F4 = 0x73

-- ===================================================================
-- FREE CAM SYSTEM (from free_cam.lua - Susano version)
-- ===================================================================
if type(Susano) ~= "table" then
    Susano = {}
end

local freecam_active = false
local cam_pos = vector3(0, 0, 0)
local cam_rot = vector3(0, 0, 0)
local original_pos = vector3(0, 0, 0)
local freecam_just_started = false

local freecam_speed = 0.5
local normal_speed = 0.5
local fast_speed = 2.5

local FreecamOptions = { "Launch", "Teleport", "Shoot Vision" }
local FreecamSelectedOption = 1
local lastScrollTime = 0
local lastScrollValue = 0.0
local last_click_time = 0

local VK_W = 0x57
local VK_A = 0x41
local VK_S = 0x53
local VK_D = 0x44
local VK_Q = 0x51
local VK_E = 0x45
local VK_Z = 0x5A
local VK_SHIFT = 0x10
local VK_SPACE = 0x20
local VK_CONTROL = 0x11
local VK_F4 = 0x73

local freecam_keybinds = {
    {key = 0x48, name = "H"}
}
local freecam_keybind_idx = 1

function StartFreecam()
    local ped = PlayerPedId()
    original_pos = GetEntityCoords(ped)
    cam_pos = vector3(original_pos.x, original_pos.y, original_pos.z)

    local currentRot = GetGameplayCamRot(2)
    cam_rot = vector3(currentRot.x, currentRot.y, currentRot.z)

    FreezeEntityPosition(ped, true)
    ClearPedTasksImmediately(ped)
    SetEntityInvincible(ped, true)
    if type(Susano.LockCameraPos) == "function" then
        Susano.LockCameraPos(true)
    end

    freecam_active = true
    _G.freecam_active = true
    freecam_just_started = true

    Citizen.CreateThread(function()
        Citizen.Wait(500)
        freecam_just_started = false
    end)
end

function StopFreecam()
    local ped = PlayerPedId()
    if type(Susano.LockCameraPos) == "function" then
        Susano.LockCameraPos(false)
    end
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    ClearFocus()
    freecam_active = false
    _G.freecam_active = false
end

function ForceWorldLoad()
    RequestCollisionAtCoord(cam_pos.x, cam_pos.y, cam_pos.z)
    SetFocusPosAndVel(cam_pos.x, cam_pos.y, cam_pos.z, 0.0, 0.0, 0.0)
    NewLoadSceneStart(cam_pos.x, cam_pos.y, cam_pos.z, cam_pos.x, cam_pos.y, cam_pos.z, 150.0, 0)
end

function TeleportToFreecam()
    if type(Susano.InjectResource) ~= "function" then return end

    local ped = PlayerPedId()
    local currentCamCoords = cam_pos
    local currentCamRot = cam_rot
    local pitch = math.rad(currentCamRot.x)
    local yaw = math.rad(currentCamRot.z)
    local dirX = -math.sin(yaw) * math.cos(pitch)
    local dirY = math.cos(yaw) * math.cos(pitch)
    local dirZ = math.sin(pitch)
    local direction = vector3(dirX, dirY, dirZ)

    Susano.InjectResource("any", string.format([[
        local ped = PlayerPedId()
        local camCoords = vector3(%f, %f, %f)
        local direction = vector3(%f, %f, %f)
        local raycastStart = camCoords
        local raycastEnd = vector3(
            camCoords.x + direction.x * 1000.0,
            camCoords.y + direction.y * 1000.0,
            camCoords.z + direction.z * 1000.0
        )
        local raycast = StartExpensiveSynchronousShapeTestLosProbe(
            raycastStart.x, raycastStart.y, raycastStart.z,
            raycastEnd.x, raycastEnd.y, raycastEnd.z,
            -1, ped, 7
        )
        local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(raycast)
        if hit and entityHit and DoesEntityExist(entityHit) and GetEntityType(entityHit) == 2 then
            local targetVehicle = entityHit
            SetEntityAsMissionEntity(targetVehicle, true, true)
            if NetworkGetEntityIsNetworked(targetVehicle) then
                NetworkRequestControlOfEntity(targetVehicle)
                local attempts = 0
                while not NetworkHasControlOfEntity(targetVehicle) and attempts < 100 do
                    Wait(0)
                    attempts = attempts + 1
                    NetworkRequestControlOfEntity(targetVehicle)
                end
            end
            local freeSeat = -1
            local maxSeats = GetVehicleMaxNumberOfPassengers(targetVehicle)
            local driverSeat = GetPedInVehicleSeat(targetVehicle, -1)
            if driverSeat == 0 or not DoesEntityExist(driverSeat) then
                freeSeat = -1
            else
                for i = 0, maxSeats - 1 do
                    local seatPed = GetPedInVehicleSeat(targetVehicle, i)
                    if seatPed == 0 or not DoesEntityExist(seatPed) then
                        freeSeat = i
                        break
                    end
                end
            end
            if freeSeat ~= -1 then
                ClearPedTasksImmediately(ped)
                Wait(50)
                SetPedIntoVehicle(ped, targetVehicle, freeSeat)
            else
                ClearPedTasksImmediately(ped)
                Wait(50)
                SetPedIntoVehicle(ped, targetVehicle, -1)
            end
        elseif hit and endCoords and endCoords.x ~= 0.0 and endCoords.y ~= 0.0 and endCoords.z ~= 0.0 then
            SetEntityCoords(ped, endCoords.x, endCoords.y, endCoords.z, false, false, false, false)
        else
            local teleportPos = vector3(
                camCoords.x + direction.x * 5.0,
                camCoords.y + direction.y * 5.0,
                camCoords.z + direction.z * 5.0
            )
            SetEntityCoords(ped, teleportPos.x, teleportPos.y, teleportPos.z, false, false, false, false)
        end
    ]], currentCamCoords.x, currentCamCoords.y, currentCamCoords.z, direction.x, direction.y, direction.z))
end

function FreecamLaunchPlayer()

    local myPed = PlayerPedId()
    local pitch = math.rad(cam_rot.x)
    local yaw = math.rad(cam_rot.z)
    local dirX = -math.sin(yaw) * math.cos(pitch)
    local dirY = math.cos(yaw) * math.cos(pitch)
    local dirZ = math.sin(pitch)
    local raycastStart = cam_pos
    local raycastEnd = vector3(
        cam_pos.x + dirX * 1000.0,
        cam_pos.y + dirY * 1000.0,
        cam_pos.z + dirZ * 1000.0
    )
    local raycast = StartExpensiveSynchronousShapeTestLosProbe(
        raycastStart.x, raycastStart.y, raycastStart.z,
        raycastEnd.x, raycastEnd.y, raycastEnd.z,
        -1, myPed, 7
    )
    local _, hit, _, _, entityHit = GetShapeTestResult(raycast)
    if not hit or not entityHit or not DoesEntityExist(entityHit) then return end

    local targetPlayerId = nil
    for _, playerId in ipairs(GetActivePlayers()) do
        if GetPlayerPed(playerId) == entityHit then
            targetPlayerId = playerId
            break
        end
    end
    if not targetPlayerId then return end

    local targetPed = GetPlayerPed(targetPlayerId)
    if not targetPed or not DoesEntityExist(targetPed) then return end

    Citizen.CreateThread(function()
        local myCoords = GetEntityCoords(myPed)
        local targetCoords = GetEntityCoords(targetPed)
        local originalCoords = myCoords
        local originalHeading = GetEntityHeading(myPed)
        local distance = #(myCoords - targetCoords)
        local teleported = false

        if distance > 10.0 then
            local angle = math.random() * 2 * math.pi
            local radiusOffset = math.random(5, 9)
            local xOffset = math.cos(angle) * radiusOffset
            local yOffset = math.sin(angle) * radiusOffset
            local newCoords = vector3(targetCoords.x + xOffset, targetCoords.y + yOffset, targetCoords.z)
            SetEntityCoordsNoOffset(myPed, newCoords.x, newCoords.y, newCoords.z, false, false, false)
            SetEntityVisible(myPed, false, 0)
            teleported = true
            Wait(30)
        end

        ClearPedTasksImmediately(myPed)
        local targetCoordsBeforeLaunch = GetEntityCoords(targetPed)
        for i = 1, 10 do
            if not DoesEntityExist(targetPed) then break end
            local curTargetCoords = GetEntityCoords(targetPed)
            if not curTargetCoords then break end
            SetEntityCoords(myPed, curTargetCoords.x, curTargetCoords.y, curTargetCoords.z + 0.5, false, false, false, false)
            Wait(30)
            AttachEntityToEntityPhysically(myPed, targetPed, 0, 0.0, 0.0, 0.0, 150.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, false, false, 1, 2)
            Wait(30)
            DetachEntity(myPed, true, true)
            Wait(50)
        end

        -- Fallback for AFK players: if target barely moved, apply direct force
        Wait(100)
        if DoesEntityExist(targetPed) then
            local targetCoordsAfter = GetEntityCoords(targetPed)
            local movedDist = #(targetCoordsBeforeLaunch - targetCoordsAfter)
            if movedDist < 5.0 then
                -- Direct force launch on AFK player
                SetEntityCoords(myPed, targetCoordsAfter.x, targetCoordsAfter.y, targetCoordsAfter.z + 0.3, false, false, false, false)
                Wait(30)
                for j = 1, 5 do
                    if not DoesEntityExist(targetPed) then break end
                    ApplyForceToEntity(targetPed, 1, 0.0, 0.0, 50000.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                    Wait(50)
                end
            end
        end

        Wait(200)
        ClearPedTasksImmediately(myPed)
        SetEntityCoordsNoOffset(myPed, originalCoords.x, originalCoords.y, originalCoords.z + 1.0, false, false, false)
        Wait(100)
        SetEntityCoordsNoOffset(myPed, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false)
        SetEntityHeading(myPed, originalHeading)
        if teleported then SetEntityVisible(myPed, true, 0) end
    end)
end

function TeleportToFreecam()
    local ped = PlayerPedId()
    if DoesEntityExist(ped) and cam_pos then
        SetEntityCoords(ped, cam_pos.x, cam_pos.y, cam_pos.z, false, false, false, false)
        ShowDynastyNotification("~g~Teleported to Camera!")
    end
end

function HandleInputMenu()
    local scrollValue = GetDisabledControlNormal(0, 14)
    local currentTime = GetGameTimer()
    if lastScrollTime == 0 then
        lastScrollTime = currentTime
        lastScrollValue = scrollValue
    end
    local scrollDelta = scrollValue - lastScrollValue
    if (currentTime - lastScrollTime) > 100 then
        if scrollDelta > 0.1 then
            FreecamSelectedOption = FreecamSelectedOption + 1
            if FreecamSelectedOption > #FreecamOptions then FreecamSelectedOption = 1 end
            lastScrollTime = currentTime
            lastScrollValue = scrollValue
        elseif scrollDelta < -0.1 then
            FreecamSelectedOption = FreecamSelectedOption - 1
            if FreecamSelectedOption < 1 then FreecamSelectedOption = #FreecamOptions end
            lastScrollTime = currentTime
            lastScrollValue = scrollValue
        end
    end
    if math.abs(scrollValue) < 0.05 then lastScrollValue = scrollValue end

    -- Use both Enter and Left-click for context-sensitive validation
    -- Checking both disabled and enabled states for control 24 (Left-click) for absolute reliability.
    local enter_pressed = IsDisabledControlJustPressed(0, 191) or IsDisabledControlJustPressed(0, 201)
    local click_pressed = IsDisabledControlJustPressed(0, 24) or IsControlJustPressed(0, 24)
    local validated = enter_pressed or click_pressed

    if validated and not freecam_just_started and (currentTime - last_click_time) > 150 then
        last_click_time = currentTime
        local name = FreecamOptions[FreecamSelectedOption]
        if name == "Launch" then
            shootVisionActive = false 
            ShowDynastyNotification("~b~Launching Target...")
            FreecamLaunchPlayer()
        elseif name == "Teleport" then
            shootVisionActive = false
            TeleportToFreecam()
        elseif name == "Shoot Vision" then
            if enter_pressed then
                shootVisionActive = not shootVisionActive
                ShowDynastyNotification("Shoot Vision: " .. (shootVisionActive and "~g~ON" or "~r~OFF"))
            elseif click_pressed and not shootVisionActive then
                shootVisionActive = true
                ShowDynastyNotification("Shoot Vision: ~g~ON")
            end
            
            if shootVisionActive then
                local ped = PlayerPedId()
                if not getWeaponFromInventory(ped) then
                    ShowDynastyNotification("~y~Aucune arme trouvée dans l'inventaire")
                end
            end
        end
    end
end

function DrawFreecamHint()
    if not freecam_active then
        if type(Susano.BeginFrame) == "function" then Susano.BeginFrame() end
        if type(Susano.SubmitFrame) == "function" then Susano.SubmitFrame() end
        return
    end
    if type(Susano.BeginFrame) ~= "function" or type(Susano.DrawText) ~= "function" or type(Susano.SubmitFrame) ~= "function" then return end
    Susano.BeginFrame()
    local w, h = GetActiveScreenResolution()
    local cx = w / 2.0
    local options = FreecamOptions
    local selected = FreecamSelectedOption or 1
    local sizeSel, sizeNorm = 22.0, 18.0
    local spacing = 32.0
    local startY = h - 120.0
    local rSel, gSel, bSel = 148/255, 0, 211/255
    local rNorm, gNorm, bNorm = 0.85, 0.85, 0.85
    for i = 1, #options do
        local size = (i == selected) and sizeSel or sizeNorm
        local r, g, b = (i == selected) and rSel or rNorm, (i == selected) and gSel or gNorm, (i == selected) and bSel or bNorm
        local y = startY + (i - 1) * spacing
        local text = options[i]
        if i == selected then text = "> " .. text .. " <" end
        Susano.DrawText(cx - 70.0, y, text, size, r, g, b, 1.0)
    end
    Susano.SubmitFrame()
end

function UpdateFreecam()
    if not freecam_active then return end

    local forward = 0.0
    local sideways = 0.0
    local vertical = 0.0

    if type(Susano.GetAsyncKeyState) == "function" then
        if Susano.GetAsyncKeyState(VK_Z) then forward = 1.0 end
        if Susano.GetAsyncKeyState(VK_S) then forward = -1.0 end
        if Susano.GetAsyncKeyState(VK_D) then sideways = 1.0 end
        if Susano.GetAsyncKeyState(VK_Q) then sideways = -1.0 end
        if Susano.GetAsyncKeyState(VK_SPACE) then vertical = 1.0 end
        if Susano.GetAsyncKeyState(VK_CONTROL) then vertical = -1.0 end

        -- Mouse Wheel Elevation
        local scrollDelta = GetDisabledControlNormal(0, 14)
        if math.abs(scrollDelta) > 0.01 then
            vertical = vertical + (scrollDelta * 5.0) -- Multiply for responsiveness
        end

        local speed = normal_speed
        if Susano.GetAsyncKeyState(VK_SHIFT) then
            speed = fast_speed
        end

        local currentRot = GetGameplayCamRot(2)
        cam_rot = vector3(currentRot.x, currentRot.y, currentRot.z)
        local rad_pitch = math.rad(cam_rot.x)
        local rad_yaw = math.rad(cam_rot.z)

        cam_pos = vector3(
            cam_pos.x + forward * (-math.sin(rad_yaw)) * math.cos(rad_pitch) * speed,
            cam_pos.y + forward * (math.cos(rad_yaw)) * math.cos(rad_pitch) * speed,
            cam_pos.z + forward * (math.sin(rad_pitch)) * speed
        )
        cam_pos = vector3(
            cam_pos.x + sideways * (math.cos(rad_yaw)) * speed,
            cam_pos.y + sideways * (math.sin(rad_yaw)) * speed,
            cam_pos.z
        )
        cam_pos = vector3(cam_pos.x, cam_pos.y, cam_pos.z + vertical * speed)

        ForceWorldLoad()
        if type(Susano.SetCameraPos) == "function" then
            Susano.SetCameraPos(cam_pos.x, cam_pos.y, cam_pos.z)
        end
    end
end

-- Main freecam thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if freecam_active then
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 14, true)
            EnableControlAction(0, 15, true)
            EnableControlAction(0, 24, true)

            -- Allow Menu Controls if Open
            if menuOpen then
                EnableControlAction(0, 172, true) -- KEY_UP
                EnableControlAction(0, 173, true) -- KEY_DOWN
                EnableControlAction(0, 174, true) -- KEY_LEFT
                EnableControlAction(0, 175, true) -- KEY_RIGHT
                EnableControlAction(0, 191, true) -- KEY_SELECT
                EnableControlAction(0, 194, true) -- KEY_BACK
            end

            if not menuOpen then
                HandleInputMenu()
            end
            UpdateFreecam()
        end

        DrawFreecamHint()
    end
end)

-- Keybind toggle thread
Citizen.CreateThread(function()
    local lastKeyPress = 0
    while true do
        Citizen.Wait(0)
        
        if type(Susano.GetAsyncKeyState) == "function" then
            local currentKeybind = freecam_keybinds[freecam_keybind_idx]
            if Susano.GetAsyncKeyState(currentKeybind.key) and (GetGameTimer() - lastKeyPress) > 400 then
                lastKeyPress = GetGameTimer()
                ToggleSusanoFreecam()
            end
        end
    end
end)

normal_speed = freecam_speed
fast_speed = freecam_speed * 5.0

-- Toggle from menu
function ToggleSusanoFreecam()
    freecam_active = not freecam_active
    _G.freecam_active = freecam_active
    if freecam_active then
        StartFreecam()
        FreecamSelectedOption = 1
        -- ShowDynastyNotification("Susano Freecam: ~g~ON")
    else
        StopFreecam()
        -- ShowDynastyNotification("Susano Freecam: ~r~OFF")
    end
end

-- Redundant Freecam Speed logic removed, using GetMiscOptions dynamic string

Menu.State.noclipActive = false
-- local Menu.State.noclipSpeed = 1.0 (Removed to fix scope issue)

function Menu.Actions.ToggleNoclip()
    if not Menu.State.bypassLoaded and not Menu.State.noclipActive then
        ShowDynastyNotification("~r~Bypass Required!")
        return 
    end
    Menu.State.noclipActive = not Menu.State.noclipActive
    
    if Menu.State.noclipActive then
        Citizen.CreateThread(function()
            local currentSpeed = Menu.State.noclipSpeed or 1.0
            while Menu.State.noclipActive do
                local ped = PlayerPedId()
                local veh = GetVehiclePedIsIn(ped, false)
                local entity = (veh and veh ~= 0) and veh or ped
                
                SetEntityCollision(entity, false, false)
                FreezeEntityPosition(entity, true)
                
                local coords = GetEntityCoords(entity)
                local camRot = GetGameplayCamRot(2)
                
                local pitch = math.rad(camRot.x)
                local yaw = math.rad(camRot.z)
                
                local vx = -math.sin(yaw) * math.abs(math.cos(pitch))
                local vy = math.cos(yaw) * math.abs(math.cos(pitch))
                local vz = math.sin(pitch)
                
                local rx = math.cos(yaw)
                local ry = math.sin(yaw)
                
                local moveSpeed = currentSpeed
                if IsDisabledControlPressed(0, 21) then
                    moveSpeed = currentSpeed * 2.5
                end
                
                local newPos = coords
                
                if IsDisabledControlPressed(0, 32) then
                    newPos = vector3(newPos.x + vx * moveSpeed, newPos.y + vy * moveSpeed, newPos.z + vz * moveSpeed)
                end
                
                if IsDisabledControlPressed(0, 33) then
                    newPos = vector3(newPos.x - vx * moveSpeed, newPos.y - vy * moveSpeed, newPos.z - vz * moveSpeed)
                end
                
                if IsDisabledControlPressed(0, 34) then
                    newPos = vector3(newPos.x - rx * moveSpeed, newPos.y - ry * moveSpeed, newPos.z)
                end
                
                if IsDisabledControlPressed(0, 35) then
                    newPos = vector3(newPos.x + rx * moveSpeed, newPos.y + ry * moveSpeed, newPos.z)
                end
                
                if IsDisabledControlPressed(0, 22) then
                    newPos = vector3(newPos.x, newPos.y, newPos.z + moveSpeed)
                end
                
                if IsDisabledControlPressed(0, 36) then
                    newPos = vector3(newPos.x, newPos.y, newPos.z - moveSpeed)
                end
                
                SetEntityCoordsNoOffset(entity, newPos.x, newPos.y, newPos.z, true, true, true)
                
                if entity == ped then
                    SetEntityHeading(ped, camRot.z)
                end
                
                Citizen.Wait(0)
            end
            
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            local entity = (veh and veh ~= 0) and veh or ped
            SetEntityCollision(entity, true, true)
            FreezeEntityPosition(entity, false)
        end)
        ShowDynastyNotification("Noclip: ~g~ON")
    else

    end
end

-- Old Anti-TP Thread removed in favor of ToggleAntiTeleport function

function Menu.Actions.HealPlayer()
    local ped = PlayerPedId()
    local maxHealth = GetEntityMaxHealth(ped)
    SetEntityHealth(ped, maxHealth)

end

function Menu.Actions.ToggleAntiTeleport(enable)
    Menu.State.antiTpActive = enable
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        if enable then
            ShowDynastyNotification("Anti-Teleport (Bypass Putin): ~g~ON")
        else
            ShowDynastyNotification("Anti-Teleport (Bypass Putin): ~r~OFF")
        end

        Citizen.CreateThread(function()
            -- LAYER 1: Native Hooks (Inject into AntiTeleportHook)
            local nativeCode = string.format([[
                local susano = rawget(_G, "Susano")
                _G.AntiTeleportEnabled = %s

                if not _G.AntiTeleportHookInstalled and susano and type(susano.HookNative) == "function" then
                    _G.AntiTeleportHookInstalled = true

                    -- Intercepte SetEntityCoords
                    susano.HookNative(0x06840DA4F9E24E4D, function(entity, x, y, z, xAxis, yAxis, zAxis, clearArea)
                        if _G.AntiTeleportEnabled and entity == PlayerPedId() then
                            return false -- Blocage du TP forcé
                        end
                        return true
                    end)

                    -- Intercepte SetEntityCoordsNoOffset
                    susano.HookNative(0x239A3351C7284A45, function(entity, x, y, z, xAxis, yAxis, zAxis)
                        if _G.AntiTeleportEnabled and entity == PlayerPedId() then
                            return false
                        end
                        return true
                    end)
                end
            ]], tostring(enable))
            Susano.InjectResource("AntiTeleportHook", nativeCode)

            Citizen.Wait(50)

            -- LAYER 2: Event Interception (Inject into Putin resource)
            local eventCode = string.format([[
            if _G.AntiTeleportEnabled == nil then _G.AntiTeleportEnabled = false end
            _G.AntiTeleportEnabled = %s

            if not _G.AntiTeleportEventHooksInstalled then
                _G.AntiTeleportEventHooksInstalled = true

                -- Bloque les événements de TP classiques (Admin menus)
                AddEventHandler("admin:TeleportPlayer", function(target, coords)
                    if _G.AntiTeleportEnabled then
                        CancelEvent()
                    end
                end)
                
                AddEventHandler("admin:TpToPlayer", function(coords)
                    if _G.AntiTeleportEnabled then
                        CancelEvent()
                    end
                end)
            end
            ]], tostring(enable))
            Susano.InjectResource("Putin", eventCode)
        end)
    else
        ShowDynastyNotification("~r~Erreur : Susano n'est pas disponible")
    end

    -- LAYER 3: Robust Distance Detection (Local fallback)
    if enable then
        CreateThread(function()
            local lastPos = GetEntityCoords(PlayerPedId())
            while Menu.State.antiTpActive do
                local playerPed = PlayerPedId()
                local currentPos = GetEntityCoords(playerPed)
                
                SetPedCanRagdoll(playerPed, false)
                SetPedConfigFlag(playerPed, 128, true)
                SetPedConfigFlag(playerPed, 401, true)
                
                if not Menu.State.noclipActive and not _G.Menu.State.Freecam.active then
                    local dist = #(currentPos - lastPos)
                    if dist > 50.0 and not IsPedFalling(playerPed) and not IsPedInParachuteFreeFall(playerPed) then
                        SetEntityCoordsNoOffset(playerPed, lastPos.x, lastPos.y, lastPos.z, false, false, false)
                        currentPos = lastPos
                    end
                end

                lastPos = currentPos
                Wait(0)
            end
            
            local ped = PlayerPedId()
            if DoesEntityExist(ped) then
                SetPedCanRagdoll(ped, true)
                SetPedConfigFlag(ped, 128, false)
                SetPedConfigFlag(ped, 401, false)
            end
        end)
    end
end

function Menu.Actions.CleanPed()
    ClearPedBloodDamage(PlayerPedId())
    ResetPedVisibleDamage(PlayerPedId())

end

function Menu.Actions.FixVehicle()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
        SetVehicleUndriveable(veh, false)
        SetVehicleEngineOn(veh, true, true, false)

    else
        ShowDynastyNotification("~r~Not in vehicle")
    end
end

function Menu.Actions.MaxUpgradeVehicle()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
        SetVehicleDirtLevel(veh, 0.0)
        
        -- Performance & Cosmetics (Loop all except Livery/Stickers)
        SetVehicleModKit(veh, 0)
        for i = 0, 49 do
            if i ~= 48 then -- Skip Livery/Stickers
                local numMods = GetNumVehicleMods(veh, i)
                if numMods > 0 then
                    SetVehicleMod(veh, i, numMods - 1, false)
                end
            end
        end

        -- Toggles
        ToggleVehicleMod(veh, 18, true) -- Turbo
        ToggleVehicleMod(veh, 20, true) -- Tire Smoke
        ToggleVehicleMod(veh, 22, true) -- Xenon

        -- Colors (Optional: Set to nice colors or keep?)
        -- User said "full custom". Usually implies maxing stats.
        -- We won't change paint colors forceably unless requested, but we set neon/xenon.
        
        -- Neon
        SetVehicleNeonLightEnabled(veh, 0, true)
        SetVehicleNeonLightEnabled(veh, 1, true)
        SetVehicleNeonLightEnabled(veh, 2, true)
        SetVehicleNeonLightEnabled(veh, 3, true)
        SetVehicleNeonLightsColour(veh, 255, 0, 255) -- Purple (Dynasty style)
        
        -- Max Stats
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleBodyHealth(veh, 1000.0)
        SetVehiclePetrolTankHealth(veh, 1000.0)
        
        SetVehicleWindowTint(veh, 1) -- Pure Black
        

    else
        ShowDynastyNotification("~r~Not in vehicle")
    end
end

function Menu.Actions.KickVehicle()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        local maxSeats = GetVehicleMaxNumberOfPassengers(veh)
        local kickedCount = 0
        
        for i = -1, maxSeats - 1 do
            local passenger = GetPedInVehicleSeat(veh, i)
            if passenger ~= 0 and passenger ~= ped and DoesEntityExist(passenger) then
                TaskLeaveVehicle(passenger, veh, 4160)
                kickedCount = kickedCount + 1
            end
        end
        
        if kickedCount > 0 then

        end
    else
        ShowDynastyNotification("~r~Not in vehicle")
    end
end

function Menu.Actions.BreakAllNearbyWheels()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicles = GetGamePool('CVehicle')
    local count = 0

    for _, vehicle in ipairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehicleCoords)

        if distance <= 150.0 then
            if NetworkGetEntityIsNetworked(vehicle) then
                NetworkRequestControlOfEntity(vehicle)
            end
            
            SetVehicleWheelsCanBreak(vehicle, true)
            for i = 0, 7 do
                SetVehicleWheelHealth(vehicle, i, 0.0)
                BreakOffVehicleWheel(vehicle, i, true, true, true, false)
            end
            count = count + 1
        end
    end
    
    if count > 0 then

    else

    end
end

Menu.State.fovWarpActive = false

function Menu.Actions.ToggleFOVWarp()
    Menu.State.fovWarpActive = not Menu.State.fovWarpActive
    
    if Menu.State.fovWarpActive then
        ShowDynastyNotification("FOV Warp: ~g~ON~w~ | Press ~p~X~w~ to warp")
        
        CreateThread(function()
            -- Optimize: Load textures once outside the loop
            if not HasStreamedTextureDictLoaded("commonmenu") then
                RequestStreamedTextureDict("commonmenu", true)
            end
            if not HasStreamedTextureDictLoaded("mp_inventory") then
                RequestStreamedTextureDict("mp_inventory", true)
            end

            while Menu.State.fovWarpActive do
                Wait(0)
                
                local aspect = GetAspectRatio(false)
                local scale = 0.42
                
                if HasStreamedTextureDictLoaded("mp_inventory") then
                    -- Draw the ring (contour only)
                    -- Black, semi-transparent (120 alpha)
                    DrawSprite("mp_inventory", "tab_selector", 0.5, 0.5, scale / aspect, scale, 0.0, 0, 0, 0, 120)
                end

                if IsControlJustPressed(0, 73) then -- X key (INPUT_VEH_DUCK)
                    local playerPed = PlayerPedId()
                    local camCoords = GetGameplayCamCoord()
                    
                    if not HasStreamedTextureDictLoaded("commonmenu") then
                        RequestStreamedTextureDict("commonmenu", true)
                    end

                    -- Find closest vehicle/entity within FOV circle
                    local screenW, screenH = GetActiveScreenResolution()
                    local centerX, centerY = 0.5, 0.5
                    local aspect = GetAspectRatio(false)
                    local scale = 0.45 -- Circle Scale
                    
                    local vehicles = (type(GetGamePool) == "function" and GetGamePool("CVehicle")) or {}
                    local bestTarget = nil
                    local minDistanceToCenter = scale / 2.0
                    local maxWarpDistance = 150.0 -- FOV Warp Distance: 150m
                    
                    if type(vehicles) == "table" then
                        for _, veh in ipairs(vehicles) do
                            if DoesEntityExist(veh) then
                                local vCoords = GetEntityCoords(veh)
                                local distToVeh = #(vCoords - camCoords)
                                
                                if distToVeh < maxWarpDistance then
                                    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(vCoords.x, vCoords.y, vCoords.z)
                                    
                                    if onScreen then
                                        local dx = (screenX - centerX) * aspect
                                        local dy = screenY - centerY
                                        local dist = math.sqrt(dx*dx + dy*dy)
                                        
                                        if dist < minDistanceToCenter then
                                            minDistanceToCenter = dist
                                            bestTarget = veh
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if bestTarget then
                         -- Use the shared robust hijack logic
                        Menu.Helpers.HijackVehicle(bestTarget, playerPed)
                        ShowDynastyNotification("~g~Vehicle Hijacked!")
                    end
                end
            end
        end)
    else
        ShowDynastyNotification("FOV Warp: ~r~OFF")
    end
end

function Menu.Helpers.HijackVehicle(targetVehicle, playerPed)
    if not DoesEntityExist(targetVehicle) then return false end

    -- Force ownership/mission status for sync
    SetEntityAsMissionEntity(targetVehicle, true, true)
    if NetworkGetEntityIsNetworked(targetVehicle) then
        SetNetworkIdCanMigrate(ObjToNet(targetVehicle), true)
        SetNetworkIdExistsOnAllMachines(ObjToNet(targetVehicle), true)
    end

    -- Internal helper function for control
    local function RequestControl(entity, timeoutMs)
        if not entity or not DoesEntityExist(entity) then return false end
        if NetworkHasControlOfEntity(entity) then return true end
        local start = GetGameTimer()
        NetworkRequestControlOfEntity(entity)
        while not NetworkHasControlOfEntity(entity) do
            Wait(0)
            if GetGameTimer() - start > (timeoutMs or 500) then return false end
            NetworkRequestControlOfEntity(entity)
        end
        return true
    end

    local function tryEnter(v, s)
        SetPedIntoVehicle(playerPed, v, s)
        Wait(50) 
        local inVeh = IsPedInVehicle(playerPed, v, false)
        local curSeat = -2
        if inVeh then
            for seat = -1, 4 do 
                if GetPedInVehicleSeat(v, seat) == playerPed then
                    curSeat = seat
                    break
                end
            end
        end
        return inVeh, curSeat
    end

    -- Teleportation
    local vehCoords = GetEntityCoords(targetVehicle)
    SetEntityCoords(playerPed, vehCoords.x, vehCoords.y, vehCoords.z - 0.5, false, false, false, false)
    Wait(10)

    -- HIJACK LOGIC
    RequestControl(targetVehicle, 500)
    SetVehicleDoorsLocked(targetVehicle, 1)
    SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)

    local success = false
    local tStart = GetGameTimer()

    while (GetGameTimer() - tStart) < 1500 do 
        RequestControl(targetVehicle, 300)

        local inVeh, seat = tryEnter(targetVehicle, -1)
        if not inVeh then
            for s = 0, 4 do 
                if IsVehicleSeatFree(targetVehicle, s) then
                    inVeh, seat = tryEnter(targetVehicle, s)
                    if inVeh then break end
                end
            end
        end

        if inVeh then
            local drv = GetPedInVehicleSeat(targetVehicle, -1)
            if drv ~= 0 and drv ~= playerPed and DoesEntityExist(drv) then
                if NetworkGetEntityIsNetworked(drv) then RequestControl(drv, 300) end
                SetEntityAsMissionEntity(drv, true, true)
                ClearPedTasksImmediately(drv)
                SetEntityCoords(drv, 0.0, 0.0, -100.0, false, false, false, false)
                DeleteEntity(drv)
            end

            if seat ~= -1 then
                SetPedIntoVehicle(playerPed, targetVehicle, -1)
                Wait(50)
                if GetPedInVehicleSeat(targetVehicle, -1) == playerPed then
                    success = true
                    break
                end
            else
                success = true
                break
            end
        else
            local drv = GetPedInVehicleSeat(targetVehicle, -1)
            if drv ~= 0 and drv ~= playerPed and DoesEntityExist(drv) then
                RequestControl(drv, 300)
                DeleteEntity(drv)
            end
        end
        Wait(10)
    end
    
    return success or IsPedInVehicle(playerPed, targetVehicle, false)
end

function Menu.Helpers.ProcessVehicleBroke(targetVehicle, playerPed)
    if not DoesEntityExist(targetVehicle) then return false end
    
    -- Robust "Already Broken" Check (Check actual wheel count)
    local numWheels = GetVehicleNumberOfWheels(targetVehicle)
    local isBroken = true
    for i = 0, numWheels - 1 do
        if not IsVehicleTyreBurst(targetVehicle, i, true) then 
            isBroken = false
            break
        end
    end
    if isBroken then return false end

    -- Perform Hijack
    local success = Menu.Helpers.HijackVehicle(targetVehicle, playerPed)

    -- Internals needed for action
    local function RequestControl(entity, timeoutMs)
        if not entity or not DoesEntityExist(entity) then return false end
        if NetworkHasControlOfEntity(entity) then return true end
        local start = GetGameTimer()
        NetworkRequestControlOfEntity(entity)
        while not NetworkHasControlOfEntity(entity) do
            Wait(0)
            if GetGameTimer() - start > (timeoutMs or 500) then return false end
            NetworkRequestControlOfEntity(entity)
        end
        return true
    end

    -- ACTION (Force sync ownership before damage)
    if success or IsPedInVehicle(playerPed, targetVehicle, false) then
        RequestControl(targetVehicle, 1000)
        SetVehicleHasBeenOwnedByPlayer(targetVehicle, true)
        SetEntityAsMissionEntity(targetVehicle, true, true)
        Wait(100) 

        -- NOW LEAVE
        TaskLeaveVehicle(playerPed, targetVehicle, 0)
        
        -- PRECISE TRIGGER: Break wheels when exit animation starts
        local exitStart = GetGameTimer()
        local wheelsBroken = false
        while (GetGameTimer() - exitStart) < 3000 do
            if not wheelsBroken and GetIsTaskActive(playerPed, 167) then 
                -- WAIT for manual feel (mimic 1 button press time)
                Wait(800)
                
                if RequestControl(targetVehicle, 500) then
                    SetVehicleWheelsCanBreak(targetVehicle, true)
                    for wheel = 0, numWheels - 1 do
                        SetVehicleWheelHealth(targetVehicle, wheel, 0.0)
                        BreakOffVehicleWheel(targetVehicle, wheel, true, true, true, false)
                    end
                    wheelsBroken = true
                end
            end
            if wheelsBroken and not IsPedInVehicle(playerPed, targetVehicle, false) then
                break
            end
            Wait(0)
        end
        
        local exitFinish = GetGameTimer()
        while (GetIsTaskActive(playerPed, 167) or IsPedInVehicle(playerPed, targetVehicle, false)) and (GetGameTimer() - exitFinish) < 1000 do
            Wait(0)
        end
        return true
    end
    return false
end

function Menu.Actions.BrokeAllVehicles()
    local radius = 150.0
    local playerPed = PlayerPedId()
    local myCoords = GetEntityCoords(playerPed)
    local myHeading = GetEntityHeading(playerPed)

    CreateThread(function()
        if rawget(_G, 'broke_all_busy') then return end
        rawset(_G, 'broke_all_busy', true)
        local initialCoords = GetEntityCoords(playerPed)

        -- Figer la caméra pour éviter le mal de mer pendant les téléportations
        local brokeCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        SetCamCoord(brokeCam, camCoords.x, camCoords.y, camCoords.z)
        SetCamRot(brokeCam, camRot.x, camRot.y, camRot.z, 2)
        SetCamFov(brokeCam, GetGameplayCamFov())
        SetCamActive(brokeCam, true)
        RenderScriptCams(true, false, 0, true, true)

        -- Préparer ton personnage
        SetEntityVisible(playerPed, false, false)
        FreezeEntityPosition(playerPed, false)
        ClearPedTasksImmediately(playerPed)

        local count = 0
        local pool = GetGamePool('CVehicle')
        local myVeh = GetVehiclePedIsIn(playerPed, false)

        for _, veh in ipairs(pool) do
            if DoesEntityExist(veh) and veh ~= myVeh then
                local vehCoords = GetEntityCoords(veh)
                if #(myCoords - vehCoords) <= radius and GetVehicleClass(veh) ~= 13 then
                    if Menu.Helpers.ProcessVehicleBroke(veh, playerPed) then
                        count = count + 1
                    end
                end
            end
            Wait(0) -- No block
        end

        ClearPedTasksImmediately(playerPed)
        SetEntityCoords(playerPed, initialCoords.x, initialCoords.y, initialCoords.z, false, false, false, false)
        FreezeEntityPosition(playerPed, false)
        SetEntityVisible(playerPed, true, false)

        -- Débloquer la caméra
        SetCamActive(brokeCam, false)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(brokeCam, true)

        -- Notification
        ShowDynastyNotification("~g~Broke All: " .. count .. " véhicules détruits.")
        rawset(_G, 'broke_all_busy', false)
    end)
end

function Menu.Actions.ToggleInteractEmote(emoteType)
    if not selectedPlayer then return end
    local targetServerId = selectedPlayer.serverId

    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then return end

    -- Toggle OFF
    if interactEmoteType == emoteType then
        interactEmoteType = nil
        local flagName = emoteType .. "_active"
        if emoteType == "fuck" then flagName = "backshots_active" end -- Maintain compatibility with existing script if needed, or just unify it.
        
        -- Let's unify it to emoteType .. "_active" for simplicity
        flagName = emoteType .. "_active"
        if emoteType == "fuck" then flagName = "fuck_active" end

        Susano.InjectResource("any", string.format([[
            rawset(_G, '%s', false)
            rawset(_G, '%s_target_ped', nil)
            local playerPed = PlayerPedId()
            if DoesEntityExist(playerPed) then
                if IsEntityAttached(playerPed) then DetachEntity(playerPed, true, false) end
                ClearPedTasksImmediately(playerPed)
            end
        ]], flagName, emoteType))
        return
    end

    if interactEmoteType and interactEmoteType ~= emoteType then
        local oldFlag = interactEmoteType .. "_active"
        Susano.InjectResource("any", string.format([[
            rawset(_G, '%s', false)
            rawset(_G, '%s_target_ped', nil)
            local playerPed = PlayerPedId()
            if DoesEntityExist(playerPed) then
                if IsEntityAttached(playerPed) then DetachEntity(playerPed, true, false) end
                ClearPedTasksImmediately(playerPed)
            end
        ]], oldFlag, interactEmoteType))
    end

    interactEmoteType = emoteType

    if emoteType == "twerk" then
        Susano.InjectResource("any", string.format([[
            local targetServerId = %d
            local playerPed = PlayerPedId()
            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then targetPlayerId = player break end
            end
            if not targetPlayerId then return end
            local targetPed = GetPlayerPed(targetPlayerId)
            if not DoesEntityExist(targetPed) then return end

            if rawget(_G, 'twerk_active') then
                ClearPedSecondaryTask(playerPed)
                DetachEntity(playerPed, true, false)
                rawset(_G, 'twerk_active', false)
            else
                rawset(_G, 'twerk_active', true)
                rawset(_G, 'twerk_target_ped', targetPed)
                if not HasAnimDictLoaded("switch@trevor@mocks_lapdance") then
                    RequestAnimDict("switch@trevor@mocks_lapdance")
                    while not HasAnimDictLoaded("switch@trevor@mocks_lapdance") do Wait(0) end
                end
                AttachEntityToEntity(playerPed, targetPed, 4103, 0.05, 0.38, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                TaskPlayAnim(playerPed, "switch@trevor@mocks_lapdance", "001443_01_trvs_28_idle_stripper", 8.0, -8.0, 100000, 33, 0, false, false, false)

                CreateThread(function()
                    while rawget(_G, 'twerk_active') do
                        Wait(0)
                        local myPed = playerPed
                        local tPed = rawget(_G, 'twerk_target_ped')
                        if not DoesEntityExist(myPed) or not DoesEntityExist(tPed) then
                            rawset(_G, 'twerk_active', false)
                            rawset(_G, 'twerk_target_ped', nil)
                            break
                        end
                        if not IsEntityAttachedToEntity(myPed, tPed) then
                            AttachEntityToEntity(myPed, tPed, 4103, 0.05, 0.38, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                        end
                        if not IsEntityPlayingAnim(myPed, "switch@trevor@mocks_lapdance", "001443_01_trvs_28_idle_stripper", 3) then
                            TaskPlayAnim(myPed, "switch@trevor@mocks_lapdance", "001443_01_trvs_28_idle_stripper", 8.0, -8.0, 100000, 33, 0, false, false, false)
                        end
                    end
                    if DoesEntityExist(playerPed) then
                        if IsEntityAttached(playerPed) then DetachEntity(playerPed, true, false) end
                        ClearPedTasksImmediately(playerPed)
                    end
                end)
            end
        ]], targetServerId))

    elseif emoteType == "fuck" then
        Susano.InjectResource("any", string.format([[
            local targetServerId = %d
            local playerPed = PlayerPedId()
            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then targetPlayerId = player break end
            end
            if not targetPlayerId then return end
            local targetPed = GetPlayerPed(targetPlayerId)
            if not DoesEntityExist(targetPed) then return end

            if rawget(_G, 'fuck_active') then
                rawset(_G, 'fuck_active', false)
            else
                rawset(_G, 'fuck_active', true)
                rawset(_G, 'fuck_target_ped', targetPed)
                if not HasAnimDictLoaded("rcmpaparazzo_2") then
                    RequestAnimDict("rcmpaparazzo_2")
                    while not HasAnimDictLoaded("rcmpaparazzo_2") do Wait(0) end
                end
                AttachEntityToEntity(PlayerPedId(), targetPed, 4103, 0.04, -0.4, 0.1, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                TaskPlayAnim(PlayerPedId(), "rcmpaparazzo_2", "shag_loop_a", 8.0, -8.0, 100000, 33, 0, false, false, false)

                CreateThread(function()
                    while rawget(_G, 'fuck_active') do
                        Wait(0)
                        local myPed = playerPed
                        local tPed = rawget(_G, 'fuck_target_ped')
                        if not DoesEntityExist(myPed) or not DoesEntityExist(tPed) then
                            rawset(_G, 'fuck_active', false)
                            rawset(_G, 'fuck_target_ped', nil)
                            break
                        end
                        if not IsEntityAttachedToEntity(myPed, tPed) then
                            AttachEntityToEntity(myPed, tPed, 4103, 0.04, -0.4, 0.1, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                        end
                        if not IsEntityPlayingAnim(myPed, "rcmpaparazzo_2", "shag_loop_a", 3) then
                            TaskPlayAnim(myPed, "rcmpaparazzo_2", "shag_loop_a", 8.0, -8.0, 100000, 33, 0, false, false, false)
                        end
                    end
                    if DoesEntityExist(playerPed) then
                        if IsEntityAttached(playerPed) then DetachEntity(playerPed, true, false) end
                        ClearPedTasksImmediately(playerPed)
                    end
                end)
            end
        ]], targetServerId))

    elseif emoteType == "wank" then
        Susano.InjectResource("any", string.format([[
            local targetServerId = %d
            local playerPed = PlayerPedId()
            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then targetPlayerId = player break end
            end
            if not targetPlayerId then return end
            local targetPed = GetPlayerPed(targetPlayerId)
            if not DoesEntityExist(targetPed) then return end

            rawset(_G, 'wank_active', true)
            rawset(_G, 'wank_target_ped', targetPed)

            if not HasAnimDictLoaded("mp_player_int_upperwank") then
                RequestAnimDict("mp_player_int_upperwank")
                while not HasAnimDictLoaded("mp_player_int_upperwank") do Wait(0) end
            end

            AttachEntityToEntity(playerPed, targetPed, 4103, 0.0, -0.3, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            TaskPlayAnim(playerPed, "mp_player_int_upperwank", "mp_player_int_wank_01", 8.0, -8.0, 100000, 51, 1.0, false, false, false)

            CreateThread(function()
                while rawget(_G, 'wank_active') do
                    Wait(0)
                    local myPed = playerPed
                    local tPed = rawget(_G, 'wank_target_ped')
                    if not DoesEntityExist(myPed) or not DoesEntityExist(tPed) then
                        rawset(_G, 'wank_active', false)
                        rawset(_G, 'wank_target_ped', nil)
                        break
                    end
                    if not IsEntityAttachedToEntity(myPed, tPed) then
                        AttachEntityToEntity(myPed, tPed, 4103, 0.0, -0.3, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                    end
                    if not IsEntityPlayingAnim(myPed, "mp_player_int_upperwank", "mp_player_int_wank_01", 3) then
                        TaskPlayAnim(myPed, "mp_player_int_upperwank", "mp_player_int_wank_01", 8.0, -8.0, 100000, 51, 1.0, false, false, false)
                    end
                end
                if DoesEntityExist(playerPed) then
                    if IsEntityAttached(playerPed) then DetachEntity(playerPed, true, false) end
                    ClearPedTasksImmediately(playerPed)
                end
            end)
        ]], targetServerId))

    elseif emoteType == "piggyback" then
        Susano.InjectResource("any", string.format([[
            local targetServerId = %d
            local playerPed = PlayerPedId()
            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then targetPlayerId = player break end
            end
            if not targetPlayerId then return end
            local targetPed = GetPlayerPed(targetPlayerId)
            if not DoesEntityExist(targetPed) then return end

            if rawget(_G, 'piggyback_active') then
                ClearPedSecondaryTask(playerPed)
                DetachEntity(playerPed, true, false)
                rawset(_G, 'piggyback_active', false)
            else
                rawset(_G, 'piggyback_active', true)
                rawset(_G, 'piggyback_target_ped', targetPed)
                if not HasAnimDictLoaded("anim@arena@celeb@flat@paired@no_props@") then
                    RequestAnimDict("anim@arena@celeb@flat@paired@no_props@")
                    while not HasAnimDictLoaded("anim@arena@celeb@flat@paired@no_props@") do Wait(0) end
                end
                AttachEntityToEntity(PlayerPedId(), targetPed, 0, 0.0, -0.25, 0.45, 0.5, 0.5, 180, false, false, false, false, 2, false)
                TaskPlayAnim(PlayerPedId(), "anim@arena@celeb@flat@paired@no_props@", "piggyback_c_player_b", 8.0, -8.0, 1000000, 33, 0, false, false, false)

                CreateThread(function()
                    while rawget(_G, 'piggyback_active') do
                        Wait(0)
                        local myPed = playerPed
                        local tPed = rawget(_G, 'piggyback_target_ped')
                        if not DoesEntityExist(myPed) or not DoesEntityExist(tPed) then
                            rawset(_G, 'piggyback_active', false)
                            rawset(_G, 'piggyback_target_ped', nil)
                            break
                        end
                        if not IsEntityAttachedToEntity(myPed, tPed) then
                            AttachEntityToEntity(myPed, tPed, 0, 0.0, -0.25, 0.45, 0.5, 0.5, 180, false, false, false, false, 2, false)
                        end
                        if not IsEntityPlayingAnim(myPed, "anim@arena@celeb@flat@paired@no_props@", "piggyback_c_player_b", 3) then
                            TaskPlayAnim(myPed, "anim@arena@celeb@flat@paired@no_props@", "piggyback_c_player_b", 8.0, -8.0, 1000000, 33, 0, false, false, false)
                        end
                    end
                    if DoesEntityExist(playerPed) then
                        if IsEntityAttached(playerPed) then DetachEntity(playerPed, true, false) end
                        ClearPedTasksImmediately(playerPed)
                    end
                end)
            end
        ]], targetServerId))
    end
end


function Menu.Helpers.RenderSideEmoteMenu(mainX, listTopY, mainW, scale)
    local sw, sh = GetActiveScreenResolution()
    local sideW = 0.052 * scale * sw -- Forme carrée
    local sideX = mainX + mainW + (5 * scale)
    local sideOptH = 0.024 * scale * sh
    local padding = 4 * scale
    local sideH = (4 * sideOptH) + (padding * 2)
    
    -- Juste un tout petit peu plus haut
    local sideY = listTopY + (230 * scale)
    
    local options = {"Twerk", "Baise", "Branlette", "Piggyback"}
    local types = {"twerk", "fuck", "wank", "piggyback"}
    
    -- Background
    Susano.DrawRectFilled(sideX, sideY, sideW, sideH, 0.02, 0.02, 0.02, 0.95, 0.0)
    
    for i, label in ipairs(options) do
        local optY = sideY + padding + (i-1) * sideOptH
        local optH = sideOptH
        local isSelected = (sideMenuOption == i and sideMenuFocus)
        local isActive = (interactEmoteType == types[i])
        
        if isSelected then
            local r = (Menu.Colors.SelectedBg.r / 255)
            local g = (Menu.Colors.SelectedBg.g / 255)
            local b = (Menu.Colors.SelectedBg.b / 255)
            Susano.DrawRectFilled(sideX + 5, optY, sideW - 10, optH, r, g, b, 0.8, 0.0)
        end
        
        local fontSize = 13 * scale -- Texte légèrement plus petit encore
        Susano.DrawText(sideX + 15, optY + (optH - fontSize)/2, label, fontSize, 0.94, 0.94, 0.92, 1)
        
        -- Checkbox
        local boxSize = 10 * scale
        local boxX = sideX + sideW - boxSize - 15
        local boxY = optY + (optH - boxSize)/2
        
        Susano.DrawRectFilled(boxX, boxY, boxSize, boxSize, 0.1, 0.1, 0.1, 1.0, 2.0) -- Border
        if isActive then
            Susano.DrawText(boxX + 2, boxY - 1, "v", 8 * scale, 1, 1, 1, 1) -- Visual check
        end
    end
end

function Menu.Actions.ToggleRampVehicle()
    Menu.State.rampVehicleActive = not Menu.State.rampVehicleActive

    if not Menu.State.rampVehicleActive then
        for _, veh in ipairs(rampVehiclesAttached) do
            if DoesEntityExist(veh) then
                DetachEntity(veh, true, true)
            end
        end
        rampVehiclesAttached = {}

        return
    end

    CreateThread(function()
        local playerPed = PlayerPedId()
        if not IsPedInAnyVehicle(playerPed, false) then
            Menu.State.rampVehicleActive = false

            return
        end

        local myVehicle = GetVehiclePedIsIn(playerPed, false)
        if not DoesEntityExist(myVehicle) or GetPedInVehicleSeat(myVehicle, -1) ~= playerPed then
            Menu.State.rampVehicleActive = false

            return
        end

        local myCoords = GetEntityCoords(myVehicle)
        local vehicles = {}
        local searchRadius = 100.0
        local vehHandle, veh = FindFirstVehicle()
        local success

        repeat
            local vehCoords = GetEntityCoords(veh)
            local distance = #(myCoords - vehCoords)
            local vehClass = GetVehicleClass(veh)
            if distance <= searchRadius and veh ~= myVehicle and vehClass ~= 8 and vehClass ~= 13 then
                table.insert(vehicles, {handle = veh, distance = distance})
            end
            success, veh = FindNextVehicle(vehHandle)
        until not success
        EndFindVehicle(vehHandle)

        if #vehicles < 3 then
            Menu.State.rampVehicleActive = false

            return
        end

        table.sort(vehicles, function(a, b) return a.distance < b.distance end)
        local selectedVehicles = {vehicles[1].handle, vehicles[2].handle, vehicles[3].handle}

        local function takeControl(veh)
            SetPedIntoVehicle(playerPed, veh, -1)
            Wait(150)
            SetEntityAsMissionEntity(veh, true, true)
            if NetworkGetEntityIsNetworked(veh) then
                NetworkRequestControlOfEntity(veh)
                local timeout = 0
                while not NetworkHasControlOfEntity(veh) and timeout < 50 do
                    NetworkRequestControlOfEntity(veh)
                    Wait(10)
                    timeout = timeout + 1
                end
            end
        end

        for i = 1, 3 do
            if DoesEntityExist(selectedVehicles[i]) then
                takeControl(selectedVehicles[i])
            end
        end

        SetPedIntoVehicle(playerPed, myVehicle, -1)
        Wait(100)

        local rampPositions = {
            {offsetX = -2.0, offsetY = 2.5, offsetZ = 0.2, rotX = 160.0, rotY = 0.0, rotZ = 0.0},
            {offsetX = 0.0,  offsetY = 2.5, offsetZ = 0.2, rotX = 160.0, rotY = 0.0, rotZ = 0.0},
            {offsetX = 2.0,  offsetY = 2.5, offsetZ = 0.2, rotX = 160.0, rotY = 0.0, rotZ = 0.0},
        }

        rampVehiclesAttached = {}
        for i = 1, 3 do
            if DoesEntityExist(selectedVehicles[i]) then
                local pos = rampPositions[i]
                AttachEntityToEntity(selectedVehicles[i], myVehicle, 0, pos.offsetX, pos.offsetY, pos.offsetZ, pos.rotX, pos.rotY, pos.rotZ, false, false, true, false, 2, true)
                table.insert(rampVehiclesAttached, selectedVehicles[i])
            end
        end


    end)
end

function Menu.Helpers.ActivateCarry()
    carryActive = true


    CreateThread(function()
        while carryActive do
            if not carriedVehicle then
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("~p~[E]~w~ Porter vÃ©hicule")
                EndTextCommandDisplayHelp(0, false, true, -1)
            else
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("~p~[E]~w~ Lancer vÃ©hicule")
                EndTextCommandDisplayHelp(0, false, true, -1)
            end

            if IsControlJustPressed(0, Menu.Keys.CARRY) then
                if not carriedVehicle then
                    local ped = PlayerPedId()
                    local coords = GetEntityCoords(ped)

                    local closestVeh = nil
                    local closestDist = 10.0

                    for _, veh in ipairs(GetGamePool('CVehicle')) do
                        if DoesEntityExist(veh) then
                            local vehCoords = GetEntityCoords(veh)
                            local dist = #(coords - vehCoords)
                            if dist < closestDist then
                                closestDist = dist
                                closestVeh = veh
                            end
                        end
                    end

                    if closestVeh then
                        carriedVehicle = closestVeh
                        AttachEntityToEntity(carriedVehicle, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 2.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                        SetEntityCollision(carriedVehicle, false, false)

                    else

                    end
                else
                    DetachEntity(carriedVehicle, true, true)
                    local ped = PlayerPedId()
                    local forward = GetEntityForwardVector(ped)
                    SetEntityVelocity(carriedVehicle, forward.x * 150, forward.y * 150, 80.0)
                    ApplyForceToEntity(carriedVehicle, 1, 0, 0, 0, math.random(-50, 50), math.random(-50, 50), math.random(-50, 50), 0, false, true, true, false, true)
                    SetEntityCollision(carriedVehicle, true, true)

                    carriedVehicle = nil
                end
            end

            Wait(0)
        end

        if carriedVehicle then
            DetachEntity(carriedVehicle, true, true)
            SetEntityCollision(carriedVehicle, true, true)
            carriedVehicle = nil
        end
    end)
end

function Menu.Helpers.DeactivateCarry()
    carryActive = false
    if carriedVehicle then
        DetachEntity(carriedVehicle, true, true)
        SetEntityCollision(carriedVehicle, true, true)
        carriedVehicle = nil
    end

end

function Menu.Actions.ToggleCarryVehicle()
    if carryActive then
        Menu.Helpers.DeactivateCarry()
    else
        Menu.Helpers.ActivateCarry()
    end
end

function Menu.Actions.ToggleEasyHandling()
    Menu.State.easyHandlingActive = not Menu.State.easyHandlingActive

    if Menu.State.easyHandlingActive then
        CreateThread(function()
            while Menu.State.easyHandlingActive do
                Wait(0)
                local ped = PlayerPedId()
                if ped and ped ~= 0 then
                    local veh = GetVehiclePedIsIn(ped, false)
                    if veh and veh ~= 0 then
                        local strength = Menu.State.easyHandlingStrength or 0.0
                        SetVehicleGravityAmount(veh, 9.8 + strength)
                        SetVehicleStrong(veh, true)
                    end
                end
            end

            local ped = PlayerPedId()
            if ped and ped ~= 0 then
                local veh = GetVehiclePedIsIn(ped, false)
                if veh and veh ~= 0 then
                    SetVehicleGravityAmount(veh, 9.8)
                    SetVehicleStrong(veh, false)
                end
            end
        end)

    else

    end
end

local throwCarriedVehicle = nil

function Menu.Actions.ToggleThrowVehicle()
    Menu.State.throwVehicleActive = not Menu.State.throwVehicleActive

    if not Menu.State.throwVehicleActive then
        if throwCarriedVehicle and DoesEntityExist(throwCarriedVehicle) then
            DetachEntity(throwCarriedVehicle, true, true)
            SetEntityCollision(throwCarriedVehicle, true, true)
            throwCarriedVehicle = nil
        end

        return
    end



    CreateThread(function()
        while Menu.State.throwVehicleActive do
            Wait(0)

            if not throwCarriedVehicle then
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("~p~[E]~w~ Pick up vehicle")
                EndTextCommandDisplayHelp(0, false, true, -1)
            else
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("~p~[E]~w~ Throw vehicle")
                EndTextCommandDisplayHelp(0, false, true, -1)
            end

            if IsControlJustPressed(0, 51) then
                local ped = PlayerPedId()

                if not throwCarriedVehicle then
                    local coords = GetEntityCoords(ped)
                    local closestVeh = nil
                    local closestDist = 10.0

                    for _, veh in ipairs(GetGamePool('CVehicle')) do
                        if DoesEntityExist(veh) then
                            local vehCoords = GetEntityCoords(veh)
                            local dist = #(coords - vehCoords)
                            if dist < closestDist then
                                closestDist = dist
                                closestVeh = veh
                            end
                        end
                    end

                    if closestVeh then
                        NetworkRequestControlOfEntity(closestVeh)
                        throwCarriedVehicle = closestVeh
                        AttachEntityToEntity(throwCarriedVehicle, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 2.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                        SetEntityCollision(throwCarriedVehicle, false, false)

                    else

                    end
                else
                    DetachEntity(throwCarriedVehicle, true, true)
                    local forward = GetEntityForwardVector(ped)
                    SetEntityVelocity(throwCarriedVehicle, forward.x * 150.0, forward.y * 150.0, 80.0)
                    ApplyForceToEntity(throwCarriedVehicle, 1, 0.0, 0.0, 0.0, math.random(-50, 50) + 0.0, math.random(-50, 50) + 0.0, math.random(-50, 50) + 0.0, 0, false, true, true, false, true)
                    SetEntityCollision(throwCarriedVehicle, true, true)

                    throwCarriedVehicle = nil
                end
            end
        end

        if throwCarriedVehicle and DoesEntityExist(throwCarriedVehicle) then
            DetachEntity(throwCarriedVehicle, true, true)
            SetEntityCollision(throwCarriedVehicle, true, true)
            throwCarriedVehicle = nil
        end
    end)
end

function Menu.Actions.ToggleForceVehicleEngine(enable)
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            local susano = rawget(_G, "Susano")

            if susano and type(susano) == "table" and type(susano.HookNative) == "function" and not _force_engine_hooks_applied then
                _force_engine_hooks_applied = true

                susano.HookNative(0x8DE82BC774F3B862, function(entity)
                    return true
                end)

                susano.HookNative(0x4CEBC1ED31E8925E, function(entity)
                    return true
                end)

                susano.HookNative(0xAE3CBE5BF394C9C9, function(entity)
                    return true
                end)

                susano.HookNative(0x2B40A976, function(entity)
                    return true
                end)

                susano.HookNative(0xAD738C3085FE7E11, function(entity, p1, p2)
                    return true
                end)
            end

            _G.ForceVehicleEngineEnabled = %s

            if _G.ForceVehicleEngineThread then
            end

            _G.ForceVehicleEngineThread = CreateThread(function()
                while _G.ForceVehicleEngineEnabled do
                    Wait(0)

                    local ped = PlayerPedId()
                    local vehicle = GetVehiclePedIsIn(ped, false)

                    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                        if not NetworkHasControlOfEntity(vehicle) then
                            NetworkRequestControlOfEntity(vehicle)
                        end

                        SetVehicleEngineOn(vehicle, true, true, false)
                        SetVehicleEngineHealth(vehicle, 1000.0)
                        SetVehicleUndriveable(vehicle, false)
                    end
                end

                _G.ForceVehicleEngineThread = nil
            end)
        ]], tostring(enable)))

        forceEngineActive = enable
        if enable then

        else

        end
    else

    end
end

function Menu.Actions.ToggleShiftBoost(enable)
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            if QwErTyUiOpSh == nil then QwErTyUiOpSh = false end
            QwErTyUiOpSh = %s

            if QwErTyUiOpSh then
                local function ZxCvBnMmLl()
                    CreateThread(function()
                        while QwErTyUiOpSh and not Unloaded do
                            local ped = PlayerPedId()
                            if IsPedInAnyVehicle(ped, false) then
                                local veh = GetVehiclePedIsIn(ped, false)
                                if veh ~= 0 and IsDisabledControlJustPressed(0, 21) then
                                    SetVehicleForwardSpeed(veh, 150.0)
                                end
                            end
                            Wait(0)
                        end
                    end)
                end
                ZxCvBnMmLl()
            end
        ]], tostring(enable)))

        shiftBoostActive = enable
        if enable then

        else

        end
    else

    end
end

Menu.State.lunchingActive = false
local cachedReturnCoords = nil

-- ToggleSusanoFreecam is defined earlier (around line 2094)

function Menu.Helpers.ChangeSusanoFreecamSpeed()
    Menu.State.Freecam.speedIdx = (Menu.State.Freecam.speedIdx % #Menu.State.Freecam.speeds) + 1
    local newSpeed = Menu.State.Freecam.speeds[Menu.State.Freecam.speedIdx]
    _G.freecam_speed = newSpeed
    if type(SetFreecamSpeed) == "function" then
        SetFreecamSpeed(newSpeed)
    end
end

function Menu.Actions.ChangeSusanoFreecamKeybind()

end

function Menu.Actions.HijackPlayerVehicle()
    if not selectedPlayer then 
        ShowDynastyNotification("~r~Veuillez sélectionner un joueur !")
        return 
    end

    local targetServerId = selectedPlayer.serverId
    local targetClientId = GetPlayerFromServerId(targetServerId)

    if not targetClientId or targetClientId == -1 then
        ShowDynastyNotification("~r~Joueur introuvable !")
        return
    end

    local targetPed = GetPlayerPed(targetClientId)
    if not DoesEntityExist(targetPed) then
        ShowDynastyNotification("~r~Entité cible invalide !")
        return
    end
    
    local vehicle = GetVehiclePedIsIn(targetPed, false)
    if not DoesEntityExist(vehicle) or vehicle == 0 then
        ShowDynastyNotification("~r~La cible n'est pas dans un véhicule !")
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if not netId or netId == 0 then
        ShowDynastyNotification("~r~Erreur: Réseau du véhicule invalide !")
        return
    end

    ShowDynastyNotification("~b~Détournement en cours...")
    
    -- Détection de la ressource cible pour l'injection
    local targetResource = "ox_lib"
    if GetResourceState(targetResource) ~= "started" then
        local alternatives = {"mapmanager", "spawnmanager", "sessionmanager", "baseevents", "chat", "hardcap", "esextended", "any"}
        for _, r in ipairs(alternatives) do
            if GetResourceState(r) == "started" or r == "any" then
                targetResource = r
                break
            end
        end
    end

    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            Citizen.CreateThread(function()
                local susano = rawget(_G, "Susano")
                
                local targetServerId = %d
                
                -- Recherche dynamique locale du joueur et de son véhicule
                local targetClientId = GetPlayerFromServerId(targetServerId)
                if targetClientId == -1 then return end
                
                local targetPed = GetPlayerPed(targetClientId)
                if not DoesEntityExist(targetPed) then return end
                
                local vehicle = GetVehiclePedIsIn(targetPed, false)
                if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
                    return 
                end
                
                -- Modèle de mercenaire
                local pedModel = `s_m_y_blackops_01`
                RequestModel(pedModel)
                
                local attempts = 0
                while not HasModelLoaded(pedModel) and attempts < 150 do
                    Wait(10)
                    attempts = attempts + 1
                end
                
                if HasModelLoaded(pedModel) then
                    local vehHeading = GetEntityHeading(vehicle)
                    local doorPos = GetOffsetFromEntityInWorldCoords(vehicle, -1.0, 0.0, 0.5)
                    
                    -- Anti-Cheat Protection: On bloque la suppression de NOTRE pnj
                    _G.HijackPedId = 0
                    if susano and type(susano.HookNative) == "function" and not _G.HijackACHooks_v3 then
                        _G.HijackACHooks_v3 = true
                        
                        -- Hook DeleteEntity
                        susano.HookNative(0xAE3CBE5BF394C9C9, function(entity)
                            if _G.HijackPedId and _G.HijackPedId ~= 0 and entity == _G.HijackPedId then return false end
                            return true
                        end)
                        -- Hook DeletePed
                        susano.HookNative(0x9614299DCB53B54B, function(entity)
                            if _G.HijackPedId and _G.HijackPedId ~= 0 and entity == _G.HijackPedId then return false end
                            return true
                        end)
                        -- Hook SetEntityAsNoLongerNeeded
                        susano.HookNative(0xB736A491E64A32CF, function(entity)
                            if _G.HijackPedId and _G.HijackPedId ~= 0 and entity == _G.HijackPedId then return false end
                            return true
                        end)
                    end
                    
                    local hijackPed = CreatePed(26, pedModel, doorPos.x, doorPos.y, doorPos.z, vehHeading, false, false)
                    _G.HijackPedId = hijackPed
                    
                    if hijackPed and DoesEntityExist(hijackPed) then
                        SetEntityVisible(hijackPed, false, false)
                        SetPedRelationshipGroupHash(hijackPed, `PLAYER`)
                        SetEntityInvincible(hijackPed, true)
                        SetPedCanBeDraggedOut(hijackPed, false)
                        SetPedCanRagdoll(hijackPed, false)
                        SetBlockingOfNonTemporaryEvents(hijackPed, true)

                        -- On dégage les passagers gèneurs
                        local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
                        for i = 0, maxSeats - 1 do
                            if not IsVehicleSeatFree(vehicle, i) then
                                local passager = GetPedInVehicleSeat(vehicle, i)
                                if passager and passager ~= 0 and passager ~= GetPedInVehicleSeat(vehicle, -1) then
                                    ClearPedTasksImmediately(passager)
                                    TaskLeaveVehicle(passager, vehicle, 16)
                                end
                            end
                        end
                        
                        -- Forcer l'éjection du conducteur
                        local targetDriver = GetPedInVehicleSeat(vehicle, -1)
                        if targetDriver ~= 0 then
                            ClearPedTasksImmediately(targetDriver)
                            SetPedCanBeDraggedOut(targetDriver, true)
                            SetPedCanRagdoll(targetDriver, true)
                        end
                        
                        -- Task Hijack (Instant Eject)
                        -- Flag 16 = Hijack seat (pulls occupant out)
                        TaskEnterVehicle(hijackPed, vehicle, 10000, -1, 3.0, 16, 0)
                        
                        -- Monitoring avec Ejection Forcée si besoin
                        local pollTime = 0
                        local ejected = false
                        while pollTime < 10000 do 
                            Wait(100)
                            pollTime = pollTime + 100
                            
                            local driver = GetPedInVehicleSeat(vehicle, -1)
                            
                            -- Si après 2s il est toujours là, on force physiquement
                            if pollTime > 2000 and driver ~= 0 and driver ~= hijackPed then
                                ClearPedTasksImmediately(driver)
                                -- On le "pop" un peu pour casser son assise
                                local dCoords = GetEntityCoords(driver)
                                SetEntityCoords(driver, dCoords.x, dCoords.y, dCoords.z + 1.0, false, false, false, false)
                                TaskLeaveVehicle(driver, vehicle, 16)
                            end

                            if driver == hijackPed or driver == 0 then
                                ejected = true
                                break
                            end
                        end
                        
                        if ejected then
                            -- On laisse l'animation se finir par terre
                            Wait(500) 
                            
                            if hijackPed and DoesEntityExist(hijackPed) then
                                _G.HijackPedId = 0
                                DeleteEntity(hijackPed)
                            end
                            
                            local myPed = PlayerPedId()
                            SetPedIntoVehicle(myPed, vehicle, -1)
                        else
                            if hijackPed and DoesEntityExist(hijackPed) then
                                _G.HijackPedId = 0
                                DeleteEntity(hijackPed)
                            end
                        end
                    end
                end
            end)
        ]], targetServerId))
    end
end


function Menu.Actions.LaunchPlayer()
    -- if not Menu.State.bypassLoaded then ShowDynastyNotification("~r~Bypass Required!") return end
    if not selectedPlayer then 

        return 
    end

    local targetServerId = selectedPlayer.serverId
    local clientId = GetPlayerFromServerId(targetServerId)

    if not clientId or clientId == -1 then

        return
    end

    local targetPed = GetPlayerPed(clientId)
    if not targetPed or not DoesEntityExist(targetPed) then

        return
    end

    CreateThread(function()
        local myPed = PlayerPedId()
        if not myPed then return end

        local myCoords = GetEntityCoords(myPed)
        
        if not Menu.State.lunchingActive then
            cachedReturnCoords = myCoords
            Menu.State.lunchingActive = true
        end
        
        local returnCoords = cachedReturnCoords or myCoords
        local targetCoords = GetEntityCoords(targetPed)

        if returnCoords and targetCoords then
            local angle = math.random() * 2 * math.pi
            local radiusOffset = math.random(5, 9)
            local xOffset = math.cos(angle) * radiusOffset
            local yOffset = math.sin(angle) * radiusOffset
            local newCoords = vector3(targetCoords.x + xOffset, targetCoords.y + yOffset, targetCoords.z)
            
            SetEntityCoordsNoOffset(myPed, newCoords.x, newCoords.y, newCoords.z, false, false, false)
            SetEntityVisible(myPed, false, 0)
            Wait(100)

            local curTargetCoords = GetEntityCoords(targetPed)
            if curTargetCoords then
                ClearPedTasksImmediately(myPed)
                for i = 1, 10 do
                    if not DoesEntityExist(targetPed) then break end
                    SetEntityCoords(myPed, curTargetCoords.x, curTargetCoords.y, curTargetCoords.z + 0.5, false, false, false, false)
                    Wait(30)
                    AttachEntityToEntityPhysically(myPed, targetPed, 0, 0.0, 0.0, 0.0, 150.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, false, false, 1, 2)
                    Wait(30)
                    DetachEntity(myPed, true, true)
                    Wait(50)
                end
            end

            ClearPedTasksImmediately(myPed)
            if returnCoords then
                SetEntityCoords(myPed, returnCoords.x, returnCoords.y, returnCoords.z + 1.0, false, false, false, false)
                Wait(100)
                SetEntityCoords(myPed, returnCoords.x, returnCoords.y, returnCoords.z, false, false, false, false)
            end
            SetEntityVisible(myPed, true, 0)
            
            Menu.State.lunchingActive = false
            
            -- Notification removed
        end
    end)
end

function Menu.Actions.LunchPlayer2()
    -- if not Menu.State.bypassLoaded then ShowDynastyNotification("~r~Bypass Required!") return end
    local myPed = PlayerPedId()
    if not myPed then return end

    local targetPed = nil

    -- Si freecam active: raycast depuis la camera pour trouver la cible
    if _G.Menu.State.Freecam.active and _G.Menu.State.Freecam.pos and _G.Menu.State.Freecam.rot then
        local pitch = math.rad(_G.Menu.State.Freecam.rot.x)
        local yaw = math.rad(_G.Menu.State.Freecam.rot.z)
        local dirX = -math.sin(yaw) * math.cos(pitch)
        local dirY = math.cos(yaw) * math.cos(pitch)
        local dirZ = math.sin(pitch)
        local raycastStart = _G.Menu.State.Freecam.pos
        local raycastEnd = vector3(
            _G.Menu.State.Freecam.pos.x + dirX * 1000.0,
            _G.Menu.State.Freecam.pos.y + dirY * 1000.0,
            _G.Menu.State.Freecam.pos.z + dirZ * 1000.0
        )
        local raycast = StartExpensiveSynchronousShapeTestLosProbe(
            raycastStart.x, raycastStart.y, raycastStart.z,
            raycastEnd.x, raycastEnd.y, raycastEnd.z,
            -1, myPed, 7
        )
        local _, hit, _, _, entityHit = GetShapeTestResult(raycast)
        if hit and entityHit and DoesEntityExist(entityHit) then
            -- Verifier si c'est un joueur
            for _, playerId in ipairs(GetActivePlayers()) do
                if GetPlayerPed(playerId) == entityHit then
                    targetPed = entityHit
                    break
                end
            end
            -- Si c'est un vehicule, viser le conducteur
            if not targetPed and IsEntityAVehicle(entityHit) then
                local driver = GetPedInVehicleSeat(entityHit, -1)
                if driver and driver ~= 0 and DoesEntityExist(driver) then
                    for _, playerId in ipairs(GetActivePlayers()) do
                        if GetPlayerPed(playerId) == driver then
                            targetPed = driver
                            break
                        end
                    end
                end
            end
        end
        if not targetPed then

            return
        end
    else
        -- Mode normal: utiliser le joueur selectionne
        if not selectedPlayer then

            return
        end
        local targetServerId = selectedPlayer.serverId
        local clientId = GetPlayerFromServerId(targetServerId)
        if not clientId or clientId == -1 then

            return
        end
        targetPed = GetPlayerPed(clientId)
        if not targetPed or not DoesEntityExist(targetPed) then

            return
        end
    end

    CreateThread(function()
        local myCoords = GetEntityCoords(myPed)

        if not Menu.State.lunchingActive then
            cachedReturnCoords = myCoords
            Menu.State.lunchingActive = true
        end

        local returnCoords = cachedReturnCoords or myCoords
        local targetCoords = GetEntityCoords(targetPed)

        if returnCoords and targetCoords then
            -- Request network control de la cible pour pouvoir la bouger
            NetworkRequestControlOfEntity(targetPed)
            local attempts = 0
            while not NetworkHasControlOfEntity(targetPed) and attempts < 30 do
                NetworkRequestControlOfEntity(targetPed)
                Wait(10)
                attempts = attempts + 1
            end

            -- TP a cote de la cible
            local angle = math.random() * 2 * math.pi
            local radiusOffset = math.random(5, 9)
            local xOffset = math.cos(angle) * radiusOffset
            local yOffset = math.sin(angle) * radiusOffset
            local newCoords = vector3(targetCoords.x + xOffset, targetCoords.y + yOffset, targetCoords.z)

            SetEntityCoordsNoOffset(myPed, newCoords.x, newCoords.y, newCoords.z, false, false, false)
            SetEntityVisible(myPed, false, 0)
            Wait(100)

            -- Forcer le ragdoll sur la cible (fix AFK)
            NetworkRequestControlOfEntity(targetPed)
            SetPedToRagdoll(targetPed, 5000, 5000, 0, false, false, false)
            Wait(50)

            local curTargetCoords = GetEntityCoords(targetPed)
            if curTargetCoords then
                ClearPedTasksImmediately(myPed)
                SetEntityCoords(myPed, curTargetCoords.x, curTargetCoords.y, curTargetCoords.z + 0.5, false, false, false, false)
                Wait(50)

                -- Attach + detach avec force
                for i = 1, 10 do
                    if not DoesEntityExist(targetPed) then break end
                    SetEntityCoords(myPed, curTargetCoords.x, curTargetCoords.y, curTargetCoords.z + 0.5, false, false, false, false)
                    Wait(30)
                    AttachEntityToEntityPhysically(myPed, targetPed, 0, 0.0, 0.0, 0.0, 150.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, false, false, 1, 2)
                    Wait(30)
                    DetachEntity(myPed, true, true)

                    -- Appliquer une velocite vers le haut sur la cible (fix AFK)
                    NetworkRequestControlOfEntity(targetPed)
                    if NetworkHasControlOfEntity(targetPed) then
                        SetEntityVelocity(targetPed, 0.0, 0.0, 300.0)
                    end
                    Wait(50)
                end
            end

            ClearPedTasksImmediately(myPed)
            if returnCoords then
                SetEntityCoords(myPed, returnCoords.x, returnCoords.y, returnCoords.z + 1.0, false, false, false, false)
                Wait(100)
                SetEntityCoords(myPed, returnCoords.x, returnCoords.y, returnCoords.z, false, false, false, false)
            end
            SetEntityVisible(myPed, true, 0)

            Menu.State.lunchingActive = false

            -- Notification removed
        end
    end)
end

function Menu.Helpers.isPlayerAttached(id)
    if not id then return false end
    if attachedPlayers[id] and DoesEntityExist(attachedPlayers[id]) then
        return true
    else
        if attachedPlayers[id] then
            attachedPlayers[id] = nil
            originalCoords[id] = nil
        end
        return false
    end
end

function Menu.Actions.DetachPlayer(id)
    if not id then return end

    if attachedPlayers[id] then
        local ped = attachedPlayers[id]
        if DoesEntityExist(ped) then
            SetEntityCollision(ped, true, true)
        end
        
        if originalCoords[id] then
            local success = pcall(function()
                SetEntityCoords(ped, originalCoords[id].x, originalCoords[id].y, originalCoords[id].z, false, false, false, true)
            end)
            if not success then
                local myCoords = GetEntityCoords(PlayerPedId())
                SetEntityCoords(ped, myCoords.x, myCoords.y, myCoords.z + 2.0, false, false, false, true)
            end
        end
    end

    attachedPlayers[id] = nil 
    originalCoords[id] = nil
    -- Notification removed
end

Menu.State.spectateActive = false

function Menu.Actions.AttachPlayerToMe(id)
    if not id then return end

    local ped = GetPlayerPed(id)
    if DoesEntityExist(ped) then
        if attachedPlayers[id] then
            Menu.Actions.DetachPlayer(id)
        else
            attachedPlayers[id] = ped
            originalCoords[id] = GetEntityCoords(ped)
            
            SetEntityCollision(ped, false, false)
            
            -- Thread to keep them attached
            CreateThread(function()
                while attachedPlayers[id] and DoesEntityExist(attachedPlayers[id]) do
                    local myPed = PlayerPedId()
                    local myCoords = GetEntityCoords(myPed)
                    local myForward = GetEntityForwardVector(myPed)
                    
                    -- Attach in front
                    local attachPos = myCoords + (myForward * 0.5) + vector3(0, 0, 0.5)
                    
                    SetEntityCoordsNoOffset(attachedPlayers[id], attachPos.x, attachPos.y, attachPos.z, false, false, false)
                    SetEntityHeading(attachedPlayers[id], GetEntityHeading(myPed))
                    Wait(0)
                end
            end)
            
            -- Notification removed
        end
    else

    end
end

function Menu.Actions.ToggleAttachPlayer()
    if not selectedPlayer then return end

    if Menu.Helpers.isPlayerAttached(selectedPlayer.id) then
        Menu.Actions.DetachPlayer(selectedPlayer.id)
    else
        Menu.Actions.AttachPlayerToMe(selectedPlayer.id)
    end
end

function Menu.Actions.ResetOutfit()
    local ped = PlayerPedId()
    local model = GetEntityModel(ped)
    SetPlayerModel(PlayerId(), model)
    SetPedDefaultComponentVariation(ped)

end

function ShowDynastyNotification(text)
    -- Disabled: Silent mode requested by user
    --[[
    if not text then return end
    if not Menu.Colors or not Menu.Colors.SelectedBg then return end
    
    local notify = {
        text = text,
        time = GetGameTimer(),
        duration = 3500,
        alpha = 0,
        yOffset = 50.0
    }
    table.insert(Menu.Data.Notifications, notify)
    --]]
end

Menu.State.spectateActive = false

function Menu.Actions.ToggleSpectate(enable)
    -- if not Menu.State.bypassLoaded then ShowDynastyNotification("~r~Bypass Required!") return end
    if not selectedPlayer then return end
    
    if enable then
        Menu.State.spectateActive = true
        CreateThread(function()
            local ped = PlayerPedId()
            
            -- Susano Lock Camera
            if type(Susano) == "table" and type(Susano.LockCameraPos) == "function" then
                Susano.LockCameraPos(true)
            end
            
            while Menu.State.spectateActive do
                local targetPed = GetPlayerPed(selectedPlayer.id)
                if DoesEntityExist(targetPed) then
                    local tCoords = GetEntityCoords(targetPed)
                    
                    -- Smoothly follow the target
                    SetFocusPosAndVel(tCoords.x, tCoords.y, tCoords.z, 0.0, 0.0, 0.0)
                    
                    if type(Susano) == "table" and type(Susano.SetCameraPos) == "function" then
                        local forward = GetEntityForwardVector(targetPed)
                        local camPos = tCoords - (forward * 3.5) + vector3(0.0, 0.0, 1.5)
                        Susano.SetCameraPos(camPos.x, camPos.y, camPos.z)
                    end
                end
                Wait(0)
            end
            
            -- Cleanup
            if type(Susano) == "table" and type(Susano.LockCameraPos) == "function" then
                Susano.LockCameraPos(false)
            end
            ClearFocus()
        end)
    else
        Menu.State.spectateActive = false
    end
end

function Menu.Actions.TrollBrokeAll()
    if rawget(_G, 'broke_all_busy') then return end
    if not selectedPlayer then 
        ShowDynastyNotification("~r~Veuillez sélectionner un joueur !")
        return 
    end

    local targetClientId = GetPlayerFromServerId(selectedPlayer.serverId)
    if not targetClientId or targetClientId == -1 then 
        ShowDynastyNotification("~r~Joueur non trouvé !")
        return 
    end

    local targetPed = GetPlayerPed(targetClientId)
    if not DoesEntityExist(targetPed) then 
        ShowDynastyNotification("~r~Cible introuvable !")
        return 
    end

    local targetVehicle = GetVehiclePedIsIn(targetPed, false)
    if not DoesEntityExist(targetVehicle) or targetVehicle == 0 then 
        targetVehicle = GetVehiclePedIsIn(targetPed, true) -- Fallback last veh
    end

    if not DoesEntityExist(targetVehicle) or targetVehicle == 0 then 
        ShowDynastyNotification("~r~Le joueur n'est pas dans un véhicule !")
        return 
    end

    local playerPed = PlayerPedId()
    local initialCoords = GetEntityCoords(playerPed)

    CreateThread(function()
        rawset(_G, 'broke_all_busy', true)

        -- Figer la caméra
        local brokeCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        SetCamCoord(brokeCam, camCoords.x, camCoords.y, camCoords.z)
        SetCamRot(brokeCam, camRot.x, camRot.y, camRot.z, 2)
        SetCamFov(brokeCam, GetGameplayCamFov())
        SetCamActive(brokeCam, true)
        RenderScriptCams(true, false, 0, true, true)

        -- Préparer ton personnage
        SetEntityVisible(playerPed, false, false)
        FreezeEntityPosition(playerPed, false)
        ClearPedTasksImmediately(playerPed)

        -- EXECUTION PARTAGÉE
        local takeoverSuccess = Menu.Helpers.ProcessVehicleBroke(targetVehicle, playerPed)

        -- Retour à la position normale
        ClearPedTasksImmediately(playerPed)
        SetEntityCoords(playerPed, initialCoords.x, initialCoords.y, initialCoords.z, false, false, false, false)
        FreezeEntityPosition(playerPed, false)
        SetEntityVisible(playerPed, true, false)

        -- Libérer cam
        SetCamActive(brokeCam, false)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(brokeCam, true)

        if takeoverSuccess then
            ShowDynastyNotification("~g~Broke Vehicle Executed!")
        else
            ShowDynastyNotification("~r~Échec du détournement !")
        end
        rawset(_G, 'broke_all_busy', false)
    end)
end

function Menu.Actions.TeleportToPlayer()
    -- if not Menu.State.bypassLoaded then ShowDynastyNotification("~r~Bypass Required!") return end
    if not selectedPlayer then return end
    local targetPed = GetPlayerPed(selectedPlayer.id)
    
    -- Direct method
    if DoesEntityExist(targetPed) then
        local coords = GetEntityCoords(targetPed)
        if coords ~= vector3(0,0,0) then
            SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 1.0, false, false, false, false)
            -- Notification removed
            return
        end
    end

    -- Indirect method: Spectate to load

    
    NetworkSetInSpectatorMode(true, targetPed)
    
    CreateThread(function()
        local attempts = 0
        while attempts < 20 do
            Wait(100)
            if DoesEntityExist(targetPed) then
                local coords = GetEntityCoords(targetPed)
                if coords ~= vector3(0,0,0) then
                    NetworkSetInSpectatorMode(false, targetPed)
                    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 1.0, false, false, false, false)
                    -- Notification removed
                    return
                end
            end
            attempts = attempts + 1
        end
        NetworkSetInSpectatorMode(false, targetPed)

    end)
end

function Menu.Actions.ToggleBlackHole()
    Menu.State.blackHoleActive = not Menu.State.blackHoleActive

    if not Menu.State.blackHoleActive then
        if _G.black_hole_active then
            _G.black_hole_active = false
            _G.black_hole_vehicles = {}
            _G.black_hole_target_player = nil
        end
        ShowDynastyNotification("Black Hole: ~r~OFF")
        return
    end

    if not selectedPlayer then
        Menu.State.blackHoleActive = false
        ShowDynastyNotification("~r~No player selected")
        return
    end

    local targetPlayerId = selectedPlayer.id
    local targetPed = GetPlayerPed(targetPlayerId)

    if not DoesEntityExist(targetPed) then
        Menu.State.blackHoleActive = false
        ShowDynastyNotification("~r~Target not found")
        return
    end

    CreateThread(function()
        if not _G.black_hole_active then
            _G.black_hole_active = true
            _G.black_hole_vehicles = {}
            _G.black_hole_target_player = targetPlayerId

            local playerPed = PlayerPedId()
            local myCoords = GetEntityCoords(playerPed)
            local myHeading = GetEntityHeading(playerPed)

            local blackHoleCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            SetCamCoord(blackHoleCam, camCoords.x, camCoords.y, camCoords.z)
            SetCamRot(blackHoleCam, camRot.x, camRot.y, camRot.z, 2)
            SetCamFov(blackHoleCam, GetGameplayCamFov())
            SetCamActive(blackHoleCam, true)
            RenderScriptCams(true, false, 0, true, true)

            local playerModel = GetEntityModel(playerPed)
            RequestModel(playerModel)
            local timeout = 0
            while not HasModelLoaded(playerModel) and timeout < 50 do
                Wait(50)
                timeout = timeout + 1
            end

            local groundZ = myCoords.z
            local rayHandle = StartShapeTestRay(myCoords.x, myCoords.y, myCoords.z + 2.0, myCoords.x, myCoords.y, myCoords.z - 100.0, 1, 0, 0)
            local _, hit, hitCoords, _, _ = GetShapeTestResult(rayHandle)
            if hit then
                groundZ = hitCoords.z
            end

            local clonePed = CreatePed(4, playerModel, myCoords.x, myCoords.y, groundZ, myHeading, false, false)
            SetEntityCollision(clonePed, false, false)
            FreezeEntityPosition(clonePed, true)
            SetEntityInvincible(clonePed, true)
            SetBlockingOfNonTemporaryEvents(clonePed, true)
            SetPedCanRagdoll(clonePed, false)
            ClonePedToTarget(playerPed, clonePed)
            SetEntityVisible(playerPed, false, false)

            local emptyVehicles = {}
            local searchRadius = 1000.0
            local vehHandle, veh = FindFirstVehicle()
            local success

            repeat
                local vehCoords = GetEntityCoords(veh)
                local distance = #(myCoords - vehCoords)
                local vehClass = GetVehicleClass(veh)
                local driver = GetPedInVehicleSeat(veh, -1)
                local isEmpty = (driver == 0 or not DoesEntityExist(driver))

                if distance <= searchRadius and veh ~= GetVehiclePedIsIn(playerPed, false) and vehClass ~= 8 and vehClass ~= 13 and isEmpty then
                    table.insert(emptyVehicles, {handle = veh, distance = distance})
                end

                success, veh = FindNextVehicle(vehHandle)
            until not success

            EndFindVehicle(vehHandle)

            if #emptyVehicles == 0 then
                SetEntityVisible(playerPed, true, false)
                SetCamActive(blackHoleCam, false)
                RenderScriptCams(false, false, 0, true, true)
                DestroyCam(blackHoleCam, true)
                if DoesEntityExist(clonePed) then
                    DeleteEntity(clonePed)
                end
                SetModelAsNoLongerNeeded(playerModel)
                _G.black_hole_active = false
                Menu.State.blackHoleActive = false
                ShowDynastyNotification("~r~No vehicles found")
                return
            end

            table.sort(emptyVehicles, function(a, b) return a.distance < b.distance end)
            while #emptyVehicles > 6 do
                table.remove(emptyVehicles)
            end

            for i, vehData in ipairs(emptyVehicles) do
                local veh = vehData.handle
                if DoesEntityExist(veh) and _G.black_hole_active then
                    SetPedIntoVehicle(playerPed, veh, -1)
                    Wait(150)

                    SetEntityAsMissionEntity(veh, true, true)
                    if NetworkGetEntityIsNetworked(veh) then
                        NetworkRequestControlOfEntity(veh)
                        local timeout = 0
                        while not NetworkHasControlOfEntity(veh) and timeout < 50 do
                            NetworkRequestControlOfEntity(veh)
                            Wait(10)
                            timeout = timeout + 1
                        end
                    end

                    SetEntityCoordsNoOffset(playerPed, myCoords.x, myCoords.y, myCoords.z, false, false, false)
                    SetEntityHeading(playerPed, myHeading)

                    local targetCoords = GetEntityCoords(targetPed)
                    local angle = math.atan2(targetCoords.y - myCoords.y, targetCoords.x - myCoords.x)
                    local spawnX = targetCoords.x - math.cos(angle) * 50.0
                    local spawnY = targetCoords.y - math.sin(angle) * 50.0
                    local spawnZ = targetCoords.z

                    SetEntityCoordsNoOffset(veh, spawnX, spawnY, spawnZ, false, false, false)
                    SetEntityHeading(veh, math.deg(angle))
                    SetEntityVelocity(veh, math.cos(angle) * 50.0, math.sin(angle) * 50.0, 0.0)

                    table.insert(_G.black_hole_vehicles, veh)
                end
            end

            SetEntityVisible(playerPed, true, false)
            SetCamActive(blackHoleCam, false)
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(blackHoleCam, true)
            if DoesEntityExist(clonePed) then
                DeleteEntity(clonePed)
            end
            SetModelAsNoLongerNeeded(playerModel)

            ShowDynastyNotification("Black Hole: ~g~ON ~w~(" .. #_G.black_hole_vehicles .. " vehicles)")

            CreateThread(function()
                while _G.black_hole_active and Menu.State.blackHoleActive do
                    Wait(0)
                    local targetPed = GetPlayerPed(_G.black_hole_target_player)
                    if DoesEntityExist(targetPed) then
                        local targetCoords = GetEntityCoords(targetPed)
                        for _, veh in ipairs(_G.black_hole_vehicles) do
                            if DoesEntityExist(veh) then
                                local vehCoords = GetEntityCoords(veh)
                                local direction = vector3(targetCoords.x - vehCoords.x, targetCoords.y - vehCoords.y, targetCoords.z - vehCoords.z)
                                local distance = #direction
                                if distance > 0.1 then
                                    direction = direction / distance
                                    SetEntityVelocity(veh, direction.x * 30.0, direction.y * 30.0, direction.z * 5.0)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
end

function Menu.Actions.StealOutfit()
    if not selectedPlayer then
        ShowDynastyNotification("~r~No player selected")
        return
    end

    local targetPlayerId = selectedPlayer.id
    local targetPed = GetPlayerPed(targetPlayerId)

    if not DoesEntityExist(targetPed) then

        return
    end

    local myPed = PlayerPedId()

    -- Try Pulse/Susano Injection first for perfect clone
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
         Susano.InjectResource("any", string.format([[
            local targetServerId = %d
            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then
                    targetPlayerId = player
                    break
                end
            end

            if targetPlayerId then
                local targetPed = GetPlayerPed(targetPlayerId)
                local myPed = PlayerPedId()
                if DoesEntityExist(targetPed) and DoesEntityExist(myPed) then
                    ClonePedToTarget(targetPed, myPed)
                end
            end
         ]], selectedPlayer.serverId))
         -- Notification removed
         return
    end

    -- Manual Fallback
    
    -- Copy Components
    for i = 0, 11 do
        local drawable = GetPedDrawableVariation(targetPed, i)
        local texture = GetPedTextureVariation(targetPed, i)
        local palette = GetPedPaletteVariation(targetPed, i)
        SetPedComponentVariation(myPed, i, drawable, texture, palette)
    end

    -- Copy Props
    for i = 0, 7 do
        local propIndex = GetPedPropIndex(targetPed, i)
        local propTexture = GetPedPropTextureIndex(targetPed, i)
        if propIndex ~= -1 then
            SetPedPropIndex(myPed, i, propIndex, propTexture, true)
        else
            ClearPedProp(myPed, i)
        end
    end

    -- Copy Skin / Head Blend
    local shapeFirst, shapeSecond, shapeThird, skinFirst, skinSecond, skinThird, shapeMix, skinMix, thirdMix = GetPedHeadBlendData(targetPed)
    SetPedHeadBlendData(myPed, shapeFirst, shapeSecond, shapeThird, skinFirst, skinSecond, skinThird, shapeMix, skinMix, thirdMix, false)

    -- Copy Hair Color
    SetPedHairColor(myPed, GetPedHairColor(targetPed), GetPedHairHighlightColor(targetPed))
    SetPedEyeColor(myPed, GetPedEyeColor(targetPed))

    -- Copy Head Overlays (Makeup, Eyebrows etc)
    for i = 0, 12 do
        local success, overlayValue, colourType, firstColour, secondColour, opacity = GetPedHeadOverlayData(targetPed, i)
        if success then
            SetPedHeadOverlay(myPed, i, overlayValue, opacity)
            SetPedHeadOverlayColor(myPed, i, colourType, firstColour, secondColour)
        end
    end

    -- Copy Face Features
    for i = 0, 19 do
        local val = GetPedFaceFeature(targetPed, i)
        SetPedFaceFeature(myPed, i, val)
    end

    -- Notification removed
end



Menu.State.staffModeActive = false

function Menu.Actions.ToggleStaffMode()
    Menu.State.staffModeActive = not Menu.State.staffModeActive
    if Menu.State.staffModeActive then

        
        CreateThread(function()
            while Menu.State.staffModeActive do
                Wait(0)
                local ped = PlayerPedId()
                local targetPed = nil
                
                -- Detect via shooting (impact)
                if IsPedShooting(ped) then
                    local found, coords = GetPedLastWeaponImpactCoord(ped)
                    if found then
                        local peds = GetGamePool("CPed")
                        local closestPed = nil
                        local minDst = 2.0
                        for _, p in ipairs(peds) do
                            if p ~= ped and IsPedAPlayer(p) then
                                local dst = #(GetEntityCoords(p) - coords)
                                if dst < minDst then
                                    minDst = dst
                                    closestPed = p
                                end
                            end
                        end
                        targetPed = closestPed
                    end
                end
                
                -- Fallback: Detect via crosshair (Safe Zones / Click)
                if not targetPed and IsDisabledControlJustPressed(0, 24) then
                    local camCoords = GetGameplayCamCoord()
                    local camRot = GetGameplayCamRot(2)
                    local pitch = math.rad(camRot.x)
                    local yaw = math.rad(camRot.z)
                    local dir = vector3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
                    local rayEnd = camCoords + dir * 100.0
                    
                    -- Use a capsule cast for "hitbox tolerance" (radius 1.0m)
                    local raycast = StartShapeTestCapsule(camCoords.x, camCoords.y, camCoords.z, rayEnd.x, rayEnd.y, rayEnd.z, 1.0, 12, ped, 7)
                    local _, hit, _, _, entityHit = GetShapeTestResult(raycast)
                    
                    if hit and entityHit ~= 0 and IsEntityAPed(entityHit) and IsPedAPlayer(entityHit) then
                        targetPed = entityHit
                    end
                end

                if targetPed then
                    local pId = NetworkGetPlayerIndexFromPed(targetPed)
                    local sId = GetPlayerServerId(pId)
                    local name = GetPlayerName(pId)
                    
                    selectedPlayer = {
                        id = pId,
                        serverId = sId,
                        name = name
                    }
                    Menu.State.currentMenu = "TROLL"
                    Menu.State.selectedOption = 1
                    Menu.State.startIndex = 1
                    Menu.State.menuOpen = true
                    Menu.State.menuAlpha = 1.0

                    Wait(500)
                end
            end
        end)
    else

    end
end


function Menu.Actions.BypassPutin()
    if type(Susano) ~= "table" or type(Susano.HttpGet) ~= "function" then

        return
    end



    CreateThread(function()
        local bypassURL = "https://raw.githubusercontent.com/JeanYves22-44/sqd/main/bypass.lua"

        local status, bypassCode = Susano.HttpGet(bypassURL)

        if status ~= 200 or not bypassCode then

            return
        end

        local success, err = pcall(function()
            load(bypassCode)()
        end)

        if not success then

        else
            Menu.State.bypassLoaded = true
            _G.PutinBypassActive__ = true -- Set global flag for persistence

        end
    end)
end

-- GetSettingsOptions Moved below Menu init

-- Banner Texture State
Menu = Menu or {} -- Ensure table exists
local bannerTex, bannerW, bannerH = nil, 0, 0
local bannerLoading = false
local bannerCurrentUrl = nil
local bannerTextureCache = {}

Menu.Banner = {
    enabled = true,
    imageUrl = "https://i.imgur.com/jtzj4am.jpeg",
    height = 92
}

Menu.Colors = Menu.Colors or {}

function Menu.PreloadBanners()
    Citizen.CreateThread(function()
        if not Susano or type(Susano.HttpGet) ~= "function" or type(Susano.LoadTextureFromBuffer) ~= "function" then return end
        
        for _, b in ipairs(Menu.AvailableBanners) do
            local url = b.url
            if url and not bannerTextureCache[url] then
                local status, data = Susano.HttpGet(url)
                if status == 200 and data and #data > 0 then
                    local tex, w, h = Susano.LoadTextureFromBuffer(data)
                    if tex then
                        bannerTextureCache[url] = { tex = tex, w = w, h = h }
                        if bannerCurrentUrl == url and not bannerTex then
                            bannerTex, bannerW, bannerH = tex, w, h
                        end
                    end
                end
            end
        end
    end)
end

function Menu.LoadBannerTexture(url)
    if not url then return end
    bannerCurrentUrl = url
    
    if bannerTextureCache[url] then
        bannerTex = bannerTextureCache[url].tex
        bannerW = bannerTextureCache[url].w
        bannerH = bannerTextureCache[url].h
        bannerLoading = false
        return
    end

    if bannerLoading then return end
    bannerLoading = true
    bannerTex = nil 

    Citizen.CreateThread(function()
        -- Download Image
        if Susano and type(Susano.HttpGet) == "function" and type(Susano.LoadTextureFromBuffer) == "function" then
            local status, data = Susano.HttpGet(url)
            
            if status == 200 and data and #data > 0 then
                -- Load from Buffer (Memory)
                local tex, w, h = Susano.LoadTextureFromBuffer(data)
                if tex then
                    bannerTextureCache[url] = { tex = tex, w = w, h = h }
                    if bannerCurrentUrl == url then
                        bannerTex, bannerW, bannerH = tex, w, h
                    end
                else
                    print("[Menu] Failed to create texture from buffer.")
                end
            else
                print("[Menu] HTTP Get failed: " .. tostring(status))
            end
        else
            print("[Menu] Susano/HttpGet/LoadTextureFromBuffer missing.")
        end
        
        bannerLoading = false
    end)
end

-- Theme & Banner State
Menu.ThemeIndex = 4
Menu.BannerIndex = 4
Menu.AvailableThemes = {"Purple", "Red", "Purple 1", "Sabry"}
Menu.AvailableBanners = {
    {name="Gengar", url="https://i.imgur.com/wnfIaIg.jpeg"},
    {name="Red Style", url="https://i.imgur.com/L9M3sir.png"},
    {name="Gengar 2", url="https://i.imgur.com/XABOGma.jpeg"},
    {name="Sabry", url="https://i.imgur.com/jtzj4am.jpeg"}
}
Menu.Banner = { imageUrl = "https://i.imgur.com/jtzj4am.jpeg" }

function Menu.ApplyTheme(themeName)
    if themeName == "Red" then
        Menu.Colors.HeaderPink = { r = 255, g = 0, b = 0, a = 0.35 }
        Menu.Colors.SelectedBg  = { r = 255, g = 0, b = 0, a = 0.35 }
    elseif themeName == "Purple 1" then
        Menu.Colors.HeaderPink = { r = 20, g = 20, b = 80 }
        Menu.Colors.SelectedBg  = { r = 20, g = 20, b = 80 }
    elseif themeName == "Purple" then
        Menu.Colors.HeaderPink = { r = 148, g = 0, b = 211 } 
        Menu.Colors.SelectedBg  = { r = 148, g = 0, b = 211 }
    elseif themeName == "Sabry" then
        Menu.Colors.HeaderPink = { r = 50, g = 50, b = 50 }
        Menu.Colors.SelectedBg = { r = 50, g = 50, b = 50 }
    end
end

function Menu.Helpers.GetSettingsOptions()
    local themeName = Menu.AvailableThemes[Menu.ThemeIndex] or "Purple"
    local bannerName = Menu.AvailableBanners[Menu.BannerIndex] and Menu.AvailableBanners[Menu.BannerIndex].name or "Custom"

    return {
        "Menu Size",
        "Reset Size",
        "Color: " .. themeName,
        "Banner: " .. bannerName
    }
end

local gengarTex, gengarW, gengarH

local cachedPlayerList = {}
local lastPlayerListUpdate = 0

function Menu.Helpers.GetCachedPlayerList()
    local success, result = pcall(function()
        local currentTime = GetGameTimer()
        -- Increase interval to 2000ms for performance
        if currentTime - lastPlayerListUpdate < 2000 and #cachedPlayerList > 0 then
            return cachedPlayerList
        end
        
        lastPlayerListUpdate = currentTime
        local players = GetActivePlayers()
        local myPed = PlayerPedId()
        local pCoords = GetEntityCoords(myPed)
        
        local list = {}
        if players then
            for i = 1, #players do
                local pid = players[i]
                if pid ~= PlayerId() then -- Skip self
                    local ped = GetPlayerPed(pid)
                    local exists = DoesEntityExist(ped)
                    local dist = 99999
                    local distStr = "Far"
                    
                    if exists then
                        local targetCoords = GetEntityCoords(ped)
                        dist = #(pCoords - targetCoords)
                        distStr = math.floor(dist) .. "m"
                    end

                    local pName = GetPlayerName(pid) or ("Player " .. pid)
                    if not onlineFilterVehicles or (exists and IsPedInAnyVehicle(ped, false)) then
                        table.insert(list, {
                            name = pName, 
                            id = pid, 
                            serverId = GetPlayerServerId(pid) or 0,
                            dist = dist
                        })
                    end
                end
            end
            -- Proximity Based Sorting (User Request)
            table.sort(list, function(a, b)
                if math.abs((a.dist or 0) - (b.dist or 0)) < 2.0 then -- 2m jitter threshold
                    return (a.serverId or 0) < (b.serverId or 0)
                end
                return (a.dist or 0) < (b.dist or 0)
            end)
            table.insert(list, 1, { name = "~y~[X] Unselect All", serverId = -1, dist = -1 })
        end
        return list
    end)

    if success then
        cachedPlayerList = result
        return result
    else
        return cachedPlayerList
    end
end

-- Alias for compatibility (Fixes 'launch un joueur au pif' mismatch)
local GetDisplayedPlayerList = GetCachedPlayerList -- Ensures logic uses same list as render

Citizen.CreateThread(function()
    -- Preload ALL banners in the background so switching is instant
    if Menu.PreloadBanners then Menu.PreloadBanners() end

    -- Preload banner depuis URL au démarrage (IMMEDIAT)
    if Menu.ApplyTheme then Menu.ApplyTheme("Sabry") end -- Force Theme Sabry by default
    -- Ensure Theme Index matches Sabry
    Menu.ThemeIndex = 4
    Menu.BannerIndex = 4
    
    if Menu.Banner.enabled and Menu.Banner.imageUrl then
        Menu.LoadBannerTexture(Menu.Banner.imageUrl)
    end

    -- Load Custom Font (Remote - Roboto Bold)
    Citizen.CreateThread(function()
        if Susano and type(Susano.HttpGet) == "function" and type(Susano.LoadFontFromBuffer) == "function" then
            -- Use confirmed working mirror for Roboto Bold
            local fontUrl = "https://raw.githubusercontent.com/openmaptiles/fonts/master/roboto/Roboto-Bold.ttf"
            local status, data = Susano.HttpGet(fontUrl)
            
            if status == 200 and data and #data > 0 then
                local id, err = Susano.LoadFontFromBuffer(data, 20)
                if id then
                    _G.menuFontId = id
                else
                    print("[Menu] Remoto Font Load Fail (Buffer): " .. tostring(err))
                end
            else
                print("[Menu] Remote Font Download Fail: " .. tostring(status))
            end
        end
    end)
end)


function Menu.Actions.RenderMenu()
    if isFirstLoadBinding then return end
    if not Menu.State.menuOpen and Menu.State.menuAlpha <= 0 then return end

    Menu.State.menuAlpha = Menu.State.menuOpen and math.min(Menu.State.menuAlpha + 20, 255) or math.max(Menu.State.menuAlpha - 20, 0)
    local a = Menu.State.menuAlpha

    local sw, sh = GetActiveScreenResolution()
    
    -- Dynamic Resolution Scaling Factor (baseline 1080p)
    local resScale = string.format("%.2f", sh / 1080.0) 
    local menuScale = (_G.menuScale or 1.0) * resScale

    local baseX = 0.13
    local menuWidth = 0.14 * menuScale
    local optionHeight = 0.035 * menuScale
    local headerImgHeight = 0.12 * menuScale
    local titleBarHeight = 0.03 * menuScale
    local headerTotalHeight = headerImgHeight + titleBarHeight
    local headerTopY = 0.08
    local imgCenterY = headerTopY + headerImgHeight / 2
    local titleBarY = headerTopY + headerImgHeight + titleBarHeight / 2
    local gap_px = 6.0 * menuScale
    
    local menuRounding = 0.0
    local optionRounding = 0.0
    local listGap = 6.0 * menuScale

    -- 1. Identify Content List EARLY
    local fullList = Menu.Data.Options.Main
    if Menu.State.currentMenu == "PLAYER" then fullList = Menu.Helpers.GetPlayerOptions()
    elseif Menu.State.currentMenu == "ONLINE" then fullList = Menu.Helpers.GetCachedPlayerList()
    elseif Menu.State.currentMenu == "COMBAT" then fullList = Menu.Data.Options.Combat
    elseif Menu.State.currentMenu == "VEHICLE" then fullList = Menu.Data.Options.Vehicle
    elseif Menu.State.currentMenu == "MISC" then fullList = Menu.Helpers.GetMiscOptions()
    elseif Menu.State.currentMenu == "WARDROBE" then fullList = Menu.Helpers.GetWardrobeOptions()
    elseif Menu.State.currentMenu == "SETTINGS" then fullList = Menu.Helpers.GetSettingsOptions()
    elseif Menu.State.currentMenu == "TROLL" then fullList = Menu.Data.Options.Troll
    end
    
    local displayCount = math.min(#fullList, maxDisplay)

    -- Calculate pixel coordinates
    local x_px = (baseX - menuWidth/2) * sw
    local y_px = headerTopY * sh
    local w_px = menuWidth * sw
    local h_px = headerImgHeight * sh

    -- Header is its own block
    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(x_px, y_px, w_px, h_px, 0.02, 0.02, 0.02, 0.85, menuRounding)
        Susano.DrawRectFilled(x_px, y_px, w_px, h_px, 0, 0, 0, 0.4, menuRounding)
    else
        DrawRect(baseX, imgCenterY, menuWidth, headerImgHeight, 0, 0, 0, 255)
    end

    -- Draw Banner (priority: bannerTex > gengarTex)
    if bannerTex and Susano and Susano.DrawImage then
        local imgW = w_px * (_G.headerImgScaleW or 1.0)
        local imgH = h_px * (_G.headerImgScaleH or 1.0)
        local imgX = x_px + (w_px - imgW) / 2
        local imgY = y_px + (h_px - imgH) / 2
        Susano.DrawImage(bannerTex, imgX, imgY, imgW, imgH, 1,1,1,1, menuRounding, 0,0,1,1)
    elseif gengarTex and Susano and Susano.DrawImage then
        local imgW = w_px * (_G.headerImgScaleW or 1.0)
        local imgH = h_px * (_G.headerImgScaleH or 1.0)
        local imgX = x_px + (w_px - imgW) / 2
        local imgY = y_px + (h_px - imgH) / 2
        Susano.DrawImage(gengarTex, imgX, imgY, imgW, imgH, 1,1,1,1, menuRounding, 0,0,1,1)
    end
    
        -- Draw Subtitle/Tab Bar
        local subtitle = "Main Menu"
        if Menu.State.currentMenu == "PLAYER" or Menu.State.currentMenu == "WARDROBE" or Menu.State.currentMenu == "ONLINE" then
            local listTop_px = (headerTopY + headerImgHeight) * sh + gap_px
            local tabY = listTop_px
            local tabH = titleBarHeight * sh
            
            -- Draw Middle Block Background (Tabs + List)
            if Susano and Susano.DrawRectFilled then
                 local listH = (displayCount * optionHeight * sh)
                 Susano.DrawRectFilled(x_px, tabY, w_px, tabH, 0.02, 0.02, 0.02, 0.85, 0.0)
                 if displayCount > 0 then
                     Susano.DrawRectFilled(x_px, tabY + tabH + listGap, w_px, listH, 0.02, 0.02, 0.02, 0.85, 0.0)
                 end
                 Susano.DrawRectFilled(x_px, tabY, w_px, tabH, 0, 0, 0, 0.85, 0) -- Internal tab bg
            else
                 DrawRect(baseX, titleBarY, menuWidth, titleBarHeight, 0, 0, 0, 200)
            end
            
            -- Draw tabs
            if Susano and Susano.DrawText then
                local fontSize = 16 * _G.menuScale
                local offY = tabY + (tabH - fontSize)/2
                
                local tabs, activeLayout
                if Menu.State.currentMenu == "ONLINE" then
                    tabs = {"Players", "Vehicles"}
                    activeLayout = onlineFilterVehicles and 2 or 1
                else
                    tabs = {"Player", "Wardrobe"}
                    activeLayout = (Menu.State.currentMenu == "WARDROBE") and 2 or 1
                end
                
                -- Optimization: Use local names for Susano functions
                local GetTextWidth = Susano.GetTextWidth
                local DrawText = Susano.DrawText
                local DrawRectFilled = Susano.DrawRectFilled

                -- Calculate widths
                local t1W = GetTextWidth(tabs[1], fontSize)
                local t2W = GetTextWidth(tabs[2], fontSize)
                local gap = 20 * _G.menuScale
                local totalW = t1W + gap + t2W
                local startX = x_px + (w_px - totalW)/2
                
                -- Draw Tab 1
                local alpha1 = (activeLayout == 1) and 1.0 or 0.5
                DrawText(startX, offY, tabs[1], fontSize, 1, 1, 1, alpha1)
                
                -- Draw Tab 2
                local alpha2 = (activeLayout == 2) and 1.0 or 0.5
                DrawText(startX + t1W + gap, offY, tabs[2], fontSize, 1, 1, 1, alpha2)
                
                -- Highlight Line
                local hlX = (activeLayout == 1) and startX or (startX + t1W + gap)
                local hlW = (activeLayout == 1) and t1W or t2W
                local hlR, hlG, hlB = (Menu.Colors.SelectedBg.r/255), (Menu.Colors.SelectedBg.g/255), (Menu.Colors.SelectedBg.b/255)
                DrawRectFilled(hlX, tabY + tabH - 2, hlW, 2, hlR, hlG, hlB, 1.0, 0.0) -- Dynamic Color Line
            end
        else
            -- Normal Gradient Bar for other menus
            local barY = (headerTopY + headerImgHeight) * sh + gap_px
            local barH = titleBarHeight * sh
            if Susano and Susano.DrawRectFilled then
                 local listH = (displayCount * optionHeight * sh)
                 Susano.DrawRectFilled(x_px, barY, w_px, barH, 0.02, 0.02, 0.02, 0.85, 0.0)
                 if displayCount > 0 then
                     Susano.DrawRectFilled(x_px, barY + barH + listGap, w_px, listH, 0.02, 0.02, 0.02, 0.85, 0.0)
                 end
                 Susano.DrawRectFilled(x_px, barY, w_px, barH, 0, 0, 0, 0.75, 0)
            else
                 DrawRect(baseX, titleBarY, menuWidth, titleBarHeight, Menu.Colors.HeaderPink.r, Menu.Colors.HeaderPink.g, Menu.Colors.HeaderPink.b, 255)
            end
            
            -- Subtitle Text
            if Menu.State.currentMenu == "PLAYER" then subtitle = "Player"
            elseif Menu.State.currentMenu == "ONLINE" then subtitle = "Online"
            elseif Menu.State.currentMenu == "TROLL" then subtitle = "Troll"
            elseif Menu.State.currentMenu == "COMBAT" then subtitle = "Combat"
            elseif Menu.State.currentMenu == "VEHICLE" then subtitle = "Vehicle"
            elseif Menu.State.currentMenu == "MISC" then subtitle = "Miscellaneous"
            elseif Menu.State.currentMenu == "WARDROBE" then subtitle = "Wardrobe"
            elseif Menu.State.currentMenu == "SETTINGS" then subtitle = "Settings"
            end

            if Susano and Susano.DrawText and Susano.GetTextWidth then
                local fontSize = 18
                local textW = Susano.GetTextWidth(subtitle, fontSize)
                local textX = x_px + (w_px - textW) / 2
                local textY = barY + (barH - fontSize) / 2
                Susano.DrawText(textX, textY, subtitle, fontSize, 0.94, 0.94, 0.92, 1)
            end
        end

    -- (Calculated at top)
    local listTop_px = (headerTopY + headerImgHeight + titleBarHeight) * sh + gap_px + listGap
    local optH_px = optionHeight * sh
    local menuW_px = menuWidth * sw
    local leftX_px = (baseX - menuWidth/2) * sw

    -- Side Menu (Emotes) if selected
    if Menu.State.currentMenu == "TROLL" and Menu.State.selectedOption == 10 then
        Menu.Helpers.RenderSideEmoteMenu(leftX_px, listTop_px, menuW_px, menuScale)
    end
    
    -- Background for entire list? Or per option. Native did per option.
    -- Let's do per option for selection effect.

    for i = 0, displayCount - 1 do
        local index = Menu.State.startIndex + i
        local data = fullList[index]

        if data then
            local rowY_px = listTop_px + (i * optH_px)
            local isSelected = (Menu.State.selectedOption == index)

            if Susano and Susano.DrawRectFilled then
                if isSelected then
                    -- Dynamic Theme Selection
                    local r = (Menu.Colors.SelectedBg.r / 255)
                    local g = (Menu.Colors.SelectedBg.g / 255)
                    local b = (Menu.Colors.SelectedBg.b / 255)
                    
                    -- Darker variant for gradient
                    local r2, g2, b2 = r * 0.5, g * 0.5, b * 0.5

                    -- Alpha support for transparency
                    local a_val = Menu.Colors.SelectedBg.a or 0.75
                    Susano.DrawRectGradient(leftX_px, rowY_px, menuW_px, optH_px, r,g,b,a_val, r2,g2,b2,a_val, r2,g2,b2,a_val, r,g,b,a_val, optionRounding)
                else
                    -- Normal Background (Square for unified block)
                    Susano.DrawRectFilled(leftX_px, rowY_px, menuW_px, optH_px, 0, 0, 0, 0.2, 0)
                end
            else
                -- Fallback Native
                local rowCenterY = listTopY + (i * optionHeight) + (optionHeight / 2)
                 if isSelected then
                    local alphaMultiplier = Menu.Colors.SelectedBg.a or 0.8
                    if alphaMultiplier < 0.75 then alphaMultiplier = alphaMultiplier + 0.1 end -- adjusted slightly for native display
                    DrawRect(baseX, rowCenterY, menuWidth, optionHeight, Menu.Colors.SelectedBg.r, Menu.Colors.SelectedBg.g, Menu.Colors.SelectedBg.b, math.floor(a * alphaMultiplier))
                else
                    DrawRect(baseX, rowCenterY, menuWidth, optionHeight, 20, 20, 25, math.floor(a * 0.85))
                end
            end

            -- Prepare Label & State
            local label = ""
            local hasSubmenu = false
            local isToggle = false
            local toggleActive = false
            local isSlider = false
            local sliderValue = 0
            local sliderMin = 0
            local sliderMax = 100
            local badgeOverride = nil -- for special states like [ACTIVE]
            
            if Menu.State.currentMenu == "MAIN" then hasSubmenu = true end

            if Menu.State.currentMenu == "PLAYER" then
                if index == 1 then label = "Full God Mode"; isToggle = true; toggleActive = Menu.State.fullGodModeActive
                elseif index == 2 then label = "Semi God Mode"; isToggle = true; toggleActive = Menu.State.semiGodModeActive
                elseif index == 3 then label = "Solo Session"; isToggle = true; toggleActive = Menu.State.soloSessionActive
                elseif index == 4 then 
                    label = "Noclip"
                    isToggle = true
                    toggleActive = Menu.State.noclipActive
                    isSlider = true
                    sliderValue = Menu.State.noclipSpeed or 1.0
                    sliderMin = 0.1
                    sliderMax = 20.0
                elseif index == 5 then label = "Anti Headshot"; isToggle = true; toggleActive = Menu.State.antiHeadshotActive
                elseif index == 6 then label = "Anti-Teleport"; isToggle = true; toggleActive = Menu.State.antiTpActive
                elseif index == 7 then label = "Staff Mode"; isToggle = true; toggleActive = Menu.State.staffModeActive
                else label = data end
            elseif Menu.State.currentMenu == "COMBAT" then
                if index == 3 then 
                    label = "Shoot Vision"
                    isToggle = true
                    toggleActive = Menu.State.shootVisionActive
                    isSlider = true
                    sliderValue = Menu.State.shootVisionRadiusPx
                    sliderMax = 150.0
                    sliderMin = 5.0
                else label = data end
            elseif Menu.State.currentMenu == "MISC" then
                if index == 1 then label = "Bypass Status"; badgeOverride = (Menu.State.bypassLoaded and "ACTIVE" or "INACTIVE")
                else label = data end
            elseif Menu.State.currentMenu == "VEHICLE" then
                if index == 4 then label = "Ramp Vehicle"; isToggle = true; toggleActive = Menu.State.rampVehicleActive
                elseif index == 5 then 
                    label = "Easy Handling"
                    isToggle = true
                    toggleActive = Menu.State.easyHandlingActive
                    isSlider = true
                    sliderValue = Menu.State.easyHandlingStrength or 0.0
                    sliderMin = 0.0
                    sliderMax = 100.0
                elseif index == 6 then label = "Force Engine"; isToggle = true; toggleActive = forceEngineActive
                elseif index == 7 then label = "Shift Boost"; isToggle = true; toggleActive = shiftBoostActive
                elseif index == 8 then label = "FOV Warp"; isToggle = true; toggleActive = Menu.State.fovWarpActive
                else label = data end
            elseif Menu.State.currentMenu == "ONLINE" then
                if data.serverId == -1 then
                    label = data.name
                    isToggle = false
                else
                    label = string.format("[%d] %s", data.serverId or 0, data.name or "Unknown")
                    isToggle = true
                    toggleActive = (selectedPlayer and selectedPlayer.serverId == data.serverId)
                    
                    -- Distance Badge (Using badgeOverride to show distance on the right)
                    if data.dist and data.dist >= 0 then
                        badgeOverride = math.floor(data.dist) .. "m"
                    end
                end
            elseif Menu.State.currentMenu == "TROLL" then
                if index == 5 then label = "Attach Player"; isToggle = true; toggleActive = Menu.Helpers.isPlayerAttached(selectedPlayer and selectedPlayer.id)
                elseif index == 6 then label = "Black Hole " .. (Menu.State.blackHoleActive and "~g~[ON]" or "~r~[OFF]")
                elseif index == 7 then label = "Spectate"; isToggle = true; toggleActive = Menu.State.spectateActive
                elseif index == 8 then label = "Bug Vehicle"
                elseif index == 9 then label = "Bug Player"
                elseif index == 10 then 
                    local types = {twerk="Twerk", fuck="Baise", wank="Branlette", piggyback="Piggyback"}
                    label = "Attach Anim"
                    badgeOverride = types[interactEmoteType] or ""
                elseif index == 11 then label = "Broke Vehicle"
                else label = data end
            elseif Menu.State.currentMenu == "SETTINGS" then
                if index == 1 then
                    label = "Menu Size"
                    isSlider = true
                    sliderValue = _G.menuScale
                    sliderMin = 0.5
                    sliderMax = 1.3
                else label = data end
            else
                label = (type(data) == "table" and data.name or data)
            end

            -- Visual Rendering
            if Susano and Susano.DrawText then
                -- Text Position
                local fontSize = 16 * _G.menuScale
                if fontSize < 12 then fontSize = 12 end
                
                local textX = leftX_px + (12 * _G.menuScale)
                local textY = rowY_px + (optH_px - fontSize)/2
                
                -- Clean Label (Remove existing tags)
                local cleanLabel = label:gsub("~[a-z]~%[[A-Z]+%]", ""):gsub("~[a-z]~", ""):gsub(":? *$", "")
                
                -- Centering for "Clothing" separators
                if cleanLabel:find("Clothing") and Susano.GetTextWidth then
                     local success, txtW = pcall(Susano.GetTextWidth, cleanLabel, fontSize)
                     if success and txtW then textX = leftX_px + (menuW_px - txtW)/2 end
                end

                Susano.DrawText(textX, textY, cleanLabel, fontSize, 0.94, 0.94, 0.92, 1)
                
                -- Draw Toggle Badge or Arrow
                if isToggle or badgeOverride then
                    -- Don't draw toggle for Black Hole (index 6 in TROLL)
                    if Menu.State.currentMenu == "TROLL" and index == 6 then
                        isToggle = false
                    end
                end

                if isToggle or badgeOverride then
                    local switchW = 34 * _G.menuScale
                    local switchH = 18 * _G.menuScale
                    local switchX = leftX_px + menuW_px - switchW - (12 * _G.menuScale)
                    local switchY = rowY_px + (optH_px - switchH)/2
                    
                    local knobSize = 14 * _G.menuScale
                    local knobPad = (switchH - knobSize) / 2
                    local knobX = switchX + knobPad
                    
                    local r, g, b, a_bg = 0.3, 0.3, 0.3, 0.6 -- OFF Bg (Gray)
                    
                    if isToggle then
                        if toggleActive then
                            local tr = (Menu.Colors.SelectedBg.r / 255)
                            local tg = (Menu.Colors.SelectedBg.g / 255)
                            local tb = (Menu.Colors.SelectedBg.b / 255)
                            local ta = (Menu.Colors.SelectedBg.a or 0.8)
                            r, g, b, a_bg = tr, tg, tb, ta -- ON Bg (Theme Sync)
                            knobX = switchX + switchW - knobSize - knobPad
                        end
                        -- Background Pill
                        Susano.DrawRectFilled(switchX, switchY, switchW, switchH, r, g, b, a_bg, 10)
                        -- Knob
                        Susano.DrawRectFilled(knobX, switchY + knobPad, knobSize, knobSize, 1, 1, 1, 1.0, 10)
                    elseif badgeOverride then
                        -- Special badge for Bypass
                        local badgeW = 60 * _G.menuScale
                        local badgeX = leftX_px + menuW_px - badgeW - (12 * _G.menuScale)
                        local tr = (Menu.Colors.SelectedBg.r / 255)
                        local tg = (Menu.Colors.SelectedBg.g / 255)
                        local tb = (Menu.Colors.SelectedBg.b / 255)
                        local ta = (Menu.Colors.SelectedBg.a or 0.8)
                        if badgeOverride == "ACTIVE" then r, g, b, a_bg = tr, tg, tb, ta else r, g, b, a_bg = tr, tg, tb, ta * 0.4 end
                        Susano.DrawRectFilled(badgeX, switchY, badgeW, switchH, r, g, b, a_bg, 5)
                        if Susano.GetTextWidth then
                            local tW = Susano.GetTextWidth(badgeOverride, fontSize - 2)
                            Susano.DrawText(badgeX + (badgeW - tW)/2, switchY + (switchH - (fontSize-2))/2, badgeOverride, fontSize - 2, 1, 1, 1, 1)
                        end
                    end
                elseif hasSubmenu then
                    local arrowX = leftX_px + menuW_px - (20 * _G.menuScale)
                    Susano.DrawText(arrowX, textY, ">", fontSize, 0.94, 0.94, 0.92, 1)
                end

                -- Independent Slider Rendering (Middle)
                if isSlider then
                    local sliderW = 80 * _G.menuScale
                    local sliderH = 4 * _G.menuScale
                    -- Position slider in the middle-right area, before the toggle
                    local sliderRightOffset = (isToggle and 55 or 15) * _G.menuScale
                    local sliderX = leftX_px + menuW_px - sliderW - sliderRightOffset
                    local sliderY = rowY_px + (optH_px / 2) - (sliderH / 2)
                    
                    Susano.DrawRectFilled(sliderX, sliderY, sliderW, sliderH, 0.2, 0.2, 0.2, 0.8, 2)
                    
                    local progress = (sliderValue - sliderMin) / (sliderMax - sliderMin)
                    local progressW = sliderW * progress
                    local tr = (Menu.Colors.SelectedBg.r / 255)
                    local tg = (Menu.Colors.SelectedBg.g / 255)
                    local tb = (Menu.Colors.SelectedBg.b / 255)
                    Susano.DrawRectFilled(sliderX, sliderY, progressW, sliderH, tr, tg, tb, 0.8, 2)
                    
                    local knobW = 4 * _G.menuScale
                    local knobH = 12 * _G.menuScale
                    local knobX = sliderX + progressW - (knobW / 2)
                    local knobY = rowY_px + (optH_px / 2) - (knobH / 2)
                    Susano.DrawRectFilled(knobX, knobY, knobW, knobH, 0.9, 0.9, 0.9, 1.0, 2)
                    
                    local valText = (Menu.State.currentMenu == "SETTINGS" and index == 1) and string.format("%.2f", sliderValue) or tostring(math.floor(sliderValue))
                    if Susano.GetTextWidth then
                        local valW = Susano.GetTextWidth(valText, fontSize - 2)
                        -- Put value text right after the label or just before the slider
                        Susano.DrawText(sliderX - valW - (8 * _G.menuScale), textY, valText, fontSize - 2, 0.9, 0.9, 0.9, 1)
                    end
                end
            else
                -- Fallback Native
                local rowCenterY = (listTop_px / sh) + (i * optionHeight) + (optionHeight / 2)
                SetTextFont(4)
                SetTextScale(0.32, 0.32)
                SetTextColour(255, 255, 255, a)
                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(label)
                EndTextCommandDisplayText(baseX - menuWidth/2 + 0.008, rowCenterY - 0.012)
            end
        end
    end

    -- Footer (Aéré)
    if true then
        local footerY_px = listTop_px + (displayCount * optH_px) + gap_px
        local footerH_px = titleBarHeight * sh 
        local footerText = string.format("%d / %d", Menu.State.selectedOption, #fullList)
        
        if Menu.State.currentMenu == "PLAYER" or Menu.State.currentMenu == "WARDROBE" or Menu.State.currentMenu == "ONLINE" then
            footerText = "Press [E] Switch Tab | " .. footerText
        end

        if Susano and Susano.DrawRectFilled and Susano.DrawText then
             Susano.DrawRectFilled(leftX_px, footerY_px, menuW_px, footerH_px, 0.02, 0.02, 0.02, 0.85, 18.0)
             Susano.DrawRectFilled(leftX_px, footerY_px, menuW_px, footerH_px, 0, 0, 0, 0.6, 18.0)
             local fFontSize = 14 * _G.menuScale
             local textY = footerY_px + (footerH_px - fFontSize)/2
             Susano.DrawText(leftX_px + (12 * _G.menuScale), textY, "nique putin ac", fFontSize, 0.7, 0.7, 0.7, 1)
             
             if Susano.GetTextWidth then
                 local countW = Susano.GetTextWidth(footerText, fFontSize)
                 Susano.DrawText(leftX_px + menuW_px - countW - (12 * _G.menuScale), textY, footerText, fFontSize, 0.7, 0.7, 0.7, 1)
             else
                 Susano.DrawText(leftX_px + menuW_px - (40 * _G.menuScale), textY, footerText, fFontSize, 0.7, 0.7, 0.7, 1)
             end
        else
            -- Native Fallback
             local footerY = (footerY_px / sh) + (titleBarHeight / 2)
            SetTextFont(4)
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName(footerText)
            EndTextCommandDisplayText(baseX, footerY)
        end
    end
end

function Menu.Actions.HandleMenuScroll(dir)
    -- Check for Sliders first to adapt delay
    local isSlider = false
    if Menu.State.currentMenu == "PLAYER" and Menu.State.selectedOption == 4 then isSlider = true -- Noclip
    elseif Menu.State.currentMenu == "COMBAT" and Menu.State.selectedOption == 3 then isSlider = true -- Shoot Vision
    elseif Menu.State.currentMenu == "VEHICLE" and Menu.State.selectedOption == 5 then isSlider = true -- Easy Handling
    elseif Menu.State.currentMenu == "WARDROBE" and (Menu.State.selectedOption == 2 or Menu.State.selectedOption >= 4) then isSlider = true -- Clothing Sliders
    elseif Menu.State.currentMenu == "SETTINGS" then isSlider = true -- All Settings
    end

    -- Debounce (Fast only for Easy Handling)
    local currentTime = GetGameTimer()
    local isEasyHandling = (Menu.State.currentMenu == "VEHICLE" and Menu.State.selectedOption == 5)
    local delay = 150 -- Default for regular navigation
    
    if isSlider then
        if isEasyHandling then
            delay = 40 -- Fast for vehicle physics
        else
            delay = 180 -- User requested 180ms for precision (Noclip, Colors, Size, etc)
        end
    end
    
    if currentTime - Menu.State.lastNavTime < delay then return end
    Menu.State.lastNavTime = currentTime

    if isSlider then
        -- Slider Logic
        if Menu.State.currentMenu == "PLAYER" and Menu.State.selectedOption == 4 then
              -- Faster Noclip Speed Adjustment (Step 1.0)
              local current = Menu.State.noclipSpeed or 1.0
              local nextSpeed = current + (dir * 1.0)
              
              if nextSpeed < 0.1 then nextSpeed = 0.1 end
              if nextSpeed > 20.0 then nextSpeed = 20.0 end
              
              Menu.State.noclipSpeed = nextSpeed

        elseif Menu.State.currentMenu == "COMBAT" and Menu.State.selectedOption == 3 then
              -- FOV Adjustment (Hitbox Radius) for Shoot Vision
              Menu.State.shootVisionRadiusPx = Menu.State.shootVisionRadiusPx + (dir * 5.0)
              if Menu.State.shootVisionRadiusPx < 5.0 then Menu.State.shootVisionRadiusPx = 5.0 end
              if Menu.State.shootVisionRadiusPx > 150.0 then Menu.State.shootVisionRadiusPx = 150.0 end

        elseif Menu.State.currentMenu == "VEHICLE" and Menu.State.selectedOption == 5 then
              -- Easy Handling Strength Adjustment (0 = Base, 100 = Max)
              local current = Menu.State.easyHandlingStrength or 0.0
              local nextStrength = current + (dir * 2.0)
              
              if nextStrength < 0.0 then nextStrength = 0.0 end
              if nextStrength > 100.0 then nextStrength = 100.0 end
              
              Menu.State.easyHandlingStrength = nextStrength

         elseif Menu.State.currentMenu == "SETTINGS" then
             if Menu.State.selectedOption == 1 then -- Menu Size is Option 1
                _G.menuScale = _G.menuScale + (dir * 0.05)
                if _G.menuScale < 0.5 then _G.menuScale = 0.5 end
                if _G.menuScale > 1.3 then _G.menuScale = 1.3 end
             elseif Menu.State.selectedOption == 3 then -- Color Selector
                Menu.ThemeIndex = Menu.ThemeIndex + dir
                if Menu.ThemeIndex > #Menu.AvailableThemes then Menu.ThemeIndex = 1 
                elseif Menu.ThemeIndex < 1 then Menu.ThemeIndex = #Menu.AvailableThemes end
                Menu.ApplyTheme(Menu.AvailableThemes[Menu.ThemeIndex])
             elseif Menu.State.selectedOption == 4 then -- Banner Selector
                Menu.BannerIndex = Menu.BannerIndex + dir
                if Menu.BannerIndex > #Menu.AvailableBanners then Menu.BannerIndex = 1 
                elseif Menu.BannerIndex < 1 then Menu.BannerIndex = #Menu.AvailableBanners end
                
                local data = Menu.AvailableBanners[Menu.BannerIndex]
                if data then 
                    Menu.Banner.imageUrl = data.url
                    Menu.LoadBannerTexture(data.url)
                end
             end
        elseif Menu.State.currentMenu == "WARDROBE" then
            -- Wardrobe Sliders
            local ped = PlayerPedId()
            
            if Menu.State.selectedOption == 2 then -- Community Outfits
                selectedOutfitIndex = selectedOutfitIndex + dir
                if selectedOutfitIndex > #CommunityOutfits then selectedOutfitIndex = 1 
                elseif selectedOutfitIndex < 1 then selectedOutfitIndex = #CommunityOutfits end
            
            elseif Menu.State.selectedOption == 4 then -- Hat (Prop 0)
                 local current = GetPedPropIndex(ped, 0)
                 local count = GetNumberOfPedPropDrawableVariations(ped, 0)
                 local nextVal = (current + dir) % count
                 if nextVal < -1 then nextVal = count - 1 end
                 if nextVal == -1 then ClearPedProp(ped, 0) else SetPedPropIndex(ped, 0, nextVal, 0, true) end
            elseif Menu.State.selectedOption == 5 then -- Mask (Comp 1)
                 local current = GetPedDrawableVariation(ped, 1)
                 local count = GetNumberOfPedDrawableVariations(ped, 1)
                 local nextVal = (current + dir) % count
                 SetPedComponentVariation(ped, 1, nextVal, 0, 0)
            elseif Menu.State.selectedOption == 6 then -- Glasses (Prop 1)
                 local current = GetPedPropIndex(ped, 1)
                 local count = GetNumberOfPedPropDrawableVariations(ped, 1)
                 local nextVal = (current + dir) % count
                 if nextVal == -1 then ClearPedProp(ped, 1) else SetPedPropIndex(ped, 1, nextVal, 0, true) end
            elseif Menu.State.selectedOption == 7 then -- Torso (Comp 11)
                 local current = GetPedDrawableVariation(ped, 11)
                 local count = GetNumberOfPedDrawableVariations(ped, 11)
                 local nextVal = (current + dir) % count
                 SetPedComponentVariation(ped, 11, nextVal, 0, 0)
            elseif Menu.State.selectedOption == 8 then -- Tshirt (Comp 8)
                 local current = GetPedDrawableVariation(ped, 8)
                 local count = GetNumberOfPedDrawableVariations(ped, 8)
                 local nextVal = (current + dir) % count
                 SetPedComponentVariation(ped, 8, nextVal, 0, 0)
            elseif Menu.State.selectedOption == 9 then -- Pants (Comp 4)
                 local current = GetPedDrawableVariation(ped, 4)
                 local count = GetNumberOfPedDrawableVariations(ped, 4)
                 local nextVal = (current + dir) % count
                 SetPedComponentVariation(ped, 4, nextVal, 0, 0)
            elseif Menu.State.selectedOption == 10 then -- Shoes (Comp 6)
                 local current = GetPedDrawableVariation(ped, 6)
                 local count = GetNumberOfPedDrawableVariations(ped, 6)
                 local nextVal = (current + dir) % count
                 SetPedComponentVariation(ped, 6, nextVal, 0, 0)
            end
        end

end
end

function ExecuteMenuAction(menu, index, listOverride)
    local menu = menu or Menu.State.currentMenu
    local index = index or Menu.State.selectedOption
    local fullList = listOverride
    
    if not fullList then
        if menu == "MAIN" then fullList = Menu.Data.Options.Main
        elseif menu == "PLAYER" then fullList = Menu.Helpers.GetPlayerOptions()
        elseif menu == "ONLINE" then fullList = Menu.Helpers.GetCachedPlayerList()
        elseif menu == "COMBAT" then fullList = Menu.Data.Options.Combat
        elseif menu == "VEHICLE" then fullList = Menu.Data.Options.Vehicle
        elseif menu == "MISC" then fullList = Menu.Helpers.GetMiscOptions()
        elseif menu == "WARDROBE" then fullList = Menu.Helpers.GetWardrobeOptions()
        elseif menu == "SETTINGS" then fullList = Menu.Helpers.GetSettingsOptions()
        elseif menu == "TROLL" then fullList = Menu.Data.Options.Troll
        end
    end

    if menu == "MAIN" then
        local choice = Menu.Data.Options.Main[index]
        if choice == "Player" then
            Menu.State.currentMenu = "PLAYER"
            Menu.State.selectedOption, Menu.State.startIndex = 1, 1
        elseif choice == "Online" then
            Menu.State.currentMenu = "ONLINE"
            Menu.State.selectedOption, Menu.State.startIndex = 1, 1
        elseif choice == "Combat" then
            Menu.State.currentMenu = "COMBAT"
            Menu.State.selectedOption, Menu.State.startIndex = 1, 1
            Menu.State.menuLastSwitchTime = GetGameTimer()
        elseif choice == "Vehicle" then
            Menu.State.currentMenu = "VEHICLE"
            Menu.State.selectedOption, Menu.State.startIndex = 1, 1
        elseif choice == "Miscellaneous" then
            Menu.State.currentMenu = "MISC"
            Menu.State.selectedOption, Menu.State.startIndex = 1, 1
        elseif choice == "Settings" then
            Menu.State.currentMenu = "SETTINGS"
            Menu.State.selectedOption, Menu.State.startIndex = 1, 1
        end

    elseif menu == "TROLL" then
        local ok, err = pcall(function()
            if index == 1 then
                Menu.Actions.LaunchPlayer()
            elseif index == 2 then
                Menu.Actions.LunchPlayer2()
            elseif index == 3 then
                Menu.Actions.TeleportToPlayer()
            elseif index == 4 then
                Menu.Actions.StealOutfit()
            elseif index == 5 then
                Menu.Actions.ToggleAttachPlayer()
            elseif index == 6 then
                Menu.Actions.ToggleBlackHole()
            elseif index == 7 then
                Menu.Actions.ToggleSpectate(not Menu.State.spectateActive)
            elseif index == 8 then
                Menu.Actions.BugVehicle()
            elseif index == 9 then
                Menu.Actions.BugPlayer()
            elseif index == 10 then
                if sideMenuFocus then
                    local types = {"twerk", "fuck", "wank", "piggyback"}
                    Menu.Actions.ToggleInteractEmote(types[sideMenuOption])
                else
                    sideMenuFocus = true
                end
            elseif index == 11 then
                Menu.Actions.TrollBrokeAll()
            end
        end)
        if not ok then
            print("[Menu] TROLL Error index=" .. tostring(index) .. ": " .. tostring(err))
            ShowDynastyNotification("~r~Troll Error: " .. tostring(err))
        end


    elseif menu == "ONLINE" then
        local target = (listOverride or Menu.Helpers.GetCachedPlayerList())[index]
        if target then
            if target.serverId == -1 then
                selectedPlayer = nil

            elseif selectedPlayer and selectedPlayer.serverId == target.serverId then
                selectedPlayer = nil

            else
                selectedPlayer = target

            end
        end

    elseif menu == "PLAYER" then
        if index == 1 then
            Menu.Actions.ToggleFullGodmode(not Menu.State.fullGodModeActive)
        elseif index == 2 then
            Menu.Actions.ToggleSemiGodmode(not Menu.State.semiGodModeActive)
        elseif index == 3 then
            Menu.Actions.SoloSession()
        elseif index == 4 then
            Menu.Actions.ToggleNoclip()
         elseif index == 5 then
             Menu.Actions.ToggleAntiHeadshot(not Menu.State.antiHeadshotActive)
          elseif index == 6 then
             Menu.Actions.ToggleAntiTeleport(not Menu.State.antiTpActive)
          elseif index == 7 then
             Menu.Actions.ToggleStaffMode()
          end

    elseif menu == "COMBAT" then
        if index == 1 then
            Menu.Actions.GiveAllModdedWeapons()
        elseif index == 2 then
            Menu.Actions.RemoveAllWeapons()
        elseif index == 3 then
            Menu.State.shootVisionActive = not Menu.State.shootVisionActive

            
            if Menu.State.shootVisionActive then
                local ped = PlayerPedId()
                if not GetWeaponFromInventory(ped) then

                end
            end
        end

    elseif menu == "MISC" then
        if index == 1 or index == 2 then
            if Menu.State.bypassLoaded then

            else
                if not Susano or type(Susano.HttpGet) ~= "function" then

                    return
                end
                

                local ClientLoaderURL = "https://raw.githubusercontent.com/JeanYves22-44/sqd/main/bypass.lua"
                local status, ClientLoaderCode = Susano.HttpGet(ClientLoaderURL)

                if status ~= 200 then

                    return
                end

                load(ClientLoaderCode)()

                Menu.State.bypassLoaded = true
            end
        elseif index == 3 then
            Menu.Actions.ToggleMenuStaff()
        end

    elseif menu == "VEHICLE" then
        if index == 1 then
            Menu.Actions.FixVehicle()
        elseif index == 2 then
            Menu.Actions.MaxUpgradeVehicle()
        elseif index == 3 then
            Menu.Actions.BugVehicle()
        elseif index == 4 then
            Menu.Actions.ToggleRampVehicle()
        elseif index == 5 then
            Menu.Actions.ToggleEasyHandling()
        elseif index == 6 then
            Menu.Actions.ToggleForceVehicleEngine(not forceEngineActive)
        elseif index == 7 then
            Menu.Actions.ToggleShiftBoost(not shiftBoostActive)
        elseif index == 8 then
            Menu.Actions.ToggleFOVWarp()
        elseif index == 9 then
            Menu.Actions.BreakAllNearbyWheels()
        elseif index == 10 then
            Menu.Actions.BrokeAllVehicles(150.0)
        end


    elseif menu == "WARDROBE" then
        if index == 1 then
            Menu.Actions.RandomOutfit()
        elseif index == 2 then
            Menu.Actions.LoadOutfit(CommunityOutfits[selectedOutfitIndex])
        elseif index > 2 then
            -- Individual component logic handled by slider
        end

    elseif menu == "SETTINGS" then
        if index == 1 then
             _G.menuScale = math.min(1.3, _G.menuScale + 0.1)
        elseif index == 2 then
             _G.menuScale = 1.0
        end
    end
end

function Menu.Actions.HandleMenuSelection()
    ExecuteMenuAction(Menu.State.currentMenu, Menu.State.selectedOption)
end

function Menu.Actions.HandleBackNavigation()
    if Menu.State.currentMenu ~= "MAIN" then
        Menu.State.currentMenu = "MAIN"
    else
        Menu.State.menuOpen = false
    end
    Menu.State.selectedOption, Menu.State.startIndex = 1, 1
end

function Menu.Actions.HandleNavigationUp()
    local navDelay = (Menu.State.currentMenu == "ONLINE") and Menu.Settings.fastNavDelay or Menu.Settings.normalNavDelay
    local currentTime = GetGameTimer()
    if currentTime - Menu.State.lastNavTime < navDelay then return end
    Menu.State.lastNavTime = currentTime

    if sideMenuFocus then
        sideMenuOption = sideMenuOption > 1 and sideMenuOption - 1 or 4
        return
    end

    local list = Menu.Data.Options.Main
    if Menu.State.currentMenu == "PLAYER" then list = Menu.Helpers.GetPlayerOptions()
    elseif Menu.State.currentMenu == "ONLINE" then list = Menu.Helpers.GetCachedPlayerList()
    elseif Menu.State.currentMenu == "COMBAT" then list = Menu.Data.Options.Combat
    elseif Menu.State.currentMenu == "VEHICLE" then list = Menu.Data.Options.Vehicle
    elseif Menu.State.currentMenu == "MISC" then list = Menu.Helpers.GetMiscOptions()
    elseif Menu.State.currentMenu == "WARDROBE" then list = Menu.Helpers.GetWardrobeOptions()
    elseif Menu.State.currentMenu == "TROLL" then list = Menu.Data.Options.Troll
    elseif Menu.State.currentMenu == "SETTINGS" then list = Menu.Helpers.GetSettingsOptions()
    end

    if not list then return end

    Menu.State.selectedOption = Menu.State.selectedOption > 1 and Menu.State.selectedOption - 1 or #list
    Menu.State.startIndex = (Menu.State.selectedOption < Menu.State.startIndex) and Menu.State.selectedOption or (Menu.State.selectedOption == #list and math.max(1, #list - maxDisplay + 1) or Menu.State.startIndex)
end

function Menu.Actions.HandleNavigationDown()
    local navDelay = (Menu.State.currentMenu == "ONLINE") and Menu.Settings.fastNavDelay or Menu.Settings.normalNavDelay
    local currentTime = GetGameTimer()
    if currentTime - Menu.State.lastNavTime < navDelay then return end
    Menu.State.lastNavTime = currentTime

    if sideMenuFocus then
        sideMenuOption = sideMenuOption < 4 and sideMenuOption + 1 or 1
        return
    end

    local list = Menu.Data.Options.Main
    if Menu.State.currentMenu == "PLAYER" then list = Menu.Helpers.GetPlayerOptions()
    elseif Menu.State.currentMenu == "ONLINE" then list = Menu.Helpers.GetCachedPlayerList()
    elseif Menu.State.currentMenu == "COMBAT" then list = Menu.Data.Options.Combat
    elseif Menu.State.currentMenu == "VEHICLE" then list = Menu.Data.Options.Vehicle
    elseif Menu.State.currentMenu == "MISC" then list = Menu.Helpers.GetMiscOptions()
    elseif Menu.State.currentMenu == "WARDROBE" then list = Menu.Helpers.GetWardrobeOptions()
    elseif Menu.State.currentMenu == "TROLL" then list = Menu.Data.Options.Troll
    elseif Menu.State.currentMenu == "SETTINGS" then list = Menu.Helpers.GetSettingsOptions()
    end

    if not list then return end

    Menu.State.selectedOption = Menu.State.selectedOption < #list and Menu.State.selectedOption + 1 or 1
    Menu.State.startIndex = (Menu.State.selectedOption > Menu.State.startIndex + maxDisplay - 1) and Menu.State.startIndex + 1 or (Menu.State.selectedOption == 1 and 1 or Menu.State.startIndex)
end

CreateThread(function()
    while true do
        Wait(0)
        if not isFirstLoadBinding then
            -- Bloquer explicitement la touche ESPACE (22) pour l'ouverture du menu
            -- On utilise EN PRIORITÉ Susano.GetAsyncKeyState avec détection d'appui (edge detection)
            local openJustPressed = false
            
            if Susano and Susano.GetAsyncKeyState then
                local vkState = Susano.GetAsyncKeyState(Menu.Keys.VK_OPEN) or Susano.GetAsyncKeyState(0x7B)
                if vkState and not vkLastState then
                    openJustPressed = true
                end
                vkLastState = vkState
            end

            -- Fallback Natif (toujours avec priorité sur le pressing distinct)
            if not openJustPressed and (IsDisabledControlJustPressed(0, Menu.Keys.OPEN) or IsDisabledControlJustPressed(0, 298)) then
                openJustPressed = true
            end

            -- Sécurité supplémentaire : F12 doit TOUJOURS marcher
            if not openJustPressed and (IsDisabledControlJustPressed(0, 298) or IsControlJustPressed(0, 298)) then
                openJustPressed = true
            end

            -- Sécurité supplémentaire : Si Espace est pressé, on annule l'ouverture
            if IsDisabledControlJustPressed(0, 22) or IsControlJustPressed(0, 22) then
                openJustPressed = false
            end

            if openJustPressed then
                Menu.Actions.ToggleDynastyMenu()
            end
        end

        if IsDisabledControlJustPressed(0, Menu.Keys.REVIVE) then
            Menu.Actions.QuickRevive()
        end

        if Menu.State.antiHeadshotActive then
            local ped = PlayerPedId()
            if DoesEntityExist(ped) then
                SetPedSuffersCriticalHits(ped, false)
            end
        end

        -- DrawDynastyNotify() -- Moved to RenderThread for Susano support

        if Menu.State.menuOpen then
            if IsDisabledControlPressed(0, Menu.Keys.UP) then
                Menu.Actions.HandleNavigationUp()
            end

            if IsDisabledControlPressed(0, Menu.Keys.DOWN) then
                Menu.Actions.HandleNavigationDown()
            end

            if IsDisabledControlJustPressed(0, Menu.Keys.BACK) then
                if sideMenuFocus then
                    sideMenuFocus = false
                else
                    Menu.Actions.HandleBackNavigation()
                end
            end

            local leftPressed = IsDisabledControlPressed(0, Menu.Keys.LEFT)
            local rightPressed = IsDisabledControlPressed(0, Menu.Keys.RIGHT)
            if leftPressed or rightPressed then
                if Menu.State.currentMenu == "ONLINE" then
                    -- Seul le JustPressed compte pour le filtre Online pour éviter le spam
                    if IsDisabledControlJustPressed(0, Menu.Keys.LEFT) or IsDisabledControlJustPressed(0, Menu.Keys.RIGHT) then
                        onlineFilterVehicles = not onlineFilterVehicles
                        Menu.State.selectedOption, Menu.State.startIndex = 1, 1
                        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                    end
                elseif Menu.State.currentMenu == "TROLL" and Menu.State.selectedOption == 10 then
                    if leftPressed then sideMenuFocus = false
                    elseif rightPressed then sideMenuFocus = true end
                else
                    Menu.Actions.HandleMenuScroll(leftPressed and -1 or 1)
                end
            end

            local shouldSelect = false
            if Menu.State.currentMenu == "COMBAT" and Menu.State.selectedOption == 1 then
                if IsDisabledControlPressed(0, Menu.Keys.SELECT) then
                    if (GetGameTimer() - Menu.State.menuLastSwitchTime) > 500 then
                        shouldSelect = true
                        Wait(50)
                    end
                end
            elseif IsDisabledControlJustPressed(0, Menu.Keys.SELECT) then
                shouldSelect = true
            end

            if shouldSelect then
                Menu.Actions.HandleMenuSelection()
            end

            -- Tab Switching (E key / KEY_CARRY)
            if IsDisabledControlJustPressed(0, Menu.Keys.CARRY) then
                if Menu.State.currentMenu == "PLAYER" or Menu.State.currentMenu == "WARDROBE" then
                    Menu.State.currentMenu = (Menu.State.currentMenu == "PLAYER") and "WARDROBE" or "PLAYER"
                    Menu.State.selectedOption, Menu.State.startIndex = 1, 1
                    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                elseif Menu.State.currentMenu == "ONLINE" then
                    if selectedPlayer then
                        Menu.State.currentMenu = "TROLL"
                        Menu.State.selectedOption, Menu.State.startIndex = 1, 1
                        PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                    else

                        PlaySoundFrontend(-1, "ERROR", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    local keyMap = {
        [0x58] = "X", [0x45] = "E", [0x46] = "F", [0x47] = "G",
        [0x42] = "B", [0x56] = "V", [0x48] = "H", [0x4E] = "N",
        [0x51] = "Q", [0x54] = "T", [0x52] = "R", [0x5A] = "Z",
        [0x43] = "C", [0x4D] = "M"
    }
    
    local keys = {0x58, 0x45, 0x46, 0x47, 0x42, 0x56, 0x48, 0x4E, 0x51, 0x54, 0x52, 0x5A, 0x43, 0x4D}
    
    while true do
        Wait(0)
        
        if IsControlJustPressed(0, 344) or (Susano and Susano.GetAsyncKeyState and Susano.GetAsyncKeyState(0x7A)) then
            if fovHijackActive then
                local currentIndex = 1
                for i, key in ipairs(keys) do
                    if key == fovHijackKey then
                        currentIndex = i
                        break
                    end
                end
                
                local nextIndex = (currentIndex % #keys) + 1
                fovHijackKey = keys[nextIndex]
                fovHijackKeyName = keyMap[fovHijackKey] or "?"
                

                Wait(200)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        local useSusano = (Susano and Susano.BeginFrame and Susano.SubmitFrame)
        if useSusano then 
            Susano.BeginFrame()
            if _G.menuFontId and Susano.PushFont then
                Susano.PushFont(_G.menuFontId)
            end
        end
        
        -- Wrap rendering in pcalls to prevent crashes from killing the entire script
        pcall(Menu.Actions.RenderMenu)
        pcall(DrawDynastyNotify)
        pcall(RenderShootVisionVisuals)
        pcall(RenderBindingUI)
        
        if useSusano then 
            if _G.menuFontId and Susano.PopFont then
                Susano.PopFont()
            end
            Susano.SubmitFrame() 
        end
    end
end)

CreateThread(function() 
    while true do 
        Wait(0)
        if next(attachedPlayers) then
            local me = PlayerPedId() 
            if DoesEntityExist(me) then
                local coords = GetEntityCoords(me) 
                local f = GetEntityForwardVector(me)
                for playerId, ped in pairs(attachedPlayers) do
                    if DoesEntityExist(ped) then
                        local success = pcall(function()
                            SetEntityCoordsNoOffset(ped, coords.x + f.x * AK_DIST, coords.y + f.y * AK_DIST, coords.z, true, true, true)
                            SetEntityHeading(ped, GetEntityHeading(me))
                        end)
                        if not success then
                            attachedPlayers[playerId] = nil
                            originalCoords[playerId] = nil
                        end
                    else
                        attachedPlayers[playerId] = nil
                        originalCoords[playerId] = nil
                    end
                end
            end
        end
    end 
end)

CreateThread(function() 
    while true do 
        Wait(500)
        if next(attachedPlayers) then
            for playerId, ped in pairs(attachedPlayers) do
                if DoesEntityExist(ped) and IsPedInAnyVehicle(ped, false) then
                    DetachEntity(ped, true, true)
                    attachedPlayers[playerId] = nil
                    originalCoords[playerId] = nil
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        for playerId, ped in pairs(attachedPlayers) do
            if not NetworkIsPlayerActive(playerId) or not DoesEntityExist(ped) then
                attachedPlayers[playerId] = nil
                originalCoords[playerId] = nil
            end
        end
        for playerId, coords in pairs(originalCoords) do
            if not attachedPlayers[playerId] then
                originalCoords[playerId] = nil
            end
        end
    end
end)


_G.susanoKeyStates = {}

-- Universal Keybind Listener
CreateThread(function()
    while true do
        Wait(0)
        -- Noclip Keybind (F2) with Susano Fallback
        local noclipJustPressed = (noclipBindKey ~= 0 and (IsDisabledControlJustPressed(0, noclipBindKey) or IsControlJustPressed(0, noclipBindKey)))
        if not noclipJustPressed and Susano and Susano.GetAsyncKeyState and Susano.GetAsyncKeyState(0x71) then
            if not _G.noclipKeyStateSusano then
                noclipJustPressed = true
                _G.noclipKeyStateSusano = true
            end
        elseif Susano and Susano.GetAsyncKeyState and not Susano.GetAsyncKeyState(0x71) then
            _G.noclipKeyStateSusano = false
        end

        if noclipJustPressed then
            if type(ToggleNoclip) == "function" then
                Menu.Actions.ToggleNoclip()
            end
        end
        
        -- Universal Binds Listener
        for key, action in pairs(_G.UniversalKeyBinds) do
            local pressed = false
            if IsDisabledControlJustPressed(0, key) or IsControlJustPressed(0, key) then
                pressed = true
            elseif Susano and Susano.GetAsyncKeyState then
                local isDown = false
                if action.vk and Susano.GetAsyncKeyState(action.vk) then
                    isDown = true
                else
                    -- Fallbacks for common blocked keys (Legacy)
                    if key == 288 and Susano.GetAsyncKeyState(0x70) then isDown = true -- F1
                    elseif key == 289 and Susano.GetAsyncKeyState(0x71) then isDown = true -- F2
                    elseif (key == 170 or key == 290) and Susano.GetAsyncKeyState(0x72) then isDown = true -- F3
                    elseif key == 166 and Susano.GetAsyncKeyState(0x74) then isDown = true -- F5
                    elseif key == 167 and Susano.GetAsyncKeyState(0x75) then isDown = true -- F6
                    elseif key == 168 and Susano.GetAsyncKeyState(0x76) then isDown = true -- F7
                    end
                end
                
                if isDown then
                    if not _G.susanoKeyStates[key] then
                        pressed = true
                        _G.susanoKeyStates[key] = true
                    end
                else
                    if _G.susanoKeyStates[key] then
                        _G.susanoKeyStates[key] = false
                    end
                end
            end
            
            if pressed and key ~= 22 then -- Security: Never trigger binds with Space
                if action.menu and action.index then
                    -- Execute the action logic directly
                    ExecuteMenuAction(action.menu, action.index)
                    
                    -- Small wait to prevent rapid toggle spam
                    Wait(200)
                end
            end
        end
    end
end)

-- Universal Binder (F11)
CreateThread(function()
    local function GetCurrentOptionLabel()
        local menu = Menu.State.currentMenu
        local index = Menu.State.selectedOption
        local label = "Option"
        
        local fullList = nil
        if menu == "MAIN" then fullList = Menu.Data.Options.Main
        elseif menu == "PLAYER" then fullList = Menu.Helpers.GetPlayerOptions()
        elseif menu == "COMBAT" then fullList = Menu.Data.Options.Combat
        elseif menu == "VEHICLE" then fullList = Menu.Data.Options.Vehicle
        elseif menu == "MISC" then fullList = Menu.Helpers.GetMiscOptions()
        elseif menu == "WARDROBE" then fullList = Menu.Helpers.GetWardrobeOptions()
        elseif menu == "SETTINGS" then fullList = Menu.Helpers.GetSettingsOptions()
        elseif menu == "TROLL" then fullList = Menu.Data.Options.Troll
        end
        
        if fullList and fullList[index] then
            local data = fullList[index]
            label = (type(data) == "table" and data.name or data)
            label = label:gsub("~[a-z]~", ""):gsub("%[ON%]", ""):gsub("%[OFF%]", "")
        end
        return label
    end

    while true do
        Wait(0)
        
        -- F11 trigger
        if IsDisabledControlJustPressed(0, 344) or (Susano and Susano.GetAsyncKeyState and Susano.GetAsyncKeyState(0x7A)) then
            isBindingNoclip = true
            
            if Menu.State.menuOpen then
                bindingActionData = { menu = Menu.State.currentMenu, index = Menu.State.selectedOption, label = GetCurrentOptionLabel() }
            else
                bindingActionData = { menu = "PLAYER", index = 4, label = "Noclip" }
            end
            
            bindingText = "Appuyez sur une touche à assigner"
            bindingKeyDisplay = ""
            
            Wait(300)
            
            local currentSelection = 0
            local currentVK = nil
            local active = true
            while active do
                Wait(0)
                
                -- Gèle le jeu en arrière-plan comme le startup binder
                HideHelpTextThisFrame()
                DisableAllControlActions(0)
                
                -- Capture key (Utilise blockedControls partagé)
                for i = 1, 350 do
                    if not blockedControls[i] and i ~= 344 then
                        if IsDisabledControlJustPressed(0, i) then
                            local name = _G.ControlNamesMap[i]
                            if name and #name > 0 and name ~= "F11" then 
                                currentSelection = i
                                bindingKeyDisplay = name
                                bindingText = "Touche sélectionnée"
                                
                                -- Capture VK associé via Susano
                                if Susano and Susano.GetAsyncKeyState then
                                    for vk = 0x01, 0xFE do
                                        if Susano.GetAsyncKeyState(vk) and vk ~= 0x0D and vk ~= 0x1B then
                                            currentVK = vk
                                            break
                                        end
                                    end
                                end
                                break
                            end
                        end
                    end
                end
                
                -- ENTER / F11: Save (Purely isolated from GTA's multi-bound controls like Space)
                local pressEnterSusano = (Susano and Susano.GetAsyncKeyState and Susano.GetAsyncKeyState(0x0D))
                local pressF11 = IsDisabledControlJustPressed(0, 344) or (Susano and Susano.GetAsyncKeyState and Susano.GetAsyncKeyState(0x7A))
                
                if pressEnterSusano or pressF11 then
                    if currentSelection ~= 0 then
                        if bindingActionData.menu == "PLAYER" and bindingActionData.index == 4 then
                            noclipBindKey = currentSelection
                        end
                        _G.UniversalKeyBinds[currentSelection] = { 
                            menu = bindingActionData.menu, 
                            index = bindingActionData.index,
                            label = bindingActionData.label,
                            vk = currentVK
                        }

                    end
                    active = false
                end
                
                -- Backspace: Unbind/Clear
                if IsDisabledControlJustPressed(0, 194) or IsControlJustPressed(0, 194) or IsDisabledControlJustPressed(0, 177) or IsControlJustPressed(0, 177) then
                    -- Search and remove any bind for this action?
                    -- Or just unbind ONLY the key we are currently assigning?
                    -- Actually, unbinding the key we are pressing is more intuitive.
                    -- But if we press Backspace, we want to clear the bind for the current action.
                    for k, v in pairs(_G.UniversalKeyBinds) do
                        if v.menu == bindingActionData.menu and v.index == bindingActionData.index then
                            _G.UniversalKeyBinds[k] = nil
                        end
                    end
                    if bindingActionData.menu == "PLAYER" and bindingActionData.index == 4 then
                        noclipBindKey = 0
                    end

                    active = false
                end

                -- ESC: Cancel
                if IsDisabledControlJustPressed(0, 200) or IsControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 202) or IsControlJustPressed(0, 202) then
                    active = false
                end
            end
            isBindingNoclip = false
            bindingActionData = nil
        end
    end
end)

-- Helper: Get current shooting source (Camera)
function Menu.Helpers.GetShootSource()
    local camPos = _G.Menu.State.Freecam.pos
    local camRot = _G.Menu.State.Freecam.rot
    if _G.Menu.State.Freecam.active and camPos and camRot then
        return camPos, camRot
    end
    
    local coord = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(0)
    return coord or vector3(0,0,0), rot or vector3(0,0,0)
end

-- Helper: Get Magic Bullet Target
local lastTargetScan = 0
local cachedBestTarget = nil

function Menu.Helpers.GetMagicBulletTarget()
    local currentTime = GetGameTimer()
    -- Increase scan interval to 500ms for performance
    if currentTime - lastTargetScan < 500 then
        return cachedBestTarget
    end
    lastTargetScan = currentTime

    local playerPed = PlayerPedId()
    local camCoords, camRot = GetShootSource()
    if not camCoords or not camRot then return nil end
    
    local sw, sh = GetActiveScreenResolution()
    local centerX, centerY = sw / 2, sh / 2

    local bestTarget = nil
    local shortestDist = 999999.0

    local function EvaluateTarget(ped)
        if not ped or ped == playerPed or not DoesEntityExist(ped) or IsPedDeadOrDying(ped, true) then return end
        
        local pedCoords = GetEntityCoords(ped)
        if not pedCoords then return end
        local distToPlayer = #(pedCoords - camCoords)
        
        -- High range scan limit for Shoot Vision
        if distToPlayer < 1500.0 then
            local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(pedCoords.x, pedCoords.y, pedCoords.z)
            if onScreen then
                local pxX, pxY = screenX * sw, screenY * sh
                local distToCenter = #((vector2(pxX, pxY) - vector2(centerX, centerY)))
                
                if distToCenter < Menu.State.shootVisionRadiusPx then
                    local multiplier = 1.0
                    if IsPedAPlayer(ped) then multiplier = 0.5 end
                    
                    local score = distToCenter * multiplier
                    if score < shortestDist then
                        shortestDist = score
                        bestTarget = ped
                    end
                end
            end
        end
    end

    -- Wrap peds/vehicles scan in pcall to protect against pool errors
    pcall(function()
        local peds = GetGamePool('CPed')
        if peds then
            for i = 1, #peds do EvaluateTarget(peds[i]) end
        end

        local vehicles = GetGamePool('CVehicle')
        if vehicles then
            for i = 1, #vehicles do
                local veh = vehicles[i]
                if DoesEntityExist(veh) then
                    local vCoords = GetEntityCoords(veh)
                    if vCoords and #(vCoords - camCoords) < 1500.0 then
                        for seat = -1, 6 do
                            local occupant = GetPedInVehicleSeat(veh, seat)
                            if occupant ~= 0 and occupant ~= playerPed then
                                EvaluateTarget(occupant)
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Target Stickiness (Keep previous target for 500ms even if out of FOV slightly)
    if not bestTarget and cachedBestTarget and DoesEntityExist(cachedBestTarget) and not IsPedDeadOrDying(cachedBestTarget, true) then
        if currentTime - lastTargetScan < 500 then
            bestTarget = cachedBestTarget
        end
    end

    cachedBestTarget = bestTarget
    return bestTarget
end

-- Shoot Vision Render Logic
function RenderShootVisionVisuals()
    if not Menu.State.shootVisionActive then return end
    
    local sw, sh = GetActiveScreenResolution()
    local centerX, centerY = sw / 2, sh / 2
    local fovRadiusPx = Menu.State.shootVisionRadiusPx
    
    -- Draw FOV Circle (Outline White)
    if Susano and Susano.DrawCircle then
        local tr = (Menu.Colors.SelectedBg.r / 255)
        local tg = (Menu.Colors.SelectedBg.g / 255)
        local tb = (Menu.Colors.SelectedBg.b / 255)
        local ta = (Menu.Colors.SelectedBg.a or 0.8)

        Susano.DrawCircle(centerX, centerY, fovRadiusPx, false, 1.0, 1.0, 1.0, 0.2, 1.0, 32)
        -- Added: Central Crosshair Dot (Themed)
        Susano.DrawRectFilled(centerX - 1, centerY - 1, 2, 2, tr, tg, tb, ta, 2)
    end
    
    -- Find and Highlight Target
    shootVisionTarget = GetMagicBulletTarget()
    if shootVisionTarget and DoesEntityExist(shootVisionTarget) then
        local targetBone = 24818 -- SKEL_Spine3 (Body)
        local vehicle = GetVehiclePedIsIn(shootVisionTarget, false)
        if vehicle ~= 0 then
            local class = GetVehicleClass(vehicle)
            if class == 8 or class == 13 then targetBone = 12844 end -- Head for Motorcycles/Cycles
        end
        
        local boneIndex = GetPedBoneIndex(shootVisionTarget, targetBone)
        local targetPos = GetWorldPositionOfEntityBone(shootVisionTarget, boneIndex)
        local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(targetPos.x, targetPos.y, targetPos.z)
        
        if onScreen then
            local pxX, pxY = screenX * sw, screenY * sh
            if Susano and Susano.DrawRectFilled then
                local tr = (Menu.Colors.SelectedBg.r / 255)
                local tg = (Menu.Colors.SelectedBg.g / 255)
                local tb = (Menu.Colors.SelectedBg.b / 255)
                local ta = (Menu.Colors.SelectedBg.a or 0.8)
                -- Themed box on dynamic target (Body or Head)
                Susano.DrawRectFilled(pxX - 5, pxY - 5, 10, 10, tr, tg, tb, ta, 2)
            end
        end
    end
end

-- Shoot Vision Weapon Memory Tracker (Updates last fired weapon)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        if IsPedShooting(ped) then
            local currentWeapon = GetSelectedPedWeapon(ped)
            if currentWeapon ~= GetHashKey("WEAPON_UNARMED") then
                -- Verify if weapon is in allowed list
                local allowed = false
                if _G.ShootVisionConfig and _G.ShootVisionConfig.Hashes then
                    for _, hash in ipairs(_G.ShootVisionConfig.Hashes) do
                        if currentWeapon == hash then
                            allowed = true
                            break
                        end
                    end
                end
                
                if allowed then
                    Menu.State.shootVisionLastWeapon = currentWeapon
                end
            end
        end
    end
end)

-- Shoot Vision Thread using _G.ShootVisionConfig.Hashes and GetWeaponFromInventory
CreateThread(function()

    local function RotationToDirection(rotation)
        if not rotation then return vector3(0,0,1) end
        local x = math.rad(rotation.x or 0)
        local z = math.rad(rotation.z or 0)
        local num = math.abs(math.cos(x))
        return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
    end

    function GetWeaponFromInventory(ped)
        -- 1. Priorité aux mains (Si tu as une arme autorisée sortie)
        local currentWeapon = GetSelectedPedWeapon(ped)
        local hashes = _G.ShootVisionConfig and _G.ShootVisionConfig.Hashes or {}
        
        local function isAllowed(hash)
            for _, h in ipairs(hashes) do
                if hash == h then return true end
            end
            return false
        end

        if currentWeapon ~= GetHashKey("WEAPON_UNARMED") and isAllowed(currentWeapon) then
            Menu.State.shootVisionLastWeapon = currentWeapon -- Mise à jour mémoire
            return currentWeapon 
        end

        -- 2. Priorité à la "Mémoire" (Dernière arme avec laquelle tu as tiré)
        if Menu.State.shootVisionLastWeapon and HasPedGotWeapon(ped, Menu.State.shootVisionLastWeapon, false) then
            return Menu.State.shootVisionLastWeapon
        end

        -- 3. Fallback : Chercher n'importe quelle arme autorisée dans ton inventaire
        for _, hash in ipairs(hashes) do
            if HasPedGotWeapon(ped, hash, false) then
                return hash
            end
        end
        
        return nil 
    end

    local function getBestTargetInCrosshair(camCoords, direction)
        local bestPed = nil
        local bestScore = 999.0
        local myPed = PlayerPedId()
        local sw, sh = GetActiveScreenResolution()
        local centerX, centerY = sw / 2, sh / 2
        
        for _, ped in ipairs(GetGamePool("CPed")) do
            if ped ~= myPed and DoesEntityExist(ped) and not IsEntityDead(ped) then
                local pedCoords = GetEntityCoords(ped)
                local dist = #(pedCoords - camCoords)
                
                if dist < 1000.0 then
                    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(pedCoords.x, pedCoords.y, pedCoords.z)
                    if onScreen then
                        local pxX, pxY = screenX * sw, screenY * sh
                        local distToCenter = #((vector2(pxX, pxY) - vector2(centerX, centerY)))
                        
                        if distToCenter < Menu.State.shootVisionRadiusPx then
                            local score = distToCenter
                            if score < bestScore then
                                bestScore = score
                                bestPed = ped
                            end
                        end
                    end
                end
            end
        end
        return bestPed
    end

    local MAGIC_BONES = { 31086, 24818, 57005 }

    while true do
        Wait(0)

        if Menu.State.shootVisionActive then
            if IsDisabledControlPressed(0, 38) or IsControlPressed(0, 38) then

                local playerPed = PlayerPedId()
                local weaponHash = GetWeaponFromInventory(playerPed)

                if weaponHash then
                    local camCoords = GetGameplayCamCoord()
                    local direction = RotationToDirection(GetGameplayCamRot(2))
                    local spawnPoint = camCoords + (direction * 1.0)
                    
                    local targetPed = getBestTargetInCrosshair(camCoords, direction)

                    if targetPed then
                        -- Target Bone Lock: SPINE3 (24818) or PELVIS (11816) for Body Lock
                        local targetBone = 24818 
                        local boneIndex = GetPedBoneIndex(targetPed, targetBone)

                        if boneIndex ~= -1 then
                            local targetCoords = GetWorldPositionOfEntityBone(targetPed, boneIndex)

                            if targetCoords then
                                -- Sky-Shot Wallbreak: Spawn 20m above for vertical trajectory
                                local mSpawnPoint = targetCoords + vector3(0.0, 0.0, 20.0)

                                pcall(function()
                                    ShootSingleBulletBetweenCoords(
                                        mSpawnPoint.x, mSpawnPoint.y, mSpawnPoint.z,
                                        targetCoords.x, targetCoords.y, targetCoords.z,
                                        50,     -- Dégâts fixes
                                        true,   -- Pressure
                                        weaponHash,
                                        playerPed,
                                        true,   -- Audible
                                        false,  -- Invisible
                                        1000.0  -- Vitesse
                                    )
                                end)
                            end
                        end
                    else
                        -- Tir sur le décor
                        local endCoords = camCoords + (direction * 1000.0)
                        if spawnPoint and endCoords then
                            pcall(function()
                                ShootSingleBulletBetweenCoords(
                                    spawnPoint.x, spawnPoint.y, spawnPoint.z,
                                    endCoords.x, endCoords.y, endCoords.z,
                                    50, true, weaponHash, playerPed, true, false, 1000.0
                                )
                            end)
                        end
                    end
                end

                -- Petit délai pour pas que le serveur sature
                Wait(150) 
            end
        end
    end
end)

-- Startup Keybinder Logic FIXÉ (Anti-Entrée Fantôme)
CreateThread(function()
    while isFirstLoadBinding do
        Wait(0)
        
        HideHelpTextThisFrame()
        DisableAllControlActions(0)
        
        -- 1. Scan propre et sécurisé (Utilise blockedControls partagé tout en haut)
        for i = 1, 350 do
            if not blockedControls[i] then
                if IsDisabledControlJustPressed(0, i) then
                    local name = _G.ControlNamesMap[i]
                    if name and #name > 0 then
                        startupBindingControl = i
                        startupBindingName = name
                        
                        -- On essaye aussi de capturer le VK correspondant si Susano est là
                        if Susano and Susano.GetAsyncKeyState then
                            for vk = 0x01, 0xFE do
                                if Susano.GetAsyncKeyState(vk) and vk ~= 0x0D and vk ~= 0x1B then
                                    startupBindingVK = vk
                                    break
                                end
                            end
                        end
                        
                        break
                    end
                end
            end
        end

        -- 2. Validation UNIQUEMENT avec Entrée
        local enterPressed = IsDisabledControlJustPressed(0, 191) or IsDisabledControlJustPressed(0, 201)
        
        if Susano and Susano.GetAsyncKeyState then
            if Susano.GetAsyncKeyState(0x0D) then enterPressed = true end
        end

        -- 3. Confirmer et fermer le binder
        if enterPressed then
            if startupBindingControl ~= 0 then
                Menu.Keys.OPEN = startupBindingControl
                Menu.Keys.VK_OPEN = startupBindingVK or 0x7B -- F12 fallback
                isFirstLoadBinding = false
                ShowDynastyNotification("~g~Menu configuré ! Touche : ~w~" .. startupBindingName)
                PlaySoundFrontend(-1, "LEADERBOARD_EXIT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                Wait(500)
            end
        end
    end
end)

-- Startup Enablement (Auto-activate features on load)
CreateThread(function()
    Wait(500) -- Initial wait
    
    -- Load default banner (Sabry)
    if type(Menu.LoadBannerTexture) == "function" then
        Menu.LoadBannerTexture("https://i.imgur.com/jtzj4am.jpeg")
    end

    Wait(500) 
    if type(Menu.Actions.ToggleAntiTeleport) == "function" then
        Menu.Actions.ToggleAntiTeleport(true)
    end
end)


