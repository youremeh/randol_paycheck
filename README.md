## Requirements

[ox_lib](https://github.com/overextended/ox_lib/releases)
[lb_phone](https://store.lbscripts.com/package/5356987) - Can be disabled/removed, only required for phone notification

QBOX Install - Navigate to this line: https://github.com/Qbox-project/qbx_core/blob/main/config/server.lua#L131 

```lua
sendPaycheck = function (player, payment)
    exports.randol_paycheck:AddToPaycheck(player.PlayerData.citizenid, payment)
    Notify(player.PlayerData.source, locale('info.received_paycheck', payment))
end,
```

# Export

The export below can be used to insert money into the paycheck rather than adding it into a player's bank/cash. You must implement these yourself.

Example: QBCore

```lua
local Player = QBCore.Functions.GetPlayer(source)
local amount = 450
exports.randol_paycheck:AddToPaycheck(Player.PlayerData.citizenid, amount)
```

Example: ESX

```lua
local xPlayer = ESX.GetPlayerFromId(source)
local amount = 450
exports.randol_paycheck:AddToPaycheck(xPlayer.identifier, amount)
```
