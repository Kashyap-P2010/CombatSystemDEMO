--!strict


export type HitData = {
	Damage        : number,
	HitboxSize    : Vector3,
	HitboxOffset  : Vector3,
	StunDuration  : number,
	ComboWindow   : number,
	AnimName      : string,    -- TODO: animator fills in actual AnimationId
}

local CombatConfig = {}


CombatConfig.Combo: { HitData } = {
	{
		Damage       = 8,
		HitboxSize   = Vector3.new(4, 4, 4),
		HitboxOffset = Vector3.new(0, 0, -3),
		StunDuration = 0.15,
		ComboWindow  = 0.70,
		AnimName     = "M1",  -- TODO
	},
	{
		Damage       = 8,
		HitboxSize   = Vector3.new(4, 4, 4),
		HitboxOffset = Vector3.new(0, 0, -3),
		StunDuration = 0.15,
		ComboWindow  = 0.70,
		AnimName     = "M2",  -- TODO
	},
	{
		Damage       = 12,
		HitboxSize   = Vector3.new(5, 4, 5),
		HitboxOffset = Vector3.new(0, 0, -3.5),
		StunDuration = 0.20,
		ComboWindow  = 0.75,
		AnimName     = "M3",  -- TODO
	},
	{
		Damage       = 20,
		HitboxSize   = Vector3.new(6, 5, 6),
		HitboxOffset = Vector3.new(0, 0, -4),
		StunDuration = 0.55,
		ComboWindow  = 0,
		AnimName     = "M4",  -- TODO
	},
}

CombatConfig.ComboResetTime       = 1.2


CombatConfig.BlockBreakThreshold  = 30
CombatConfig.BlockDamageReduction = 0.80


CombatConfig.DodgeCooldown        = 0.80
CombatConfig.DodgeIFrames         = 0.20
CombatConfig.DodgeForce           = 55


CombatConfig.MaxHitDistance       = 12

return CombatConfig
