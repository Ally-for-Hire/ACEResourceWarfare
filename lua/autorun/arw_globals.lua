--- Color Initialization
-- These colors will be used for sending different colored messages to the player
Color_Red   = Color(255, 0, 0)
Color_Green = Color(0, 255, 0)
Color_Blue  = Color(0, 0, 255)
Color_White = Color(255, 255, 255)
Color_Gray  = Color(155, 155, 155)

--- Multipliers
-- These values adjust the final cost computation for a vehicle
EngineMul   = 0.5
PenMul      = 0.9
SideMul     = 2
FrontMul    = 1

--- Valid Critical Components
-- These are the critical components we are looking for when doing our calculations
Criticals = {
    ["ace_crewseat_driver"] = true,
    ["ace_crewseat_loader"] = true,
    ["ace_crewseat_gunner"] = true,
    ["acf_ammo"] = true,
    ["acf_fuel"] = true,
    ["acf_engine"] = true
}