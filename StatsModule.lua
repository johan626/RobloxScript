-- StatsModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/StatsModule.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))
local AchievementManager -- Akan dimuat nanti untuk menghindari dependensi siklik

local StatsModule = {}

-- Event & Fungsi Remote
local apChangedEvent = ReplicatedStorage:FindFirstChild("AchievementPointsChanged") or Instance.new("RemoteEvent", ReplicatedStorage)
apChangedEvent.Name = "AchievementPointsChanged"

-- Hapus instansi lama untuk memastikan tipe yang benar
if ReplicatedStorage:FindFirstChild("GetInitialAchievementPoints") then
	ReplicatedStorage.GetInitialAchievementPoints:Destroy()
end
local getInitialAPFunc = Instance.new("RemoteFunction", ReplicatedStorage)
getInitialAPFunc.Name = "GetInitialAchievementPoints"

local getWeaponStatsFunc = ReplicatedStorage:FindFirstChild("GetWeaponStats") or Instance.new("RemoteFunction", ReplicatedStorage)
getWeaponStatsFunc.Name = "GetWeaponStats"

-- Struktur data default untuk statistik
local DEFAULT_STATS = {
	TotalCoins = 0,
	TotalDamageDealt = 0,
	TotalKills = 0,
	TotalRevives = 0,
	TotalKnocks = 0,
	SkillPoints = 0,
	Skills = {},
	DailyRewardLastClaim = 0,
	DailyRewardCurrentDay = 1,
	SkillResetCount = 0,
	AchievementPoints = 0,
	WeaponStats = {}
}

-- =============================================================================
-- FUNGSI INTI
-- =============================================================================

-- Fungsi untuk mendapatkan data statistik pemain dari cache DataStoreManager
function StatsModule.GetData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[StatsModule] Gagal mendapatkan data bahkan setelah menunggu untuk pemain: " .. player.Name)
		return table.clone(DEFAULT_STATS)
	end

	-- Pastikan data statistik ada
	if not playerData.data.stats then
		playerData.data.stats = table.clone(DEFAULT_STATS)
	end

	-- Pastikan semua field default ada (untuk migrasi data lama)
	local hasChanges = false
	for key, value in pairs(DEFAULT_STATS) do
		if playerData.data.stats[key] == nil then
			playerData.data.stats[key] = value
			hasChanges = true
		end
	end

	if hasChanges then
		DataStoreManager:UpdatePlayerData(player, playerData.data)
	end

	return playerData.data.stats
end

-- Fungsi untuk menyimpan data statistik pemain
function StatsModule.SaveData(player, statsData)
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.data then return end

	playerData.data.stats = statsData
	DataStoreManager:UpdatePlayerData(player, playerData.data)
end

-- =============================================================================
-- LOGIKA LEADERBOARD
-- =============================================================================

local leaderboardCache = {} -- { userId = { StatName = value } }
local dirtyLeaderboardPlayers = {} -- { userId = true }

local function updateLeaderboardCache(player, statName, value)
	local userId = player.UserId
	if not leaderboardCache[userId] then leaderboardCache[userId] = {} end
	leaderboardCache[userId][statName] = value
	dirtyLeaderboardPlayers[userId] = true
end

local function saveDirtyLeaderboards()
	for userId, _ in pairs(dirtyLeaderboardPlayers) do
		local playerData = leaderboardCache[userId]
		if playerData then
			if playerData.TotalKills then
				DataStoreManager:UpdateLeaderboard("KillsLeaderboard", userId, playerData.TotalKills)
			end
			if playerData.TotalDamageDealt then
				DataStoreManager:UpdateLeaderboard("DamageLeaderboard", userId, playerData.TotalDamageDealt)
			end
			-- Tambahkan leaderboard lain di sini jika perlu
		end
	end
	dirtyLeaderboardPlayers = {} -- Reset setelah disimpan
end

-- Simpan leaderboard secara berkala
task.spawn(function()
	while true do
		task.wait(120) -- Simpan setiap 2 menit
		saveDirtyLeaderboards()
	end
end)

-- =============================================================================
-- FUNGSI PUBLIK (API)
-- =============================================================================

