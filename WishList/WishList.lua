WishList = WishList or {}
local WL = WishList
local libSets = WL.LibSets

--> Taken from addon DolgubonLazyWritCretaor to speed up the loot messages!
--The flavour text of a writ reward box
local writRewardContainerFlavText = GetItemLinkFlavorText("|H1:item:121302:175:1:0:0:0:0:0:0:0:0:0:0:0:1:0:0:1:0:0:0|h|h")
--The flavour text of a writ reward box's content with materials (another box)
local writRewardContainerContentContainerFlavText = GetItemLinkFlavorText("|H1:item:99256:3:1:0:0:0:0:0:0:0:0:0:0:0:1:0:0:1:0:0:0|h|h")
local allowedItemTypes = WL.checkItemTypes
WL.comingFromSortScrollListSetupFunction = false

--Start data of addon
WL.CurrentState = WISHLIST_TAB_STATE_NO_SETS 	    --1=NoSets, 2=Loading, 3=SetsLoaded
WL.CurrentTab   = WISHLIST_TAB_SEARCH               --1=Search, 2=WishList
WL.CurrentCharData = {}
WL.LoggedInCharData = {}
WL.sortType = 1
WL.firstWishListCall = false

WL.fallbackSetLang = "en" -- the fallback language for the setNames if the clientLanguage is not supported within LibSets

WL.invSingleSlotUpdateData = {}
WL.debug = false

--SavedVars
WL.data = {}
WL.accData = {}
WL.initDone = false

--Other addons
WL.otherAddons = {}
WL.otherAddons.LazyWritCreatorActive = false

--Preventing variables
WL.preventerVars = {}
WL.preventerVars.addonMenuBuild = false
WL.preventerVars.writCreatorAutoLootBoxesActive = false
WL.preventerVars.runSetNameLanguageChecks = false
WL.maxNameColumnWidth = nil

------------------------------------------------
--- Event Handlers
------------------------------------------------
local function checkAntiLootDisableTime(disable)
    --Checked in EVENT_SINGLE_SLOT_UPDATE: If the addon DolgubonsLazyWritCreator is active and should autoloot the writ reward containers:
    --This funciton will reset the anti-loot-check variable after 3 seconds, or increase the timer by 3 seconds
    --so the looted containers are not checked against set items and the unneeded scans stress the client this way
    disable = disable or false
    local antiLootUpdaterName = WL.addonVars.addonName .. "_DisableAntiLootTimer"
    EVENT_MANAGER:UnregisterForUpdate(antiLootUpdaterName)
    if disable then return false end
    --If anti loot flag is not enabled, abort now
    if not WL.preventerVars.writCreatorAutoLootBoxesActive then return false end

    --Remove anti loot flag after 3 seconds again
    EVENT_MANAGER:RegisterForUpdate(antiLootUpdaterName, 3000, function()
--d(">Disabling the anti loot again now!")
        WL.preventerVars.writCreatorAutoLootBoxesActive = false
        checkAntiLootDisableTime(true)
    end)
end

--EVENT_INVENTORY_SINGLE_SLOT_UPDATE (number eventCode, Bag bagId, number slotId, boolean isNewItem, ItemUISoundCategory itemSoundCategory, number inventoryUpdateReason, number stackCountChange)
function WL.Inv_Single_Slot_Update(_, bagId, slotId, isNewItem, _, inventoryUpdateReason, _, debug)
    debug = debug or false
    if inventoryUpdateReason ~= INVENTORY_UPDATE_REASON_DEFAULT then return false end
    if debug then d("[WL.Inv_Single_Slot_Update] " .. GetItemLink(bagId, slotId) .. ", isNew: " .. tostring(isNewItem)) end
    if not isNewItem then return false end
    --Abort here if we are arrested by a guard (thief system) as it will scan our inventory for stolen items and destroy them.
    --We don't need to scan it with our functions too at this case
    if IsUnderArrest() then return end
    --Do not execute if horse is changed
    if SCENE_MANAGER:GetCurrentScene() == STABLES_SCENE then return end
    --Check if item in slot is still there
    if GetItemType(bagId, slotId) == ITEMTYPE_NONE then return end
    --Save the current bagId and slotIndex with the itemLink to internal WishList temp data so the LootReceived event can use it
    if ((not debug and bagId == BAG_BACKPACK) or debug) then
        local itemLink = GetItemLink(bagId, slotId)
        if itemLink then
            WL.invSingleSlotUpdateData = WL.invSingleSlotUpdateData or {}
            WL.invSingleSlotUpdateData[itemLink] = slotId
            if debug then d("[WishList]" .. itemLink .. " - Inv_Single_Slot_Update: Set the slotId " ..tostring(slotId) .. " to the WL internal variables!") end
        end
    end
    --Are we in simulation mode or is DolgubonsLazyWritCreatorAddon not active? Abort here then
    if debug or not WL.otherAddons.LazyWritCreatorActive then return false end
    --Is the automatic opening of the writ container rewards active?
    if WritCreater and WritCreater.savedVars and WritCreater.savedVars.lootContainerOnReceipt then
        --d(">Writ creator active and settings = auto loot container")
        --Is the setting within the addon active to auto loot the boxes?
        local autoLoot
        if WritCreater.savedVars.ignoreAuto then
            autoLoot = WritCreater.savedVars.autoLoot
        else
            autoLoot = GetSetting(SETTING_TYPE_LOOT,LOOT_SETTING_AUTO_LOOT) == "1"
        end
        --Is this a new looted writ reward box or the box form a writ reward box?
        local itemLink = GetItemLink(bagId, slotId)
        local itemFlavText = GetItemLinkFlavorText(itemLink)
        if itemFlavText == writRewardContainerFlavText then
            --d(">Item is a autolooted writ container: " .. itemLink)
            --Set the preventer functions so the loot event cllback function of Wishlist is not called for the autoloot of the boxes
            WL.preventerVars.writCreatorAutoLootBoxesActive = true
        elseif itemFlavText == writRewardContainerContentContainerFlavText then
            if not autoLoot then
                return false
            end
            --d(">Item is a autolooted writ container content container: " .. itemLink)
            --Set the preventer functions so the loot event callback function of Wishlist is not called for the autoloot of the boxes
            WL.preventerVars.writCreatorAutoLootBoxesActive = true
        end
        --Disable the anti-loot flag after 3 seconds again
        if WL.preventerVars.writCreatorAutoLootBoxesActive then
            checkAntiLootDisableTime()
        end
    else
        if WL.preventerVars.writCreatorAutoLootBoxesActive then checkAntiLootDisableTime(true) end
        WL.preventerVars.writCreatorAutoLootBoxesActive = false
    end
end

