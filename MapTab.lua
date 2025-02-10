local MT = Navigator_MapTab -- from XML
local Nav = Navigator
local Search = Nav.Search
local Utils = Nav.Utils

MT.filter = Nav.FILTER_NONE
MT.needsRefresh = false
MT.collapsedCategories = {}

function MT:queueRefresh()
    if not self.needsRefresh then
        self.needsRefresh = true
        if self.visible and not self.menuOpen then
            zo_callLater(function()
                if self.needsRefresh and self.visible and not self.menuOpen then
                    self:ImmediateRefresh()
                else
                    -- Nav.log("MT:queueRefresh: skipped")
                end
            end, 50)
            -- Nav.log("MT:queueRefresh: queued")
        else
            -- Nav.log("MT:queueRefresh: not queued")
        end
    end
end

function MT:ImmediateRefresh()
    -- Nav.log("MT:ImmediateRefresh")
    self:executeSearch(self.searchString, true)
    self.needsRefresh = false
end

function MT:layoutRow(rowControl, data, _)
	local name = data.name
    local tooltipText = data.tooltip
    local icon = data:GetIcon()
    local categoryId = data.dataEntry.categoryId

    local suffix = data:GetSuffix(categoryId ~= "bookmarks")
    if suffix ~= nil then
        local colour = ZO_ColorDef:New(data:GetSuffixColour())
        name = name .. " " .. colour:Colorize(suffix)
    end

	if icon ~= nil then
        rowControl.icon:SetColor(ZO_ColorDef.HexToFloats(data:GetIconColour()))
		rowControl.icon:SetTexture(icon)
		rowControl.icon:SetHidden(false)
    else
		rowControl.icon:SetHidden(true)
	end

    rowControl.cost:SetHidden(data.isFree)

    rowControl.keybind:SetHidden(not data.isSelected)
    rowControl.bg:SetHidden(not data.isSelected)
    if data.isSelected then
        rowControl.label:SetAnchor(TOPRIGHT, rowControl.keybind, TOPLEFT, -4, -1)
    else
        rowControl.label:SetAnchor(TOPRIGHT, rowControl, TOPRIGHT, -4, 0)
    end

	rowControl.label:SetText(name)

    rowControl.label:SetColor(ZO_ColorDef.HexToFloats(data:GetColour()))

    rowControl:SetHandler("OnMouseEnter", function(rc)
        if tooltipText then
            ZO_Tooltips_ShowTextTooltip(rc, LEFT, tooltipText)
        end
    end)
    rowControl:SetHandler("OnMouseExit", function(_)
        ZO_Tooltips_HideTextTooltip()
        rowControl.label:SetColor(ZO_ColorDef.HexToFloats(data:GetColour()))
    end)
end

function MT:showFilterControl(text)
    self.filterControl:SetHidden(false)
    self.filterControl:SetText("|u6:6::"..text.."|u")
    self.editControl:SetAnchor(TOPLEFT, self.filterControl, TOPRIGHT, 2, -1)
end

function MT:hideFilterControl()
    self.filterControl:SetHidden(true)
    self.editControl:SetAnchor(TOPLEFT, self.searchControl, TOPLEFT, 4, -1)
end

function MT:updateFilterControl()
    if self.filter == Nav.FILTER_NONE then
        self:hideFilterControl()
        return
    elseif self.filter == Nav.FILTER_PLAYERS then
        self:showFilterControl('Players')
    elseif self.filter == Nav.FILTER_HOUSES then
        self:showFilterControl('Houses')
    end
end

function MT:layoutCategoryRow(rowControl, data, _)
	rowControl.label:SetText(data.name)
end

function MT:layoutHintRow(rowControl, data, _)
	rowControl.label:SetText(data.hint or "-")
end

local function weightComparison(x, y)
    if x.weight ~= y.weight then
        return x.weight > y.weight
    end
	return Utils.SortName(x) < Utils.SortName(y)
end

local function nameComparison(x, y)
	return Utils.SortName(x) < Utils.SortName(y)
