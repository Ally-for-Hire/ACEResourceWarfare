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
    local TotalHP        = VehicleStatistics["TotalHP"] -- Mostly to discourage high weight tanks
    local MaxPen         = VehicleStatistics["MaxPen"] -- Max pen is nice, but I need to implement a DPS multiplier, or a reason to not have 0s reload
    local EffectiveFront = ArmorStatistics["EffectiveFront"] -- Listen, daktank wasn't all bad
    local EffectiveSide  = ArmorStatistics["EffectiveSide"] -- But I want to do something more complex with this, flat 2x doesn't seem right
    local Price          = EffectiveFront * FrontMul 
                         + EffectiveSide  * SideMul 
                         + MaxPen         * PenMul 
                         + TotalHP        * EngineMul
    
    timer.Create("arw.pointinfotimer", 0.5, 1, function()
        Player:SendMsg(Color_White, "--------------------------------------------------")
        Player:SendMsg(Color_White, "+ Frontal Cost: " .. math.Round(EffectiveFront, 1) .. "mm x" .. FrontMul .. " = " .. math.Round(EffectiveFront * FrontMul, 1))
        Player:SendMsg(Color_White, "+ Side Cost: " .. math.Round(EffectiveSide, 1) .. "mm x" .. SideMul .. " = " .. math.Round(EffectiveSide * SideMul, 1))
        Player:SendMsg(Color_White, "+ Horsepower Cost: " .. math.Round(TotalHP, 1) .. "hp x" .. EngineMul .. " = " .. math.Round(TotalHP * EngineMul, 1))
        Player:SendMsg(Color_White, "+ Max Pen Cost: " .. math.Round(MaxPen, 1) .. "mm x" .. PenMul .. " = " .. math.Round(MaxPen * PenMul, 1))
        Player:SendMsg(Color_Red,   "= Final Cost: " .. math.Round(Price, 1))
        Player:SendMsg(Color_White, "--------------------------------------------------")
    end)
end

--- Final Hooks
-- Register our function to fire when a dupe finish-pasting event occurs
hook.Add("AdvDupe_FinishPasting", "arw.main", onDupeFinish)
