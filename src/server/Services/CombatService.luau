--!strict


local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Remotes      = require(Shared.Remotes.RemoteDefinitions)
local CombatConfig = require(Shared.Config.CombatConfig)


type BlockState = {
	IsBlocking     : boolean,
	DamageAbsorbed : number,
}


local _blockStates: { [number]: BlockState } = {}


local function getBlockState(userId: number): BlockState
	if not _blockStates[userId] then
		_blockStates[userId] = { IsBlocking = false, DamageAbsorbed = 0 }
	end
	return _blockStates[userId]
end

local function applyDamage(targetCharacter: Model, amount: number): ()
	local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	if humanoid.Health <= 0 then return end
	humanoid:TakeDamage(amount)
end

local function replicateState(player: Player, stateName: string, duration: number?): ()
	Remotes.CharacterStateChanged:FireClient(player, player, stateName, duration)
end


local function validateHitDistance(attackerHRP: BasePart, reportedCF: CFrame): boolean
	local dist = (attackerHRP.Position - reportedCF.Position).Magnitude
	return dist <= CombatConfig.MaxHitDistance
end

local function findHitTargets(hitboxCF: CFrame, hitboxSize: Vector3, attacker: Player): { Model }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local excluded: { Instance } = {}
	if attacker.Character then
		table.insert(excluded, attacker.Character)
	end
	params.FilterDescendantsInstances = excluded

	local parts = workspace:GetPartBoundsInBox(hitboxCF, hitboxSize, params)

	local hits: { Model } = {}
	local seen: { [Model]: boolean } = {}

	for _, part in parts do
		local model    = part:FindFirstAncestorOfClass("Model")
		if not model or seen[model] then continue end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then continue end
		seen[model] = true
		table.insert(hits, model)
	end

	return hits
end


local function onCombatHit(attacker: Player, comboIndex: number, hitboxCF: CFrame, hitboxSize: Vector3): ()
	if typeof(comboIndex)  ~= "number"  then return end
	if typeof(hitboxCF)    ~= "CFrame"  then return end
	if typeof(hitboxSize)  ~= "Vector3" then return end

	if comboIndex < 1 or comboIndex > #CombatConfig.Combo then return end

	local attackerChar = attacker.Character
	if not attackerChar then return end

	local attackerHRP = attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not attackerHRP then return end

	if not validateHitDistance(attackerHRP, hitboxCF) then
		warn(`[CombatService] rejected hit from {attacker.Name} — hitbox too far (combo {comboIndex})`)
		return
	end

	local hitData = CombatConfig.Combo[comboIndex]
	local targets = findHitTargets(hitboxCF, hitboxSize, attacker)

	for _, targetChar in targets do
		local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
		local userId       = if targetPlayer then targetPlayer.UserId else -1
		local blockState   = getBlockState(userId)

		local finalDamage = hitData.Damage

		if blockState.IsBlocking then
			finalDamage = math.floor(finalDamage * (1 - CombatConfig.BlockDamageReduction))
			blockState.DamageAbsorbed += hitData.Damage

			if blockState.DamageAbsorbed >= CombatConfig.BlockBreakThreshold then
				blockState.IsBlocking     = false
				blockState.DamageAbsorbed = 0
				applyDamage(targetChar, finalDamage)
				if targetPlayer then
					replicateState(targetPlayer, "BlockBroken", 0.8)
				end
				continue
			end
		end

		applyDamage(targetChar, finalDamage)

		if targetPlayer then
			replicateState(targetPlayer, "Stunned", hitData.StunDuration)
		end
	end
end

local function onBlockState(player: Player, isBlocking: boolean): ()
	if typeof(isBlocking) ~= "boolean" then return end
	local state      = getBlockState(player.UserId)
	state.IsBlocking = isBlocking
	if not isBlocking then
		state.DamageAbsorbed = 0
	end
end

local function onDodgeState(player: Player, direction: Vector3): ()
	if typeof(direction) ~= "Vector3" then return end

	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude > 0 then
		flat = flat.Unit
	else
		flat = -hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
	end

	hrp.AssemblyLinearVelocity = flat * CombatConfig.DodgeForce
end


local function onPlayerRemoving(player: Player): ()
	_blockStates[player.UserId] = nil
end


local CombatService = {}

function CombatService.Init(): ()
	Remotes.CombatHit:Connect(onCombatHit)
	Remotes.BlockState:Connect(onBlockState)
	Remotes.DodgeState:Connect(onDodgeState)

	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return CombatService
