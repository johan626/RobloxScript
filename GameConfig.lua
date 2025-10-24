-- GameConfig.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/GameConfig.lua
-- Script Place: ACT 1: Village

local config = {
	-- Pengaturan DataStore
	DataStore = {
		-- Lingkungan saat ini: "prod" untuk rilis, "dev" untuk pengujian
		Environment = "dev",
	},

	-- Pengaturan Gelombang (Wave)
	Wave = {
		-- Bonus yang diberikan kepada pemain yang bertahan hidup di akhir setiap gelombang
		BonusPoints = 100,
		-- Persentase heal yang diterima pemain di akhir setiap gelombang (0.1 = 10%)
		HealPercentage = 0.1,
		-- Pengganda jumlah zombi per pemain di setiap gelombang
		ZombiesPerWavePerPlayer = 5,
		-- Bonus poin yang diberikan saat mengalahkan bos
		BossKillBonus = 5000,
	},

	-- Pengaturan Gelombang Gelap (Dark Wave)
	DarkWave = {
		-- Gelombang gelap terjadi setiap kelipatan dari nilai ini (misal, 2 berarti di gelombang 2, 4, 6, ...)
		Interval = 2,
	},

	-- Pengaturan Bulan Darah (Blood Moon)
	BloodMoon = {
		-- Peluang terjadinya Blood Moon pada gelombang gelap (0.3 = 30%)
		Chance = 0.3,
		-- Pengganda jumlah zombie yang muncul saat Blood Moon (1.5 = 50% lebih banyak)
		SpawnMultiplier = 1.5,
	},

	-- Pengaturan Pencahayaan (Lighting)
	Lighting = {
		-- Pengaturan untuk suasana gelap
		DarkSettings = {
			Brightness = 0.25,
			ClockTime = 0,
			Ambient = Color3.new(0, 0, 0),
			OutdoorAmbient = Color3.new(0, 0, 0)
		},
		-- Pengaturan untuk suasana Blood Moon
		BloodSettings = {
			Brightness = 0.5,
			ClockTime = 2,
			Ambient = Color3.fromRGB(64, 0, 0),
			OutdoorAmbient = Color3.fromRGB(128, 0, 0)
		},
		-- Durasi transisi pencahayaan dalam detik
		TransitionDuration = 10,
	},
}

return config
