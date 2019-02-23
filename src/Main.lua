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

local GPS = LibStub("LibGPS2")
local PATH = "Lib3D/example"
Example = {}

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

    local unit = ZO_Group_GetUnitTagForGroupIndex(1)
    d(GetUnitName(unit))
    --d(GetUnitWorldPosition(unit))
    d(GetMapPlayerPosition(unit))

    --local MageLight_TopLevel = WM:CreateTopLevelWindow("MageLight_TopLevel")
    local MageLight_TopLevel = WM:CreateControl("MageLight_TopLevel", GuiRoot, CT_TOPLEVELCONTROL)
    MageLight_TopLevel:Create3DRenderSpace()

    local fragment = ZO_SimpleSceneFragment:New(MageLight_TopLevel)
    HUD_UI_SCENE:AddFragment(fragment)
    HUD_SCENE:AddFragment(fragment)
    LOOT_SCENE:AddFragment(fragment)

    -- register a callback, so we know when to start/stop displaying the mage light
    Lib3D:RegisterWorldChangeCallback("MageLight", function(identifier, zoneIndex, isValidZone, newZone)
        if not newZone then return end
        
        if isValidZone then
            Example.ShowMageLight()
        else
            Example.HideMageLight()
        end
    end)
    
    -- create the mage light
    -- we have one parent control (light) which we will move around the player
    -- and two child controls for the light's center and a periodically pulsing sphere
    light = WM:CreateControl(nil, MageLight_TopLevel, CT_CONTROL)
    center = WM:CreateControl(nil, light, CT_TEXTURE)
    
    -- make the control 3 dimensional
    light:Create3DRenderSpace()
    center:Create3DRenderSpace()
    
    -- set texture, size and enable the depth buffer so the mage light is hidden behind world objects
    -- esoui/art/lfg/gamepad/lfg_roleicon_tank.dds
    -- esoui/art/lfg/gamepad/lfg_roleicon_healer.dds
    center:SetTexture("/esoui/art/lfg/gamepad/lfg_roleicon_dps.dds")
    center:SetColor(0.23, 0.59, 0.81, 1.0)
    center:Set3DLocalDimensions(0.5, 0.5)
    center:Set3DRenderSpaceUsesDepthBuffer(true)
    center:Set3DRenderSpaceOrigin(0,0,0.1)

    --MageLight_TopLevel:Set3DRenderSpaceOrigin(worldX, worldY, worldZ)
end

function Example.ShowMageLight()
    light:SetHidden(false)
    center:SetHidden(false)
    
    EM:UnregisterForUpdate("MageLight")
    -- perform the following every single frame
    EM:RegisterForUpdate("MageLight", 0, function(time)
        
        local x, y, z, forwardX, forwardY, forwardZ, rightX, rightY, rightZ, upX, upY, upZ = Lib3D:GetCameraRenderSpace()
        
        -- align our mage light with the camera's render space so the light is always facing the camera
        light:Set3DRenderSpaceForward(forwardX, forwardY, forwardZ)
        light:Set3DRenderSpaceRight(rightX, rightY, rightZ)
        light:Set3DRenderSpaceUp(upX, upY, upZ)
        
        -- get the player position, so we can place the mage light nearby
        local worldX, worldY, worldZ = Lib3D:ComputePlayerRenderSpacePosition()
        if not worldX then return end
        -- this creates the circeling motion around the player
        local time = GetFrameTimeSeconds()
        --worldX = worldX + math.sin(time)
        --worldZ = worldZ + math.cos(time)
        --worldY = worldY - 0.75 + 0.5 * math.sin(0.5 * time)
        worldX = worldX
        worldZ = worldZ
        worldY = worldY + 0.5

        -- Group member?
        local unit = ZO_Group_GetUnitTagForGroupIndex(1)
        local playerPos = GetMapPlayerPosition(unit)
        local globalX, globalY = GPS:LocalToGlobal(GetMapPlayerPosition(unit))
        local worldX, worldZ = Lib3D:GlobalToWorld(globalX, globalY)
        worldX, _, worldZ = WorldPositionToGuiRender3DPosition(worldX * 100, 0, worldZ * 100)
        --
        worldY = worldY + 0.5

        MageLight_TopLevel:Set3DRenderSpaceOrigin(worldX, worldY, worldZ)
        
        -- add a pulsing animation
        --center:SetAlpha(math.sin(2 * time) * 0.25 + 0.75)
        
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