local isItemAlreadyOnWishlist = WL.isItemAlreadyOnWishlist
local IfItemIsOnWishlist = WL.IfItemIsOnWishlist
local function lootReceivedWishListCheck(itemId, itemLink, isLootedByPlayer, receivedByCharName, whereWasItLootedData, debug, bagId, slotIndex)
    debug = debug or false
    local receivedBy = {}
    if itemLink == nil or itemId == nil then return nil end
    --Compare some data like the itemType, weaponOrArmorType, slot, traut of itemLink of the looted item with your wishList
    local itemType = GetItemLinkItemType(itemLink)
    if debug then
        d(">itemType: " ..tostring(itemType))
    end
    if not allowedItemTypes[itemType] then return false end

    --Check if the item is a set part
    local isSet, setName, _, _, _, setId = GetItemLinkSetInfo(itemLink, false)
    if debug then
        d(">isSet: " ..tostring(isSet) .. ", setName: " .. tostring(setName) .. ", setId: " ..tostring(setId))
    end
    if not isSet then return false end

    --Get the armor or weapon type for comparison
    local armorOrWeaponType
    if itemType == ITEMTYPE_ARMOR then
        armorOrWeaponType = GetItemLinkArmorType(itemLink)
    elseif itemType == ITEMTYPE_WEAPON then
        armorOrWeaponType = GetItemLinkWeaponType(itemLink)
    end
    if debug then
        d(">armorOrWeaponType: " ..tostring(armorOrWeaponType))
    end
    --Get the slot type
    local slotType = GetItemLinkEquipType(itemLink)
    if debug then
        d(">slotType: " ..tostring(slotType))
    end
    --Get the trait
    local traitType = GetItemLinkTraitInfo(itemLink)
    if debug then
        d(">traitType: " ..tostring(traitType))
    end
    --Get the quality
    local quality = GetItemLinkQuality(itemLink)
    if debug then
        d(">quality: " ..tostring(quality))
    end
    --Get the settings
    local settings = WL.data
    local isOnWishList, item, itemIdOfSetPart
    local charData = {}

    --Check if not in dungeon and setting to be in a ddngeon upon notify is enabled
    if settings.notifyOnFoundItemsOnlyInDungeons == true then
        if not IsUnitInDungeon("player") then
            if debug then d("<<<should be in dungeon but is not!") end
            return
        end
    end

    --Check the item's level and if the setting to only notify if the level is the currently max CP level is enabled
    local doGoOn = true
    if settings.notifyOnFoundItemsOnlyMaxCP == true then
        doGoOn = false
        local maxLevel = GetMaxLevel()
        local requiredLevel = GetItemLinkRequiredLevel(itemLink)
        local itemReqCPLevel = GetItemLinkRequiredChampionPoints(itemLink)
        if requiredLevel >= maxLevel then doGoOn = true end
        if doGoOn == true then
            local maxCP = GetChampionPointsPlayerProgressionCap()
            if itemReqCPLevel <= 0 or itemReqCPLevel < maxCP then
                doGoOn = false
            end
        end
        if doGoOn == false then
            if debug then d("<<<item level should be max CP but is only " ..tostring(requiredLevel) .. " and " .. tostring(itemReqCPLevel) .. " CP)") end
            return
        end
    end
    --Scan all characters or only the currently logged in?
    if settings.scanAllChars then
        if debug then
            d(">Scanning all chars' wishlists")
        end
        local charsOfAcc = WL.accData.chars
        for charId, charInfo in pairs(charsOfAcc) do
            charData = {}
            charData.id = charId
            charData.name = charInfo.name
            if debug then
                d(">>scanning char: " .. tostring(charData.name))
            end
            charData.class = charInfo.class
            if charData ~= nil and charData.id ~= nil then
                --Check if the item is on the wishlist
                isOnWishList, itemIdOfSetPart, item = isItemAlreadyOnWishlist(itemLink, itemId, charData, true, setId, itemType, armorOrWeaponType, slotType, traitType, quality)
                if debug then
                    d(">>isOnWishList: " .. tostring(isOnWishList))
                end
                --Is the item on the wishlist?
                if isOnWishList then
                    --Simulate the EVENT_INVENTORY_SINGLE_SLOT_UPDATE now to fill the needed variables for the automatic icon marking
                    if debug and bagId and slotIndex then WL.Inv_Single_Slot_Update(WL.addonVars.addonName, bagId, slotIndex, true, _, INVENTORY_UPDATE_REASON_DEFAULT, _, debug) end
                    --Add the current date & time to the item
                    item = WL.addTimeStampToItem(item)
                    --Remove the gender stuff from the setname
                    setName = zo_strformat("<<C:1>>", setName)
                    --Is the setting disable to use the char name and not the account name? But not for our own as this will be handled within function IfItemIsOnWishlist.
                    if not isLootedByPlayer then
                        --Check if we can determine the charName of the grouped accountName which looted the item
                        local receivedByAccountName = WL.mapGroupedCharNameToAccountName(receivedByCharName)
                        receivedBy.accountName = receivedByAccountName
                    end
                    receivedBy.charName = receivedByCharName
                    --Is the item on the WishList?
                    IfItemIsOnWishlist(item, itemId, itemLink, setName, isLootedByPlayer, receivedBy, charData, whereWasItLootedData, debug)
                end
            end
        end
    else
        if debug then
            d(">Scan only this char's wishlist")
        end
        charData = WL.LoggedInCharData
        if charData == nil or charData.id == nil then return false end
        --Check if the item is on the wishlist
        isOnWishList, itemIdOfSetPart, item = isItemAlreadyOnWishlist(itemLink, itemId, charData, true, setId, itemType, armorOrWeaponType, slotType, traitType, quality)
        if debug then
            d(">>isOnWishList: " .. tostring(isOnWishList))
        end
        if not isOnWishList then return false end
        --Simulate the EVENT_INVENTORY_SINGLE_SLOT_UPDATE now to fill the needed variables for the automatic icon marking
        if debug and bagId and slotIndex then WL.Inv_Single_Slot_Update(WL.addonVars.addonName, bagId, slotIndex, true, _, INVENTORY_UPDATE_REASON_DEFAULT, _, debug) end
        --Add the current date & time to the item
        item = WL.addTimeStampToItem(item)
        --Remove the gender stuff from the setname
        setName = zo_strformat("<<C:1>>", setName)
        --Is the setting disable to use the char name and not the account name? But not for our own as this will be handled within function IfItemIsOnWishlist.
        if not isLootedByPlayer then
            --Check if we can determine the charName of the grouped accountName which looted the item
            local receivedByAccountName = WL.mapGroupedCharNameToAccountName(receivedByCharName)
            receivedBy.accountName = receivedByAccountName
        end
        receivedBy.charName = receivedByCharName
        --Is the item on the wishlist?
        IfItemIsOnWishlist(item, itemId, itemLink, setName, isLootedByPlayer, receivedBy, charData, whereWasItLootedData, debug)
    end
    --Reset the INVENTORY_SINGLE_SLOT_UPDATE variable for the automatic icon mark again now
    WL.invSingleSlotUpdateData[itemLink] = nil
end

function WL.simulateLootReceived(bagId, slotIndex, receivedBy, isLootedByPlayer)
    if isLootedByPlayer == nil then isLootedByPlayer = true end
    receivedBy = receivedBy or GetUnitName("player")
    local itemLink = GetItemLink(bagId, slotIndex)
    if itemLink == nil then return nil end
    local itemId = GetItemLinkItemId(itemLink)
    --isInPVP, isInDelve, isInPublicDungeon, isInGroupDungeon, isInRaid, isInGroup, groupSize
    local whereWasItLootedData = { WL.getCurrentZoneAndGroupStatus() }
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    d("WL.SimulateLootReceived: " .. tostring(itemLink) .. ", itemId: " ..tostring(itemId) .. ", receivedBy: " ..tostring(receivedBy) .. ", isLootedByPlayer: " .. tostring(isLootedByPlayer))
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    lootReceivedWishListCheck(itemId, itemLink, isLootedByPlayer, receivedBy, whereWasItLootedData, true, bagId, slotIndex)
end

--EVENT_LOOT_RECEIVED (number eventCode, string receivedBy, string itemName, number quantity, ItemUISoundCategory soundCategory, LootItemType lootType, boolean self, boolean isPickpocketLoot, string questItemIcon, number itemId, boolean isStolen)
function WL.LootReceived(_, receivedBy, itemLink, _, _, lootType, isLootedByPlayer, _, _, itemId, _)
--d("WL.LootReceived: " .. tostring(itemLink) .. ", receivedBy: " .. tostring(receivedBy) .. ", isLootedByPlayer: " .. tostring(isLootedByPlayer))
    --Only check if an item was looted
    if not lootType == LOOT_TYPE_ITEM then return false end
    --Are we looting writ reward containers, and cotainers in there? No set items will be looted so abort here until everything is looted
    --As we cannot detect when it ends to loot all writ containers we can only assume it's ended after ~3 seconds and will be
    --increased each time the next writ container get's looted by 3 seconds
    if WL.preventerVars.writCreatorAutoLootBoxesActive then
        --d(">Auto loot of writ container active -> ABORTING")
        return false
    end
    --Check where the item was looted
    --isInPVP, isInDelve, isInPublicDungeon, isInGroupDungeon, isInRaid, isInGroup, groupSize
    local whereWasItLootedData = { WL.getCurrentZoneAndGroupStatus() }

    --Check if the item is on a wishlist
    lootReceivedWishListCheck(itemId, itemLink, isLootedByPlayer, receivedBy, whereWasItLootedData, WL.debug, nil, nil)
end

------------------------------------------------
--- Wishlist - ZO_SortFilterList entry creation
------------------------------------------------

--Check which language should be added first to the set name column (client language or standard language EN)
-->This function should only be run once after reloadui, and once after the settings were changed (See variable WL.preventerVars.runSetNameLanguageChecks)
local function checkLanguageToAddFirst()
    --d("[WishList]checkLanguageToAddFirst, WL.langToAddFirst: " ..tostring(WL.langToAddFirst))
    if not WL.preventerVars.runSetNameLanguageChecks then return WL.langToAddFirst end
    --Checks which language should be added first to the setName output
    local clientLang = WL.clientLang or WL.fallbackSetLang
    local setNameOutputSettings = WL.data.useLanguageForSetNames
    local clientLangIsSupportedInLibSets = libSets.supportedLanguages[clientLang]
    local langToAddFirst = "en"
    --Check if the client language is disabled in the settings for the setName
    local clientLangIsEnabledInSetNameSettings = setNameOutputSettings[clientLang] or false
    --Check if all languages are disabled in the settings for the setNames
    local fallbackLangEnabledInSetNameSettings = false
    local otherNonFallbackLangEnabledInSetNameSettings = false
    local allLanguagesDisabledInSetNameSettings = true
    local doNotAddFirstLanguage = false
    for langToCheck, isEnabledCheck in pairs(setNameOutputSettings) do
        --Language is enabled?
        if isEnabledCheck then
            allLanguagesDisabledInSetNameSettings = false
            --English language is enabled in the settings?
            if langToCheck == langToAddFirst then
                fallbackLangEnabledInSetNameSettings = true
            elseif langToCheck ~= clientLang then
                otherNonFallbackLangEnabledInSetNameSettings = true
            end
        end
    end
    --All languages are disabled in the settings of the setName
    if allLanguagesDisabledInSetNameSettings then
        --Client language is not supported within LibSets. Then use the default language "en"
        --Client language is supported within LibSets? Then add it as first language
        if clientLangIsSupportedInLibSets then
            langToAddFirst = clientLang
        --else --Client language is not supported, so use the fallback language
        end
    --Not all languages are disabled in the settings of the setName
    else
        --The client language is supported within LibSets and the client language is enabled in the settings for the setName output:
        --Then add it as first language
        if clientLangIsSupportedInLibSets and clientLangIsEnabledInSetNameSettings then
            langToAddFirst = clientLang
        --The client language is not supported within LibSets or the client language is not enabled in the settings for the setName output,
        --and the fallback language is not enabled in the settings of the setName, but another language is enabled
        --Then add it as first language
        elseif (not clientLangIsSupportedInLibSets or not clientLangIsEnabledInSetNameSettings) and
                (not fallbackLangEnabledInSetNameSettings and otherNonFallbackLangEnabledInSetNameSettings) then
            --Check if the fallback language "en" is not enabled in the settings of the setName, but another language is enabled.
            --Then do not add the fallback language "en" but only the enabled language
            doNotAddFirstLanguage = true
        end
    end
    --d(">doNotAddFirstLanguage: " .. tostring(doNotAddFirstLanguage) .. ", langToAddFirst: " .. tostring(langToAddFirst) .. "-> clientLang: " ..tostring(clientLang)..", supported: " ..tostring(clientLangIsSupportedInLibSets)..", enabled: " ..tostring(clientLangIsEnabledInSetNameSettings) .. ", allDisabled: " ..tostring(allLanguagesDisabledInSetNameSettings))
    if doNotAddFirstLanguage then langToAddFirst = nil end
    WL.preventerVars.runSetNameLanguageChecks = false
    WL.langToAddFirst = langToAddFirst
    return langToAddFirst
