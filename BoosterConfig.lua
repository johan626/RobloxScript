-- BoosterConfig.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BoosterConfig.lua
-- Script Place: Lobby

local BoosterConfig = {
	SelfRevive = {
		Name = "Self Revive",
		Price = 250,
		Icon = "SR",
		Description = "Gives you a chance to revive yourself upon being knocked down."
	},
	StarterPoints = {
		Name = "Starter Points",
		Price = 350,
		Icon = "SP",
		Description = "Gives you 1500 starting points."
	},
	CouponDiscount = {
		Name = "50% Discount Coupon",
		Price = 350,
		Icon = "50%",
		Description = "Activate to get a 50% discount on your next vending machine purchase."
	},
	StartingShield = {
		Name = "Starting Shield",
		Price = 350,
		Icon = "SH",
		Description = "Gain a 50% health shield at the start of the game."
	},
	LegionsLegacy = {
		Name = "Legion's Legacy",
		Price = 400,
		Icon = "LL",
		Description = "Replaces your starter weapon (M1911) with one random weapon from the entire list of available weapons in RandomWeapon."
	}
}

return BoosterConfig
