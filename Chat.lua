local MS = MapSearch
local Chat = MS.Chat or {
    lsc = nil,
    AutoCompleteProvider = nil
}
local logger = MS.logger

function Chat:Init()
    self.lsc = LibSlashCommander
    if not self.lsc then
        return
    end

    local command = self.lsc:Register()
    command:AddAlias("/tp") -- TODO: Make this configurable
    command:SetCallback(function(input) self:TP(input) end)
    command:SetDescription("Map Search: Teleports to the given zone")

    ---@class Chat.AutoCompleteProvider
    Chat.AutoCompleteProvider = LibSlashCommander.AutoCompleteProvider:Subclass()

    function Chat.AutoCompleteProvider:New()
        return Chat.lsc.AutoCompleteProvider.New(self)
    end

    function Chat.AutoCompleteProvider:GetResultList()
        local zoneList = MS.Locations:getZoneList()
        local list = {}
        for i = 1, #zoneList do
            list[zoneList[i].name] = zoneList[i].name
        end
        logger:Info("Chat.AutoCompleteProvider:GetResultList: "..#list)
        return list
    end

    command:SetAutoComplete(self.AutoCompleteProvider:New())

    command.GetAutoCompleteResults = function(self, text)
        local results = {}

        local searchResult = MS.Search.run(text, {FILTER_TYPE_NONE})

        local count = (#searchResult <= 1) and #searchResult or 1
        for i = 1, count do
            local listEntry = searchResult[i]
            results[listEntry.name] = listEntry.name
        end

        return results
    end

    self.command = command
end

function Chat:TP(text)
    local MT = MS.MapTab
    local Locs = MS.Locations

    local searchResult = MS.Search.run(text, {FILTER_TYPE_NONE})
    if #searchResult == 0 then
        return
    end

    local data = searchResult[1]
    local zoneId = data.zoneId

    if data.nodeIndex or data.userID then
        MT.jumpToNode(data)
    end

    local node = Locs:getPlayerInZone(zoneId)
    if not node then
        return
    end

    -- local userID, poiType, zoneId, zoneName = node.userID, node.poiType, node.zoneId, node.zoneName

    CHAT_SYSTEM:AddMessage("Jumping to "..node.zoneName.." via "..node.userID)
    SCENE_MANAGER:Hide("worldMap")

    if node.poiType == POI_TYPE_FRIEND then
        JumpToFriend(node.userID)
    elseif node.poiType == POI_TYPE_GUILDMATE then
        JumpToGuildMember(node.userID)
    end

end

MS.Chat = Chat