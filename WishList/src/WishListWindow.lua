WishList = WishList or {}
local WL = WishList

------------------------------------------------
--- WishList Window -> ZO_SortFilterList
------------------------------------------------
WishListWindow = ZO_SortFilterList:Subclass()

function WishListWindow:New( control )
	local list = ZO_SortFilterList.New(self, control)
	list.frame = control
	list:Setup()
	return(list)
end

function WishListWindow:Setup( )
--d("[WishListWindow:Setup]")
    WL.comingFromSortScrollListSetupFunction = true
	--Dialogs
	WL.WishListWindowAddItemInitialize(WishListAddItemDialog)
    WL.WishListWindowRemoveItemInitialize(WishListRemoveItemDialog)
    WL.WishListWindowReloadItemsInitialize(WishListReloadItemsDialog)
    WL.WishListWindowRemoveAllItemsInitialize(WishListRemoveAllItemsDialog)
    WL.WishListWindowChooseCharInitialize(WishListChooseCharDialog)
    WL.WishListWindowClearHistoryInitialize(WishListClearHistoryDialog)
    WL.WishListWindowChangeQualityInitialize(WishListChangeQualityDialog)

	--Scroll UI
	ZO_ScrollList_AddDataType(self.list, WISHLIST_DATA, "WishListRow", 30, function(control, data)
        self:SetupItemRow(control, data)
    end)
	ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
	self:SetAlternateRowBackgrounds(true)

	self.masterList = { }

    --Build the sortkeys depending on the settings
    --self:BuildSortKeys() --> Will be called internally in "self.sortHeaderGroup:SelectAndResetSortForKey"
	self.currentSortKey = "name"
	self.currentSortOrder = ZO_SORT_ORDER_UP
	self.sortHeaderGroup:SelectAndResetSortForKey(self.currentSortKey) -- Will call "SortScrollList" internally
	--The sort function
    self.sortFunction = function( listEntry1, listEntry2 )
        if     self.currentSortKey == nil or self.sortKeys[self.currentSortKey] == nil
            or listEntry1.data == nil or listEntry1.data[self.currentSortKey] == nil
            or listEntry2.data == nil or listEntry2.data[self.currentSortKey] == nil then
            return nil
        end
        return(ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, self.sortKeys, self.currentSortOrder))
	end
	self.searchDrop = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("SearchDrop"))
    WL.initializeSearchDropdown(self, WISHLIST_TAB_SEARCH, "set")
    --Character/toon dropdown box
    WL.charsData = {}
    WL.charsData = WL.buildCharsDropEntries()
    self.charsDrop = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("CharsDrop"))

    WL.initializeSearchDropdown(self, WISHLIST_TAB_WISHLIST, "char")
    --Search box and search functions
	self.searchBox = self.frame:GetNamedChild("SearchBox")
	self.searchBox:SetHandler("OnTextChanged", function() self:RefreshFilters() end)
	self.search = ZO_StringSearch:New()
	self.search:AddProcessor(WL.sortType, function(stringSearch, data, searchTerm, cache)
        return(self:ProcessItemEntry(stringSearch, data, searchTerm, cache))
    end)
    --Sort headers
	self.headers = self.frame:GetNamedChild("Headers")
    self.headerDate = self.headers:GetNamedChild("DateTime")
	self.headerArmorOrWeaponType = self.headers:GetNamedChild("ArmorOrWeaponType")
	self.headerSlot = self.headers:GetNamedChild("Slot")
	self.headerTrait = self.headers:GetNamedChild("Trait")
    self.headerQuality = self.headers:GetNamedChild("Quality")
    self.headerUsername = self.headers:GetNamedChild("UserName")
    self.headerLocality = self.headers:GetNamedChild("Locality")

	--No Sets Loaded UI
	self.labelNoSets = self.frame:GetNamedChild("labelNoSets")
	self.labelNoSets:SetText(GetString(WISHLIST_NO_SETS_LOADED))

	self.buttonLoadSets = self.frame:GetNamedChild("buttonLoadSets")
	self.buttonLoadSets:SetText(GetString(WISHLIST_LOAD_SETS))

	--Loading Sets UI
	self.labelLoadingSets = self.frame:GetNamedChild("labelLoadingSets")
	self.labelLoadingSets:SetText(zo_strformat(GetString(WISHLIST_SETS_LOADED), WL.accData.setCount))

    --Add the WishList scene
	WL.scene = ZO_Scene:New(WISHLIST_SCENE_NAME, SCENE_MANAGER)
	WL.scene:AddFragment(ZO_SetTitleFragment:New(WISHLIST_TITLE))
	WL.scene:AddFragment(ZO_FadeSceneFragment:New(WishListFrame))
	WL.scene:AddFragment(TITLE_FRAGMENT)
	WL.scene:AddFragment(RIGHT_BG_FRAGMENT)
	WL.scene:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL)
	WL.scene:AddFragment(CODEX_WINDOW_SOUNDS)
	WL.scene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
	WL.scene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)

    --Build initial masterlist via self:BuildMasterList()
--d("[WL.Setup] RefreshData > BuildMasterList ???")
    self:RefreshData()
end

local function resetSortGroupHeader(currentTab)
--d("[WL.resetSortGroupHeader]")
    if WL.window.sortHeaderGroup then
        local saveData = WL.data
        local sortHeaderKey = saveData.sortKey[currentTab] or "name"
        local sortOrder = saveData.sortOrder[currentTab]

        WL.window.currentSortKey = sortHeaderKey
        WL.window.currentSortOrder = sortOrder
        WL.window.sortHeaderGroup:SelectAndResetSortForKey(sortHeaderKey)
        --Select the sort header again to invert the sort order, if last sort order was inverted
        if sortOrder == ZO_SORT_ORDER_DOWN then
            WL.window.sortHeaderGroup:SelectHeaderByKey(sortHeaderKey)
        end
    end
end

function WL.saveSortGroupHeader(currentTab)
--d("[WL.saveSortGroupHeader]")
    if WL.window then
        local saveData = WL.data
        saveData.sortKey[currentTab]    = WL.window.currentSortKey
        saveData.sortOrder[currentTab]  = WL.window.currentSortOrder
    end
end

--Update the title of a scene's fragment with a new text
local function WLW_UpdateSceneFragmentTitle(sceneName, fragment, childName, newTitle)
    childName = childName or "Label"
    if sceneName == nil or fragment == nil or newTitle == nil then return false end
    local sm = SCENE_MANAGER
    if not sm then return false end
    local currentScene = sm.currentScene
    local currentSceneName = currentScene.name
    if not currentScene or not currentSceneName or not currentSceneName == sceneName or not currentScene.fragments then return end
    for _, fragmentInCurrentScene in ipairs(currentScene.fragments) do
        if fragmentInCurrentScene == fragment then
            if fragmentInCurrentScene then
                local fragmentCtrl = fragmentInCurrentScene.control
                if fragmentCtrl then
                    local fragmentCtrlChildLabel = fragmentCtrl:GetNamedChild(childName)
                    if fragmentCtrlChildLabel and fragmentCtrlChildLabel.SetText then
                        fragmentCtrlChildLabel:SetText(newTitle)
                    end
                end
            end
            return true
        end
    end
    return false
end

function WishListWindow:UpdateUI(state)
	WL.CurrentState = state
--d("[WishListWindow:UpdateUI] state: " ..tostring(state) .. ", currentTab: " ..tostring(WL.CurrentTab))

------------------------------------------------------------------------------------------------------------------------
    --SEARCH tab
	if WL.CurrentTab == WISHLIST_TAB_SEARCH then
		--Set the texture of the search button to "pressed"
        local normalSearchTexture = "/esoui/art/menubar/gamepad/gp_playermenu_icon_activityfinder.dds"
        local normalListTexture = "/esoui/art/journal/journal_tabicon_cadwell_up.dds"
        local normalHistoryTexture = "/esoui/art/guild/tabicon_history_up.dds"
        WishListFrameTabSearch:SetNormalTexture(normalSearchTexture)
        WishListFrameTabList:SetNormalTexture(normalListTexture)
        WishListFrameTabHistory:SetNormalTexture(normalHistoryTexture)

