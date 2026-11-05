Config = {}

-- Model list of vehicles that have a trunk (box truck / van style) from which a spare tire can be extracted.
-- Use the spawn model names.
Config.Trucks = {
    'boxville', 'boxville2', 'boxville3', 'mule', 'mule2', 'mule3',
    'pony', 'pony2', 'benson', 'hauler', 'hauler2', 'phantom', 'phantom3',
    'pounder', 'pounder2', 'stockade', 'stockade3', 'rumpo', 'rumpo2',
    'rumpo3', 'burrito', 'burrito2', 'burrito3', 'speedo', 'speedo2',
    'speedo4', 'bobcatxl', 'youga', 'youga2', 'youga3', 'gburrito', 'gburrito2',
}

-- The inventory item the player holds to represent a physical tire / spare tire.
Config.TireItem = 'tire'

-- How many bolts each wheel has. Each bolt is loosened/tightened one at a time.
Config.BoltsPerWheel = 5

-- How many spares can be extracted from a single vehicle trunk over time.
Config.MaxTrunkSpares = 1

-- Time (ms) for each realistic step of the process.
Config.Progress = {
    ExtractSpare    = 3500, -- pulling the spare out of the trunk
    ApproachWheel   = 2500, -- walking up to the wheel / kneeling down
    UnscrewBolt     = 2200, -- one bolt unscrewed
    RemoveWheel     = 4500, -- pulling the wheel off the hub
    CarryOldToTrunk = 4000, -- carrying the old wheel to the trunk
    InstallWheel    = 4500, -- putting the new wheel on the hub
    TightenBolt     = 2200, -- one bolt tightened
    DropTire        = 1500, -- throwing the tire to the ground
}

-- Small delay (ms) used to space out repeated bolt actions for realism.
Config.StepDelay = 250

-- Distance in meters within which the player can interact with a vehicle.
Config.InteractDistance = 3.0

-- Wheel bone names used to position targets and the mechanic next to the correct wheel.
Config.WheelBones = {
    [0] = 'wheel_lf', -- front left
    [1] = 'wheel_rf', -- front right
    [2] = 'wheel_lr', -- rear left
    [3] = 'wheel_rr', -- rear right
}

-- Offset applied on top of each wheel bone to move the player next to the tire.
Config.WheelKneelOffset = 1.2

-- Bone / offset used to detect the back (trunk) of the vehicle.
Config.TrunkBone = 'boot'
Config.TrunkOffset = { x = 0.0, y = -2.4, z = 0.3 }

-- Wheel prop model that is visually held / thrown for full realism.
Config.TirePropModel = 'prop_wheel_01'

-- Messages shown to the player.
Config.Locale = {
    ['extract_spare_opt']    = 'Extract Spare Tire',
    ['extract_spare_start']  = 'Opening the truck trunk...',
    ['extract_spare_end']    = 'You pulled a spare tire from the trunk.',
    ['extract_no_spare']     = 'There is no spare tire left in this trunk.',
    ['no_room']              = 'You have no space for another tire.',
    ['already_have_tire']    = 'You are already carrying a spare tire.',
    ['replace_tire_opt']     = 'Replace Burst Tire',
    ['need_tire']            = 'You need a spare tire first. Extract one from the truck trunk.',
    ['no_burst_tire']        = 'This tire is not burst.',
    ['approach_wheel']       = 'Kneeling by the wheel...',
    ['unscrew_bolt']         = 'Unscrewing bolt %d/%d...',
    ['remove_wheel']         = 'Pulling the wheel off the hub...',
    ['carry_old_to_trunk']   = 'Carrying the old tire to the truck...',
    ['install_wheel']        = 'Mounting the new wheel...',
    ['tighten_bolt']         = 'Tightening bolt %d/%d...',
    ['done']                 = 'The tire has been replaced successfully.',
    ['drop_hint']            = 'Press [E] to drop the tire',
    ['drop_start']           = 'Dropping the tire...',
    ['drop_end']             = 'You dropped the tire on the ground.',
    ['cancel']               = 'Cancelled',
    ['pickup_tire_opt']      = 'Pick Up Tire',
    ['pickup_start']         = 'Picking up the tire...',
    ['no_item_definition']   = '^1[RealisticTires] Item "%s" is not registered. Add it to ox_inventory items.',
}
