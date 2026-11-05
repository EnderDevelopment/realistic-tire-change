# Realistic Tire Replacement (ESX + OX)

A realistic FiveM tire replacement system for **ESX**, **ox_target** and **ox_lib**. Every step is animated and plays out like the real thing — nothing is cut short.

## Features

- When a wheel bursts (tyre burst state, e.g. after being shot), the player can fix it.
- **Extract spare from the truck trunk** using the OX "eye" target system.
- The spare becomes a **`tire` inventory item**.
- Go to the burst wheel and:
  1. Kneel down next to the wheel (realistic animation).
  2. **Unscrew every bolt one at a time** (one progress bar per bolt, with a small delay between each for realism).
  3. Pull the old/burst wheel off the hub (a real wheel prop appears in hand).
  4. **Carry the old tire to the truck trunk** and store it there.
  5. Mount the new wheel on the hub.
  6. **Tighten every bolt one at a time**.
- Press **E** while holding a tire to drop/throw it on the ground.
- Dropped tires can be picked up again with the OX target system.
- A small delay (Config.StepDelay) is inserted between each bolt action so the process feels real and not rushed.

## Installation

1. Copy the folder into your `resources` directory (e.g. `resources/realistic_tires`).
2. Add to `server.cfg`:
   ```
   ensure ox_lib
   ensure ox_target
   ensure es_extended
   ensure ox_inventory
   ensure realistic_tires
   ```
3. Make sure the `tire` item is registered in **ox_inventory**:

   The resource already tries to register it via `exports.ox_inventory:RegisterItem`. If that export is not available on your build, add the item manually to your ox_inventory `items.lua`:

   ```lua
   ['tire'] = {
       label = 'Tire',
       weight = 15000,
       stack = true,
       close = true,
       description = 'A rubber tire. Ready to be mounted on a wheel hub.',
   }
   ```

## Configuration

Everything can be tuned in `config.lua`:

| Key | Purpose |
| --- | --- |
| `Config.Trucks` | Vehicle models whose trunk holds a spare tire. |
| `Config.TireItem` | The inventory item used as a tire. |
| `Config.BoltsPerWheel` | How many bolts each wheel has (one progress per bolt). |
| `Config.MaxTrunkSpares` | How many usable spares a trunk holds. |
| `Config.Progress.*` | Timings (ms) for each realistic step. |
| `Config.StepDelay` | Pause between each bolt action for realism. |
| `Config.WheelBones` | Bone names per wheel (used to aim the player next to the correct wheel). |
| `Config.TirePropModel` | The wheel prop model held/thrown for visuals. |
| `Config.Locale` | All displayed text (translate easily / switch to Arabic if you wish). |

## Notes

- Tires burst naturally from game damage (bullets/collisions). This script reacts to any wheel already in a burst state — there is no random auto-pop.
- The UI text is in English by default. You can translate any string directly in `Config.Locale` (including to Arabic).
- No real secrets or tokens are used; set your own server details as usual.

---

More FiveM resource projects by EnderDevelopment: https://github.com/EnderDevelopment

Project page: https://dash.enderdevelopment.com/community/54c68496-f67c-4f48-8513-6a76ae01eaf6?utm_source=github&utm_medium=readme&utm_campaign=auto_publish&utm_content=54c68496-f67c-4f48-8513-6a76ae01eaf6
