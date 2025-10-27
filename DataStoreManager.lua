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


local DATA_VERSION = 4 -- Versi struktur data diperbarui


-- =============================================================================

-- MIGRASI DATA

-- =============================================================================


-- Tambahkan fungsi migrasi baru di sini. Setiap fungsi harus menerima

-- data pemain dan mengembalikannya setelah dimodifikasi.

local function _migrate_v3_to_v4(playerData)

	-- Contoh: Menambahkan tabel pencapaian (achievements) baru ke data

	if not playerData.data.achievements then

		playerData.data.achievements = {}

	end

	return playerData

end


-- Petakan fungsi migrasi ke versi yang di-upgrade

local migrations = {

	[3] = _migrate_v3_to_v4,

}


-- Fungsi utama untuk menerapkan migrasi secara berurutan

local function _migrateData(playerData)

	local originalVersion = playerData.version

	while playerData.version < DATA_VERSION do

		local migrator = migrations[playerData.version]

		if not migrator then

			warn("Tidak ditemukan migrator untuk versi " .. playerData.version .. ". Menghentikan migrasi.")

			return nil -- Gagal

		end



		local success, result = pcall(migrator, playerData)

		if not success then

			warn("Gagal menerapkan migrator untuk versi " .. playerData.version .. ": " .. tostring(result))

			return nil -- Gagal

		end



		playerData = result

		playerData.version = playerData.version + 1

	end



	if playerData.version > originalVersion then

		print("Data berhasil dimigrasi dari v" .. originalVersion .. " ke v" .. playerData.version)

	end



	return playerData

end


local function createDefaultData()

	return {

		version = DATA_VERSION,

		data = {

			stats = {},

			coins = 0,

			inventory = {},

			missions = nil,

			achievements = {}, -- Ditambahkan di v4

			settings = {

				sound = { enabled = true, sfxVolume = 0.8 },

				hud = {},

			},

		}

	}

end



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


		if data and type(data) == "table" then

			if data.version < DATA_VERSION then

				-- Data versi lama, jalankan migrasi

				local migratedData = _migrateData(data)

				if migratedData then

					playerDataCache[player] = migratedData

				else

					-- Migrasi gagal, buat data default untuk sesi ini

					warn("Migrasi data gagal untuk " .. player.Name .. ". Membuat data default.")

					playerDataCache[player] = createDefaultData()

				end

			else

				-- Versi data sudah sesuai

				playerDataCache[player] = data

			end

		else

			-- Tidak ada data, buat struktur default baru

			playerDataCache[player] = createDefaultData()

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

function DataStoreManager:UpdateLeaderboard(leaderboardName, userId, score)
	if not leaderboardName or not userId or type(score) ~= "number" then
		warn("[DataStoreManager] Panggilan UpdateLeaderboard tidak valid: " .. tostring(leaderboardName))
		return
	end

	local leaderboardStore = DataStoreService:GetOrderedDataStore(leaderboardName)
	retryDataStoreCall(function()
		leaderboardStore:SetAsync(tostring(userId), score)
		return true
	end)
end

-- =============================================================================
-- FUNGSI ADMIN
-- =============================================================================

function DataStoreManager:DeletePlayerData(userId)
	local userIdStr = tostring(userId)

	-- Hapus dari cache jika pemain online
	local targetPlayer = Players:GetPlayerByUserId(userId)
	if targetPlayer then
		self:ClearPlayerCache(targetPlayer)
	end

	-- Hapus dari DataStore utama
	local mainSuccess, mainErr = pcall(function()
		return playerDS:RemoveAsync(userIdStr)
	end)

	if not mainSuccess then
		warn("[DataStoreManager] Gagal menghapus data dari DS utama untuk userID " .. userIdStr .. ": " .. tostring(mainErr))
	end

	-- Hapus dari DataStore backup
	local backupSuccess, backupErr = pcall(function()
		return playerDSBackup:RemoveAsync(userIdStr)
	end)

	if not backupSuccess then
		warn("[DataStoreManager] Gagal menghapus data dari DS backup untuk userID " .. userIdStr .. ": " .. tostring(backupErr))
	end

	print("[DataStoreManager] Upaya penghapusan data selesai untuk userID " .. userIdStr)
	return mainSuccess and backupSuccess
end

function DataStoreManager:LogAdminAction(adminPlayer, action, targetUserId, reason)
	-- Fungsi ini dapat diperluas untuk mencatat ke layanan eksternal (misalnya, Discord webhook)
	local adminName = adminPlayer.Name
	local timestamp = os.date("!%Y-%m-%d %H:%M:%S Z")
	reason = reason or "N/A"

	local logMessage = string.format(
		"ADMIN ACTION: %s | Admin: %s (%d) | Action: %s | Target: %d | Reason: %s",
		timestamp,
		adminName,
		adminPlayer.UserId,
		action,
		targetUserId,
		reason
	)

	print(logMessage)
	-- Di masa depan, ini bisa mengirim ke OrderedDataStore atau layanan logging
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
