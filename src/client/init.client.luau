--!strict


local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
Shared:WaitForChild("Config")
Shared:WaitForChild("Remotes")

local MovementController = require(script.Controllers.MovementController)
local CombatController   = require(script.Controllers.CombatController)
local SkillController    = require(script.Controllers.SkillController)

MovementController.Init()
CombatController.Init()
SkillController.Init()
