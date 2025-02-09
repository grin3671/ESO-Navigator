---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by david.
--- DateTime: 08/02/2025 15:35
---

local Nav = Navigator

--- @class Node
local Node = {}

function Node:New(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Node:IsPlayer() return false end

function Node:AddBookmarkMenuItem(entry)
    if entry and not Nav.Bookmarks:contains(entry) then
        AddMenuItem(GetString(NAVIGATOR_MENU_ADDBOOKMARK), function()
            Nav.Bookmarks:add(entry)
            MT.menuOpen = false
            zo_callLater(function() MT:ImmediateRefresh() end, 10)
        end)
    end
end

function Node:GetIcon()
    return self.icon
end

function Node:GetColorDef()
    if self.isSelected and self.known and not self.disabled then
        return ZO_SELECTED_TEXT
    elseif self.colour ~= nil and not self.disabled then
        return ZO_ColorDef:New(self.colour:UnpackRGBA())
    elseif self.known and not self.disabled then
        return ZO_NORMAL_TEXT
    else
        return ZO_DISABLED_TEXT -- rowControl.label:SetColor(0.51, 0.51, 0.44, 1.0)
    end
end

function Node:GetIconColorDef()
    if self.iconColour then
        return ZO_ColorDef:New(self.iconColour:UnpackRGBA())
    elseif self.known and not self.disabled then
        return ZO_WHITE
    else
        return ZO_DISABLED_TEXT
    end
end

function Node:GetSuffixColorDef()
    return ZO_ColorDef:New((self.known and not self.disabled) and "82826F" or "444444")
end

function Node:ZoomToPOI(setWaypoint)
    local function getPOIMapInfo(zoneIndex, mapId, poiIndex)
        if mapId == 2082 then
            return 0.3485, 0.3805 -- GetPOIMapInfo returns 0,0 for The Shambles
        else
            return GetPOIMapInfo(zoneIndex, poiIndex)
        end
    end

    local function panToPOI(zoneIndex, mapId, poiIndex)
        local normalizedX, normalizedZ = getPOIMapInfo(zoneIndex, mapId, poiIndex)
        Nav.log("Node:ZoomToPOI: poiIndex=%d, %f,%f", poiIndex, normalizedX, normalizedZ)
        if setWaypoint then
            PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, normalizedX, normalizedZ)
        end

        local mapPanAndZoom = ZO_WorldMap_GetPanAndZoom()
        mapPanAndZoom:PanToNormalizedPosition(normalizedX, normalizedZ, false)
    end

    local targetMapId = self.mapId or Nav.Locations.GetMapIdByZoneId(self.zoneId)
    local currentMapId = GetCurrentMapId()
    local targetZoneIndex = GetZoneIndex(self.zoneId)

    if targetMapId ~= currentMapId then
        WORLD_MAP_MANAGER:SetMapById(targetMapId)

        zo_callLater(function()
            panToPOI(targetZoneIndex, targetMapId, self.poiIndex)
        end, 100)
    else
        panToPOI(targetZoneIndex, targetMapId, self.poiIndex)
    end
end


--- @class PlayerNode
local PlayerNode = Node:New()

function PlayerNode:IsPlayer() return true end

function PlayerNode:GetIconColorDef()
    if self.poiType == Nav.POI_FRIEND then
        return ZO_ColorDef:New(0.9, 0.8, 0)
    elseif self.poiType == Nav.POI_GROUPMATE then
        return ZO_WHITE
    elseif Nav.IsPlayer(self.poiType) then
        return ZO_NORMAL_TEXT
    else
        return ZO_DISABLED_TEXT
    end
end

function PlayerNode:GetSuffixColorDef()
    return ZO_ColorDef:New(self.canJumpToPlayer and "76BCC" or "82826F")
end

function PlayerNode:JumpToPrimaryResidence()
    SCENE_MANAGER:Hide("worldMap")
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.POSITIVE_CLICK,zo_strformat(GetString(NAVIGATOR_TRAVELING_TO_PLAYER_HOUSE), self.userID))
    JumpToHouse(self.userID)
end

