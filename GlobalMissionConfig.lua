-- GlobalMissionConfig.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/GlobalMissionConfig.lua
-- Script Place: Lobby, ACT 1: Village

local GlobalMissionConfig = {}

--[[
    Struktur Misi Global:
    {
        ID = string (unik untuk setiap misi global),
        Description = string (deskripsi yang ditampilkan di papan misi),
        Type = string (tipe event yang dilacak, cth. "KILL", "WAVE_COMPLETE"),
        GlobalTarget = number (target kolektif untuk seluruh server),
        RewardTiers = table (daftar tingkatan hadiah berdasarkan kontribusi)
    }

    Struktur RewardTiers:
    {
        Contribution = number (jumlah kontribusi minimum untuk mendapatkan hadiah ini),
        Reward = {
            Type = string (tipe hadiah, cth. "MissionPoints"),
            Value = number (jumlah hadiah)
        }
    }
    PENTING: RewardTiers harus diurutkan dari kontribusi TERKECIL ke TERBESAR.
]]

GlobalMissionConfig.Missions = {
	{
		ID = "G_KILL_1",
		Description = "Seluruh komunitas harus mengalahkan 1.000.000 Zombi!",
		Type = "KILL",
		GlobalTarget = 1000000,
		RewardTiers = {
			{ Contribution = 100,  Reward = { Type = "MissionPoints", Value = 1000 } },
			{ Contribution = 500,  Reward = { Type = "MissionPoints", Value = 5500 } },
			{ Contribution = 1000, Reward = { Type = "MissionPoints", Value = 12000 } },
			{ Contribution = 2500, Reward = { Type = "MissionPoints", Value = 35000 } },
		}
	},
	{
		ID = "G_WAVE_COMPLETE_1",
		Description = "Selesaikan total 50.000 Gelombang di seluruh server!",
		Type = "WAVE_COMPLETE",
		GlobalTarget = 50000,
		RewardTiers = {
			{ Contribution = 10, Reward = { Type = "MissionPoints", Value = 2000 } },
			{ Contribution = 25, Reward = { Type = "MissionPoints", Value = 6000 } },
			{ Contribution = 50, Reward = { Type = "MissionPoints", Value = 15000 } },
		}
	},
	{
		ID = "G_HEADSHOT_1",
		Description = "Komunitas global: Dapatkan 500.000 Headshots!",
		Type = "HEADSHOT",
		GlobalTarget = 500000,
		RewardTiers = {
			{ Contribution = 200,  Reward = { Type = "MissionPoints", Value = 3000 } },
			{ Contribution = 500,  Reward = { Type = "MissionPoints", Value = 8000 } },
			{ Contribution = 1000, Reward = { Type = "MissionPoints", Value = 20000 } },
		}
	},
}

-- Pengaturan lainnya
GlobalMissionConfig.MISSION_DURATION = 7 * 24 * 60 * 60 -- Durasi misi dalam detik (7 hari)
GlobalMissionConfig.DATA_SCOPE = "Stats" -- Scope yang digunakan di DataStoreManager
GlobalMissionConfig.GLOBAL_DATA_KEY = "__GLOBAL_MISSION_STATE_V2__" -- Kunci unik untuk data global di dalam DataStore

return GlobalMissionConfig