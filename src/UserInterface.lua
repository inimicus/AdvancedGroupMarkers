-- -----------------------------------------------------------------------------
-- Advanced Group Markets
-- Author:  g4rr3t
-- Created: February 22, 2019
--
-- UserInterface.lua
-- -----------------------------------------------------------------------------

AvGM.UI = {}

--EVENT_GROUP_MEMBER_ROLE_CHANGED (*string* _unitTag_, *[LFGRole|#LFGRole]* _newRole_)
--EVENT_GROUP_UPDATE
--GetGroupSize()
--IsUnitGrouped(*string* _unitTag_)
--GetGroupUnitTagByIndex(*luaindex* _sortIndex_)
--GetGroupIndexByUnitTag(*string* _unitTag_)
--IsGroupMemberInRemoteRegion(*string* _unitTag_)
--GetGroupMemberSelectedRole(*string* _unitTag_)
--ZO_Group_GetUnitTagForGroupIndex
--
--IsGroupMemberInSameInstanceAsPlayer(GetGroupUnitTagByIndex(1))

--Set3DRenderSpaceOrigin(*number* _xM_, *number* _yM_, *number* _zM_)
--* GetMapPlayerPosition(*string* _unitTag_)
--** _Returns:_ *number* _normalizedX_, *number* _normalizedZ_, *number* _heading_, *bool* _isShownInCurrentMap_
--* GetUnitWorldPosition(*string* _unitTag_)
--** _Returns:_ *integer* _zoneId_, *integer* _worldX_, *integer* _worldY_, *integer* _worldZ_

local EM = EVENT_MANAGER
local WM = WINDOW_MANAGER

local light, center, groupMarkersTop
local measurementControl = CreateControl(AvGM.name .. "MeasurementControl", GuiRoot, CT_CONTROL)
measurementControl:Create3DRenderSpace()

local groupMarkersControl
local groupMembers = {}

function AvGM.UI:Setup()

    groupMarkersControl = WM:CreateControl("groupMakersControl", GuiRoot, CT_TOPLEVELCONTROL)
    groupMarkersControl:Create3DRenderSpace()

    local fragment = ZO_SimpleSceneFragment:New(groupMarkersControl)
    HUD_UI_SCENE:AddFragment(fragment)
    HUD_SCENE:AddFragment(fragment)
    LOOT_SCENE:AddFragment(fragment)

    AvGM.GroupUpdate()

    EM:RegisterForEvent(AvGM.name .. "GroupChanged", EVENT_GROUP_UPDATE, AvGM.GroupUpdate)
    EM:RegisterForEvent(AvGM.name .. "GroupRoleChanged", EVENT_GROUP_MEMBER_ROLE_CHANGED, AvGM.GroupUpdate)
end

-- TODO: Avoid rebuilding groupMembers table
-- Use unitTag or name or something else instead
function AvGM.GroupUpdate()

    -- Delete any existing groupMembers items
    for i=0, #groupMembers do
        --groupMembers[i].outer:SetHidden(true)
        --groupMembers[i].inner:SetHidden(true)
        groupMembers[i] = nil
    end

    if IsUnitGrouped("player") or AvGM.debugMode > 0 then
        AvGM:Trace(1, "Grouped (or debugging)")

        -- Populate group members, create controls
        for i = 1, GetGroupSize() do

            groupMembers[i] = {}
            groupMembers[i].id = "groupMarker" .. i

            local outer = WM:GetControlByName(groupMembers[i].id .. "_outer")
            local inner = WM:GetControlByName(groupMembers[i].id .. "_inner")

            if outer == nil then
                groupMembers[i].outer = WM:CreateControl(groupMembers[i].id .. "_outer", groupMarkersControl, CT_CONTROL)
                groupMembers[i].outer:Set3DRenderSpaceSystem(GUI_RENDER_3D_SPACE_SYSTEM_CAMERA)
                groupMembers[i].outer:Create3DRenderSpace()
            else
                groupMembers[i].outer = outer
            end

            if inner == nil then
                groupMembers[i].inner = WM:CreateControl(groupMembers[i].id .. "_inner", groupMembers[i].outer, CT_TEXTURE)
                groupMembers[i].inner:Create3DRenderSpace()
                -- esoui/art/lfg/gamepad/lfg_roleicon_tank.dds
                -- esoui/art/lfg/gamepad/lfg_roleicon_healer.dds
                groupMembers[i].inner:SetTexture("/esoui/art/lfg/gamepad/lfg_roleicon_dps.dds")
                --groupMembers[i].inner:SetColor(0.23, 0.59, 0.81, 1.0)
                groupMembers[i].inner:SetColor(0.95, 0.59, 0.51, 1.0)
                groupMembers[i].inner:Set3DLocalDimensions(5, 5)
                groupMembers[i].inner:Set3DRenderSpaceUsesDepthBuffer(false)
                groupMembers[i].inner:Set3DRenderSpaceOrigin(0,0,0)
            else
                groupMembers[i].inner = inner
            end

        end

        AvGM.UI.ShowGroupMarkers()
    else
        AvGM:Trace(1, "No longer grouped")
        AvGM.UI.HideGroupMarkers()
    end
end

local function DrawLoop(time)

    for i = 1, #groupMembers do

        Set3DRenderSpaceToCurrentCamera(measurementControl:GetName())
        local x, y, z = measurementControl:Get3DRenderSpaceOrigin()
        local forwardX, forwardY, forwardZ = measurementControl:Get3DRenderSpaceForward()
        local rightX, rightY, rightZ = measurementControl:Get3DRenderSpaceRight()
        local upX, upY, upZ = measurementControl:Get3DRenderSpaceUp()

        -- Update rotation
        groupMembers[i].outer:Set3DRenderSpaceForward(forwardX, forwardY, forwardZ)
        groupMembers[i].outer:Set3DRenderSpaceRight(rightX, rightY, rightZ)
        groupMembers[i].outer:Set3DRenderSpaceUp(upX, upY, upZ)

        local unit = GetGroupUnitTagByIndex(i)
        local zoneId, worldX, worldY, worldZ = GetUnitWorldPosition(unit)
        worldX, worldY, worldZ = WorldPositionToGuiRender3DPosition(worldX, worldY, worldZ)
        worldY = worldY + 2.75

        groupMembers[i].outer:Set3DRenderSpaceOrigin(worldX, worldY, worldZ)
    end
end

function AvGM.UI.ShowGroupMarkers()
    AvGM:Trace(1, "Showing Group Markers")
    for i = 1, #groupMembers do
        groupMembers[i].outer:SetHidden(false)
        groupMembers[i].inner:SetHidden(false)
    end

    EM:UnregisterForUpdate(AvGM.name .. "DrawLoop")
    EM:RegisterForUpdate(AvGM.name .. "DrawLoop", 5000, function(...) DrawLoop(...) return end)
end

function AvGM.UI.HideGroupMarkers()
    AvGM:Trace(1, "Hiding Group Markers")
    EM:UnregisterForUpdate(AvGM.name .. "DrawLoop")

    for i = 1, #groupMembers do
        groupMembers[i].outer:SetHidden(true)
        groupMembers[i].inner:SetHidden(true)
    end
end

function AvGM.UI.SlashCommand(command)
    -- Debug Options ----------------------------------------------------------
    if command == "pos" then
        local zoneId, worldX, worldY, worldZ = GetUnitWorldPosition("player")
        AvGM:Trace(1, "World - Zone: <<1>> WorldX: <<2>> WorldY: <<3>> WorldZ: <<4>>", zoneId, worldX, worldY, worldZ)
        worldX, worldY, worldZ = WorldPositionToGuiRender3DPosition(worldX, worldY, worldZ)
        AvGM:Trace(1, "GUI - X: <<1>> Y: <<2>> Z: <<3>>", worldX, worldY, worldZ)
    else
        d(Cool.prefix .. "Command not recognized!")
    end
end
--* GetUnitWorldPosition(*string* _unitTag_)