-- Fungsi untuk menambah nilai tertentu
function StatsModule.IncrementStat(player, key, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return end

	local data = StatsModule.GetData(player)
	local newValue = (data[key] or 0) + amount
	data[key] = newValue
	StatsModule.SaveData(player, data)

	-- Periksa pencapaian untuk stat ini
	if not AchievementManager then AchievementManager = require(script.Parent:WaitForChild("AchievementManager")) end
	AchievementManager:UpdateStatProgress(player, key, newValue)

	-- Update cache leaderboard jika stat ini dilacak
	if key == "TotalKills" or key == "TotalDamageDealt" then
		updateLeaderboardCache(player, key, newValue)
	end

	if key == "AchievementPoints" then
		apChangedEvent:FireClient(player, data[key])
	end
end

-- Fungsi publik untuk menambah statistik
function StatsModule.AddKill(player, amount)
	StatsModule.IncrementStat(player, "TotalKills", amount or 1)
end

function StatsModule.AddCoin(player, amount)
	StatsModule.IncrementStat(player, "TotalCoins", amount)
end

function StatsModule.AddKnock(player, amount)
	StatsModule.IncrementStat(player, "TotalKnocks", amount or 1)
end

function StatsModule.AddRevive(player, amount)
	StatsModule.IncrementStat(player, "TotalRevives", amount or 1)
end

function StatsModule.AddTotalDamage(player, amount)
	StatsModule.IncrementStat(player, "TotalDamageDealt", amount)
end

function StatsModule.AddWeaponKill(player, weaponName)
	if not player or not weaponName then return end
	local data = StatsModule.GetData(player)
	if not data.WeaponStats[weaponName] then
		data.WeaponStats[weaponName] = { Kills = 0, Damage = 0 }
	end
	data.WeaponStats[weaponName].Kills += 1
	StatsModule.SaveData(player, data)
	if not AchievementManager then AchievementManager = require(script.Parent:WaitForChild("AchievementManager")) end
	AchievementManager:UpdateWeaponKill(player, weaponName, data.WeaponStats[weaponName].Kills)
end

function StatsModule.AddWeaponDamage(player, weaponName, amount)
	if not player or not weaponName or not amount then return end
	local data = StatsModule.GetData(player)
	if not data.WeaponStats[weaponName] then
		data.WeaponStats[weaponName] = { Kills = 0, Damage = 0 }
	end
	data.WeaponStats[weaponName].Damage += amount
	StatsModule.SaveData(player, data)
end

function StatsModule.AddAchievementPoints(player, amount)
	StatsModule.IncrementStat(player, "AchievementPoints", amount)
end

function StatsModule.RemoveAchievementPoints(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return false end
	local data = StatsModule.GetData(player)
	if (data.AchievementPoints or 0) < amount then
		return false
	end
	data.AchievementPoints -= amount
	StatsModule.SaveData(player, data)
	apChangedEvent:FireClient(player, data.AchievementPoints)
	return true
end

function StatsModule.SetStat(player, key, value)
	if not player or not key or value == nil then return end
	local data = StatsModule.GetData(player)
	data[key] = value
	StatsModule.SaveData(player, data)
	-- Panggil juga pemeriksaan pencapaian
	if not AchievementManager then AchievementManager = require(script.Parent:WaitForChild("AchievementManager")) end
	AchievementManager:UpdateStatProgress(player, key, value)
end

-- =============================================================================
-- KONEKSI EVENT & FUNGSI REMOTE
-- =============================================================================

Players.PlayerRemoving:Connect(function(player)
	if dirtyLeaderboardPlayers[player.UserId] then
		saveDirtyLeaderboards() -- Simpan semua yang kotor jika pemain keluar
	end
	leaderboardCache[player.UserId] = nil
	dirtyLeaderboardPlayers[player.UserId] = nil
end)

getInitialAPFunc.OnServerInvoke = function(player)
	local data = StatsModule.GetData(player)
	return data.AchievementPoints or 0
end

getWeaponStatsFunc.OnServerInvoke = function(player)
	local data = StatsModule.GetData(player)
	local weaponStats = data.WeaponStats or {}
	local sortedStats = {}
	for name, stats in pairs(weaponStats) do
		table.insert(sortedStats, { Name = name, Kills = stats.Kills or 0, Damage = stats.Damage or 0 })
	end
	table.sort(sortedStats, function(a, b) return a.Kills > b.Kills end)
	return sortedStats
end

return StatsModule
