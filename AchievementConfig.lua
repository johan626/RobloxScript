-- AchievementConfig.lua (ModuleScript) 
-- Path: ServerScriptService/ModuleScript/AchievementConfig.lua
-- Script Place: Lobby & ACT 1: Village

local ServerScriptService = game:GetService("ServerScriptService")
local RandomWeaponConfig = require(ServerScriptService.ModuleScript:WaitForChild("RandomWeaponConfig"))

local allAchievements = {}

-- Function to generate tiered achievements dynamically
local function generateTieredAchievements(achievements, config)
	for _, tier in ipairs(config.Tiers) do
		local achievement = {
			ID = string.format("%s_T%d", config.BaseID, tier.Tier),
			Name = tier.Name,
			Desc = string.format(config.Desc, tier.Target),
			Target = tier.Target,
			APReward = tier.APReward,
			Stat = config.Stat,
			Tier = tier.Tier,
			Title = tier.Title,
			Category = config.Category, -- Add category
		}
		table.insert(achievements, achievement)
	end
end

-- Function to generate weapon achievements dynamically
local function generateWeaponAchievements(achievements)
	local weaponTiers = {
		{ Target = 1000,    Title = "Specialist",   APReward = 100 },
		{ Target = 10000,   Title = "Expert",       APReward = 250 },
		{ Target = 100000,  Title = "Master",       APReward = 1000 },
		{ Target = 1000000, Title = "Legendary",  APReward = 5000 },
	}

	for _, weaponName in ipairs(RandomWeaponConfig.AvailableWeapons) do
		for i, tier in ipairs(weaponTiers) do
			local achievement = {
				ID = string.format("WEAPON_KILL_%s_T%d", weaponName:upper():gsub("-", "_"), i),
				Name = string.format("%s %s", tier.Title, weaponName),
				Desc = string.format("Defeat %s zombies using the %s.", tier.Target, weaponName),
				Target = tier.Target,
				APReward = tier.APReward,
				Weapon = weaponName,
				Tier = i,
				Title = string.format("%s %s", tier.Title, weaponName),
				Category = "Tempur", -- Add category
			}
			table.insert(achievements, achievement)
		end
	end
end

-- Configuration for Deadeye achievements
local deadeyeConfig = {
	BaseID = "DEADEYE",
	Stat = "Headshots",
	Category = "Tempur",
	Desc = "Get %s headshots.",
	Tiers = {
		{ Tier = 1, Name = "Sharpshooter", Title = "Sharpshooter", Target = 100,    APReward = 100 },
		{ Tier = 2, Name = "Deadeye",      Title = "Deadeye",      Target = 1000,   APReward = 250 },
		{ Tier = 3, Name = "Headhunter",   Title = "Headhunter",   Target = 10000,  APReward = 1000 },
		{ Tier = 4, Name = "Godlike Aim",  Title = "Godlike Aim",  Target = 100000, APReward = 5000 },
	}
}

-- Configuration for Survivor achievements
local survivorConfig = {
	BaseID = "SURVIVOR",
	Stat = "WavesSurvivedNoKnock",
	Category = "Ketahanan Hidup",
	Desc = "Selesaikan %s gelombang tanpa terkena knock down.",
	Tiers = {
		{ Tier = 1, Name = "Determined",  Title = "Determined",  Target = 10,  APReward = 150 },
		{ Tier = 2, Name = "Resilient",   Title = "Resilient",   Target = 25,  APReward = 300 },
		{ Tier = 3, Name = "Untouchable", Title = "Untouchable", Target = 50,  APReward = 750 },
		{ Tier = 4, Name = "The Legend",  Title = "The Legend",  Target = 100, APReward = 2000 },
	}
}

