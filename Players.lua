---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by david.
--- DateTime: 31/01/2025 12:30
---
local Nav = Navigator
local Players = Nav.Players or {
    players = nil
}
local Utils = Nav.Utils

local function addPlayer(self, zones, zoneId, zoneName, userID, icon, charName)
    if self.players[userID] then
        return self.players[userID]
    end

    local player = Nav.PlayerNode:New({
        name = userID,
        zoneId = zoneId,
        zoneName = Utils.FormatSimpleName(zoneName),
        userID = userID,
        icon = icon,
        poiType = Nav.POI_PLAYER,
        known = true,
        canJumpToPlayer = zones[zoneId] and zones[zoneId].canJumpToPlayer
    })

    self.players[userID] = player
    if charName then
        charName = zo_strformat("<<!AC:1>>", charName)
        player.charName = charName
    end
    return player
end

function Players:SetupPlayers()
    local zones = Nav.Locations:GetZones()

    local myID = GetDisplayName()
    self.players = {}

    local guildCount = GetNumGuilds()
    for guild = 1, guildCount do
        local guildID = GetGuildId(guild)
        local guildMembers = GetNumGuildMembers(guildID)

        for i = 1, guildMembers do
            local userID, _, _, playerStatus = GetGuildMemberInfo(guildID, i)

            if playerStatus ~= PLAYER_STATUS_OFFLINE and userID ~= myID then
                local hasChar, charName, zoneName, _, _, _, _, zoneId = GetGuildMemberCharacterInfo(guildID, i)
                if hasChar then
                    local player = addPlayer(self, zones, zoneId, zoneName, userID, "Navigator/media/player.dds", charName)
                    player.isGuildmate = true
                end
            end
        end
    end

    local friendCount = GetNumFriends()
    for i = 1, friendCount do
        local userID, _, playerStatus, secsSinceLogoff = GetFriendInfo(i)

        if playerStatus ~= PLAYER_STATUS_OFFLINE and secsSinceLogoff == 0 then
            local hasChar, charName, zoneName, _, _, _, _, zoneId = GetFriendCharacterInfo(i)
            if hasChar then
                local player = addPlayer(self, zones, zoneId, zoneName, userID, "Navigator/media/player_friend.dds", charName)
                player.isFriend = true
            end
        end
    end

    local groupCount = GetGroupSize()
    local playerName = string.lower(GetUnitName("player"))
    for i = 1, groupCount do
        local unitTag = GetGroupUnitTagByIndex(i)
        if unitTag then
            local charName = GetUnitName(unitTag)
            local userID = GetUnitDisplayName(unitTag)
            if IsUnitOnline(unitTag) and string.lower(charName) ~= playerName then
                local zoneId = GetZoneId(GetUnitZoneIndex(unitTag))
                local zoneName = GetZoneNameById(zoneId)
                local icon = isLeader and "/esoui/art/icons/mapkey/mapkey_groupleader.dds" or "/esoui/art/icons/mapkey/mapkey_groupmember.dds"
                local player = addPlayer(self, zones, zoneId, zoneName, userID or '"'..charName..'"', icon, charName)
                if player then
                    player.canJumpToPlayer = true
                    player.unitTag = unitTag
                    player.isLeader = IsUnitGroupLeader(unitTag)
                end
            end
        end
    end
end

function Players:ClearPlayers()
    self.players = nil
end

function Players:GetPlayerList()
    if self.players == nil then self:SetupPlayers() end

    local nodes = {}
    for _, player in pairs(self.players) do
        table.insert(nodes, player)
    end

    return nodes
end

function Players:GetPlayerInZone(zoneId)
    if self.players == nil then self:SetupPlayers() end

    for _, player in pairs(self.players) do
        if player.zoneId == zoneId then
            return player
        end
    end
    return nil
end

local function groupComparison(x, y)
    if x.isLeader and not y.isLeader then -- There can be only one
        return true
    elseif y.isLeader and not x.isLeader then
        return false
    end
    return (x.barename or x.name) < (y.barename or y.name)
end

function Players:GetGroupList()
    if self.players == nil then self:SetupPlayers() end
    
    local list = {}
    for _, player in pairs(self.players) do
        if player.isGroupmate and player.userID then
            table.insert(list, player)
        end
    end

    table.sort(list, groupComparison)

    return list
end

function Players:IsGroupLeader()
    return string.lower(GetUnitName("player")) == string.lower(GetGroupLeaderUnitTag())
end

Nav.Players = Players