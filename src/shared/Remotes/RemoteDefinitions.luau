--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

type RemoteMap = {

	CombatHit             : RemoteEvent,
	BlockState            : RemoteEvent,
	DodgeState            : RemoteEvent,

	UseSkill              : RemoteEvent,

	CharacterStateChanged : RemoteEvent,
}

local function getOrCreate(parent: Instance, name: string, className: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local inst    = Instance.new(className)
	inst.Name     = name
	inst.Parent   = parent
	return inst
end

local remoteFolder = getOrCreate(ReplicatedStorage, "Remotes", "Folder")

local Remotes: RemoteMap = {

	CombatHit             = getOrCreate(remoteFolder, "CombatHit",             "RemoteEvent") :: RemoteEvent,
	BlockState            = getOrCreate(remoteFolder, "BlockState",            "RemoteEvent") :: RemoteEvent,
	DodgeState            = getOrCreate(remoteFolder, "DodgeState",            "RemoteEvent") :: RemoteEvent,

	UseSkill              = getOrCreate(remoteFolder, "UseSkill",              "RemoteEvent") :: RemoteEvent,

	CharacterStateChanged = getOrCreate(remoteFolder, "CharacterStateChanged", "RemoteEvent") :: RemoteEvent,
}

return Remotes
