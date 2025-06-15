local Config = lib.require('config')

local PC_PEDs = {}
local initZones = {}

local function targetLocalEntity(entity, options, distance)
    for _, option in ipairs(options) do
        option.distance = distance
        option.onSelect = option.action
        option.action = nil
    end
    exports.ox_target:addLocalEntity(entity, options)
end

local function InputWithdraw(amount)
    local response = lib.inputDialog('Withdrawal', {
        {
            type = 'number',
            label = 'How much do you want?',
            icon = 'fa-solid fa-hand-pointer',
            description = ('Pick an amount to withdraw. You have $%s available'):format(amount),
            required = true
        },
        {
            type = 'select',
            label = 'Cash or Bank?',
            required = true,
            icon = 'fa-solid fa-wallet',
            options = {
                {value = 'cash', label = 'Cash'},
                {value = 'bank', label = 'Bank'}
            }
        }
    })

    if not response then return end

    local inputAmt = response[1]
    local accountType = response[2]

    if inputAmt < 1 then
        return DoNotification('Amount needs to be greater than 0.', 'Error in Transaction')
    end

    if inputAmt > amount then
        return DoNotification('Insufficient funds in your paycheck.', 'Error in Transaction')
    end

    local success = lib.callback.await('randol_paycheck:server:withdraw', false, inputAmt, accountType)
    if success then
        lib.playAnim(cache.ped, 'friends@laf@ig_5', 'nephew', 8.0, -8.0, -1, 49, 0, false, false, false)
        Wait(2000)
        ClearPedTasks(cache.ped)
    end
end

local function viewPaycheck()
    local paycheckAmount = lib.callback.await('randol_paycheck:server:checkPaycheck', true)
    lib.registerContext({
        id = 'view_pc',
        title = ('You have $%s'):format(paycheckAmount),
        options = {
            {
                title = 'Withdraw Paycheck',
                description = 'Turn your paycheck into cash, or deposit it into your bank',
                icon = 'fa-solid fa-money-check-dollar',
                onSelect = function() InputWithdraw(tonumber(paycheckAmount)) end
            }
        }
    })
    lib.showContext('view_pc')
end

local function removePedAtLocation(locationIndex)
    local ped = PC_PEDs[locationIndex]
    if not ped or not DoesEntityExist(ped) then return end
    exports.ox_target:removeLocalEntity(ped, 'View Paycheck')
    DeleteEntity(ped)
    PC_PEDs[locationIndex] = nil
end

local function spawnPedAtLocation(locationIndex, loc)
    lib.requestModel(loc.model, 10000)
    local ped = CreatePed(0, loc.model, loc.coords, false, false)
    SetEntityAsMissionEntity(ped)
    SetPedFleeAttributes(ped, 0, 0)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetPedDefaultComponentVariation(ped)
    SetModelAsNoLongerNeeded(loc.model)
    lib.playAnim(ped, 'mp_prison_break', 'hack_loop', 8.0, -8.0, -1, 1, 0.0, 0, 0, 0)
    targetLocalEntity(ped, {
        {
            icon = 'fa-solid fa-money-check-dollar',
            label = 'View Paycheck',
            action = function()
                lib.playAnim(cache.ped, 'friends@laf@ig_5', 'nephew', 8.0, -8.0, -1, 49, 0, false, false, false)
                if lib.progressCircle({
                    duration = 2500,
                    position = 'bottom',
                    label = 'Checking account...',
                    useWhileDead = true,
                    canCancel = false,
                    disable = { move = true, car = true, mouse = false, combat = true },
                }) then
                    ClearPedTasks(cache.ped)
                    viewPaycheck()
                end
            end
        }
    }, 4.5)
    PC_PEDs[locationIndex] = ped
end

local function paycheckZone()
    for i, loc in ipairs(Config.locations) do
        local zone = lib.points.new({
            coords = loc.coords.xyz,
            distance = 50,
            onEnter = function() spawnPedAtLocation(i, loc) end,
            onExit = function() removePedAtLocation(i) end,
        })
        initZones[i] = zone
    end
end

function OnPlayerLoaded()
    paycheckZone()
end

function OnPlayerUnload()
    for _, zone in pairs(initZones) do
        zone:remove()
    end
    initZones = {}

    for i in pairs(PC_PEDs) do
        removePedAtLocation(i)
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, zone in pairs(initZones) do
            zone:remove()
        end
        initZones = {}

        for i in pairs(PC_PEDs) do
            removePedAtLocation(i)
        end
    end
end)