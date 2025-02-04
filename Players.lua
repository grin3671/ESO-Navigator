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

local function addPlayerZone(self, zones, zoneId, zoneName, userID, icon, poiType, charName)
    if zones[zoneId] and CanJumpToPlayerInZone(zoneId) then
        local zoneInfo = {
            zoneId = zoneId,
            zoneName = Utils.FormatSimpleName(zoneName),
            userID = userID,
            icon = icon,
            poiType = poiType
        }

        self.players[userID] = zoneInfo
        if charName then
            charName = zo_strformat("<<!AC:1>>", charName)
            zoneInfo.charName = charName
        end
    end
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
                    addPlayerZone(self, zones, zoneId, zoneName, userID, "/esoui/art/menubar/gamepad/gp_playermenu_icon_character.dds", Nav.POI_GUILDMATE, charName)
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
                addPlayerZone(self, zones, zoneId, zoneName, userID, "/esoui/art/menubar/gamepad/gp_playermenu_icon_character.dds", Nav.POI_FRIEND, charName)
            end
        end
    end
end

function Players:ClearPlayers()
    self.players = nil
end

function Players:GetPlayerList()
    if self.players == nil then
        self:SetupPlayers()
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
    if self.players == nil then
        self:SetupPlayers()
    end

    for _, player in pairs(self.players) do
        if player.zoneId == zoneId then
            return {
                name = player.zoneName,
                barename = Utils.bareName(player.zoneName),
                zoneId = zoneId,
                zoneName = player.zoneName,
                icon = player.icon,
                poiType = player.poiType,
                userID = player.userID,
                known = true,
                weight = player.weight,
                canJumpToPlayer = player.canJumpToPlayer
            }
        end
    end
    return nil
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
            local displayName = GetUnitDisplayName(unitTag) or '"'..unitName..'"'
            local zoneId = GetZoneId(GetUnitZoneIndex(unitTag))
            if CanJumpToPlayerInZone(zoneId) and IsUnitOnline(unitTag) and string.lower(unitName) ~= player then
                local zoneName = GetZoneNameById(zoneId)
                local isLeader = IsUnitGroupLeader(unitTag)
                local icon = isLeader and "/esoui/art/icons/mapkey/mapkey_groupleader.dds" or "/esoui/art/icons/mapkey/mapkey_groupmember.dds" --"/esoui/art/compass/groupleader.dds" or "/esoui/art/compass/groupmember.dds"
                table.insert(list, {
                    name = displayName, -- Character nickname
                    zoneId = zoneId,
                    zoneName = zoneName,
                    isLeader = isLeader,
                    --charName = GetUniqueNameForCharacter(unitName),
                    unitTag = unitTag, -- Format: group{index}
                    poiType = Nav.POI_GROUPMATE,
                    icon = icon,
                    suffix = zoneName,
                    known = true,
                    weight = isLeader and 1.2 or 1.1
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