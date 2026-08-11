local VORPcore = exports.vorp_core:GetCore()

-- Runtime state only.
-- Because all chest definitions live in config.lua, no SQL/database is required.
local ChestState = {}

math.randomseed(os.time())

local function debugPrint(message)
    if Config.Debug then
        print(('[enchanted_acres_loot_chests] %s'):format(message))
    end
end

local function sendDiscordLog(src, chestId, chest, success, reason)
    if not Config.Webhook or not Config.Webhook.Enabled or Config.Webhook.URL == '' then
        return
    end

    local playerName = GetPlayerName(src) or ('Player %s'):format(src)
    local loot = {}

    for _, reward in ipairs(chest.loot or {}) do
        loot[#loot + 1] = ('`%s` x%s'):format(tostring(reward.item), tostring(reward.amount))
    end

    local payload = {
        username = Config.Webhook.Username or 'Enchanted Acres Loot Chests Logs',
        embeds = {{
            title = success and 'Chest Loot Received' or 'Chest Loot Failed',
            color = success and 5763719 or 15548997,
            fields = {
                { name = 'Player', value = ('%s\nServer ID: `%s`'):format(playerName, src), inline = true },
                { name = 'Chest', value = ('`%s`'):format(chestId), inline = true },
                { name = 'Result', value = success and 'SUCCESS' or 'FAILED', inline = true },
                { name = 'Required Key', value = ('`%s`'):format(tostring(chest.key)), inline = true },
                { name = 'Key Consumed', value = chest.consumeKey and 'Yes' or 'No', inline = true },
                { name = 'Reason', value = reason or 'All loot delivered.', inline = false },
                { name = 'Configured Loot', value = #loot > 0 and table.concat(loot, '\n') or 'No loot configured', inline = false }
            },
            footer = { text = 'Enchanted Acres Loot Chests' },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }}
    }

    if Config.Webhook.Avatar and Config.Webhook.Avatar ~= '' then
        payload.avatar_url = Config.Webhook.Avatar
    end

    PerformHttpRequest(Config.Webhook.URL, function(statusCode)
        if statusCode < 200 or statusCode >= 300 then
            debugPrint(('Discord webhook failed: HTTP %s'):format(statusCode))
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end

local function notify(src, message)
    TriggerClientEvent('enchanted_acres_loot_chests:notify', src, message)
end

local function isAdmin(src)
    if src == 0 then
        return true
    end

    return IsPlayerAceAllowed(src, Config.AdminAce)
end

local function getCurrentCoords(id, chest)
    local state = ChestState[id]
    if state and state.coords then
        return state.coords
    end
    return chest.coords
end

local function buildChestList()
    local result = {}

    for id, chest in pairs(Config.Chests) do
        local coords = getCurrentCoords(id, chest)
        result[#result + 1] = {
            id = id,
            x = coords.x,
            y = coords.y,
            z = coords.z,
            heading = coords.w,
            prop = chest.prop,
        }
    end

    return result
end

local function chooseMoveLocation(id, chest)
    if not chest.moveOnLoot and not chest.moveOnRespawn then return nil end

    local locations = chest.moveLocations
    if type(locations) ~= 'table' or #locations == 0 then return nil end

    local current = getCurrentCoords(id, chest)
    local candidates = {}

    for _, coords in ipairs(locations) do
        if coords and (
            math.abs(coords.x - current.x) > 0.01 or
            math.abs(coords.y - current.y) > 0.01 or
            math.abs(coords.z - current.z) > 0.01
        ) then
            candidates[#candidates + 1] = coords
        end
    end

    if #candidates == 0 then
        for _, coords in ipairs(locations) do
            if coords then candidates[#candidates + 1] = coords end
        end
    end

    if #candidates == 0 then return nil end
    return candidates[math.random(1, #candidates)]
end

local function syncAllChests(target)
    TriggerClientEvent('enchanted_acres_loot_chests:receiveChests', target or -1, buildChestList())
end

CreateThread(function()
    for id, chest in pairs(Config.Chests) do
        ChestState[id] = {
            opened = false,
            nextReset = 0,
            coords = chest.coords,
        }
    end

    Wait(1000)
    syncAllChests(-1)
end)

RegisterNetEvent('enchanted_acres_loot_chests:requestChests', function()
    syncAllChests(source)
end)

-- Return whether the chest is currently available.
local function isChestAvailable(id)
    local state = ChestState[id]
    if not state then
        return false
    end

    if not state.opened then
        return true
    end

    if state.nextReset > 0 and os.time() >= state.nextReset then
        state.opened = false
        state.nextReset = 0
        TriggerClientEvent('enchanted_acres_loot_chests:updateOpened', -1, id, false)
        return true
    end

    return false
end

-- Server-side inventory count.
local function getItemCount(src, item)
    local result = nil

    exports.vorp_inventory:getItemCount(src, function(count)
        result = tonumber(count) or 0
    end, item)

    -- VORP's callback is normally immediate, but allow a tick for compatibility.
    local timeout = GetGameTimer() + 1000
    while result == nil and GetGameTimer() < timeout do
        Wait(0)
    end

    return result or 0
end

local function canCarry(src, item, amount)
    local result = nil

    exports.vorp_inventory:canCarryItem(src, item, amount, function(canCarryResult)
        result = canCarryResult ~= false
    end)

    local timeout = GetGameTimer() + 1000
    while result == nil and GetGameTimer() < timeout do
        Wait(0)
    end

    return result == true
end

local function addItem(src, item, amount)
    local result = nil

    exports.vorp_inventory:addItem(src, item, amount, nil, function(success)
        result = success ~= false
    end)

    local timeout = GetGameTimer() + 1000
    while result == nil and GetGameTimer() < timeout do
        Wait(0)
    end

    return result == true
end

local function removeItem(src, item, amount)
    local result = nil

    exports.vorp_inventory:subItem(src, item, amount, nil, function(success)
        result = success ~= false
    end)

    local timeout = GetGameTimer() + 1000
    while result == nil and GetGameTimer() < timeout do
        Wait(0)
    end

    return result == true
end

local function giveLoot(src, chest)
    -- First check that all loot can fit.
    for _, reward in ipairs(chest.loot or {}) do
        local item = tostring(reward.item or '')
        local amount = tonumber(reward.amount or 0) or 0

        if item ~= '' and amount > 0 then
            if not canCarry(src, item, amount) then
                notify(src, Config.Notifications.InventoryFull)
                return false
            end
        end
    end

    -- Give all loot.
    for _, reward in ipairs(chest.loot or {}) do
        local item = tostring(reward.item or '')
        local amount = tonumber(reward.amount or 0) or 0

        if item ~= '' and amount > 0 then
            if not addItem(src, item, amount) then
                debugPrint(('Could not add %sx %s to player %s.'):format(amount, item, src))
                notify(src, Config.Notifications.InventoryFull)
                return false
            end
        end
    end

    return true
end

RegisterNetEvent('enchanted_acres_loot_chests:open', function(chestId)
    local src = source
    local chest = Config.Chests[chestId]

    if not chest then
        debugPrint(('Player %s attempted to open invalid chest %s.'):format(src, tostring(chestId)))
        return
    end

    local state = ChestState[chestId]

    if not state then
        state = {
            opened = false,
            nextReset = 0,
            coords = chest.coords,
        }
        ChestState[chestId] = state
    end

    if not isChestAvailable(chestId) then
        notify(src, Config.Notifications.Empty)
        sendDiscordLog(src, chestId, chest, false, 'Chest was empty or on cooldown.')
        return
    end

    -- Server-side distance validation.
    local ped = GetPlayerPed(src)
    if ped == 0 then
        return
    end

    local playerCoords = GetEntityCoords(ped)
    local currentCoords = getCurrentCoords(chestId, chest)
    local chestCoords = vector3(currentCoords.x, currentCoords.y, currentCoords.z)
    local distance = #(playerCoords - chestCoords)

    if distance > (Config.InteractDistance + 1.0) then
        debugPrint(('Rejected chest %s from player %s: distance %.2f'):format(
            chestId, src, distance
        ))
        sendDiscordLog(src, chestId, chest, false, ('Player was too far away: %.2f units.'):format(distance))
        return
    end

    local keyItem = chest.key

    if not keyItem or keyItem == '' then
        debugPrint(('Chest %s has no key configured.'):format(chestId))
        return
    end

    local keyCount = getItemCount(src, keyItem)

    if keyCount < 1 then
        notify(src, Config.Notifications.NeedKey)
        sendDiscordLog(src, chestId, chest, false, 'Player did not have the required key.')
        return
    end

    -- Lock before giving rewards to prevent double-use.
    state.opened = true

    if chest.consumeKey then
        if not removeItem(src, keyItem, 1) then
            state.opened = false
            notify(src, Config.Notifications.NeedKey)
            sendDiscordLog(src, chestId, chest, false, 'The required key could not be removed.')
            return
        end
    end

    if not giveLoot(src, chest) then
        state.opened = false

        if chest.consumeKey then
            addItem(src, keyItem, 1)
        end

        sendDiscordLog(src, chestId, chest, false, 'Loot could not be delivered. Chest unlocked and consumed key returned when applicable.')
        return
    end

    -- Move immediately only when explicitly configured to do so.
    local moveCoords = chest.moveOnLoot and chooseMoveLocation(chestId, chest) or nil

    if moveCoords then
        state.coords = moveCoords
        state.opened = false
        state.nextReset = 0

        TriggerClientEvent(
            'enchanted_acres_loot_chests:updateLocation',
            -1,
            chestId,
            moveCoords.x,
            moveCoords.y,
            moveCoords.z,
            moveCoords.w,
            false
        )

        notify(src, Config.Notifications.Opened .. ' The chest has moved to a new location.')
        sendDiscordLog(
            src,
            chestId,
            chest,
            true,
            ('All configured loot was successfully delivered. Chest moved to %.2f, %.2f, %.2f.'):format(
                moveCoords.x, moveCoords.y, moveCoords.z
            )
        )

        debugPrint(('Player %s opened chest %s. It moved to %.2f, %.2f, %.2f.'):format(
            src, chestId, moveCoords.x, moveCoords.y, moveCoords.z
        ))
        return
    end

    -- Normal respawn behavior. If moveOnRespawn is enabled, the chest changes
    -- to another preset location when the respawn timer finishes.
    local respawnMinutes = tonumber(chest.respawnMinutes or 0) or 0

    if respawnMinutes > 0 then
        state.nextReset = os.time() + (respawnMinutes * 60)

        SetTimeout(respawnMinutes * 60 * 1000, function()
            if Config.Chests[chestId] and ChestState[chestId] then
                local respawnState = ChestState[chestId]
                local respawnMove = chest.moveOnRespawn and chooseMoveLocation(chestId, chest) or nil

                if respawnMove then
                    respawnState.coords = respawnMove
                    respawnState.opened = false
                    respawnState.nextReset = 0

                    TriggerClientEvent(
                        'enchanted_acres_loot_chests:updateLocation',
                        -1,
                        chestId,
                        respawnMove.x,
                        respawnMove.y,
                        respawnMove.z,
                        respawnMove.w,
                        false
                    )

                    debugPrint(('Chest %s respawned and moved to %.2f, %.2f, %.2f.'):format(
                        chestId, respawnMove.x, respawnMove.y, respawnMove.z
                    ))
                else
                    respawnState.opened = false
                    respawnState.nextReset = 0
                    TriggerClientEvent('enchanted_acres_loot_chests:updateOpened', -1, chestId, false)
                    debugPrint(('Chest %s has respawned.'):format(chestId))
                end
            end
        end)
    else
        state.nextReset = 0
    end

    local currentCoords = getCurrentCoords(chestId, chest)
    TriggerClientEvent('enchanted_acres_loot_chests:updateOpened', -1, chestId, true)
    TriggerClientEvent(
        'enchanted_acres_loot_chests:playOpen',
        src,
        currentCoords.x,
        currentCoords.y,
        currentCoords.z
    )

    notify(src, Config.Notifications.Opened)
    sendDiscordLog(src, chestId, chest, true, 'All configured loot was successfully delivered.')
    debugPrint(('Player %s opened chest %s.'):format(src, chestId))
end)

--========================================================--
-- ADMIN COMMANDS
--========================================================--

RegisterCommand('chestreset', function(src, args)
    if not Config.EnableAdminCommands then
        return
    end

    if not isAdmin(src) then
        if src ~= 0 then
            notify(src, Config.Notifications.NoPermission)
        end
        return
    end

    local chestId = args[1]

    if not chestId or not Config.Chests[chestId] then
        if src ~= 0 then
            notify(src, 'Invalid chest ID.')
        end
        return
    end

    local currentCoords = getCurrentCoords(chestId, Config.Chests[chestId])

    ChestState[chestId] = {
        opened = false,
        nextReset = 0,
        coords = currentCoords,
    }

    TriggerClientEvent(
        'enchanted_acres_loot_chests:updateLocation',
        -1,
        chestId,
        currentCoords.x,
        currentCoords.y,
        currentCoords.z,
        currentCoords.w,
        false
    )

    if src ~= 0 then
        notify(src, ('Chest "%s" has been reset.'):format(chestId))
    end
end, false)

RegisterCommand('chestreload', function(src)
    if not Config.EnableAdminCommands then
        return
    end

    if not isAdmin(src) then
        if src ~= 0 then
            notify(src, Config.Notifications.NoPermission)
        end
        return
    end

    ChestState = {}

    for id, chest in pairs(Config.Chests) do
        ChestState[id] = {
            opened = false,
            nextReset = 0,
            coords = chest.coords,
        }
    end

    syncAllChests(-1)

    if src ~= 0 then
        notify(src, 'Chest configuration reloaded.')
    end
end, false)
