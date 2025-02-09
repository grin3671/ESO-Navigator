local Nav = Navigator
local Recents = Nav.Recents or {
    nodes = {},
    maxStored = 20
}
local FTrecent

function Recents:init()
    self.nodes = Nav.saved.recentNodes or {}

    if _G["FasterTravel"] ~= nil and
       _G["FasterTravel"].settings ~= nil and
       _G["FasterTravel"].settings.recentsEnabled then
        Nav.log("FasterTravel is active")
        FTrecent = _G["FasterTravel"].settings.recent
        -- Nav.log("%s", FT.settings.recent)
    else
        self:addTravelDialogCallbacks()
        self:hook(true)
    end
end

function Recents:insert(nodeIndex)
    if nodeIndex == 211 or nodeIndex == 212 then
        -- Always store The Harborage as index 210
        nodeIndex = 210
    end

    local node = Nav.Locations:GetNode(nodeIndex)
    if node and node.zoneId == Nav.ZONE_CYRODIIL and node.poiType == Nav.POI_WAYSHRINE then
        Nav.log("Recents:insert("..nodeIndex..") - not adding Cyrodiil wayshrine")
        return
    end

    for i = 1, #self.nodes do
        if self.nodes[i] == nodeIndex then
            table.remove(self.nodes, i)
            Nav.log("Recents:insert("..nodeIndex..") removed existing entry #"..i)
            break
        end
    end
    if #self.nodes >= self.maxStored then
        table.remove(self.nodes)
        Nav.log("Recents:insert("..nodeIndex..") removed overflow entry #"..#self.nodes)
    end
    table.insert(self.nodes, 1, nodeIndex)
    Nav.log("Recents:insert("..nodeIndex..")")
    self:save()
end

function Recents:save()
    Nav.saved.recentNodes = self.nodes
end

function Recents:getRecents(count)
    local results = {}
    --local nodeMap = Nav.Locations:getNodeMap()

    --if nodeMap ~= nil then
        for i = 1, #self.nodes do
            local nodeIndex = self.nodes[i] or 0 -- nodeMap[self.nodes[i]].nodeIndex or 0
            if Nav.Locations:IsHarborage(nodeIndex) then
                nodeIndex = Nav.Locations:GetHarborage()
            end
            local node = Nav.Locations:GetNode(nodeIndex, true)
            node.known = Nav.Locations:isKnownNode(nodeIndex)
            node.bookmarked = Nav.Bookmarks:contains(node)
            table.insert(results, node)

            if #results >= count then
                return results
            end
        end
    --end

    return results
end

function Recents:onPlayerActivated()
    if FTrecent ~= nil and #FTrecent >= 1 then
        -- Pull the most recent nodeIndex from FasterTravel
        local nodeIndex = FTrecent[1].nodeIndex
        Nav.log("Recents:onPlayerActivated: adding recent from FasterTravel: "..nodeIndex)
        self:insert(nodeIndex)
    end
end

local travelDialogs = {
    FAST_TRAVEL_CONFIRM = {},
    TRAVEL_TO_HOUSE_CONFIRM = {},
    RECALL_CONFIRM = {}
}

-- replacement callbacks factory
local function MyCallbackFactory(name)
    return function(dialog)
        Nav.log("Callback %s", name)
        local node = dialog.data
        if node.nodeIndex then -- is nil when travelling to house since U29
            Recents:insert(node.nodeIndex)
        end
        if travelDialogs[name].saved_callback then -- call the original callback if not nil
            travelDialogs[name].saved_callback(dialog)
        end
    end
end

function Recents.addTravelDialogCallbacks()
	-- find the original dialogs for RECALL_CONFIRM and FAST_TRAVEL_CONFIRM
	for name, data in pairs(travelDialogs) do
		-- extract "Confirm" callbacks if any and save them
		if 	ESO_Dialogs[name] and
			ESO_Dialogs[name].buttons and
			ESO_Dialogs[name].buttons[1] then 
				data.saved_callback = ESO_Dialogs[name].buttons[1].callback -- may be nil
                Nav.log("Saved callback for travel dialog '"..name.."'")
        end
		-- create new callbacks
        Nav.log("Adding callback for travel dialog '"..name.."'")
		data.my_callback = MyCallbackFactory(name)
	end
end

Recents.__Hook_Checker = function(name, node, _, ...)
    Nav.log("HookChecker: %s", name)
    if travelDialogs[name] then
        Nav.log("Hook checkpoint TRAVEL")
        -- replace callbacks
        for _, data in pairs(travelDialogs) do
            if 	ESO_Dialogs[name] and 
                ESO_Dialogs[name].buttons and
                ESO_Dialogs[name].buttons[1] then 
                    if ESO_Dialogs[name].buttons[1].callback ~= data.my_callback then
                        if ESO_Dialogs[name].buttons[1].callback == data.saved_callback then
                            ESO_Dialogs[name].buttons[1].callback = data.my_callback
                        else
                            Nav.log("Something nasty going on - who else modifies %s dialog?!", name)
                        end
                    end
            else --[[
                Bandits UI has an option to turn off fast travel confirmations
                which sets ESO_Dialogs[name].buttons to nil 
                but if it is in use, all travels are autoconfirmed!
                so we can add the wayshrine to Recents without further consideration
                ]]--
                if node.nodeIndex then 
                    Recents:insert(node.nodeIndex)
                end
            end
        end
    else
        Nav.log("Hook checkpoint NON-TRAVEL")
        -- restore original callbacks
        for _, data in pairs(travelDialogs) do
            if 	ESO_Dialogs[name] and 
                ESO_Dialogs[name].buttons and
                ESO_Dialogs[name].buttons[1] then 
                    if ESO_Dialogs[name].buttons[1].callback ~= data.saved_callback then
                        if ESO_Dialogs[name].buttons[1].callback == data.my_callback then
                            ESO_Dialogs[name].buttons[1].callback = data.saved_callback
                        else
                            Nav.log("Something nasty going on - who else modifies %s dialog?!", name)
                        end
                    end
            end
        end
    end
    return false -- true == I've done everything, don't call ZO_Dialogs_ShowPlatformDialog
end

function Recents:hook(enabled)
    if enabled then
        ZO_PreHook("ZO_Dialogs_ShowPlatformDialog", self.__Hook_Checker)
    else
        ZO_PreHook("ZO_Dialogs_ShowPlatformDialog", function() return false end)
    end
end

Nav.Recents = Recents