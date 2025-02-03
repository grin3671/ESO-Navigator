---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by david.
--- DateTime: 31/01/2025 12:30
---
local Nav = Navigator
local Players = Nav.Players or {
    players = nil,
    playerZones = nil
}
local Utils = Nav.Utils

local function addPlayerZone(self, zones, zoneId, zoneName, userID, icon, poiType)
    if zones[zoneId] and CanJumpToPlayerInZone(zoneId) then
        local zoneInfo = {
            zoneId = zoneId,
            zoneName = Utils.FormatSimpleName(zoneName),
            userID = userID,
            icon = icon,
            poiType = poiType
        }

        self.players[userID] = zoneInfo
        self.playerZones[zoneId] = zoneInfo
    end
end

function Players:SetupPlayerZones()
    local zones = Nav.Locations:GetZones()

    local myID = GetDisplayName()
    self.playerZones = {}
    self.players = {}

    local guildCount = GetNumGuilds()
    for guild = 1, guildCount do
        local guildID = GetGuildId(guild)
        local guildMembers = GetNumGuildMembers(guildID)

        for i = 1, guildMembers do
            local userID, _, _, playerStatus = GetGuildMemberInfo(guildID, i)

            if playerStatus ~= PLAYER_STATUS_OFFLINE and userID ~= myID then
                local _, _, zoneName, _, _, _, _, zoneId = GetGuildMemberCharacterInfo(guildID, i)
                addPlayerZone(self, zones, zoneId, zoneName, userID, "/esoui/art/menubar/gamepad/gp_playermenu_icon_character.dds", Nav.POI_GUILDMATE)
            end
        end
    end

    local friendCount = GetNumFriends()
    for i = 1, friendCount do
        local userID, _, playerStatus, secsSinceLogoff = GetFriendInfo(i)

        if playerStatus ~= PLAYER_STATUS_OFFLINE and secsSinceLogoff == 0 then
            local hasChar, _, zoneName, _, _, _, _, zoneId = GetFriendCharacterInfo(i)
            if hasChar then
                addPlayerZone(self, zones, zoneId, zoneName, userID, "/esoui/art/menubar/gamepad/gp_playermenu_icon_character.dds", Nav.POI_FRIEND)
            end
        end
    end
end

function Players:ClearPlayers()
    self.playerZones = nil
    self.players = nil
end

function Players:GetPlayerList()
    if self.players == nil then
        self:SetupPlayerZones()
    end

    local nodes = {}
    for userID, info in pairs(self.players) do
        table.insert(nodes, {
            name = userID,
            barename = userID:sub(2), -- remove '@' prefix
            zoneId = info.zoneId,
            zoneName = info.zoneName,
            icon = info.icon,
            suffix = info.zoneName,
            poiType = info.poiType,
            userID = userID,
            known = true
        })
    end

    return nodes
end

function Players:GetPlayerInZone(zoneId)
    if self.playerZones == nil then
        self:SetupPlayerZones()
    end

    local info = self.playerZones[zoneId]
    if info then
        return {
            name = info.zoneName,
            barename = Utils.bareName(info.zoneName),
            zoneId = zoneId,
            zoneName = info.zoneName,
            icon = info.icon,
            poiType = info.poiType,
            userID = info.userID,
            known = true
        }
    else
        return nil
    end
end

local function groupComparison(x, y)
    if x.isLeader and not y.isLeader then -- There can be only one
        return true
    end
    return (x.barename or x.name) < (y.barename or y.name)
end

function Players:GetGroupList()
    local list = {}

    local gCount = GetGroupSize()

    local player = string.lower(GetUnitName("player"))

    for i = 1, gCount do
        local unitTag = GetGroupUnitTagByIndex(i)
        if unitTag then
            local unitName = GetUnitName(unitTag)
            local zoneId = GetZoneId(GetUnitZoneIndex(unitTag))
            if CanJumpToPlayerInZone(zoneId) and IsUnitOnline(unitTag) and string.lower(unitName) ~= player then
                local zoneName = GetZoneNameById(zoneId)
                local isLeader = IsUnitGroupLeader(unitTag)
                local icon = isLeader and "/esoui/art/icons/mapkey/mapkey_groupleader.dds" or "/esoui/art/icons/mapkey/mapkey_groupmember.dds" --"/esoui/art/compass/groupleader.dds" or "/esoui/art/compass/groupmember.dds"
                table.insert(list, {
                    name = unitName, -- Character nickname
                    zoneId = zoneId,
                    zoneName = zoneName,
                    isLeader = isLeader,
                    --charName = GetUniqueNameForCharacter(unitName),
                    unitTag = unitTag, -- Format: group{index}
                    poiType = Nav.POI_GROUPMATE,
                    icon = icon,
                    suffix = zoneName,
                    known = true
                })
            end
        end
    end

    table.sort(list, groupComparison)

    return list
end

function Players:IsGroupLeader()
    return string.lower(GetUnitName("player")) == string.lower(GetGroupLeaderUnitTag())
end

Nav.Players = Players