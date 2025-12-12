local RSGCore = exports['rsg-core']:GetCoreObject()


RSGCore.Functions.CreateCallback('rsg-presents:server:hasWrappingMaterials', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false, false)
        return
    end
    
    local emptyBox = Player.Functions.GetItemByName(Config.EmptyBoxItem)
    local wrappingPaper = Player.Functions.GetItemByName(Config.WrappingPaperItem)
    
    local hasBox = emptyBox and emptyBox.amount > 0
    local hasPaper = wrappingPaper and wrappingPaper.amount > 0
    
    cb(hasBox, hasPaper)
end)


RSGCore.Functions.CreateCallback('rsg-presents:server:getPlayerName', function(source, cb, targetId)
    local Player = RSGCore.Functions.GetPlayer(targetId)
    
    if Player then
        local charInfo = Player.PlayerData.charinfo
        cb(charInfo.firstname .. ' ' .. charInfo.lastname)
    else
        cb('Unknown Player')
    end
end)


RegisterNetEvent('rsg-presents:server:wrapItem', function(itemName, amount, slot)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    
    for _, item in ipairs(Config.BlacklistedItems) do
        if item == itemName then
            TriggerClientEvent('rsg-presents:client:showError', src, Config.Messages.blacklisted)
            return
        end
    end
    
    
    local playerItem = Player.Functions.GetItemByName(itemName)
    if not playerItem or playerItem.amount < amount then
        TriggerClientEvent('rsg-presents:client:showError', src, 'You don\'t have enough of this item!')
        return
    end
    
    
    local emptyBox = Player.Functions.GetItemByName(Config.EmptyBoxItem)
    if not emptyBox or emptyBox.amount < 1 then
        TriggerClientEvent('rsg-presents:client:showError', src, Config.Messages.no_box)
        return
    end
    
    
    local wrappingPaper = Player.Functions.GetItemByName(Config.WrappingPaperItem)
    if not wrappingPaper or wrappingPaper.amount < 1 then
        TriggerClientEvent('rsg-presents:client:showError', src, Config.Messages.no_paper)
        return
    end
    
   
    local itemInfo = playerItem.info or {}
    
    
    local removed = Player.Functions.RemoveItem(itemName, amount, slot)
    if not removed then
        TriggerClientEvent('rsg-presents:client:showError', src, 'Failed to remove item!')
        return
    end
    
    
    local boxRemoved = Player.Functions.RemoveItem(Config.EmptyBoxItem, 1)
    if not boxRemoved then
       
        Player.Functions.AddItem(itemName, amount, nil, itemInfo)
        TriggerClientEvent('rsg-presents:client:showError', src, 'Failed to use gift box!')
        return
    end
    
    
    local paperRemoved = Player.Functions.RemoveItem(Config.WrappingPaperItem, 1)
    if not paperRemoved then
        
        Player.Functions.AddItem(itemName, amount, nil, itemInfo)
        Player.Functions.AddItem(Config.EmptyBoxItem, 1)
        TriggerClientEvent('rsg-presents:client:showError', src, 'Failed to use wrapping paper!')
        return
    end
    
    
    local presentMetadata = {
        wrappedItem = itemName,
        wrappedAmount = amount,
        wrappedInfo = itemInfo,
        wrappedBy = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        wrappedAt = os.date('%Y-%m-%d %H:%M')
    }
    
    
    local added = Player.Functions.AddItem(Config.PresentItem, 1, nil, presentMetadata)
    
    if added then
        TriggerClientEvent('rsg-presents:client:wrapSuccess', src)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.PresentItem], 'add', 1)
    else
        
        Player.Functions.AddItem(itemName, amount, nil, itemInfo)
        Player.Functions.AddItem(Config.EmptyBoxItem, 1)
        Player.Functions.AddItem(Config.WrappingPaperItem, 1)
        TriggerClientEvent('rsg-presents:client:showError', src, 'Failed to create present!')
    end
end)

