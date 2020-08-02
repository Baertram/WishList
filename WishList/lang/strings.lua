--Global language constants with English text
WishList = WishList or {}
local WL = WishList

--English base strings: These need to be seperated from other strings which "use these base strings",
-- so they can be created before the other strings
local stringsBase = {
    WISHLIST_TITLE                      = "WishList",
    WISHLIST_HISTORY_TITLE              = "history",

    WISHLIST_TOOLTIP_COLOR_KEY          = "|cFFA500", --Orange, RGB: 255 165 000
    WISHLIST_TOOLTIP_COLOR_VALUE        = "|cF6F6F6", -- Gray-White, RGB: 246 246 246

    WISHLIST_HEADER_DATE                = "Date",                                   -- Date
    WISHLIST_HEADER_NAME                = GetString(SI_INVENTORY_SORT_TYPE_NAME),   -- Name
    WISHLIST_HEADER_TYPE                = GetString(SI_SMITHING_HEADER_ITEM),       -- Type
    WISHLIST_HEADER_SLOT                = "Slot",
    WISHLIST_HEADER_TRAIT               = GetString(SI_SMITHING_HEADER_TRAIT),      -- Trait
    WISHLIST_HEADER_CHARS               = GetString(SI_BINDING_NAME_TOGGLE_CHARACTER), -- Character / toon
    WISHLIST_HEADER_USERNAME            = "User",
    WISHLIST_HEADER_LOCALITY            = "Locality",
    WISHLIST_HEADER_QUALITY             = GetString(SI_TRADINGHOUSEFEATURECATEGORY5), --Quality
    WISHLIST_HEADER_LAST_ADDED          = "Last added",

    WISHLIST_CONST_ID                   = "id",
    WISHLIST_CONST_SET                  = "set",
    WISHLIST_CONST_BONUS                = "bonuses",
    WISHLIST_CONST_ARMORANDWEAPONTYPE   = "Armor / Weapon type",
    WISHLIST_CONST_ARMORTYPE            = "Armor type",
    WISHLIST_CONST_WEAPONTYPE           = "Weapon type",
    WISHLIST_CONST_ITEMID               = "ItemId",

    WISHLIST_DIALOG_ADD_ITEM            = "Add item",
    WISHLIST_BUTTON_REMOVE_HISTORY_TT   = "Clear history",

    WISHLIST_DLC                        = GetString(SI_MARKET_PRODUCT_TOOLTIP_DLC),
    WISHLIST_ZONE                       = GetString(SI_CHAT_CHANNEL_NAME_ZONE),
    WISHLIST_WAYSHRINES                 = GetString(SI_MAPFILTER8),
    WISHLIST_ARMORTYPE                  = GetString(SI_ITEM_FORMAT_STR_ARMOR) .. " " .. GetString(SI_GUILD_HERALDRY_TYPE_HEADER),
    WISHLIST_DROPLOCATIONS              = "Drop locations",
    WISHLIST_DROPLOCATION_SPECIAL       = "Speziell (e.g. Level Up, Prophet)",
    WISHLIST_DROPLOCATION_BG            = GetString(SI_LEADERBOARDTYPE4), --Battleground

    WISHLIST_LIBSETS                    = "LibSets",

    WISHLIST_ARMOR                      = GetString(SI_ITEMTYPE2),
    WISHLIST_WEAPONS                    = GetString(SI_ITEMFILTERTYPE1),
    WISHLIST_JEWELRY                    = GetString(SI_ITEMFILTERTYPE25),
}
WL.stringsBaseEN = stringsBase
for stringId, stringValue in pairs(stringsBase) do
    ZO_CreateStringId(stringId, stringValue)
    SafeAddVersion(stringId, 1)
end

