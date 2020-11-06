WishList = WishList or {}
local WL = WishList
local libSets = WL.LibSets

local allowedItemTypes = WL.checkItemTypes
--Only body armor parts
local isBodyArmorPart = {
    [EQUIP_TYPE_CHEST]      = true,
    [EQUIP_TYPE_COSTUME]    = false,
    [EQUIP_TYPE_FEET]       = true,
    [EQUIP_TYPE_HAND]       = true,
    [EQUIP_TYPE_HEAD]       = false,
    [EQUIP_TYPE_INVALID]    = false,
    [EQUIP_TYPE_LEGS]       = true,
    [EQUIP_TYPE_MAIN_HAND]  = false,
    [EQUIP_TYPE_NECK]       = false,
    [EQUIP_TYPE_OFF_HAND]   = false,
    [EQUIP_TYPE_ONE_HAND]   = false,
    [EQUIP_TYPE_POISON]     = false,
    [EQUIP_TYPE_RING]       = false,
    [EQUIP_TYPE_SHOULDERS]  = false,
    [EQUIP_TYPE_TWO_HAND]   = false,
    [EQUIP_TYPE_WAIST]      = true,
}
--Only 1hd weapons
local is1hdWeapon = {
    [WEAPONTYPE_AXE]                =      true,
    [WEAPONTYPE_BOW]                =      false,
    [WEAPONTYPE_DAGGER]             =      true,
    [WEAPONTYPE_FIRE_STAFF]         =      false,
    [WEAPONTYPE_FROST_STAFF]        =      false,
    [WEAPONTYPE_HAMMER]             =      true,
    [WEAPONTYPE_HEALING_STAFF]      =      false,
    [WEAPONTYPE_LIGHTNING_STAFF]    =      false,
    [WEAPONTYPE_NONE]               =      false,
    [WEAPONTYPE_RUNE]               =      false,
    [WEAPONTYPE_SHIELD]             =      true,
    [WEAPONTYPE_SWORD]              =      true,
    [WEAPONTYPE_TWO_HANDED_AXE]     =      false,
    [WEAPONTYPE_TWO_HANDED_HAMMER]  =      false,
    [WEAPONTYPE_TWO_HANDED_SWORD]   =      false,
}
--Only 2hd weapons
local is2hdWeapon = {
    [WEAPONTYPE_AXE]                =      false,
    [WEAPONTYPE_BOW]                =      true,
    [WEAPONTYPE_DAGGER]             =      false,
    [WEAPONTYPE_FIRE_STAFF]         =      true,
    [WEAPONTYPE_FROST_STAFF]        =      true,
    [WEAPONTYPE_HAMMER]             =      false,
    [WEAPONTYPE_HEALING_STAFF]      =      true,
    [WEAPONTYPE_LIGHTNING_STAFF]    =      true,
    [WEAPONTYPE_NONE]               =      false,
    [WEAPONTYPE_RUNE]               =      false,
    [WEAPONTYPE_SHIELD]             =      false,
    [WEAPONTYPE_SWORD]              =      false,
    [WEAPONTYPE_TWO_HANDED_AXE]     =      true,
    [WEAPONTYPE_TWO_HANDED_HAMMER]  =      true,
    [WEAPONTYPE_TWO_HANDED_SWORD]   =      true,
}

--Center Screen Announcement
function WL.CSA(text, soundToPlay)
    if not text or text == "" then return end
    local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, soundToPlay or SOUNDS.CHAMPION_POINTS_COMMITTED)
    params:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_DISPLAY_ANNOUNCEMENT)
    params:SetText(text)
    CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(params)
end


------------------------------------------------
--- SavedVariables functions
------------------------------------------------
--As long as SV were not migrated to server dependent ones: Use the "Default" SV profile.
--Else return the profile with the server name
function WL.getSavedVarsServer()
    local accDataServerIndependent = WL.accDataServerIndependent
    if not accDataServerIndependent or
        ( accDataServerIndependent ~= nil and not accDataServerIndependent.savedVarsWereMigratedToServerDependent ) then
        return WL.addonVars.addonSavedVarsDefault --"Default"
    end
    return GetWorldName()
end
local getSavedVarsServer = WL.getSavedVarsServer


local function buildSVLastCharacterNameEntry(charId, accName)
    if charId == nil then return false end
    accName = accName or GetDisplayName()
    local savedVarsServer = getSavedVarsServer()
    local addonVars = WL.addonVars
    if WishList_Data and WishList_Data[savedVarsServer] and WishList_Data[savedVarsServer][accName]
        and WishList_Data[savedVarsServer][accName][charId]
        and WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab]
        and WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab][addonVars.addonSavedVarsLastCharacterIdentifier] == nil then
        local charData = WL.getCharDataById(charId)
        if charData == nil then return false end
        local lastCharacterName = charData.nameClean
        if lastCharacterName ~= nil and lastCharacterName ~= "" then
            WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab][addonVars.addonSavedVarsLastCharacterIdentifier] = lastCharacterName
            return true
        end
    end
    return false
end


function WL.checkIfWLSavedVarsExist(charId)
    if charId == nil then return false end
    local accName = GetDisplayName()
    local savedVarsServer = getSavedVarsServer()
    local addonVars = WL.addonVars
    if    WishList_Data ~= nil and WishList_Data[savedVarsServer] ~= nil and WishList_Data[savedVarsServer][accName] ~= nil
      and WishList_Data[savedVarsServer][accName][charId] ~= nil and WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab] ~= nil
      and WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab][addonVars.addonSavedVarsWishListTab] ~= nil
      and #WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab][addonVars.addonSavedVarsWishListTab] > 0 then
        return true
    else
        --Create the WishList SavedVars entry for the missing charData, but as no entries are given return false in the end!
        if WishList_Data ~= nil then
            WishList_Data[savedVarsServer] = WishList_Data[savedVarsServer] or {}
            WishList_Data[savedVarsServer][accName] = WishList_Data[savedVarsServer][accName] or {}
            WishList_Data[savedVarsServer][accName][charId] = WishList_Data[savedVarsServer][accName][charId] or {}
            WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab] = WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab] or {}
            WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab][addonVars.addonSavedVarsWishListTab] = WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab][addonVars.addonSavedVarsWishListTab] or {}
            --Build the $LastCharacterName entry if missing
            buildSVLastCharacterNameEntry(charId, accName)
        end
    end
    return false
end

function WL.getWishListSaveVars(charData, calledBy, noFallBackToLoggedIn)
    calledBy = calledBy or ""
    noFallBackToLoggedIn = noFallBackToLoggedIn or false
--d("[WL]getWishListSaveVars | Called by: " ..tostring(calledBy))
    local wishListSavedVars = {}
    local accName = GetDisplayName()
    local savedVarsServer = getSavedVarsServer()
    local addonVars = WL.addonVars
    if charData ~= nil and charData.id ~= nil and charData.id ~= WL.LoggedInCharData.id then
        if WL.checkIfWLSavedVarsExist(charData.id) then
--d(">WL data of char exists")
            wishListSavedVars = WishList_Data[savedVarsServer][accName][charData.id][addonVars.addonSavedVarsDataTab][addonVars.addonSavedVarsWishListTab]
        end
    else
        --CharData is not given so use the currently logged in char's WishList!
        -->Do not use WL.data as this is the normal SavedVariables and will only save the Non-WishList/History settings!
        WL.LoggedInCharData = WL.LoggedInCharData or WL.checkCurrentCharData(true)
        if charData == nil or charData.id == nil then
--d(">no chardata given!")
            if noFallBackToLoggedIn then
--d("<<<ABORT!")
                return nil
            end
        --else
--d(">using logged in charData")
        end
        local loggedInCharId = WL.LoggedInCharData.id
        WL.checkIfWLSavedVarsExist(loggedInCharId)
        wishListSavedVars = WishList_Data[savedVarsServer][accName][loggedInCharId][addonVars.addonSavedVarsDataTab][addonVars.addonSavedVarsWishListTab]
    end
    return wishListSavedVars
end

function WL.getWishListItemCount(charData)
    local wlSVs = WL.getWishListSaveVars(charData, "WL.getWishListItemCount", true)
    if wlSVs ~= nil then
        return #wlSVs
    end
    return nil
end

function WL.checkIfHistorySavedVarsExist(charId)
    if charId == nil then return false end
    local accName = GetDisplayName()
    local savedVarsServer = getSavedVarsServer()
    local addonVars = WL.addonVars
    if    WishList_Data ~= nil and WishList_Data[savedVarsServer] ~= nil and WishList_Data[savedVarsServer][accName] ~= nil
            and WishList_Data[savedVarsServer][accName][charId] ~= nil and WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab] ~= nil
            and WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab][addonVars.addonSavedVarsHistoryTab] ~= nil
            and #WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab][addonVars.addonSavedVarsHistoryTab] > 0 then
            return true
    else
        --Create the history SavedVars entry for the missing charData, but as no entries are given return false in the end!
        if WishList_Data ~= nil then
            WishList_Data[savedVarsServer] = WishList_Data[savedVarsServer] or {}
            WishList_Data[savedVarsServer][accName] = WishList_Data[savedVarsServer][accName] or {}
            WishList_Data[savedVarsServer][accName][charId] = WishList_Data[savedVarsServer][accName][charId] or {}
            WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab] = WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab] or {}
            WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab][addonVars.addonSavedVarsHistoryTab] = WishList_Data[savedVarsServer][accName][charId][addonVars.addonSavedVarsDataTab][addonVars.addonSavedVarsHistoryTab] or {}
            --Build the $LastCharacterName entry if missing
            buildSVLastCharacterNameEntry(charId, accName)
        end
    end
    return false
end

function WL.getHistorySaveVars(charData, calledBy, noFallBackToLoggedIn)
    calledBy = calledBy or ""
    noFallBackToLoggedIn = noFallBackToLoggedIn or false
--d("[WL]getHistorySaveVars | Called by: " ..tostring(calledBy))
    local historySavedVars = {}
    local accName = GetDisplayName()
    local savedVarsServer = getSavedVarsServer()
    local addonVars = WL.addonVars
    if charData ~= nil and charData.id ~= nil and charData.id ~= WL.LoggedInCharData.id then
        if WL.checkIfHistorySavedVarsExist(charData.id) then
--d(">History data of char exists")
            historySavedVars = WishList_Data[savedVarsServer][accName][charData.id][addonVars.addonSavedVarsDataTab][addonVars.addonSavedVarsHistoryTab]
        end
    else
        --CharData is not given so use the currently logged in char's history!
        -->Do not use WL.data as this is the normal SavedVariables and will only save the Non-WishList/History settings!
        WL.LoggedInCharData = WL.LoggedInCharData or WL.checkCurrentCharData(true)
        if charData == nil or charData.id == nil then
--d(">no chardata given!")
            if noFallBackToLoggedIn then
--d("<<<ABORT!")
                return nil end
        else
--d(">using logged in charData")
        end
        local loggedInCharId = WL.LoggedInCharData.id
        WL.checkIfHistorySavedVarsExist(loggedInCharId)
        historySavedVars = WishList_Data[savedVarsServer][accName][loggedInCharId][addonVars.addonSavedVarsDataTab][addonVars.addonSavedVarsHistoryTab]
    end
    return historySavedVars
end

function WL.getHistoryItemCount(charData)
    local histSVs = WL.getHistorySaveVars(charData, "WL.getHistoryItemCount", true)
    if histSVs ~= nil then
        return #histSVs
    end
    return nil
end

------------------------------------------------
--- Item icon functions
------------------------------------------------
function WL.buildItemTraitIconText(text, traitId, size)
    if not traitId then return text end
    local itemTraitIconText = text
    size = size or 20
    if traitId ~= ITEM_TRAIT_TYPE_NONE then
        --itemTraitIconText = zo_iconTextFormat(WL.traitTextures[traitId], 20, 20, itemTraitIconText)
        local texturePath = WL.traitTextures[traitId]
        if not texturePath then return "" end
        itemTraitIconText = zo_iconFormat(texturePath, size, size)
        if text then
            itemTraitIconText = text .. " " .. itemTraitIconText
        end
    end
    return itemTraitIconText
end

function WL.buildItemItemTypeIconText(text, itemTypeId, size)
    if not itemTypeId then return text end
    size = size or 20
    local itemTypeIconText = text
    if itemTypeId ~= 0 then
        --itemTraitIconText = zo_iconTextFormat(WL.traitTextures[traitId], 20, 20, itemTraitIconText)
        local texturePath = WL.ItemTypeTextures[itemTypeId]
        if not texturePath then return "" end
        itemTypeIconText = zo_iconFormat(texturePath, size, size)
        if text then
            itemTypeIconText = text .. " " .. itemTypeIconText
        end
    end
    return itemTypeIconText
end

function WL.buildItemWeaponOrArmorTypeIconText(text, weaponOrArmorType, itemType, size)
    if not itemType then return text end
    size = size or 20
    local itemWeaponrOrArmorTypeIconText = text
    local textureTable
    if itemType == ITEMTYPE_WEAPON then
        textureTable = WL.WeaponTypeTextures
    elseif itemType == ITEMTYPE_ARMOR then
        textureTable = WL.ArmorTypeTextures
    end
    if weaponOrArmorType ~= 0 then
        local texturePath = textureTable[weaponOrArmorType]
        if not texturePath then return "" end
        itemWeaponrOrArmorTypeIconText = zo_iconFormat(texturePath, size, size)
        if text then
            itemWeaponrOrArmorTypeIconText = text .. " " .. itemWeaponrOrArmorTypeIconText
        end
    end
    return itemWeaponrOrArmorTypeIconText
