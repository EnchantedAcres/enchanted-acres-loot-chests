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
--
-- respawnMinutes = 0 means the chest never automatically resets.
--========================================================--

Config.Chests = {

    -- Example Chest #1
    ['Chest_1'] = {
        coords = vector4(-278.45, 804.12, 119.38, 92.50),

        -- Chest prop
        prop = 'p_chest01x',

        -- Item required to open this chest
        key = 'Chest1_key',

        -- Remove one key when the chest is opened?
        consumeKey = true,

        -- Loot ONLY for this chest
        loot = {
            { item = 'bread', amount = 2 },
            { item = 'revival_syringe', amount = 1 },
            { item = 'goldnugget', amount = 3 },
        },

        -- Minutes before this chest can be looted again.
        -- 0 = one-time chest until the resource/server is restarted.
        respawnMinutes = 1440, -- 24 hours
    },

    -- Example Chest #2
    ['Chest_2'] = {
        coords = vector4(-1123.72, 489.64, 93.18, 180.00),

        prop = 'p_chest01x',

        key = 'Chest2_key',

        consumeKey = false,

        loot = {
            { item = 'red_sage', amount = 5 },
            { item = 'feather', amount = 3 },
            { item = 'magic_powder', amount = 2 },
        },

        respawnMinutes = 60,
    },

    -- Example Chest #3
    ['Chest_3'] = {
        coords = vector4(-3572.17, -3573.81, 47.92, 270.00),

        prop = 'p_chest01x',

        key = 'Chest3_key',

        consumeKey = true,

        loot = {
            { item = 'ammo_revolver', amount = 20 },
            { item = 'bread', amount = 5 },
            { item = 'water', amount = 5 },
        },

        respawnMinutes = 0,
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
