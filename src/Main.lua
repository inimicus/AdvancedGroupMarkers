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
local WM = WINDOW_MANAGER

Example = {}

local measurementControl = CreateControl(AvGM.name .. "MeasurementControl", GuiRoot, CT_CONTROL)
measurementControl:Create3DRenderSpace()

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

local light, center

function AvGM.Initialize(event, addonName)
    if addonName ~= AvGM.name then return end

    AvGM:Trace(1, "Advanced Group Markers Loaded")
    EM:UnregisterForEvent(AvGM.name, EVENT_ADD_ON_LOADED)

    AvGM.preferences = ZO_SavedVars:NewAccountWide("AdvancedGroupMarkersVariables", AvGM.dbVersion, nil, {})

    -- Use saved debugMode value
    --AvGM.debugMode = AvGM.preferences.debugMode

    --SLASH_COMMANDS[AvGM.slash] = AvGM.UI.SlashCommand

    AvGM:Trace(2, "Finished Initialize()")

    --local MageLight_TopLevel = WM:CreateTopLevelWindow("MageLight_TopLevel")
    local MageLight_TopLevel = WM:CreateControl("MageLight_TopLevel", GuiRoot, CT_TOPLEVELCONTROL)
    MageLight_TopLevel:Create3DRenderSpace()

    local fragment = ZO_SimpleSceneFragment:New(MageLight_TopLevel)
    HUD_UI_SCENE:AddFragment(fragment)
    HUD_SCENE:AddFragment(fragment)
    LOOT_SCENE:AddFragment(fragment)

    light = WM:CreateControl(nil, MageLight_TopLevel, CT_CONTROL)
    center = WM:CreateControl(nil, light, CT_TEXTURE)
    
    light:Create3DRenderSpace()
    center:Create3DRenderSpace()
    
    -- esoui/art/lfg/gamepad/lfg_roleicon_tank.dds
    -- esoui/art/lfg/gamepad/lfg_roleicon_healer.dds
    center:SetTexture("/esoui/art/lfg/gamepad/lfg_roleicon_dps.dds")
    center:SetColor(0.23, 0.59, 0.81, 1.0)
    center:Set3DLocalDimensions(0.5, 0.5)
    center:Set3DRenderSpaceUsesDepthBuffer(true)
    center:Set3DRenderSpaceOrigin(0,0,0.1)

    Example.ShowMageLight()
end

function Example.ShowMageLight()
    light:SetHidden(false)
    center:SetHidden(false)
    
    EM:UnregisterForUpdate("MageLight")

    EM:RegisterForUpdate("MageLight", 0, function(time)
        
        Set3DRenderSpaceToCurrentCamera(measurementControl:GetName())
        local x, y, z = measurementControl:Get3DRenderSpaceOrigin()
        local forwardX, forwardY, forwardZ = measurementControl:Get3DRenderSpaceForward()
        local rightX, rightY, rightZ = measurementControl:Get3DRenderSpaceRight()
        local upX, upY, upZ = measurementControl:Get3DRenderSpaceUp()
        
        -- align our mage light with the camera's render space so the light is always facing the camera
        light:Set3DRenderSpaceForward(forwardX, forwardY, forwardZ)
        light:Set3DRenderSpaceRight(rightX, rightY, rightZ)
        light:Set3DRenderSpaceUp(upX, upY, upZ)

        local unit = ZO_Group_GetUnitTagForGroupIndex(1)
        local zoneId, worldX, worldY, worldZ = GetUnitWorldPosition("player")
        worldX, worldY, worldZ = WorldPositionToGuiRender3DPosition(worldX, worldY, worldZ)
        worldY = worldY + 2.75

        MageLight_TopLevel:Set3DRenderSpaceOrigin(worldX, worldY, worldZ)
        
    end)
end

function Example.HideMageLight()
    -- remove the on update handler and hide the mage light
    EM:UnregisterForUpdate("MageLight")
    light:SetHidden(true)
    center:SetHidden(true)
end
-- -----------------------------------------------------------------------------
-- Event Hooks
-- -----------------------------------------------------------------------------

EM:RegisterForEvent(AvGM.name, EVENT_ADD_ON_LOADED, AvGM.Initialize)

--EVENT_GROUP_MEMBER_ROLE_CHANGED (*string* _unitTag_, *[LFGRole|#LFGRole]* _newRole_)
--GetGroupSize()
--IsUnitGrouped(*string* _unitTag_)
--GetGroupUnitTagByIndex(*luaindex* _sortIndex_)
--GetGroupIndexByUnitTag(*string* _unitTag_)
--IsGroupMemberInRemoteRegion(*string* _unitTag_)
--GetGroupMemberSelectedRole(*string* _unitTag_)
--GetUnitWorldPosition(*string* _unitTag_)
--ZO_Group_GetUnitTagForGroupIndex

--Set3DRenderSpaceOrigin(*number* _xM_, *number* _yM_, *number* _zM_)
--* GetMapPlayerPosition(*string* _unitTag_)
--** _Returns:_ *number* _normalizedX_, *number* _normalizedZ_, *number* _heading_, *bool* _isShownInCurrentMap_
