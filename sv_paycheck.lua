local function AddToPaycheck(cid, amount)
    if not cid or not amount then return end
    MySQL.update.await([[INSERT INTO paychecks (citizenid, amount) VALUES (?, ?) ON DUPLICATE KEY UPDATE amount = amount + ?]], {cid, amount, amount})
    local result = MySQL.single.await('SELECT amount FROM paychecks WHERE citizenid = ?', {cid})
    if not result then return end
    local src = GetSourceFromIdentifier(cid)
    if src then DoNotification(src, 'You received your paycheck of $'..amount..', bringing your total to $'..result.amount, 'New Deposit') end
end
exports('AddToPaycheck', AddToPaycheck)

lib.callback.register('randol_paycheck:server:withdraw', function(source, amount, accountType)
    local src = source
    local Player = GetPlayer(src)
    local cid = GetPlyIdentifier(Player)
    local result = MySQL.rawExecute.await('SELECT amount FROM paychecks WHERE citizenid = ?', {cid})
    if not result[1].amount then return false end
    if tonumber(result[1].amount) < amount then
        DoNotification(src, 'Insufficient funds in your paycheck.', 'Error in Transaction')
        return false
    end
    result[1].amount -= amount
    MySQL.update.await('UPDATE paychecks SET amount = ? WHERE citizenid = ?', {result[1].amount, cid})
    if accountType == 'cash' then
        AddMoney(Player, 'cash', amount)
        DoNotification(src, ('You withdrew $%s from your paycheck.'):format(amount), 'New Withdraw')
    else
        AddMoney(Player, 'bank', amount)
        DoNotification(src, ('You deposited $%s from your paycheck into your bank account.'):format(amount), 'New Withdraw')
    end
    return true
end)

lib.callback.register('randol_paycheck:server:checkPaycheck', function(source)
    local src = source
    local Player = GetPlayer(src)
    local cid = GetPlyIdentifier(Player)
    local result = MySQL.query.await('SELECT * FROM paychecks WHERE citizenid = ?', {cid})
    local paycheckAmount = 0
    if result[1] then
        paycheckAmount = result[1].amount
    else
        MySQL.insert.await('INSERT INTO paychecks (citizenid, amount) VALUE (?, ?)', {cid, 0})
    end
    return paycheckAmount
end)

AddEventHandler('onServerResourceStart', function(resource)
    if resource == GetCurrentResourceName() then MySQL.query([=[CREATE TABLE IF NOT EXISTS paychecks ( citizenid varchar(100) NOT NULL, amount varchar(50) DEFAULT NULL, PRIMARY KEY (citizenid));]=]) end
end)