function PlayerNode:JumpToPlayer()
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.POSITIVE_CLICK,zo_strformat(GetString(NAVIGATOR_TRAVELING_TO_ZONE_VIA_PLAYER), self.zoneName, self.userID))
    SCENE_MANAGER:Hide("worldMap")
    Nav.log("Jump %s %d", self.userID, self.poiType)
    if self.poiType == Nav.POI_FRIEND then
        JumpToFriend(self.userID)
    elseif self.poiType == Nav.POI_GUILDMATE then
        JumpToGuildMember(self.userID)
    elseif self.poiType == Nav.POI_GROUPMATE then
        JumpToGroupMember(self.userID or self.charName)
    end
end

function PlayerNode:OnClick()
    self:JumpToPlayer()
end

function PlayerNode:AddMenuItems()
    AddMenuItem(zo_strformat(GetString(SI_WORLD_MAP_ACTION_TRAVEL_TO_WAYSHRINE), self.userID), function()
        zo_callLater(function() self:JumpToPlayer() end, 10)
    end)
    if Nav.Players:IsGroupLeader() and self.poiType == Nav.POI_GROUPMATE then
        AddMenuItem(GetString(SI_GROUP_LIST_MENU_PROMOTE_TO_LEADER), function()
            GroupPromote(self.unitTag)
            MT.menuOpen = false
            MT:ImmediateRefresh()
        end)
    end
    AddMenuItem(GetString(SI_SOCIAL_MENU_VISIT_HOUSE), function()
        self:JumpToPrimaryResidence()
        MT.menuOpen = false
    end)

    local bookmarkEntry = { userID = self.userID, action = "house" }
    if not Nav.Bookmarks:contains(bookmarkEntry) then
        AddMenuItem(GetString(NAVIGATOR_MENU_ADDHOUSEBOOKMARK), function()
            Nav.Bookmarks:add(bookmarkEntry)
            MT.menuOpen = false
            zo_callLater(function() MT:ImmediateRefresh() end, 10)
        end)
    end
end


--- @class ZoneNode
local ZoneNode = Node:New()

function ZoneNode:JumpToZone()
    Nav.Players:SetupPlayers()
    local zoneId = self.zoneId

    local player = Nav.Players:GetPlayerInZone(zoneId)
    if not player then
        -- Eeek! Refresh the search results and finish
        Nav.MapTab:buildScrollList()
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, (zo_strformat(GetString(NAVIGATOR_NO_PLAYER_IN_ZONE), GetZoneNameById(zoneId))))
        return
    end

    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.POSITIVE_CLICK, (zo_strformat(GetString(NAVIGATOR_TRAVELING_TO_ZONE_VIA_PLAYER), player.zoneName, player.userID)))
    SCENE_MANAGER:Hide("worldMap")
    Nav.log("Jump %s %d", player.userID, player.poiType)
    if player.poiType == Nav.POI_FRIEND then
        JumpToFriend(player.userID)
    elseif player.poiType == Nav.POI_GUILDMATE then
        JumpToGuildMember(player.userID)
    elseif player.poiType == Nav.POI_GROUPMATE then
        JumpToGroupMember(player.userID or player.charName)
    end
end

function ZoneNode:OnClick(isDoubleClick)
    local clickEvent
    if isDoubleClick then
        if clickEvent then zo_removeCallLater(clickEvent) end
        self:JumpToZone() --jumpToZone(self.zoneId)
    else
        local mapZoneId = Nav.Locations:getCurrentMapZoneId()
        local currentMapId = GetCurrentMapId()
        local targetMapId = self.mapId or Nav.Locations.GetMapIdByZoneId(self.zoneId)
        Nav.log("ZoneNode:OnClick: self.zoneId %d self.mapId %d mapZoneId %d mapId %d", self.zoneId, self.mapId or 0, mapZoneId, targetMapId)
        if self.zoneId ~= mapZoneId or (self.mapId and self.mapId ~= currentMapId) then
            --Nav.log("selectResult: mapId %d", targetMapId or 0)
            if targetMapId then
                -- Delay single click to give time for the double-click to occur
                clickEvent = zo_callLater(function()
                    Nav.MapTab.filter = Nav.FILTER_NONE
                    --self.editControl:SetText("")
                    WORLD_MAP_MANAGER:SetMapById(targetMapId)
                end, 200)
            end
        end
    end
