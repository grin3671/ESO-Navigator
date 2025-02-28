---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by david.
--- DateTime: 08/02/2025 15:35
---

local Nav = Navigator

local pingEvent

--- @class Node
local Node = {}

function Node:New(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Node:IsHouse() return false end
function Node:IsPOI() return false end

---WeightComparison
---@param x Node
---@param y Node
function Node.WeightComparison(x, y)
    local xWeight = x:GetWeight()
    local yWeight = y:GetWeight()

    if xWeight ~= yWeight then
        return xWeight > yWeight
    end
    return Nav.SortName(x.name) < Nav.SortName(y.name)
end

function Node:IsKnown()
    if self.known == nil then
        if self.nodeIndex then
            local known, _, _, _, _, _, _, _, _ = GetFastTravelNodeInfo(self.nodeIndex)
            self.known = known
        else
            local x, z, iconType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = GetPOIMapInfo(self.zoneIndex, self.poiIndex)
            self.known = isDiscovered
        end
    end
    return self.known
end

function Node:GetWeight()
    return 1.0
end

function Node:AddBookmarkMenuItem(entry)
    if entry and not Nav.Bookmarks:contains(entry) then
        AddMenuItem(GetString(NAVIGATOR_MENU_ADDBOOKMARK), function()
            Nav.Bookmarks:add(entry)
            Nav.MapTab.menuOpen = false
            zo_callLater(function() Nav.MapTab:ImmediateRefresh() end, 10)
        end)
    end
end

function Node:GetName()
    return self.name or ""
end

function Node:GetIcon()
    return self.icon
end

function Node:GetSuffix()
    return self.suffix or ""
end

function Node:GetTagList(showBookmark)
    local tagList = {}
    if showBookmark and Nav.Bookmarks:contains(self) then
        table.insert(tagList, "bookmark")
    end
    return tagList
end

function Node:GetOverlayIcon()
    return nil, nil
end

function Node:GetTooltip()
    return self.tooltip
end

function Node:GetColour(isSelected)
    if isSelected and self.known and not self.disabled then
        return Nav.COLOUR_WHITE
    elseif self.known and not self.disabled then
        return Nav.COLOUR_NORMAL
    else
        return Nav.COLOUR_DISABLED
    end
end

function Node:GetIconColour()
    if self.known and not self.disabled then
        return Nav.COLOUR_WHITE
    else
        return Nav.COLOUR_DISABLED
    end
end

function Node:GetSuffixColour()
    if self.known and not self.disabled then
        return Nav.COLOUR_SUFFIX_NORMAL
    else
        return Nav.COLOUR_SUFFIX_DISABLED
    end
    --return (self.known and not self.disabled) and Nav.COLOUR_SUFFIX_NORMAL or Nav.COLOUR_SUFFIX_DISABLED
end
Node.GetTagColour = Node.GetSuffixColour

function Node:GetRecallCost()
    return nil -- By default, free!
end

function Node:GetMapInfo(self, zoneIndex, mapId)
    if mapId == 2082 then
        return 0.3485, 0.3805 -- The Shambles
    elseif self.nodeIndex == 407 then
        return 0.9273, 0.7105 -- Dragonguard Sanctum
    else
        return GetPOIMapInfo(zoneIndex, self.poiIndex)
    end
end

function Node:ZoomToPOI(setWaypoint, useCurrentZone)
    local function panToPOI(self, zoneIndex, mapId)
        local normalizedX, normalizedZ = self:GetMapInfo(self, zoneIndex, mapId)
        Nav.log("Node:ZoomToPOI: poiIndex=%d, %f,%f", self.poiIndex or -1, normalizedX, normalizedZ)
        if setWaypoint then
            PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, normalizedX, normalizedZ)
        else
            Node.AddPing(normalizedX, normalizedZ)
        end

        local mapPanAndZoom = ZO_WorldMap_GetPanAndZoom()
        mapPanAndZoom:PanToNormalizedPosition(normalizedX, normalizedZ, useCurrentZone)
    end

    local targetMapId = self.mapId or Nav.Locations.GetMapIdByZoneId(self.zoneId)
    local currentMapId = GetCurrentMapId()
    local targetZoneIndex = GetZoneIndex(self.zoneId)
    if self.nodeIndex == 407 then -- Dragonguard Sanctum
        targetMapId = 1654
    end

    if targetMapId ~= currentMapId then
        WORLD_MAP_MANAGER:SetMapById(targetMapId)

        zo_callLater(function()
            panToPOI(self, targetZoneIndex, targetMapId)
        end, 100)
    else
        panToPOI(self, targetZoneIndex, targetMapId)
    end
