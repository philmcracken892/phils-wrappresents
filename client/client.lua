local RSGCore = exports['rsg-core']:GetCoreObject()

local isWrapping = false
local propHandle = nil


local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local timeout = 0
        while not HasAnimDictLoaded(dict) and timeout < 1000 do
            Wait(10)
            timeout = timeout + 10
        end
    end
    return HasAnimDictLoaded(dict)
end


local function IsBlacklisted(itemName)
    for _, item in ipairs(Config.BlacklistedItems) do
        if item == itemName then
            return true
        end
    end
    return false
end


local function GetPlayerItems()
    local items = {}
    local playerData = RSGCore.Functions.GetPlayerData()
    
    if playerData and playerData.items then
        for slot, item in pairs(playerData.items) do
            if item and item.name and item.amount and item.amount > 0 then
                if not IsBlacklisted(item.name) then
                    table.insert(items, {
                        slot = slot,
                        name = item.name,
                        label = item.label or item.name,
                        amount = item.amount,
                        info = item.info or {}
                    })
                end
            end
        end
    end
    
    return items
end


local function CreateProp()
    if not Config.PresentProp then return end
    
    local ped = PlayerPedId()
    local modelHash = GetHashKey(Config.PresentProp)
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 500 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if not HasModelLoaded(modelHash) then
        return
    end
    
    local coords = GetEntityCoords(ped)
    propHandle = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)
    
    if propHandle and DoesEntityExist(propHandle) then
        local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_L_Hand")
        AttachEntityToEntity(propHandle, ped, boneIndex, 0.1, 0.05, -0.03, 30.0, 0.0, 0.0, true, true, false, true, 1, true)
    end
    
    SetModelAsNoLongerNeeded(modelHash)
end

-- Delete prop
local function DeleteProp()
    if propHandle and DoesEntityExist(propHandle) then
        DeleteEntity(propHandle)
        propHandle = nil
    end
end


local function PlayWrappingAnimation()
    local ped = PlayerPedId()
    
    isWrapping = true
    
    local dictLoaded = LoadAnimDict(Config.Animation.dict)
    if not dictLoaded then
        isWrapping = false
        return false
    end
    
    CreateProp()
    
    TaskPlayAnim(ped, Config.Animation.dict, Config.Animation.clip, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    local success = lib.progressCircle({
        duration = Config.Animation.duration,
        position = 'bottom',
        label = Config.Messages.wrapping,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        }
    })
    
    ClearPedTasks(ped)
    DeleteProp()
    RemoveAnimDict(Config.Animation.dict)
    
    isWrapping = false
    
    return success
end


local function WrapItem(itemName, amount, slot)
    local success = PlayWrappingAnimation()
    
    if success then
        TriggerServerEvent('rsg-presents:server:wrapItem', itemName, amount, slot)
    else
        lib.notify({
            title = 'Presents',
            description = Config.Messages.wrapped_cancel,
            type = 'error'
        })
    end
end


local function ProcessSelectedItem(item)
    if item.amount == 1 then
        WrapItem(item.name, 1, item.slot)
        return
    end
    
    local input = lib.inputDialog('Wrap Present', {
        {
            type = 'number',
            label = 'Amount to wrap',
            description = 'You have ' .. item.amount .. ' ' .. item.label,
            default = 1,
            min = 1,
            max = item.amount
        }
    })
    
    if input and input[1] then
        local amount = tonumber(input[1])
        if amount and amount > 0 and amount <= item.amount then
            WrapItem(item.name, amount, item.slot)
        else
            lib.notify({
                title = 'Presents',
                description = 'Invalid amount!',
                type = 'error'
            })
        end
    end
end


local function OpenWrapMenu()
    if isWrapping then return end
    
    RSGCore.Functions.TriggerCallback('rsg-presents:server:hasWrappingMaterials', function(hasBox, hasPaper)
        if not hasBox and not hasPaper then
            lib.notify({
                title = 'Presents',
                description = Config.Messages.no_materials,
                type = 'error'
            })
            return
        elseif not hasBox then
            lib.notify({
                title = 'Presents',
                description = Config.Messages.no_box,
                type = 'error'
            })
            return
        elseif not hasPaper then
            lib.notify({
                title = 'Presents',
                description = Config.Messages.no_paper,
                type = 'error'
            })
            return
        end
        
        local items = GetPlayerItems()
        
        if #items == 0 then
            lib.notify({
                title = 'Presents',
                description = Config.Messages.no_items,
                type = 'error'
            })
            return
        end
        
        local options = {}
        
        for _, item in ipairs(items) do
            local itemData = {
                slot = item.slot,
                name = item.name,
                label = item.label,
                amount = item.amount,
                info = item.info
            }
            
            table.insert(options, {
                title = item.label,
                description = 'Amount: ' .. item.amount,
                icon = 'gift',
                onSelect = function()
                    ProcessSelectedItem(itemData)
                end
            })
        end
        
        lib.registerContext({
            id = 'wrap_present_menu',
            title = '🎁 Select Item to Wrap',
            options = options
        })
        
        lib.showContext('wrap_present_menu')
    end)
end


