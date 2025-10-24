-- GachaConfig.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/GachaConfig.lua
-- Script Place: Lobby

local GachaConfig = {
	GACHA_COST = 100,

	RARITY_CHANCES = {
		Legendary = 5,  -- Chance in percent (5%)
		Booster = 10, -- Chance in percent (10%)
		Common = 85, -- Chance in percent (85%)
	},

	COMMON_REWARD_RANGE = {
		Min = 10, 
		Max = 50
	},

	PITY_THRESHOLD = 50, -- The number of rolls to guarantee a Legendary prize

	-- Multi-Roll Settings
	MULTI_ROLL_COST_MULTIPLIER = 10, -- The player pays for this many rolls
	MULTI_ROLL_COUNT = 11 -- The player receives this many rolls (10 + 1 free)
}

return GachaConfig
