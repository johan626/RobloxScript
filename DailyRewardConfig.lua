-- DailyRewardConfig.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/DailyRewardConfig.lua
-- Script Place: Lobby

local DailyRewardConfig = {}

--[[
    Struktur Hadiah:
    {
        Type = "Coins" | "Booster" | "Skin",
        Value = number (untuk Koin) | string (nama Booster) | "Random" (untuk Skin)
    }
]]

DailyRewardConfig.Rewards = {
	-- Minggu 1
	{ Type = "Coins", Value = 250 },
	{ Type = "Booster", Value = "StarterPoints" },
	{ Type = "Coins", Value = 500 },
	{ Type = "Mystery" }, -- Hari ke-4
	{ Type = "Coins", Value = 750 },
	{ Type = "Booster", Value = "StarterPoints" },
	{ Type = "Skin", Value = "Random" }, -- Hari ke-7

	-- Minggu 2
	{ Type = "Coins", Value = 1000 },
	{ Type = "Booster", Value = "StartingShield" },
	{ Type = "Coins", Value = 1250 },
	{ Type = "Mystery" }, -- Hari ke-11
	{ Type = "Coins", Value = 1500 },
	{ Type = "Booster", Value = "StartingShield" },
	{ Type = "Skin", Value = "Random" }, -- Hari ke-14

	-- Minggu 3
	{ Type = "Coins", Value = 1750 },
	{ Type = "Booster", Value = "StarterPoints" },
	{ Type = "Coins", Value = 2000 },
	{ Type = "Mystery" }, -- Hari ke-18
	{ Type = "Coins", Value = 2250 },
	{ Type = "Booster", Value = "StarterPoints" },
	{ Type = "Skin", Value = "Random" }, -- Hari ke-21

	-- Minggu 4
	{ Type = "Coins", Value = 2500 },
	{ Type = "Booster", Value = "StartingShield" },
	{ Type = "Coins", Value = 2750 },
	{ Type = "Mystery" }, -- Hari ke-25
	{ Type = "Coins", Value = 3000 },
	{ Type = "Booster", Value = "StartingShield" },
	{ Type = "Skin", Value = "Random" } -- Hari ke-28
}

--[[
    Kumpulan hadiah yang mungkin untuk tipe "Misteri".
    Struktur sama seperti hadiah biasa.
]]
DailyRewardConfig.MysteryRewards = {
	{ Type = "Coins", Value = 500 },
	{ Type = "Coins", Value = 1000 },
	{ Type = "Coins", Value = 2500 },
	{ Type = "Booster", Value = "StarterPoints" },
	{ Type = "Booster", Value = "StartingShield" },
	{ Type = "Skin", Value = "Random" } -- Skin juga bisa didapat dari kotak misteri
}

return DailyRewardConfig
