-- MPShopConfig.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/MPShopConfig.lua
-- Script Place: Lobby

local MPShopConfig = {
	Items = {
		XP_BOOSTER_30MIN = {
			ID = "XP_BOOSTER_30MIN",
			Name = "XP Booster (30 Menit)",
			Description = "Gandakan perolehan XP Anda dari semua sumber selama 30 menit waktu bermain.",
			MPCost = 2000,
			Type = "Consumable",
			Duration = 1800 -- Detik
		},
		COIN_BOOSTER_1GAME = {
			ID = "COIN_BOOSTER_1GAME",
			Name = "Coin Booster (1 Game)",
			Description = "Tingkatkan perolehan Koin Anda sebesar 50% untuk satu permainan berikutnya.",
			MPCost = 3000,
			Type = "Consumable"
		},
		DAILY_MISSION_REROLL = {
			ID = "DAILY_MISSION_REROLL",
			Name = "Daily Mission Reroll",
			Description = "Ganti salah satu misi harian Anda saat ini dengan yang baru secara acak.",
			MPCost = 500,
			Type = "Consumable"
		}
	}
}

return MPShopConfig
