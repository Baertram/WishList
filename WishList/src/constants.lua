WishList = WishList or {}
local WL = WishList

------------------------------------------------
--- Addon data
------------------------------------------------
WL.addonVars =  {}
WL.addonVars.addonRealVersion		    = 2.96
WL.addonVars.addonSavedVarsVersion	    = 2.0 --Changing this will reset the SavedVariables!!!
WL.addonVars.addonName				    = "WishList"
WL.addonVars.addonSavedVars			    = "WishList_Data"
WL.addonVars.addonSavedVarsAllServers   = "WishList_Data_All_Servers"
WL.addonVars.addonSavedVarsDefault      = "Default"
WL.addonVars.addonSavedVarsAccountWide  = "$AccountWide"
WL.addonVars.addonSavedVarsAccountWideDataTab = "AccountwideData"
WL.addonVars.addonSavedVarsDataTab      = "Data"
WL.addonVars.addonSavedVarsWishListTab  = "wishList"
WL.addonVars.addonSavedVarsHistoryTab   = "history"
WL.addonVars.addonSavedVarsLastCharacterIdentifier = "$LastCharacterName"
WL.addonVars.addonSavedVarsAccountWideServerIndependent = "AccountwideDataServerIndependent"
WL.addonVars.settingsName   		    = "WishList"
WL.addonVars.settingsDisplayName   	    = WL.addonVars.settingsName
WL.addonVars.addonAuthor			    = "Meai & Baertram"
WL.addonVars.addonWebsite			    = "http://www.esoui.com/downloads/info1641-WishList.html"
WL.addonVars.addonDonation			    = "https://www.esoui.com/portal.php?id=136&a=faq&faqid=131"
WL.addonVars.addonFeedback			    = "https://www.esoui.com/downloads/info1641-WishList.html#comments"

WL.SVrelated_doReloadUINow = false

--Libraries
WL.addonMenu = LibAddonMenu2
WL.LMM2 = LibMainMenu2
WL.LibSets = LibSets

