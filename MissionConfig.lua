-- MissionConfig.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/MissionConfig.lua
-- Script Place: Lobby, ACT 1: Village

local MissionConfig = {}

--[[
    Struktur Misi:
    {
        ID = string (unik),
        Description = string (deskripsi untuk ditampilkan di UI),
        Type = string (tipe misi, cth. "KILL_ZOMBIES", "COMPLETE_WAVES"),
        Target = number (jumlah yang harus dicapai),
        Reward = {
            Type = "MissionPoints",
            Value = number
        }
    }
]]

-- ==================================================
-- PENGATURAN MISI
-- ==================================================
MissionConfig.DailyMissionCount = 3
MissionConfig.WeeklyMissionCount = 3

-- ==================================================
-- DAFTAR MISI HARIAN
-- ==================================================
MissionConfig.DailyMissions = {
	{ ID = "D_COMPLETE_WAVES_EASY", Description = "Selesaikan 3 Gelombang", Type = "WAVE_COMPLETE", Target = 3, Reward = { Type = "MissionPoints", Value = 100 } },
	{ ID = "D_KILL_ZOMBIES_EASY", Description = "Kalahkan 75 Zombie", Type = "ZOMBIE_KILL", Target = 75, Reward = { Type = "MissionPoints", Value = 150 } },
	{ ID = "D_GET_HEADSHOTS_EASY", Description = "Dapatkan 25 Headshot", Type = "HEADSHOT", Target = 25, Reward = { Type = "MissionPoints", Value = 200 } },
	{ ID = "D_KILL_ZOMBIES_MEDIUM", Description = "Kalahkan 150 Zombie", Type = "ZOMBIE_KILL", Target = 150, Reward = { Type = "MissionPoints", Value = 250 } },
	{ ID = "D_USE_BOOSTERS", Description = "Gunakan 2 Booster", Type = "USE_BOOSTER", Target = 2, Reward = { Type = "MissionPoints", Value = 300 } },
	{ ID = "D_KILL_SMG", Description = "Kalahkan 100 Zombie dengan SMG", Type = "ZOMBIE_KILL", WeaponType = "SMG", Target = 100, Reward = { Type = "MissionPoints", Value = 350 } },
	{ ID = "D_GET_HEADSHOTS_HARD", Description = "Dapatkan 50 Headshot", Type = "HEADSHOT", Target = 50, Reward = { Type = "MissionPoints", Value = 400 } },
	{ ID = "D_REVIVE_TEAMMATES", Description = "Revive 3 rekan tim", Type = "REVIVE_PLAYER", Target = 3, Reward = { Type = "MissionPoints", Value = 400 } },
	{ ID = "D_COMPLETE_GAME_EASY", Description = "Selesaikan 1 permainan (minimal 10 gelombang)", Type = "GAME_COMPLETE", Target = 1, Reward = { Type = "MissionPoints", Value = 500 } },
	{ ID = "D_KILL_SPECIAL_ZOMBIES", Description = "Kalahkan 10 Zombie Spesial (Tank/Shooter)", Type = "KILL_SPECIAL", Target = 10, Reward = { Type = "MissionPoints", Value = 500 } },
}

-- ==================================================
-- DAFTAR MISI MINGGUAN
-- ==================================================
MissionConfig.WeeklyMissions = {
	{ ID = "W_COMPLETE_WAVES_MEDIUM", Description = "Selesaikan 25 Gelombang", Type = "WAVE_COMPLETE", Target = 25, Reward = { Type = "MissionPoints", Value = 750 } },
	{ ID = "W_KILL_ZOMBIES_HARD", Description = "Kalahkan 1000 Zombie", Type = "ZOMBIE_KILL", Target = 1000, Reward = { Type = "MissionPoints", Value = 1000 } },
	{ ID = "W_GET_HEADSHOTS_MEDIUM", Description = "Dapatkan 250 Headshot", Type = "HEADSHOT", Target = 250, Reward = { Type = "MissionPoints", Value = 1250 } },
	{ ID = "W_KILL_BOSS", Description = "Kalahkan 3 Boss", Type = "BOSS_KILL", Target = 3, Reward = { Type = "MissionPoints", Value = 1500 } },
	{ ID = "W_COMPLETE_GAME_HARD", Description = "Selesaikan 1 permainan di kesulitan Hard atau lebih tinggi", Type = "GAME_COMPLETE_HARD", Target = 1, Reward = { Type = "MissionPoints", Value = 2000 } },
	{ ID = "W_KILL_LMG", Description = "Kalahkan 500 Zombie dengan LMG", Type = "ZOMBIE_KILL", WeaponType = "LMG", Target = 500, Reward = { Type = "MissionPoints", Value = 1500 } },
	{ ID = "W_NO_KNOCK_WAVES", Description = "Selesaikan 10 gelombang berturut-turut tanpa jatuh", Type = "NO_KNOCK_STREAK", Target = 10, Reward = { Type = "MissionPoints", Value = 1750 } },
	{ ID = "W_SPEND_COINS", Description = "Belanjakan 50,000 Koin", Type = "SPEND_COINS", Target = 50000, Reward = { Type = "MissionPoints", Value = 1000 } },
	{ ID = "W_EARN_AP", Description = "Dapatkan 1000 Achievement Points", Type = "EARN_AP", Target = 1000, Reward = { Type = "MissionPoints", Value = 1500 } },
	{ ID = "W_DEAL_DAMAGE", Description = "Berikan total 5,000,000 kerusakan", Type = "DEAL_DAMAGE", Target = 5000000, Reward = { Type = "MissionPoints", Value = 2000 } },
}

return MissionConfig
