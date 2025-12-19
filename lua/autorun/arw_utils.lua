--- Function: Returns the total effective armor from the front of the vehicle to the current point
-- Uses a trace line recursively, ignoring each Entity once it’s hit.
function recursiveArmorTrace(Entity, Position, Direction, CheckLOS)
    local MaxArmor  = 0
    local Filter    = {}
    local Trace     = {Entity = nil, Hit = true}
    local Attempts  = 0
    local StartAdd  = (CheckLOS and 1 or 0) * Direction * 5

    while Trace.Hit == true do
        Trace = util.TraceLine({
            start  = Position + Direction * 500,
            endpos = Position + StartAdd,
            filter = Filter
        })
        
        if not IsValid(Trace.Entity) then continue end

        if ACF_CheckClips(Trace.Entity, Trace.HitPos) or Trace.Entity == Entity then --Hit visclip. Skip straight to ignoring
            if CheckLOS then
                print("Early out, hit entity before final pos")
                return 0
            end
            table.insert(Filter, Trace.Entity)
            continue
        end

        table.insert(Filter, Trace.Entity)
        ACF_Check(Trace.Entity)
        
        -- Stole this from the ACE sourcecode lol
        local Angle	    	= ACF_GetHitAngle(Trace.HitNormal , Trace.Normal)
        local Mat			= Trace.Entity.ACF.Material or "RHA"
        local MatData		= ACE_GetMaterialData( Mat )
        local armor         = Trace.Entity.ACF.Armour
        local losArmor		= armor / math.abs( math.cos(math.rad(Angle)) ^ ACF.SlopeEffectFactor ) * MatData["effectiveness"]

        MaxArmor = MaxArmor + losArmor
        Attempts = Attempts + 1
    end

    if #Filter == 0 then
        return 0
    end

    return MaxArmor 
end

--- Calculate the corners of an entity visible from a given direction
-- Returns the visible corners, and the surface area from that direction
function entVisibleCorners(Entity, Direction)
    local min, max = Entity:OBBMins(), Entity:OBBMaxs()
    local count = 0

    local maxTLVec = Entity:GetPos()
    local maxBRVec = Entity:GetPos()

    local sideDir = Direction:Cross(Vector(0, 0, 1))
    local topLeftVec = Entity:GetPos() + sideDir * 400 + Vector(0, 0, 400)
    local bottomRightVec = Entity:GetPos() - sideDir * 400 - Vector(0, 0, 400)

    debugoverlay.Sphere(topLeftVec, 3, 15, Color(255, 0, 0, 100), true)
    debugoverlay.Sphere(bottomRightVec, 3, 15, Color(0, 255, 0, 100), true)

    local corners = {
        Vector(min.x, min.y, min.z),
        Vector(min.x, min.y, max.z),
        Vector(min.x, max.y, min.z),
        Vector(min.x, max.y, max.z),
        Vector(max.x, min.y, min.z),
        Vector(max.x, min.y, max.z),
        Vector(max.x, max.y, min.z),
        Vector(max.x, max.y, max.z)
    }

    for i = 1, #corners do
        corners[i] = Entity:LocalToWorld(corners[i] * 0.95)
        if corners[i]:Distance(topLeftVec) < maxTLVec:Distance(topLeftVec) then maxTLVec = corners[i] end
        if corners[i]:Distance(bottomRightVec) < maxBRVec:Distance(bottomRightVec) then maxBRVec = corners[i] end
        
        local Trace = util.TraceLine({
            start = corners[i] + Direction * 100,
            endpos = corners[i] + Direction * 2,
            filter = function(ent)
                -- Only allow the trace to hit the specified entity
                return ent == Entity
            end
        })

        if Trace.Hit then
            corners[i] = Vector()
        else
            count = count + 1
        end
    end

    local vertical = maxTLVec[3] - maxBRVec[3]
    maxTLVec[3] = 0
    maxBRVec[3] = 0
    local horizontal = maxTLVec:Distance(maxBRVec)
    local surfaceArea = horizontal * vertical
    debugoverlay.Sphere(maxTLVec, 3, 15, Color(255, 0, 0, 100), true)
    debugoverlay.Sphere(maxBRVec, 3, 15, Color(0, 255, 0, 100), true)

    return corners, count, surfaceArea
end

--- Function: Returns a table of various armor statistics about the tank
-- Scans each relevant ACF entity for forward/side armor.
function vehicleArmorScan(Entities, MainGun)
    local EffectiveFront   = 0
    local EffectiveSide    = 0
    local FrontSurfaceArea = 0
    local SideSurfaceArea  = 0
    local FrontDir         = MainGun:GetForward():GetNormalized()
    local SideDir          = MainGun:GetRight():GetNormalized()
    local Count            = 0

    for _, Entity in pairs(Entities) do
        local EntClass = Entity:GetClass()
        local EntCenter = Entity:WorldSpaceCenter()

        if Criticals[EntClass] then
            -- Simple placeholder, will make this shoot traces around the bounding box 
            -- Current plan: shoot traces at every bounding box position moved slightly towards trace
            -- If the trace intersects the entity, then we know its not within LOS, and we ignore that
            -- Otherwise, assume that the entire section has the same armor, and multiply by that area
            local FrontVectors, CornerCount, SurfaceArea = entVisibleCorners(Entity, FrontDir)
            local FrontArmor = 0
            for _, val in pairs(FrontVectors) do
                if val == Vector() then continue end
                debugoverlay.Sphere(val, 1, 15, Color(0, 0, 255, 100), true)
                FrontArmor = FrontArmor + recursiveArmorTrace(nil, val, FrontDir) / CornerCount
            end
            EffectiveFront = EffectiveFront + FrontArmor * SurfaceArea
            FrontSurfaceArea = FrontSurfaceArea + SurfaceArea

            /*
            local SideVectors, SurfaceArea = entVisibleCorners(Entity, SideDir)
            local SideArmor = 0
            for _, val in pairs(SideVectors) do
                SideArmor = SideArmor + recursiveArmorTrace(nil, val, SideDir) / #SideVectors
            end
            EffectiveSide = EffectiveSide + SideArmor * SurfaceArea
            SideSurfaceArea = SideSurfaceArea + SurfaceArea
            */
            -- EffectiveFront = EffectiveFront + recursiveArmorTrace(Entity, EntCenter, FrontDir)
            -- EffectiveSide = EffectiveSideR + recursiveArmorTrace(Entity, EntCenter, SideDir)

            Count = Count + 1
        end
    end

    print(FrontSurfaceArea)

    return {EffectiveFront = EffectiveFront / FrontSurfaceArea, EffectiveSide = EffectiveSide / SideSurfaceArea} -- Count placeholder for surface area
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