end

function WL.buildItemSlotIconText(text, slotType, size)
    if not slotType then return text end
    size = size or 20
    local itemSlotIconText = text
    if slotType ~= 0 then
        local texturePath = WL.SlotTextures[slotType]
        if not texturePath then return "" end
        itemSlotIconText = zo_iconFormat(texturePath, size, size)
        if text then
            itemSlotIconText = text .. " " .. itemSlotIconText
        end
    end
    return itemSlotIconText
end



------------------------------------------------
--- Character/toon functions
------------------------------------------------
function WL.addCharBrackets(charName)
    if charName == nil or charName == "" then return "" end
    return " [" .. charName .. "]"
end

function WL.checkCharsData()
    if WL.charsData == nil or (WL.charsData ~= nil and #WL.charsData == 0) then
        WL.charsData = WL.buildCharsDropEntries()
    end
end

function WL.getCharsOfAccount()
--d("[WL]getCharsOfAccount")
    --Get the char name and unique ID for the savedvars and add a list of name, colorized chat name and ID to the acocunt wide sv data
    if WL.accData then
        WL.accData.chars = {}
        --Get all of the characters/toons
        for i = 1, GetNumCharacters() do
            --Get name and unique id
            -- @return name string,gender [Gender|#Gender],level integer,classId integer,raceId integer,alliance [Alliance|#Alliance],id string,locationId integer
            local charName, _, _, classId, _, _, characterId, _ = GetCharacterInfo(i)
            WL.accData.chars[characterId] = {}
            --Format the name
            charName = zo_strformat(SI_UNIT_NAME, charName)
            --Check if the char was logged in at least once already having the WishList addon active:
            local charData = {}
            charData.id         = characterId
            charData.name       = charName
            charData.nameClean  = charName
            charData.class      = classId
            local charNameChat = WL.buildCharNameChatText(charData, characterId, false, nil)
--d(">id: " .. tostring(characterId) .. ", name: " .. tostring(charName))
            WL.accData.chars[characterId].id        = characterId
            WL.accData.chars[characterId].name      = charNameChat
            WL.accData.chars[characterId].nameClean = charName
            WL.accData.chars[characterId].class     = classId
        end
    end
end

function WL.getCharDataById(charId)
    if WL.accData.chars ~= nil then
        local charsOfAccount = WL.accData.chars
        local charData = charsOfAccount[charId]
        if charData then
            local currentCharData = {}
            currentCharData["id"]           = charId
            currentCharData["name"]         = charData.name
            currentCharData["nameClean"]    = charData.nameClean
            currentCharData["class"]        = charData.class
            return currentCharData
        end
    end
    return nil
end

function WL.getCharDataByName(charName)
--d("[WL.getCharDataByName] charName: " .. tostring(charName))
    --Format the character name euqal to the savedvars data of all chars
    charName = zo_strformat(SI_UNIT_NAME, charName)
    if WL.accData.chars ~= nil then
        local charsOfAccount = WL.accData.chars
        for characterId, charData in pairs(charsOfAccount) do
            if charData.nameClean == charName then
                local currentCharData = {}
                currentCharData["id"]           = characterId
                currentCharData["name"]         = charData.name
                currentCharData["nameClean"]    = charData.nameClean
                currentCharData["class"]        = charData.class
                return currentCharData
            end
        end
    end
    return nil
end

function WL.checkCurrentCharData(loggedIn, fallbackLoggedIn)
    loggedIn = loggedIn or false
    fallbackLoggedIn = fallbackLoggedIn or false
------------------------------------------------------------------------------------------------------------------------
    local function checkLoggedInCharData()
        local charName = GetUnitName("player")
        charName = zo_strformat(SI_UNIT_NAME, charName)
        --Logged in data only needs to be filled once
        if WL.LoggedInCharData == nil or WL.LoggedInCharData.id == nil or WL.LoggedInCharData.name == nil then
--d(">Currently logged in char")
            WL.LoggedInCharData = {}
            --WL.LoggedInCharData = WL.getCharDataByName(charName)
            local loggedInCharId = GetCurrentCharacterId()
            WL.LoggedInCharData = WL.getCharDataById(loggedInCharId)
        end
    end
------------------------------------------------------------------------------------------------------------------------
--d("[WL.checkCurrentCharData] loggedIn: " .. tostring(loggedIn))
    if loggedIn then
        checkLoggedInCharData()
    else
        --Currently selected char data of the chasr dropdown at the WishList tab needs to be determined on demand
        local selectedCharData = WL.window and WL.window.charsDrop:GetSelectedItemData()
        if selectedCharData and selectedCharData.id ~= nil then
            WL.CurrentCharData.id           = selectedCharData.id
            WL.CurrentCharData.name         = selectedCharData.name
            WL.CurrentCharData.nameClean    = selectedCharData.nameClean
            WL.CurrentCharData.class        = selectedCharData.class
        else
            if fallbackLoggedIn == true then
                checkLoggedInCharData()
            end
        end
    end
end

function WL.buildCharNameChatText(charData, charId, noBrackets, entriesOfChar)
    noBrackets = noBrackets or false
    if WL.data.showWishlistEntriesInCharDropdown or WL.data.showWishlistEntriesInCharDropdown then
        entriesOfChar = entriesOfChar or 0
    else
        entriesOfChar = nil
    end
    if charData == nil and charId == nil then return "" end
    if charData == nil and charId ~= nil then
        charData = WL.accData.chars[charId]
    elseif charId ~= nil and charData ~= nil and charData.name == nil or charData.name == "" or charData.class == nil then
        charData = WL.accData.chars[charId]
    end
    --Get the class id of the charname
    local classId = charData.class
    local charNameChat = charData.nameClean
    --Get the class color
    local charColorDef = GetClassColor(classId)
    if nil ~= charColorDef then charNameChat = charColorDef:Colorize(charNameChat) end
    charNameChat = zo_iconTextFormatNoSpace(WL.getClassIcon(classId), 20, 20, charNameChat)
    local isLoggedInChar = false
    --Color the currently logegd in char in other ways
    --if charData.nameClean ~= nil and charData.nameClean ~= "" and WL.LoggedInCharData.nameClean ~= nil and WL.LoggedInCharData.nameClean ~= ""
    --    and charData.nameClean == WL.LoggedInCharData.nameClean then
    if charId ~= nil and WL.LoggedInCharData.id ~= nil and WL.LoggedInCharData.id == charId then
        isLoggedInChar = true
    else
        local loggedInCharId = GetCurrentCharacterId()
        if charData.id ~= nil and charData.id == loggedInCharId then
            isLoggedInChar = true
        end
    end
    if isLoggedInChar then
        charColorDef = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_MARKET_COLORS, MARKET_COLORS_PURCHASED_DIMMED))
        charNameChat = charColorDef:Colorize(charNameChat)
        charNameChat = " - " .. charNameChat .. " - "
    end
    if noBrackets == false then
        charNameChat = " [" .. charNameChat .. "]"
    end
    if entriesOfChar ~= nil then
        charNameChat = "(" .. tostring(entriesOfChar) .. ") " .. charNameChat
    end
    return charNameChat
end

function WL.getClassIcon(classId)
    --* GetClassInfo(*luaindex* _index_)
    -- @return defId integer,lore string,normalIconKeyboard textureName,pressedIconKeyboard textureName,mouseoverIconKeyboard textureName,isSelectable bool,ingameIconKeyboard textureName,ingameIconGamepad textureName,normalIconGamepad textureName,pressedIconGamepad textureName
    --Fix for Warden and Templar here:

    --[[
    local classLuaIndex = classId
    --Warden
    if classId == 4 then
        classLuaIndex = 5
    --Necromancer
    elseif classId == 5 then
        classLuaIndex = 6
    --Templar
    elseif classId == 6 then
        classLuaIndex = 4
    end
    ]]
    local classLuaIndex = GetClassIndexById(classId)
    local _, _, textureName, _, _, _, ingameIconKeyboard, _, _, _= GetClassInfo(classLuaIndex)
    return ingameIconKeyboard or textureName or ""
end

function WL.buildCharsDropEntries()
--d("[WL]buildCharsDropEntries")
    local charsComboBoxEntryBase = {}
    if WL.accData.chars ~= nil then
       local cnt = 0
       local charsOfAccount = WL.accData.chars
        for characterId, charData in pairs(charsOfAccount) do
            cnt = cnt + 1
            local stringId = WISHLIST_CHARSDROP_PREFIX .. tostring(characterId)
            local charName = WL.buildCharNameChatText(charData, charData.id, true, nil)
            ZO_CreateStringId(stringId, charName)
            SafeAddVersion(stringId, 1)
            table.insert(charsComboBoxEntryBase, {
                id                  =   characterId,
                name                =   charName,
                nameClean           =   charData.nameClean,
                class               =   charData.class,
            })
        end
        --Sort the chars table by their name
        if charsComboBoxEntryBase ~= nil and #charsComboBoxEntryBase > 0 then
            table.sort(charsComboBoxEntryBase,
                --Sort function, returns true if item a will be before b
                function(a,b)
                    --Move the current char to the top of the list (current char name starts with " -")
                    --if string.sub(tostring(a.name), 1, 2) == " -" or string.sub(tostring(b.name), 1, 2) == " -" then
                    --    return true
                    --else
                        return a.nameClean < b.nameClean
                    --end
                end
            )
        end
    else
        return nil
    end
    return charsComboBoxEntryBase
end


------------------------------------------------
--- ChampionRank functions
------------------------------------------------
function WL.getCPLevelNeeded(itemLink, reqLevel)
    if reqLevel == nil or reqLevel < GetMaxLevel() or itemLink == nil then return nil end
--d("[WL]getCPLevelNeeded: " .. itemLink .. ", level: " .. tostring(reqLevel))
    --Champion ranks
    local maxCPLevel = GetChampionPointsPlayerProgressionCap() -- The current maxmium of Champion ranks
    local CPlevels = {}
    local level = 0
    local cpIcon = zo_iconFormat("/esoui/art/menubar/gamepad/gp_playermenu_icon_champion.dds", 32, 32)
    for cpRank = 10, maxCPLevel, 10 do
        CPlevels[cpRank] = cpIcon .. cpRank
    end
    local cpReq = GetItemLinkRequiredChampionPoints(itemLink)
    if cpReq > 0 then
        level = level + cpReq
    end
    if level ~= 0 and CPlevels[level] ~= nil then return CPlevels[level] end
    return nil
end
------------------------------------------------
--- Itemlink functions
------------------------------------------------
function WL.buildItemLink(itemId, qualityIdWishList)
    if itemId == nil then return nil end
    qualityIdWishList = qualityIdWishList or WISHLIST_QUALITY_LEGENDARY -- Legendary
    --Using WishList's own itemlink function
    --The qualityId is the chosen quality from the "Add set item dialog". See file WishListDataTypes.lua, table WL.quality. So it can be 1 to 12
    --and must be mapped to the real qualityIds for the itemlink.
    local qualityIdItemLink = WL.mapWLQualityToItemLinkQuality(qualityIdWishList)
    --Using LibSets to get the itemLink
    return libSets.buildItemLink(itemId, qualityIdItemLink)
    --return string.format("|H1:item:%d:%d:50:0:0:0:0:0:0:0:0:0:0:0:0:%d:%d:0:0:%d:0|h|h", itemId, qualityIdItemLink, ITEMSTYLE_NONE, 0, 10000)
end

--Map the WishList internal quality (See file WishListDataTypes.lua, table WL.quality) to the itemLink qualities:
--357:  Trash
--366:  Normal
--367:  Magic
--368:  Arcane
--369:  Artifact
--370:  Legendary
function WL.mapWLQualityToItemLinkQuality(qualityIdWishList)
    local qualityIdItemLink = 370 -- preset with Legendary quality
    --Map the quality from WishList#s add item dialog to the itemLink quality now
    local mapQualities = {
        [WISHLIST_QUALITY_ALL]		= 357,      --Any quality
        [WISHLIST_QUALITY_TRASH] 	= 357, 		--Trash
        [WISHLIST_QUALITY_NORMAL] 	= 366, 		--Normal (white)
        [WISHLIST_QUALITY_MAGIC] 	= 367, 		--Magic (green)
        [WISHLIST_QUALITY_ARCANE] 	= 368, 		--Arcane (blue)
        [WISHLIST_QUALITY_ARTIFACT] 	= 369, 		--Artifact (purple)
        [WISHLIST_QUALITY_LEGENDARY]		= 370, 		--Legendary (golden)
        [WISHLIST_QUALITY_MAGIC_OR_ARCANE] 	= 367, 		--Magic or arcane
        [WISHLIST_QUALITY_ARCANE_OR_ARTIFACT]		= 368, 		--Arcane or artifact
        [WISHLIST_QUALITY_ARTIFACT_OR_LEGENDARY]	= 369, 	    --Artifact or legendary
        [WISHLIST_QUALITY_MAGIC_TO_LEGENDARY]	= 367, 		--Magic to legendary
        [WISHLIST_QUALITY_ARCANE_TO_LEGENDARY]	= 368, 		--Arcane to legendary
    }
    if mapQualities[qualityIdWishList] ~= nil then
        qualityIdItemLink =  mapQualities[qualityIdWishList]
    end
    return qualityIdItemLink