end

local function addDeveloperTooltip(nodeData)
    local items = {
        "bareName='" .. (nodeData.barename or '-').."'",
        "searchName='" .. Utils.SearchName(nodeData.originalName or nodeData.name or '-').."'",
        "sortName='" .. Utils.SortName(nodeData).."'",
        "weight="..(nodeData.weight or 0)
    }
    if nodeData.nodeIndex then
        table.insert(items, "nodeIndex="..(nodeData.nodeIndex or "-"))
    end
    if nodeData.zoneId then
        table.insert(items, "zoneId="..(nodeData.zoneId or "-"))
    end
    if nodeData.tooltip then
        table.insert(items, 1, nodeData.tooltip)
    end

    nodeData.tooltip = table.concat(items, "; ")
end

local function buildCategoryHeader(scrollData, id, title, collapsed)
    title = tonumber(title) ~= nil and GetString(title) or title
    local recentEntry = ZO_ScrollList_CreateDataEntry(collapsed and 2 or 0, { id = id, name = title })
    table.insert(scrollData, recentEntry)
end

local function buildResult(listEntry, currentNodeIndex, isSelected)
    local nodeData = Utils.shallowCopy(listEntry)
    nodeData.isSelected = isSelected
    nodeData.dataIndex = currentNodeIndex

    -- Nav.log("%s: traders %d", nodeData.barename, nodeData.traders or 0)

    if not nodeData.known and nodeData.nodeIndex then
        nodeData.tooltip = GetString(NAVIGATOR_NOT_KNOWN)
    end

    nodeData.isFree = true
    if Nav.isRecall and nodeData.known and nodeData.nodeIndex then
        local _, timeLeft = GetRecallCooldown()

        if timeLeft == 0 then
            local currencyType = CURT_MONEY
            local currencyAmount = GetRecallCost(nodeData.nodeIndex)
            if currencyAmount > 0 then
                local formatType = ZO_CURRENCY_FORMAT_AMOUNT_ICON
                local currencyString = zo_strformat(SI_NUMBER_FORMAT, ZO_Currency_FormatKeyboard(currencyType, currencyAmount, formatType))
                nodeData.tooltip = string.format(GetString(SI_TOOLTIP_RECALL_COST) .. "%s", currencyString)
                nodeData.isFree = false
            end
        end
    end

    if Nav.isDeveloper then
        addDeveloperTooltip(nodeData)
    end

    return nodeData
end

local function buildList(scrollData, id, title, list, defaultString)
    local collapsed = MT.collapsedCategories[id] and true or false
    local hasFocus = MT.editControl:HasFocus()

    buildCategoryHeader(scrollData, id, title, collapsed)

    if collapsed then
        return
    elseif #list == 0 and defaultString then
        list = {{ hint = GetString(defaultString) }}
    end

    local currentNodeIndex = MT.resultCount

    for i = 1, #list do
        if list[i].hint then
            local entry = ZO_ScrollList_CreateDataEntry(3, { hint = list[i].hint })
            table.insert(scrollData, entry)
        else
            local isSelected = hasFocus and list[i].known and (currentNodeIndex == Nav.targetNode)
            local nodeData = buildResult(list[i], currentNodeIndex, isSelected)

            local entry = ZO_ScrollList_CreateDataEntry(1, nodeData, id)
            table.insert(scrollData, entry)

            currentNodeIndex = currentNodeIndex + 1
        end
    end

    MT.resultCount = currentNodeIndex
end

function MT:UpdateEditDefaultText()
	local searchString = self.editControl:GetText()
	if searchString == "" then
		-- reinstate default text
        local openTabBinding = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction("NAVIGATOR_OPENTAB") or '-'
        local s = zo_strformat(self.editControl:HasFocus() and GetString(NAVIGATOR_SEARCH) or GetString(NAVIGATOR_SEARCH_KEYPRESS),
            openTabBinding)
		ZO_EditDefaultText_Initialize(self.editControl, s)
	else
		-- remove default text
		ZO_EditDefaultText_Disable(self.editControl)
	end
