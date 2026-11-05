-- Registers the physical tire item for ox_inventory.
-- If the export is not available, the resource logs a warning and the item must
-- be added manually to your ox_inventory items.lua file:
--
--   ['tire'] = {
--       label = 'Tire',
--       weight = 15000,
--       stack = true,
--       close = true,
--   },

local success = pcall(function()
    exports.ox_inventory:RegisterItem(Config.TireItem, {
        name   = Config.TireItem,
        label  = 'Tire',
        weight = 15000,
        stack  = true,
        close  = true,
        description = 'A rubber tire. Ready to be mounted on a wheel hub.',
    })
end)

if not success then
    CreateThread(function()
        Wait(5000)
        local esx = exports['es_extended']:getSharedObject()
        if esx then
            print(('\n^1[RealisticTires]^0 %s\n'):format(Config.Locale['no_item_definition']:format(Config.TireItem)))
        end
    end)
end
