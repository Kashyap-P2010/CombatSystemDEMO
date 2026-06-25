--!strict


local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Remotes     = require(Shared.Remotes.RemoteDefinitions)
local SkillConfig = require(Shared.Config.SkillConfig)


local _cooldownEndTimes: { [number]: { [number]: number } } = {}


local function isOnCooldown(userId: number, slotIndex: number): boolean
	local playerCDs = _cooldownEndTimes[userId]
	if not playerCDs then return false end
	local endTime = playerCDs[slotIndex]
	if not endTime then return false end
	return os.clock() < endTime
end

local function startCooldown(userId: number, slotIndex: number, duration: number): ()
	if not _cooldownEndTimes[userId] then
		_cooldownEndTimes[userId] = {}
	end
	_cooldownEndTimes[userId][slotIndex] = os.clock() + duration
end

local function findSkillTargets(origin: Vector3, range: number, caster: Player): { Model }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local excluded: { Instance } = {}
	if caster.Character then
		table.insert(excluded, caster.Character)
	end
	params.FilterDescendantsInstances = excluded

	local parts = workspace:GetPartBoundsInRadius(origin, range, params)

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


local function onUseSkill(player: Player, slotIndex: number): ()
	if typeof(slotIndex) ~= "number" then return end
	if slotIndex < 1 or slotIndex > #SkillConfig.Skills then return end

	local userId = player.UserId

	if isOnCooldown(userId, slotIndex) then
		warn(`[SkillService] {player.Name} tried skill {slotIndex} while on cooldown`)
		return
	end

	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local skill = SkillConfig.Skills[slotIndex]

	startCooldown(userId, slotIndex, skill.Cooldown)

	local targets = findSkillTargets(hrp.Position, skill.Range, player)

	for _, targetChar in targets do
		local humanoid = targetChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
		if not humanoid or humanoid.Health <= 0 then continue end

		humanoid:TakeDamage(skill.Damage)

		local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
		if targetPlayer then
			Remotes.CharacterStateChanged:FireClient(targetPlayer, targetPlayer, "Stunned", 0.5)
		end
	end

	-- TODO: broadcast skill.VFXTag via CollectionService to all clients
end


local function onPlayerRemoving(player: Player): ()
	_cooldownEndTimes[player.UserId] = nil
end


local SkillService = {}

function SkillService.Init(): ()
	Remotes.UseSkill:Connect(onUseSkill)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return SkillService