end

function MT:buildScrollList(keepScrollPosition)
    local scrollPosition = 0
    if keepScrollPosition then
        scrollPosition = ZO_ScrollList_GetScrollValue(self.listControl)
        -- Nav.log("MT:buildScrollList: pos=%d", scrollPosition)
    end

	ZO_ScrollList_Clear(self.listControl)

	self:UpdateEditDefaultText()

    local scrollData = ZO_ScrollList_GetDataList(self.listControl)

    local isSearching = #Nav.results > 0 or (self.searchString and self.searchString ~= "")
    MT.resultCount = 0
    if isSearching then
        buildList(scrollData, "results", NAVIGATOR_CATEGORY_RESULTS, Nav.results, NAVIGATOR_HINT_NORESULTS)
    else
        local group = Nav.Players:GetGroupList()
        if #group > 0 then
            buildList(scrollData, "group", SI_MAIN_MENU_GROUP, group)
        end

        local bookmarks = Nav.Bookmarks:getBookmarks()
        buildList(scrollData, "bookmarks", NAVIGATOR_CATEGORY_BOOKMARKS, bookmarks, NAVIGATOR_HINT_NOBOOKMARKS)

        local recentCount = Nav.saved.recentsCount
        local recents = Nav.Recents:getRecents(recentCount)
        buildList(scrollData, "recents", NAVIGATOR_CATEGORY_RECENT, recents, NAVIGATOR_HINT_NORECENTS)

        local zone = Nav.Locations:getCurrentMapZone()
        if zone and zone.zoneId == Nav.ZONE_TAMRIEL then
            local list = Nav.Locations:getZoneList()
            table.sort(list, nameComparison)
            buildList(scrollData, "zones", NAVIGATOR_CATEGORY_ZONES, list)
        elseif zone then
            local list = Nav.Locations:getKnownNodes(zone.zoneId)

            if Nav.isRecall and zone.zoneId ~= Nav.ZONE_CYRODIIL then
                local node = Nav.JumpToZoneNode:New(zone)
                local playerInfo = Nav.Players:GetPlayerInZone(zone.zoneId)
                if playerInfo then
                    node.name = zo_strformat(GetString(NAVIGATOR_TRAVEL_TO_ZONE), zone.name)
                    node.known = true
                else
                    node.name = GetString(NAVIGATOR_NO_TRAVEL_PLAYER)
                    node.known = false
                end
                node.weight = 10.0 -- list this first!
                table.insert(list, node)
            end

            table.sort(list, weightComparison)
            buildList(scrollData, "results", zone.name, list)
        end
    end

	ZO_ScrollList_Commit(self.listControl)

    if keepScrollPosition then
        ZO_ScrollList_ScrollAbsolute(self.listControl, scrollPosition)
    elseif MT.resultCount > 0 then
        -- FIXME: this doesn't account for the headings
        ZO_ScrollList_ScrollDataIntoView(self.listControl, Nav.targetNode + 1, nil, true)
    end
end

function MT:executeSearch(searchString, keepTargetNode)
	local results

    MT.searchString = searchString

    results = Search:Run(searchString or "", MT.filter)

	Nav.results = results
    if not keepTargetNode or Nav.targetNode >= (MT.resultCount or 0) then
        -- Nav.log("executeSearch: reset targetNode keep=%d, oldTarget=%d, count=%d", keepTargetNode and 1 or 0, Nav.targetNode, (MT.resultCount or 0))
    	Nav.targetNode = 0
        keepTargetNode = false
    end

	MT:buildScrollList(keepTargetNode)
    MT:updateFilterControl()
end

function MT:getTargetDataIndex()
	local currentNodeIndex = 0

    local scrollData = ZO_ScrollList_GetDataList(self.listControl)

    for i = 1, #scrollData do
        if scrollData[i].typeId == 1 then -- wayshrine row
            if currentNodeIndex == Nav.targetNode then
                return i
            end
            currentNodeIndex = currentNodeIndex + 1
        end
    end

	return nil
