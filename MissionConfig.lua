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
	{
		ID = "D_KILL_ZOMBIES_1",
		Description = "Kalahkan 50 Zombie",
		Type = "KILL_ZOMBIES",
		Target = 50,
		Reward = { Type = "MissionPoints", Value = 100 }
	},
	{
		ID = "D_COMPLETE_WAVES_1",
		Description = "Selesaikan 3 Gelombang",
		Type = "COMPLETE_WAVES",
		Target = 3,
		Reward = { Type = "MissionPoints", Value = 150 }
	},
	{
		ID = "D_KILL_ZOMBIES_2",
		Description = "Kalahkan 100 Zombie",
		Type = "KILL_ZOMBIES",
		Target = 100,
		Reward = { Type = "MissionPoints", Value = 200 }
	},
	{
		ID = "D_KILL_AR_1",
		Description = "Kalahkan 75 Zombie dengan Assault Rifle",
		Type = "KILL_WITH_WEAPON_TYPE",
		WeaponType = "Assault Rifle",
		Target = 75,
		Reward = { Type = "MissionPoints", Value = 300 }
	},
	{
		ID = "D_HEADSHOT_PISTOL_1",
		Description = "Dapatkan 25 Headshot dengan Pistol",
		Type = "GET_HEADSHOTS_WITH_WEAPON_TYPE",
		WeaponType = "Pistol",
		Target = 25,
		Reward = { Type = "MissionPoints", Value = 350 }
	},
}

-- ==================================================
-- DAFTAR MISI MINGGUAN
-- ==================================================
MissionConfig.WeeklyMissions = {
	{
		ID = "W_KILL_ZOMBIES_1",
		Description = "Kalahkan 500 Zombie",
		Type = "KILL_ZOMBIES",
		Target = 500,
		Reward = { Type = "MissionPoints", Value = 750 }
	},
	{
		ID = "W_COMPLETE_WAVES_1",
		Description = "Selesaikan 15 Gelombang",
		Type = "COMPLETE_WAVES",
		Target = 15,
		Reward = { Type = "MissionPoints", Value = 1000 }
	},
	{
		ID = "W_KILL_BOSS_1",
		Description = "Kalahkan Boss 'Brute'",
		Type = "KILL_BOSS",
		Target = 1,
		Reward = { Type = "MissionPoints", Value = 1500 }
	},
	{
		ID = "W_KILL_SHOTGUN_1",
		Description = "Kalahkan 300 Zombie dengan Shotgun",
		Type = "KILL_WITH_WEAPON_TYPE",
		WeaponType = "Shotgun",
		Target = 300,
		Reward = { Type = "MissionPoints", Value = 1200 }
	},
	{
		ID = "W_HEADSHOT_SNIPER_1",
		Description = "Dapatkan 100 Headshot dengan Sniper Rifle",
		Type = "GET_HEADSHOTS_WITH_WEAPON_TYPE",
		WeaponType = "Sniper Rifle",
		Target = 100,
		Reward = { Type = "MissionPoints", Value = 1500 }
	},
}

return MissionConfig