end

function Node.AddPing(x, y)
    Node.RemovePings()
    local pinMgr = ZO_WorldMap_GetPinManager()
    pinMgr:CreatePin(MAP_PIN_TYPE_AUTO_MAP_NAVIGATION_PING, "pings", x, y)
    pingEvent = zo_callLater(function()
        Node.RemovePings()
        pingEvent = nil
    end, 2800)
end

function Node.RemovePings()
    if pingEvent then
        zo_removeCallLater(pingEvent)
        pingEvent = nil
        ZO_WorldMap_GetPinManager():RemovePins("pings", MAP_PIN_TYPE_AUTO_MAP_NAVIGATION_PING)
    end
end

function Node:DoAction(action)
    if action == Nav.ACTION_SHOWONMAP then
        self:ZoomToPOI(false)
    elseif action == Nav.ACTION_SETDESTINATION then
        self:ZoomToPOI(true)
    elseif action == Nav.ACTION_TRAVEL then
        self:Jump()
    end
end

--- @class PlayerNode
local PlayerNode = Node:New()

function PlayerNode:GetWeight()
    if self.isGroupmate then
        return self.isLeader and 1.3 or 1.2
    elseif self.isFriend then
        return 1.1
    else
        return 1.0
    end
end

function PlayerNode:GetIcon()
    if self.isGroupmate then
        return self.isLeader and "/esoui/art/icons/mapkey/mapkey_groupleader.dds" or "/esoui/art/icons/mapkey/mapkey_groupmember.dds"
    else
        return "Navigator/media/player.dds"
    end
end

function PlayerNode:GetSuffix() return self.zoneName or "" end

function PlayerNode:GetOverlayIcon()
    if self.isFriend then
        return "Navigator/media/overlays/star.dds", Nav.COLOUR_FRIEND
    else
        return nil, nil
    end
end

function PlayerNode:GetIconColour()
    if self.isFriend then
        return Nav.COLOUR_FRIEND
    elseif self.isGroupmate then
        return Nav.COLOUR_WHITE
    else
        return Nav.COLOUR_NORMAL
    end
end

function PlayerNode:GetSuffixColour()
    return self.canJumpToPlayer and Nav.COLOUR_JUMPABLE or Nav.COLOUR_SUFFIX_NORMAL
end

function PlayerNode:JumpToPrimaryResidence()
    SCENE_MANAGER:Hide("worldMap")
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.POSITIVE_CLICK,zo_strformat(GetString(NAVIGATOR_TRAVELING_TO_PLAYER_HOUSE), self.userID))
    JumpToHouse(self.userID)
end

function PlayerNode:JumpToPlayer()
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.POSITIVE_CLICK,zo_strformat(GetString(NAVIGATOR_TRAVELING_TO_PLAYER_IN_ZONE), self.userID, self.zoneName))
    SCENE_MANAGER:Hide("worldMap")
    if self.isFriend then
        JumpToFriend(self.userID)
    elseif self.isGuildmate then
        JumpToGuildMember(self.userID)
    elseif self.isGroupmate then
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
    if Nav.Players:IsGroupLeader() and self.isGroupmate then
        AddMenuItem(GetString(SI_GROUP_LIST_MENU_PROMOTE_TO_LEADER), function()
            GroupPromote(self.unitTag)
            Nav.MapTab.menuOpen = false
            Nav.MapTab:ImmediateRefresh()
        end)
    end
    AddMenuItem(GetString(SI_SOCIAL_MENU_VISIT_HOUSE), function()
        self:JumpToPrimaryResidence()
        Nav.MapTab.menuOpen = false
    end)

    local bookmarkEntry = { userID = self.userID, action = "house" }
    if not Nav.Bookmarks:contains(bookmarkEntry) then
        AddMenuItem(GetString(NAVIGATOR_MENU_ADDHOUSEBOOKMARK), function()
            Nav.Bookmarks:add(bookmarkEntry)
            Nav.MapTab.menuOpen = false
            zo_callLater(function() Nav.MapTab:ImmediateRefresh() end, 10)
        end)
    end
