local ChestObjects = {}
local Chests = {}

local function debugPrint(message)
    if Config.Debug then
        print(('[enchanted_acres_loot_chests] %s'):format(message))
    end
end

local function loadModel(model)
    local hash = joaat(model)

    if not IsModelValid(hash) then
        debugPrint(('Invalid chest prop: %s'):format(model))
        return nil
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 10000

    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
    end

    if not HasModelLoaded(hash) then
        debugPrint(('Could not load chest prop: %s'):format(model))
        return nil
    end

    return hash
end

local function deleteChestObject(id)
    local object = ChestObjects[id]

    if object and DoesEntityExist(object) then
        SetEntityAsMissionEntity(object, true, true)
        DeleteObject(object)
    end

    ChestObjects[id] = nil
end

local function spawnChest(chest)
    deleteChestObject(chest.id)

    local hash = loadModel(chest.prop or 'p_chest01x')

    if not hash then
        return
    end

    local object = CreateObject(
        hash,
        chest.x,
        chest.y,
        chest.z,
        false,
        false,
        false
    )

    if not DoesEntityExist(object) then
        debugPrint(('Could not create chest object: %s'):format(chest.id))
        SetModelAsNoLongerNeeded(hash)
        return
    end

    SetEntityHeading(object, chest.heading or 0.0)
    FreezeEntityPosition(object, true)
    SetEntityAsMissionEntity(object, true, true)

    ChestObjects[chest.id] = object
    Chests[chest.id] = chest

    SetModelAsNoLongerNeeded(hash)
end

local function drawText3D(x, y, z, text)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(x, y, z)

    if not onScreen then
        return
    end

    SetTextScale(0.30, 0.30)
    SetTextFontForCurrentCommand(1)
    SetTextColor(255, 255, 255, 215)
    SetTextCentre(true)

    DisplayText(
        CreateVarString(10, 'LITERAL_STRING', text),
        screenX,
        screenY
    )
end

RegisterNetEvent('enchanted_acres_loot_chests:receiveChests', function(chests)
    for id in pairs(ChestObjects) do
        deleteChestObject(id)
    end

    Chests = {}

    for _, chest in ipairs(chests or {}) do
        spawnChest(chest)
    end
end)

RegisterNetEvent('enchanted_acres_loot_chests:updateOpened', function(chestId, opened)
    if Chests[chestId] then
        Chests[chestId].opened = opened
    end
end)

RegisterNetEvent('enchanted_acres_loot_chests:notify', function(message)
    TriggerEvent('vorp:TipRight', message, 4000)
end)

RegisterNetEvent('enchanted_acres_loot_chests:playOpen', function()
    -- Placeholder for an opening animation/sound.
    -- The physical prop remains in the world.
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('enchanted_acres_loot_chests:requestChests')
end)

CreateThread(function()
    while true do
        local sleep = Config.ClientCheckMs

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        local closestChest = nil
        local closestDistance = Config.InteractDistance

        for id, chest in pairs(Chests) do
            local chestCoords = vector3(chest.x, chest.y, chest.z)
            local distance = #(playerCoords - chestCoords)

            if distance <= closestDistance then
                closestDistance = distance
                closestChest = chest
            end
        end

        if closestChest then
            sleep = 0

            local prompt

            if closestChest.opened then
                prompt = 'Chest Empty'
            else
                prompt = '[E] Open Chest'
            end

            drawText3D(
                closestChest.x,
                closestChest.y,
                closestChest.z + 0.8,
                prompt
            )

            if not closestChest.opened
                and IsControlJustReleased(0, Config.InteractKey) then

                TriggerServerEvent(
                    'enchanted_acres_loot_chests:open',
                    closestChest.id
                )

                Wait(1000)
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    for id in pairs(ChestObjects) do
        deleteChestObject(id)
    end
end)
