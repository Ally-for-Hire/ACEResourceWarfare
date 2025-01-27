print("Things Started")

hook.Remove("arw.main")

hook.Add("AdvDupe_FinishPasting", "arw.main", function(Data)
    EntityList = Data[1].EntityList
    CreatedEntities = Data[1].CreatedEntities
    ConstraintList = Data[1].ConstraintList
    CreatedConstraints = Data[1].CreatedConstraints
    HitPos = Data[1].PositionOffset
    Player = Data[1].Player

    print(Player)
end)