RegisterNetEvent('rsg-presents:server:givePresent', function(targetServerId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local TargetPlayer = RSGCore.Functions.GetPlayer(targetServerId)
    
    if not Player or not TargetPlayer then
        TriggerClientEvent('rsg-presents:client:showError', src, 'Player not found!')
        return
    end
    
    
    local present = Player.Functions.GetItemByName(Config.PresentItem)
    if not present or present.amount < 1 then
        TriggerClientEvent('rsg-presents:client:showError', src, 'You don\'t have a present to give!')
        return
    end
    
    local presentInfo = present.info or {}
    
    
    local giverName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local receiverName = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
    
    
    local removed = Player.Functions.RemoveItem(Config.PresentItem, 1)
    if not removed then
        TriggerClientEvent('rsg-presents:client:showError', src, 'Failed to remove present!')
        return
    end
    
   
    local giftTagInfo = {
        from = giverName,
        to = receiverName,
        date = os.date('%B %d, %Y'),
        message = 'Merry Christmas!'
    }
    
    
    local added = TargetPlayer.Functions.AddItem(Config.PresentItem, 1, nil, presentInfo)
    
    if added then
        
        local tagAdded = TargetPlayer.Functions.AddItem(Config.GiftTagItem, 1, nil, giftTagInfo)
        
        if tagAdded then
            TriggerClientEvent('rsg-inventory:client:ItemBox', targetServerId, RSGCore.Shared.Items[Config.GiftTagItem], 'add', 1)
        end
        
        TriggerClientEvent('rsg-presents:client:gavePresent', src, receiverName)
        TriggerClientEvent('rsg-presents:client:receivedPresent', targetServerId, giverName)
        TriggerClientEvent('rsg-inventory:client:ItemBox', targetServerId, RSGCore.Shared.Items[Config.PresentItem], 'add', 1)
    else
       
        Player.Functions.AddItem(Config.PresentItem, 1, nil, presentInfo)
        TriggerClientEvent('rsg-presents:client:showError', src, 'Failed to give present - inventory full!')
    end
end)


RSGCore.Functions.CreateUseableItem(Config.GiftTagItem, function(source, item)
    TriggerClientEvent('rsg-presents:client:useGiftTag', source, item.info)
end)


RegisterNetEvent('rsg-presents:server:unwrapPresent', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    
    local present = Player.Functions.GetItemByName(Config.PresentItem)
    if not present or present.amount < 1 then
        TriggerClientEvent('rsg-presents:client:showError', src, 'You don\'t have a present to unwrap!')
        return
    end
    
    local presentInfo = present.info or {}
    
   
    if not presentInfo.wrappedItem or not presentInfo.wrappedAmount then
        TriggerClientEvent('rsg-presents:client:showError', src, Config.Messages.invalid_present)
        Player.Functions.RemoveItem(Config.PresentItem, 1)
        return
    end
    
    local wrappedItem = presentInfo.wrappedItem
    local wrappedAmount = presentInfo.wrappedAmount
    local wrappedInfo = presentInfo.wrappedInfo or {}
    
    
    local itemData = RSGCore.Shared.Items[wrappedItem]
    if not itemData then
        TriggerClientEvent('rsg-presents:client:showError', src, Config.Messages.invalid_present)
        Player.Functions.RemoveItem(Config.PresentItem, 1)
        return
    end
    
    
    local removed = Player.Functions.RemoveItem(Config.PresentItem, 1)
    if not removed then
        TriggerClientEvent('rsg-presents:client:showError', src, 'Failed to unwrap present!')
        return
    end
    
    
    local added = Player.Functions.AddItem(wrappedItem, wrappedAmount, nil, wrappedInfo)
    
    if added then
        local itemLabel = itemData.label or wrappedItem
        TriggerClientEvent('rsg-presents:client:unwrappedPresent', src, itemLabel, wrappedAmount)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, itemData, 'add', wrappedAmount)
    else
        
        Player.Functions.AddItem(Config.PresentItem, 1, nil, presentInfo)
        TriggerClientEvent('rsg-presents:client:showError', src, 'Inventory full - cannot unwrap!')
    end
end)


RSGCore.Functions.CreateUseableItem(Config.EmptyBoxItem, function(source, item)
    TriggerClientEvent('rsg-presents:client:useEmptyBox', source)
end)

RSGCore.Functions.CreateUseableItem(Config.WrappingPaperItem, function(source, item)
    TriggerClientEvent('rsg-presents:client:useWrappingPaper', source)
end)

RSGCore.Functions.CreateUseableItem(Config.PresentItem, function(source, item)
    TriggerClientEvent('rsg-presents:client:useWrappedPresent', source, item.info)
end)

print('^2[rsg-presents]^7 Resource started successfully!')