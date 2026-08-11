Config = {}

--========================================================--
-- ENCHANTED ACRES CHEST SYSTEM
-- Everything below can be configured from this file.
--========================================================--

Config.Debug = false

--========================================================--
-- DISCORD WEBHOOK
--========================================================--

Config.Webhook = {
    Enabled = true,
    URL = '', -- Paste your Discord webhook URL here
    Username = 'Enchanted Acres Loot Chests Logs',
    Avatar = '',
    Color = 3447003,
}


-- Interaction distance
Config.InteractDistance = 2.0

-- E key: 0xCEFD9220
Config.InteractKey = 0xCEFD9220

-- How often the client checks for nearby chests.
Config.ClientCheckMs = 250

--========================================================--
-- NOTIFICATIONS
--========================================================--

Config.Notifications = {
    NeedKey       = 'You need the correct key to open this chest.',
    Empty         = 'This chest is empty.',
    Opened        = 'You opened the chest.',
    InventoryFull = 'You do not have enough room for all of the loot.',
    NoPermission  = 'You do not have permission to use this command.',
}

--========================================================--
-- CHESTS
--
-- coords = vector4(x, y, z, heading)
--
-- Each chest can have:
--   coords
--   prop
--   key
--   consumeKey
--   loot
--   respawnMinutes
--   moveOnLoot
--   moveOnRespawn
--   moveLocations
--
-- Loot amounts can be fixed or randomized.
-- Fixed:    { item = 'bread', amount = 5 }
-- Random:   { item = 'bread', amount = { min = 2, max = 8 } }
-- Each loot entry rolls independently every time the chest is successfully opened.
--
-- moveOnLoot = true makes the chest move immediately after a successful loot.
-- moveOnRespawn = true makes the chest move when its respawn timer finishes.
-- Set moveOnLoot = false and moveOnRespawn = true to move only on respawn.
-- moveLocations is a preset list of Vector4 locations the chest can move to.
-- The current location is excluded whenever another location is available.
--
-- respawnMinutes = 0 means the chest never automatically resets.
--========================================================--

Config.Chests = {

    -- Example Chest #1
    ['Chest_1'] = {
        coords = vector4(-278.45, 804.12, 119.38, 92.50),

        -- Move this chest to another preset location after it is found.
        moveOnLoot = false,

        -- Move this chest when its respawn timer finishes.
        moveOnRespawn = true,

        -- Preset locations for this chest.
        moveLocations = {
            vector4(-300.25, 820.10, 119.40, 15.00),
            vector4(-245.80, 790.65, 119.25, 180.00),
            vector4(-325.10, 775.40, 120.05, 270.00),
            vector4(-260.45, 850.20, 118.90, 90.00),
        },

        -- Chest prop
        prop = 'p_chest01x',

        -- Item required to open this chest
        key = 'Chest1_key',

        -- Remove one key when the chest is opened?
        consumeKey = true,

        -- Loot ONLY for this chest
        loot = {
            { item = 'revival_syringe', amount = { min = 1, max = 2 } },
            { item = 'goldnugget', amount = { min = 1, max = 5 } },
        },

        -- Minutes before this chest can be looted again.
        -- 0 = one-time chest until the resource/server is restarted.
        respawnMinutes = 120, -- 2 hours
    },

    -- Example Chest #2
    ['Chest_2'] = {
        coords = vector4(-1123.72, 489.64, 93.18, 180.00),

        prop = 'p_chest01x',

        key = 'Chest2_key',

        consumeKey = false,

        loot = {
            { item = 'red_sage', amount = { min = 2, max = 8 } },
            { item = 'magic_powder', amount = { min = 1, max = 4 } },
        },

        respawnMinutes = 60,
    },

    -- Add as many chests as you want:
    --
    -- ['my_new_chest'] = {
    --     coords = vector4(x, y, z, heading),
    --     prop = 'p_chest01x',
    --     key = 'my_special_key',
    --     consumeKey = true,
    --     loot = {
    --         { item = 'item_name', amount = 1 },
    --         { item = 'another_item', amount = 5 },
    --     },
    --     respawnMinutes = 120,
    -- },
}

--========================================================--
-- ADMIN COMMANDS
--========================================================--

Config.AdminAce = 'enchantedacres.chestadmin'

-- Optional helper commands.
-- /chestreset <chestId>
-- /chestreload
Config.EnableAdminCommands = true