end


--- @class ZoneNode
local ZoneNode = Node:New()

function ZoneNode:GetWeight()
    return Nav.jumpState == Nav.JUMPSTATE_WORLD and 1.0 or 0.9
end

function ZoneNode:GetIcon()
    return "Navigator/media/zone.dds"
end

function ZoneNode:GetTooltip()
    if self.zoneId == Nav.ZONE_CYRODIIL then return nil end
    local player = Nav.Players:GetPlayerInZone(self.zoneId)
    local stringId = player and NAVIGATOR_TIP_DOUBLECLICK_TO_TRAVEL or NAVIGATOR_NO_TRAVEL_PLAYER
    return zo_strformat(GetString(stringId), self.name)
end

function ZoneNode:IsJumpable()
    local player = Nav.Players:GetPlayerInZone(self.zoneId)
    return player and self.zoneId > Nav.ZONE_TAMRIEL and self.zoneId ~= Nav.ZONE_CYRODIIL
end

function ZoneNode:GetColour()
    return (Nav.jumpState == Nav.JUMPSTATE_WAYSHRINE and Nav.COLOUR_NORMAL) or
            (self:IsJumpable() and Nav.COLOUR_JUMPABLE) or Nav.COLOUR_POI
end

function ZoneNode:GetOverlayIcon()
    if self:IsJumpable() and Nav.jumpState == Nav.JUMPSTATE_WORLD then
        return "Navigator/media/overlays/dot.dds", Nav.COLOUR_JUMPABLE
    else
        return nil, nil
    end
end

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
    if player.isFriend then
        JumpToFriend(player.userID)
    elseif player.isGuildmate then
        JumpToGuildMember(player.userID)
    elseif player.isGroupmate then
        JumpToGroupMember(player.userID or player.charName)
    end
end

function ZoneNode:OnClick(isDoubleClick)
    self:DoAction(isDoubleClick and Nav.saved.zoneDoubleClick or Nav.saved.zoneSingleClick)
end

function ZoneNode:DoAction(action)
    if action == Nav.ACTION_SHOWONMAP then
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
    elseif action == Nav.ACTION_TRAVEL then
        self:JumpToZone()
    end
end

function ZoneNode:AddMenuItems()
    local targetMapId = self.mapId or Nav.Locations.GetMapIdByZoneId(self.zoneId)
    if targetMapId ~= GetCurrentMapId() then
        AddMenuItem(GetString(NAVIGATOR_MENU_SHOWONMAP), function()
            WORLD_MAP_MANAGER:SetMapById(targetMapId)
        end)
    end

    if Nav.jumpState == Nav.JUMPSTATE_WORLD and self.canJumpToPlayer and self.zoneId ~= Nav.ZONE_CYRODIIL then
        AddMenuItem(zo_strformat(GetString(SI_WORLD_MAP_ACTION_TRAVEL_TO_WAYSHRINE), self.zoneName), function()
            zo_callLater(function() self:JumpToZone() end, 10)
        end)
    end
    self:AddBookmarkMenuItem({ zoneId = self.zoneId, mapId = self.mapId })
end


--- @class JumpToZoneNode
local JumpToZoneNode = ZoneNode:New()
JumpToZoneNode.AddMenuItems = ZoneNode.AddMenuItems

function JumpToZoneNode:GetName()
    if self.known then
        return zo_strformat(GetString(NAVIGATOR_TRAVEL_TO_ZONE), self.name)
    else
        return GetString(NAVIGATOR_NO_TRAVEL_PLAYER)
    end
