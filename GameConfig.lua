-- GameConfig.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/GameConfig.lua
-- Script Place: Lobby, ACT 1: Village

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
		Chance = 0.2 ,
		-- Pengganda jumlah zombie yang muncul saat Blood Moon (1.5 = 50% lebih banyak)
		SpawnMultiplier = 1.5,
	},

	-- Pengaturan Gelombang Spesial Baru
	FastWave = {
		-- Peluang terjadinya gelombang ini (0.15 = 15%)
		Chance = 0.2,
		-- Pengganda kecepatan untuk semua zombi
		SpeedMultiplier = 1.2,
	},

	SpecialWave = {
		-- Peluang terjadinya gelombang ini (0.15 = 15%)
		Chance = 0.2,
		-- Tipe zombi yang diizinkan untuk spawn
		AllowedTypes = {"Runner", "Shooter", "Tank"},
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

	-- Pengaturan Senjata Acak
	RandomWeapon = {
		BaseCost = 750,
		CostIncrease = 50, -- Jumlah kenaikan harga setiap pembelian
	},

	-- Pengaturan Ekonomi
	Economy = {
		-- Pengganda untuk menghitung BP yang didapat dari kerusakan (misal: 1 damage * 0.5 = 0.5 BP)
		BP_Per_Damage_Multiplier = 0.5,

		-- Pengaturan Ekonomi Koin (Mata Uang Permanen)
		Coins = {
			-- Bonus koin tetap yang diberikan di akhir setiap gelombang
			WaveCompleteBonus = 50,
			-- Rasio konversi kerusakan menjadi koin. Formula: Kerusakan / Rasio.
			-- Rasio ini akan dikalikan dengan HealthMultiplier tingkat kesulitan untuk menyeimbangkan.
			DamageToCoinConversionRatio = 20,
			-- Pengganda hadiah koin berdasarkan tingkat kesulitan. Diterapkan SETELAH perhitungan dasar.
			DifficultyCoinMultipliers = {
				Easy = 1,
				Normal = 1.2,
				Hard = 1.5,
				Expert = 2,
				Hell = 2.5,
				Crazy = 3,
			}
		}
	},

	-- Pengaturan Tingkat Kesulitan
	Difficulty = {
		Easy = {
			HealthMultiplier = 1,
			DamageMultiplier = 1,
			Rules = {
				FriendlyFire = false,
				IncreaseRandomWeaponCost = false,
				MaxPerks = 3,
				AllowRevive = true,
			}
		},
		Normal = {
			HealthMultiplier = 1.5,
			DamageMultiplier = 1.5,
			Rules = {
				FriendlyFire = false,
				IncreaseRandomWeaponCost = false,
				MaxPerks = 3,
				AllowRevive = true,
			}
		},
		Hard = {
			HealthMultiplier = 2,
			DamageMultiplier = 2,
			Rules = {
				FriendlyFire = true,
				IncreaseRandomWeaponCost = false,
				MaxPerks = 3,
				AllowRevive = true,
			}
		},
		Expert = {
			HealthMultiplier = 3,
			DamageMultiplier = 3,
			Rules = {
				FriendlyFire = true,
				IncreaseRandomWeaponCost = true,
				MaxPerks = 3,
				AllowRevive = true,
			}
		},
		Hell = {
			HealthMultiplier = 5,
			DamageMultiplier = 5,
			Rules = {
				FriendlyFire = true,
				IncreaseRandomWeaponCost = true,
				MaxPerks = 2,
				AllowRevive = true,
			}
		},
		Crazy = {
			HealthMultiplier = 10,
			DamageMultiplier = 10,
			Rules = {
				FriendlyFire = true,
				IncreaseRandomWeaponCost = true,
				MaxPerks = 1,
				AllowRevive = false,
			}
		},
	},
}

return config
