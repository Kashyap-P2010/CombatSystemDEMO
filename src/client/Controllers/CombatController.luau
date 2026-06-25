--!strict

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Remotes      = require(Shared.Remotes.RemoteDefinitions)
local CombatConfig = require(Shared.Config.CombatConfig)

local localPlayer = Players.LocalPlayer

type CombatState = "Idle" | "Attacking" | "Blocking" | "Dodging" | "Stunned" | "Locked"

local CombatController = {}

local _state: CombatState         = "Idle"
local _comboIndex: number         = 0
local _comboResetTask: thread?    = nil
local _isAttacking: boolean       = false
local _isBlocking: boolean        = false
local _isDodging: boolean         = false
local _dodgeCooldownReady: boolean = true
local _character: Model?          = nil
local _hrp: BasePart?             = nil

local function cancelComboReset(): ()
	if _comboResetTask then
		task.cancel(_comboResetTask)
		_comboResetTask = nil
	end
end

local function scheduleComboReset(): ()
	cancelComboReset()
	_comboResetTask = task.delay(CombatConfig.ComboResetTime, function()
		_comboIndex     = 0
		_isAttacking    = false
		_comboResetTask = nil
		if _state == "Attacking" then
			_state = "Idle"
		end
	end)
end

local function buildHitboxCFrame(hitData: CombatConfig.HitData): CFrame?
	if not _hrp then return nil end
	return _hrp.CFrame * CFrame.new(hitData.HitboxOffset)
end

local function fireNextComboHit(): ()
	if _state == "Locked" or _state == "Stunned" then return end
	if _isAttacking then return end
	if _isBlocking then return end

	local nextIndex = _comboIndex + 1
	if nextIndex > #CombatConfig.Combo then
		nextIndex = 1
	end

	local hitData = CombatConfig.Combo[nextIndex]
	_comboIndex   = nextIndex
	_isAttacking  = true
	_state        = "Attacking"

	-- TODO: play hitData.AnimName animation

	local hitboxCF = buildHitboxCFrame(hitData)
	if not hitboxCF then
		_isAttacking = false
		return
	end

	Remotes.CombatHit:FireServer(nextIndex, hitboxCF, hitData.HitboxSize)

	task.delay(hitData.ComboWindow * 0.6, function()
		_isAttacking = false
	end)

	if nextIndex == #CombatConfig.Combo then

		cancelComboReset()
		task.delay(hitData.ComboWindow + 0.1, function()
			_comboIndex = 0
			_state      = "Idle"
		end)
	else
		scheduleComboReset()
	end
end

local function startBlock(): ()
	if _state == "Attacking" or _state == "Locked" then return end
	_isBlocking = true
	_state      = "Blocking"
	Remotes.BlockState:FireServer(true)
	-- TODO: play Block animation
end

local function endBlock(): ()
	if not _isBlocking then return end
	_isBlocking = false
	_state      = "Idle"
	Remotes.BlockState:FireServer(false)
	-- TODO: play UnBlock animation
end

local function performDodge(): ()
	if _state == "Locked" or _state == "Stunned" then return end
	if not _dodgeCooldownReady then return end
	if _isDodging then return end

	_isDodging          = true
	_dodgeCooldownReady = false
	_state              = "Dodging"

	local direction = Vector3.new(0, 0, 1)
	if _hrp then
		local look  = _hrp.CFrame.LookVector
		direction   = Vector3.new(-look.X, 0, -look.Z)
	end

	Remotes.DodgeState:FireServer(direction)
	-- TODO: play Dodge animation

	task.delay(CombatConfig.DodgeCooldown * 0.3, function()
		_isDodging = false
		if _state == "Dodging" then
			_state = "Idle"
		end
	end)

	task.delay(CombatConfig.DodgeCooldown, function()
		_dodgeCooldownReady = true
	end)
end

local function onCharacterStateChanged(player: Player, stateName: string, duration: number?): ()
	if player ~= localPlayer then return end

	local stunTime = if duration then duration else 0.3

	if stateName == "Stunned" then
		_state = "Stunned"
		-- TODO: play GetHit / StunnedLoop animation
		task.delay(stunTime, function()
			if _state == "Stunned" then
				_state = "Idle"
			end
		end)

	elseif stateName == "BlockBroken" then

		_isBlocking = false
		_state      = "Stunned"
		-- TODO: play BlockBreak → StunnedLoop animation sequence
		task.delay(if duration then duration else 0.8, function()
			if _state == "Stunned" then
				_state = "Idle"
			end
		end)
	end
end

local function onInputBegan(input: InputObject, gameProcessed: boolean): ()
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		fireNextComboHit()
		return
	end

	local keyCode = input.KeyCode

	if keyCode == Enum.KeyCode.LeftShift then
		startBlock()
	elseif keyCode == Enum.KeyCode.C then
		performDodge()
	end
end

local function onInputEnded(input: InputObject, _gameProcessed: boolean): ()
	if input.KeyCode == Enum.KeyCode.LeftShift then
		endBlock()
	end
end

local function setupCharacter(character: Model): ()
	_character          = character
	_hrp                = character:WaitForChild("HumanoidRootPart") :: BasePart
	_state              = "Idle"
	_comboIndex         = 0
	_isAttacking        = false
	_isBlocking         = false
	_isDodging          = false
	_dodgeCooldownReady = true
	cancelComboReset()
end

function CombatController.GetState(): CombatState
	return _state
end

function CombatController.SetLocked(locked: boolean): ()
	_state = if locked then "Locked" else "Idle"
end

function CombatController.Init(): ()
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
	Remotes.CharacterStateChanged:Connect(onCharacterStateChanged)

	local character = localPlayer.Character
	if character then
		setupCharacter(character)
	end

	localPlayer.CharacterAdded:Connect(function(char: Model)
		setupCharacter(char)
	end)
end

return CombatController