--......................................................................................................................
        --Sets are not loaded yet -> Show load button
        if WL.CurrentState == WISHLIST_TAB_STATE_NO_SETS then
            WLW_UpdateSceneFragmentTitle(WISHLIST_SCENE_NAME, TITLE_FRAGMENT, "Label", GetString(WISHLIST_TITLE) ..  " - " .. zo_strformat(GetString(WISHLIST_SETS_LOADED), 0))

            --No Sets Loaded
            self.setsLoading = false
            --Disable the Wishlist tab button
            WishListFrameTabList:SetEnabled(false)

            --No Sets Loaded UI
            self.frame:GetNamedChild("labelNoSets"):SetHidden(false)
            self.frame:GetNamedChild("buttonLoadSets"):SetHidden(false)

            --Sets Loaded UI
            self.frame:GetNamedChild("SetsLastScanned"):SetHidden(true)
            self.frame:GetNamedChild("Reload"):SetHidden(true)
            self.frame:GetNamedChild("RemoveAll"):SetHidden(true)
            self.frame:GetNamedChild("CopyWishList"):SetHidden(true)
            self.frame:GetNamedChild("RemoveHistory"):SetHidden(true)
            self.frame:GetNamedChild("Search"):SetHidden(true)
            self.frame:GetNamedChild("SearchDrop"):SetHidden(true)
            self.frame:GetNamedChild("CharsDrop"):SetHidden(true)
            self.frame:GetNamedChild("List"):SetHidden(true)
            self.searchBox:SetHidden(true)

            self.frame:GetNamedChild("Headers"):SetHidden(true)
            self.headerDate:SetHidden(true)
            self.headerArmorOrWeaponType:SetHidden(true)
            self.headerSlot:SetHidden(true)
            self.headerTrait:SetHidden(true)
            self.headerUsername:SetHidden(true)
            self.headerLocality:SetHidden(true)

            --Reset the sortGroupHeader
            resetSortGroupHeader(WL.CurrentTab)

            --Sets Loading UI
            self.labelLoadingSets:SetHidden(true)

            --......................................................................................................................
            --Sets are currently loading -> Update label with count of sets & items
        elseif WL.CurrentState == WISHLIST_TAB_STATE_SETS_LOADING then
            WLW_UpdateSceneFragmentTitle(WISHLIST_SCENE_NAME, TITLE_FRAGMENT, "Label", GetString(WISHLIST_TITLE) .. " - " .. GetString(WISHLIST_LOADING_SETS))
            --Sets Loading
            self.setsLoading = true
            --Disable the Wishlist tab button
            WishListFrameTabList:SetEnabled(false)

            --No Sets Loaded UI
            self.frame:GetNamedChild("labelNoSets"):SetHidden(true)
            self.frame:GetNamedChild("buttonLoadSets"):SetHidden(true)

            --Sets Loaded UI
            self.frame:GetNamedChild("SetsLastScanned"):SetHidden(true)
            self.frame:GetNamedChild("Reload"):SetHidden(true)
            self.frame:GetNamedChild("RemoveAll"):SetHidden(true)
            self.frame:GetNamedChild("CopyWishList"):SetHidden(true)
            self.frame:GetNamedChild("RemoveHistory"):SetHidden(true)
            self.frame:GetNamedChild("Search"):SetHidden(true)
            self.frame:GetNamedChild("SearchDrop"):SetHidden(true)
            self.frame:GetNamedChild("CharsDrop"):SetHidden(true)
            self.frame:GetNamedChild("List"):SetHidden(true)
            self.searchBox:SetHidden(true)

            self.frame:GetNamedChild("Headers"):SetHidden(true)
            self.headerDate:SetHidden(true)
            self.headerArmorOrWeaponType:SetHidden(true)
            self.headerSlot:SetHidden(true)
            self.headerTrait:SetHidden(true)
            self.headerUsername:SetHidden(true)
            self.headerLocality:SetHidden(true)

            --Sets Loading UI
            self.labelLoadingSets:SetHidden(false)
            --......................................................................................................................
            --Sets are loaded -> Show them in list
        elseif WL.CurrentState == WISHLIST_TAB_STATE_SETS_LOADED then
            WLW_UpdateSceneFragmentTitle(WISHLIST_SCENE_NAME, TITLE_FRAGMENT, "Label", GetString(WISHLIST_TITLE))

            --Sets Loaded
            self.setsLoading = false
            --Enable the Wishlist tab button again
            WishListFrameTabList:SetEnabled(true)

            --No Sets Loaded UI
            self.frame:GetNamedChild("labelNoSets"):SetHidden(true)
            self.frame:GetNamedChild("buttonLoadSets"):SetHidden(true)

            --Sets Loaded UI
            if WL.accData.setsLastScanned ~= nil and WL.accData.setsLastScanned > 0 then
                local setsLastScanned = WL.getDateTimeFormatted(WL.accData.setsLastScanned)
                local libSetsVersionInfo = ""
                local libSets = WL.LibSets
                if libSets and libSets.name and libSets.version then
                    libSetsVersionInfo = setsLastScanned .. "\n" .. libSets.name .. " v" .. tostring(libSets.version)
                    setsLastScanned = libSetsVersionInfo
                end
                self.frame:GetNamedChild("SetsLastScanned"):SetText(setsLastScanned)
                self.frame:GetNamedChild("SetsLastScanned"):SetHidden(false)
            end
            self.frame:GetNamedChild("Reload"):SetHidden(false)
            self.frame:GetNamedChild("RemoveAll"):SetHidden(true)
            self.frame:GetNamedChild("CopyWishList"):SetHidden(true)
            self.frame:GetNamedChild("RemoveHistory"):SetHidden(true)
            self.frame:GetNamedChild("Search"):SetHidden(false)
            self.frame:GetNamedChild("SearchDrop"):SetHidden(false)
            self.frame:GetNamedChild("CharsDrop"):SetHidden(true)

            self.frame:GetNamedChild("Headers"):SetHidden(false)
            self.headerDate:SetHidden(true)
            self.headerArmorOrWeaponType:SetHidden(true)
            self.headerSlot:SetHidden(true)
            self.headerTrait:SetHidden(true)
            self.headerQuality:SetHidden(true)
            self.headerUsername:SetHidden(true)
            self.headerLocality:SetHidden(true)

            self.frame:GetNamedChild("List"):SetHidden(false)
            WL.initializeSearchDropdown(self, WL.CurrentTab, "set")
            self.searchBox:SetHidden(false)

            --Sets Loading UI
            self.labelLoadingSets:SetHidden(true)

            --Reset the sortGroupHeader
            resetSortGroupHeader(WL.CurrentTab)

            self:RefreshData()
        end