end

function JumpToZoneNode:GetIcon()
    return self.known and "Navigator/media/recall.dds" or "esoui/art/crafting/crafting_smithing_notrait.dds"
end

function JumpToZoneNode:GetOverlayIcon()
    return nil, nil
end

function JumpToZoneNode:GetSuffix() return "" end
function JumpToZoneNode:GetTagList() return {} end
function JumpToZoneNode:GetTooltip() return nil end

function JumpToZoneNode:GetColour(isSelected)
    if isSelected and self.known then
        return Nav.COLOUR_WHITE
    else
        return self.known and Nav.COLOUR_JUMPABLE or Nav.COLOUR_DISABLED
    end
end

JumpToZoneNode.GetIconColour = JumpToZoneNode.GetColour

function JumpToZoneNode:OnClick()
    self:JumpToZone()
end


--- @class HouseNode
local HouseNode = Node:New()

function HouseNode:IsHouse() return true end

function HouseNode:GetHouseId()
    if self.houseId == nil then
        self.houseId = GetFastTravelNodeHouseId(self.nodeIndex)
    end
    return self.houseId
end

function HouseNode:IsPrimary()
    if self.isPrimary == nil then
        self.isPrimary = self:GetHouseId() == GetHousingPrimaryHouse()
    end
    return self.isPrimary
end

function HouseNode:GetWeight()
    local weight = 1.0

    if self.isAlias then
        weight = 0.6
    elseif not self.owned then
        weight = 0.4
    elseif Nav.Bookmarks:contains(self) then
        weight = 1.2
    end
    if self:IsPrimary() then
        weight = weight + 0.1
    end

    return weight
end

function HouseNode:GetIcon()
    return "Navigator/media/house.dds"
end

function HouseNode:GetIconColour()
    if self.owned then
        return Nav.COLOUR_WHITE
    else
        return Nav.COLOUR_DISABLED
    end
end

function HouseNode:GetOverlayIcon()
    if self:IsPrimary() then
        return "Navigator/media/overlays/star.dds", Nav.COLOUR_WHITE
    else
        return nil, nil
    end
end

function HouseNode:GetColour(isSelected)
    if isSelected and self.known and self.owned then
        return Nav.COLOUR_WHITE
    else
        return (self.known and self.owned) and Nav.COLOUR_NORMAL or Nav.COLOUR_DISABLED
    end
end

function HouseNode:GetSuffixColour()
    return (self.known and self.owned) and Nav.COLOUR_SUFFIX_NORMAL or Nav.COLOUR_SUFFIX_DISABLED
end

function HouseNode:Jump(jumpOutside)
    if not CanJumpToHouseFromCurrentLocation() then
        local cannotJumpString = self.owned and GetString(SI_COLLECTIONS_CANNOT_JUMP_TO_HOUSE_FROM_LOCATION) or GetString(SI_COLLECTIONS_CANNOT_PREVIEW_HOUSE_FROM_LOCATION)
        zo_callLater(function()
            SCENE_MANAGER:Hide("worldMap")
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, cannotJumpString)
        end, 10)
        return
    end

    local stringId = jumpOutside and NAVIGATOR_TRAVELING_TO_HOUSE_OUTSIDE or NAVIGATOR_TRAVELING_TO_HOUSE_INSIDE
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.POSITIVE_CLICK, zo_strformat(GetString(stringId), self.name))
    RequestJumpToHouse(self:GetHouseId(), jumpOutside)
    zo_callLater(function() SCENE_MANAGER:Hide("worldMap") end, 10)
end

function HouseNode:OnClick()
    self:Jump(false)
end