end

--Helper function to get the zoneName for a zoneId
local zoneIdsAdded = {}
local wayshrinesAdded = {}
local zoneIdNames = {}
local wayshrineNames = {}
local function checkAndGetZoneName(p_zoneId, p_setId, p_dropLocationsText, p_dropLocationsZoneIds)
    if p_zoneId > 0 and not zoneIdsAdded[p_zoneId] then
        local zoneNameLocalized = nil
        if p_zoneId ~= WISHLIST_ZONEID_BATTLEGROUNDS and p_zoneId ~= WISHLIST_ZONEID_SPECIAL then
            zoneNameLocalized = libSets.GetZoneName(p_zoneId, WL.clientLang)
        end
        if zoneNameLocalized == nil or zoneNameLocalized == "" then
            --Get the setType and check if it's from a battleground (there is no zoneId for them so we need to use a fixed String)
            local isBGSetType = libSets.IsBattlegroundSet(p_setId)
            if isBGSetType then
                zoneNameLocalized = GetString(WISHLIST_DROPLOCATION_BG)
                if p_dropLocationsZoneIds == nil then
                    p_dropLocationsZoneIds = {}
                    p_dropLocationsZoneIds = {[1] = WISHLIST_ZONEID_BATTLEGROUNDS}
                end
            else
                --Get the setType and check if it's from a battleground (there is no zoneId for them so we need to use a fixed String)
                local isSpecialSetType = libSets.IsSpecialSet(p_setId)
                if isSpecialSetType then
                    zoneNameLocalized = GetString(WISHLIST_DROPLOCATION_SPECIAL)
                    if p_dropLocationsZoneIds == nil then
                        p_dropLocationsZoneIds = {[1] = WISHLIST_ZONEID_SPECIAL}
                    end
                end
            end
        end
        if zoneNameLocalized and zoneNameLocalized ~= "" then
            if p_dropLocationsText == "" then
                p_dropLocationsText = zoneNameLocalized
            else
                p_dropLocationsText = p_dropLocationsText .. ", " .. zoneNameLocalized
            end
            zoneIdsAdded[p_zoneId] = true
            zoneIdNames[p_zoneId] = zoneNameLocalized
        end
    end
    return p_dropLocationsText, p_dropLocationsZoneIds
end