end

function ZoneNode:AddMenuItems()
    local targetMapId = self.mapId or Nav.Locations.GetMapIdByZoneId(self.zoneId)
    if targetMapId ~= GetCurrentMapId() then
        AddMenuItem(GetString(NAVIGATOR_MENU_SHOWONMAP), function()
            WORLD_MAP_MANAGER:SetMapById(targetMapId)
        end)
    end

    if Nav.isRecall and self.canJumpToPlayer and self.zoneId ~= Nav.ZONE_CYRODIIL then
        AddMenuItem(zo_strformat(GetString(SI_WORLD_MAP_ACTION_TRAVEL_TO_WAYSHRINE), self.zoneName), function()
            zo_callLater(function() self:JumpToZone() end, 10)
        end)
    end
    self:AddBookmarkMenuItem({ zoneId = self.zoneId, mapId = self.mapId })
end


--- @class JumpToZoneNode
local JumpToZoneNode = ZoneNode:New()
JumpToZoneNode.AddMenuItems = ZoneNode.AddMenuItems

function JumpToZoneNode:GetIcon()
    return self.known and "Navigator/media/recall.dds" or "esoui/art/crafting/crafting_smithing_notrait.dds"
end

function JumpToZoneNode:GetColorDef()
    if self.isSelected and self.known then
        return ZO_SELECTED_TEXT
    else
        return self.known and ZO_SECOND_CONTRAST_TEXT or ZO_DISABLED_TEXT
    end
end

JumpToZoneNode.GetIconColorDef = JumpToZoneNode.GetColorDef

function JumpToZoneNode:OnClick()
    self:JumpToZone()
end


--- @class HouseNode
local HouseNode = Node:New()

function HouseNode:GetColorDef()
    if self.isSelected and self.known and self.owned then
        return ZO_SELECTED_TEXT
    elseif self.known and self.owned then
        return ZO_NORMAL_TEXT
    else
        return ZO_DISABLED_TEXT -- rowControl.label:SetColor(0.51, 0.51, 0.44, 1.0)
    end
end

function Node:GetSuffixColorDef()
    return ZO_ColorDef:New(self.known and self.owned and "82826F" or "616151")
end

local function requestJumpToHouse(data, jumpOutside)
    if not CanJumpToHouseFromCurrentLocation() then
        local cannotJumpString = data.owned and GetString(SI_COLLECTIONS_CANNOT_JUMP_TO_HOUSE_FROM_LOCATION) or GetString(SI_COLLECTIONS_CANNOT_PREVIEW_HOUSE_FROM_LOCATION)
        zo_callLater(function()
            SCENE_MANAGER:Hide("worldMap")
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, cannotJumpString)
        end, 10)
        return
    end

    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.POSITIVE_CLICK,
            zo_strformat(GetString(jumpOutside and NAVIGATOR_TRAVELING_TO_HOUSE_OUTSIDE or NAVIGATOR_TRAVELING_TO_HOUSE_INSIDE), data.name))
    local houseId = data.houseId or GetFastTravelNodeHouseId(data.nodeIndex)
    RequestJumpToHouse(houseId, jumpOutside)
    zo_callLater(function() SCENE_MANAGER:Hide("worldMap") end, 10)
end

function HouseNode:OnClick()
    requestJumpToHouse(self, false)
end