-- Configuration for Wave Conqueror achievements
local waveConquerorConfig = {
	BaseID = "WAVE_CONQUEROR",
	Stat = "TotalWavesCompleted",
	Category = "Ketahanan Hidup",
	Desc = "Selesaikan total %s gelombang zombi.",
	Tiers = {
		{ Tier = 1, Name = "Rookie Conqueror",    Title = "Rookie Conqueror",    Target = 100,   APReward = 100 },
		{ Tier = 2, Name = "Hardened Conqueror",  Title = "Hardened Conqueror",  Target = 500,   APReward = 250 },
		{ Tier = 3, Name = "Veteran Conqueror",   Title = "Veteran Conqueror",   Target = 1000,  APReward = 500 },
		{ Tier = 4, Name = "Legendary Conqueror", Title = "Legendary Conqueror", Target = 5000,  APReward = 1000 },
	}
}

-- Configuration for Coin Collector achievements
local coinCollectorConfig = {
	BaseID = "COIN_COLLECTOR",
	Stat = "TotalCoinsCollected",
	Category = "Koleksi",
	Desc = "Kumpulkan total %s koin.",
	Tiers = {
		{ Tier = 1, Name = "Thrifty",     Title = "Thrifty",     Target = 100000,   APReward = 100 },
		{ Tier = 2, Name = "Investor",    Title = "Investor",    Target = 500000,   APReward = 250 },
		{ Tier = 3, Name = "Millionaire", Title = "Millionaire", Target = 1000000,  APReward = 500 },
		{ Tier = 4, Name = "The Magnate", Title = "The Magnate", Target = 10000000, APReward = 1000 },
	}
}

-- Configuration for Boss Hunter achievements
local bossHunterConfig = {
	BaseID = "BOSS_HUNTER",
	Stat = "BossKills",
	Category = "Progresi",
	Desc = "Kalahkan total %s bos.",
	Tiers = {
		{ Tier = 1, Name = "Boss Hunter",   Title = "Boss Hunter",   Target = 10,   APReward = 150 },
		{ Tier = 2, Name = "Elite Hunter",  Title = "Elite Hunter",  Target = 50,   APReward = 300 },
		{ Tier = 3, Name = "Master Hunter", Title = "Master Hunter", Target = 150,  APReward = 750 },
		{ Tier = 4, Name = "The Dominator", Title = "The Dominator", Target = 500,  APReward = 2000 },
	}
}

-- Configuration for Gacha Enthusiast achievements
local gachaEnthusiastConfig = {
	BaseID = "GACHA_ENTHUSIAST",
	Stat = "GachaSpins",
	Category = "Koleksi",
	Desc = "Lakukan spin gacha sebanyak %s kali.",
	Tiers = {
		{ Tier = 1, Name = "Gambler",        Title = "Gambler",        Target = 50,    APReward = 100 },
		{ Tier = 2, Name = "High Roller",    Title = "High Roller",    Target = 250,   APReward = 250 },
		{ Tier = 3, Name = "Gacha Addict",   Title = "Gacha Addict",   Target = 1000,  APReward = 500 },
		{ Tier = 4, Name = "King of Chance", Title = "King of Chance", Target = 5000,  APReward = 1000 },
	}
}

-- Configuration for Mission Accomplished achievements
local missionAccomplishedConfig = {
	BaseID = "MISSION_ACCOMPLISHED",
	Stat = "MissionsCompleted",
	Category = "Progresi",
	Desc = "Selesaikan total %s misi.",
	Tiers = {
		{ Tier = 1, Name = "Operative",       Title = "Operative",       Target = 50,    APReward = 100 },
		{ Tier = 2, Name = "Specialist",      Title = "Specialist",      Target = 200,   APReward = 250 },
		{ Tier = 3, Name = "Elite Operative", Title = "Elite Operative", Target = 500,   APReward = 500 },
		{ Tier = 4, Name = "Master of Tasks", Title = "Master of Tasks", Target = 1500,  APReward = 1000 },
	}
}

