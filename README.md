# Enchanted Acres Configurable Chest System v2

A Fully Customizable Loot Chest System For VORP 
Every chest is configured directly in `config.lua`.

## No SQL Required

Chest locations, props, keys, loot, key consumption, and respawn timers are all in `config.lua`.

## Requirements

- vorp_core
- vorp_inventory

## Installation

Put the folder in your resources directory:

```text
resources/enchanted_acres_loot_chests
```

Then add:

```cfg
ensure vorp_core
ensure vorp_inventory
ensure enchanted_acres_loot_chests
```

If your VORP resources are already started elsewhere, keep your existing order.

## Configuring a Chest

Use a Vector4:

```lua
['Chest_1'] = {
    coords = vector4(-278.45, 804.12, 119.38, 92.50),
    prop = 'p_chest01x', -- You can Change the Prop for Each Chest
    key = 'Chest1_key', -- You can Configure any item in your Database to use as a Key
    consumeKey = true, -- Set to False if you wish to let the player keep the Key, This is also Configureable per chest

    loot = {                                      -- You can Change the Loot Table Per Chest Just make sure the "item" matches the item name in your Database
        { item = 'Bread', amount = 2 },
        { item = 'revival_syringe', amount = 1 },
        { item = 'goldnugget', amount = 3 },
    },

    respawnMinutes = 120, -- This is in Minutes   ("0" ) 
},
```

Vector4 is:

```text
X, Y, Z, Heading
```

## Different Key Per Chest

Every chest has its own `key`: Which you can configure any item in your Vorp Inventory as a Key Item

```lua
key = 'Chest1_key'
```

Another chest:

```lua
key = 'Chest2_key'
```

Another:

```lua
key = 'Chest3_key'
```

## Different Loot Per Chest

Every chest has its own `loot` table: You can Fully Configure the Loot Table for each Chest

```lua
loot = {
    { item = 'bread', amount = 2 },
    { item = 'goldnugget', amount = 5 },
},
```

There is no shared default loot table.

## Consume Key

Remove one key after a successful open:

```lua
consumeKey = true
```

Keep the key:

```lua
consumeKey = false
```

## Respawn

Chest never automatically respawns:

```lua
respawnMinutes = 0
```

Respawn after one hour:

```lua
respawnMinutes = 60
```

Respawn after 24 hours:

```lua
respawnMinutes = 1440
```

Respawn after 7 days:

```lua
respawnMinutes = 10080
```

## Adding More Chests

Simply add another entry:

```lua
['graveyard_cache'] = {
    coords = vector4(123.45, 456.78, 78.90, 180.0),
    prop = 'p_chest01x',
    key = 'graveyard_key',
    consumeKey = true,

    loot = {
        { item = 'bones', amount = 5 },
        { item = 'goldnugget', amount = 2 },
    },

    respawnMinutes = 720,
},
```

You can add as many as you want.

## Admin Commands

Reset one chest:

```text
/chestreset bloodmoon_cache
```

Reload all configured chest props:

```text
/chestreload
```

The admin ACE is:

```cfg
add_ace group.admin enchantedacres.chestadmin allow
```

Change `Config.AdminAce` if your server uses a different permission system.

## Important

The item names in `key` and `loot` must match the item names registered in your VORP inventory.

## Current Behavior

- Chest props spawn automatically.
- Players see `[E] Open Chest` nearby.
- The server checks the player is actually near the chest.
- The server checks the configured key.
- The key can optionally be consumed.
- Loot is checked against inventory capacity before rewards are given.
- The chest becomes empty after successful looting.
- A configured respawn timer can make it available again.
- All chest definitions are controlled from `config.lua`.

## Discord Webhook

Configure the Discord webhook in `config.lua`:

```lua
Config.Webhook = {
    Enabled = true,
    URL = 'YOUR_DISCORD_WEBHOOK_URL',
    Username = 'Enchanted Acres Loot Chests Logs',
    Avatar = '',
    Color = 3447003,
}
```

Logs include player name, server ID, chest ID, required key, key consumption, configured loot, and whether loot was successfully received. Failed attempts include the reason.