end

function MT:getTargetNode()
    local i = self:getTargetDataIndex()

    if i then
        local scrollData = ZO_ScrollList_GetDataList(self.listControl)
        return scrollData[i].data
    end

    return nil
end

function MT:getNextCategoryFirstIndex()
    local scrollData = ZO_ScrollList_GetDataList(self.listControl)

    if #scrollData <= 2 then
        return -- nothing to find!
    end

    local currentIndex = self:getTargetDataIndex()
    local currentNodeIndex = Nav.targetNode + 1

    local i = currentIndex + 1
    local foundCategory = false

    while true do
        if scrollData[i].typeId == 1 then -- wayshrine row
            if (foundCategory and scrollData[i].data.known) or i == currentIndex then
                -- return the first entry after the category header
                -- Nav.log("Index %d node %d is result - returning", i, currentNodeIndex)
                return currentNodeIndex
            end
            -- Nav.log("Index %d node %d is result - incrementing", i, currentNodeIndex)
            currentNodeIndex = currentNodeIndex + 1
        elseif scrollData[i].typeId == 0 then -- category header
            -- Nav.log("Index %d node %d is category", i, currentNodeIndex)
            foundCategory = true
        end

        if i >= #scrollData then
            -- Nav.log("Wrapping at index %d node %d", i, currentNodeIndex)
            i = 1
            currentNodeIndex = 0
        else
            i = i + 1
        end
    end
end

function MT:init()
	Nav.log("MapTab:init")
end

function MT:onTextChanged(editbox)
	local searchString = string.lower(editbox:GetText())
    if searchString == "z:" then
        local mapId = Nav.Locations.GetMapIdByZoneId(2) -- Tamriel
        Nav.log("MT:onTextChanged mapId %d", mapId or -1)
        -- if mapId then
        WORLD_MAP_MANAGER:SetMapById(mapId)
        -- end
        MT.filter = Nav.FILTER_NONE
        editbox:SetText("")
        editbox.editTextChanged = false
        searchString = ""
    elseif searchString == "h:" then
        self.filter = Nav.FILTER_HOUSES
        editbox:SetText("")
        editbox.editTextChanged = false
        searchString = ""
    elseif searchString == '@' or searchString == "p:" then
        self.filter = Nav.FILTER_PLAYERS
        editbox.editTextChanged = false
        editbox:SetText("")
        searchString = ""
    else
        self.editControl.editTextChanged = true
    end

    self:executeSearch(searchString)
end

function MT:selectCurrentResult()
	local data = self:getTargetNode()
	if data then
		self:selectResult(nil, data, 1)
	end
end

function MT:nextResult()
    local known = false
    local startNode = Nav.targetNode
    repeat
    	Nav.targetNode = (Nav.targetNode + 1) % MT.resultCount
        local node = self:getTargetNode()
        if node and node.known then
            known = true
        end
    until known or Nav.targetNode == startNode
	self:buildScrollList()
end

function MT:previousResult()
    local known = false
    local startNode = Nav.targetNode
    repeat
        Nav.targetNode = Nav.targetNode - 1
        if Nav.targetNode < 0 then
            Nav.targetNode = MT.resultCount - 1
        end
        local node = self:getTargetNode()
        if node and node.known then
            known = true
        end
    until known or Nav.targetNode == startNode
	self:buildScrollList()
end

function MT:nextCategory()
    Nav.targetNode = self:getNextCategoryFirstIndex()
	self:buildScrollList()
end

function MT:previousCategory()
    -- Nav.targetNode = self:getPreviousCategoryFirstIndex()
	-- self:buildScrollList()
end

function MT:resetFilter()
	Nav.log("MT.resetFilter")
    self.filter = Nav.FILTER_NONE
    self:hideFilterControl()
    self:ImmediateRefresh()
	ZO_ScrollList_ResetToTop(self.listControl)
end

