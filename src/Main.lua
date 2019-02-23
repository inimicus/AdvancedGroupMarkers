-- -----------------------------------------------------------------------------
-- Advanced Group Markets
-- Author:  g4rr3t
-- Created: February 22, 2019
--
-- Fancy group markers via 3D API
--
-- Main.lua
-- -----------------------------------------------------------------------------

AvGM            = {}
AvGM.name       = "AdvancedGroupMarkers"
AvGM.version    = "0.0.1"
AvGM.dbVersion  = 1
AvGM.slash      = "/avgm"
AvGM.prefix     = "[AvGM] "

local EM = EVENT_MANAGER

-- -----------------------------------------------------------------------------
-- Level of debug output
-- 1: Low    - Basic debug info, show core functionality
-- 2: Medium - More information about skills and addon details
-- 3: High   - Everything
AvGM.debugMode = 1
-- -----------------------------------------------------------------------------

function AvGM:Trace(debugLevel, ...)
    if debugLevel <= AvGM.debugMode then
        local message = zo_strformat(...)
        d(AvGM.prefix .. message)
    end
end

-- -----------------------------------------------------------------------------
-- Startup
-- -----------------------------------------------------------------------------

function AvGM.Initialize(event, addonName)
    if addonName ~= AvGM.name then return end
    AvGM:Trace(1, "Advanced Group Markers Loaded")
    EM:UnregisterForEvent(AvGM.name, EVENT_ADD_ON_LOADED)

    AvGM.preferences = ZO_SavedVars:NewAccountWide("AdvancedGroupMarkersVariables", AvGM.dbVersion, nil, {})

    -- Use saved debugMode value
    --AvGM.debugMode = AvGM.preferences.debugMode

    SLASH_COMMANDS[AvGM.slash] = AvGM.UI.SlashCommand

    AvGM.UI:Setup()
    AvGM:Trace(2, "Finished Initialize()")
end

-- -----------------------------------------------------------------------------
-- Event Hooks
-- -----------------------------------------------------------------------------

EM:RegisterForEvent(AvGM.name, EVENT_ADD_ON_LOADED, AvGM.Initialize)