------------------------------------------------------------------------------------------------------------------------
    --WISHLIST tab
	elseif WL.CurrentTab == WISHLIST_TAB_WISHLIST then
        WLW_UpdateSceneFragmentTitle(WISHLIST_SCENE_NAME, TITLE_FRAGMENT, "Label", GetString(WISHLIST_TITLE))
        --Set the texture of the search button to "pressed"
        local normalSearchTexture = "/esoui/art/miscellaneous/search_icon.dds"
        local normalListTexture = "/esoui/art/journal/journal_tabicon_cadwell_down.dds"
        local normalHistoryTexture = "/esoui/art/guild/tabicon_history_up.dds"
        WishListFrameTabSearch:SetNormalTexture(normalSearchTexture)
        WishListFrameTabList:SetNormalTexture(normalListTexture)
        WishListFrameTabHistory:SetNormalTexture(normalHistoryTexture)

		--No Sets Loaded UI
		self.frame:GetNamedChild("labelNoSets"):SetHidden(true)
		self.frame:GetNamedChild("buttonLoadSets"):SetHidden(true)

		--Sets Loaded UI
        self.frame:GetNamedChild("SetsLastScanned"):SetHidden(true)
		self.frame:GetNamedChild("Reload"):SetHidden(true)
        self.frame:GetNamedChild("RemoveAll"):SetHidden(false)
        self.frame:GetNamedChild("CopyWishList"):SetHidden(false)
        self.frame:GetNamedChild("RemoveHistory"):SetHidden(true)
        WL.updateRemoveAllButon(self.frame:GetNamedChild("RemoveAll"), self.frame:GetNamedChild("CopyWishList"))
        self.frame:GetNamedChild("Search"):SetHidden(false)
		self.frame:GetNamedChild("SearchDrop"):SetHidden(false)
        self.frame:GetNamedChild("CharsDrop"):SetHidden(false)

        self.frame:GetNamedChild("Headers"):SetHidden(false)
        self.headerDate:SetHidden(false)
		self.headerArmorOrWeaponType:SetHidden(false)
		self.headerSlot:SetHidden(false)
		self.headerTrait:SetHidden(false)
        self.headerQuality:SetHidden(false)
        self.headerUsername:SetHidden(true)
        self.headerLocality:SetHidden(true)

        WL.initializeSearchDropdown(self, WL.CurrentTab, "set")
		self.searchBox:SetHidden(false)

		--Sets Loading UI
		self.labelLoadingSets:SetHidden(true)

    	self.searchBox:Clear()

        --Reset the sortGroupHeader
        resetSortGroupHeader(WL.CurrentTab)

		self:RefreshData()

------------------------------------------------------------------------------------------------------------------------
    --HISTORY tab
    elseif WL.CurrentTab == WISHLIST_TAB_HISTORY then
        WLW_UpdateSceneFragmentTitle(WISHLIST_SCENE_NAME, TITLE_FRAGMENT, "Label", GetString(WISHLIST_HISTORY_TITLE):upper())
        --Set the texture of the search button to "pressed"
        local normalSearchTexture = "/esoui/art/miscellaneous/search_icon.dds"
        local normalListTexture = "/esoui/art/journal/journal_tabicon_cadwell_up.dds"
        local normalHistoryTexture = "/esoui/art/guild/tabicon_history_down.dds"
        WishListFrameTabSearch:SetNormalTexture(normalSearchTexture)
        WishListFrameTabList:SetNormalTexture(normalListTexture)
        WishListFrameTabHistory:SetNormalTexture(normalHistoryTexture)

        --No Sets Loaded UI
        self.frame:GetNamedChild("labelNoSets"):SetHidden(true)
        self.frame:GetNamedChild("buttonLoadSets"):SetHidden(true)

        --Sets Loaded UI
        self.frame:GetNamedChild("SetsLastScanned"):SetHidden(true)
        self.frame:GetNamedChild("Reload"):SetHidden(true)
        --WL.updateRemoveAllButon(self.frame:GetNamedChild("RemoveAll"), self.frame:GetNamedChild("CopyWishList"))
        self.frame:GetNamedChild("RemoveAll"):SetHidden(true)
        self.frame:GetNamedChild("CopyWishList"):SetHidden(true)
        self.frame:GetNamedChild("RemoveHistory"):SetHidden(false)
        self.frame:GetNamedChild("Search"):SetHidden(false)
        self.frame:GetNamedChild("SearchDrop"):SetHidden(false)
        self.frame:GetNamedChild("CharsDrop"):SetHidden(false)

        self.frame:GetNamedChild("Headers"):SetHidden(false)
        self.headerDate:SetHidden(false)
        self.headerArmorOrWeaponType:SetHidden(false)
        self.headerSlot:SetHidden(false)
        self.headerTrait:SetHidden(false)
        self.headerQuality:SetHidden(true)
        self.headerUsername:SetHidden(false)
        self.headerLocality:SetHidden(false)

        WL.initializeSearchDropdown(self, WL.CurrentTab, "set")
        self.searchBox:SetHidden(false)

        --Sets Loading UI
        self.labelLoadingSets:SetHidden(true)

        self.searchBox:Clear()

        --Reset the sortGroupHeader
        resetSortGroupHeader(WL.CurrentTab)

        self:RefreshData()
	end
end

function WishListWindow:BuildMasterList(calledFromFilterFunction)
    calledFromFilterFunction = calledFromFilterFunction or false
--d("[WishListWindow:BuildMasterList]calledFromFilterFunction: " ..tostring(calledFromFilterFunction))
    --Sets tab row creation from savedvars sets list
------------------------------------------------------------------------------------------------------------------------
	if WL.CurrentTab == WISHLIST_TAB_SEARCH then
        self.masterList = {}
        local setsData = WL.accData.sets
		for setId, setData in pairs(setsData) do
			table.insert(self.masterList, WL.CreateEntryForSet(setId, setData))
		end
------------------------------------------------------------------------------------------------------------------------
	--Wishlist tab row creation from wishlist savedvars items
    elseif WL.CurrentTab == WISHLIST_TAB_WISHLIST then
        self.masterList = {}
        --Update the current selected character data
        WL.checkCurrentCharData(false)
        local selectedCharData = WL.CurrentCharData
        if selectedCharData == nil then return false end
--d(">Chardata found: " .. selectedCharData.name)
        local wishList = WL.getWishListSaveVars(selectedCharData, "WishListWindow:BuildMasterList")
        if wishList == nil or #wishList == 0 then return false end
