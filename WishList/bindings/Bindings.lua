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
        local itemType = GetItemLinkItemType(itemLink)
        --d(">ItemType: " ..tostring(itemType))
        local armorOrWeaponType = 0
        if itemType == ITEMTYPE_ARMOR then
            armorOrWeaponType = GetItemLinkArmorType(itemLink)
        elseif itemType == ITEMTYPE_WEAPON then
            armorOrWeaponType = GetItemLinkWeaponType(itemLink)
        end
        local isSet, setName, _, _, _, setId = GetItemLinkSetInfo(itemLink, false)
        --d(">isSet: " ..tostring(isSet) .. ", setName: " ..tostring(setName) .. ", armorOrWeaponType: " .. tostring(armorOrWeaponType))
        if not isSet then return end
        --d(">Checking if item " .. itemLink .. " is on WishList...")
        --Get the item's id from the link
        --Check if already on Wishlist
        local isAlreadyOnWL, setItemId = WL.isItemAlreayOnWishlist(itemLink)
        --If not: add the item
        if setItemId == nil then
            --d("<< ABORTED!")
            return
        end
        if not isAlreadyOnWL then
            local traitType = GetItemLinkTraitInfo(itemLink)
            local equipType = GetItemLinkEquipType(itemLink)
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
            table.insert(items, data)
            WishList:AddItem(items)
        else
            --Already on WishList, so ask to remove it
            local item = {}
            item.id = setItemId
            WL.showRemoveItem(item)
        end
    end
end