-- Configuration for Master Tactician achievements
local masterTacticianConfig = {
	BaseID = "MASTER_TACTICIAN",
	Stat = "BoostersUsed",
	Category = "Progresi",
	Desc = "Gunakan total %s booster untuk membantumu dalam pertempuran.",
	Tiers = {
		{ Tier = 1, Name = "Tactician",        Title = "Tactician",        Target = 50,    APReward = 100 },
		{ Tier = 2, Name = "Strategist",       Title = "Strategist",       Target = 200,   APReward = 250 },
		{ Tier = 3, Name = "Master Tactician", Title = "Master Tactician", Target = 500,   APReward = 500 },
		{ Tier = 4, Name = "The Grandmaster",  Title = "The Grandmaster",  Target = 1500,  APReward = 1000 },
	}
}

-- Configuration for Living Legend achievements
local livingLegendConfig = {
	BaseID = "LIVING_LEGEND",
	Stat = "PlayerLevel",
	Category = "Progresi",
	Desc = "Capai level pemain %s.",
	Tiers = {
		{ Tier = 1, Name = "Rising Star",    Title = "Rising Star",    Target = 50,   APReward = 150 },
		{ Tier = 2, Name = "Veteran",        Title = "Veteran",        Target = 100,  APReward = 300 },
		{ Tier = 3, Name = "Elite",          Title = "Elite",          Target = 250,  APReward = 750 },
		{ Tier = 4, Name = "Living Legend",  Title = "Living Legend",  Target = 500,  APReward = 2000 },
	}
}

-- Configuration for Zombie Slayer achievements
local zombieSlayerConfig = {
	BaseID = "ZOMBIE_SLAYER",
	Stat = "TotalKills",
	Category = "Tempur",
	Desc = "Kalahkan total %s zombi.",
	Tiers = {
		{ Tier = 1, Name = "Zombie Slayer",      Title = "Zombie Slayer",      Target = 5000,    APReward = 100 },
		{ Tier = 2, Name = "Zombie Executioner", Title = "Zombie Executioner", Target = 25000,   APReward = 250 },
		{ Tier = 3, Name = "Zombie Annihilator", Title = "Zombie Annihilator", Target = 100000,  APReward = 500 },
		{ Tier = 4, Name = "The Apocalypse",     Title = "The Apocalypse",     Target = 500000,  APReward = 1000 },
	}
}

-- Configuration for War Machine achievements
local warMachineConfig = {
	BaseID = "WAR_MACHINE",
	Stat = "TotalDamageDealt",
	Category = "Tempur",
	Desc = "Berikan total %s kerusakan pada zombi.",
	Tiers = {
		{ Tier = 1, Name = "Brawler",       Title = "Brawler",       Target = 5000000,    APReward = 100 },
		{ Tier = 2, Name = "Ravager",       Title = "Ravager",       Target = 25000000,   APReward = 250 },
		{ Tier = 3, Name = "Juggernaut",    Title = "Juggernaut",    Target = 100000000,  APReward = 500 },
		{ Tier = 4, Name = "War Machine",   Title = "War Machine",   Target = 500000000,  APReward = 1000 },
	}
}

-- Generate all achievements
generateTieredAchievements(allAchievements, deadeyeConfig)
generateTieredAchievements(allAchievements, warMachineConfig)
generateTieredAchievements(allAchievements, survivorConfig)
generateTieredAchievements(allAchievements, waveConquerorConfig)
generateTieredAchievements(allAchievements, coinCollectorConfig)
generateTieredAchievements(allAchievements, bossHunterConfig)
generateTieredAchievements(allAchievements, gachaEnthusiastConfig)
generateTieredAchievements(allAchievements, missionAccomplishedConfig)
generateTieredAchievements(allAchievements, zombieSlayerConfig)
generateTieredAchievements(allAchievements, masterTacticianConfig)
generateTieredAchievements(allAchievements, livingLegendConfig)
generateWeaponAchievements(allAchievements)

return allAchievements