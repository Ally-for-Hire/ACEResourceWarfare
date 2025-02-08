--- Function: Returns the total effective armor from the front of the vehicle to the current point
-- Uses a trace line recursively, ignoring each Entity once it’s hit.
function recursiveArmorTrace(Entity, Position, Direction)
    local MaxArmor  = 0
    local Filter    = {}
    local Trace     = {Entity = nil}
    local Attempts  = 0

    while Trace.Entity != Entity and Attempts < 1000 do
        Trace = util.TraceLine({
            start  = Position + Direction * 500,
            endpos = Position,
            filter = Filter
        })

        if Trace.Entity == Entity then break end
        if not IsValid(Trace.entity) then continue end

        table.insert(Filter, Trace.Entity)
        ACF_Check(Trace.Entity)
        
        -- Stole this from the ACE sourcecode lol
        local Angle	    	= ACF_GetHitAngle( Trace.HitNormal , Trace.Normal )
        local Mat			= Trace.Entity.ACF.Material or "RHA"	--very important thing
        local MatData		= ACE_GetMaterialData( Mat )
        local armor         = Trace.Entity.ACF.Armour
        local losArmor		= armor / math.abs( math.cos(math.rad(Angle)) ^ ACF.SlopeEffectFactor ) * MatData["effectiveness"]
        
        MaxArmor = MaxArmor + losArmor
        Attempts = Attempts + 1
    end

    print(Entity)
    print("    Attempts: " .. Attempts)
    -- print("    ArmorMod: " .. ACF.ArmorMod)

    if #Filter == 0 then
        return 0
    end

    return MaxArmor 
end

--- Function: Returns a table of various armor statistics about the tank
-- Scans each relevant ACF entity for forward/side armor.
function vehicleArmorScan(Entities, MainGun)
    local EffectiveFront = 0
    local EffectiveSide  = 0
    local FrontDir       = MainGun:GetForward()
    local SideDir        = MainGun:GetRight()
    local Count          = 0

    for _, val in pairs(Entities) do
        local EntClass = val:GetClass()
        local EntCenter = val:WorldSpaceCenter()

        if Criticals[EntClass] then
            -- Simple placeholder, will make this shoot traces around the bounding box 
            EffectiveFront = EffectiveFront + ACE_LOSMultiTrace(EntCenter + FrontDir * 300, EntCenter)
            EffectiveSide  = EffectiveSide  + ACE_LOSMultiTrace(EntCenter + SideDir * 300, EntCenter)
            Count = Count + 1
        end
    end

    return {EffectiveFront = EffectiveFront / Count, EffectiveSide = EffectiveSide / Count} -- Count placeholder for surface area
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