local function checkAndGetWayshrineName(p_wayShrines)
    if p_wayShrines and type(p_wayShrines) == "table" then
        for _, wsIndex in ipairs(p_wayShrines) do
            if wsIndex > 0 and not wayshrinesAdded[wsIndex] then
                local wsNameLocalized = nil
                --@return known bool,name string,normalizedX number,normalizedY number,icon textureName,glowIcon textureName:nilable,poiType [PointOfInterestType|#PointOfInterestType],isShownInCurrentMap bool,linkedCollectibleIsLocked bool
                --function GetFastTravelNodeInfo(nodeIndex) end
                local _, wsName = GetFastTravelNodeInfo(wsIndex)
                if wsName and wsName ~= "" then
                    wsNameLocalized = ZO_CachedStrFormat("<<C:1>>", wsName)
                    if wsNameLocalized and wsNameLocalized ~= "" then
                        wayshrinesAdded[wsIndex] = true
                        wayshrineNames[wsIndex] = wsNameLocalized
                    end
                end
            end
        end
    end
end

--ZO_SortScrollList - Item for the sets tab's list
function WL.CreateEntryForSet( setId, setData )
	--Item data format: {id=number, itemType=ITEM_TYPE, trait=ITEM_TRAIT_TYPE, type=ARMOR_TYPE/WEAPON_TYPE, slot=EQUIP_TYPE}
    --local setsData = WL.accData.sets
	local itemId = WL.GetFirstSetItem(setId)
    if itemId == nil then return nil end
	--local bonuses = setsData[setId][1].bonuses
    local itemLink = WL.buildItemLink(itemId, WISHLIST_QUALITY_LEGENDARY) -- Always use the legendary quality for the sets list
    local _, _, numBonuses = GetItemLinkSetInfo(itemLink, false)
    --Remove the gender stuff from the setname
    local clientLang = WL.clientLang or WL.fallbackSetLang
    local nameColumnValue = ""
    --Get the settings for the setName output
    local clientLangSetName = setData.names[clientLang] or setData.names[WL.fallbackSetLang]
    local langsAdded = 0
    local setNameOutputSettings = WL.data.useLanguageForSetNames
    if not libSets or setNameOutputSettings == nil then
        nameColumnValue = clientLangSetName
        langsAdded = langsAdded +1
    else
        local langsAlreadyAdded = {}
        --Which language should be added first to the setName column?
        local langToAddFirst = checkLanguageToAddFirst()
        if langToAddFirst ~= nil then
            nameColumnValue = setData.names[langToAddFirst]
            langsAlreadyAdded[langToAddFirst] = true
            langsAdded = langsAdded +1
        end
        --For each enabled language in the WishList "LibSets setName output" settings (which is not the already added
        --client language or English)
        for languageToAddToSetName, isEnabled in pairs(setNameOutputSettings) do
            if isEnabled and not langsAlreadyAdded[languageToAddToSetName] then
                if langsAdded == 0 then
                    --Add the set name in this language without a seperator character
                    nameColumnValue = nameColumnValue .. setData.names[languageToAddToSetName]
                else
                    --Add the set name in this language with a seperator character /
                    nameColumnValue = nameColumnValue .. " / " .. setData.names[languageToAddToSetName]
                end
                --Increase the counter
                langsAdded = langsAdded +1
            end
        end
    end
    --Set the width of the label column depending on the languages added
    local columnWidthAdd = 0
    if langsAdded > 1 then
        columnWidthAdd = langsAdded * 125
    end
    --Get the drop location(s) of the set via LibSets
    local dropLocationsText = ""
    local dropLocationsZoneIds = libSets.GetZoneIds(setId)
    zoneIdsAdded = {}
    zoneIdNames = {}
    wayshrinesAdded = {}
    wayshrineNames = {}
    --Get the zoneIds' text now
    if dropLocationsZoneIds ~= nil then
        if type(dropLocationsZoneIds) == "table" then
            --Get each zoneId, get the zoneName localized via LibZone (via LiBSets) or from LibSets data
            for _, zoneId in ipairs(dropLocationsZoneIds) do
                dropLocationsText = checkAndGetZoneName(zoneId, setId, dropLocationsText, nil)
            end
        end
    else
        --For battleground sets there is no zoneId. Use the constant here
        dropLocationsText, dropLocationsZoneIds = checkAndGetZoneName(WISHLIST_ZONEID_BATTLEGROUNDS, setId, dropLocationsText, dropLocationsZoneIds)
    end
    --Get the drop location wayshrines
    local setWayshrines = libSets.GetWayshrineIds(setId)
    checkAndGetWayshrineName(setWayshrines)
    --Get the DLC id
    local dlcId = libSets.GetDLCId(setId)
    local dlcName = libSets.GetDLCName(dlcId)
    --Get set type
    local setType = libSets.GetSetType(setId)
    local setTypeName = libSets.GetSetTypeName(setType)
    --Get traits needed for craftable sets
    local traitsNeeded = libSets.GetTraitsNeeded(setId)

    local maxNameColumnWidth = 200 + columnWidthAdd
    if WL.maxNameColumnWidth == nil or maxNameColumnWidth > WL.maxNameColumnWidth then
--d(">WL.maxNameColumnWidth changed to: " ..tostring(WL.maxNameColumnWidth))
        WL.maxNameColumnWidth = maxNameColumnWidth
    end

    local setsData = WL.accData.sets[setId]
    --Table entry for the ZO_ScrollList data
	return({
        type        = WL.sortType,
		setId       = setId,
		name        = nameColumnValue,
        names       = setData.names,
        columnWidth = maxNameColumnWidth,
		itemLink    = itemLink,
		bonuses     = numBonuses,
        --LibSets data
        setType     = setType,
        traitsNeeded= traitsNeeded,
        dlcId       = dlcId,
        locality    = dropLocationsText,
        zoneIds     = dropLocationsZoneIds,
        wayshrines  = setWayshrines,
        zoneIdNames = zoneIdNames,
        wayshrineNames = wayshrineNames,
        dlcName     = dlcName,
        setTypeName = setTypeName,
        armorTypes  = setsData.armorTypes,
        dropMechanics = setsData.dropMechanics,
	})
end

--ZO_SortFilterList - Item for the WishList tab's list (called within BuildMasterList)
function WL.CreateEntryForItem(item)
    local itemLink = WL.buildItemLink(item.id, item.quality)
--d("[WL.CreateEntryForItem] " .. itemLink)

	local setId = item.setId
    local setName = item.setName
    --local name = GetItemLinkName(itemLink)
	if setId == nil or setName == nil then
        local _, setLocName, _, _, _, setLocId = GetItemLinkSetInfo(itemLink, false)
        --Remove the gender stuff from the setname
        setName = zo_strformat("<<C:1>>", setLocName)
        setId = setLocId
    end
    --If the quality is not set, set it with no matter which quality now
    if item.quality == nil then
        item.quality = WISHLIST_QUALITY_ALL
    end
    --Get the names of the types (for search and order functions)
    local itemTypeName, itemArmorOrWeaponTypeName, itemSlotName, itemTraitName, itemQualityName = WL.getItemTypeNamesForSortListEntry(item.itemType, item.armorOrWeaponType, item.slot, item.trait, item.quality)

    zoneIdsAdded = {}
    zoneIdNames = {}
    wayshrinesAdded = {}
    wayshrineNames = {}
    --Get the drop location(s) of the set via LibSets
    local dropLocationsZoneIds = libSets.GetZoneIds(setId)
    --Get the drop location wayshrines
    local setWayshrines = libSets.GetWayshrineIds(setId)
    checkAndGetWayshrineName(setWayshrines)
    --Get the DLC id
    local dlcId = libSets.GetDLCId(setId)
    local dlcName = libSets.GetDLCName(dlcId)
    --Get set type
    local setType = libSets.GetSetType(setId)
    local setTypeName = libSets.GetSetTypeName(setType)
    --Get traits needed for craftable sets
    local traitsNeeded = libSets.GetTraitsNeeded(setId)
    --The return table of the item on the WishList
    local setsData = WL.accData.sets[setId]
    local wlEntryTable = {
        type                    = 1, -- for the search method to work -> Find the processor in zo_stringsearch:Process()
        setId                   = setId,
        id                      = item.id,
        itemType                = item.itemType,
        itemTypeName            = itemTypeName,
        trait                   = item.trait,
        traitName               = itemTraitName,
        armorOrWeaponType       = item.armorOrWeaponType,
        armorOrWeaponTypeName   = itemArmorOrWeaponTypeName,
        slot                    = item.slot,
        slotName                = itemSlotName,
        name                    = setName,
        itemLink                = itemLink,
        timestamp               = item.timestamp,
        quality                 = item.quality,
        qualityName             = itemQualityName,
        --LibSets data
        setType     = setType,
        traitsNeeded= traitsNeeded,
        dlcId       = dlcId,
        zoneIds     = dropLocationsZoneIds,
        wayshrines  = setWayshrines,
        zoneIdNames = zoneIdNames,
        wayshrineNames = wayshrineNames,
        dlcName     = dlcName,
        setTypeName = setTypeName,
        armorTypes  = setsData.armorTypes,
        dropMechanics = setsData.dropMechanics,
    }
    --Build the data entry for the ZO_SortScrollList row (for searching and sorting with the names AND the ids!)
	return wlEntryTable
end

--ZO_SortFilterList - Item for the History tab's list (called within BuildMasterList)
function WL.CreateHistoryEntryForItem(item)
    local itemLink = WL.buildItemLink(item.id, item.quality)
--d("[WL.CreateHistoryEntryForItem] " .. itemLink .. ", timestamp: " .. tostring(item.timestamp))
    local setId = item.setId
    local setName = item.setName
    --local name = GetItemLinkName(itemLink)
    if setId == nil or setName == nil then
        local _, setLocName, _, _, _, setLocId = GetItemLinkSetInfo(itemLink, false)
        --Remove the gender stuff from the setname
        setName = zo_strformat("<<C:1>>", setLocName)
        setId = setLocId
    end
    --If the quality is not set, set it with no matter which quality now
    if item.quality == nil then
        item.quality = WISHLIST_QUALITY_ALL
    end
    --Get the names of the types (for search and order functions)
    local itemTypeName, itemArmorOrWeaponTypeName, itemSlotName, itemTraitName, itemQualityName = WL.getItemTypeNamesForSortListEntry(item.itemType, item.armorOrWeaponType, item.slot, item.trait, item.quality)

    zoneIdsAdded = {}
    zoneIdNames = {}
    wayshrinesAdded = {}
    wayshrineNames = {}
    --Get the drop location(s) of the set via LibSets
    local dropLocationsZoneIds = libSets.GetZoneIds(setId)
    --Get the drop location wayshrines
    local setWayshrines = libSets.GetWayshrineIds(setId)
    checkAndGetWayshrineName(setWayshrines)
    --Get the DLC id
    local dlcId = libSets.GetDLCId(setId)
    local dlcName = libSets.GetDLCName(dlcId)
    --Get set type
    local setType = libSets.GetSetType(setId)
    local setTypeName = libSets.GetSetTypeName(setType)
    --Get traits needed for craftable sets
    local traitsNeeded = libSets.GetTraitsNeeded(setId)
    --d(">>>>itemType: " .. tostring(itemTypeName) .. ", armorOrWeaponType: " .. tostring(itemArmorOrWeaponTypeName) .. ", slot: " ..tostring(itemSlotName) .. ", trait: " .. tostring(itemTraitName))
    --Build the data entry for the ZO_SortScrollList row (for searching and sorting with the names AND the ids!)
    local setsData = WL.accData.sets[setId]
    return({
        type                    = 1, -- for the search method to work -> Find the processor in zo_stringsearch:Process()
        setId                   = setId,
        id                      = item.id,
        itemType                = item.itemType,
        itemTypeName            = itemTypeName,
        trait                   = item.trait,
        traitName               = itemTraitName,
        armorOrWeaponType       = item.armorOrWeaponType,
        armorOrWeaponTypeName   = itemArmorOrWeaponTypeName,
        slot                    = item.slot,
        slotName                = itemSlotName,
        name                    = setName,
        date                    = item.date,
        itemLink                = itemLink,
        timestamp               = item.timestamp,
        username                = item.username,
        displayName             = function() if item.displayName ~= nil then return item.displayName else return "" end end,
        locality                = item.locality,
        quality                 = item.quality,
        qualityName             = itemQualityName,
        --LibSets data
        setType     = setType,
        traitsNeeded= traitsNeeded,
        dlcId       = dlcId,
        zoneIds     = dropLocationsZoneIds,
        wayshrines  = setWayshrines,
        zoneIdNames = zoneIdNames,
        wayshrineNames = wayshrineNames,
        dlcName     = dlcName,
        setTypeName = setTypeName,
        armorTypes  = setsData.armorTypes,
        dropMechanics = setsData.dropMechanics,
    })
end

------------------------------------------------
--- Wishlist / History - Add items
------------------------------------------------
--Add item to the WishList SavedVariables
function WishList:AddItem(items, charData, alreadyOnWishlistCheckDone, noAddedChatOutput)
    alreadyOnWishlistCheckDone = alreadyOnWishlistCheckDone or false
    noAddedChatOutput = noAddedChatOutput or false
    local count = 0
    local wishList = WL.getWishListSaveVars(charData, "WishList:AddItem")
    if wishList == nil then return true end
    --local charNameChat = WL.buildCharNameChatText(charData, nil)
--d("[WL]AddItem, SV found for charName " .. tostring(charData.name) .. ", CharId: " .. tostring(charData.id))
    local charNameChat = charData.name
    local displayName = GetDisplayName()
    for i = 1, #items do
		local item = items[i]
        --Is the item already on the WishList?
        local itemLink
        if item.itemLink ~= nil then
            itemLink = item.itemLink
        else
            itemLink = WL.buildItemLink(item.id, item.quality)
        end
        local alreadyOnWishList = false
        if not alreadyOnWishlistCheckDone then
            alreadyOnWishList = WL.isItemAlreadyOnWishlist(itemLink, item.id, charData) or false
        end
        if not alreadyOnWishList then
            --Add the date & time as the item got added
            if item.timestamp == nil then
                item = WL.addTimeStampToItem(item)
            end
            --Insert the item to the character dependent WishList SavedVars global table WishList_Data["Default"][GetDisplayName()][charId]["Data"]["wishList"]
            --table.insert(wishList, item)
--d("[WishList]AddItem, item quality: " ..tostring(item.quality))
            table.insert(WishList_Data["Default"][displayName][charData.id]["Data"]["wishList"], item)
            count = count + 1
            local traitId = item.trait
            local traitText = ""
            if traitId ~= nil then
                traitText = WL.TraitTypes[traitId]
                traitText = WL.buildItemTraitIconText(traitText, traitId)
            end
            if not noAddedChatOutput then
                d(itemLink..GetString(WISHLIST_ADDED) .. ", " .. traitText .. charNameChat)
            end
        end
	end
    d(zo_strformat(GetString(WISHLIST_ITEMS_ADDED) .. charNameChat .. " (" .. WL.getWishListItemCount(charData) .. ")", count)) -- count.." item(s) added to Wish List"
    WL.updateRemoveAllButon()

	if WL.window ~= nil then
        WishList:ReloadItems()
	end
end

function WL.AddSetItems(addType)
    --d("[WL.AddSetItems] addType: " .. tostring(addType))
    --Close the add item dialog at first!
    WishListAddItemDialogCancel:callback()

    local charsComboBox = WishListAddItemDialogContentCharsCombo.m_comboBox
    local itemTypeComboBox = WishListAddItemDialogContentItemTypeCombo.m_comboBox
    local armorOrWeaponComboBox = WishListAddItemDialogContentArmorOrWeaponTypeCombo.m_comboBox
    local slotComboBox = WishListAddItemDialogContentSlotCombo.m_comboBox
    local traitComboBox = WishListAddItemDialogContentTraitCombo.m_comboBox
    local qualityComboBox = WishListAddItemDialogContentQualityCombo.m_comboBox

    local addType2ChatMsg = {
        [WISHLIST_ADD_TYPE_WHOLE_SET]                         = WL.buildTooltip(GetString(WISHLIST_DIALOG_ADD_WHOLE_SET_TT)),
        [WISHLIST_ADD_TYPE_BY_ITEMTYPE]                       = WL.buildTooltip(GetString(WISHLIST_DIALOG_ADD_ALL_TYPE_OF_SET_TT), itemTypeComboBox.m_selectedItemText:GetText()),
        [WISHLIST_ADD_TYPE_BY_ITEMTYPE_AND_ARMOR_WEAPON_TYPE] = WL.buildTooltip(GetString(WISHLIST_DIALOG_ADD_ALL_TYPE_TYPE_OF_SET_TT), itemTypeComboBox.m_selectedItemText:GetText(), armorOrWeaponComboBox.m_selectedItemText:GetText()),
        [WISHLIST_ADD_BODY_PARTS_ARMOR]                       = WL.buildTooltip(GetString(WISHLIST_DIALOG_ADD_BODY_PARTS_ARMOR_OF_SET_TT)),
        [WISHLIST_ADD_ONE_HANDED_WEAPONS]                     = WL.buildTooltip(GetString(WISHLIST_DIALOG_ADD_ONE_HANDED_WEAPONS_OF_SET_TT)),
        [WISHLIST_ADD_TWO_HANDED_WEAPONS]                     = WL.buildTooltip(GetString(WISHLIST_DIALOG_ADD_TWO_HANDED_WEAPONS_OF_SET_TT)),
        [WISHLIST_ADD_MONSTER_SET_PARTS_ARMOR]                = WL.buildTooltip(GetString(WISHLIST_DIALOG_ADD_MONSTER_SET_PARTS_ARMOR_OF_SET_TT)),
    }
    local chatMsg = addType2ChatMsg[addType] or ""
    if chatMsg == nil or chatMsg == "" then return false end
    d(chatMsg)

    --Get the character data where the set parts should be added to the wishlist
    local selectedCharData = charsComboBox.m_selectedItemData
    if selectedCharData == nil or selectedCharData.id == nil then return false end
    --Get the selected itemType
    local selectedItemTypeData = itemTypeComboBox.m_selectedItemData
    if selectedItemTypeData == nil or selectedItemTypeData.id == nil then return false end
    --Get the selected weapon or armor type
    local selectedItemArmorOrWeaponTypeData = armorOrWeaponComboBox.m_selectedItemData
    if selectedItemArmorOrWeaponTypeData == nil or selectedItemArmorOrWeaponTypeData.id == nil then return false end
    --Get the selected slot type
    local selectedSlotData = slotComboBox.m_selectedItemData
    if selectedSlotData == nil or selectedSlotData.id == nil then return false end
    --get the selected item trait
    local selectedItemTraitData = traitComboBox.m_selectedItemData
    if selectedItemTraitData == nil or selectedItemTraitData.id == nil then return false end
    --get the selected quality
    local selectedItemQualityData = qualityComboBox.m_selectedItemData
    if selectedItemQualityData == nil or selectedItemQualityData.id == nil then return false end

--d(">selectedItemType: " ..tostring(selectedItemTypeData.id) .. ", selectedItemArmorOrWeaponTypeData: " .. tostring(selectedItemArmorOrWeaponTypeData.id) .. ", selectedSlotData: " ..tostring(selectedSlotData.id) .. ", selectedItemTrait: " ..tostring(selectedItemTraitData.id) .. ", selectedItemQuality: " ..tostring(selectedItemQualityData.id))
    --The items to add table
    local items = {}
    --Get the set parts to add
    items = WL.getSetItemsByData(WL.currentSetId, selectedItemTypeData, selectedItemArmorOrWeaponTypeData, selectedSlotData, selectedItemTraitData, selectedItemQualityData, addType)
    --Add the items now, if some were found
    if #items > 0 then
        --Add the currently selected values to the "Last added" history data of the SavedVariables
        WL.addLastAddedHistoryFromAddItemDialog(WL.currentSetId, itemTypeComboBox, armorOrWeaponComboBox, traitComboBox, slotComboBox, charsComboBox, qualityComboBox, addType)
        --Add the found set items to the WishList of the selected user now
        WishList:AddItem(items, selectedCharData)
    else
        d("!!! " .. GetString(WISHLIST_NO_ITEMS_ADDED_WITH_SELECTED_DATA))
    end
end

--Add item to the history SavedVariables
function WishList:AddHistoryItem(items, charData, noAddedChatOutput)
--d("[WishList:AddHistoryItem]")
    noAddedChatOutput = noAddedChatOutput or false
    local count = 0
    local history = WL.getHistorySaveVars(charData)
    if history == nil then return true end
    --local charNameChat = WL.buildCharNameChatText(charData, nil)
    local charNameChat = charData.name
    local displayName = GetDisplayName()
    for i = 1, #items do
        local item = items[i]
        --Is the item already on the WishList?
        local itemLink
        if item.itemLink ~= nil then
            itemLink = item.itemLink
        else
            itemLink = WL.buildItemLink(item.id, item.quality)
        end
--d(">item added to history: " .. itemLink)
        if item.timestamp == nil then
            item = WL.addTimeStampToItem(item)
        end
        --table.insert(history, item)
        table.insert(WishList_Data["Default"][displayName][charData.id]["Data"]["history"], item)
        count = count + 1
        local traitId = item.trait
        local traitText = ""
        if traitId ~= nil then
            traitText = WL.TraitTypes[traitId]
            traitText = WL.buildItemTraitIconText(traitText, traitId)
        end
        if not noAddedChatOutput then
            d(itemLink..GetString(WISHLIST_HISTORY_ADDED) .. ", " .. traitText .. charNameChat)
        end
    end
    d(zo_strformat(GetString(WISHLIST_HISTORY_ITEMS_ADDED) .. charNameChat .. " (" .. WL.getHistoryItemCount(charData) .. ")", count)) -- count.." item(s) added to Wish List"
    WL.updateRemoveAllButon()

    if WL.window ~= nil then
        WishList:ReloadItems()
    end
end

------------------------------------------------
--- Wishlist / History - Remove items
------------------------------------------------
function WishList:RemoveItem(item, charData)
    local index = -1
    local wishList = WL.getWishListSaveVars(charData, "WishList:RemoveItem")
    if wishList == nil then return true end
    --local charNameChat = WL.buildCharNameChatText(charData, nil)
    local displayName = GetDisplayName()
    local charNameChat = charData.name
	for i = 1, #wishList do
		local itm = wishList[i]
		if itm.id == item.id then
			index = i
			break
		end
	end
	if index ~= -1 then
		--table.remove(wishList, index)
        table.remove(WishList_Data["Default"][displayName][charData.id]["Data"]["wishList"], index)
        local itemLink
        if item.itemLink ~= nil then
            itemLink = item.itemLink
        else
            itemLink = WL.buildItemLink(item.id, item.quality)
        end
        local traitId = item.trait
        local itemTraitText = WL.TraitTypes[traitId]
        itemTraitText = WL.buildItemTraitIconText(itemTraitText, traitId)
		d(itemLink..GetString(WISHLIST_REMOVED) .. ", " .. itemTraitText .. charNameChat .. " (" .. WL.getWishListItemCount(charData) .. ")")
	end
    WL.updateRemoveAllButon()
    WishList:ReloadItems()
end

function WishList:RemoveHistoryItem(item, charData)
    local index = -1
    local history = WL.getHistorySaveVars(charData)
    if history == nil then return true end
    local displayName = GetDisplayName()
    --local charNameChat = WL.buildCharNameChatText(charData, nil)
    local charNameChat = charData.name
    for i = 1, #history do
        local itm = history[i]
        if itm.id == item.id then
            index = i
            break
        end
    end
    if index ~= -1 then
        --table.remove(history, index)
        table.remove(WishList_Data["Default"][displayName][charData.id]["Data"]["history"], index)
        local itemLink
        if item.itemLink ~= nil then
            itemLink = item.itemLink
        else
            itemLink = WL.buildItemLink(item.id, item.quality)
        end
        local traitId = item.trait
        local itemTraitText = WL.TraitTypes[traitId]
        itemTraitText = WL.buildItemTraitIconText(itemTraitText, traitId)
        d(itemLink..GetString(WISHLIST_HISTORY_REMOVED) .. ", " .. itemTraitText .. charNameChat.. " (" .. WL.getHistoryItemCount(charData) .. ")")
    end
    WL.updateRemoveAllButon()
    WishList:ReloadItems()
end

function WishList:RemoveAllItemsWithCriteria(criteria, charData)
--d("[WL]RemoveAllItemsWithCriteria")
    if criteria == nil then return false end
    local wishList = WL.getWishListSaveVars(charData, "WishList:RemoveAllItemsWithCriteria")
    if wishList == nil then return true end
    --local charNameChat = WL.buildCharNameChatText(charData, nil)
    local displayName = GetDisplayName()
    local charNameChat = charData.name
    local setName = ""
    local cnt = 0
    for i = #wishList, 1, -1 do
        local itm = wishList[i]
        --Check the criteria now, which is specified, and combine them for a check against the WishList items
        local removeItemNow = false
        if criteria.timestamp ~= nil then
--d(">timestamp: " ..tostring(criteria.timestamp) .. "/" .. tostring(itm.timestamp))
            if itm.timestamp == criteria.timestamp then
                removeItemNow = true
            else
                removeItemNow = false
            end
        end
        if criteria.itemType ~= nil then
--d(">itemType: " ..tostring(criteria.itemType) .. "/" .. tostring(itm.itemType))
            if itm.itemType == criteria.itemType then
                removeItemNow = true
            else
                removeItemNow = false
            end
        end
        if criteria.armorOrWeaponType ~= nil then
--d(">armorOrWeaponType: " ..tostring(criteria.armorOrWeaponType) .. "/" .. tostring(itm.armorOrWeaponType))
            if itm.armorOrWeaponType == criteria.armorOrWeaponType then
                removeItemNow = true
            else
                removeItemNow = false
            end
        end
        if criteria.slot ~= nil then
--d(">slot: " ..tostring(criteria.slot) .. "/" .. tostring(itm.slot))
            if itm.slot == criteria.slot then
                removeItemNow = true
            else
                removeItemNow = false
            end
        end
        if criteria.trait ~= nil then
--d(">trait: " ..tostring(criteria.trait) .. "/" .. tostring(itm.trait))
            if itm.trait == criteria.trait then
                removeItemNow = true
            else
                removeItemNow = false
            end
        end
        if removeItemNow then
--d(">>>remove item now!")
            local itemLink
            if itm.itemLink ~= nil then
                itemLink = itm.itemLink
            else
                itemLink = WL.buildItemLink(itm.id, itm.quality)
            end
            local traitId = itm.trait
            local itemTraitText = WL.TraitTypes[traitId]
            itemTraitText = WL.buildItemTraitIconText(itemTraitText, traitId)
            --Remove the WishList entry of the current, or the selected char
            table.remove(WishList_Data["Default"][displayName][charData.id]["Data"]["wishList"], i)
            d(itemLink..GetString(WISHLIST_REMOVED) .. ", " .. itemTraitText .. charNameChat)
            cnt = cnt +1
        end
    end
    d(zo_strformat(GetString(WISHLIST_ITEMS_REMOVED) .. " " .. charNameChat .. " (" .. WL.getWishListItemCount(charData) .. ")", cnt)) -- count.." item(s) removed from Wish List"
    WL.updateRemoveAllButon()
    WishList:ReloadItems()
end


function WishList:RemoveAllItemsOfSet(setId, charData)
    if setId == nil then return false end
    local wishList = WL.getWishListSaveVars(charData, "WishList:RemoveAllItemsOfSet")
    if wishList == nil then return true end
    --local charNameChat = WL.buildCharNameChatText(charData, nil)
    local displayName = GetDisplayName()
    local charNameChat = charData.name
    local setName = ""
    local cnt = 0
    for i = #wishList, 1, -1 do
        local itm = wishList[i]
        if itm.setId == setId then
            local itemLink = WL.buildItemLink(itm.id, itm.quality)
            if setName == "" then
                local _, setLocName, _, _, _, setLocId = GetItemLinkSetInfo(itemLink, false)
                --Remove the gender stuff from the setname
                setName = zo_strformat("<<C:1>>", setLocName)
            end
            local traitId = itm.trait
            local itemTraitText = WL.TraitTypes[traitId]
            itemTraitText = WL.buildItemTraitIconText(itemTraitText, traitId)
            --Remove the WishList entry of the current, or the selected char
            --table.remove(wishList, i)
            table.remove(WishList_Data["Default"][displayName][charData.id]["Data"]["wishList"], i)
            d(itemLink..GetString(WISHLIST_REMOVED) .. ", " .. itemTraitText .. charNameChat)
            cnt = cnt +1
        end
    end
    d(zo_strformat(GetString(WISHLIST_ITEMS_REMOVED) .. ", Set: \"" .. setName .. "\" " .. charNameChat .. " (" .. WL.getWishListItemCount(charData) .. ")", cnt)) -- count.." item(s) removed from Wish List"
    WL.updateRemoveAllButon()
    WishList:ReloadItems()
end

function WishList:ChangeQualityOfItem(item, charData, newQuality)
    local index = -1
    local wishList = WL.getWishListSaveVars(charData, "WishList:ChangeQualityOfItem")
    if wishList == nil then return true end
    --local charNameChat = WL.buildCharNameChatText(charData, nil)
    local displayName = GetDisplayName()
    local charNameChat = charData.name
    for i = 1, #wishList do
        local itm = wishList[i]
        if itm.id == item.id then
            index = i
            break
        end
    end
    if index ~= -1 then
        local currentWishListSVEntry = WishList_Data["Default"][displayName][charData.id]["Data"]["wishList"][index]
        if currentWishListSVEntry ~= nil then
            currentWishListSVEntry["quality"] = newQuality
        end
        local itemLink
        if item.itemLink ~= nil then
            itemLink = item.itemLink
        else
            itemLink = WL.buildItemLink(item.id, item.quality)
        end
        local traitId = item.trait
        local itemTraitText = WL.TraitTypes[traitId]
        itemTraitText = WL.buildItemTraitIconText(itemTraitText, traitId)
        d(itemLink.. zo_strformat(GetString(WISHLIST_UPDATED), GetString(WISHLIST_HEADER_QUALITY)) .. ", " .. itemTraitText .. charNameChat .. " (" .. WL.getWishListItemCount(charData) .. ")")
    end
    WishList:ReloadItems()
end

function WishList:ChangeQualityOfItemsOfSet(setId, charData, newQuality)
    if setId == nil then return false end
    local wishList = WL.getWishListSaveVars(charData, "WishList:ChangeQualityOfItemsOfSet")
    if wishList == nil then return true end
    --local charNameChat = WL.buildCharNameChatText(charData, nil)
    local displayName = GetDisplayName()
    local charNameChat = charData.name
    local setName = ""
    local cnt = 0
    for i = #wishList, 1, -1 do
        local itm = wishList[i]
        if itm.setId == setId then
            local itemLink = WL.buildItemLink(itm.id, itm.quality)
            if setName == "" then
                local _, setLocName, _, _, _, setLocId = GetItemLinkSetInfo(itemLink, false)
                --Remove the gender stuff from the setname
                setName = zo_strformat("<<C:1>>", setLocName)
            end
            local traitId = itm.trait
            local itemTraitText = WL.TraitTypes[traitId]
            itemTraitText = WL.buildItemTraitIconText(itemTraitText, traitId)
            --Update the WishList entry of the current, or the selected char
            local currentWishListEntryOfSetItem = WishList_Data["Default"][displayName][charData.id]["Data"]["wishList"][i]
            if currentWishListEntryOfSetItem ~= nil then
                currentWishListEntryOfSetItem["quality"] = newQuality
                d(itemLink..zo_strformat(GetString(WISHLIST_UPDATED), GetString(WISHLIST_HEADER_QUALITY)) .. ", " .. itemTraitText .. charNameChat)
                cnt = cnt +1
            end
        end
    end
    d(zo_strformat(GetString(WISHLIST_ITEMS_UPDATED) .. ", Set: \"" .. setName .. "\" " .. charNameChat .. " (" .. WL.getWishListItemCount(charData) .. ")", cnt)) -- count.." item(s) updated in Wish List"
    WishList:ReloadItems()
end

function WishList:RemoveAllHistoryItemsWithCriteria(criteria, charData)
    --d("[WL]RemoveAllItemsWithCriteria")
    if criteria == nil then return false end
    local history = WL.getHistorySaveVars(charData)
    if history == nil then return true end
    --local charNameChat = WL.buildCharNameChatText(charData, nil)
    local displayName = GetDisplayName()
    local charNameChat = charData.name
    local setName = ""
    local cnt = 0
    for i = #history, 1, -1 do
        local itm = history[i]
        --Check the criteria now, which is specified, and combine them for a check against the WishList items
        local removeItemNow = false
        if criteria.timestamp ~= nil then
            --d(">timestamp: " ..tostring(criteria.timestamp) .. "/" .. tostring(itm.timestamp))
            if itm.timestamp == criteria.timestamp then
                removeItemNow = true
            else
                removeItemNow = false
            end
        end
        if criteria.itemType ~= nil then
            --d(">itemType: " ..tostring(criteria.itemType) .. "/" .. tostring(itm.itemType))
            if itm.itemType == criteria.itemType then
                removeItemNow = true
            else
                removeItemNow = false
            end
        end
        if criteria.armorOrWeaponType ~= nil then
            --d(">armorOrWeaponType: " ..tostring(criteria.armorOrWeaponType) .. "/" .. tostring(itm.armorOrWeaponType))
            if itm.armorOrWeaponType == criteria.armorOrWeaponType then
                removeItemNow = true
            else
                removeItemNow = false
            end
        end
        if criteria.slot ~= nil then
            --d(">slot: " ..tostring(criteria.slot) .. "/" .. tostring(itm.slot))
            if itm.slot == criteria.slot then
                removeItemNow = true
            else
                removeItemNow = false
            end
        end
        if criteria.trait ~= nil then
            --d(">trait: " ..tostring(criteria.trait) .. "/" .. tostring(itm.trait))
            if itm.trait == criteria.trait then
                removeItemNow = true
            else
                removeItemNow = false
            end
        end
        if removeItemNow then
            --d(">>>remove item now!")
            local itemLink
            if itm.itemLink ~= nil then
                itemLink = itm.itemLink
            else
                itemLink = WL.buildItemLink(itm.id, itm.quality)
            end
            local traitId = itm.trait
            local itemTraitText = WL.TraitTypes[traitId]
            itemTraitText = WL.buildItemTraitIconText(itemTraitText, traitId)
            --Remove the history entry of the current, or the selected char
            table.remove(WishList_Data["Default"][displayName][charData.id]["Data"]["history"], i)
            d(itemLink..GetString(WISHLIST_HISTORY_REMOVED) .. ", " .. itemTraitText .. charNameChat)
            cnt = cnt +1
        end
    end
    d(zo_strformat(GetString(WISHLIST_HISTORY_ITEMS_REMOVED) .. " " .. charNameChat .. " (" .. WL.getHistoryItemCount(charData) .. ")", cnt)) -- count.." item(s) removed from history"
    WL.updateRemoveAllButon()
    WishList:ReloadItems()
end

function WishList:RemoveAllHistoryItemsOfSet(setId, charData)
    if setId == nil then return false end
    local history = WL.getHistorySaveVars(charData)
    if history == nil then return true end
    --local charNameChat = WL.buildCharNameChatText(charData, nil)
    local displayName = GetDisplayName()
    local charNameChat = charData.name
    local setName = ""
    local cnt = 0
    for i = #history, 1, -1 do
        local itm = history[i]
        if itm.setId == setId then
            local itemLink = WL.buildItemLink(itm.id, itm.quality)
            if setName == "" then
                local _, setLocName, _, _, _, setLocId = GetItemLinkSetInfo(itemLink, false)
                --Remove the gender stuff from the setname
                setName = zo_strformat("<<C:1>>", setLocName)
            end
            local traitId = itm.trait
            local itemTraitText = WL.TraitTypes[traitId]
            itemTraitText = WL.buildItemTraitIconText(itemTraitText, traitId)
            --Remove the WishList entry of the current, or the selected char
            --table.remove(history, i)
            table.remove(WishList_Data["Default"][displayName][charData.id]["Data"]["history"], i)
            d(itemLink..GetString(WISHLIST_HISTORY_REMOVED) .. ", " .. itemTraitText .. charNameChat)
            cnt = cnt + 1
        end
    end
    d(zo_strformat(GetString(WISHLIST_HISTORY_ITEMS_REMOVED) .. ", Set: \"" .. setName .. "\" " .. charNameChat .. " (" .. WL.getHistoryItemCount(charData) .. ")", cnt)) -- count.." item(s) removed from history"
    WL.updateRemoveAllButon()
    WishList:ReloadItems()
end

function WishList:RemoveAllItems(charData)
    local wishList = WL.getWishListSaveVars(charData, "WishList:RemoveAllItems")
    if wishList == nil then return true end
    --local charNameChat = WL.buildCharNameChatText(charData, nil)
    local displayName = GetDisplayName()
    local charNameChat = charData.name
    local cnt = 0
    for i = #wishList, 1, -1 do
        local itm = wishList[i]
        local itemLink = WL.buildItemLink(itm.id, itm.quality)
        local traitId = itm.trait
        local itemTraitText = WL.TraitTypes[traitId]
        itemTraitText = WL.buildItemTraitIconText(itemTraitText, traitId)
        --Remove the WishList entry of the current, or the selected char
        --wishList[i] = nil
        WishList_Data["Default"][displayName][charData.id]["Data"]["wishList"][i] = nil
        d(itemLink..GetString(WISHLIST_REMOVED) .. ", " .. itemTraitText .. charNameChat)
        cnt = cnt + 1
    end
    --Clear the wishlist of the current, or the selected char
    --wishList = {}
    WishList_Data["Default"][displayName][charData.id]["Data"]["wishList"] = nil
    d(zo_strformat(GetString(WISHLIST_ITEMS_REMOVED) .. charNameChat .. " (" .. WL.getWishListItemCount(charData) .. ")", cnt)) -- count.." item(s) removed from Wish List"
    WL.updateRemoveAllButon()
    WishList:ReloadItems()
end

function WishList:ClearHistory(charData)
    local history = WL.getHistorySaveVars(charData)
    if history == nil then return true end
    --local charNameChat = WL.buildCharNameChatText(charData, nil)
    local displayName = GetDisplayName()
    local charNameChat = charData.name
    local cnt = 0
--d("[WishList:ClearHistory]char: " .. tostring(charNameChat))
    for i = #history, 1, -1 do
        local itm = history[i]
        local itemLink = WL.buildItemLink(itm.id, itm.quality)
        local traitId = itm.trait
        local itemTraitText = WL.TraitTypes[traitId]
        itemTraitText = WL.buildItemTraitIconText(itemTraitText, traitId)
        --Remove the History entry of the current, or the selected char
        --history[i] = nil
        WishList_Data["Default"][displayName][charData.id]["Data"]["history"][i] = nil
        d(itemLink..GetString(WISHLIST_HISTORY_REMOVED) .. ", " .. itemTraitText .. charNameChat)
        cnt = cnt + 1
    end
    --Clear the wishlist of the current, or the selected char
    --history = {}
    WishList_Data["Default"][displayName][charData.id]["Data"]["history"] = nil
    d(zo_strformat(GetString(WISHLIST_HISTORY_ITEMS_REMOVED) .. charNameChat .. " (" .. WL.getHistoryItemCount(charData) .. ")", cnt)) -- count.." item(s) removed from history"
    WL.updateRemoveAllButon()
    WishList:ReloadItems()
end

function WishList:ReloadItems()
    WL.window:RefreshData()
end

--Add one  last added setItems history (added via the "Add item dialog")
function WishList:AddLastAddedHistory(newAddedData)
    if not newAddedData then return end
    newAddedData.dateTime = newAddedData.dateTime or GetTimeStamp()
    local lastAddedHistoryData = WL.accData.lastAddedViaDialog
    if not lastAddedHistoryData then return end
   lastAddedHistoryData[newAddedData.dateTime] = newAddedData
end

--Get the last added setItems history (added via the "Add item dialog")
function WishList:GetLastAddedHistory()
    local lastAddedHistoryData = WL.accData.lastAddedViaDialog
    if not lastAddedHistoryData then return end
    return lastAddedHistoryData
end

------------------------------------------------
--- Settings / SavedVariables
------------------------------------------------
local function afterSettings()
    --==================================================================================================================
    --UPDATES TO THE SETTINGS AFTER THEY HAVE BEEN LOADED
    --==================================================================================================================
    local settings = WL.data

    --WishList version 2.8: TRansfer old obsolete setting useSortTiebrakerName (if set) to new dropdown box setting useSortTiebraker
    if settings.useSortTiebrakerName ~= nil then
        if settings.useSortTiebrakerName == true then
            WL.data.useSortTiebraker = 1
        end
        WL.data.useSortTiebrakerName = nil
    end

    --WishList version 2.96: Added "Add dialog" history of last added data
    --Build characterId entries in the accountWide SavedVariables
    --settings.dialogAddHistory
end

--Migrate the SavedVariables from server non-dependent to server dependent ones
local function migrateSavedVarsToServerDependent()
    local worldName = GetWorldName()
    d("[WishList]SavedVariables -> Migrating to server dependent now")
    local accountName = GetDisplayName()
    if not accountName then return end
    local accountWideSaved = "$AccountWide"
    --[[
         ["Default"] =
        {
            ["@Baertram"] =
            {
                ["$AccountWide"] =
                {
                },
                ["8798292065306120"] =
                {
                },
                ...
            },
        }
    ]]
    --We got all character data in this table (but it was saved account wide!)
    local svDataOFAllAccounts = WishList_Data["Default"]
    if svDataOFAllAccounts ~= nil then
        d(">Found SV of account \'" .. tostring(accountName) .. "\' &  it's WishList enabled characters")
        local copyOfNonServerDependentSV = ZO_ShallowTableCopy(svDataOFAllAccounts)
        if copyOfNonServerDependentSV ~= nil then
            --d(">>Created copy of all accounts and characters, and moved them to the server dependent SV.")
            --Create ServerDependent SavedVariable subtables at top (= "profile" parameter of ZO_SavedVars:New(..., profile, ...))
            WishList_Data[worldName] = copyOfNonServerDependentSV
            return true
        end
    else
        d("<Aborting: Server dependent SavedVariables do already exist for account: " ..tostring(accountName))
    end
    return false
end

function WL.loadSettings()
    WL.SVrelated_doReloadUINow = false
    local addonVars = WL.addonVars
    local lang = GetCVar("language.2")
    if lang == "de" then
        WL.defaultAccSettings.use24hFormat = true
    end

    local worldName = nil
    --Get non-server dependent general settings
    local accDataServerIndependent = ZO_SavedVars:NewAccountWide(addonVars.addonSavedVarsAllServers, 999, "AccountwideDataServerIndependent", {}, nil, nil)
    if accDataServerIndependent.savedVarsWereMigratedToServerDependent then
        --SV were migrated to the table containing the worldname e.g. "EU Megaserver"
        worldName = GetWorldName()
        if WishList_Data[worldName] ~= nil then
            --Invalidate the old non-server dependent SavedVariables
            if WishList_Data["Default"] ~= nil then
                d("[WishList]OLD Non-server dependent WishList SavedVariables still exist -> Removing them now")
                WishList_Data["Default"] = nil
                WL.SVrelated_doReloadUINow = true
            end
        end
    end

    --Load the account wide settings (Sets, save mode of SavedVars, etc.)
    --worldName will be nil before migration so the data wil be read from the old $AccountWide table.
    --After migration the $AccountWide table (without server!) contains the boolean entry "savedVarsWereMigratedToServerDependent=true", and thus the variable
    --worldName will be e.g. "EU Megaserver"
    --ZO_SavedVars:NewAccountWide(savedVariableTable, version, namespace, defaults, profile, displayName)
    WL.accData = ZO_SavedVars:NewAccountWide(addonVars.addonSavedVars, 999, "AccountwideData", WL.defaultAccSettings, worldName, nil)

    --Check, by help of basic version 999 settings, if the settings should be loaded for each character or account wide
    --Use the current addon version to read the settings now
    if (WL.accData.saveMode == 1) then
        --Load the character user settings
        WL.data = ZO_SavedVars:NewCharacterIdSettings(addonVars.addonSavedVars, addonVars.addonSavedVarsVersion, "Data", WL.defaultSettings, worldName)
        --------------------------------------------------------------------------------------------------------------------
    else
        --Load the account wide user settings
        WL.data = ZO_SavedVars:NewAccountWide(addonVars.addonSavedVars, addonVars.addonSavedVarsVersion, "Data", WL.defaultSettings, worldName, nil)
    end

    --Apply some fixes/add subtables and data, after the settings were loaded
    afterSettings()

    --Migrate the SavedVariables to ServerDependent ones
    if not accDataServerIndependent.savedVarsWereMigratedToServerDependent then
        if migrateSavedVarsToServerDependent() == true then
            accDataServerIndependent.savedVarsWereMigratedToServerDependent = true
            accDataServerIndependent.savedVarsWereMigratedToServerDependentTimeStamp = os.date("%c")
            d("[WishList]SavedVariables were successfully migrated to server dependent ones at: " ..tostring(accDataServerIndependent.savedVarsWereMigratedToServerDependentTimeStamp) .. "!")
            WL.SVrelated_doReloadUINow = true
        else
            d("[WishList]SavedVariables were NOT migrated. Still using non-server dependent ones!")
        end
    end
    WL.accDataServerIndependent = accDataServerIndependent
end

------------------------------------------------
--- MainMenu button
------------------------------------------------
local function WL_addMainMenuButton()
    local settings = WL.data
    --Create the libMainMenu 2.0 object
    if WL.LMM2 == nil then return end
    WL.LMM2:Init()

    --The name of the button, descriptor
    local descriptor = WL.addonVars.addonName
    -- Add to main menu
    local categoryLayoutInfo =
    {
        binding         = "WISHLIST_SHOW",
        categoryName    = SI_BINDING_NAME_WISHLIST_SHOW,
        callback        = function() WishList:Show() end,
        visible         = function(buttonData)
                return settings.showMainMenuButton
        end,
        normal          = "esoui/art/tradinghouse/tradinghouse_listings_tabicon_up.dds",
        pressed         = "esoui/art/tradinghouse/tradinghouse_listings_tabicon_down.dds",
        highlight       = "esoui/art/tradinghouse/tradinghouse_listings_tabicon_over.dds",
        disabled        = "esoui/art/tradinghouse/tradinghouse_listings_tabicon_disabled.dds",
    }
    WL.LMM2:AddMenuItem(descriptor, categoryLayoutInfo)
end

------------------------------------------------
--- Slash commands
------------------------------------------------
local function WL_RegisterSlashCommands()
    local function showWishList()
        WishList:Show()
    end
    -- Register slash commands
    SLASH_COMMANDS["/wl"]       = showWishList
    SLASH_COMMANDS["/wishlist"] = showWishList
end

------------------------------------------------
--- Initialization
------------------------------------------------

local function WL_Hooks()
    --Sort header OnMouseUp callback function for SHIFT key checks
    local function WL_SortHeaderOnMouseUp(sortHeaderCtrl, upInside)
        --Was the mouse released above the ctrl ?
        if upInside == true and sortHeaderCtrl ~= nil
            and sortHeaderCtrl.GetParent ~= nil and sortHeaderCtrl:GetParent() == WishListFrameHeaders then
            --Was the shift key pressed?
            if IsShiftKeyDown() then
                WL._clickedSortHeader = sortHeaderCtrl
                --Get the key of the sortHeader
                local sortHeaderKey = sortHeaderCtrl.key
                if sortHeaderKey == nil then return end
                local sortTiebrakerChoicesWithSortHeaderKeys = WL.sortTiebrakerChoicesWithSortHeaderKeys
                if sortTiebrakerChoicesWithSortHeaderKeys == nil then return end
                local newTiebrakerValue = 0
                for newTiebrakerIndex, tiebrakerName in ipairs(sortTiebrakerChoicesWithSortHeaderKeys) do
                    if tiebrakerName == sortHeaderKey then
                        local nameOfSortHeader = ""
                        local nameOfSortHeaderCtrl = WINDOW_MANAGER:GetControlByName(sortHeaderCtrl:GetName(), "Name")
                        if nameOfSortHeaderCtrl ~= nil and nameOfSortHeaderCtrl.GetText then
                            nameOfSortHeader = nameOfSortHeaderCtrl:GetText()
                        end
                        d(string.format(GetString(WISHLIST_SORTHEADER_GROUP_CHANGED), tostring(nameOfSortHeader)))
                        newTiebrakerValue = newTiebrakerIndex
                        break
                    end
                end
                --Get the settingsm for the selected key and change it accordingly
                if newTiebrakerValue and newTiebrakerValue > 0 then
                    WL.data.useSortTiebraker = newTiebrakerValue
                    --Rebuild the sortKeys now
                    WL.sortKeys =  WL.getSortKeysWithTiebrakerFromSettings()
                end
                --Do not run the normal sort header group OnMouseDown event now!
                return true
            end
        end
    end
    ZO_PreHook("ZO_SortHeader_OnMouseUp", WL_SortHeaderOnMouseUp)
end

function WL.init(_, addonName)
    local addonVars = WL.addonVars
    if addonName ~= addonVars.addonName then
        --Check if addon "LazyWritCreator" is active
        if(addonName == "DolgubonsLazyWritCreator" or WritCreater ~= nil) then
            WL.otherAddons.LazyWritCreatorActive = true
        end
        return
    end
    if WL.initDone then return end

    --Unregister for on loaded event
    EVENT_MANAGER:UnregisterForEvent(addonVars.addonName, EVENT_ADD_ON_LOADED)

    --The client language
    WL.clientLang = GetCVar("language.2")
    WL.clientLangIsEN = WL.clientLang == "en" or false
    WL.preventerVars.runSetNameLanguageChecks = true

    --Load the settings
    WL.loadSettings()

    --Build the list sortkeys depending on the selected dropdown entry from LAM settings
    WL.sortKeys =  WL.getSortKeysWithTiebrakerFromSettings()

    --Check if the last scan of the sets was done with an older LibSets version
    local scanSetsNowSilently = false
    local lastLibSetsVersionScanDone = WL.accData.setsLastScannedLibSetsVersion
    if lastLibSetsVersionScanDone == nil or lastLibSetsVersionScanDone < libSets.version then
        scanSetsNowSilently = true
    end
    if not scanSetsNowSilently then
        --Check if the sets are updated with LibSets v0.06 (or higher) data
        --Does the "setsLastScanned" entry exist or does the "names" subtable exist?
        --If not we did not scan the sets new and got old setData. Therefore we need to update it now once via LibSets, but silently
        local setsData = WL.accData.sets
        if setsData then
            for _, setData in pairs(setsData) do
                if WL.accData.setsLastScanned == nil or setData.names == nil then
                    scanSetsNowSilently = true
                    break -- Get out of the lop now
                end
            end
        end
    end
    --Scan the sets now silently?
    if scanSetsNowSilently then
        WL.GetAllSetData(true)
    end
    --Get the characters of the currently logged in account and list all available ones in a list (for the char selection dropdown at the WishList tab e.g.)
    WL.getCharsOfAccount()

    --Get the currently logged in char data
    WL.checkCurrentCharData(true)

    --Build the LAM addon menu
    if not WL.preventerVars.addonMenuBuild then
        WL.buildAddonMenu()
    end

    --EVENTs
    EVENT_MANAGER:RegisterForEvent(addonVars.addonName, EVENT_LOOT_RECEIVED, WL.LootReceived)
    --Register for player inventory slot update
    EVENT_MANAGER:RegisterForEvent(addonVars.addonName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, WL.Inv_Single_Slot_Update)
    --Add a filter to the event to speed up item checks only on default items not a weapon charge etc.
    EVENT_MANAGER:AddFilterForEvent(addonVars.addonName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT, REGISTER_FILTER_IS_NEW_ITEM, true)

    EVENT_MANAGER:RegisterForEvent(addonVars.addonName.. "_PLAYER_ACTIVATED", EVENT_PLAYER_ACTIVATED, function()
        if WL.SVrelated_doReloadUINow == true then
            zo_callLater(function()
                d("[WishList]Reloading the UI due to SavedVariables migration!")
                if WishList_Data["Default"] == nil then
                    WL.accDataServerIndependent.savedVarsWereMigratedFinished = true
                end
                ReloadUI("ingame") end,
            50)
        else
            --Check if WishList SVs were migrated and finished the reloaduis
            if WishList_Data["Default"] == nil and WL.accDataServerIndependent then
                if WL.accDataServerIndependent.savedVarsWereMigratedToServerDependent == true and WL.accDataServerIndependent.savedVarsWereMigratedFinished == true then
                    WL.accDataServerIndependent.savedVarsWereMigratedFinished = nil
                    --Show an onscreen message + chat message
                    d("[WishList]Migration of SavedVariables of account \'" ..tostring(GetDisplayName()) .."\' to server \'" ..tostring(GetWorldName()) .. "\' finished!")
                    --TODO: OnScreen message
                    local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, SOUNDS.CHAMPION_POINTS_COMMITTED)
                    params:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_DISPLAY_ANNOUNCEMENT)
                    params:SetText("[|c00FF00WishList|r]SavedVariables migrated to server!")
                    CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(params)
                end
            end
        end
    end)

    --HANDLERs
    --Link handler (for right clicking an item in chat, etc.)
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, WL.linkContextMenu)

    --Add the main menu button
    WL_addMainMenuButton()

    --Register the slash commands
    WL_RegisterSlashCommands()

    --Hooks
    WL_Hooks()

    WL.firstWishListCall = true
    WL.initDone = true
end

------------------------------------------------
--- Addon Start Event
------------------------------------------------
EVENT_MANAGER:RegisterForEvent(WL.addonVars.addonName, EVENT_ADD_ON_LOADED, WL.init)