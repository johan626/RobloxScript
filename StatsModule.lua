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

-- Cache untuk melacak pemain yang statistik papan peringkatnya perlu diperbarui
local dirtyLeaderboardPlayers = {}

-- =============================================================================
-- FUNGSI INTI
-- =============================================================================

-- Fungsi untuk mendapatkan data statistik pemain dari cache DataStoreManager
function StatsModule.GetData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[StatsModule] Gagal mendapatkan data untuk pemain: " .. player.Name)
		return {}
	end

	-- Pastikan sub-tabel stats ada
	if not playerData.data.stats then
		local defaultData = require(script.Parent:WaitForChild("DataStoreManager")).DEFAULT_PLAYER_DATA
		playerData.data.stats = {}
		for k, v in pairs(defaultData.stats) do
			playerData.data.stats[k] = v
		end
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

	-- Tandai pemain sebagai "kotor" jika statistik papan peringkat berubah
	if key == "TotalKills" or key == "TotalDamageDealt" or key == "AchievementPoints" then
		if not dirtyLeaderboardPlayers[player] then
			print(string.format("[StatsModule][Cache] Menandai %s untuk pembaruan papan peringkat.", player.Name))
		end
		dirtyLeaderboardPlayers[player] = true
	end

	-- Kirim event untuk Achievement Points secara langsung
	if key == "AchievementPoints" then
		apChangedEvent:FireClient(player, data[key])
	end
end

function StatsModule.GetStat(player, key)
	if not player or not key then return nil end
	local data = StatsModule.GetData(player)
	return data[key]
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
	-- Hapus pemain dari cache. Penyimpanan ditangani oleh DataStoreManager.
	dirtyLeaderboardPlayers[player] = nil
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

-- =============================================================================
-- FUNGSI PENYIMPANAN PAPAN PERINGKAT
-- =============================================================================

local function savePlayerLeaderboardData(player)
	if not dirtyLeaderboardPlayers[player] then return end

	local data = StatsModule.GetData(player)
	if data then
		print(string.format("[StatsModule][Cache] Menyimpan paksa data papan peringkat untuk %s.", player.Name))
		DataStoreManager:UpdateLeaderboard("KillsLeaderboard_v1", player.UserId, data.TotalKills or 0)
		DataStoreManager:UpdateLeaderboard("TDLeaderboard_v1", player.UserId, data.TotalDamageDealt or 0)
		DataStoreManager:UpdateLeaderboard("APLeaderboard_v1", player.UserId, data.AchievementPoints or 0)
	end
	dirtyLeaderboardPlayers[player] = nil -- Hapus dari cache setelah disimpan
end

function StatsModule.ForceSavePlayerLeaderboard(player)
	savePlayerLeaderboardData(player)
end

function StatsModule.ForceSaveAllDirtyLeaderboards()
	print("[StatsModule][Cache] Menyimpan paksa semua data papan peringkat yang tertunda...")
	for player, _ in pairs(dirtyLeaderboardPlayers) do
		if player.Parent then
			savePlayerLeaderboardData(player)
		end
	end
end


-- Loop pembaruan periodik untuk papan peringkat
task.spawn(function()
	while true do
		task.wait(60) -- Jalankan setiap 60 detik

		local dirtyCount = 0
		for _ in pairs(dirtyLeaderboardPlayers) do dirtyCount += 1 end
		if dirtyCount == 0 then continue end

		print(string.format("[StatsModule][Cache] Memulai pembaruan papan peringkat periodik untuk %d pemain...", dirtyCount))

		local playersToUpdate = {}
		for player, _ in pairs(dirtyLeaderboardPlayers) do
			if player.Parent then -- Pastikan pemain masih ada di server
				table.insert(playersToUpdate, player)
			end
		end

		for _, player in ipairs(playersToUpdate) do
			savePlayerLeaderboardData(player)
		end
		print("[StatsModule][Cache] Pembaruan papan peringkat periodik selesai.")
	end
end)

return StatsModule