function HouseNode:AddMenuItems()
    if self.owned then
        AddMenuItem(zo_strformat(GetString(SI_WORLD_MAP_ACTION_TRAVEL_TO_HOUSE_INSIDE), self.name), function()
            self:Jump(false)
        end)
        AddMenuItem(zo_strformat(GetString(SI_WORLD_MAP_ACTION_TRAVEL_TO_HOUSE_OUTSIDE), self.name), function()
            self:Jump(true)
        end)
    else
        AddMenuItem(zo_strformat(GetString(SI_WORLD_MAP_ACTION_PREVIEW_HOUSE), self.name), function()
            self:Jump(false)
        end)
    end
    --TODO: Revisit: setting the primary residence didn't seem to be immediately visible
    --if not data.isPrimary then
    --    AddMenuItem(zo_strformat(GetString(SI_HOUSING_FURNITURE_SETTINGS_GENERAL_PRIMARY_RESIDENCE_BUTTON_TEXT), data.name), function()
    --        local houseId = data.houseId or GetFastTravelNodeHouseId(data.nodeIndex)
    --        SetHousingPrimaryHouse(houseId)
    --        zo_callLater(function()
    --            Nav.Locations:SetupNodes()
    --            Nav.MapTab:ImmediateRefresh()
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

function FastTravelNode:GetWeight()
    local weight = ((self.freeRecall or Nav.jumpState == Nav.JUMPSTATE_WAYSHRINE) and 1.0) or
            (not self.known and 0.4) or
            (self.disabled and 0.3) or 0.8

    if Nav.Bookmarks:contains(self) then
        weight = weight + 0.15
    end
    if self.traders and self.traders > 0 then
        weight = weight + 0.02 * self.traders
    end

    return weight
end

function FastTravelNode:GetSuffix()
    if self.poiType == Nav.POI_GROUP_DUNGEON then
        return self.nodeIndex ~= 550 and GetString(NAVIGATOR_DUNGEON) or ""
    elseif self.poiType == Nav.POI_TRIAL then
        return GetString(NAVIGATOR_TRIAL)
    elseif self.poiType == Nav.POI_ARENA then
        return GetString(NAVIGATOR_ARENA)
    end
    return ""
end

function FastTravelNode:GetTagList(showBookmark)
    local tagList = {}

    if self.traders and self.traders > 0 then
        if self.traders >= 5 then
            table.insert(tagList, "city")
        elseif self.traders >= 2 then
            table.insert(tagList, "town")
        end
        table.insert(tagList, "trader")
    end

    return Nav.Utils.tableConcat(tagList, Node.GetTagList(self, showBookmark))
end

function Node:GetOverlayIcon()
    if self:GetRecallCost() then
        return "Navigator/media/overlays/coin.dds", Nav.COLOUR_COIN
    else
        return nil, nil
    end
end

function FastTravelNode:GetRecallCost()
    if Nav.jumpState == Nav.JUMPSTATE_WAYSHRINE or self.disabled then
        return nil
    end

    local _, timeLeft = GetRecallCooldown()
    if timeLeft == 0 then
        local currencyAmount = GetRecallCost(self.nodeIndex)
        if currencyAmount > 0 then
            return currencyAmount
        end
    end
    return nil -- It's free!
end

function FastTravelNode:Jump()
    if not self.known or self.disabled then
        Nav.log("FastTravelNode:Jump: unknown or disabled")
        return
    end

    ZO_Dialogs_ReleaseDialog("FAST_TRAVEL_CONFIRM")
    ZO_Dialogs_ReleaseDialog("RECALL_CONFIRM")

    if Nav.jumpState == Nav.JUMPSTATE_WORLD then
        -- Locked out of recall for a time
        local _, timeLeft = GetRecallCooldown()
        if timeLeft ~= 0 then
            local text = zo_strformat(SI_FAST_TRAVEL_RECALL_COOLDOWN, self.originalName, ZO_FormatTimeMilliseconds(timeLeft, TIME_FORMAT_STYLE_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS))
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, text)
            return
        end
    end

    local confirm = Nav.saved.confirmFastTravel
    local cost = Nav.jumpState == Nav.JUMPSTATE_WORLD and GetRecallCost(self.nodeIndex) or 0
    local currency = GetRecallCurrency(self.nodeIndex)
    local canAffordRecall = cost <= GetCurrencyAmount(currency, CURRENCY_LOCATION_CHARACTER)
    if (confirm == Nav.CONFIRMFASTTRAVEL_NEVER and canAffordRecall) or
       (confirm == Nav.CONFIRMFASTTRAVEL_WHENCOST and cost == 0) then
        zo_callLater(function()
            FastTravelToNode(self.nodeIndex)
            SCENE_MANAGER:Hide("worldMap")
            local id = Nav.jumpState == Nav.JUMPSTATE_WORLD and NAVIGATOR_RECALLING_TO_LOCATION_COST or NAVIGATOR_TRAVELING_TO_LOCATION
            local currencyString = zo_strformat(SI_NUMBER_FORMAT, ZO_Currency_FormatKeyboard(CURT_MONEY, cost, ZO_CURRENCY_FORMAT_AMOUNT_ICON))
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.POSITIVE_CLICK,
                    zo_strformat(GetString(id), self.name, currencyString))
        end, 10)
        return
    end

    local id = Nav.jumpState == Nav.JUMPSTATE_WORLD and "RECALL_CONFIRM" or "FAST_TRAVEL_CONFIRM"
    ZO_Dialogs_ShowPlatformDialog(id, {nodeIndex = self.nodeIndex}, {mainTextParams = {self.originalName}})