local function GetNearbyPlayers()
    local players = {}
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local playerList = GetActivePlayers()
    
    for _, player in ipairs(playerList) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(coords - targetCoords)
            
            if distance <= Config.GiveDistance then
                local serverId = GetPlayerServerId(player)
                table.insert(players, {
                    id = player,
                    serverId = serverId,
                    distance = distance
                })
            end
        end
    end
    
    return players
end


local function GivePresentToPlayer(targetServerId)
    local success = PlayWrappingAnimation()
    
    if success then
        TriggerServerEvent('rsg-presents:server:givePresent', targetServerId)
    else
        lib.notify({
            title = 'Presents',
            description = Config.Messages.wrapped_cancel,
            type = 'error'
        })
    end
end


local function OpenGiveMenu()
    local nearbyPlayers = GetNearbyPlayers()
    
    if #nearbyPlayers == 0 then
        lib.notify({
            title = 'Presents',
            description = Config.Messages.no_players,
            type = 'error'
        })
        return
    end
    
    local options = {}
    local playersProcessed = 0
    local totalPlayers = #nearbyPlayers
    
    for _, player in ipairs(nearbyPlayers) do
        local serverId = player.serverId
        local dist = player.distance
        
        RSGCore.Functions.TriggerCallback('rsg-presents:server:getPlayerName', function(name)
            playersProcessed = playersProcessed + 1
            
            table.insert(options, {
                title = name,
                description = string.format('Distance: %.1fm', dist),
                icon = 'user',
                onSelect = function()
                    GivePresentToPlayer(serverId)
                end
            })
            
            if playersProcessed >= totalPlayers then
                lib.registerContext({
                    id = 'give_present_menu',
                    title = '🎁 Give Present To',
                    options = options
                })
                
                lib.showContext('give_present_menu')
            end
        end, serverId)
    end
end


local function UnwrapPresent()
    local success = PlayWrappingAnimation()
    
    if success then
        TriggerServerEvent('rsg-presents:server:unwrapPresent')
    else
        lib.notify({
            title = 'Presents',
            description = Config.Messages.wrapped_cancel,
            type = 'error'
        })
    end
end


local function ViewGiftTag(tagInfo)
    if not tagInfo or not tagInfo.from or not tagInfo.to then
        lib.notify({
            title = 'Gift Tag',
            description = 'This gift tag is blank',
            type = 'info'
        })
        return
    end
    
    lib.alertDialog({
        header = Config.Messages.gift_tag_title,
        content = string.format(Config.Messages.gift_tag_message, tagInfo.to, tagInfo.from),
        centered = true,
        cancel = false,
        labels = {
            confirm = 'Close'
        }
    })
end


RegisterNetEvent('rsg-presents:client:useGiftTag', function(tagData)
    ViewGiftTag(tagData)
end)




RegisterNetEvent('rsg-presents:client:useEmptyBox', function()
    if isWrapping then return end
    OpenWrapMenu()
end)


RegisterNetEvent('rsg-presents:client:useWrappingPaper', function()
    if isWrapping then return end
    OpenWrapMenu()
end)


RegisterNetEvent('rsg-presents:client:useWrappedPresent', function(presentData)
    if isWrapping then return end
    
    lib.registerContext({
        id = 'present_options_menu',
        title = '🎁 Present Options',
        options = {
            {
                title = '🎁 Give to Someone',
                description = 'Give this present to a nearby player',
                icon = 'gift',
                onSelect = function()
                    OpenGiveMenu()
                end
            },
            {
                title = '📦 Unwrap Present',
                description = 'Open and see what\'s inside',
                icon = 'box-open',
                onSelect = function()
                    UnwrapPresent()
                end
            }
        }
    })
    
    lib.showContext('present_options_menu')
end)


RegisterNetEvent('rsg-presents:client:receivedPresent', function(senderName)
    lib.notify({
        title = '🎁 Present Received!',
        description = string.format(Config.Messages.received_present, senderName),
        type = 'success',
        duration = 7000
    })
    
    
    Wait(2000)
    lib.notify({
        title = '🏷️ Gift Tag',
        description = 'Check your gift tag for a special message!',
        type = 'info',
        duration = 5000
    })
end)


RegisterNetEvent('rsg-presents:client:gavePresent', function(receiverName)
    lib.notify({
        title = 'Present Given!',
        description = string.format(Config.Messages.gave_present, receiverName),
        type = 'success',
        duration = 5000
    })
end)


RegisterNetEvent('rsg-presents:client:unwrappedPresent', function(itemLabel, amount)
    lib.notify({
        title = 'Present Unwrapped!',
        description = string.format(Config.Messages.unwrapped, itemLabel, amount),
        type = 'success',
        duration = 5000
    })
end)


RegisterNetEvent('rsg-presents:client:wrapSuccess', function()
    lib.notify({
        title = 'Presents',
        description = Config.Messages.wrapped_success,
        type = 'success'
    })
end)


RegisterNetEvent('rsg-presents:client:showError', function(message)
    lib.notify({
        title = 'Presents',
        description = message,
        type = 'error'
    })
end)


RegisterCommand('wrappresent', function()
    if isWrapping then return end
    OpenWrapMenu()
end, false)