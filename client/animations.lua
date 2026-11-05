local Animations = {}

-- A set of known-good animation dictionaries / clips used for realism.
-- Each has a fallback scenario/dict so the script never hard-crashes if an
-- animation dict is missing on a given server build.
local CLIPS = {
    kneel       = { dict = 'amb@world_human_welding@male@idle_a', clip = 'idle_a' },
    work_back   = { dict = 'missmechanic',                        clip = 'work2_base' },
    carry       = { dict = 'anim@heists@box_carry@',              clip = 'idle' },
    toss        = { dict = 'anim@amb@club@member@idle@',          clip = 'base' },
}

local function loadDict(dict)
    if not dict then return false end
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local tries = 0
        while not HasAnimDictLoaded(dict) and tries < 50 do
            tries = tries + 1
            Wait(50)
        end
    end
    return HasAnimDictLoaded(dict)
end

-- Fallback: make the player kneel using the game's built-in scenario task.
function Animations.FallbackKneel()
    TaskStartScenarioInPlace(PlayerPedId(), 'CODE_HUMAN_MEDIC_KNEEL', 0, true)
    Wait(300)
end

-- Play a kneeling / working pose near the wheel.
function Animations.KneelByWheel()
    local clip = CLIPS.kneel
    if loadDict(clip.dict) then
        TaskPlayAnim(PlayerPedId(), clip.dict, clip.clip, 8.0, 1.0, -1, 1, 0, false, false, false)
    else
        Animations.FallbackKneel()
    end
end

-- Play a "working back bent" pose used while manipulating bolts.
function Animations.WorkAtWheel()
    local clip = CLIPS.work_back
    if loadDict(clip.dict) then
        TaskPlayAnim(PlayerPedId(), clip.dict, clip.clip, 8.0, 1.0, -1, 1, 0, false, false, false)
    else
        Animations.KneelByWheel()
    end
end

-- Play a carrying pose while holding a tire.
function Animations.CarryTire()
    local clip = CLIPS.carry
    if loadDict(clip.dict) then
        TaskPlayAnim(PlayerPedId(), clip.dict, clip.clip, 8.0, 1.0, -1, 49, 0, false, false, false)
    end
end

-- Small tossing animation when dropping a tire.
function Animations.TossTire()
    local clip = CLIPS.toss
    if loadDict(clip.dict) then
        TaskPlayAnim(PlayerPedId(), clip.dict, clip.clip, 8.0, 1.0, 1200, 0, 0, false, false, false)
    end
end

-- Stop the current playing animation on the player.
function Animations.Clear()
    ClearPedTasks(PlayerPedId())
end

-- Remove any hand props currently attached to the player ped.
function Animations.ClearProps()
    local ped = PlayerPedId()
    ClearPedProp(ped, 0)
    ClearPedProp(ped, 1)
end

-- Spawn a wheel prop attached to the player's hand (for carrying realism).
-- Returns the prop entity or nil.
function Animations.AttachTire(ped, boneIndex)
    local bone = GetPedBoneIndex(ped, boneIndex or 57005) -- hand_r
    local prop = CreateObject(GetHashKey(Config.TirePropModel), GetEntityCoords(ped), true, true, false)
    SetEntityAsMissionEntity(prop, true, true)
    SetEntityCollision(prop, false, true)
    AttachEntityToEntity(prop, ped, bone, 0.18, 0.05, 0.0, 0.0, 90.0, 0.0, true, true, false, true, 1, true)
    return prop
end

-- Throw a wheel prop away from the player.
function Animations.ThrowTire()
    local ped = PlayerPedId()
    local prop = Animations.AttachTire(ped, 57005)
    if prop then
        Wait(700)
        DetachEntity(prop, true, true)
        local heading = GetEntityHeading(ped)
        local offset = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 1.0)
        SetEntityCoords(prop, offset.x, offset.y, offset.z)
        SetEntityVelocity(prop, -math.sin(math.rad(heading)) * 2.0, math.cos(math.rad(heading)) * 2.0, 2.0)
        SetEntityCollision(prop, true, true)
    end
    Animations.ClearProps()
    return prop
end

-- Execute an ox_lib progress bar with the given options, returning true on completion.
function Animations.Progress(options)
    local ok = lib.progressBar({
        duration   = options.duration,
        label      = options.label,
        useWhileDead = false,
        canCancel  = options.canCancel ~= false,
        disable    = { move = true, car = true, combat = true },
        anim       = options.anim,
        onStart    = options.onStart,
        onComplete = options.onComplete,
    })
    return ok
end

return Animations
