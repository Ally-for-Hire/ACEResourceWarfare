--- Color Initialization
-- These colors will be used for sending different colored messages to the player
local Color_Red   = Color(255, 0, 0)
local Color_Green = Color(0, 255, 0)
local Color_Blue  = Color(0, 0, 255)
local Color_White = Color(255, 255, 255)
local Color_Gray  = Color(155, 155, 155)

--- Multipliers
-- These values adjust the final cost computation for a vehicle
local EngineMul   = 0.5
local PenMul      = 0.83
local SideMul     = 0.1
local FrontMul    = 1

--- Function: Returns the total effective armor from the front of the vehicle to the current point
-- Uses a trace line recursively, ignoring each Entity once it’s hit.
local function recursiveArmorTrace(Entity, Position, Direction)
    local MaxArmor  = 0
    local Filter    = {}
    local Trace     = {Entity = nil}
    local Attempts  = 0

    while Trace["Entity"] != Entity and Attempts < 1000 do
        Trace = util.TraceLine({
            start  = Position + Direction * 500,
            endpos = Position,
            filter = Filter
        })

        if Trace["Entity"] == Entity then break end

        table.insert(Filter, Trace["Entity"])
        --MaxArmor = MaxArmor + PropArmor -- PropArmor currently doesnt work
        Attempts = Attempts + 1
    end

    return MaxArmor / (#Filter)
end

--- Function: Returns a table of various armor statistics about the tank
-- Scans each relevant ACF entity for forward/side armor.
local function vehicleArmorScan(Entities, MainGun)
    local EffectiveFront = 0
    local EffectiveSide  = 0
    local FrontDir       = MainGun:GetForward()
    local SideDir        = MainGun:GetRight()

    for _, val in pairs(Entities) do
        local EntClass = val:GetClass()

        if EntClass == "acf_engine" or EntClass == "acf_fuel" or EntClass == "acf_ammo" then
            EffectiveFront = EffectiveFront + recursiveArmorTrace(val, val:GetPos(), FrontDir)
            EffectiveSide  = EffectiveSide  + recursiveArmorTrace(val, val:GetPos(), SideDir)
        end
    end

    return {EffectiveFront = EffectiveFront, EffectiveSide = EffectiveSide}
end

--- Function: Returns a table of various general statistics about the tank
-- Summarizes total horsepower, engine count, maximum penetration, and largest caliber gun.
local function vehicleStatScan(Entities)
    local TotalHP       = 0
    local EngineCount   = 0
    local MaxPen        = 0
    local MaxCaliber    = 0
    local MaxCaliberGun = nil

    for _, val in pairs(Entities) do
        if val:GetClass() == "acf_engine" then
            -- Convert kW to HP, then multiply by a custom factor of 1.25
            TotalHP = TotalHP + (val.peakkw * 1.34102 * 1.25)
            EngineCount = EngineCount + 1

        elseif val:GetClass() == "acf_ammo" then
            -- Safely get the MaxPen from the bullet data
            local Pen = ACF.RoundTypes[val.BulletData.Type].getDisplayData(val.BulletData).MaxPen or 0
            if Pen > MaxPen then
                MaxPen = Pen
            end

        elseif val:GetClass() == "acf_gun" then
            -- Track the gun with the largest caliber
            if val.Caliber > MaxCaliber then
                MaxCaliber   = val.Caliber
                MaxCaliberGun = val
            end
        end
    end

    return {TotalHP = TotalHP, EngineCount = EngineCount, MaxPen = MaxPen, MaxCaliberGun = MaxCaliberGun}
end

--- Calculates the cost for a vehicle and displays it to the player
-- Once the paste is finished, this function gathers stats, calculates a price, 
-- and sends a breakdown to the player.
local function onDupeFinish(Data)
    -- Dupe Information
    local CreatedEntities = Data[1].CreatedEntities
    local Player          = Data[1].Player
    
    -- Dupe Statistics
    local VehicleStatistics = vehicleStatScan(CreatedEntities)
    local ArmorStatistics   = {EffectiveFront = 0, EffectiveSide = 0}
    
    -- Debug Information
    local MainGun     = VehicleStatistics["MaxCaliberGun"]
    local MainGunName = "" 
    local EngineCount = VehicleStatistics["EngineCount"]

    -- These values are fucky, we only want to continue if we know for a fact this is a valid vehicle
    if MainGun == nil then return end

    MainGunName       = ACF.Weapons["Guns"][MainGun.Id].name or "" 
    ArmorStatistics   = vehicleArmorScan(CreatedEntities, MainGun)

    -- Point Value Information
    local TotalHP        = VehicleStatistics["TotalHP"]
    local MaxPen         = VehicleStatistics["MaxPen"]
    local EffectiveFront = ArmorStatistics["EffectiveFront"]
    local EffectiveSide  = ArmorStatistics["EffectiveSide"]
    local Price          = EffectiveFront * FrontMul 
                         + EffectiveSide  * SideMul 
                         + MaxPen         * PenMul 
                         + TotalHP        * EngineMul
    
    timer.Create("arw.pointinfotimer", 0.5, 1, function()
        Player:SendMsg(Color_White, "---------------------------------------------")
        Player:SendMsg(Color_White, "+ Effective Frontal Armor: " .. math.Round(EffectiveFront, 1))
        Player:SendMsg(Color_White, "+ Effective Side Armor: " .. math.Round(EffectiveSide, 1))
        Player:SendMsg(Color_White, "+ Total Horsepower: " .. math.Round(TotalHP, 1))
        Player:SendMsg(Color_Gray,  "| Engine Cost: " .. math.Round(TotalHP * EngineMul, 1))
        Player:SendMsg(Color_White, "+ Maximum Penetration: " .. math.Round(MaxPen, 1))
        Player:SendMsg(Color_Gray,  "| Pen Cost: " .. math.Round(MaxPen * PenMul, 1))
        Player:SendMsg(Color_Red,   "= Final Cost: " .. math.Round(Price, 1))
        Player:SendMsg(Color_White, "---------------------------------------------")
    end)
end

--- Final Hooks
-- Register our function to fire when a dupe finish-pasting event occurs
hook.Add("AdvDupe_FinishPasting", "arw.main", onDupeFinish)
