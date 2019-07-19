WishList = WishList or {}
local WL = WishList

------------------------------------------------
--- Wishlist - Keybindings
------------------------------------------------
--Add/Remove an item from the wishlist via keybinding
function WishList:AddOrRemoveFromWishList()
    --d("WishList:AddOrRemoveFromWishList()")
    local bagId, slotIndex = WL.GetBagAndSlotFromControlUnderMouse()
    --bag and slot could be retrieved?
    if bagId ~= nil and slotIndex ~= nil then
        --d(">bag: " .. tostring(bagId) .. ", slot: " .. tostring(slotIndex))
        local itemLink = GetItemLink(bagId, slotIndex)
        local isSet, setName, _, _, _, setId = GetItemLinkSetInfo(itemLink, false)
        if not isSet then return end
        --d(">isSet: " ..tostring(isSet) .. ", setName: " ..tostring(setName) .. ", armorOrWeaponType: " .. tostring(armorOrWeaponType))
        local itemType = GetItemLinkItemType(itemLink)
        local armorOrWeaponType = 0
        if itemType == ITEMTYPE_ARMOR then
            armorOrWeaponType = GetItemLinkArmorType(itemLink)
        elseif itemType == ITEMTYPE_WEAPON then
            armorOrWeaponType = GetItemLinkWeaponType(itemLink)
        end
        local slotType = GetItemLinkEquipType(itemLink)
        local traitType = GetItemLinkTraitInfo(itemLink)
        local itemQuality = GetItemLinkQuality(itemLink)
        --d(">Checking if item " .. itemLink .. " is on WishList...")
        --Get the currently logged in charData
        WL.checkCurrentCharData(true)
        local charData = WL.LoggedInCharData
        --Check if already on Wishlist
        local isAlreadyOnWL, setItemId = WL.isItemAlreadyOnWishlist(itemLink, nil, charData, true, setId, itemType, armorOrWeaponType, slotType, traitType, itemQuality)
        --If not: add the item
        if setItemId == nil then
            --d("<< ABORTED!")
            return
        end
        if not isAlreadyOnWL then
            local equipType = GetItemLinkEquipType(itemLink)
            local qualityWL = itemQuality + WL.ESOquality2WLqualityAdd

            setName = zo_strformat("<<C:1>>", setName)
            local items = {}
            local data = {}
            data.setId      = setId
            data.setName    = setName
            data.id         = setItemId
            data.itemType   = itemType
            data.armorOrWeaponType       = armorOrWeaponType
            data.slot       = equipType
            data.trait      = traitType
            data.quality    = qualityWL
            table.insert(items, data)
            --WishList:AddItem(items, charData, alreadyOnWishlistCheckDone, noAddedChatOutput)
            WishList:AddItem(items, charData, true)
        else
            --Already on WishList, so ask to remove it
            local item = {}
            item.id = setItemId
            WL.showRemoveItem(item)
        end
    end
end