end

--Map the WishList qualityId to a a table of itemQuality types
function WL.mapWLQualityToItemQualityTypes(qualityIdWishList)
--d("[WishList]mapWLQualityToItemQualityTypes-qualityIdWishList: " ..tostring(qualityIdWishList))
    local mapQualities = {
        [WISHLIST_QUALITY_ALL]		= {         --Any quality
            [ITEM_QUALITY_TRASH]    = true,
            [ITEM_QUALITY_NORMAL]   = true,
            [ITEM_QUALITY_MAGIC]    = true,
            [ITEM_QUALITY_ARCANE]   = true,
            [ITEM_QUALITY_ARTIFACT] = true,
            [ITEM_QUALITY_LEGENDARY]= true,
        },
        [WISHLIST_QUALITY_TRASH] 	= {         --Trash
            [ITEM_QUALITY_TRASH]    = true,
        },
        [WISHLIST_QUALITY_NORMAL] 	= {         --Normal (white)
            [ITEM_QUALITY_NORMAL]   = true,

        },
        [WISHLIST_QUALITY_MAGIC] 	= {         --Magic (green)
            [ITEM_QUALITY_MAGIC]    = true,

        },
        [WISHLIST_QUALITY_ARCANE] 	= {         --Arcane (blue)
            [ITEM_QUALITY_ARCANE]   = true,

        },
        [WISHLIST_QUALITY_ARTIFACT] 	= {      --Artifact (purple)
            [ITEM_QUALITY_ARTIFACT] = true,

        },
        [WISHLIST_QUALITY_LEGENDARY]		= {   --Legendary (golden)
            [ITEM_QUALITY_LEGENDARY]= true,

        },
        [WISHLIST_QUALITY_MAGIC_OR_ARCANE] 	= {         --Magic or arcane
            [ITEM_QUALITY_MAGIC]    = true,
            [ITEM_QUALITY_ARCANE]   = true,

        },
        [WISHLIST_QUALITY_ARCANE_OR_ARTIFACT]		= { --Arcane or artifact
            [ITEM_QUALITY_ARCANE]   = true,
            [ITEM_QUALITY_ARTIFACT] = true,

        },
        [WISHLIST_QUALITY_ARTIFACT_OR_LEGENDARY]	= { --Artifact or legendary
            [ITEM_QUALITY_ARTIFACT] = true,
            [ITEM_QUALITY_LEGENDARY]= true,

        },
        [WISHLIST_QUALITY_MAGIC_TO_LEGENDARY]	= {    --Magic to legendary
            [ITEM_QUALITY_MAGIC]    = true,
            [ITEM_QUALITY_ARCANE]   = true,
            [ITEM_QUALITY_ARTIFACT] = true,
            [ITEM_QUALITY_LEGENDARY]= true,

        },
        [WISHLIST_QUALITY_ARCANE_TO_LEGENDARY]	= {    --Arcane to legendary
            [ITEM_QUALITY_ARCANE]   = true,
            [ITEM_QUALITY_ARTIFACT] = true,
            [ITEM_QUALITY_LEGENDARY]= true,
        },
    }
    if mapQualities[qualityIdWishList] then
        return mapQualities[qualityIdWishList]
    end
    return mapQualities[WISHLIST_QUALITY_ALL] --If not found: Return any quality
end

--[[
function WL.ilTest()
    d("[WishList]Quality test:")
    for qualityId=350, 370, 1 do
        d(">quality " ..tostring(qualityId) .. ": "  .. WL.buildItemLink(109568, qualityId))
    end
end
]]