function HouseNode:AddMenuItems()
    if self.owned then
        AddMenuItem(zo_strformat(GetString(SI_WORLD_MAP_ACTION_TRAVEL_TO_HOUSE_INSIDE), self.name), function()
            requestJumpToHouse(self, false)
        end)
        AddMenuItem(zo_strformat(GetString(SI_WORLD_MAP_ACTION_TRAVEL_TO_HOUSE_OUTSIDE), self.name), function()
            requestJumpToHouse(self, true)
        end)
    else
        AddMenuItem(zo_strformat(GetString(SI_WORLD_MAP_ACTION_PREVIEW_HOUSE), self.name), function()
            requestJumpToHouse(self, false)
        end)
    end
    --TODO: Revisit: setting the primary residence didn't seem to be immediately visible
    --if not data.isPrimary then
    --    AddMenuItem(zo_strformat(GetString(SI_HOUSING_FURNITURE_SETTINGS_GENERAL_PRIMARY_RESIDENCE_BUTTON_TEXT), data.name), function()
    --        local houseId = data.houseId or GetFastTravelNodeHouseId(data.nodeIndex)
    --        SetHousingPrimaryHouse(houseId)
    --        zo_callLater(function()
    --            Nav.Locations:setupNodes()
    --            MT:ImmediateRefresh()
    --        end, 10)
    --        ClearMenu()
    --    end)
    --end
    AddMenuItem(GetString(NAVIGATOR_MENU_SHOWONMAP), function()
        self:ZoomToPOI(false)
    end)
    AddMenuItem(GetString(NAVIGATOR_MENU_SETDESTINATION), function()
        self:ZoomToPOI(true)
    end)
    self:AddBookmarkMenuItem({ nodeIndex = self.nodeIndex })
end


--- @class FastTravelNode
local FastTravelNode = Node:New()

function FastTravelNode:Jump()
    if not self.known or self.disabled then
        return
    end

    ZO_Dialogs_ReleaseDialog("FAST_TRAVEL_CONFIRM")
    ZO_Dialogs_ReleaseDialog("RECALL_CONFIRM")

    local id = (Nav.isRecall == true and "RECALL_CONFIRM") or "FAST_TRAVEL_CONFIRM"
    if Nav.isRecall == true then
        local _, timeLeft = GetRecallCooldown()
        if timeLeft ~= 0 then
            local text = zo_strformat(SI_FAST_TRAVEL_RECALL_COOLDOWN, self.originalName, ZO_FormatTimeMilliseconds(timeLeft, TIME_FORMAT_STYLE_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS))
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, text)
            return
        end
    end
    ZO_Dialogs_ShowPlatformDialog(id, {nodeIndex = self.nodeIndex}, {mainTextParams = {self.originalName}})
end

function FastTravelNode:OnClick()
    self:Jump()
end

function FastTravelNode:AddMenuItems()
    local strId = (Nav.isRecall and self.poiType ~= Nav.POI_HOUSE) and SI_WORLD_MAP_ACTION_RECALL_TO_WAYSHRINE or SI_WORLD_MAP_ACTION_TRAVEL_TO_WAYSHRINE
    AddMenuItem(zo_strformat(GetString(strId), self.name), function()
        self:Jump()
    end)
    AddMenuItem(GetString(NAVIGATOR_MENU_SHOWONMAP), function()
        self:ZoomToPOI(false)
    end)
    AddMenuItem(GetString(NAVIGATOR_MENU_SETDESTINATION), function()
        self:ZoomToPOI(true)
    end)
    --self:AddBookmarkMenuItem({ nodeIndex = self.nodeIndex })
end


--- @class PlayerHouseNode
local PlayerHouseNode = Node:New()

function PlayerHouseNode:OnClick()
    SCENE_MANAGER:Hide("worldMap")
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.POSITIVE_CLICK,zo_strformat(GetString(NAVIGATOR_TRAVELING_TO_PLAYER_HOUSE), self.userID))
    JumpToHouse(self.userID)
end

function PlayerHouseNode:AddMenuItems()
    AddMenuItem(GetString(SI_SOCIAL_MENU_VISIT_HOUSE), function()
        zo_callLater(function()
            SCENE_MANAGER:Hide("worldMap")
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.POSITIVE_CLICK,zo_strformat(GetString(NAVIGATOR_TRAVELING_TO_PLAYER_HOUSE), self.userID))
            JumpToHouse(self.userID)
        end, 10)
    end)
end


Nav.Node = Node
Nav.PlayerNode = PlayerNode
Nav.ZoneNode = ZoneNode
Nav.JumpToZoneNode = JumpToZoneNode
Nav.HouseNode = HouseNode
Nav.FastTravelNode = FastTravelNode
Nav.PlayerHouseNode = PlayerHouseNode
