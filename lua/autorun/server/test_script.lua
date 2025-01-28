print("Things Started")

local function recursiveScan(Entities)
    local TotalHP = 0
    local MaxPen  = 0

    for _, val in pairs(Entities) do
        if val:GetClass() == "acf_engine" then
            TotalHP = TotalHP + (val.peakkw * 1.34102 * 1.25)
        elseif val:GetClass() == "acf_ammo" then
            local Pen = ACF.RoundTypes[val.BulletData.Type].getDisplayData(val.BulletData).MaxPen or 0
            if Pen > MaxPen then
                MaxPen = Pen
            end
        end
    end

    return {TotalHP = TotalHP, MaxPen = MaxPen}
end

local function onDupeFinish(Data)
    local EntityList         = Data[1].EntityList
    local CreatedEntities    = Data[1].CreatedEntities
    local ConstraintList     = Data[1].ConstraintList
    local CreatedConstraints = Data[1].CreatedConstraints
    local HitPos             = Data[1].PositionOffset
    local Player             = Data[1].Player
    
    local VehicleStatistics  = recursiveScan(CreatedEntities)
    
    local TotalHP            = VehicleStatistics["TotalHP"]
    local MaxPen             = VehicleStatistics["MaxPen"]

    print("Total Horsepower       " .. TotalHP)
    print("Maximum Penetration    " .. MaxPen)

    --Player:SendMsg(Color(255, 0, 0), "FUCK")
end


hook.Add("AdvDupe_FinishPasting", "arw.main", onDupeFinish)