function WL.parseLink(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	local i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

function WL.GetItemIDFromLink(itemLink)
    return GetItemLinkItemId(itemLink)
    --return tonumber(string.match(itemLink,"|H%d:item:(%d+)"))
end


------------------------------------------------
--- Wishlist marker function
------------------------------------------------
function WL.MarkWithMarkerIcon(itemId, itemLink, charData, debug)
    if debug then d("[WL.MarkWithMarkerIcon] " .. itemLink) end
    if itemId == nil or itemLink == nil or charData == nil then return nil end
    local settings = WL.data
    local bagId = BAG_BACKPACK

    --ZOs standard locked icons
    -->Not supported

    --ItemSaver marker icon
    -->Not supported

    --FCOItemSaver marker icon
    if FCOIS ~= nil and FCOIS.MarkItem ~= nil then
        local markAllCharsTheSame = false
        local markAllCharsDifferently = false
        --Mark all characters with the same icon?
        if settings.fcoisMarkerIconAutoMarkLootedSetPart and settings.fcoisMarkerIconLootedSetPart ~= nil then
            markAllCharsTheSame = true
        --Mark each characters with it's own icon?
        elseif settings.fcoisMarkerIconAutoMarkLootedSetPartPerChar and settings.fcoisMarkerIconLootedSetPartPerChar ~= nil
                and settings.fcoisMarkerIconLootedSetPartPerChar[charData.id] ~= nil then
            markAllCharsDifferently = true
        end
        if debug then
            if markAllCharsTheSame then
                d(">Mark all chars the same with icon: " ..tostring(settings.fcoisMarkerIconLootedSetPart))
            elseif markAllCharsDifferently then
                d(">Mark all chars differently. Char '" .. charData.name .. "': " ..tostring(settings.fcoisMarkerIconLootedSetPartPerChar[charData.id]))
            end
        end
        --Nothing to mark? Abort here now
        if not markAllCharsTheSame and not markAllCharsDifferently then return end
        --Check the inventorySingleSlotUpdate parameters collected before as the item got looted
        if WL.invSingleSlotUpdateData ~= nil and WL.invSingleSlotUpdateData[itemLink] ~= nil then
            --Was the slotIndex saved as the item got looted (EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
            local slotIndex = WL.invSingleSlotUpdateData[itemLink]
            if slotIndex ~= nil then
                --Only update the inventory if it is currently shown. It will be updated automatically if you show it else.
                local updatePlayerInv = not ZO_PlayerInventoryList:IsHidden() or false
                --Preset the marker icon with the one for "All the same"
                local wishlistMarkerIconOfChar = settings.fcoisMarkerIconLootedSetPart
                --Should the marker icon be the one of another char's WishList instead?
                if markAllCharsDifferently then
                    wishlistMarkerIconOfChar = settings.fcoisMarkerIconLootedSetPartPerChar[charData.id]
                end
                if debug then
                    local itemLinkAtBag = GetItemLink(bagId, slotIndex)
                    d(">" .. itemLinkAtBag .. " - slotIndex: " .. tostring(slotIndex) .. ", updateInv: " .. tostring(updatePlayerInv))
                end
                --FCOIS.MarkItem(bag, slot, iconId, showIcon, updateInventories)
                FCOIS.MarkItem(bagId, slotIndex, wishlistMarkerIconOfChar, true, updatePlayerInv)
                --Reset the temporary looted item table for this itemLink (WL.invSingleSlotUpdateData[itemLink] = nil) won't be done here now
                --as other characts might have the same itemLink on their Wishlist and the marker icons should be applied to them all!
                --The reset will be done in file WishList.lua, function "lootReceivedWishListCheck" after all character's wishlist got scanned properly.
            end
        end
    end
end


------------------------------------------------
--- Wishlist history functions
------------------------------------------------
function WL.AddLootToHistory(item, itemId, itemLink, setName, isLootedByPlayer, receivedBy, charData, whereWasItLootedData)
--d("[WL]AddLootToHistory " .. itemLink)
    if item == nil or itemId == nil or itemLink == nil or setName == nil or charData == nil then return end
    --Check where it was looted
    --isInPVP, isInDelve, isInPublicDungeon, isInGroupDungeon, isInRaid, isInGroup, groupSize, zoneId, subZoneId
    local localityStr = ""
    if whereWasItLootedData ~= nil then
        local zoneName, subZoneName
        --Zone
        if whereWasItLootedData[8] ~= nil and whereWasItLootedData[8] ~= 0 then
            zoneName = zo_strformat("<<C:1>>", GetZoneNameById(whereWasItLootedData[8]))
        end
        --SubZone
        if whereWasItLootedData[9] ~= nil and whereWasItLootedData[9] ~= 0 then
            subZoneName = zo_strformat("<<C:1>>", GetZoneNameById(whereWasItLootedData[9]))
        end
        if zoneName ~= nil and zoneName ~= "" then
            localityStr = zoneName
        end
        if subZoneName ~= nil and subZoneName ~= "" and subZoneName ~= zoneName then
            if localityStr ~= "" then
                localityStr = localityStr .. " (" .. subZoneName .. ")"
            else
                localityStr = subZoneName
            end
        end
    end
    --The table of items to add later to the history
    local items = {}
    --Check set parameters
    local setId = item.setId
    if setId == nil or setName == nil then
        local _, setLocName, _, _, _, setLocId = GetItemLinkSetInfo(itemLink, false)
        --Remove the gender stuff from the setname
        setName = zo_strformat("<<C:1>>", setLocName)
        setId = setLocId
    end
    --The entry for the history SavedVars
    local data = {}
    data.setId                  = setId
    data.setName                = setName
    data.id                     = itemId
    data.itemType               = item.itemType
    data.armorOrWeaponType      = item.armorOrWeaponType
    data.slot                   = item.slot
    data.trait                  = item.trait
    data.quality                = item.quality
    data.timestamp              = item.timestamp
    data.username               = receivedBy.charName
    data.displayName            = receivedBy.accountName
    data.locality               = localityStr
    --data.itemLink               = itemLink
    table.insert(items, data)
    --Item was added to internal list?
    if items ~= nil and #items > 0 then
        --Add this entry to the SavedVariables now and update the history ZO_ScrollFilterList now
        WL:AddHistoryItem(items, charData)
    end
end

------------------------------------------------
--- Wishlist content functions
------------------------------------------------
function WL.IsEmpty(charData)
	local wishList = WL.getWishListSaveVars(charData, "WL.IsEmpty")
    if wishList == nil then return true end
	local cnt = #wishList
	if cnt > 0 then
		return false, cnt
	end
	return true, 0
end

function WL.IsHistoryEmpty(charData)
    local history = WL.getHistorySaveVars(charData, "WL.IsHistoryEmpty")
    if history == nil then return true end
    local cnt = #history
    if cnt > 0 then
        return false, cnt
    end
    return true, 0
end

--Checksi fi the item is already on trhe WishList and returns isAlreadyOnWishList boolean, itemId of the item, item data
function WL.isItemAlreadyOnWishlist(itemLink, itemId, charData, scanByDetails, setId, itemType, armorOrWeaponType, slotType, traitType, itemQuality)
    scanByDetails = scanByDetails or false
--d("[WL.isItemAlreayOnWishlist] " .. itemLink)
    if scanByDetails and (setId == nil or itemType == nil or armorOrWeaponType == nil or slotType == nil or traitType == nil or itemQuality == nil) then return false, nil, nil end
    if charData == nil then return false, nil, nil end
    local wishList = WL.getWishListSaveVars(charData, "WL.isItemAlreadyOnWishlist")
    if wishList == nil then return false, nil, nil end
    local isAlreadyOnWishList = false
    if itemLink == nil and itemId == nil then return false, nil, nil end
    if itemLink == nil then
        itemLink = WL.buildItemLink(itemId, nil)
    end
    if itemId == nil then
        itemId = WL.GetItemIDFromLink(itemLink)
    end
    local item = {}
--d(">WL.isItemAlreayOnWishlist " .. itemLink .. ", itemId: " .. itemId .. ", char name: " .. tostring(charData.name) .. ", scanByDetails: " ..tostring(scanByDetails) .. ", setId: " .. tostring(setId) ..", itemType: " ..tostring(itemType) .. ", armorOrWeaponType: " .. tostring(armorOrWeaponType) .. ", slotType: " ..tostring(slotType) .. ", traitType: " .. tostring(traitType) .. ", quality: " ..tostring(itemQuality))
    if itemId ~= nil then
        for i = 1, #wishList do
            item = wishList[i]
            if scanByDetails then
                if item.setId == setId then
                    if item.itemType == itemType then
                        if item.armorOrWeaponType == armorOrWeaponType then
                            if item.slot == slotType then
                                if item.trait == traitType then
                                    --Quality checks
                                    --Get the itemQuality
                                    itemQuality = itemQuality or GetItemLinkDisplayQuality(itemLink)
                                    if itemQuality ~= nil and item.quality ~= nil then
                                        --Get the qualities to check
                                        local qualitiesToCheck = WL.mapWLQualityToItemQualityTypes(item.quality)
                                        if qualitiesToCheck ~= nil then
                                            local isQualityToCheckOnItem = qualitiesToCheck[itemQuality] or false
                                            return isQualityToCheckOnItem, itemId, item
                                        else
                                            isAlreadyOnWishList = false
                                        end
                                    else
                                        isAlreadyOnWishList = true
                                    end
                                    return isAlreadyOnWishList, itemId, item
                                end
                            end
                        end
                    end
                end
            else
                if item.id == itemId then
                    isAlreadyOnWishList = true
                    return isAlreadyOnWishList, itemId, item
                end
            end
        end
    end
    return isAlreadyOnWishList, itemId, item
end

--After an item is found on your WishList, during loot: Show a chat/onscreen message and add it to the history tab
function WL.IfItemIsOnWishlist(item, itemId, itemLink, setName, isLootedByPlayer, receivedBy, charData, whereWasItLootedData, debug)
    --WL._item = item
    --Item is on a wishlist, so output the info and center screen announcement
    --local charName = WL.buildCharNameChatText(charData, nil)
    local settings = WL.data
    local text = ""
    --Character or account name in output?
    local charName = receivedBy.charName
    local accountName = receivedBy.accountName
    if debug then
        d("[WL.IfItemIsOnWishlist] " .. itemLink .. ", accountName: " ..tostring(accountName) .. ", charName: " ..tostring(charName))
    end
    local charOrAccountName = ""
    if isLootedByPlayer then
        charName    = WL.LoggedInCharData.nameClean
        accountName = ZO_CachedStrFormat(SI_UNIT_NAME, GetDisplayName())
    else
        charName    = ZO_CachedStrFormat(SI_UNIT_NAME, charName)
        accountName = ZO_CachedStrFormat(SI_UNIT_NAME, accountName)
    end
    receivedBy.charName     = charName
    receivedBy.accountName  = accountName
    if settings.useItemFoundCharacterName then
        charOrAccountName = charName
    else
        charOrAccountName = accountName
    end
    if settings.itemFoundText ~= nil and settings.itemFoundText ~= "" then
        --Loot message text build-up
        --Loot message placeholders:
        --<<1>>  Name (link)
        --<<2>>  Looted by
        --<<3>>  Trait
        --<<4>>  Quality
        --<<5>>  Level
        --<<6>>  Set name
        --Get trait info
        local traitInfo = WL.buildItemTraitIconText(WL.TraitTypes[item.trait], item.trait)
        --Get item quality
        local quality = GetItemLinkQuality(itemLink)
        --Get item level
        local reqLevel = GetItemLinkRequiredLevel(itemLink)
        --is the item level 50? Check if CP rank is needed and update the level str
        local cpLevelNeeded = WL.getCPLevelNeeded(itemLink, reqLevel)
        local levelStr = reqLevel
        if cpLevelNeeded ~= nil then
            levelStr = cpLevelNeeded
        end
        local weaponOrArmorType = ""
        --Old with version 2.2
        --text = zo_strformat(settings.itemFoundText, itemLink, charOrAccountName, traitInfo, quality, levelStr, item.setName)
        --Changed with version 2.3 on advice of user zelenin -> See comments on esoui:  https://www.esoui.com/downloads/addcomment.php?action=addcomment&fileid=1641&quote=105877
        text = zo_strformat(settings.itemFoundText, itemLink, string.format("|H0:character:%s|h%s|h", charOrAccountName, charOrAccountName), traitInfo, quality, levelStr, item.setName)

        --[[
        if string.find(text, "<<1>>") then
            text = zo_strformat(settings.itemFoundText, itemLin)
        end
        if string.find(text, "<<2>>") then
            text = zo_strformat(text, "<<1>>", charOrAccountName)
        end
        if string.find(text, "<<3>>") then
            text = zo_strformat(text, "<<1>>", "<<2>>", WL.TraitTypes[item.trait])
        end
        if string.find(text, "<<4>>") then
            text = zo_strformat(text, "<<1>>", "<<2>>", "<<3>>", quality)
        end
        if string.find(text, "<<5>>") then
            --Get item level
            local reqLevel = GetItemLinkRequiredLevel(itemLink)
            text = zo_strformat(text, "<<1>>", "<<2>>", "<<3>>", "<<4>>" , reqLevel)
        end
        if string.find(text, "<<6>>") then
            text = zo_strformat(text, "<<1>>", "<<2>>", "<<3>>", "<<4>>", "<<5>>", item.setName)
        end
        if string.find(text, "<<7>>") then
            --Weapon
            if item.itemType == ITEMTYPE_WEAPON then
                text = zo_strformat(text, "<<1>>", "<<2>>", "<<3>>", "<<4>>", "<<5>>", "<<6>>", WL.WeaponTypes[item.armorOrWeaponType])
                --Armor
            elseif item.itemType == ITEMTYPE_ARMOR then
                text = zo_strformat(text, "<<1>>", "<<2>>", "<<3>>", "<<4>>", "<<5>>", "<<6>>", WL.ArmorTypes[item.armorOrWeaponType])
            end
        end
        if string.find(text, "<<8>>") then
            text = zo_strformat(text, "<<1>>", "<<2>>", "<<3>>", "<<4>>", "<<5>>", "<<6>>", "<<7>>", WL.SlotTypes[item.slot])
        end
        ]]
    else
        text = itemLink .. " (" .. setName .. ")"
        --Weapon
        if item.itemType == ITEMTYPE_WEAPON then
            text = text.." ["..WL.WeaponTypes[item.armorOrWeaponType].."] ["..WL.TraitTypes[item.trait].."]"
            --Armor
        elseif item.itemType == ITEMTYPE_ARMOR then
            text = text.." ["..WL.ArmorTypes[item.armorOrWeaponType].."] ["..WL.SlotTypes[item.slot].."] ["..WL.TraitTypes[item.trait].."]"
        end
        if isLootedByPlayer then
            text = GetString(WISHLIST_LOOT_MSG_YOU).." " .. text .. " " .. charOrAccountName
        else
            text = zo_strformat("\"<<1>>\"", receivedBy)..GetString(WISHLIST_LOOT_MSG_OTHER).. " " .. text .. charOrAccountName
        end
    end
    --Did your current char loot the item, or someone else?
    if isLootedByPlayer then
        --Mark the item with any marker icon now to protect it?
        WL.MarkWithMarkerIcon(itemId, itemLink, charData, debug)
    end
    --Add the looted item to the history
    WL.AddLootToHistory(item, itemId, itemLink, setName, isLootedByPlayer, receivedBy, charData, whereWasItLootedData)
    --Output the message text to chat
    if text and text ~= "" then
        --Output the message text to chat
        d(text)
        --Output the message text to center screen announcement
        if settings.useItemFoundCSA == true then
            WL.CSA(text)
        end
    end
end

--Select the set's items from the internal set data tables and build a return table with all items matching the criteria
function WL.getSetItemsByCriteria(setId, itemTypeId, armorOrWeaponTypeId, traitId, slotId, qualityId)
    local setsData = WL.accData.sets[setId]
    local allTraitsTraitId = #WL.TraitTypes
    local items = {}
    for setItemId, _ in pairs(setsData) do
        if type(setItemId) == "number" then
            local itemLink = WL.buildItemLink(setItemId, WISHLIST_QUALITY_LEGENDARY) --Always use legendary quality for the setData
            local itemType = GetItemLinkItemType(itemLink)
            local armorOrWeaponType
            if itemType == ITEMTYPE_ARMOR then
                armorOrWeaponType = GetItemLinkArmorType(itemLink)
            elseif itemType == ITEMTYPE_WEAPON then
                armorOrWeaponType = GetItemLinkWeaponType(itemLink)
            end
            local equipType = GetItemLinkEquipType(itemLink)
            local traitType = GetItemLinkTraitInfo(itemLink)

            --Are itemType, armorOrWeaponType, slot and trait (if not all traits choosen) etc. equal to the chosen entries at the add dialog?
            if      itemType == itemTypeId
                    and armorOrWeaponType == armorOrWeaponTypeId
                    and equipType == slotId
                    and (allTraitsTraitId == traitId or traitType == traitId) then
                local clientLang = WL.clientLang or WL.fallbackSetLang
--d(">[WL.getSetItemsByCriteria]" .. itemLink .. " (" .. itemType .. ", ".. armorOrWeaponType .. ", ".. equipType .. ", ".. traitType .. ")")
                local data = {}
                data.setId                  = setId
                data.setName                = setsData.names[clientLang]
                data.id                     = setItemId
                data.itemType               = itemType
                data.armorOrWeaponType      = armorOrWeaponType
                data.slot                   = equipType
                data.trait                  = traitType
                --Add the quality so we can check this data later on as an item was looted
                data.quality                = qualityId
                table.insert(items, data)
            end
        end
    end
    return items
end

--Get set items by the help of the dropdown boxes  of the add item dialog + clicked button addType on the add item dialog (to e.g. add a whole set, only monster helmet and shoulders, ...)
function WL.getSetItemsByData(setId, selectedItemTypeData, selectedItemArmorOrWeaponTypeData, selectedSlotData, selectedItemTraitData, selectedItemQualityData, addType)
    --addType:
    --1=whole set items with selected traits
    --2=only chosen set item type (weapon or armor) with selected traits
    --3=only chosen set item type (weapon or armor) and weapon/armor type (1hd, 2hd, neck, chest, ...) with selected traits
    --4=only 1hd weapons of the set with selected trait
    --5=only 2hd weapons of the set with selected trait
    --6=only body armor parts (no shoulder or head -> used with monster set) of the set with selected trait
    --7=only monster set parts (shoulder and head) of the set with selected trait
    local items = {}
    --The set data (all items of currently selected set)
    if setId == nil or WL.accData == nil or WL.accData.sets == nil or WL.accData.sets[setId] == nil then return items end
    if WL.TraitTypes == nil then return items end
    local setsData = WL.accData.sets[setId]
    local allTraitsTraitId = #WL.TraitTypes
    local addTypeIsAll = (addType == WISHLIST_ADD_TYPE_WHOLE_SET) or false
    local addTypeIsOnlyWeapons = (addType == WISHLIST_ADD_ONE_HANDED_WEAPONS or addType == WISHLIST_ADD_TWO_HANDED_WEAPONS) or false
    local addTypeIsOnlyArmor = (addType == WISHLIST_ADD_BODY_PARTS_ARMOR or addType == WISHLIST_ADD_MONSTER_SET_PARTS_ARMOR) or false
    --Check each set item of the set if the selected ids form the "add set part dialog" are the same, or if the special buttons pressed apply
    for setItemId, _ in pairs(setsData) do
        local skipItem = false
        if type(setItemId) == "number" then
            --Build the itemlink
            local itemLink = WL.buildItemLink(setItemId, WISHLIST_QUALITY_LEGENDARY) -- Always use the legendary item for the searches
            --d(">"..itemLink)
            --Get the itemtype of the item
            local itemType = GetItemLinkItemType(itemLink)
--d(">itemtype check: " .. tostring(selectedItemTypeData.id) .. "/" .. tostring(itemType).. ", skipItem: " ..tostring(skipItem))
            if not skipItem and ((addTypeIsAll or addTypeIsOnlyWeapons or addTypeIsOnlyArmor) or selectedItemTypeData.id == itemType) then
                --Get the armor or weapon type of the item
                local armorOrWeaponType
                if itemType == ITEMTYPE_ARMOR then
                    --Only add weapons but armor item found? Skip it
                    if addTypeIsOnlyWeapons then
                        skipItem = true
                    end
                    armorOrWeaponType = GetItemLinkArmorType(itemLink)
                elseif itemType == ITEMTYPE_WEAPON then
                    --Only add armor but weapon item found? Skip it
                    if addTypeIsOnlyArmor then
                        skipItem = true
                    end
                    armorOrWeaponType = GetItemLinkWeaponType(itemLink)
                    if not skipItem then
                        --Check the weapon type now (1hd, 2hd)
                        --One handed only
                        if addType == WISHLIST_ADD_ONE_HANDED_WEAPONS then
                            skipItem = not is1hdWeapon[armorOrWeaponType]
                            --Two handed only
                        elseif addType == WISHLIST_ADD_TWO_HANDED_WEAPONS then
                            skipItem = not is2hdWeapon[armorOrWeaponType]
                        end
                    end
                else
                    if not skipItem then
                        if addTypeIsOnlyWeapons or addTypeIsOnlyArmor then skipItem = true end
                    end
                end
--d(">armorAndWeaponType check: " .. tostring(selectedItemArmorOrWeaponTypeData.id) .. "/" .. tostring(armorOrWeaponType) .. ", skipItem: " ..tostring(skipItem))
                if not skipItem and ((addTypeIsAll or addTypeIsOnlyWeapons or addTypeIsOnlyArmor or addType == WISHLIST_ADD_TYPE_BY_ITEMTYPE)
                    or selectedItemArmorOrWeaponTypeData.id == armorOrWeaponType) then
                    --Get the slot
                    local equipType = GetItemLinkEquipType(itemLink)
                    --Only add armor parts?
                    if addTypeIsOnlyArmor then
                        --Only add body armor parts?
                        if addType == WISHLIST_ADD_BODY_PARTS_ARMOR then
                            skipItem = not isBodyArmorPart[equipType]
                        --Only add shoulder & chest armor parts?
                        elseif addType == WISHLIST_ADD_MONSTER_SET_PARTS_ARMOR then
                            skipItem = (equipType ~= EQUIP_TYPE_HEAD and equipType ~= EQUIP_TYPE_SHOULDERS) or false
                        end
                    end
--d(">slot check: " .. tostring(selectedSlotData.id) .. "/" .. tostring(equipType).. ", skipItem: " ..tostring(skipItem))
                    if not skipItem and ((addTypeIsAll or addTypeIsOnlyWeapons or addTypeIsOnlyArmor or addType == WISHLIST_ADD_TYPE_BY_ITEMTYPE or addType == WISHLIST_ADD_TYPE_BY_ITEMTYPE_AND_ARMOR_WEAPON_TYPE)
                        or selectedSlotData.id == equipType) then
                        --Get the trait
                        local traitType = GetItemLinkTraitInfo(itemLink)
--d(">trait check: " .. tostring(selectedItemTraitData.id) .. "/" .. tostring(traitType).. ", skipItem: " ..tostring(skipItem))
                        if not skipItem and (selectedItemTraitData.id == allTraitsTraitId or selectedItemTraitData.id == traitType) then
                            --Get the names of the types (for search and order functions)
                            --local itemTypeName, itemArmorOrWeaponTypeName, itemSlotName, itemTraitName = WL.getItemTypeNamesForSortListEntry(selectedItemTypeData.id, selectedItemArmorOrWeaponTypeData.id, selectedSlotData.id, traitType)
                            --Build the data entry for the ZO_SortScrollList row (for searching and sorting with the names AND the ids!)
                            local data = {}
                            data.setId                  = setId
                            data.setName                = setsData.names[WL.clientLang]
                            data.id                     = setItemId
                            data.itemType               = itemType
                            --data.itemTypeName           = itemTypeName
                            data.armorOrWeaponType      = armorOrWeaponType
                            --data.armorOrWeaponTypeName  = itemArmorOrWeaponTypeName
                            data.slot                   = equipType
                            --data.slotName               = itemSlotName
                            data.trait                  = traitType
                            --data.traitName              = itemTraitName
                            data.quality                = selectedItemQualityData.id
                            table.insert(items, data)
                        end
                    end
                end
            end
        end
    end
    return items
end

--Copy a whole wishlist to another character
function WL.copyWishList(fromCharData, toCharId)
--d("[WL.copyWishList] ")
    if fromCharData == nil or fromCharData.id == nil or toCharId == nil then return nil end
--d(">[from]id: " .. tostring(fromCharData.id) .. ", name: " .. tostring(fromCharData.name) .. " -> [to]id: " .. tostring(toCharId))
    --Gte the wishlist of the from char
    local wishList = WL.getWishListSaveVars(fromCharData, "WL.copyWishList FROM")
    if wishList == nil then return false end
    --Get the wishlist of the to char
    local toCharData = WL.getCharDataById(toCharId)
    if toCharData == nil or toCharData.name == nil then return false end
    local wishListTo = WL.getWishListSaveVars(toCharData, "WL.copyWishList TO")
    if wishListTo == nil then return false end
    --local charNameFromChat = WL.buildCharNameChatText(fromCharData, nil)
    --local charNameToChat = WL.buildCharNameChatText(toCharData, nil)
    local charNameFromChat = fromCharData.name
    local charNameToChat = toCharData.name
    local items = {}
    local cnt = 0
    for i = 1, #wishList do
        local itm = wishList[i]
        local itemLink = WL.buildItemLink(itm.id, itm.quality)
        local traitId = itm.trait
        local itemTraitText = WL.TraitTypes[traitId]
        itemTraitText = WL.buildItemTraitIconText(itemTraitText, traitId)
        --Is the item already on the to char's wishlist?
        local alreadyOnWishList = WL.isItemAlreadyOnWishlist(itemLink, itm.id, toCharData) or false
        if not alreadyOnWishList then
            --Copy the item to the to character's wishlist now
            table.insert(items, itm)
            cnt = cnt + 1
            d(tostring(cnt) .. ") " .. zo_strformat(GetString(WISHLIST_ITEM_COPIED), itemLink .. " " .. itemTraitText, charNameFromChat, charNameToChat))
        end
    end
    if #items > 0 then
        WishList:AddItem(items, toCharData, true, true)
    else
        d(GetString(WISHLIST_NO_ITEMS_COPIED))
    end
end


------------------------------------------------------------------------------------------------------------------------
--- Set Item Collections book
------------------------------------------------------------------------------------------------------------------------
local function isKnownInSetItemCollectionBook(itemLink)
    if not itemLink then return end
    return IsItemLinkSetCollectionPiece(itemLink) and IsItemSetCollectionPieceUnlocked(GetItemLinkItemId(itemLink))
end

function WL.IsItemLinkKnownInSetItemCollectionBook(itemLink)
    return isKnownInSetItemCollectionBook(itemLink)
end

function WL.IsItemKnownInSetItemCollectionBook(item)
    if not item then return end
    local itemLink = item.itemLink or WL.buildItemLink(item.id, item.quality)
    if itemLink and itemLink ~= "" then
        return IsItemLinkSetCollectionPiece(itemLink) and IsItemSetCollectionPieceUnlocked(GetItemLinkItemId(itemLink))
    end
    return false
end

--Scan the WishList of a chosen char for items which are alreardy known in the Set item colelciton book, and mark their
--data with the "setItemCollectionBookKnown = true" entry
function WL.scanWishListForAlreadyKnownSetItemCollectionEntries(charData, noReload, wishList)
    charData = charData or WL.LoggedInCharData
    wishList = wishList or WL.getWishListSaveVars(charData, "WL.scanWishListForAlreadyKnownSetItemCollectionEntries")
    if wishList == nil then return false end
    local displayName = GetDisplayName()
    local savedVarsServer = getSavedVarsServer()
    local addonVars = WL.addonVars
	local countChanged = 0
    for i = 1, #wishList do
		local itm = wishList[i]
        if not itm.knownInSetItemCollectionBook then
            if itm.id then
                local itemLink = WL.buildItemLink(itm.id, itm.quality)
                if itemLink and itemLink ~= "" then
                    local isKnown = WL.IsItemKnownInSetItemCollectionBook(itm)
                    if isKnown == true then
                        WishList_Data[savedVarsServer][displayName][charData.id][addonVars.addonSavedVarsDataTab][addonVars.addonSavedVarsWishListTab][i].knownInSetItemCollectionBook = true
                        countChanged = countChanged + 1
                    end
                end
            end
        else
            countChanged = countChanged + 1
        end
	end
    if countChanged > 0 and not noReload then
        if WL.window ~= nil and not WL.window.control:IsHidden() then
            WishList:ReloadItems()
        end
    end
end


------------------------------------------------
--- Tooltip functions
------------------------------------------------
function WL.showItemLinkTooltip(control, parent, anchor1, offsetX, offsetY, anchor2)
    if control == nil or control.data == nil or control.data.itemLink == nil then ClearTooltip(WishListTooltip) return nil end
    anchor1 = anchor1 or TOPRIGHT
    anchor2 = anchor2 or TOPLEFT
    offsetX = offsetX or -100
    offsetY = offsetY or 0
    InitializeTooltip(WishListTooltip, parent, anchor1, offsetX, offsetY, anchor2)
    WishListTooltip:SetLink(control.data.itemLink)
    if (control.data.style) then
        WishListTooltip:AddLine(LocalizeString("\n|c<<1>><<Z:2>>|r", ZO_NORMAL_TEXT:ToHex(), control.data.style), "ZoFontGameSmall")
    end
end

function WL.hideItemLinkTooltip()
    ClearTooltip(WishListTooltip)
end

function WL.showTextTooltip(control, anchor1, identifierStr)
--d("[WL]showTextTooltip, identifierStr: " .. tostring(identifierStr))
    if control == nil or control.data == nil or identifierStr == nil or identifierStr == "" then return nil end
    anchor1 = anchor1 or LEFT
    local ttText = ""
    local data = control.data
    if identifierStr == "DateTime" then
        --Build the date & time from the data of the control
        local timeStamp = data.timestamp
        ttText = WL.getDateTimeFormatted(timeStamp)
    end
    if ttText ~= "" then
        ZO_Tooltips_ShowTextTooltip(control, anchor1, ttText)
    end
end

--Build the neded data for an item (itemlink) tooltip we can show anywhere
function WL.buildItemlinkTooltipData(control)
    --Get the add item dialog control + the trait combobox
    --local control = WishListAddItemDialog
    if control == nil or control.IsHidden == nil or control:IsHidden() then WL.hideItemLinkTooltip() return nil end
    local content   = GetControl(control, "Content")
    local comboTrait = ZO_ComboBox_ObjectFromContainer(content:GetNamedChild("TraitCombo")) --GetControl(content, "TraitCombo")
    --Check if the all traits is selected
    local allTraitsTraitId = #WL.TraitTypes
    local traitId = comboTrait:GetSelectedItemData().id
    --No tooltip if trait is not specified!
    if traitId == allTraitsTraitId then WL.hideItemLinkTooltip() return nil end

    --Get the other combo boxes
    local comboItemType = ZO_ComboBox_ObjectFromContainer(content:GetNamedChild("ItemTypeCombo")) --GetControl(content, "ItemTypeCombo")
    local comboArmorOrWeaponType = ZO_ComboBox_ObjectFromContainer(content:GetNamedChild("ArmorOrWeaponTypeCombo")) --GetControl(content, "ArmorOrWeaponTypeCombo")
    local comboSlot = ZO_ComboBox_ObjectFromContainer(content:GetNamedChild("SlotCombo")) --GetControl(content, "SlotCombo")
    local comboQuality = ZO_ComboBox_ObjectFromContainer(content:GetNamedChild("QualityCombo")) --GetControl(content, "QualityCombo")
    local comboChars = ZO_ComboBox_ObjectFromContainer(content:GetNamedChild("CharsCombo")) --GetControl(content, "CharsCombo")

    --Get the data from the add dialog dropdowns and build an item and chardata from it
    local items = {}
    local selectedCharData = {}
    --Get items which would be added to teh WishList
    items, selectedCharData = WL.buildSetItemDataFromAddItemDialog(comboItemType, comboArmorOrWeaponType, comboTrait, comboSlot, comboChars, comboQuality)
    --Get the itemLink of the created item
    if items == nil and #items > 1 then WL.hideItemLinkTooltip() return nil end
    local item = items[1]
    local itemId = item["id"]
    if itemId == nil then WL.hideItemLinkTooltip() return nil end

    --Build the itemlink from that data to create a tooltip
    local wlQualityForTooltip = comboQuality:GetSelectedItemData().id
    local itemLink = WL.buildItemLink(itemId, wlQualityForTooltip)
    if itemLink == nil or itemLink == "" then WL.hideItemLinkTooltip() return nil end

    local style = ""

    --Will be used within function WL.showItemLinkTooltip(control) as "control"
    local virtualListRowControl = {}
    virtualListRowControl.data      = {}
    virtualListRowControl.data.itemLink   = itemLink
    virtualListRowControl.data.style      = style
    return virtualListRowControl
end

function WL.buildTooltip(tooltipText, zoStrFormatReplaceText1, zoStrFormatReplaceText2, zoStrFormatReplaceText3)
    local ttText = ""
    if zoStrFormatReplaceText1 ~= nil then
        if zoStrFormatReplaceText3 ~= nil then
            ttText = zo_strformat(tooltipText, zoStrFormatReplaceText1, zoStrFormatReplaceText2, zoStrFormatReplaceText3)
        elseif zoStrFormatReplaceText2 ~= nil then
            ttText = zo_strformat(tooltipText, zoStrFormatReplaceText1, zoStrFormatReplaceText2)
        else
            ttText = zo_strformat(tooltipText, zoStrFormatReplaceText1)
        end
    else
        ttText = tooltipText
    end
    return ttText
end

function WL.ShowTooltip(ctrl, tooltipPosition, tooltipText, zoStrFormatReplaceText1, zoStrFormatReplaceTex2, zoStrFormatReplaceText3)
--d("[WL]ShowTooltip - ctrl: " ..tostring(ctrl:GetName()) .. ", text: " .. tostring(tooltipText))
    if ctrl == nil or tooltipText == nil or tooltipText == "" then return false end
	local tooltipPositions = {
        [TOP]       = true,
        [RIGHT]     = true,
        [BOTTOM]    = true,
        [LEFT]      = true,
    }
    if not tooltipPositions[tooltipPosition] then
        tooltipPosition = LEFT
	end
	local ttText = WL.buildTooltip(tooltipText, zoStrFormatReplaceText1, zoStrFormatReplaceTex2, zoStrFormatReplaceText3)
    ZO_Tooltips_ShowTextTooltip(ctrl, tooltipPosition, ttText)
end

function WL.HideTooltip()
    ZO_Tooltips_HideTextTooltip()
end


------------------------------------------------
--- Set functions
------------------------------------------------
function WL.GetSetBonuses( itemLink, numBonuses )
    local bonuses

    if (numBonuses > 0) then
        bonuses = { }
        for i = 1, numBonuses do
            local _, description = GetItemLinkSetBonusInfo(itemLink, false, i)
            table.insert(bonuses, description)
        end
    else
        -- Arena weapons are not sets use the enchantment description instead
        local _, _, description = GetItemLinkEnchantInfo(itemLink)
        bonuses = { description }
    end

    return(bonuses)
end

--Returns the first found itemId from a setId
function WL.GetFirstSetItem(setId)
    if setId == nil then return nil end
    local setData = WL.accData.sets[setId]
    for itemId, value in pairs(setData) do
        if value == true and type(itemId) == "number" then
            return itemId
        end
    end
end

-----------------------------------------------------------
--- Context menus (WishList, Sets, Inventory, LinkHandler
-----------------------------------------------------------
function WL.addItemFromLinkHandlerToWishList(itemLink, itemId, itemType, isSet, setNameStr, numBonuses, setId, charData, qualityWL)
    if charData == nil or charData.id == nil then return false end
    if itemLink == nil then return false end
    local items = {}
    local traitType = GetItemLinkTraitInfo(itemLink)
    local equipType = GetItemLinkEquipType(itemLink)
    local armorOrWeaponType = 0
    if itemId == nil then
        itemId = WL.GetItemIDFromLink(itemLink)
    end
    if itemType == ITEMTYPE_ARMOR then
        armorOrWeaponType = GetItemLinkArmorType(itemLink)
    elseif itemType == ITEMTYPE_WEAPON then
        armorOrWeaponType = GetItemLinkWeaponType(itemLink)
    end
    --Strip gender stuff from the set name
    setNameStr = zo_strformat("<<C:1>>", setNameStr)
    --Item data format: {id=number, itemType=ITEM_TYPE, trait=ITEM_TRAIT_TYPE, type=ARMOR_TYPE/WEAPON_TYPE, slot=EQUIP_TYPE}
    table.insert(items, {setName=setNameStr, id=itemId, itemType=itemType, trait=traitType, armorOrWeaponType=armorOrWeaponType, slot=equipType, bonuses=numBonuses, setId=setId, quality=qualityWL})
    if #items > 0 then
        --Add to the selected char's savedvars data
        local alreadyOnWishListCheckDone = false
        if charData.id == WL.LoggedInCharData.id then
            alreadyOnWishListCheckDone = true
        end
        WishList:AddItem(items, charData, alreadyOnWishListCheckDone)
    end
end

--LINK_HANDLER right clickt context menu
function WL.linkContextMenu(link, button, _, _, linkType, ...)
    if button == MOUSE_BUTTON_INDEX_RIGHT and linkType == ITEM_LINK_TYPE and not IsItemLinkCrafted(link) then
        local isShiftKeyPressed = IsShiftKeyDown()
        zo_callLater(
            function ()
                local itemType = GetItemLinkItemType(link)
                if allowedItemTypes[itemType] then
                    local isSet, setNameStr, numBonuses, _, _, setId = GetItemLinkSetInfo(link, false)
                    if not isSet then return false end
                    local customMenuEntryAddOrRemoveWishList = ""
                    --WL.isItemAlreadyOnWishlist(itemLink, itemId, charData, scanByDetails, setId, itemType, armorOrWeaponType, slotType, traitType)
                    local isItemAlreadyOnWishList, itemId, _ = WL.isItemAlreadyOnWishlist(link, nil, WL.LoggedInCharData) or false, nil, nil
                    if(isShiftKeyPressed or not isItemAlreadyOnWishList) then
                        customMenuEntryAddOrRemoveWishList = GetString(WISHLIST_CONTEXTMENU_ADD)
                    elseif isItemAlreadyOnWishList then
                        customMenuEntryAddOrRemoveWishList = GetString(WISHLIST_CONTEXTMENU_REMOVE)
                    end
                    local qualityWL = GetItemLinkQuality(link) + WL.ESOquality2WLqualityAdd
                    AddCustomMenuItem(customMenuEntryAddOrRemoveWishList, function()
                        --Show the dialog to choose the character where the item should be added now
                        --WL.addItemFromLinkHandlerToWishList(link, itemId, itemType, isSet, setNameStr, numBonuses, setId, charData)
                        local data = {}
                        data.id         = itemId
                        data.itemLink   = link
                        data.itemType   = itemType
                        data.isSet      = isSet
                        data.setName    = setNameStr
                        data.numBonuses = numBonuses
                        data.setId      = setId
                        data.quality    = qualityWL
                        if isShiftKeyPressed or not isItemAlreadyOnWishList then
                            --WL.ShowChooseChar(doAWishListCopy, addItemForCharData, comingFromWishListWindow)
                            WL.ShowChooseChar(false, data, false)
                        else
                            WL.showRemoveItem(data, false, false)
                        end
                    end)
                    ShowMenu()
                end
            end
            , 1)
    end
end

--Show the map of a zoneId
function WL.openMapOfZoneId(zoneId)
    if libSets.openMapOfZoneId then
        libSets.openMapOfZoneId(zoneId)
    end
end

--Show the wayshrine on a map
function WL.showWayshrineNodeIdOnMap(wayshrineNodeId)
    if libSets.showWayshrineNodeIdOnMap then
        libSets.showWayshrineNodeIdOnMap(wayshrineNodeId)
    end
end

local function buildSetDropLocationContextMenuEntries(data)
    --Got drop zones of the item?
    local alreadyAddedZoneIds = {}
    if data.zoneIds then
        local zoneIdContextMenuEntries = {}
        for _, zoneId in ipairs(data.zoneIds) do
            if zoneId ~= -1 and not alreadyAddedZoneIds[zoneId] then
                local zoneName = libSets.GetZoneName(zoneId, WL.clientLang)
                if zoneName == nil then
                    if data.setType == LIBSETS_SETTYPE_BATTLEGROUND then
                        zoneName = GetString(WISHLIST_DROPLOCATION_BG)
                    end
                end
                local subMenuEntry = {
                    label 		    = zoneName,
                    callback 	    = function() WL.openMapOfZoneId(zoneId) end
                }
                table.insert(zoneIdContextMenuEntries, subMenuEntry)
                alreadyAddedZoneIds[zoneId] = true
            end
        end
        --Add submenu in contextmenus howing the different zoneId names as each new row
        if zoneIdContextMenuEntries and #zoneIdContextMenuEntries > 0 then
            AddCustomSubMenuItem(GetString(WISHLIST_DROPLOCATIONS), zoneIdContextMenuEntries)
        end
    end
end

local function buildSetWayshrinesContextMenuEntries(data)
    local alreadyAddedWayshrines = {}
    if data.wayshrines then
        local wayshrinesContextMenuEntries = {}
        for _, wayshrineNodeIndex in ipairs(data.wayshrines) do
            if wayshrineNodeIndex > 0 and not alreadyAddedWayshrines[wayshrineNodeIndex] then
                --GetFastTravelNodeInfo(*luaindex* _nodeIndex_)
                --** _Returns:_ *bool* _known_, *string* _name_, *number* _normalizedX_, *number* _normalizedY_, *textureName* _icon_, *textureName:nilable* _glowIcon_, *[PointOfInterestType|#PointOfInterestType]* _poiType_, *bool* _isShownInCurrentMap_, *bool* _linkedCollectibleIsLocked_
                local wsKnown, wsName = GetFastTravelNodeInfo(wayshrineNodeIndex)
                local wayshrineName = ZO_CachedStrFormat("<<C:1>>", wsName)
                local subMenuEntry = {
                    label 		    = wayshrineName,
                    callback 	    = function() WL.showWayshrineNodeIdOnMap(wayshrineNodeIndex) end --libSets.JumpToSetId(data.setId, factionIndex) end,
                }
                table.insert(wayshrinesContextMenuEntries, subMenuEntry)
                alreadyAddedWayshrines[wayshrineNodeIndex] = true
            end
        end
        --Add submenu in contextmenus howing the different zoneId names as each new row
        if wayshrinesContextMenuEntries and #wayshrinesContextMenuEntries > 0 then
            AddCustomSubMenuItem(GetString(WISHLIST_WAYSHRINES), wayshrinesContextMenuEntries)
        end
    end
end

--Set list/wishList row right click context menu
function WL.showContextMenu(control, button, upInside)
    --AddCustomMenuItem(mytext, myfunction, itemType, myFont, normalColor, highlightColor, itemYPad, horizontalAlignment)
    --AddCustomSubMenuItem(mytext, entries, myfont, normalColor, highlightColor, itemYPad)
    local setName = ""
    local data
    local itemLink
    if WL.CurrentTab == WISHLIST_TAB_SEARCH then
        if upInside then
            if button == MOUSE_BUTTON_INDEX_LEFT then
                WL.showAddItem(control.data, true)

            elseif button == MOUSE_BUTTON_INDEX_RIGHT then
                if control and control.data then
                    data = control.data
                    ClearMenu()
                    AddCustomMenuItem(GetString(WISHLIST_LINK_ITEM_TO_CHAT), function() StartChatInput(CHAT_SYSTEM.textEntry:GetText()..data.itemLink) end) -- Link to chat
                    AddCustomMenuItem(GetString(WISHLIST_DIALOG_ADD_ITEM), function() WL.showAddItem(data, true) end) -- Add item
                    --LibSets data
                    --Got drop zones of the item?
                    buildSetDropLocationContextMenuEntries(data)
                    --Got wayshrines of the item?
                    buildSetWayshrinesContextMenuEntries(data)
                    ShowMenu()
                end
            end
        end
    elseif WL.CurrentTab == WISHLIST_TAB_WISHLIST then
        if upInside then
            if button == MOUSE_BUTTON_INDEX_LEFT then
                StartChatInput(CHAT_SYSTEM.textEntry:GetText()..control.data.itemLink)
            elseif button == MOUSE_BUTTON_INDEX_RIGHT then
                if control and control.data then
                    ClearMenu()
                    data = control.data
                    setName = data.name
                    itemLink = data.itemLink
                    local dateAndTime = WL.getDateTimeFormatted(data.timestamp)
                    local armorOrWeaponType = ""
                    if data.itemType == ITEMTYPE_WEAPON then
                        --Weapon
                        armorOrWeaponType = WL.WeaponTypes[data.armorOrWeaponType]
                    elseif data.itemType == ITEMTYPE_ARMOR then
                        --Armor
                        armorOrWeaponType = WL.ArmorTypes[data.armorOrWeaponType]
                    end
                    local slot = WL.SlotTypes[data.slot]
                    local traitText = WL.TraitTypes[data.trait]
                    local trait = WL.buildItemTraitIconText(traitText, data.trait)
                    AddCustomMenuItem(GetString(WISHLIST_LINK_ITEM_TO_CHAT),
                        function() if itemLink ~= nil and itemLink ~= "" then StartChatInput(CHAT_SYSTEM.textEntry:GetText()..itemLink) end
                    end) -- Link item to chat
                    AddCustomMenuItem(GetString(WISHLIST_DIALOG_REMOVE_ITEM),
                        function() WL.showRemoveItem(data, false, true, false, WISHLIST_REMOVE_ITEM_TYPE_NORMAL)
                    end)  -- Remove item
                    AddCustomMenuItem(zo_strformat(GetString(WISHLIST_DIALOG_REMOVE_ITEM_KNOWN_SETITEMCOLLECTION_OF_SET), setName),
                        function() WL.showRemoveItem(data, false, true, false, WISHLIST_REMOVE_ITEM_TYPE_KNOWN_SETITEMCOLLECTION_OF_SET)
                    end)  -- Remove all sets items of the setId already known in Set Item Collection book
                    AddCustomMenuItem(zo_strformat(GetString(WISHLIST_DIALOG_REMOVE_ITEM_DATETIME), dateAndTime),
                        function() WL.showRemoveItem(data, false, true, false, WISHLIST_REMOVE_ITEM_TYPE_DATEANDTIME)
                    end)  -- Remove item by date & time
                    AddCustomMenuItem(ZO_CachedStrFormat(GetString(WISHLIST_DIALOG_REMOVE_ITEM_ARMORORWEAPONTYPE), armorOrWeaponType),
                        function() WL.showRemoveItem(data, false, true, false, WISHLIST_REMOVE_ITEM_TYPE_ARMORANDWEAPONTYPE)
                    end)  -- Remove item by armor or weapon type
                    AddCustomMenuItem(ZO_CachedStrFormat(GetString(WISHLIST_DIALOG_REMOVE_ITEM_SLOT), slot),
                        function() WL.showRemoveItem(data, false, true, false, WISHLIST_REMOVE_ITEM_TYPE_SLOT)
                    end)  -- Remove item by slot
                    AddCustomMenuItem(ZO_CachedStrFormat(GetString(WISHLIST_DIALOG_REMOVE_ITEM_TRAIT), trait),
                        function() WL.showRemoveItem(data, false, true, false, WISHLIST_REMOVE_ITEM_TYPE_TRAIT)
                    end)  -- Remove item by trait
                    AddCustomMenuItem(GetString(WISHLIST_DIALOG_REMOVE_ITEM_KNOWN_SETITEMCOLLECTION),
                        function() WL.showRemoveItem(data, false, true, false, WISHLIST_REMOVE_ITEM_TYPE_KNOWN_SETITEMCOLLECTION)
                    end)  -- Remove all sets items already known in Set Item Collection book
                    AddCustomMenuItem(zo_strformat(GetString(WISHLIST_DIALOG_REMOVE_WHOLE_SET), setName),
                        function() WL.showRemoveItem(data, true, true, false, WISHLIST_REMOVE_ITEM_TYPE_NORMAL)
                    end)  -- Remove whole set
                    AddCustomMenuItem(GetString(WISHLIST_DIALOG_CHANGE_QUALITY),
                        function() WL.showChangeQuality(data, false, true)
                    end)  -- Change quality
                    AddCustomMenuItem(GetString(WISHLIST_DIALOG_CHANGE_QUALITY_WHOLE_SET),
                        function() WL.showChangeQuality(data, true, true)
                    end)  -- Change quality of whole set
                    --LibSets data
                    --Got drop zones of the item?
                    buildSetDropLocationContextMenuEntries(data)
                    --Got wayshrines of the item?
                    buildSetWayshrinesContextMenuEntries(data)
                end
                ShowMenu()
            end
        end
    elseif WL.CurrentTab == WISHLIST_TAB_HISTORY then
        if upInside then
            local username
            if control and control.data then
                username = control.data.displayName
                if username == nil or username == "" then
                    username = control.data.username
                end
            end
            data = control.data
            itemLink = data.itemLink
            if button == MOUSE_BUTTON_INDEX_LEFT then
                if username ~= nil and username ~= "" and userName ~= "???" and username ~= GetDisplayName() and username ~= zo_strformat("<<C:1>>", GetUnitName("player")) then
                    StartChatInput("/w " .. tostring(username) .. " " .. zo_strformat(GetString(WISHLIST_WHISPER_RECEIVER_QUESTION), username, itemLink))
                end
            elseif button == MOUSE_BUTTON_INDEX_RIGHT then
                if control and control.data then
                    ClearMenu()
                    setName = data.name
                    local dateAndTime = WL.getDateTimeFormatted(data.timestamp)
                    local armorOrWeaponType = ""
                    if data.itemType == ITEMTYPE_WEAPON then
                        --Weapon
                        armorOrWeaponType = WL.WeaponTypes[data.armorOrWeaponType]
                    elseif data.itemType == ITEMTYPE_ARMOR then
                        --Armor
                        armorOrWeaponType = WL.ArmorTypes[data.armorOrWeaponType]
                    end
                    local slot = WL.SlotTypes[data.slot]
                    local traitText = WL.TraitTypes[data.trait]
                    local trait = WL.buildItemTraitIconText(traitText, data.trait)
                    if username ~= nil and username ~= "" and username ~= GetDisplayName() and username ~= zo_strformat("<<C:1>>", GetUnitName("player")) then
                        AddCustomMenuItem(zo_strformat(GetString(WISHLIST_WHISPER_RECEIVER), username, itemLink), function() StartChatInput("/w " .. tostring(username) .. " " .. zo_strformat(GetString(WISHLIST_WHISPER_RECEIVER_QUESTION), username, itemLink)) end) -- Whisper and ask for item
                    end
                    AddCustomMenuItem(GetString(WISHLIST_LINK_ITEM_TO_CHAT), function() StartChatInput(CHAT_SYSTEM.textEntry:GetText()..itemLink) end) -- Link item
                    AddCustomMenuItem(GetString(WISHLIST_DIALOG_REMOVE_ITEM), function()
                        WL.showRemoveItem(data, false, true, true)
                    end)  -- Remove history item
                    AddCustomMenuItem(zo_strformat(GetString(WISHLIST_DIALOG_REMOVE_ITEM_DATETIME), dateAndTime),
                        function() WL.showRemoveItem(data, false, true, true, WISHLIST_REMOVE_ITEM_TYPE_DATEANDTIME)
                    end)  -- Remove item by date & time
                    AddCustomMenuItem(ZO_CachedStrFormat(GetString(WISHLIST_DIALOG_REMOVE_ITEM_ARMORORWEAPONTYPE), armorOrWeaponType),
                        function() WL.showRemoveItem(data, false, true, true, WISHLIST_REMOVE_ITEM_TYPE_ARMORANDWEAPONTYPE)
                    end)  -- Remove item by armor or weapon type
                    AddCustomMenuItem(ZO_CachedStrFormat(GetString(WISHLIST_DIALOG_REMOVE_ITEM_SLOT), slot),
                        function() WL.showRemoveItem(data, false, true, true, WISHLIST_REMOVE_ITEM_TYPE_SLOT)
                    end)  -- Remove item by slot
                    AddCustomMenuItem(ZO_CachedStrFormat(GetString(WISHLIST_DIALOG_REMOVE_ITEM_TRAIT), trait),
                        function() WL.showRemoveItem(data, false, true, true, WISHLIST_REMOVE_ITEM_TYPE_TRAIT)
                    end)  -- Remove item by trait
                    AddCustomMenuItem(zo_strformat(GetString(WISHLIST_DIALOG_REMOVE_WHOLE_SET), setName), function()
                        WL.showRemoveItem(data, true, true, true)
                    end)  -- Remove whole set from history
                    --LibSets data
                    --Got drop zones of the item?
                    buildSetDropLocationContextMenuEntries(data)
                    --Got wayshrines of the item?
                    buildSetWayshrinesContextMenuEntries(data)
                end
                ShowMenu()
            end
        end
    end
end

--Search dropdown box texts
function WL.getSearchTypeText(searchType)
    if not searchType or searchType == "" or searchType < WISHLIST_SEARCH_TYPE_ITERATION_BEGIN or searchType > WISHLIST_SEARCH_TYPE_ITERATION_END then return end
    local prefix = WISHLIST_SEARCHDROP_PREFIX
    local searchTypeNameConstant = WISHLIST_SEARCHDROP_PREFIX .. tostring(searchType)
    local searchTypeName = GetString(_G[searchTypeNameConstant])
    return searchTypeName
end

------------------------------------------------
--- Load the sets
------------------------------------------------
local function showTotalItemsLoaded()
    --Update UI, loading sets to finished loadgin sets!
    WL.CurrentTab = WISHLIST_TAB_SEARCH
    WL.window:UpdateUI(WISHLIST_TAB_STATE_SETS_LOADED) -- Update UI, sets currently loading
    d("[" .. GetString(WISHLIST_TITLE) .."]")
    d("-> "..GetString(WISHLIST_TOTAL_SETS)..tostring(WL.accData.setCount))
    d("-> "..GetString(WISHLIST_TOTAL_SETS_ITEMS)..tostring(WL.accData.itemCount))
    d("<<=============================================<<")
end

--New with version 2.5 as LibSets provides the setData now and scanning is not needed anymore
function WL.GetAllSetData(silent)
    silent = silent or false
    if not silent then
        --Hide Controls
        WL.window.labelNoSets:SetHidden(true)
        WL.window.buttonLoadSets:SetHidden(true)

        --Show Loading controls
        WL.window.labelLoadingSets:SetHidden(false)
        d(">>=============================================>>")
        d("[" .. GetString(WISHLIST_TITLE) .."]")
        d(GetString(WISHLIST_LOADING_SETS))

        --Update UI, no sets loaded yet -> Beginning to load sets
        WL.CurrentTab = WISHLIST_TAB_SEARCH
        WL.window:UpdateUI(WISHLIST_TAB_STATE_SETS_LOADING)
    end

    --Clear all set data
    WL.accData.sets = {}
    WL.accData.setCount = 0
    WL.accData.itemCount = 0

    --Clear the setCount variables
    WL.setNames = {}

    --Get all sets using LibSets
    if WL.LibSets == nil then WL.LibSets = LibSets end
    if WL.LibSets == nil then d("[WishList]Needed library \'LibSets\' is missing or not activated!") return end
    libSets = WL.LibSets
    local libSetsVersion = libSets.version
    local setCount = 0
    local allSetIds = libSets.GetAllSetIds()
    if allSetIds then
        local setItemIdsPreloaded = libSets.GetAllSetItemIds()
        local setNamesPreloaded   = libSets.GetAllSetNames()
        if not setItemIdsPreloaded or not setNamesPreloaded then
            d("<<ERROR: LibSets data is missing (itemIds, names)")
            return
        end
        --local clientLang = WL.clientLang or WL.fallbackSetLang
        local setsData = WL.accData.sets
        --For each setId: Read the setItemIds, and the name and the build a table for the WishList data (SavedVariables)
        for setId, _ in pairs(allSetIds) do
--d(">setId: " ..tostring(setId))
            local setNamesAdded = false
            local setItemIdsAdded = false
            local setsArmorTypes = nil
            local setsDropMechanics = nil
            setsData[setId] = {}
            --Add set names and client language name
            if setNamesPreloaded[setId] ~= nil then
--d(">>setNamesPreloaded found")
                setNamesAdded = true
                local setNames = setNamesPreloaded[setId]
                setsData[setId].names = setNames
                --if setNames[clientLang] ~= nil then
                --    setsData[setId].name = setNames[clientLang]
                --    WL.setNames[setNames[clientLang]] = true
                --end
            end
            --Add the itemIds of the set
            if setItemIdsPreloaded[setId] ~= nil then
--d(">>setItemIdsPreloaded found")
                for setItemId, _ in pairs(setItemIdsPreloaded[setId]) do
                    setsData[setId][setItemId] = true
                    WL.accData.itemCount = WL.accData.itemCount + 1
                    setItemIdsAdded = true
                end
                --Get the armorType of the setItemIds and build the setsArmorTypes table
                if libSets.GetSetArmorTypes then
                    setsArmorTypes = libSets.GetSetArmorTypes(setId)
                    if setsArmorTypes then
                        setsData[setId]["armorTypes"] = setsArmorTypes
                    end
                end
                --Get the dropMEchnic of the setItemIds and build the setsDropMechanics table
                if libSets.GetDropMechanic then
                    setsDropMechanics = libSets.GetDropMechanic(setId, false)
                    if setsDropMechanics then
                        setsData[setId]["dropMechanics"] = setsDropMechanics
                    end
                end
            end
            if setNamesAdded or setItemIdsAdded then
                setCount = setCount + 1
            end
        end
        --Update the sets count
        WL.accData.setCount = setCount
        WL.accData.setsLastScanned = GetTimeStamp()
        WL.accData.setsLastScannedLibSetsVersion = libSetsVersion
    else
        d("<<ERROR: LibSets data is missing (setIds)")
    end
    if not silent then
        showTotalItemsLoaded()
    end
end


------------------------------------------------
--- Wishlist keybinding functions
------------------------------------------------
local function MyGetItemDetails(rowControl)
    local bagId, slotIndex

    --gotta do this in case deconstruction, or player equipment
    local dataEntry = rowControl.dataEntry

    --case to handle equiped items
    if(not dataEntry) then
        bagId = rowControl.bagId
        slotIndex = rowControl.slotIndex
    else
        bagId = dataEntry.data.bagId
        slotIndex = dataEntry.data.slotIndex
    end

    --case to handle list dialog, list dialog uses index instead of slotIndex and bag instead of bagId...?
    if(dataEntry and not bagId and not slotIndex) then
        bagId = rowControl.dataEntry.data.bag
        slotIndex = rowControl.dataEntry.data.index
    end

    return bagId, slotIndex
end

function WL.checkIfAlreadyOnWishList(bagId, slotIndex, charData)
    local itemLink = GetItemLink(bagId, slotIndex)
    local isSet, setName, _, _, _, setId = GetItemLinkSetInfo(itemLink, false)
    if not isSet then return end
    local itemType = GetItemLinkItemType(itemLink)
    local armorOrWeaponType = 0
    if itemType == ITEMTYPE_ARMOR then
        armorOrWeaponType = GetItemLinkArmorType(itemLink)
    elseif itemType == ITEMTYPE_WEAPON then
        armorOrWeaponType = GetItemLinkWeaponType(itemLink)
    end
    local slotType = GetItemLinkEquipType(itemLink)
    local traitType = GetItemLinkTraitInfo(itemLink)
    local equipType = GetItemLinkEquipType(itemLink)
    local itemQuality = GetItemLinkDisplayQuality(itemLink)
    --Get the currently logged in charData
    WL.checkCurrentCharData(true)
    charData = charData or WL.LoggedInCharData
    --Check if already on Wishlist
    local isAlreadyOnWL, setItemId, item = WL.isItemAlreadyOnWishlist(itemLink, nil, charData, true, setId, itemType, armorOrWeaponType, slotType, traitType, itemQuality)
    return isAlreadyOnWL, setItemId, setId, setName, itemType, armorOrWeaponType, equipType, traitType, itemQuality, charData, item
end

function WL.GetBagAndSlotFromControlUnderMouse()
    --Get the control below the mouse cursor
    local moctrl = WINDOW_MANAGER:GetMouseOverControl()
    if moctrl == nil then return end
    --d("[GetBagAndSlotFromControlUnderMouse] " .. moc:GetName())
    local bagId
    local slotIndex
    --if it's a backpack row or child of one -> PRE API 1000015
    if moctrl:GetName():find("^ZO_%a+Backpack%dRow%d%d*") then
        if moctrl:GetName():find("^ZO_%a+Backpack%dRow%d%d*$") then
            bagId, slotIndex = MyGetItemDetails(moctrl)
        else
            moctrl = moctrl:GetParent()
            if moctrl:GetName():find("^ZO_%a+Backpack%dRow%d%d*$") then
                bagId, slotIndex = MyGetItemDetails(moctrl)
            end
        end
        --if it's a backpack row or child of one -> Since API 1000015
    elseif moctrl:GetName():find("^ZO_%a+InventoryList%dRow%d%d*") then
        if moctrl:GetName():find("^ZO_%a+InventoryList%dRow%d%d*$") then
            bagId, slotIndex = MyGetItemDetails(moctrl)
        else
            moctrl = moctrl:GetParent()
            if moctrl:GetName():find("^ZO_%a+InventoryList%dRow%d%d*$") then
                bagId, slotIndex = MyGetItemDetails(moctrl)
            end
        end
        --CRAFTBAG: if it's a backpack row or child of one -> Since API 1000015
    elseif moctrl:GetName():find("^ZO_CraftBagList%dRow%d%d*") then
        if moctrl:GetName():find("^ZO_CraftBagList%dRow%d%d*$") then
            bagId, slotIndex = MyGetItemDetails(moctrl)
        else
            moctrl = moctrl:GetParent()
            if moctrl:GetName():find("^ZO_CraftBagList%dRow%d%d*$") then
                bagId, slotIndex = MyGetItemDetails(moctrl)
            end
        end
        --Character
    elseif moctrl:GetName():find("^ZO_CharacterEquipmentSlots.+$") then
        bagId, slotIndex = MyGetItemDetails(moctrl)
        --Quickslot
    elseif moctrl:GetName():find("^ZO_QuickSlotList%dRow%d%d*") then
        bagId, slotIndex = MyGetItemDetails(moctrl)
        --Vendor rebuy
    elseif moctrl:GetName():find("^ZO_RepairWindowList%dRow%d%d*") then
        bagId, slotIndex = MyGetItemDetails(moctrl)
    end
    if bagId ~= nil and slotIndex ~= nil then
        return bagId, slotIndex
    else
        return false
    end
end

------------------------------------------------
--- Wishlist date/time functions
------------------------------------------------
function WL.getDateTimeFormatted(dateTimeStamp)
--d("[WL.getDateTimeFormatted]dateTimeStamp: "  ..tostring(dateTimeStamp))
    local dateTimeStr = ""
    if dateTimeStamp ~= nil then
        --Format the timestamp to the output version again
        if os and os.date then
            if WL.accData.useCustomDateFormat ~= nil and WL.accData.useCustomDateFormat ~= "" then
                dateTimeStr = os.date(WL.accData.useCustomDateFormat, dateTimeStamp)
            else
                if WL.accData.use24hFormat then
                    dateTimeStr = os.date("%d.%m.%y, %H:%M:%S", dateTimeStamp)
                else
                    dateTimeStr = os.date("%y-%m-%d, %I:%M:%S %p", dateTimeStamp)
                end

            end
        end
    end
    return dateTimeStr
end

function WL.addTimeStampToItem(item)
--d("[WL.addTimeStampToItem]")
    --Add the current date & time to the item
    if item and os and os.time then
        local currentTimeAndDateTimestamp = os.time()
        if currentTimeAndDateTimestamp ~= nil then
            item.timestamp = currentTimeAndDateTimestamp
        end
    end
    return item
end

------------------------------------------------
--- Wishlist zone & group functions
------------------------------------------------
function WL.getCurrentZoneAndGroupStatus()
    local isInPublicDungeon = false
    local isInGroupDungeon = false
    local isInAnyDungeon = false
    local isInRaid = false
    local isInDelve = false
    local isInGroup = false
    local groupSize = 0
    local isInPVP = false
    local zoneId = 0
    local subZoneId = 0
    local currentMapZoneIndex = GetCurrentMapZoneIndex()
    if currentMapZoneIndex ~= nil then
        zoneId = GetZoneId(currentMapZoneIndex)
        if GetParentZoneId ~= nil then
            local parentZoneId = GetParentZoneId(zoneId)
            if parentZoneId ~= nil and parentZoneId ~= 0 then
                subZoneId = zoneId
                zoneId = parentZoneId
            end
        end
    end

    isInPVP = IsPlayerInAvAWorld()
    isInAnyDungeon = IsAnyGroupMemberInDungeon() -- returns true if not in group and in solo dungeon/delve
    isInRaid = IsPlayerInRaid()
    isInGroup = IsUnitGrouped("player")

    --Check if user is in any dungeon
    if not isInGroup then
        isInDelve = isInAnyDungeon
    else
        groupSize = GetGroupSize() --SMALL_GROUP_SIZE_THRESHOLD (4) / RAID_GROUP_SIZE_THRESHOLD (12) / GROUP_SIZE_MAX (24)
        isInDelve = isInAnyDungeon and not isInRaid and groupSize <= SMALL_GROUP_SIZE_THRESHOLD
    end
    --Get POI info for group and public dungeons
    local zoneIndex, poiIndex = GetCurrentSubZonePOIIndices()
    local abort = false
    if zoneIndex == nil then
        abort = true
    end
    if poiIndex == nil then
        abort = true
    end
    if not abort then
        local _, _, _, iconPath = GetPOIMapInfo(zoneIndex, poiIndex)
        if iconPath:find("poi_delve") then
            -- in a delve
            isInDelve = true
        end
        isInPublicDungeon = GetPOIType(zoneIndex, poiIndex) == POI_TYPE_PUBLIC_DUNGEON
        isInGroupDungeon = GetPOIType(zoneIndex, poiIndex) == POI_TYPE_GROUP_DUNGEON
        if isInPublicDungeon then
            isInDelve = false
            isInGroupDungeon = false
        elseif isInGroupDungeon then
            isInDelve = false
            isInPublicDungeon = false
        end
        --[[
            else
                --Workaround as long as some public dungeons are not determined correctly (e.g. in Reapers March)
                --Workaround disabled: Delves are not determined correctly this way (you are normally grouped in public dungeons?!)!
                isInPublicDungeon = (isInAnyDungeon and not isInGroup)
        ]]
    end
--d("[WL.getCurrentZoneAndGroupStatus] PvP: " .. tostring(isInPVP) .. ", Delve: " .. tostring(isInDelve) .. ", PubDun: " .. tostring(isInPublicDungeon) .. ", GroupDun: " .. tostring(isInGroupDungeon) .. ", inGroup: " .. tostring(isInGroup) .. ", groupSize: " .. groupSize .. ", zoneId: " .. tostring(zoneId) .. ", subZoneId: " .. tostring(subZoneId))
    return isInPVP, isInDelve, isInPublicDungeon, isInGroupDungeon, isInRaid, isInGroup, groupSize, zoneId, subZoneId
end

------------------------------------------------
--- Group functions
------------------------------------------------
function WL.mapGroupedCharNameToAccountName(charNameInGroup)
--d("[WL.mapGroupedCharNameToAccountName]charNameInGroup: " .. tostring(charNameInGroup))
    local cleanCharNameInGroup = ZO_CachedStrFormat(SI_UNIT_NAME, charNameInGroup)
    --Are we in a group? And is the accountName we want to check in our group?
    if not IsUnitGrouped("player") or not IsCharacterInGroup(cleanCharNameInGroup) then return nil end
    --Get own player's name
    local playerName = ZO_CachedStrFormat(SI_UNIT_NAME, GetUnitName("player"))
    -- Get group Size
    local groupSize = GetGroupSize()
    -- Cycle through group and get their "unitTags"
    for i=1, groupSize, 1 do
        local unitTagOfGroupMember = GetGroupUnitTagByIndex(i)
        local charName = ZO_CachedStrFormat(SI_UNIT_NAME, GetUnitName(unitTagOfGroupMember))
        --Charname of the unit in the group is the one that looted an item? Return it's accountname now
        if charName ~= playerName and charName == cleanCharNameInGroup then
            local unitDisplayName = GetUnitDisplayName(unitTagOfGroupMember)
            if unitDisplayName ~= nil and unitDisplayName ~= "" then
                return unitDisplayName
            end
        end
    end
    return nil
end


------------------------------------------------
--- Table search functions
------------------------------------------------
--[[
function WL.searchTableWithSearchString(tableToSearch, searchString, tableKey)
    if tableToSearch ~= nil and searchString ~= nil and searchString ~= "" then
        for _, tableValueString in pairs(tableToSearch) do
            if zo_plainstrfind(tableValueString:lower(), searchString) then
                return true
            end
        end
    end
    return false
end
]]


------------------------------------------------
--- Color functions
------------------------------------------------
-- Map the qualityId of WishList to one ZOs qualityId
function WL.mapWLQualityToZOsQuality(qualityIdWishList)
    local qualityIdStart = ITEM_QUALITY_NORMAL
    local qualityIdEnd   = ITEM_QUALITY_LEGENDARY
    local mapQualitiesStart = {
        [WISHLIST_QUALITY_ALL]		                = ITEM_QUALITY_TRASH,       --Any quality
        [WISHLIST_QUALITY_TRASH] 	                = ITEM_QUALITY_TRASH, 		--Trash
        [WISHLIST_QUALITY_NORMAL] 	                = ITEM_QUALITY_NORMAL, 		--Normal (white)
        [WISHLIST_QUALITY_MAGIC] 	                = ITEM_QUALITY_MAGIC, 		--Magic (green)
        [WISHLIST_QUALITY_ARCANE] 	                = ITEM_QUALITY_ARCANE, 		--Arcane (blue)
        [WISHLIST_QUALITY_ARTIFACT] 	            = ITEM_QUALITY_ARTIFACT, 	--Artifact (purple)
        [WISHLIST_QUALITY_LEGENDARY]		        = ITEM_QUALITY_LEGENDARY, 	--Legendary (golden)
        [WISHLIST_QUALITY_MAGIC_OR_ARCANE] 	        = ITEM_QUALITY_MAGIC, 		--Magic or arcane
        [WISHLIST_QUALITY_ARCANE_OR_ARTIFACT]		= ITEM_QUALITY_ARCANE, 		--Arcane or artifact
        [WISHLIST_QUALITY_ARTIFACT_OR_LEGENDARY]	= ITEM_QUALITY_ARTIFACT, 	--Artifact or legendary
        [WISHLIST_QUALITY_MAGIC_TO_LEGENDARY]	    = ITEM_QUALITY_MAGIC, 		--Magic to legendary
        [WISHLIST_QUALITY_ARCANE_TO_LEGENDARY]	    = ITEM_QUALITY_ARCANE, 		--Arcane to legendary
    }
    local mapQualitiesEnd = {
        [WISHLIST_QUALITY_ALL]		                = ITEM_QUALITY_LEGENDARY,   --Any quality
        [WISHLIST_QUALITY_TRASH] 	                = ITEM_QUALITY_TRASH, 		--Trash
        [WISHLIST_QUALITY_NORMAL] 	                = ITEM_QUALITY_NORMAL, 		--Normal (white)
        [WISHLIST_QUALITY_MAGIC] 	                = ITEM_QUALITY_MAGIC, 		--Magic (green)
        [WISHLIST_QUALITY_ARCANE] 	                = ITEM_QUALITY_ARCANE, 		--Arcane (blue)
        [WISHLIST_QUALITY_ARTIFACT] 	            = ITEM_QUALITY_ARTIFACT, 	--Artifact (purple)
        [WISHLIST_QUALITY_LEGENDARY]		        = ITEM_QUALITY_LEGENDARY, 	--Legendary (golden)
        [WISHLIST_QUALITY_MAGIC_OR_ARCANE] 	        = ITEM_QUALITY_ARCANE, 		--Magic or arcane
        [WISHLIST_QUALITY_ARCANE_OR_ARTIFACT]		= ITEM_QUALITY_ARTIFACT, 	--Arcane or artifact
        [WISHLIST_QUALITY_ARTIFACT_OR_LEGENDARY]	= ITEM_QUALITY_LEGENDARY, 	--Artifact or legendary
        [WISHLIST_QUALITY_MAGIC_TO_LEGENDARY]	    = ITEM_QUALITY_LEGENDARY, 	--Magic to legendary
        [WISHLIST_QUALITY_ARCANE_TO_LEGENDARY]	    = ITEM_QUALITY_LEGENDARY, 	--Arcane to legendary
    }
    if mapQualitiesStart[qualityIdWishList] ~= nil then
        qualityIdStart = mapQualitiesStart[qualityIdWishList]
    end
    if mapQualitiesEnd[qualityIdWishList] ~= nil then
        qualityIdEnd = mapQualitiesEnd[qualityIdWishList]
    end
    return qualityIdStart, qualityIdEnd
end

function WL.ColorizeByQualityColor(text, WLquality)
    if not text or text == "" or not WLquality then return "" end
    local ZOsQualityIdFrom, ZOsQualityIdTo = WL.mapWLQualityToZOsQuality(WLquality)
    local qualityColorFrom  = GetItemQualityColor(ZOsQualityIdFrom)
    local colorizedText = text
    --More than 1 color to apply to the text (from -> to values)
    if ZOsQualityIdFrom ~= ZOsQualityIdTo then
        local qualityColorTo = GetItemQualityColor(ZOsQualityIdTo)
        --Split the string at the half and colorize the "left with from" and the "right part with to" quality colors
        local strLen = string.len(text)
        local endleft = zo_roundToNearest(strLen/2, 1)
        local strLeft = string.sub(text, 1, endleft)
        local strRight = string.sub(text, endleft+1)
        colorizedText = qualityColorFrom:Colorize(strLeft) .. qualityColorTo:Colorize(strRight)
    else
        colorizedText = qualityColorFrom:Colorize(text)
    end
    return colorizedText
end