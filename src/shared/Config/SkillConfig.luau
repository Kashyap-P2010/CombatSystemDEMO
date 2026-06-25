--!strict

export type SkillData = {
	Name      : string,
	Cooldown  : number,
	Damage    : number,
	Range     : number,
	AnimName  : string,   -- TODO: animator fills in actual AnimationId
	VFXTag    : string,   -- TODO: CollectionService tag for VFX handler
	IsAwaken  : boolean,
}

local SkillConfig = {}

SkillConfig.Skills: { SkillData } = {

	{
		Name     = "Spin Kick",
		Cooldown = 8,
		Damage   = 25,
		Range    = 6,
		AnimName = "Skill1",     -- TODO
		VFXTag   = "VFX_Skill1", -- TODO
		IsAwaken = false,
	},

	{
		Name     = "Double Power Punch",
		Cooldown = 10,
		Damage   = 35,
		Range    = 5,
		AnimName = "Skill2",     -- TODO
		VFXTag   = "VFX_Skill2", -- TODO
		IsAwaken = false,
	},

	{
		Name     = "Kick Combo",
		Cooldown = 12,
		Damage   = 30,
		Range    = 6,
		AnimName = "Skill3",     -- TODO
		VFXTag   = "VFX_Skill3", -- TODO
		IsAwaken = false,
	},

	{
		Name     = "Ultra Power Punch",
		Cooldown = 15,
		Damage   = 55,
		Range    = 5,
		AnimName = "Skill4",     -- TODO
		VFXTag   = "VFX_Skill4", -- TODO
		IsAwaken = false,
	},

	{
		Name     = "Awaken",
		Cooldown = 60,
		Damage   = 80,
		Range    = 8,
		AnimName = "Awaken",     -- TODO
		VFXTag   = "VFX_Awaken", -- TODO
		IsAwaken = true,
	},
}

SkillConfig.KeyBinds: { [number]: Enum.KeyCode } = {
	[1] = Enum.KeyCode.Q,
	[2] = Enum.KeyCode.E,
	[3] = Enum.KeyCode.R,
	[4] = Enum.KeyCode.F,
	[5] = Enum.KeyCode.G,
}

SkillConfig.AwakenHoldTime = 1.0

return SkillConfig