end

function FastTravelNode:AddMenuItems()
    if self:IsKnown() then
        local strId = Nav.jumpState == Nav.JUMPSTATE_WORLD and SI_WORLD_MAP_ACTION_RECALL_TO_WAYSHRINE or SI_WORLD_MAP_ACTION_TRAVEL_TO_WAYSHRINE
        AddMenuItem(zo_strformat(GetString(strId), self.name), function()
            self:Jump()
        end)
    end
    AddMenuItem(GetString(NAVIGATOR_MENU_SHOWONMAP), function()
        self:ZoomToPOI(false)
    end)
    AddMenuItem(GetString(NAVIGATOR_MENU_SETDESTINATION), function()
        self:ZoomToPOI(true)
    end)
    self:AddBookmarkMenuItem({ nodeIndex = self.nodeIndex })
end

function FastTravelNode:OnClick(isDoubleClick)
    self:DoAction(isDoubleClick and Nav.saved.destinationDoubleClick or Nav.saved.destinationSingleClick)
end


--- @class PlayerHouseNode
local PlayerHouseNode = Node:New()

function PlayerHouseNode:GetIcon()
    return "Navigator/media/house.dds"
end

function PlayerHouseNode:GetOverlayIcon()
    return "Navigator/media/overlays/player.dds", Nav.COLOUR_WHITE
end

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


--- @class POINode
local POINode = Node:New()

function POINode:IsPOI() return true end

function POINode:GetColour(isSelected)
    if isSelected and self.known and not self.disabled then
        return Nav.COLOUR_WHITE
    elseif self.known and not self.disabled then
        return Nav.COLOUR_POI
    else
        return Nav.COLOUR_DISABLED
    end
end

function POINode:GetSuffixColour()
    if self.known and not self.disabled then
        return Nav.COLOUR_SUFFIX_POI
    else
        return Nav.COLOUR_SUFFIX_DISABLED
    end
end
POINode.GetTagColour = POINode.GetSuffixColour

function POINode:OnClick()
    self:ZoomToPOI(false)
end

function POINode:AddMenuItems()
    AddMenuItem(GetString(NAVIGATOR_MENU_SHOWONMAP), function()
        self:ZoomToPOI(false)
    end)
    AddMenuItem(GetString(NAVIGATOR_MENU_SETDESTINATION), function()
        self:ZoomToPOI(true)
    end)
    self:AddBookmarkMenuItem({ poiIndex = self.poiIndex, zoneId = self.zoneId })
end

function POINode:GetWeight()
    local weight = self:IsKnown() and 0.5 or 0.3
    if Nav.Bookmarks:contains(self) then
        weight = weight + 0.05
    end
    return weight
end


--- @class KeepNode
local KeepNode = Node:New()

function KeepNode:GetColour(isSelected)
    if isSelected and self.accessible then
        return Nav.COLOUR_WHITE
    elseif self.accessible then
        return Nav.COLOUR_NORMAL
    else
        return Nav.COLOUR_POI
    end
end

