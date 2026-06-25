--!strict


local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared          = ReplicatedStorage:WaitForChild("Shared")
local CharacterConfig = require(Shared.Config.CharacterConfig)

local localPlayer = Players.LocalPlayer
local camera      = workspace.CurrentCamera


type MovementState = "Idle" | "Walking" | "Running" | "Jumping" | "Dashing" | "Rolling" | "Locked"


local MovementController = {}

local _state: MovementState       = "Idle"
local _character: Model?          = nil
local _humanoid: Humanoid?        = nil
local _hrp: BasePart?             = nil
local _isDashing: boolean         = false
local _isRolling: boolean         = false
local _iFrameActive: boolean      = false
local _dashCooldownReady: boolean = true
local _dashCount: number          = 0

local _lastKeyTapTime: { [Enum.KeyCode]: number } = {}

local DASH_KEYS: { Enum.KeyCode } = {
	Enum.KeyCode.W,
	Enum.KeyCode.A,
	Enum.KeyCode.S,
	Enum.KeyCode.D,
}


local function keyToDirection(keyCode: Enum.KeyCode): Vector3
	if not _hrp then return Vector3.new(0, 0, -1) end
	local cf      = _hrp.CFrame
	local forward = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit
	local right   = forward:Cross(Vector3.new(0, 1, 0)).Unit

	if keyCode == Enum.KeyCode.W then return forward
	elseif keyCode == Enum.KeyCode.S then return -forward
	elseif keyCode == Enum.KeyCode.D then return right
	elseif keyCode == Enum.KeyCode.A then return -right
	end
	return forward
end


local function performRoll(direction: Vector3): ()
	if not _hrp or not _humanoid then return end
	if not _dashCooldownReady then return end
	if _isRolling then return end

	_isRolling         = true
	_iFrameActive      = true
	_dashCooldownReady = false
	_state             = "Rolling"

	-- TODO: play Roll animation

	_hrp.AssemblyLinearVelocity = direction * CharacterConfig.RollForce

	task.delay(CharacterConfig.RollIFrames, function()
		_iFrameActive = false
	end)

	task.delay(CharacterConfig.RollDuration, function()
		_isRolling = false
		if _state == "Rolling" then
			_state = "Idle"
		end
	end)

	task.delay(CharacterConfig.DashCooldown, function()
		_dashCooldownReady = true
		_dashCount         = 0
	end)
end


local function performDash(direction: Vector3): ()
	if not _hrp or not _humanoid then return end
	if not _dashCooldownReady then return end
	if _isDashing then return end

	_isDashing = true
	_state     = "Dashing"

	-- TODO: play Dash1 or Dash2 animation (based on _dashCount)

	_hrp.AssemblyLinearVelocity = direction * CharacterConfig.DashForce

	task.delay(CharacterConfig.DashDuration, function()
		_isDashing = false
		if _state == "Dashing" then
			_state = "Idle"
		end
	end)
end


local function onInputBegan(input: InputObject, gameProcessed: boolean): ()
	if gameProcessed then return end
	if _state == "Locked" then return end

	local keyCode = input.KeyCode

	local isDashKey = false
	for _, k in DASH_KEYS do
		if k == keyCode then
			isDashKey = true
			break
		end
	end

	if not isDashKey then return end

	local now  = tick()
	local last = _lastKeyTapTime[keyCode] or 0

	if (now - last) <= CharacterConfig.DoubleTapWindow then
		_dashCount += 1
		local direction = keyToDirection(keyCode)

		if _dashCount >= 3 then
			performRoll(direction)
		else
			performDash(direction)
		end
	end

	_lastKeyTapTime[keyCode] = now
end


local function setupCharacter(character: Model): ()
	_character = character
	_humanoid  = character:WaitForChild("Humanoid") :: Humanoid
	_hrp       = character:WaitForChild("HumanoidRootPart") :: BasePart

	_state             = "Idle"
	_isDashing         = false
	_isRolling         = false
	_iFrameActive      = false
	_dashCooldownReady = true
	_dashCount         = 0

	_humanoid.WalkSpeed = CharacterConfig.WalkSpeed
	_humanoid.JumpPower = CharacterConfig.JumpPower
end


function MovementController.GetState(): MovementState
	return _state
end

function MovementController.SetLocked(locked: boolean): ()
	if locked then
		_state = "Locked"
		if _humanoid then
			_humanoid.WalkSpeed = 0
		end
	else
		_state = "Idle"
		if _humanoid then
			_humanoid.WalkSpeed = CharacterConfig.WalkSpeed
		end
	end
end

function MovementController.IsIFrameActive(): boolean
	return _iFrameActive
end

function MovementController.Init(): ()
	UserInputService.InputBegan:Connect(onInputBegan)

	local character = localPlayer.Character
	if character then
		setupCharacter(character)
	end

	localPlayer.CharacterAdded:Connect(function(char: Model)
		setupCharacter(char)
	end)
end

return MovementController