--Constants
WISHLIST_SCENE_NAME = "WishListScene"
--For the ZO_SortList row, the datatpye
WISHLIST_DATA = 1
--The tabs of the scene multitab control
WISHLIST_TAB_SEARCH             = 1
WISHLIST_TAB_WISHLIST           = 2
WISHLIST_TAB_HISTORY            = 3
--The state of the multitab's search tab
WISHLIST_TAB_STATE_NO_SETS      = 1
WISHLIST_TAB_STATE_SETS_LOADING = 2
WISHLIST_TAB_STATE_SETS_LOADED  = 3
--The search types
WISHLIST_SEARCH_TYPE_BY_NAME                = 1
WISHLIST_SEARCH_TYPE_BY_SET_BONUS           = 2
WISHLIST_SEARCH_TYPE_BY_ARMORTYPE           = 3
WISHLIST_SEARCH_TYPE_BY_WEAPONTYPE          = 4
WISHLIST_SEARCH_TYPE_BY_SLOT                = 5
WISHLIST_SEARCH_TYPE_BY_TRAIT               = 6
WISHLIST_SEARCH_TYPE_BY_ITEMID              = 7
WISHLIST_SEARCH_TYPE_BY_DATE                = 8
WISHLIST_SEARCH_TYPE_BY_LOCATION            = 9
WISHLIST_SEARCH_TYPE_BY_USERNAME            = 10
WISHLIST_SEARCH_TYPE_BY_LIBSETSSETTYPE      = 11
WISHLIST_SEARCH_TYPE_BY_LIBSETSDLCID        = 12
WISHLIST_SEARCH_TYPE_BY_LIBSETSTRAITSNEEDED = 13
WISHLIST_SEARCH_TYPE_BY_LIBSETSZONEID       = 14
WISHLIST_SEARCH_TYPE_BY_LIBSETSWAYSHRINENODEINDEX = 15
WISHLIST_SEARCH_TYPE_BY_LIBSETSDROPMECHANIC     = 16
WISHLIST_SEARCH_TYPE_ITERATION_BEGIN = WISHLIST_SEARCH_TYPE_BY_NAME
WISHLIST_SEARCH_TYPE_ITERATION_END = WISHLIST_SEARCH_TYPE_BY_LIBSETSDROPMECHANIC
local searchTypesForCriteria = {
    [WISHLIST_SEARCH_TYPE_BY_NAME]                  = true,
    [WISHLIST_SEARCH_TYPE_BY_SET_BONUS]             = true,
    [WISHLIST_SEARCH_TYPE_BY_ARMORTYPE]             = true,
    [WISHLIST_SEARCH_TYPE_BY_WEAPONTYPE]            = true,
    [WISHLIST_SEARCH_TYPE_BY_SLOT]                  = true,
    [WISHLIST_SEARCH_TYPE_BY_TRAIT]                 = true,
    [WISHLIST_SEARCH_TYPE_BY_LOCATION]              = true,
    [WISHLIST_SEARCH_TYPE_BY_USERNAME]              = true,
    [WISHLIST_SEARCH_TYPE_BY_ITEMID]                = true,
    [WISHLIST_SEARCH_TYPE_BY_DATE]                  = true,
    [WISHLIST_SEARCH_TYPE_BY_LIBSETSSETTYPE]        = true,
    [WISHLIST_SEARCH_TYPE_BY_LIBSETSDLCID]          = true,
    [WISHLIST_SEARCH_TYPE_BY_LIBSETSTRAITSNEEDED]   = true,
    [WISHLIST_SEARCH_TYPE_BY_LIBSETSZONEID]         = true,
    [WISHLIST_SEARCH_TYPE_BY_LIBSETSWAYSHRINENODEINDEX] = true,
    [WISHLIST_SEARCH_TYPE_BY_LIBSETSDROPMECHANIC]       = true,
}
WL.searchTypesForCriteria = searchTypesForCriteria
local searchTypesForContextMenuCriteria = {
    [WISHLIST_SEARCH_TYPE_BY_NAME]                  = false,
    [WISHLIST_SEARCH_TYPE_BY_SET_BONUS]             = false,
    [WISHLIST_SEARCH_TYPE_BY_ARMORTYPE]             = true,
    [WISHLIST_SEARCH_TYPE_BY_WEAPONTYPE]            = true,
    [WISHLIST_SEARCH_TYPE_BY_SLOT]                  = true,
    [WISHLIST_SEARCH_TYPE_BY_TRAIT]                 = true,
    [WISHLIST_SEARCH_TYPE_BY_LOCATION]              = false,
    [WISHLIST_SEARCH_TYPE_BY_USERNAME]              = false,
    [WISHLIST_SEARCH_TYPE_BY_ITEMID]                = false,
    [WISHLIST_SEARCH_TYPE_BY_DATE]                  = false,
    [WISHLIST_SEARCH_TYPE_BY_LIBSETSSETTYPE]        = true,
    [WISHLIST_SEARCH_TYPE_BY_LIBSETSDLCID]          = true,
    [WISHLIST_SEARCH_TYPE_BY_LIBSETSTRAITSNEEDED]   = false,
    [WISHLIST_SEARCH_TYPE_BY_LIBSETSZONEID]         = false,
    [WISHLIST_SEARCH_TYPE_BY_LIBSETSWAYSHRINENODEINDEX] = false,
    [WISHLIST_SEARCH_TYPE_BY_LIBSETSDROPMECHANIC]       = true,
}
WL.searchTypesForContextMenuCriteria = searchTypesForContextMenuCriteria
--Constants for the number of search dropdown entries at each tab:
WISHLIST_TAB_SEARCH_ENTRY_COUNT     = WISHLIST_SEARCH_TYPE_ITERATION_END
WISHLIST_TAB_WHISLIST_ENTRY_COUNT   = WISHLIST_SEARCH_TYPE_ITERATION_END
WISHLIST_TAB_HISTORY_ENTRY_COUNT    = WISHLIST_SEARCH_TYPE_ITERATION_END
--The add dialog set part types
WISHLIST_ADD_TYPE_WHOLE_SET                             = 1
WISHLIST_ADD_TYPE_BY_ITEMTYPE                           = 2
WISHLIST_ADD_TYPE_BY_ITEMTYPE_AND_ARMOR_WEAPON_TYPE     = 3
WISHLIST_ADD_ONE_HANDED_WEAPONS                         = 4
WISHLIST_ADD_TWO_HANDED_WEAPONS                         = 5
WISHLIST_ADD_BODY_PARTS_ARMOR                           = 6
WISHLIST_ADD_MONSTER_SET_PARTS_ARMOR                    = 7
--The different types for the remove item dialog
WISHLIST_REMOVE_ITEM_TYPE_NORMAL                        = 1
WISHLIST_REMOVE_ITEM_TYPE_DATEANDTIME                   = 2
WISHLIST_REMOVE_ITEM_TYPE                               = 3
WISHLIST_REMOVE_ITEM_TYPE_ARMORANDWEAPONTYPE            = 4
WISHLIST_REMOVE_ITEM_TYPE_SLOT                          = 5
WISHLIST_REMOVE_ITEM_TYPE_TRAIT                         = 6
--The prefix for the character dropdown entries
WISHLIST_SEARCHDROP_PREFIX= "WISHLIST_SEARCHDROP"
WISHLIST_CHARSDROP_PREFIX = "WISHLIST_CHARSDROP"
--Qualities
WL.ESOquality2WLqualityAdd = 2 --Add this number to the ESO quality returned by GetItemLinkQuality to get the appropriate WishList quality constant
WISHLIST_QUALITY_ALL = 1
WISHLIST_QUALITY_TRASH = 2
WISHLIST_QUALITY_NORMAL = 3
WISHLIST_QUALITY_MAGIC = 4
WISHLIST_QUALITY_ARCANE = 5
WISHLIST_QUALITY_ARTIFACT = 6
WISHLIST_QUALITY_LEGENDARY = 7
WISHLIST_QUALITY_MAGIC_OR_ARCANE = 8
WISHLIST_QUALITY_ARCANE_OR_ARTIFACT = 9
WISHLIST_QUALITY_ARTIFACT_OR_LEGENDARY = 10
WISHLIST_QUALITY_MAGIC_TO_LEGENDARY = 11
WISHLIST_QUALITY_ARCANE_TO_LEGENDARY = 12
--ZoneIds for LibSets data
WISHLIST_ZONEID_BATTLEGROUNDS = 999999
WISHLIST_ZONEID_SPECIAL       = 999998

