-- LevelModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/LevelModule.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

-- Modul lain
local SkillModule = require(script.Parent:WaitForChild("SkillModule"))
local AchievementManager = require(script.Parent:WaitForChild("AchievementManager"))

local LevelManager = {}

-- RemoteEvent
local LevelUpdateEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("LevelUpdateEvent") or Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
LevelUpdateEvent.Name = "LevelUpdateEvent"

-- Struktur data default untuk level (bagian dari Stats)
local DEFAULT_LEVEL_DATA = {
	Level = 1,
	XP = 0
}

-- =============================================================================
-- FUNGSI INTI
-- =============================================================================

-- Fungsi untuk menghitung XP yang dibutuhkan untuk level berikutnya
local function GetXPForNextLevel(level)
	return 1000 + (level * 100)
end

function LevelManager.GetData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[LevelManager] Gagal mendapatkan data bahkan setelah menunggu untuk pemain: " .. player.Name)
		return table.clone(DEFAULT_LEVEL_DATA)
	end

	-- Data level adalah bagian dari data Stats
	if not playerData.data.stats then
		playerData.data.stats = {}
	end

	local stats = playerData.data.stats
	local hasChanges = false
	if stats.Level == nil then
		stats.Level = DEFAULT_LEVEL_DATA.Level
		hasChanges = true
	end
	if stats.XP == nil then
		stats.XP = DEFAULT_LEVEL_DATA.XP
		hasChanges = true
	end

	if hasChanges then
		DataStoreManager:UpdatePlayerData(player, playerData.data)
	end

	return { Level = stats.Level, XP = stats.XP }
end

function LevelManager.SaveData(player, levelData)
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.data then return end

	if not playerData.data.stats then
		playerData.data.stats = {}
	end

	playerData.data.stats.Level = levelData.Level
	playerData.data.stats.XP = levelData.XP
	DataStoreManager:UpdatePlayerData(player, playerData.data)
end

-- =============================================================================
-- API PUBLIK
-- =============================================================================

function LevelManager.AddXP(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return end

	local data = LevelManager.GetData(player)
	data.XP += amount

	local xpNeeded = GetXPForNextLevel(data.Level)

	while data.XP >= xpNeeded do
		data.XP -= xpNeeded
		data.Level += 1
		SkillModule.AddSkillPoint(player, 1) -- Asumsi menambah 1 poin per level
		AchievementManager:UpdateStatProgress(player, "PlayerLevel", data.Level)

		-- Update leaderboard saat level naik
		DataStoreManager:UpdateLeaderboard("LevelLeaderboard_v1", player.UserId, data.Level)

		xpNeeded = GetXPForNextLevel(data.Level)
	end

	LevelManager.SaveData(player, data)
	LevelUpdateEvent:FireClient(player, data.Level, data.XP, xpNeeded)
end

-- =============================================================================
-- KONEKSI EVENT
-- =============================================================================

local function initializePlayerData(player)
	task.spawn(function()
		local data = LevelManager.GetData(player)
		local xpNeeded = GetXPForNextLevel(data.Level)
		LevelUpdateEvent:FireClient(player, data.Level, data.XP, xpNeeded)
	end)
end

Players.PlayerAdded:Connect(function(player)
	DataStoreManager:OnPlayerDataLoaded(player, function()
		initializePlayerData(player)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	DataStoreManager:OnPlayerDataLoaded(player, function()
		initializePlayerData(player)
	end)
end

return LevelManager
