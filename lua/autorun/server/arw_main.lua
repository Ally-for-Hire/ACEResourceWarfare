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
        Player:SendMsg(Color_White, "+ Frontal Armor Cost: " .. math.Round(EffectiveFront, 1) .. "mm x" .. FrontMul .. " = " .. math.Round(EffectiveFront * FrontMul, 1))
        Player:SendMsg(Color_White, "+ Side Armor Cost: " .. math.Round(EffectiveSide, 1) .. "mm x" .. SideMul .. " = " .. math.Round(EffectiveSide * SideMul, 1))
        Player:SendMsg(Color_White, "+ Total Horsepower Cost: " .. math.Round(TotalHP, 1) .. "hp x" .. EngineMul .. " = " .. math.Round(TotalHP * EngineMul, 1))
        Player:SendMsg(Color_White, "+ Maximum Penetration Cost: " .. math.Round(MaxPen, 1) .. "mm x" .. PenMul .. " = " .. math.Round(MaxPen * PenMul, 1))
        Player:SendMsg(Color_Red,   "= Final Cost: " .. math.Round(Price, 1))
        Player:SendMsg(Color_White, "---------------------------------------------")
    end)
end

--- Final Hooks
-- Register our function to fire when a dupe finish-pasting event occurs
hook.Add("AdvDupe_FinishPasting", "arw.main", onDupeFinish)