--Sort header names
local sortTiebrakerChoicesWithSortHeaderKeys = {
    [-1] = "!None",
    [1] = "name",
    [2] = "armorOrWeaponTypeName",
    [3] = "slotName",
    [4] = "traitName",
    [5] = "quality",
    [6] = "username",
    [7] = "locality",
    [8] = "timestamp",
}
WL.sortTiebrakerChoicesWithSortHeaderKeys = sortTiebrakerChoicesWithSortHeaderKeys

--LAM dropdown box entries for the possible tiebraker choices
local sortTiebrakerChoices = {
    [1] = GetString(WISHLIST_LAM_SORT_USE_TIEBRAKER_NONE),
    [2] = GetString(WISHLIST_HEADER_NAME),
    [3] = GetString(WISHLIST_HEADER_TYPE),
    [4] = GetString(WISHLIST_HEADER_SLOT),
    [5] = GetString(WISHLIST_HEADER_TRAIT),
    [6] = GetString(WISHLIST_HEADER_QUALITY),
    [7] = GetString(WISHLIST_HEADER_USERNAME),
    [8] = GetString(WISHLIST_HEADER_LOCALITY),
    [9] = GetString(WISHLIST_HEADER_DATE),
}
WL.sortTiebrakerChoices = sortTiebrakerChoices

--LAM dropdown box entries for the possible tiebraker choices values
local sortTiebrakerChoicesValues = {}
table.insert(sortTiebrakerChoicesValues, -1)
for value=1, #sortTiebrakerChoices-1 do
    table.insert(sortTiebrakerChoicesValues, value)
end
WL.sortTiebrakerChoicesValues = sortTiebrakerChoicesValues

------------------------------------------------------------------------------------------------------------------------
-- SAVED VARIABLES
------------------------------------------------------------------------------------------------------------------------
--SavedVars accountwide defaults
WL.defaultAccSettings = {
    saveMode = 1,       --1=Each character, 2=Account wide
    sets = {},
    setCount = 0,
    itemCount = 0,
    use24hFormat = false,
    useCustomDateFormat = "",
    setsLastScanned = 0,
    lastAddedViaDialog = {},
}
--SavedVars defaults
WL.defaultSettings = {
    wishList = {},
    history = {},
    sortKey = {
        [WISHLIST_TAB_SEARCH]   = "name",
        [WISHLIST_TAB_WISHLIST] = "name",
    },
    sortOrder = {
        [WISHLIST_TAB_SEARCH]   = ZO_SORT_ORDER_UP,
        [WISHLIST_TAB_WISHLIST] = ZO_SORT_ORDER_UP,
    },
    preSelectLoggedinCharAtItemAddDialog = true,
    scanAllChars                         = false,
    showMainMenuButton                   = false,
    --useSortTiebrakerName                 = true,  --Removed and replaced by WL.defaultSettings.useSortTiebraker
    useSortTiebraker                     = -1,       --No additional group sorting
    fcoisMarkerIconAutoMarkLootedSetPart = false,
    fcoisMarkerIconAutoMarkLootedSetPartPerChar = false,
    fcoisMarkerIconLootedSetPart         = FCOIS_CON_ICON_LOCK or 1, -- Lock icon
    fcoisMarkerIconLootedSetPartPerChar  = {},
    useItemFoundCharacterName            = true,
    useItemFoundCSA                      = true,
    itemFoundText                        = GetString(WISHLIST_LOOT_MSG_STANDARD),
    useLanguageForSetNames               = {
        ["de"] = false,
        ["en"] = true,
        ["fr"] = false,
        ["ru"] = false,
        ["jp"] = false,
    },
    notifyOnFoundItemsOnlyMaxCP = false,
    notifyOnFoundItemsOnlyInDungeons = false,
    dialogAddHistory = {},
}

--For the add item dialog
WL.lastSelectedLastAddedHistoryEntry = nil