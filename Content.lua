---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by david.
--- DateTime: 24/02/2025 07:29
---

local Nav = Navigator


local function nameComparison(x, y)
    return Nav.Utils.SortName(x) < Nav.Utils.SortName(y)
end


---@class Category
local Category = {}

function Category:New(o)
    o = o or {
        id = "",
        title = "",
        list = {},
        emptyHint = nil,
        maxEntries = nil,
        sort = nil
    }
    setmetatable(o, self)
    self.__index = self
    return o
end




--- @class Content
local Content = {}

function Content:New()
    local o = {
        categories = {}
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Content:AddGroupCategory()
    local group = Nav.Players:GetGroupList()
    if #group > 0 then
        table.insert(self.categories, {
            id = "group",
            title = SI_MAIN_MENU_GROUP,
            list = group
        })
    end
end

function Content:AddBookmarksCategory()
    table.insert(self.categories, {
        id = "bookmarks",
        title = NAVIGATOR_CATEGORY_BOOKMARKS,
        list = Nav.Bookmarks:getBookmarks(),
        emptyHint = NAVIGATOR_HINT_NOBOOKMARKS
    })
end

function Content:AddRecentsCategory()
    local recentCount = Nav.saved.recentsCount
    if recentCount > 0 then
        table.insert(self.categories, {
            id = "recents",
            title = NAVIGATOR_CATEGORY_RECENT,
            list = Nav.Recents:getRecents(),
            emptyHint = NAVIGATOR_HINT_NORECENTS,
            maxEntries = recentCount
        })
    end
end

function Content:AddZoneCategory(zone)
    local list = Nav.Locations:GetNodeList(zone.zoneId, false, Nav.saved.listPOIs)
    table.sort(list, Nav.Node.WeightComparison)

    if Nav.jumpState == Nav.JUMPSTATE_WORLD and zone.zoneId ~= Nav.ZONE_CYRODIIL then
        local node = Nav.JumpToZoneNode:New(Nav.Utils.shallowCopy(zone))
        local playerInfo = Nav.Players:GetPlayerInZone(zone.zoneId)
        node.known = playerInfo ~= nil
        table.insert(list, 1, node)
    end

    table.insert(self.categories, {
        id = "results",
        title = zone.name,
        list = list
    })
end

function Content:AddCyrodiilCategories()
    local list = Nav.Locations:GetNodeList(Nav.ZONE_CYRODIIL, false, Nav.saved.listPOIs)
    local zone = Nav.Locations.zones[Nav.ZONE_CYRODIIL]

    local allianceNodes = {}
    allianceNodes[ALLIANCE_ALDMERI_DOMINION] = {}
    allianceNodes[ALLIANCE_DAGGERFALL_COVENANT] = {}
    allianceNodes[ALLIANCE_EBONHEART_PACT] = {}
    local poiNodes = {}

    for i = 1, #list do
        local node = list[i]
        if node.alliance and allianceNodes[node.alliance] then
            table.insert(allianceNodes[node.alliance], node)
        elseif node.alliance then
            table.insert(poiNodes, node)
        end
    end

    for _, poiNode in pairs(zone.pois) do
        table.insert(poiNodes, poiNode)
    end

    local pa = Nav.currentAlliance
    local allianceList =
            (pa == ALLIANCE_ALDMERI_DOMINION and { ALLIANCE_ALDMERI_DOMINION, ALLIANCE_DAGGERFALL_COVENANT, ALLIANCE_EBONHEART_PACT }) or
            (pa == ALLIANCE_DAGGERFALL_COVENANT and { ALLIANCE_DAGGERFALL_COVENANT, ALLIANCE_EBONHEART_PACT, ALLIANCE_ALDMERI_DOMINION }) or
            (pa == ALLIANCE_EBONHEART_PACT and { ALLIANCE_EBONHEART_PACT, ALLIANCE_ALDMERI_DOMINION, ALLIANCE_DAGGERFALL_COVENANT })

    for i = 1, #allianceList do
        local alliance = allianceList[i]
        table.sort(allianceNodes[alliance], Nav.Node.WeightComparison)
        table.insert(self.categories, {
            id = string.format("alliance_%d", alliance),
            title = GetAllianceName(alliance),
            list = allianceNodes[alliance]
        })
    end

    table.sort(poiNodes, Nav.Node.WeightComparison)
    table.insert(self.categories, {
        id = "pois",
        title = NAVIGATOR_CATEGORY_POI,
        list = poiNodes
    })
end


--- @class ZoneContent
local ZoneContent = Content:New()

function ZoneContent:New(zone)
    local o = {
        zone = zone
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function ZoneContent:Compose()
    self.categories = {}

    self:AddGroupCategory()
    self:AddBookmarksCategory()
    self:AddRecentsCategory()
    self:AddZoneCategory(self.zone)
end


--- @class CyrodiilContent
local CyrodiilContent = Content:New()

function CyrodiilContent:Compose()
    self.categories = {}

    self:AddGroupCategory()

    if Nav.jumpState == Nav.JUMPSTATE_WAYSHRINE then
        self:AddBookmarksCategory()
        self:AddRecentsCategory()
    end

    self:AddCyrodiilCategories()
end


--- @class ZoneListContent
local ZoneListContent = Content:New()

function ZoneListContent:AddZoneListCategory()
    local list = Nav.Locations:GetZoneList()
    table.sort(list, nameComparison)

    table.insert(self.categories, {
        id = "zones",
        title = NAVIGATOR_CATEGORY_ZONES,
        list = list
    })
end

function ZoneListContent:Compose()
    self.categories = {}

    self:AddGroupCategory()
    self:AddBookmarksCategory()
    self:AddRecentsCategory()
    self:AddZoneListCategory()
end


---@class SearchContent
local SearchContent = Content:New()

function SearchContent:New(results)
    local o = {
        results = results
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function SearchContent:Compose()
    self.categories = {}

    table.insert(self.categories, {
        id = "results",
        title = NAVIGATOR_CATEGORY_RESULTS,
        list = self.results,
        emptyHint = NAVIGATOR_HINT_NORESULTS
    })
end


Nav.Category = Category
Nav.ZoneContent = ZoneContent
Nav.ZoneListContent = ZoneListContent
Nav.CyrodiilContent = CyrodiilContent
Nav.SearchContent = SearchContent