function KeepNode:GetTagList(showBookmark)
    local tagList = {}

    local isUnderAttack = self:IsUnderAttack()
    if isUnderAttack then
        Nav.log("Keep %s %d UA %d", self.name, self.keepId, isUnderAttack)
        table.insert(tagList, isUnderAttack == 2 and "attackburst" or "attackburst-small")
    end

    return Nav.Utils.tableConcat(tagList, Node.GetTagList(self, showBookmark))
end

function KeepNode:GetTagColour()
    return Nav.COLOUR_WHITE
end

function KeepNode:OnClick()
    self:ZoomToPOI(false)
end

function KeepNode:IsUnderAttack()
    local historyPercent = ZO_WorldMap_GetHistoryPercentToUse()
    if GetHistoricalKeepUnderAttack(self.keepId, self.bgContext, historyPercent) then
        return 2
    end

    for i = 1, 3 do
        local resourceKeepId = GetResourceKeepForKeep(self.keepId, i)
        if resourceKeepId > 0 then
            -- Check if the resource is being attacked rather than reclaimed
            if GetHistoricalKeepUnderAttack(resourceKeepId, self.bgContext, historyPercent) then
               --and GetKeepAlliance(resourceKeepId, bgCtx) == self.alliance then
                return 1
            end
        end
    end

    return nil
end

function KeepNode:GetMapInfo(self, _, _)
    local _,nx,ny  = GetKeepPinInfo(self.keepId, self.bgCtx)
    Nav.log("KeepNode:GetMapInfo: keepId=%d -> %f,%f", self.keepId, nx, ny)
    return nx,ny
end

function KeepNode:Jump()
    local canTravelToKeep = WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_KEEP_RECALL)
    if not canTravelToKeep then
        local startKeepId = GetKeepFastTravelInteraction()
        canTravelToKeep = startKeepId and self.keepId ~= startKeepId
    end
    if canTravelToKeep then
        TravelToKeep(self.keepId)
        ZO_WorldMap_HideWorldMap()
    end
end

function KeepNode:AddMenuItems()
    if self.accessible then
        AddMenuItem(zo_strformat(GetString(SI_WORLD_MAP_ACTION_TRAVEL_TO_WAYSHRINE), self.name), function()
            self:Jump()
        end)
    end
    AddMenuItem(GetString(NAVIGATOR_MENU_SHOWONMAP), function()
        self:ZoomToPOI(false)
    end)
    AddMenuItem(GetString(NAVIGATOR_MENU_SETDESTINATION), function()
        self:ZoomToPOI(true)
    end)
    --self:AddBookmarkMenuItem({ nodeIndex = self.nodeIndex })
end

function KeepNode:OnClick(isDoubleClick)
    local action = isDoubleClick and Nav.saved.destinationDoubleClick or Nav.saved.destinationSingleClick
    if not self.accessible and action == Nav.ACTION_TRAVEL then
        action = Nav.ACTION_SETDESTINATION
    end
    self:DoAction(action)
end

function KeepNode:DoAction(action)
    if action == Nav.ACTION_SHOWONMAP then
        self:ZoomToPOI(false, true)
    elseif action == Nav.ACTION_SETDESTINATION then
        self:ZoomToPOI(true, true)
    elseif action == Nav.ACTION_TRAVEL then
        self:Jump()
    end
end

function KeepNode:GetWeight()
    --FIXME: Lower weight of non-accessible keeps
    local w = (self.icon:find("AvA_borderKeep") and 1.07) or
              (self.icon:find("AvA_town") and 1.08) or
              (self.icon:find("AvA_outpost") and 1.09) or 1.1
    if not self.accessible then w = w - 0.5 end
    return w
end

Nav.Node = Node
Nav.PlayerNode = PlayerNode
Nav.ZoneNode = ZoneNode
Nav.JumpToZoneNode = JumpToZoneNode
Nav.HouseNode = HouseNode
Nav.FastTravelNode = FastTravelNode
Nav.PlayerHouseNode = PlayerHouseNode
Nav.POINode = POINode
Nav.KeepNode = KeepNode