function MT:resetSearch()
	Nav.log("MT.resetSearch")
	self.editControl:SetText("")
    self.filter = Nav.FILTER_NONE
    self:hideFilterControl()
    self:ImmediateRefresh()

	--ZO_EditDefaultText_Initialize(editbox, GetString(FASTER_TRAVEL_WAYSHRINES_SEARCH))
	--ResetVisibility(listcontrol)
	ZO_ScrollList_ResetToTop(self.listControl)
end

local function showWayshrineMenu(owner, data)
	ClearMenu()
    local bookmarks = Nav.Bookmarks

    if data.AddMenuItems then
        data:AddMenuItems()
    end

    if data.isBookmark then
        AddMenuItem(GetString(NAVIGATOR_MENU_REMOVEBOOKMARK), function()
            bookmarks:remove(data)
            MT.menuOpen = false
            zo_callLater(function() MT:ImmediateRefresh() end, 10)
        end)
    end

    MT.menuOpen = true
	ShowMenu(owner)
    SetMenuHiddenCallback(function()
        Nav.log("SetMenuHiddenCallback: Menu hidden")
        MT.menuOpen = false
        if MT.needsRefresh then
            MT:ImmediateRefresh()
        end
    end)
end

local function showGroupMenu(owner, _)
    ClearMenu()

    AddMenuItem(GetString(SI_GROUP_LEAVE), function()
        ZO_Dialogs_ShowDialog("GROUP_LEAVE_DIALOG")
        MT.menuOpen = false
        MT:ImmediateRefresh()
    end)

    MT.menuOpen = true
    ShowMenu(owner)
    SetMenuHiddenCallback(function()
        Nav.log("SetMenuHiddenCallback: Menu hidden")
        MT.menuOpen = false
        if MT.needsRefresh then
            MT:ImmediateRefresh()
        end
    end)
end

function MT:selectResult(control, data, mouseButton, isDoubleClick)
    if mouseButton == 1 then
        if data.OnClick then
            Nav.log("OnClick %s", data.name or "-")
            data:OnClick(isDoubleClick)
        end
    elseif mouseButton == 2 then
        showWayshrineMenu(control, data)
    else
        Nav.log("selectResult: unhandled; poiType=%d zoneId=%d", data.poiType or -1, data.zoneId or -1)
    end
end

function MT:RowMouseUp(control, mouseButton, isDoubleClick)
    local data = ZO_ScrollList_GetData(control)
    self:selectResult(control, data, mouseButton, isDoubleClick)
end

function MT:CategoryRowMouseUp(control, mouseButton)
    --Nav.log("MT:CategoryRowMouseUp %d %s", mouseButton, )
    local data = ZO_ScrollList_GetData(control)
    if mouseButton == 2 then
        if data.id == "group" then
            showGroupMenu(control, data)
        end
    else
        Nav.log("Toggling category %s", data.id)
        self.collapsedCategories[data.id] = not self.collapsedCategories[data.id]
        MT:buildScrollList(true)
        MT:updateFilterControl()
    end
end

function MT:IsViewingInitialZone()
    local zone = Nav.Locations:getCurrentMapZone()
    return not zone or zone.zoneId == Nav.initialMapZoneId
end

function MT:OnMapChanged()
    local mapId = GetCurrentMapId()
    if Nav.mapVisible and mapId ~= self.currentMapId then
        self.currentMapId = mapId
        local zone = Nav.Locations:getCurrentMapZone()
        Nav.log("OnMapChanged: now zoneId=%d mapId=%d initial=%d", zone and zone.zoneId or 0, mapId or 0, Nav.initialMapZoneId or 0)
        if zone and zone.zoneId <= 2 then
            self.collapsedCategories = { bookmarks = true, recents = true }
        else
            self.collapsedCategories = {}
        end
        Nav.targetNode = 0
        self.filter = Nav.FILTER_NONE
        self:updateFilterControl()
        self.editControl:SetText("")
        -- end
        self:executeSearch("")
    end
end

Nav.MapTab = MT