--English WishList translations (using already created base strings)
local strings = {
    WISHLIST_SEARCHDROP_START        = "Search by ",
    WISHLIST_SEARCHDROP1       = GetString(WISHLIST_HEADER_NAME) .. "/SetId",
    WISHLIST_SEARCHDROP2       = GetString(WISHLIST_CONST_SET) .. " " .. GetString(WISHLIST_CONST_BONUS),
    WISHLIST_SEARCHDROP3       = GetString(WISHLIST_CONST_ARMORTYPE),
    WISHLIST_SEARCHDROP4       = GetString(WISHLIST_CONST_WEAPONTYPE),
    WISHLIST_SEARCHDROP5       = GetString(WISHLIST_HEADER_SLOT),
    WISHLIST_SEARCHDROP6       = GetString(WISHLIST_HEADER_TRAIT),
    WISHLIST_SEARCHDROP7       = GetString(WISHLIST_CONST_ITEMID),
    WISHLIST_SEARCHDROP8       = GetString(WISHLIST_HEADER_DATE),
    WISHLIST_SEARCHDROP9       = GetString(WISHLIST_HEADER_LOCALITY),
    WISHLIST_SEARCHDROP10       = GetString(WISHLIST_HEADER_USERNAME),
    --LibSets searches
    WISHLIST_SEARCHDROP11      = GetString(WISHLIST_LIBSETS) .. ": Set type",
    WISHLIST_SEARCHDROP12      = GetString(WISHLIST_LIBSETS) .. ": " .. GetString(WISHLIST_DLC),
    WISHLIST_SEARCHDROP13      = GetString(WISHLIST_LIBSETS) .. ": Traits needed",
    WISHLIST_SEARCHDROP14      = GetString(WISHLIST_LIBSETS) .. ": " .. GetString(WISHLIST_ZONE),
    WISHLIST_SEARCHDROP15      = GetString(WISHLIST_LIBSETS) .. ": " .. GetString(WISHLIST_WAYSHRINES),
    WISHLIST_SEARCHDROP16      = GetString(WISHLIST_LIBSETS) .. ": " .. GetString(WISHLIST_DROPLOCATIONS),

    WISHLIST_LOOT_MSG_YOU            = "YOU LOOTED ",
    WISHLIST_LOOT_MSG_OTHER          = " LOOTED ",
    WISHLIST_LOOT_MSG_STANDARD       = "[<<2>>] looted \"<<1>>\" with trait <<3>>, quality <<4>>, level <<5>>, set \"<<6>>\"",

    WISHLIST_CONTEXTMENU_ADD         = "Add to " .. GetString(WISHLIST_TITLE),
    WISHLIST_CONTEXTMENU_REMOVE      = "Remove from " .. GetString(WISHLIST_TITLE),
    WISHLIST_CONTEXTMENU_REMOVE_FROM_LAST_ADDED = "Remove from last added",
    WISHLIST_CONTEXTMENU_CLEAR_LAST_ADDED = "Clear last added (will close this dialog!)",
    WISHLIST_CLEAR_LAST_ADDED_TITLE = "Clear last added history?",
    WISHLIST_CLEAR_LAST_ADDED_TEXT = "Do you really want to clear all entries of the last added history?",

    WISHLIST_ADDED                   = " added to " .. GetString(WISHLIST_TITLE),
    WISHLIST_REMOVED                 = " removed from " .. GetString(WISHLIST_TITLE),
    WISHLIST_UPDATED                 = " updated <<1>> in " .. GetString(WISHLIST_TITLE),
    WISHLIST_ITEMS_ADDED             = "<<1[No item/1 item/$d items]>> added to " .. GetString(WISHLIST_TITLE),
    WISHLIST_ITEMS_REMOVED           = "<<1[No item/1 item/$d items]>> removed from " .. GetString(WISHLIST_TITLE),
    WISHLIST_ITEMS_UPDATED           = "<<1[No item/1 item/$d items]>> changed in " .. GetString(WISHLIST_TITLE),

    WISHLIST_HISTORY_ADDED                   = " added to " .. GetString(WISHLIST_HISTORY_TITLE),
    WISHLIST_HISTORY_REMOVED                 = " removed from " .. GetString(WISHLIST_HISTORY_TITLE),
    WISHLIST_HISTORY_ITEMS_ADDED             = "<<1[No entry/1 entry/$d entries]>> added to " .. GetString(WISHLIST_HISTORY_TITLE),
    WISHLIST_HISTORY_ITEMS_REMOVED           = "<<1[No entry/1 entry/$d entries]>> removed from " .. GetString(WISHLIST_HISTORY_TITLE),

    WISHLIST_ITEMTRAITTYPE_SPECIAL  = "Special",

    WISHLIST_DIALOG_ADD_WHOLE_SET_TT         = "Add all items of the current set, with selected traits, to your " .. GetString(WISHLIST_TITLE),
    WISHLIST_DIALOG_ADD_ALL_TYPE_OF_SET_TT   = "Add all items of the current set, with selected item type (<<1>>) and selected trait, to your " .. GetString(WISHLIST_TITLE),
    WISHLIST_DIALOG_ADD_ALL_TYPE_TYPE_OF_SET_TT = "Add all items of the current set, with selected item type (<<1>>), item (<<2>>) and selected trait, to your " .. GetString(WISHLIST_TITLE),
    WISHLIST_DIALOG_ADD_ANY_TRAIT            = "- Any trait of current item -",
    WISHLIST_NO_ITEMS_ADDED_WITH_SELECTED_DATA = "No items found with the selected data -> No items were added to your " .. GetString(WISHLIST_TITLE),
    WISHLIST_DIALOG_ADD_ONE_HANDED_WEAPONS_OF_SET_TT = "Add all one-handed items of the current set, with selected trait, to your " .. GetString(WISHLIST_TITLE),
    WISHLIST_DIALOG_ADD_TWO_HANDED_WEAPONS_OF_SET_TT = "Add all two-handed items of the current set, with selected trait, to your " .. GetString(WISHLIST_TITLE),
    WISHLIST_DIALOG_ADD_BODY_PARTS_ARMOR_OF_SET_TT = "Add all body armor parts of the current set, with selected trait, to your " .. GetString(WISHLIST_TITLE),
    WISHLIST_DIALOG_ADD_MONSTER_SET_PARTS_ARMOR_OF_SET_TT = "Add shoulder and hear armor parts of the current set, with selected trait, to your " .. GetString(WISHLIST_TITLE),

    WISHLIST_DIALOG_REMOVE_ITEM              = "Remove item",
    WISHLIST_DIALOG_REMOVE_ITEM_QUESTION     = "Remove <<1>>?",
    WISHLIST_DIALOG_REMOVE_ITEM_DATETIME            = "Remove items with date & time \"<<1>>\"",
    WISHLIST_DIALOG_REMOVE_ITEM_TYPE                = "Remove items with item type \"<<1>>\"",
    WISHLIST_DIALOG_REMOVE_ITEM_ARMORORWEAPONTYPE   = "Remove items with type \"<<1>>\"",
    WISHLIST_DIALOG_REMOVE_ITEM_SLOT                = "Remove items with slot \"<<1>>\"",
    WISHLIST_DIALOG_REMOVE_ITEM_TRAIT               = "Remove items with trait \"<<1>>\"",

    WISHLIST_DIALOG_REMOVE_WHOLE_SET         = "Remove whole set \"<<1>>\"",
    WISHLIST_DIALOG_REMOVE_WHOLE_SET_QUESTION= "Really remove all items of set \"<<1>>\"?",
    WISHLIST_BUTTON_REMOVE_ALL_TT            = "Remove all items of selected character from " .. GetString(WISHLIST_TITLE),
    WISHLIST_DIALOG_REMOVE_ALL_ITEMS_QUESTION     = "Really remove all items?",
    WISHLIST_BUTTON_CLEAR_HISTORY_TT            = GetString(WISHLIST_BUTTON_REMOVE_HISTOTY_TT) .. "?",
    WISHLIST_DIALOG_CLEAR_HISTORY_QUESTION      = "Really clear " .. GetString(WISHLIST_HISTORY_TITLE) .. " for selected character?",
    WISHLIST_DIALOG_CHANGE_QUALITY              = "Change " .. GetString(SI_TRADINGHOUSEFEATURECATEGORY5),
    WISHLIST_DIALOG_CHANGE_QUALITY_QUESTION     = "Change <<1>>?",
    WISHLIST_DIALOG_CHANGE_QUALITY_WHOLE_SET    = "Change " .. GetString(SI_TRADINGHOUSEFEATURECATEGORY5) .. " of set",
    WISHLIST_DIALOG_CHANGE_QUALITY_WHOLE_SET_QUESTION   = "Really change all items of set \"<<1>>\"?",

    WISHLIST_BUTTON_COPY_WISHLIST_TT            = "Copy " .. GetString(WISHLIST_TITLE),
    WISHLIST_BUTTON_CHOOSE_CHARACTER_TT         = "Choose character",
    WISHLIST_BUTTON_CHOOSE_CHARACTER_QUESTION_ADD_ITEM   = GetString(WISHLIST_DIALOG_ADD_ITEM) .. " <<1>>:",
    WISHLIST_BUTTON_CHOOSE_CHARACTER_QUESTION_COPY_WL  = "Copy " .. GetString(WISHLIST_TITLE) .. " of <<1>> to:",
    WISHLIST_ITEM_COPIED                        = "Copied <<1>> from <<2>> to <<3>>",
    WISHLIST_NO_ITEMS_COPIED                    = "No items copied, maybe all items are already on the target's " .. GetString(WISHLIST_TITLE),

    WISHLIST_DIALOG_RELOAD_ITEMS             = "Reload items",
    WISHLIST_DIALOG_RELOAD_ITEMS_QUESTION    = "THIS WILL RELOAD ALL SET ITEMS using library \'LibSets\'!\nShouldn't take longer than 10 seconds.",
    WISHLIST_LINK_ITEM_TO_CHAT               = GetString(SI_ITEM_ACTION_LINK_TO_CHAT),
    WISHLIST_WHISPER_RECEIVER                = "Whisper \"<<C:1>>\" and ask for <<2>>",
    WISHLIST_WHISPER_RECEIVER_QUESTION       = "Hey <<C:1>>, you have found this item: <<2>>. I'm searching for it and would like to ask if you will trade it to me? Thank you.",

    WISHLIST_SETS_LOADED                     = "<<1[No set/1 set/$d sets]>> loaded",
    WISHLIST_NO_SETS_LOADED                  = "No sets are loaded. Click the button to load all sets.\This can take several minutes to finish and will lag your game client!",
    WISHLIST_LOAD_SETS                       = "Load sets",
    WISHLIST_LOADING_SETS                    = "Loading sets...",
    WISHLIST_TOTAL_SETS                      = "Total sets: ",
    WISHLIST_TOTAL_SETS_ITEMS                = "Total items: ",
    WISHLIST_SETS_FOUND                      = "Sets found: <<1>> with <<2>> total items",

    WISHLIST_ITEM_QUALITY_ALL                       = "- Any " .. GetString(SI_TRADINGHOUSEFEATURECATEGORY5) .. " -",
    WISHLIST_ITEM_QUALITY_MAGIC_OR_ARCANE           = GetString(SI_ITEMQUALITY2) .. ", " .. GetString(SI_ITEMQUALITY3), 		--Magic or arcane
    WISHLIST_ITEM_QUALITY_ARCANE_OR_ARTIFACT        = GetString(SI_ITEMQUALITY3) .. ", " .. GetString(SI_ITEMQUALITY4), 		--Arcane or artifact
    WISHLIST_ITEM_QUALITY_ARTIFACT_OR_LEGENDARY     = GetString(SI_ITEMQUALITY4) .. ", " .. GetString(SI_ITEMQUALITY5), 	    --Artifact or legendary
    WISHLIST_ITEM_QUALITY_MAGIC_TO_LEGENDARY        = GetString(SI_ITEMQUALITY2) .. " -> " .. GetString(SI_ITEMQUALITY5), 		--Magic to legendary
    WISHLIST_ITEM_QUALITY_ARCANE_TO_LEGENDARY       = GetString(SI_ITEMQUALITY3) .. " -> " .. GetString(SI_ITEMQUALITY5), 		--Arcane to legendary

    --Tooltips
    WISHLIST_BUTTON_RELOAD_TT                = "Reload all set data",
    WISHLIST_BUTTON_SEARCH_TT                = "Set & item search",
    WISHLIST_BUTTON_WISHLIST_TT              = "Your " .. GetString(WISHLIST_TITLE),
    WISHLIST_BUTTON_HISTORY_TT               = zo_strformat("<<C:1>>", GetString(WISHLIST_HISTORY_TITLE)),
    WISHLIST_BUTTON_SETTINGS_TT              = GetString(WISHLIST_TITLE) .. " settings",
    WISHLIST_CHARDROPDOWN_ITEMCOUNT_WISHLIST = "[<<C:1>>]\n<<2[No item/1 item/$d items]>> on " .. GetString(WISHLIST_TITLE),
    WISHLIST_CHARDROPDOWN_ITEMCOUNT_HISTORY  = "[<<C:1>>]\n<<2[No entry/1 entry/$d entries]>> in " .. GetString(WISHLIST_HISTORY_TITLE),

    --Keybindings
    SI_BINDING_NAME_WISHLIST_SHOW           = "Show " .. GetString(WISHLIST_TITLE),
    SI_BINDING_NAME_WISHLIST_ADD_OR_REMOVE  = "Add/Remove to/from " .. GetString(WISHLIST_TITLE),

    -- LAM addon settings
    WISHLIST_WARNING_RELOADUI               = "Attention:\nChanging this option will do an automatic reload of the user interface!",
    WISHLIST_LAM_ADDON_DESC                 = GetString(WISHLIST_TITLE) .. " - Your list of wanted set items",
    WISHLIST_LAM_SAVEDVARIABLES             = "Saving the settings",
    WISHLIST_LAM_SV                         = "Save type",
    WISHLIST_LAM_SV_TT                      = "Choose if you want to save your addon data account wide, or different for each of your character.\n\nThis does not apply to the Wish Lists as you can choose which character gets and item added/removed from every character!",
    WISHLIST_LAM_SV_ACCOUNT_WIDE            = "Account wide",
    WISHLIST_LAM_SV_EACH_CHAR               = "Each character",
    WISHLIST_LAM_USE_24h_FORMAT             = "Use 24h time format",
    WISHLIST_LAM_USE_24h_FORMAT_TT          = "Use the 24 hours time format for date & time formats",
    WISHLIST_LAM_USE_CUSTOM_DATETIME_FORMAT     = "Custom date & time format",
    WISHLIST_LAM_USE_CUSTOM_DATETIME_FORMAT_TT  = "Specify your own date & time format.\nLeve the edit field empty to use the standard date & time format.\nThe usable placeholders are pre-defined within the lua language:\n\n%a	abbreviated weekday name (e.g., Wed)\n%A	full weekday name (e.g., Wednesday)\n%b	abbreviated month name (e.g., Sep)\n%B	full month name (e.g., September)\n%c	date and time (e.g., 09/16/98 23:48:10)\n%d	day of the month (16) [01-31]\n%H	hour, using a 24-hour clock (23) [00-23]\n%I	hour, using a 12-hour clock (11) [01-12]\n%M	minute (48) [00-59]\n%m	month (09) [01-12]\n%p	either \"am\" or \"pm\" (pm)\n%S	second (10) [00-61]\n%w	weekday (3) [0-6 = Sunday-Saturday]\n%x	date (e.g., 09/16/98)\n%X	time (e.g., 23:48:10)\n%Y	full year (1998)\n%y	two-digit year (98) [00-99]\n%%	the character `%´",

    WISHLIST_LAM_SCAN                       = "Scans",
    WISHLIST_LAM_SCAN_ALL_CHARS             = "Scan all character WishLists",
    WISHLIST_LAM_SCAN_ALL_CHARS_TT          = "Scan each of your characters WishLists for looted items, and not only the currently logged in character's WishList",

    WISHLIST_LAM_ADD_ITEM                   = "Add items to " .. GetString(WISHLIST_TITLE),
    WISHLIST_LAM_PRESELECT_CHAR_ON_ITEM_ADD = "Preselect logged in character",
    WISHLIST_LAM_PRESELECT_CHAR_ON_ITEM_ADD_TT = "Preselect the currently logged in character at the item add dialog, or use the last chosen character from the list tab?",

    WISHLIST_LAM_ADD_MAIN_MENU_BUTTON       = "Show main menu button",
    WISHLIST_LAM_ADD_MAIN_MENU_BUTTON_TT    = "Show a button in the main menu to show the " .. GetString(WISHLIST_TITLE),

    WISHLIST_LAM_SORT                       = "Sort",
    WISHLIST_LAM_SORT_USE_TIEBRAKER         = "Group sort by this tiebreaker",
    WISHLIST_LAM_SORT_USE_TIEBRAKER_TT      = "Use the selected column as 2nd sort tiebraker. Your selected sort column will then also be grouped by your selected column afterwards.",
    WISHLIST_LAM_SORT_USE_TIEBRAKER_NONE    = "No grouping!",

    WISHLIST_LAM_FCOIS                      = "FCO ItemSaver",
    WISHLIST_LAM_FCOIS_MARK_ITEM_AUTO       = "Mark looted set item",
    WISHLIST_LAM_FCOIS_MARK_ITEM_AUTO_TT    = "Mark a looted set item from your wishlist with this FCO ItemSaver marker icon",
    WISHLIST_LAM_FCOIS_MARKER_ICONS_PER_CHAR         = "FCOItemSaver - Marker icons for each char's WishList",
    WISHLIST_LAM_FCOIS_MARK_ITEM_AUTO_PER_CHAR       = "Mark looted set item indiv. for each char",
    WISHLIST_LAM_FCOIS_MARK_ITEM_AUTO_PER_CHAR_TT    = "Mark a looted set item from a characters wishlist with this FCO ItemSaver marker icon.\nEach character's wishlist can use its own marker icon.",
    WISHLIST_LAM_FCOIS_MARK_ITEM_CHARAKTER_NAME      = "Character name",
    WISHLIST_LAM_FCOIS_MARK_ITEM_ICON                = "Marker icon",

    WISHLIST_LAM_ITEM_FOUND                         = "Found items on " .. GetString(WISHLIST_TITLE),
    WISHLIST_LAM_ITEM_FOUND_USE_CHARACTERNAME       = "Show character or account name",
    WISHLIST_LAM_ITEM_FOUND_USE_CHARACTERNAME_TT    = "Enabled: Show the characater name of the character looting an item on your " .. GetString(WISHLIST_TITLE) .."\nDisabled: Show the account name of the character looting an item on your " .. GetString(WISHLIST_TITLE),
    WISHLIST_LAM_ITEM_FOUND_USE_CSA                 = "Show center screen message too",
    WISHLIST_LAM_ITEM_FOUND_USE_CSA_TT              = "Show a center screen announcement message in addition to the chat message",
    WISHLIST_LAM_ITEM_FOUND_TEXT                    = "Looted item message",
    WISHLIST_LAM_ITEM_FOUND_TEXT_TT                 = "Specify the message text which will appear in the chat and (if enabled) at the center screen announcement, if an item on your " .. GetString(WISHLIST_TITLE) .. " was looted.\nLeve the edit field empty to show a default loot message.\n\nYou can use the following placeholders in your message, which will be replaced with the looted item information:\n<<1>>    Name (link)\n<<2>>  Looted by\n<<3>>   Trait\n<<4>>  Quality\n<<5>>  Level\n<<6>>  Set name",

    WISHLIST_LAM_FORMAT_OPTIONS                     = "Output format",
    WISHLIST_LAM_SETNAME_LANGUAGES                  = "Set name languages",
    WISHLIST_LAM_SETNAME_LANGUAGES_TT               = "Enable the set name languages which should be shown in the " .. GetString(WISHLIST_TITLE) .. " sets list (seperated by a / character). The current client language will be shown first (If supported. Else English is shown first).",

    WISHLIST_LAM_ITEM_FOUND_ONLY_MAX_CP             = "Only item level at CP" ..tostring(GetChampionPointsPlayerProgressionCap()),
    WISHLIST_LAM_ITEM_FOUND_ONLY_MAX_CP_TT          = "Only notify if the found item's level is the currently maximum available ChampionPoints level CP"..tostring(GetChampionPointsPlayerProgressionCap()),
    WISHLIST_LAM_ITEM_FOUND_ONLY_IN_DUNGEONS        = "Only inside dungeons",
    WISHLIST_LAM_ITEM_FOUND_ONLY_IN_DUNGEONS_TT     = "Only notify if you are currently inside a dungeon.",

    WISHLIST_SORTHEADER_GROUP_CHANGED               = "[" .. GetString(WISHLIST_TITLE) .. "]Sort grouping changed to: %s",
}
WL.stringsEN = strings

--Register the language constants so other files can use the function "SafeAddString" too
for stringId, stringValue in pairs(strings) do
    ZO_CreateStringId(stringId, stringValue)
    SafeAddVersion(stringId, 1)
end