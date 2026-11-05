local ESX = exports['es_extended']:getSharedObject()

-- Track how many spare tires each vehicle trunk currently contains and how many
-- old (flat) tires the player has stored back into it. Keyed by vehicle netId.
local TrunkState = {}

local function ensureTrunk(netId)
    if not TrunkState[netId] then
        TrunkState[netId] = {
            spares = Config.MaxTrunkSpares,
            stored = 0,
        }
    end
    return TrunkState[netId]
end

-- Player asks the server how many spare tires are available in a truck trunk.
lib.callback.register('realistic_tires:getTrunkSpares', function(source, netId)
    ensureTrunk(netId)
    return TrunkState[netId].spares
end)

-- Player completed extracting one spare tire from a trunk.
lib.callback.register('realistic_tires:extractSpare', function(source, netId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    local state = ensureTrunk(netId)
    if state.spares <= 0 then return false end

    local item = xPlayer.getInventoryItem(Config.TireItem)
    if not item then return false end
    if item.count >= 50 then return 'no_room' end

    state.spares = state.spares - 1
    xPlayer.addInventoryItem(Config.TireItem, 1)
    return true
end)

-- Player stored an old (flat) tire back into the trunk after the replacement.
lib.callback.register('realistic_tires:storeTire', function(source, netId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    -- Consume the old flat tire from the player's inventory.
    if xPlayer.removeInventoryItem(Config.TireItem, 1) then
        local state = ensureTrunk(netId)
        state.stored = state.stored + 1
        -- An old tire in the trunk slowly turns back into a usable spare over time.
        if state.stored >= Config.MaxTrunkSpares then
            state.stored = 0
            state.spares = math.min(state.spares + 1, Config.MaxTrunkSpares)
        end
    end
    return true
end)

-- Player dropped a tire on the ground (removes it from inventory).
lib.callback.register('realistic_tires:dropTire', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    if xPlayer.removeInventoryItem(Config.TireItem, 1) then
        return true
    end
    return false
end)

-- Player picked a dropped tire back up from the ground (adds it back to inventory).
lib.callback.register('realistic_tires:addTireToPlayer', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    if xPlayer.addInventoryItem(Config.TireItem, 1) then
        return true
    end
    return false
end)