--d(">>Building master list entries, count: " .. tostring(#wishList))
        for i = 1, #wishList do
			local item = wishList[i]
            --local itemTypeName, itemArmorOrWeaponTypeName, itemSlotName, itemTraitName, itemQualityName = WL.getItemTypeNamesForSortListEntry(item.itemType, item.armorOrWeaponType, item.slot, item.trait, item.quality)
--d(">>itemType: " .. tostring(itemTypeName) .. ", armorOrWeaponType: " .. tostring(itemArmorOrWeaponTypeName) .. ", slot: " ..tostring(itemSlotName) .. ", trait: " .. tostring(itemTraitName).. ", quality: " .. tostring(itemQualityName))
			table.insert(self.masterList, WL.CreateEntryForItem(item))
        end

------------------------------------------------------------------------------------------------------------------------
    --Wishlist tab row creation from history
    elseif WL.CurrentTab == WISHLIST_TAB_HISTORY then
        self.masterList = {}
        --Update the current selected character data
        WL.checkCurrentCharData(false)
        local selectedCharData = WL.CurrentCharData
        if selectedCharData == nil then return false end
        local history = WL.getHistorySaveVars(selectedCharData)
        if history == nil or #history == 0 then return false end
        for i = 1, #history do
            local item = history[i]
--local itemTypeName, itemArmorOrWeaponTypeName, itemSlotName, itemTraitName = WL.getItemTypeNamesForSortListEntry(item.itemType, item.armorOrWeaponType, item.slot, item.trait)
--d(">>history itemType: " .. tostring(itemTypeName) .. ", armorOrWeaponType: " .. tostring(itemArmorOrWeaponTypeName) .. ", slot: " ..tostring(itemSlotName) .. ", trait: " .. tostring(itemTraitName))
            table.insert(self.masterList, WL.CreateHistoryEntryForItem(item))
        end

	end
end

--Setup the data of each row which gets added to the ZO_SortFilterList
function WishListWindow:SetupItemRow( control, data )
    if WL.comingFromSortScrollListSetupFunction then return end
    --local clientLang = WL.clientLang or WL.fallbackSetLang
    --d(">>>      [WishListWindow:SetupItemRow] " ..tostring(data.names[clientLang]))
    control.data = data

    local nameColumn = control:GetNamedChild("Name")
    nameColumn.normalColor = ZO_DEFAULT_TEXT
    local nameColumnValue = ""
    if not data.columnWidth then data.columnWidth = 200 end
    nameColumn:SetDimensions(data.columnWidth, 30)
    nameColumn:SetText(data.name)
    local armorOrWeaponTypeColumn = control:GetNamedChild("ArmorOrWeaponType")
    local slotColumn = control:GetNamedChild("Slot")
    local traitColumn = control:GetNamedChild("Trait")
    local dateColumn = control:GetNamedChild("DateTime")
    local qualityColumn = control:GetNamedChild("Quality")
    local userNameColumn = control:GetNamedChild("UserName")
    local localityColumn = control:GetNamedChild("Locality")
    localityColumn.localityName = nil
    ------------------------------------------------------------------------------------------------------------------------
    if WL.CurrentTab == WISHLIST_TAB_WISHLIST then
        --d(">WISHLIST_TAB_WISHLIST")
        local dateTimeStamp = data.timestamp
        local dateTimeStr = WL.getDateTimeFormatted(dateTimeStamp)
        dateColumn:SetText(dateTimeStr)
        dateColumn:SetHidden(false)
        userNameColumn:SetHidden(true)
        qualityColumn:SetHidden(false)
        localityColumn:SetHidden(true)
        armorOrWeaponTypeColumn:SetHidden(false)
        slotColumn:SetHidden(false)
        traitColumn:SetHidden(false)
        armorOrWeaponTypeColumn.normalColor = ZO_DEFAULT_TEXT
        local armorOrWeaponTypeColumnText = ""
        if data.itemType == ITEMTYPE_WEAPON then
            --Weapon
            armorOrWeaponTypeColumnText = WL.WeaponTypes[data.armorOrWeaponType]
        elseif data.itemType == ITEMTYPE_ARMOR then
            --Armor
            armorOrWeaponTypeColumnText = WL.ArmorTypes[data.armorOrWeaponType]
        end
        armorOrWeaponTypeColumn:SetText(armorOrWeaponTypeColumnText)
        slotColumn.normalColor = ZO_DEFAULT_TEXT
        slotColumn:SetText(WL.SlotTypes[data.slot])
        traitColumn.normalColor = ZO_DEFAULT_TEXT
        --Add the icon to the trait column
        local traitId = data.trait
        local traitText = ""
        if traitId ~= nil then
            traitText = WL.TraitTypes[traitId]
            traitText = WL.buildItemTraitIconText(traitText, traitId)
        end
        traitColumn:SetText(traitText)
        local qualityText = ""
        if data.quality then
            qualityText = WL.quality[data.quality]
        end
        qualityColumn:SetText(qualityText)
        ------------------------------------------------------------------------------------------------------------------------
    elseif WL.CurrentTab == WISHLIST_TAB_HISTORY then
        --d(">WISHLIST_TAB_HISTORY")
        local dateTimeStamp = data.timestamp
        local dateTimeStr = WL.getDateTimeFormatted(dateTimeStamp)
        dateColumn:SetText(dateTimeStr)
        dateColumn:SetHidden(false)
        qualityColumn:SetHidden(true)
        userNameColumn:SetHidden(false)
        local userNameText = ""
        if data.username ~= nil and data.username ~= "" then
            userNameText = data.username
        end
        if data.displayName ~= nil and data.displayName ~= "" then
            if userNameText ~= "" then
                userNameText = userNameText .. " [" .. data.displayName .. "]"
            else
                userNameText = data.displayName
            end
        end
        if userNameText == "" then
            userNameText = "???"
        end
        userNameColumn:SetText(userNameText)
        localityColumn:SetHidden(false)
        localityColumn:SetText(data.locality)
        localityColumn.localityName = data.locality
        armorOrWeaponTypeColumn:SetHidden(false)
        slotColumn:SetHidden(false)
        traitColumn:SetHidden(false)
        armorOrWeaponTypeColumn.normalColor = ZO_DEFAULT_TEXT
        local armorOrWeaponTypeColumnText = ""
        if data.itemType == ITEMTYPE_WEAPON then
            --Weapon
            armorOrWeaponTypeColumnText = WL.WeaponTypes[data.armorOrWeaponType]
        elseif data.itemType == ITEMTYPE_ARMOR then
            --Armor
            armorOrWeaponTypeColumnText = WL.ArmorTypes[data.armorOrWeaponType]
        end
        armorOrWeaponTypeColumn:SetText(armorOrWeaponTypeColumnText)
        slotColumn.normalColor = ZO_DEFAULT_TEXT
        slotColumn:SetText(WL.SlotTypes[data.slot])
        traitColumn.normalColor = ZO_DEFAULT_TEXT
        --Add the icon to the trait column
        local traitId = data.trait
        local traitText = ""
        if traitId ~= nil then
            traitText = WL.TraitTypes[traitId]
            traitText = WL.buildItemTraitIconText(traitText, traitId)
        end
        traitColumn:SetText(traitText)
        qualityColumn:SetText("")
        ------------------------------------------------------------------------------------------------------------------------
    elseif WL.CurrentTab == WISHLIST_TAB_SEARCH then
        --d(">WISHLIST_TAB_SEARCH")
        userNameColumn:SetHidden(true)
        localityColumn:SetHidden(true)
        dateColumn:SetHidden(true)
        armorOrWeaponTypeColumn:SetHidden(true)
        slotColumn:SetHidden(true)
        traitColumn:SetHidden(true)
        qualityColumn:SetHidden(true)
        armorOrWeaponTypeColumn:SetText("")
        slotColumn:SetText("")
        traitColumn:SetText("")
        dateColumn:SetText("")
        qualityColumn:SetText("")
    end
    --Set the row to the list now
    ZO_SortFilterList.SetupRow(self, control, data)
end

function WL.createWindow(doShow)
    doShow = doShow or false
    if (not WL.window) then
        WL.window = WishListWindow:New(WishListFrame)
    end
    if doShow then
        --Reset variable
        WL.comingFromSortScrollListSetupFunction = false
        if WL.accData.setCount == 0 then
            WL.window:UpdateUI(WISHLIST_TAB_STATE_NO_SETS)
        else
            WL.window:UpdateUI(WISHLIST_TAB_STATE_SETS_LOADED)
        end
    end
end

function WishList:Show()
    WL.createWindow(true)

    if (WishListFrame:IsControlHidden()) then
        SCENE_MANAGER:Show("WishListScene")
        WL.windowShown = true
    else
        SCENE_MANAGER:Hide("WishListScene")
        WL.windowShown = false
    end
end

function WL.updateRemoveAllButon(removeAllBtn, copyWishListButton)
    if not WL.windowShown then return false end
    --History
    if WL.CurrentTab == WISHLIST_TAB_HISTORY then
        if removeAllBtn == nil then
            removeAllBtn = WL.window.frame:GetNamedChild("RemoveHistory")
        end
        if removeAllBtn ~= nil then
            removeAllBtn:SetHidden(false)
            local isHistoryEmpty, _ = WL.IsHistoryEmpty(WL.CurrentCharData)
            if not isHistoryEmpty then
                removeAllBtn:SetEnabled(true)
            else
                removeAllBtn:SetEnabled(false)
            end
        end

    --WishList
    elseif WL.CurrentTab == WISHLIST_TAB_WISHLIST then
        if removeAllBtn == nil then
            removeAllBtn = WL.window.frame:GetNamedChild("RemoveAll")
        end
        if copyWishListButton == nil then
            copyWishListButton = WL.window.frame:GetNamedChild("CopyWishList")
        end
        if removeAllBtn ~= nil and copyWishListButton ~= nil then
            removeAllBtn:SetHidden(false)
            copyWishListButton:SetHidden(false)
            local isEmpty, _ = WL.IsEmpty(WL.CurrentCharData)
            if not isEmpty then
                removeAllBtn:SetEnabled(true)
                copyWishListButton:SetEnabled(true)
            else
                removeAllBtn:SetEnabled(false)
                copyWishListButton:SetEnabled(false)
            end
        end
    end
end

--Change the tabs at the WishList menu
function WL.SetTab(index)
    --Save the current sort order and key
    WL.saveSortGroupHeader(WL.CurrentTab)
    --Change to the new tab
    WL.CurrentTab = index
    --Clear the master list of the currently shown ZO_SortFilterList
    ZO_ScrollList_Clear(WL.window.list)
    WL.window.masterList = {}
    --Reset variable
    WL.comingFromSortScrollListSetupFunction = false
    --Update the UI (hide/show items)
    WL.window:UpdateUI(WL.CurrentState)
end


------------------------------------------------
--- WishList Window -> Filter & Sorting
------------------------------------------------
function WL.getItemTypeNamesForSortListEntry(itemType, armorOrWeaponType, slot, trait, quality)
    local itemTypes = WL.ItemTypes
    local traitTypes = WL.TraitTypes
    local slotNames = WL.SlotTypes
    local qualityNames = WL.quality
    local armorOrWeaponTypeName = ""
    if itemType == ITEMTYPE_WEAPON then
        armorOrWeaponTypeName = WL.WeaponTypes[armorOrWeaponType] or "HALLO"
    elseif itemType == ITEMTYPE_ARMOR then
        armorOrWeaponTypeName = WL.ArmorTypes[armorOrWeaponType] or "HALLO"
    end
    local itemTypeName = itemTypes[itemType] or ""
    local slotTypeName = slotNames[slot] or ""
    local traitTypeName = traitTypes[trait] or ""
    local qualityName = qualityNames[quality] or ""
    return itemTypeName, armorOrWeaponTypeName, slotTypeName, traitTypeName, qualityName
end

function WishListWindow:FilterScrollList()
--d("[WishListWindow:FilterScrollList]")
	local scrollData = ZO_ScrollList_GetDataList(self.list)
	ZO_ClearNumericallyIndexedTable(scrollData)

    --Get the search method chosen at the search dropdown
    self.searchType = self.searchDrop:GetSelectedItemData().id
    --Check the search text
    local searchInput = self.searchBox:GetText()

    local function checkIfMasterListRebuildNeeded(selfVar)
        --If not coming from setup function
        if not WL.comingFromSortScrollListSetupFunction then
--d("--->>>checkIfMasterListRebuildNeeded: true")
            selfVar:BuildMasterList(true)
        end
    end

------------------------------------------------------------------------------------------------------------------------
    --Sets tab - Changed set name search field or method
    if WL.CurrentTab == WISHLIST_TAB_SEARCH then
        --Rebuild the masterlist so the total list and counts are correct!
        checkIfMasterListRebuildNeeded(self)
        for i = 1, #self.masterList do
            --Get the data of each set item
            local data = self.masterList[i]
            --Search for text/set bonuses
            if searchInput == "" or self:CheckForMatch(data, searchInput) then
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(WISHLIST_DATA, data))
            end
        end

------------------------------------------------------------------------------------------------------------------------
    --WishList tab - Changed character
    elseif WL.CurrentTab == WISHLIST_TAB_WISHLIST then
        --Get the character ID from the chars/toon dropdown
        --local selectedCharData = self.charsDrop:GetSelectedItemData()
		WL.checkCurrentCharData(false)
        --Rebuild the masterlist so the total list and counts are correct!
        checkIfMasterListRebuildNeeded(self)
		--self.charId = selectedCharData.id
		self.charId = WL.CurrentCharData.id
        --WL.CurrentCharData.id = selectedCharData.id
        --local charNameWithoutTexture = string.gsub(selectedCharData.name, "|t%-?%d+%%?:%-?%d+%%?:.-|t%s*", "")
        --WL.CurrentCharData.name = selectedCharData.name
        --Get the WishList's SavedVariables data for the selected char ID now
        if self.charId ~= nil then
            --local accName = GetDisplayName()
            --local wishListOfCharId = WishList_Data["Default"][accName][self.charId]["Data"]["wishList"]
            local wishListOfCharId = WL.getWishListSaveVars(WL.CurrentCharData, "WishListWindow:FilterScrollList")
            if wishListOfCharId == nil or #wishListOfCharId == 0 then
                --Update the counter
                self:UpdateCounter(scrollData)
                WL.updateRemoveAllButon()
                return false
            end
--d(">MasterList count: " ..tostring(#self.masterList))
            --Add the saved wishlist items of the chosen character
            for i = 1, #self.masterList do
                --Get the data of each set item on the wishlist of the char
                local wlDataOfCharId = wishListOfCharId[i]
                local data = {}
                local itemId = wlDataOfCharId["id"]
                local itemLink = WL.buildItemLink(itemId, wlDataOfCharId["quality"])
                local _, _, numBonuses, _, _, _ = GetItemLinkSetInfo(itemLink, false)
                --Get the names for the sort & filter functions
                local itemTypeName, armorOrWeaponTypeName, slotTypeName, traitTypeName, qualityName = WL.getItemTypeNamesForSortListEntry(wlDataOfCharId["itemType"], wlDataOfCharId["armorOrWeaponType"], wlDataOfCharId["slot"], wlDataOfCharId["trait"], wlDataOfCharId["quality"])
                data["type"]                    = 1 -- for the search method to work -> Find the processor in zo_stringsearch:Process()
                data["id"]                      = itemId
                data["setId"]                   = wlDataOfCharId["setId"]
                data["itemType"]                = wlDataOfCharId["itemType"]
                data["itemTypeName"]            = itemTypeName
                data["trait"]                   = wlDataOfCharId["trait"]
                data["traitName"]               = traitTypeName
                data["armorOrWeaponType"]       = wlDataOfCharId["armorOrWeaponType"]
                data["armorOrWeaponTypeName"]   = armorOrWeaponTypeName
                data["slot"]                    = wlDataOfCharId["slot"]
                data["slotName"]                = slotTypeName
                data["quality"]                 = wlDataOfCharId["quality"]
                data["qualityName"]             = qualityName
                data["name"]                    = wlDataOfCharId["setName"]
                data["itemLink"]                = itemLink
                data["bonuses"]                 = numBonuses -- the number of the bonuses of the set
                data["timestamp"]               = wlDataOfCharId["timestamp"]
                --Filter out by name or set bonus
                if searchInput == "" or self:CheckForMatch(data, searchInput) then
                    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(WISHLIST_DATA, data))
                end
            end
        end
        WL.updateRemoveAllButon()

------------------------------------------------------------------------------------------------------------------------
    --History tab - Changed character
    elseif WL.CurrentTab == WISHLIST_TAB_HISTORY then
        --Get the character ID from the chars/toon dropdown
        --local selectedCharData = self.charsDrop:GetSelectedItemData()
        WL.checkCurrentCharData(false)
        --Rebuild the masterlist so the total list and counts are correct!
        checkIfMasterListRebuildNeeded(self)
        --self.charId = selectedCharData.id
        self.charId = WL.CurrentCharData.id
        --WL.CurrentCharData.id = selectedCharData.id
        --local charNameWithoutTexture = string.gsub(selectedCharData.name, "|t%-?%d+%%?:%-?%d+%%?:.-|t%s*", "")
        --WL.CurrentCharData.name = selectedCharData.name
        --Get the WishList's SavedVariables data for the selected char ID now
        if self.charId ~= nil then
            --local accName = GetDisplayName()
            --local wishListOfCharId = WishList_Data["Default"][accName][self.charId]["Data"]["wishList"]
            local historyOfCharId = WL.getHistorySaveVars(WL.CurrentCharData)
            if historyOfCharId == nil or #historyOfCharId == 0 then
                --Update the counter
                self:UpdateCounter(scrollData)
                WL.updateRemoveAllButon()
                return false
            end
--d(">MasterList count: " ..tostring(#self.masterList))
            --Add the saved wishlist items of the chosen character
            for i = 1, #self.masterList do
                --Get the data of each set item on the wishlist of the char
                local histDataOfCharId = historyOfCharId[i]
                local data = {}
                local itemId = histDataOfCharId["id"]
                local itemLink = WL.buildItemLink(itemId, histDataOfCharId["quality"])
                local _, _, numBonuses, _, _, _ = GetItemLinkSetInfo(itemLink, false)
                --Get the names for the sort & filter functions
                local itemTypeName, armorOrWeaponTypeName, slotTypeName, traitTypeName, qualityName = WL.getItemTypeNamesForSortListEntry(histDataOfCharId["itemType"], histDataOfCharId["armorOrWeaponType"], histDataOfCharId["slot"], histDataOfCharId["trait"], histDataOfCharId["quality"])
                data["type"]                    = 1 -- for the search method to work -> Find the processor in zo_stringsearch:Process()
                data["id"]                      = itemId
                data["setId"]                   = histDataOfCharId["setId"]
                data["itemType"]                = histDataOfCharId["itemType"]
                data["itemTypeName"]            = itemTypeName
                data["trait"]                   = histDataOfCharId["trait"]
                data["traitName"]               = traitTypeName
                data["armorOrWeaponType"]       = histDataOfCharId["armorOrWeaponType"]
                data["armorOrWeaponTypeName"]   = armorOrWeaponTypeName
                data["slot"]                    = histDataOfCharId["slot"]
                data["slotName"]                = slotTypeName
                data["quality"]                 = histDataOfCharId["quality"]
                data["qualityName"]             = qualityName
                data["name"]                    = histDataOfCharId["setName"]
                data["itemLink"]                = itemLink
                data["bonuses"]                 = numBonuses -- the number of the bonuses of the set
                data["timestamp"]               = histDataOfCharId["timestamp"]
                data["username"]                = histDataOfCharId["username"]
                if histDataOfCharId["displayName"] ~= nil then
                    data["displayName"]             = histDataOfCharId["displayName"]
                end
                data["locality"]                = histDataOfCharId["locality"]
                --Filter out by name or set bonus
                if searchInput == "" or self:CheckForMatch(data, searchInput) then
                    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(WISHLIST_DATA, data))
                end
            end
        end
        WL.updateRemoveAllButon()
    end
    --Update the counter
    self:UpdateCounter(scrollData)
end

function WishListWindow:UpdateCounter(scrollData)
    --Update the counter (found by search/total) at the bottom right of the scroll list
    local listCountAndTotal = ""
    if self.masterList == nil or (self.masterList ~= nil and #self.masterList == 0) then
        listCountAndTotal = "0 / 0"
    else
        listCountAndTotal = string.format("%d / %d", #scrollData, #self.masterList)
    end
    self.frame:GetNamedChild("Counter"):SetText(listCountAndTotal)
end

function WishListWindow:BuildSortKeys()
--d("[WL.BuildSortKeys]")
    self.sortKeys = {}
    if WL.data.useSortTiebrakerName then
        self.sortKeys = {
            ["timestamp"]               = { isId64       = true, tiebreaker = "name"  }, --isNumeric = true
            ["name"]                    = { caseInsensitive = true },
            ["armorOrWeaponTypeName"]   = { caseInsensitive = true, tiebreaker = "name" },
            ["slotName"]                = { caseInsensitive = true, tiebreaker = "name" },
            ["traitName"]               = { caseInsensitive = true, tiebreaker = "name" },
            ["quality"]                 = { caseInsensitive = true, tiebreaker = "name" },
            ["username"]                = { caseInsensitive = true, tiebreaker = "name" },
            ["locality"]                = { caseInsensitive = true, tiebreaker = "name" },
        }
    else
        self.sortKeys = {
            ["timestamp"]               = { isId64       = true }, -- isNumeric = true
            ["name"]                    = { caseInsensitive = true },
            ["armorOrWeaponTypeName"]   = { caseInsensitive = true },
            ["slotName"]                = { caseInsensitive = true },
            ["traitName"]               = { caseInsensitive = true },
            ["quality"]                 = { caseInsensitive = true },
            ["username"]                = { caseInsensitive = true },
            ["locality"]                = { caseInsensitive = true },
        }
    end
end

function WishListWindow:SortScrollList( )
    --Build the sortkeys depending on the settings
    self:BuildSortKeys()
    --Get the current sort header's key and direction
    self.currentSortKey = self.sortHeaderGroup:GetCurrentSortKey()
    self.currentSortOrder = self.sortHeaderGroup:GetSortDirection()
--d("[WishListWindow:SortScrollList] sortKey: " .. tostring(self.currentSortKey) .. ", sortOrder: " ..tostring(self.currentSortOrder))
	if (self.currentSortKey ~= nil and self.currentSortOrder ~= nil) then
        --If not coming from setup function
        if WL.comingFromSortScrollListSetupFunction then return end
        --Update the scroll list and re-sort it -> Calls "SetupItemRow" internally!
		local scrollData = ZO_ScrollList_GetDataList(self.list)
        if scrollData and #scrollData > 0 then
            table.sort(scrollData, self.sortFunction)
            self:RefreshVisible()
        end
	end
end

------------------------------------------------
--- Search/Filter Functions
------------------------------------------------
function WishListWindow:OrderedSearch( haystack, needles )
	-- A search for "spell damage" should match "Spell and Weapon Damage" but
	-- not "damage from enemy spells", so search term order must be considered
	haystack = haystack:lower()
	needles = needles:lower()
	local i = 0
	for needle in needles:gmatch("%S+") do
		i = haystack:find(needle, i + 1, true)
		if (not i) then return(false) end
	end
	return(true)
end

function WishListWindow:SearchSetBonuses( bonuses, searchInput )
	local curpos = 1
	local delim
	local exclude = false

	repeat
		local found = false
		delim = searchInput:find("[+,-]", curpos)
		if (not delim) then delim = 0 end
		local searchQuery = searchInput:sub(curpos, delim - 1)
		if (searchQuery:find("%S+")) then
			for i = 1, #bonuses do
				if (self:OrderedSearch(bonuses[i], searchQuery)) then
					found = true
					break
				end
			end

			if (found == exclude) then return(false) end
		end
		curpos = delim + 1
		if (delim ~= 0) then exclude = searchInput:sub(delim, delim) == "-" end
	until delim == 0
	return(true)
end

function WishListWindow:SearchByCriteria(data, searchInput, searchType)
--d("[WLW:SearchByCriteria]searchType: " .. tostring(searchType) .. ", searchInput: " .. tostring(searchInput))
    if data == nil or searchInput == nil or searchInput == "" or searchType == nil then return nil end
    local searchValueType = type(searchInput)
--[[
    data["type"]                    = 1 -- for the search method to work -> Find the processor in zo_stringsearch:Process()
    data["id"]                      = itemId
    data["setId"]                   = histDataOfCharId["setId"]
    data["itemType"]                = histDataOfCharId["itemType"]
    data["itemTypeName"]            = itemTypeName
    data["trait"]                   = histDataOfCharId["trait"]
    data["traitName"]               = traitTypeName
    data["armorOrWeaponType"]       = histDataOfCharId["armorOrWeaponType"]
    data["armorOrWeaponTypeName"]   = armorOrWeaponTypeName
    data["slot"]                    = histDataOfCharId["slot"]
    data["slotName"]                = slotTypeName
    data["quality"]                 = histDataOfCharId["quality"]
    data["qualityName"]             = qualityName
    data["name"]                    = histDataOfCharId["setName"]
    data["itemLink"]                = itemLink
    data["bonuses"]                 = numBonuses -- the number of the bonuses of the set
    data["timestamp"]               = histDataOfCharId["timestamp"]
    data["username"]                = histDataOfCharId["username"]
    data["displayName"]             = histDataOfCharId["displayName"]
    data["locality"]                = histDataOfCharId["locality"]
]]
    --Search by item type
    if searchType == WISHLIST_SEARCH_TYPE_BY_TYPE then
        local searchInputNumber = tonumber(searchInput)
        if searchInputNumber ~= nil then
            searchValueType = type(searchInputNumber)
        end
        if      searchValueType == "string" then
            local itemTypeName = data.itemTypeName
            if itemTypeName and itemTypeName ~= "" then
                if zo_plainstrfind(itemTypeName:lower(), searchInput:lower()) then
                    return true
                end
            end
        elseif  searchValueType == "number" then
            local itemType = data.itemType
            if itemType ~= nil and itemType == searchInputNumber then return true end
        end

    --Search by armor or weapon type
    elseif searchType == WISHLIST_SEARCH_TYPE_BY_ARMORANDWEAPONTYPE then
        local searchInputNumber = tonumber(searchInput)
        if searchInputNumber ~= nil then
            searchValueType = type(searchInputNumber)
        end
        if      searchValueType == "string" then
            local armorOrWeaponTypeName = data.armorOrWeaponTypeName
            if armorOrWeaponTypeName and armorOrWeaponTypeName ~= "" then
                if zo_plainstrfind(armorOrWeaponTypeName:lower(), searchInput:lower()) then
                    return true
                end
            end
        elseif  searchValueType == "number" then
            local armorOrWeaponType = data.armorOrWeaponType
            if armorOrWeaponType ~= nil and armorOrWeaponType == searchInputNumber then return true end
        end

    --Search by slot
    elseif searchType == WISHLIST_SEARCH_TYPE_BY_SLOT then
        local searchInputNumber = tonumber(searchInput)
        if searchInputNumber ~= nil then
            searchValueType = type(searchInputNumber)
        end
        if      searchValueType == "string" then
            local slotTypeName = data.slotName
            if slotTypeName and slotTypeName ~= "" then
                if zo_plainstrfind(slotTypeName:lower(), searchInput:lower()) then
                    return true
                end
            end
        elseif  searchValueType == "number" then
            local slotType = data.slot
            if slotType ~= nil and slotType == searchInputNumber then return true end
        end

    --Search by trait
    elseif searchType == WISHLIST_SEARCH_TYPE_BY_TRAIT then
        local searchInputNumber = tonumber(searchInput)
        if searchInputNumber ~= nil then
            searchValueType = type(searchInputNumber)
        end
        if      searchValueType == "string" then
            local traitTypeName = data.traitName
            if traitTypeName and traitTypeName ~= "" then
                if zo_plainstrfind(traitTypeName:lower(), searchInput:lower()) then
                    return true
                end
            end
        elseif  searchValueType == "number" then
            local traitType = data.trait
            if traitType ~= nil and traitType == searchInputNumber then return true end
        end

    --Search by location
    elseif searchType == WISHLIST_SEARCH_TYPE_BY_LOCATION then
        if searchValueType == "string" then
            local location = data.locality
            if location and location ~= "" then
                if zo_plainstrfind(location:lower(), searchInput:lower()) then
                    return true
                end
            end
        end

    --Search by username
    elseif searchType == WISHLIST_SEARCH_TYPE_BY_USERNAME then
        if searchValueType == "string" then
            local charName = data.username
            local accName = data.displayName
            if (charName and charName ~= "") or (accName and accName ~= "") then
                local searchInputLower = searchInput:lower()
                if (charName and zo_plainstrfind(charName:lower(), searchInputLower)) or (accName and zo_plainstrfind(accName:lower(), searchInputLower)) then
                    return true
                end
            end
        end

    --Search by itemId
    elseif searchType == WISHLIST_SEARCH_TYPE_BY_ITEMID then
        local itemId = data.id
        if itemId and zo_plainstrfind(itemId, searchInput) then
            return true
        end

    --Search by date
    elseif searchType == WISHLIST_SEARCH_TYPE_BY_DATE then
        if searchValueType == "string" then
            local timestamp = data.timestamp
            if timestamp ~= nil then
                --Create the date format from the timestamp
                local dateTimeStr = WL.getDateTimeFormatted(timestamp)
                if dateTimeStr ~= "" then
                    if zo_plainstrfind(dateTimeStr:lower(), searchInput:lower()) then
                        return true
                    end
                end
                --and compare it to the entered date format
            end
        end
    end
    return false
end

function WishListWindow:CheckForMatch( data, searchInput )
    if self.searchType ~= nil then
        --d("[WLW:CheckForMatch]searchType: " .. tostring(self.searchType) .. ", searchInput: " .. tostring(searchInput))
        --Search by name
        if self.searchType == WISHLIST_SEARCH_TYPE_BY_NAME then
            return(self.search:IsMatch(searchInput, data))
        --Search by set bonus
        elseif (self.searchType == WISHLIST_SEARCH_TYPE_BY_SET_BONUS) then
            if (type(data.bonuses) == "number") then
                -- Lazy initialization of set bonus data
                data.bonuses = WL.GetSetBonuses(data.itemLink, data.bonuses)
            end
            return(self:SearchSetBonuses(data.bonuses, searchInput))
            --Search by type
        else
            local searchTypesForCriteria = {
                [WISHLIST_SEARCH_TYPE_BY_NAME]                  = true,
                [WISHLIST_SEARCH_TYPE_BY_SET_BONUS]             = true,
                [WISHLIST_SEARCH_TYPE_BY_ARMORANDWEAPONTYPE]    = true,
                [WISHLIST_SEARCH_TYPE_BY_SLOT]                  = true,
                [WISHLIST_SEARCH_TYPE_BY_TRAIT]                 = true,
                [WISHLIST_SEARCH_TYPE_BY_LOCATION]              = true,
                [WISHLIST_SEARCH_TYPE_BY_USERNAME]              = true,
                [WISHLIST_SEARCH_TYPE_BY_ITEMID]                = true,
                [WISHLIST_SEARCH_TYPE_BY_DATE]                  = true,
                --[WISHLIST_SEARCH_TYPE_BY_TYPE]                  = true, -- disabled
            }
            local searchTypeForCriteria = searchTypesForCriteria[self.searchType] or nil
            if searchTypeForCriteria ~= nil then
                return(self:SearchByCriteria(data, searchInput, self.searchType))
            end
        end
    end
	return(false)
end

function WishListWindow:ProcessItemEntry( stringSearch, data, searchTerm )
--d("[WLW.ProcessItemEntry] stringSearch: " ..tostring(stringSearch) .. ", setName: " .. tostring(data.name:lower()) .. ", searchTerm: " .. tostring(searchTerm))
	if ( zo_plainstrfind(data.name:lower(), searchTerm) ) then
		return(true)
	end
	return(false)
end


------------------------------------------------
--- Wish List Row
------------------------------------------------
function WishListRow_OnMouseEnter( rowControlEnter )
	WL.window:Row_OnMouseEnter(rowControlEnter)
    local showItemLinkTooltip = false
    local showAdditionalTextTooltip = false
    if WL.CurrentTab ~= WISHLIST_TAB_HISTORY then
        showItemLinkTooltip = true
    else
        showItemLinkTooltip = true
        showAdditionalTextTooltip = true
    end
    if showItemLinkTooltip then
        WL.showItemLinkTooltip(rowControlEnter, WishListFrame, TOPRIGHT, -100, 0, TOPLEFT)
    end
    if showAdditionalTextTooltip then
        local data = rowControlEnter.data
        if data ~= nil then
            local clientLang = WL.clientLang or WL.fallbackSetLang
            local tooltipText = ""
            local nameVar = ""
            if data.names then
                nameVar = data.names[clientLang]
            elseif data.name then
                nameVar = data.name
            end
            tooltipText = GetString(WISHLIST_TOOLTIP_COLOR_KEY) .. GetString(WISHLIST_CONST_SET) .. "|r: " .. GetString(WISHLIST_TOOLTIP_COLOR_VALUE) .. nameVar .. "|r (" .. GetString(WISHLIST_CONST_BONUS) .. ": " .. GetString(WISHLIST_TOOLTIP_COLOR_VALUE) .. data.bonuses .. "|r, " .. GetString(WISHLIST_CONST_ID) .. ": " .. GetString(WISHLIST_TOOLTIP_COLOR_VALUE) .. data.setId .. "|r)"
            tooltipText = tooltipText .. "\n" .. GetString(WISHLIST_TOOLTIP_COLOR_KEY) .. GetString(WISHLIST_HEADER_LOCALITY) .. "|r: " .. GetString(WISHLIST_TOOLTIP_COLOR_VALUE) .. data.locality .. "|r"
            tooltipText = tooltipText .. "\n" .. GetString(WISHLIST_TOOLTIP_COLOR_KEY) .. GetString(WISHLIST_HEADER_NAME) .. "|r: " .. GetString(WISHLIST_TOOLTIP_COLOR_VALUE) ..data.username .. "|r"
            if data.displayName ~= nil and data.displayName ~= "" then
                tooltipText = tooltipText .. " [" .. data.displayName .. "]"
            end
            if data.timestamp ~= nil then
                local dateTimeStr = WL.getDateTimeFormatted(data.timestamp)
                tooltipText = tooltipText .. "\n" .. GetString(WISHLIST_TOOLTIP_COLOR_KEY) .. GetString(WISHLIST_HEADER_DATE) .. "|r: " .. GetString(WISHLIST_TOOLTIP_COLOR_VALUE) .. dateTimeStr .. "|r"
            end
            if tooltipText ~= "" then
                WL.ShowTooltip(rowControlEnter, TOP, tooltipText)
            end
        end
    end
end

function WishListRow_OnMouseExit( rowControlExit )
	WL.window:Row_OnMouseExit(rowControlExit)
    WL.hideItemLinkTooltip()
    WL.HideTooltip()
end

function WishListRow_OnMouseUp( rowControlUp, button, upInside )
    if upInside then
        WL.hideItemLinkTooltip()
        WL.HideTooltip()
        WL.showContextMenu(rowControlUp, button, upInside)
    end
end


------------------------------------------------
--- Combo Box Initializers
------------------------------------------------
function WL.initializeSearchDropdown(wishListWindow, currentTab, searchBoxType)
    if wishListWindow == nil then return false end
    currentTab = currentTab or WL.CurrentTab or WISHLIST_TAB_SEARCH
    searchBoxType = searchBoxType or "set"
--d("[WL.initializeSearchDropdown]currentTab: " ..tostring(currentTab) ..", searchBoxType: " ..tostring(searchBoxType))
    WL.checkCharsData()
    if currentTab == WISHLIST_TAB_WISHLIST and (WL.charsData == nil or #WL.charsData == 0) then return false end
    local currentTab2SearchDropValues = {
        [WISHLIST_TAB_SEARCH]   = {
            ["set"] = {dropdown=wishListWindow.searchDrop,  prefix=WISHLIST_SEARCHDROP_PREFIX,  entryCount=WISHLIST_TAB_SEARCH_ENTRY_COUNT},
        },
        [WISHLIST_TAB_WISHLIST] = {
            ["set"] = {dropdown=wishListWindow.searchDrop,  prefix=WISHLIST_SEARCHDROP_PREFIX,  entryCount=WISHLIST_TAB_WHISLIST_ENTRY_COUNT},
            ["char"]= {dropdown=wishListWindow.charsDrop,   prefix=WISHLIST_CHARSDROP_PREFIX,    entryCount=#WL.charsData},
        },
        [WISHLIST_TAB_HISTORY] = {
            ["set"] = {dropdown=wishListWindow.searchDrop,  prefix=WISHLIST_SEARCHDROP_PREFIX,  entryCount=WISHLIST_TAB_HISTORY_ENTRY_COUNT},
            ["char"]= {dropdown=wishListWindow.charsDrop,   prefix=WISHLIST_CHARSDROP_PREFIX,    entryCount=#WL.charsData},
        }
    }
    local searchDropAtTab = currentTab2SearchDropValues[currentTab]
    local searchDropData = searchDropAtTab[searchBoxType]
    if searchDropData == nil then return false end
    --d(">searchDropData: " .. tostring(searchDropData.dropdown) ..", " ..tostring(searchDropData.prefix) .. ", " .. tostring(searchDropData.entryCount))
    wishListWindow:InitializeComboBox(searchDropData.dropdown, searchDropData.prefix, searchDropData.entryCount)
end

function WishListWindow:InitializeComboBox( control, prefix, max )
    local isCharCB = (prefix == WISHLIST_CHARSDROP_PREFIX) or false
    local isSetSearchCB = (prefix == WISHLIST_SEARCHDROP_PREFIX) or false
--d("[WishListWindow:InitializeComboBox]isSetSearchCB: " .. tostring(isSetSearchCB) .. ", isCharCB: " .. tostring(isCharCB) .. ", prefix: " .. tostring(prefix) ..", max: " .. tostring(max))
    local setSearchCBEntryStart = WISHLIST_SEARCHDROP_PREFIX
    control:SetSortsItems(false)
    control:ClearItems()

    local callback = function( ... ) --comboBox, entryText, entry, selectionChanged )
        self:RefreshFilters()
    end

    local selectedCharDataBeforeUpdate
    --local currentCharName
    local currentCharId = 0
    local itemToSelect = 1
    --local currentCharName = ""
    --Character combo box?
    if isCharCB then
        --currentCharName = GetUnitName("player")
        --Format the name
        --currentCharName = zo_strformat(SI_UNIT_NAME, currentCharName)
        selectedCharDataBeforeUpdate = WL.SelectedCharDataBeforeUpdate or nil
        if selectedCharDataBeforeUpdate ~= nil and selectedCharDataBeforeUpdate.charId ~= nil then
            currentCharId = selectedCharDataBeforeUpdate.charId
        else
            currentCharId = GetCurrentCharacterId()
        end
    end
    for i = 1, max do
        local entry
        --Character combo box?
        if isCharCB then
            local charData = WL.charsData[i]
            local charNameToken = prefix .. tostring(charData.id)
--d(">charNameToken: " ..tostring(charNameToken))
            local charName = GetString(charNameToken)
            --d(">charName: " .. tostring(charName))
            entry = ZO_ComboBox:CreateItemEntry(charName, callback)
            local charId = -1
            if charData ~= nil then
                charId = charData.id
                --[[
                if charData.nameClean == currentCharName then
                    itemToSelect = i
                end
                ]]
                if charId == currentCharId then
                    itemToSelect = i
                end
            else
                charId = i
            end
            entry.id         = charId
            entry.name       = charData.name
            entry.nameClean  = charData.nameClean
            entry.class      = charData.class

        --Search type combo box
        elseif isSetSearchCB then
            local entryText = GetString(prefix, i)
            --entryText = entryText .. GetString(setSearchCBEntryStart, i)
            entry = ZO_ComboBox:CreateItemEntry(entryText, callback)
            entry.id = i
        end
        control:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
    end
    if itemToSelect ~= nil then
        control:SelectItemByIndex(itemToSelect, true)
    end

    --Character dropdown box?
    if isCharCB then
        --Set a variable to check if the dropdown of characters is currently visible
        ZO_PreHook(control, "SetVisible", function(self, visible)
            if(visible) then
                WL.activeCharDropdown = self
            else
                WL.activeCharDropdown = nil
            end
        end)

        --Show tooltips in WishList char dropdown entries, if the dropdown box is allowed
        ZO_PreHook("ZO_Menu_SetSelectedIndex", function(index)
            if(not WL.activeCharDropdown) then return end
            ZO_Tooltips_HideTextTooltip()
            if(not index or not ZO_Menu.items) then return end
            local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
            if not mouseOverControl then return false end
            index = zo_max(zo_min(index, #ZO_Menu.items), 1)
            if index then
                local selectedControlItem = control.m_sortedItems[index]
                if selectedControlItem ~= nil and selectedControlItem.id ~= nil then
                    local charData = {}
                    charData.id = selectedControlItem.id
                    local tooltipText = ""
                    if WL.CurrentTab == WISHLIST_TAB_WISHLIST then
                        tooltipText = zo_strformat(WISHLIST_CHARDROPDOWN_ITEMCOUNT_WISHLIST, selectedControlItem.name, WL.getWishListItemCount(charData))
                    elseif WL.CurrentTab == WISHLIST_TAB_HISTORY then
                        tooltipText = zo_strformat(WISHLIST_CHARDROPDOWN_ITEMCOUNT_HISTORY, selectedControlItem.name, WL.getHistoryItemCount(charData))
                    end
                    if tooltipText ~= nil and tooltipText ~= "" then
                        ZO_Tooltips_ShowTextTooltip(mouseOverControl, LEFT, tooltipText)
                    end
                end
            end
        end)
    end
end