local mkstr = function(id, str)
    SafeAddString(_G[id], str, 1)
end


-- Controls menu entry (opens the Navigator tab on the World Map)
-- mkstr("SI_BINDING_NAME_NAVIGATOR_SEARCH", "Open on World Map")







-- Edit box hint text (<<1>> is replaced by 'Tab')
mkstr("NAVIGATOR_SEARCH_KEYPRESS", "Rechercher (<<1>>)") -- 1:Keyname
mkstr("NAVIGATOR_SEARCH","Rechercher des lieux / zones / @joueurs")

-- Category Headings
mkstr("NAVIGATOR_CATEGORY_BOOKMARKS", "Signets")
mkstr("NAVIGATOR_CATEGORY_RECENT", "Récents")
mkstr("NAVIGATOR_CATEGORY_ZONES", "Zones")



-- Result hints
--mkstr("NAVIGATOR_HINT_NORESULTS", "No results found")
--mkstr("NAVIGATOR_HINT_NORECENTS", "Destinations that you travel to will automatically appear here")
--mkstr("NAVIGATOR_HINT_NOBOOKMARKS", "Right click a destination to create (or delete) a bookmark for it")

-- Enter key label (keep it short!)
mkstr("NAVIGATOR_KEY_ENTER", "Entrée")






-- Tooltips
-- mkstr("NAVIGATOR_NOT_KNOWN", "Not known by this character") -- Location not known

-- Actions items
mkstr("NAVIGATOR_TRAVEL_TO_ZONE", "Se rendre à <<1>>") -- 1:Zone
--mkstr("NAVIGATOR_MENU_ADDBOOKMARK", "Add Bookmark")
--mkstr("NAVIGATOR_MENU_ADDHOUSEBOOKMARK", "Add Primary Residence Bookmark")
--mkstr("NAVIGATOR_MENU_REMOVEBOOKMARK", "Remove Bookmark")



-- Status / error messages
--mkstr("NAVIGATOR_NO_TRAVEL_PLAYER", "No players to travel to")
--mkstr("NAVIGATOR_CANNOT_TRAVEL_TO_PLAYER", "Unable to travel to player <<1>>") -- 1:player
--mkstr("NAVIGATOR_NO_PLAYER_IN_ZONE", "Failed to find a player to travel to in <<1>>") -- 1:zone
--mkstr("NAVIGATOR_PLAYER_NOT_IN_ZONE", "<<1>> is no longer in <<2>>") -- 1:player 2:zone
--mkstr("NAVIGATOR_TRAVELING_TO_ZONE_VIA_PLAYER", "Traveling to <<1>> via <<2>>") -- 1:player 2:zone

-- Chat slash command
-- mkstr("NAVIGATOR_SLASH_DESCRIPTION", "Navigator: Teleports to the given zone, wayshrine, house or player")

-- Custom location names
--mkstr("NAVIGATOR_LOCATION_OBLIVIONPORTAL", "Oblivion Portal")
