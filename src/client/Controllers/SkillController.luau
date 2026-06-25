--!strict


local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Remotes     = require(Shared.Remotes.RemoteDefinitions)
local SkillConfig = require(Shared.Config.SkillConfig)

local localPlayer = Players.LocalPlayer


local SkillController = {}

local _cooldownEndTimes: { [number]: number } = {}
local _isSkillActive: boolean  = false
local _awakenHoldStart: number? = nil
local _awakenFired: boolean    = false
local _characterReady: boolean = false


local function isOnCooldown(slotIndex: number): boolean
	local endTime = _cooldownEndTimes[slotIndex]
	if not endTime then return false end
	return tick() < endTime
end

local function startCooldown(slotIndex: number): ()
	local skill = SkillConfig.Skills[slotIndex]
	if not skill then return end
	_cooldownEndTimes[slotIndex] = tick() + skill.Cooldown
end


local function fireSkill(slotIndex: number): ()
	if not _characterReady then return end
	if _isSkillActive then return end
	if isOnCooldown(slotIndex) then return end

	local skill = SkillConfig.Skills[slotIndex]
	if not skill then return end

	_isSkillActive = true

	-- TODO: play skill.AnimName animation

	startCooldown(slotIndex)

	Remotes.UseSkill:FireServer(slotIndex)

	task.delay(1.5, function()
		_isSkillActive = false
	end)
end


local function onAwakenKeyDown(): ()
	if isOnCooldown(5) then return end
	_awakenHoldStart = tick()
	_awakenFired     = false
end

local function onAwakenKeyUp(): ()
	local holdStart  = _awakenHoldStart
	_awakenHoldStart = nil
	if not holdStart or _awakenFired then return end

	local held = tick() - holdStart
	if held >= SkillConfig.AwakenHoldTime then
		fireSkill(5)
		_awakenFired = true
	end
end


local function onInputBegan(input: InputObject, gameProcessed: boolean): ()
	if gameProcessed then return end

	local keyCode = input.KeyCode

	for slotIndex, bind in SkillConfig.KeyBinds do
		if keyCode == bind then
			if slotIndex == 5 then
				onAwakenKeyDown()
			else
				fireSkill(slotIndex)
			end
			return
		end
	end
end

local function onInputEnded(input: InputObject, _gameProcessed: boolean): ()
	if input.KeyCode == SkillConfig.KeyBinds[5] then
		onAwakenKeyUp()
	end
end


local function setupCharacter(character: Model): ()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	_isSkillActive   = false
	_awakenHoldStart = nil
	_awakenFired     = false

	task.defer(function()
		_characterReady = true
	end)

	humanoid.Died:Connect(function()
		_characterReady = false
		_isSkillActive  = false
	end)
end


function SkillController.IsOnCooldown(slotIndex: number): boolean
	return isOnCooldown(slotIndex)
end

function SkillController.GetCooldownRemaining(slotIndex: number): number
	local endTime = _cooldownEndTimes[slotIndex]
	if not endTime then return 0 end
	return math.max(0, endTime - tick())
end

function SkillController.Init(): ()
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)

	local character = localPlayer.Character
	if character then
		setupCharacter(character)
	end

	localPlayer.CharacterAdded:Connect(function(char: Model)
		setupCharacter(char)
	end)
end

return SkillController
