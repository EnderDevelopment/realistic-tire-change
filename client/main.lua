local ESX = exports['es_extended']:getSharedObject()
local Animations = require 'client.animations'

local Targeting = {
    currentVehicle = nil,
    currentKey = nil,
}

local DroppedTires = {} -- prop entity -> true (registered for pickup)

-- Forward declaration so dropTire (defined earlier) can call it.
local registerDropPickup

-- -------------------------------------------------------------
-- Helpers
-- -------------------------------------------------------------

local function isTruck(model)
    for _, name in ipairs(Config.Trucks) do
        if GetHashKey(name) == model then
            return true
        end
    end
    return false
end

local function getBurstWheels(veh)
    local bursts = {}
    for i = 0, 3 do
        if GetVehicleWheelIsTyreBurst(veh, i, false) then
            bursts[#bursts + 1] = i
        end
    end
    return bursts
end

local function getNearestVehicle()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local veh = nil
    local closest = Config.InteractDistance

    for _, v in ipairs(GetGamePool('CVehicle')) do
        local dist = #(coords - GetEntityCoords(v))
        if dist < closest then
            closest = dist
            veh = v
        end
    end
    return veh
end

local function hasTireItem()
    if exports.ox_inventory then
        local count = exports.ox_inventory:GetItemCount(Config.TireItem)
        if count and count > 0 then return true end
    end
    local data = ESX.GetPlayerData()
    local items = data.inventory or data.items or {}
    for _, item in ipairs(items) do
        if item.name == Config.TireItem and item.count and item.count > 0 then
            return true
        end
    end
    return false
end

-- -------------------------------------------------------------
-- Trunk interaction (extract spare)
-- -------------------------------------------------------------

local function extractSpare(veh)
    local netId = NetworkGetNetworkIdFromEntity(veh)

    if hasTireItem() then
        lib.notify({ title = Config.Locale['already_have_tire'], type = 'error' })
        return
    end

    local spares = lib.callback.await('realistic_tires:getTrunkSpares', false, netId)
    if not spares or spares <= 0 then
        lib.notify({ title = Config.Locale['extract_no_spare'], type = 'error' })
        return
    end

    -- Walk to the back of the vehicle (the trunk).
    local ped = PlayerPedId()
    local back = GetOffsetFromEntityInWorldCoords(veh, 0.0, -2.4, 0.0)
    TaskGoToCoordAnyMeans(ped, back.x, back.y, back.z, 1.0, 0, false, 786603, 0.0)
    Wait(1200)

    Animations.WorkAtWheel()
    local ok = Animations.Progress({
        duration = Config.Progress.ExtractSpare,
        label = Config.Locale['extract_spare_start'],
        anim = { dict = 'missmechanic', clip = 'work2_base', flag = 1 },
    })
    Animations.Clear()

    if not ok then
        lib.notify({ title = Config.Locale['cancel'], type = 'error' })
        return
    end

    local result = lib.callback.await('realistic_tires:extractSpare', false, netId)
    if result == true then
        Animations.CarryTire()
        lib.notify({ title = Config.Locale['extract_spare_end'], type = 'success' })
        Wait(800)
        Animations.Clear()
    elseif result == 'no_room' then
        lib.notify({ title = Config.Locale['no_room'], type = 'error' })
    else
        lib.notify({ title = Config.Locale['extract_no_spare'], type = 'error' })
    end
end

-- -------------------------------------------------------------
-- Wheel replacement
-- -------------------------------------------------------------

local function boltProgress(duration, label)
    Animations.WorkAtWheel()
    local ok = Animations.Progress({
        duration = duration,
        label = label,
        anim = { dict = 'missmechanic', clip = 'work2_base', flag = 1 },
    })
    Wait(Config.StepDelay)
    return ok
end

local function replaceTire(veh, wheelIndex)
    if not hasTireItem() then
        lib.notify({ title = Config.Locale['need_tire'], type = 'error' })
        return
    end

    if not GetVehicleWheelIsTyreBurst(veh, wheelIndex, false) then
        lib.notify({ title = Config.Locale['no_burst_tire'], type = 'error' })
        return
    end

    local ped = PlayerPedId()

    -- Step 1: walk to the side of the wheel and kneel down.
    local bone = GetEntityBoneIndexByName(veh, Config.WheelBones[wheelIndex])
    if bone == -1 then bone = 0 end
    local side = GetOffsetFromEntityInWorldCoords(veh, Config.WheelKneelOffset, 0.0, 0.0)
    TaskGoToCoordAnyMeans(ped, side.x, side.y, side.z, 1.0, 0, false, 786603, 0.0)
    Wait(1200)

    Animations.KneelByWheel()
    local ok = Animations.Progress({
        duration = Config.Progress.ApproachWheel,
        label = Config.Locale['approach_wheel'],
        anim = { dict = 'missmechanic', clip = 'work2_base', flag = 1 },
    })
    Animations.Clear()

    if not ok then
        lib.notify({ title = Config.Locale['cancel'], type = 'error' })
        return
    end

    -- Step 2: loosen every bolt, one at a time, realistically.
    for bolt = 1, Config.BoltsPerWheel do
        ok = boltProgress(Config.Progress.UnscrewBolt, Config.Locale['unscrew_bolt']:format(bolt, Config.BoltsPerWheel))
        Animations.Clear()
        if not ok then
            lib.notify({ title = Config.Locale['cancel'], type = 'error' })
            return
        end
    end

    -- Step 3: pull the burst/old wheel off the hub.
    Animations.AttachTire(ped, 57005)
    Animations.WorkAtWheel()
    ok = Animations.Progress({
        duration = Config.Progress.RemoveWheel,
        label = Config.Locale['remove_wheel'],
        anim = { dict = 'missmechanic', clip = 'work2_base', flag = 1 },
    })
    Animations.ClearProps()
    Animations.Clear()
    if not ok then
        lib.notify({ title = Config.Locale['cancel'], type = 'error' })
        return
    end

    -- Step 4: carry the old tire to the truck trunk (consumes the old item).
    Animations.CarryTire()
    ok = Animations.Progress({
        duration = Config.Progress.CarryOldToTrunk,
        label = Config.Locale['carry_old_to_trunk'],
        anim = { dict = 'anim@heists@box_carry@', clip = 'idle', flag = 49 },
    })
    Animations.Clear()
    if not ok then
        lib.notify({ title = Config.Locale['cancel'], type = 'error' })
        return
    end
    lib.callback.await('realistic_tires:storeTire', false, NetworkGetNetworkIdFromEntity(veh))

    -- Step 5: mount the new wheel on the hub.
    Animations.WorkAtWheel()
    ok = Animations.Progress({
        duration = Config.Progress.InstallWheel,
        label = Config.Locale['install_wheel'],
        anim = { dict = 'missmechanic', clip = 'work2_base', flag = 1 },
    })
    Animations.Clear()
    if not ok then
        lib.notify({ title = Config.Locale['cancel'], type = 'error' })
        return
    end

    -- Step 6: tighten every bolt, one at a time.
    for bolt = 1, Config.BoltsPerWheel do
        ok = boltProgress(Config.Progress.TightenBolt, Config.Locale['tighten_bolt']:format(bolt, Config.BoltsPerWheel))
        Animations.Clear()
        if not ok then
            lib.notify({ title = Config.Locale['cancel'], type = 'error' })
            return
        end
    end

    -- The wheel is fixed.
    SetVehicleTyreBurst(veh, wheelIndex, false, 1000.0)
    lib.notify({ title = Config.Locale['done'], type = 'success' })
end

-- -------------------------------------------------------------
-- Dropping / throwing a tire with E
-- -------------------------------------------------------------

local dropping = false

local function dropTire()
    if dropping then return end
    if not hasTireItem() then return end
    if IsPedInAnyVehicle(PlayerPedId(), false) then return end

    dropping = true
    Animations.TossTire()
    local ok = Animations.Progress({
        duration = Config.Progress.DropTire,
        label = Config.Locale['drop_start'],
        anim = { dict = 'anim@amb@club@member@idle@', clip = 'base', flag = 1 },
    })
    Animations.Clear()

    if ok then
        local result = lib.callback.await('realistic_tires:dropTire', false)
        if result then
            local prop = Animations.ThrowTire()
            if prop and DoesEntityExist(prop) then
                DroppedTires[prop] = true
                registerDropPickup(prop)
            end
            lib.notify({ title = Config.Locale['drop_end'], type = 'success' })
        end
    end
    dropping = false
end

-- -------------------------------------------------------------
-- Target registration
-- -------------------------------------------------------------

local function buildKey(veh)
    local parts = {}
    if isTruck(GetEntityModel(veh)) then
        parts[#parts + 1] = 'trunk'
    end
    for _, idx in ipairs(getBurstWheels(veh)) do
        parts[#parts + 1] = 'wheel' .. idx
    end
    return table.concat(parts, ',')
end

local function registerVehicleTargets(veh)
    local options = {}

    if isTruck(GetEntityModel(veh)) then
        options[#options + 1] = {
            name = 'extract_spare',
            label = Config.Locale['extract_spare_opt'],
            icon = 'fa-solid fa-box-open',
            distance = Config.InteractDistance,
            onSelect = function(data)
                extractSpare(data.entity)
            end,
        }
    end

    for _, idx in ipairs(getBurstWheels(veh)) do
        options[#options + 1] = {
            name = 'replace_tire_' .. idx,
            label = Config.Locale['replace_tire_opt'],
            icon = 'fa-solid fa-wrench',
            distance = Config.InteractDistance,
            onSelect = function(data)
                replaceTire(data.entity, idx)
            end,
        }
    end

    if #options > 0 then
        exports.ox_target:addLocalVehicle(veh, options)
    end
end

registerDropPickup = function(prop)
    if not DoesEntityExist(prop) then return end
    exports.ox_target:addLocalEntity(prop, {
        {
            name = 'pickup_tire',
            label = Config.Locale['pickup_tire_opt'],
            icon = 'fa-solid fa-hand',
            distance = 2.0,
            onSelect = function(data)
                local ok = Animations.Progress({
                    duration = Config.Progress.ExtractSpare,
                    label = Config.Locale['pickup_start'],
                })
                if ok then
                    lib.callback.await('realistic_tires:addTireToPlayer', false)
                    DeleteEntity(data.entity)
                    DroppedTires[data.entity] = nil
                end
            end,
        },
    })
end

-- -------------------------------------------------------------
-- Main targeting loop
-- -------------------------------------------------------------

CreateThread(function()
    while true do
        local veh = getNearestVehicle()

        if veh ~= Targeting.currentVehicle then
            if Targeting.currentVehicle and DoesEntityExist(Targeting.currentVehicle) then
                exports.ox_target:removeLocalVehicle(Targeting.currentVehicle)
            end
            Targeting.currentVehicle = veh
            Targeting.currentKey = nil
        end

        if veh and DoesEntityExist(veh) then
            local key = buildKey(veh)
            if key ~= Targeting.currentKey then
                exports.ox_target:removeLocalVehicle(veh)
                if key ~= '' then
                    registerVehicleTargets(veh)
                end
                Targeting.currentKey = key
            end
        end

        Wait(500)
    end
end)

-- -------------------------------------------------------------
-- E key to drop a held tire (INPUT_CONTEXT = 51)
-- -------------------------------------------------------------

CreateThread(function()
    while true do
        if IsControlJustPressed(0, 51) then
            CreateThread(dropTire)
        end
        Wait(100)
    end
end)

-- -------------------------------------------------------------
-- Hint while carrying a tire
-- -------------------------------------------------------------

CreateThread(function()
    while true do
        if hasTireItem() and not IsPedInAnyVehicle(PlayerPedId(), false) then
            lib.textUI(Config.Locale['drop_hint'], { position = 'bottom-center' })
            Wait(250)
        else
            lib.hideTextUI()
            Wait(500)
        end
    end
end)

-- Clean up dropped tire targets when they are removed from the world.
CreateThread(function()
    while true do
        Wait(5000)
        for prop in pairs(DroppedTires) do
            if not DoesEntityExist(prop) then
                DroppedTires[prop] = nil
            end
        end
    end
end)
