--- Function: Returns the total effective armor from the front of the vehicle to the current point
-- Uses a trace line recursively, ignoring each Entity once it’s hit.
function recursiveArmorTrace(Entity, Position, Direction)
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
function vehicleArmorScan(Entities, MainGun)
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
function vehicleStatScan(Entities)
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
