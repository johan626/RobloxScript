-- DataStoreManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/DataStoreManager.lua
-- Script Place: Lobby & ACT 1: Village

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

-- Impor konfigurasi
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local DataStoreManager = {}
DataStoreManager.__index = DataStoreManager

local DATA_VERSION = 3 -- Versi struktur data diperbarui

-- Konfigurasi DataStore
local env = GameConfig.DataStore.Environment or "prod" -- Default ke "prod" jika tidak disetel
local playerDS = DataStoreService:GetDataStore("PlayerDS", env) -- Menggunakan DS baru untuk struktur baru
local playerDSBackup = DataStoreService:GetDataStore("PlayerDSBackup", env)
local globalDS = DataStoreService:GetDataStore("GlobalDS", env)

-- Cache untuk data pemain & status 'dirty'
local playerDataCache = {}
local dirtyPlayers = {}
local isShuttingDown = false

-- Sinyal & State untuk memanajemen pemuatan data
local playerDataLoadedCallbacks = {}
local playerDataLoading = {}
local dataLoadedEvent = Instance.new("BindableEvent")


-- =============================================================================
-- API PUBLIK & LOGIKA INTI
-- =============================================================================

-- Fungsi untuk memeriksa apakah data pemain sudah dimuat
function DataStoreManager:IsPlayerDataLoaded(player)
	return playerDataCache[player] ~= nil
end

-- Fungsi untuk mendaftarkan callback yang akan dijalankan setelah data pemain dimuat
function DataStoreManager:OnPlayerDataLoaded(player, callback)
	if self:IsPlayerDataLoaded(player) then
		task.spawn(callback, playerDataCache[player])
		return
	end
	if not playerDataLoadedCallbacks[player] then
		playerDataLoadedCallbacks[player] = {}
	end
	table.insert(playerDataLoadedCallbacks[player], callback)
end

-- Fungsi yield (menunggu) sampai data pemain dimuat
function DataStoreManager:GetOrWaitForPlayerData(player)
	local startTime = tick()
	local TIMEOUT = 20 -- Detik

	while not self:IsPlayerDataLoaded(player) do
		if tick() - startTime > TIMEOUT then
			warn("[DataStoreManager] GetOrWaitForPlayerData timed out untuk " .. player.Name)
			return nil
		end
		dataLoadedEvent.Event:Wait(0.1) -- Tunggu sebentar agar loop bisa memeriksa timeout
	end
	return playerDataCache[player]
end

-- Fungsi coba ulang (retry) untuk panggilan DataStore
local function retryDataStoreCall(func, attempts)
	attempts = attempts or 3
	for i = 1, attempts do
		local success, result = pcall(func)
		if success then
			return result
		else
			warn("[DataStoreManager] Percobaan " .. i .. " gagal: " .. tostring(result))
			if i < attempts then task.wait(2) end
		end
	end
	return nil
end

-- Fungsi untuk memuat data pemain saat mereka bergabung (asinkron)
function DataStoreManager:LoadPlayerData(player)
	if self:IsPlayerDataLoaded(player) or playerDataLoading[player] then return end
	playerDataLoading[player] = true

	task.spawn(function()
		local userId = tostring(player.UserId)

		local data
		local success = false
		for i = 1, 3 do
			local pcall_success, result = pcall(function()
				return playerDS:GetAsync(userId)
			end)
			if pcall_success then
				success = true
				data = result
				break
			else
				warn("[DataStoreManager] Percobaan memuat data " .. i .. " gagal: " .. tostring(result))
				if i < 3 then task.wait(2) end
			end
		end

		if not Players:GetPlayerByUserId(player.UserId) then
			playerDataLoading[player] = nil
			return
		end

		if not success then
			player:Kick("Gagal memuat data Anda karena masalah layanan. Silakan coba lagi nanti untuk melindungi progres Anda.")
			playerDataLoading[player] = nil
			return
		end

		if data and type(data) == "table" and data.version == DATA_VERSION then
			playerDataCache[player] = data
		else
			-- Data lama atau tidak ada data, buat struktur default baru
			playerDataCache[player] = {
				version = DATA_VERSION,
				data = {
					stats = (data and data.data and data.data.stats) or {},
					coins = (data and data.data and data.data.coins) or 0,
					inventory = (data and data.data and data.data.inventory) or {},
					missions = (data and data.data and data.data.missions) or nil,
					settings = {
						sound = { enabled = true, sfxVolume = 0.8 },
						hud = {}, -- Akan diisi oleh klien dengan posisi default
					},
				}
			}
		end

		playerDataLoading[player] = nil
		print("[DataStoreManager] Data berhasil dimuat untuk " .. player.Name)
		dataLoadedEvent:Fire()

		if playerDataLoadedCallbacks[player] then
			for _, callback in ipairs(playerDataLoadedCallbacks[player]) do
				task.spawn(callback, playerDataCache[player])
			end
			playerDataLoadedCallbacks[player] = nil
		end
	end)
end

function DataStoreManager:GetPlayerData(player) return playerDataCache[player] end

function DataStoreManager:UpdatePlayerData(player, newData)
	if not playerDataCache[player] then
		warn("[DataStoreManager] Tidak dapat memperbarui data untuk pemain yang tidak ada di cache: " .. player.Name)
		return
	end
	playerDataCache[player].data = newData
	dirtyPlayers[player] = true
end

function DataStoreManager:SavePlayerData(player)
	if not dirtyPlayers[player] then return end
	local dataToSave = playerDataCache[player]
	if not dataToSave then return end
	local userId = tostring(player.UserId)
	local mainSuccess = retryDataStoreCall(function() playerDS:SetAsync(userId, dataToSave); return true end)
	if mainSuccess then
		retryDataStoreCall(function() playerDSBackup:SetAsync(userId, dataToSave); return true end)
		print("[DataStoreManager] Data berhasil disimpan ke DS utama & backup untuk " .. player.Name)
		dirtyPlayers[player] = nil
	else
		warn("[DataStoreManager] Gagal menyimpan data ke DS utama untuk " .. player.Name)
	end
end

function DataStoreManager:ClearPlayerCache(player)
	playerDataCache[player] = nil; dirtyPlayers[player] = nil; playerDataLoading[player] = nil; playerDataLoadedCallbacks[player] = nil
end

function DataStoreManager:Init()
	coroutine.wrap(function()
		while not isShuttingDown do
			task.wait(60)
			for player, _ in pairs(dirtyPlayers) do self:SavePlayerData(player) end
		end
	end)()
	Players.PlayerRemoving:Connect(function(player)
		if dirtyPlayers[player] then self:SavePlayerData(player) end
		self:ClearPlayerCache(player)
	end)
	game:BindToClose(function()
		isShuttingDown = true
		for _, player in pairs(Players:GetPlayers()) do
			if dirtyPlayers[player] then self:SavePlayerData(player) end
		end
	end)
end

return DataStoreManager
