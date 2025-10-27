-- DataStoreManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/DataStoreManager.lua
-- Deskripsi: Mengelola semua interaksi dengan Roblox DataStore, termasuk data pemain dan data global.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Memuat konfigurasi game untuk menentukan lingkungan (dev/prod)
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local DataStoreManager = {}

-- Menentukan lingkungan datastore
local ENVIRONMENT = GameConfig.DataStore and GameConfig.DataStore.Environment or "dev"

-- Mendapatkan objek DataStore dengan scope lingkungan
local PlayerDS = DataStoreService:GetDataStore("PlayerDS", ENVIRONMENT)
local GlobalDS = DataStoreService:GetDataStore("GlobalDS", ENVIRONMENT)

-- Cache untuk menyimpan data pemain yang sedang online
-- Struktur Cache: { [UserId] = { data = {}, isDirty = false, isLoading = true } }
local playerDataCache = {}

-- Struktur data default untuk pemain baru.
-- Versi ditambahkan untuk memfasilitasi migrasi data di masa mendatang.
local DEFAULT_PLAYER_DATA = {
    version = 1,
    lastSaveTimestamp = 0,
    stats = {
        TotalCoins = 0,
        TotalDamageDealt = 0,
        TotalKills = 0,
        TotalRevives = 0,
        TotalKnocks = 0,
        DailyRewardLastClaim = 0,
        DailyRewardCurrentDay = 1,
        AchievementPoints = 0,
        MissionPoints = 0,
        WeaponStats = {},
        MissionsCompleted = 0,
    },
    missions = {
        Daily = { Missions = {}, LastReset = 0, RerollUsed = false },
        Weekly = { Missions = {}, LastReset = 0, RerollUsed = false },
        RecentMissions = {}
    },
    leveling = {
        Level = 1,
        XP = 0,
    },
    globalMissions = {},
    titles = {
        UnlockedTitles = {},
        EquippedTitle = ""
    },
    inventory = {
        Coins = 0,
        Skins = {
            Owned = {},
            Equipped = {}
        },
        PityCount = 0,
        LastFreeGachaClaimUTC = 0
    },
    achievements = {
        Completed = {},
        Progress = {}
    },
    boosters = {
        Owned = {},
        Active = nil
    },
    settings = {
        sound = { enabled = true, sfxVolume = 0.8 },
        controls = { fireControlType = "FireButton" },
        hud = {}
    }
}

-- Fungsi internal untuk membuat salinan mendalam dari tabel
local function deepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            v = deepCopy(v)
        end
        copy[k] = v
    end
    return copy
end


function DataStoreManager:LoadPlayerData(player)
	local userId = player.UserId
	local key = "Player_" .. userId

	-- Tandai bahwa data sedang dimuat untuk mencegah penyimpanan simultan
	playerDataCache[userId] = { data = nil, isDirty = false, isLoading = true }

	-- Sinyal untuk memberitahu thread lain bahwa data telah dimuat
	local dataLoadedSignal = Instance.new("BindableEvent")

	task.spawn(function()
		local attempts = 0
		local success = false
		local loadedData = nil

		while not success and attempts < 5 do
			attempts = attempts + 1
			local ok, result = pcall(function()
				return PlayerDS:UpdateAsync(key, function(oldData)
					-- Jika tidak ada data lama, gunakan data default
					if not oldData then
						return deepCopy(DEFAULT_PLAYER_DATA)
					end
					-- Di sini kita bisa menambahkan logika migrasi data berdasarkan oldData.version
					-- Untuk saat ini, kita hanya mengembalikan data lama jika ada.
					return oldData
				end)
			end)

			if ok then
				success = true
				loadedData = result
			else
				warn("[DataStoreManager] Gagal memuat data untuk " .. player.Name .. " (Percobaan " .. attempts .. "): " .. tostring(result))
				task.wait(3) -- Tunggu sebelum mencoba lagi
			end
		end

		if success then
			playerDataCache[userId].data = loadedData
			playerDataCache[userId].isLoading = false
			print("[DataStoreManager] Data berhasil dimuat untuk " .. player.Name)
		else
			-- Jika semua percobaan gagal, gunakan data default dan kunci penyimpanan untuk sesi ini
			warn("[DataStoreManager] Semua percobaan memuat data gagal untuk " .. player.Name .. ". Menggunakan data default sementara. PENYIMPANAN DINONAKTIFKAN.")
			playerDataCache[userId].data = deepCopy(DEFAULT_PLAYER_DATA)
			playerDataCache[userId].isLoading = false
			playerDataCache[userId].saveLocked = true -- Kunci penyimpanan untuk mencegah overwrite
		end

		-- Memberi sinyal bahwa data sudah siap (baik berhasil maupun gagal)
		dataLoadedSignal:Fire(playerDataCache[userId].data)
		dataLoadedSignal:Destroy()
	end)

	-- Kembalikan event agar skrip lain bisa menunggu
	return dataLoadedSignal.Event
end

-- Fungsi untuk skrip lain menunggu data siap
function DataStoreManager:GetOrWaitForPlayerData(player)
	local userId = player.UserId
	if not playerDataCache[userId] or playerDataCache[userId].isLoading then
		-- Jika data belum ada atau sedang dimuat, tunggu sinyal
		local dataLoadedEvent = self:LoadPlayerData(player)
		dataLoadedEvent:Wait()
	end
	return playerDataCache[userId]
end

-- Fungsi internal untuk menyimpan data pemain tunggal
local function savePlayerDataFunc(userId)
	local cacheEntry = playerDataCache[userId]
	-- Jangan simpan jika data dikunci, tidak diubah, atau masih dimuat
	if not cacheEntry or not cacheEntry.isDirty or cacheEntry.isLoading or cacheEntry.saveLocked then
		return false -- Mengindikasikan penyimpanan tidak dilakukan
	end

	local key = "Player_" .. userId
	local dataToSave = cacheEntry.data
	dataToSave.lastSaveTimestamp = os.time() -- Perbarui timestamp sebelum menyimpan

	local attempts = 0
	local success = false
	while not success and attempts < 3 do
		attempts = attempts + 1
		local ok, err = pcall(function()
			PlayerDS:SetAsync(key, dataToSave)
		end)
		if ok then
			success = true
			cacheEntry.isDirty = false -- Reset flag setelah berhasil disimpan
			print("[DataStoreManager] Data berhasil disimpan untuk UserId: " .. userId)
		else
			warn("[DataStoreManager] Gagal menyimpan data untuk UserId: " .. userId .. " (Percobaan " .. attempts .. "): " .. tostring(err))
			if attempts < 3 then task.wait(2) end
		end
	end
	return success
end

-- Fungsi penyimpanan sinkron (yielding) untuk kasus-kasus kritis seperti teleportasi
function DataStoreManager:SavePlayerDataYielding(player)
	return savePlayerDataFunc(player.UserId)
end


function DataStoreManager:SavePlayerData(player)
	savePlayerDataFunc(player.UserId)
end

-- Fungsi untuk menandai data pemain telah diubah dan perlu disimpan
function DataStoreManager:UpdatePlayerData(player, newData)
    local userId = player.UserId
    if playerDataCache[userId] then
        playerDataCache[userId].data = newData
        playerDataCache[userId].isDirty = true
    end
end

-- Inisialisasi loop autosave dan event-event
function DataStoreManager:Init()
	print("DataStoreManager Diinisialisasi dalam mode: " .. ENVIRONMENT)

	-- Loop Autosave
	task.spawn(function()
		while true do
			task.wait(60)
			for userId, _ in pairs(playerDataCache) do
				savePlayerDataFunc(userId)
			end
		end
	end)

	-- Simpan saat pemain keluar
	Players.PlayerRemoving:Connect(function(player)
		savePlayerDataFunc(player.UserId)
		playerDataCache[player.UserId] = nil -- Hapus dari cache
	end)

	-- Simpan semua data saat server ditutup
	game:BindToClose(function()
		if not RunService:IsStudio() then
			local saveTasks = {}
			for userId, _ in pairs(playerDataCache) do
				table.insert(saveTasks, task.spawn(savePlayerDataFunc, userId))
			end
			-- Tunggu semua tugas penyimpanan selesai
			for _, t in ipairs(saveTasks) do
				task.wait()
			end
		end
	end)
end


function DataStoreManager:GetPlayerData(player)
	if playerDataCache[player.UserId] then
		return playerDataCache[player.UserId]
	end
	return nil
end

-- =============================================================================
-- API UNTUK DATA GLOBAL (LEADERBOARD, DLL.)
-- =============================================================================

function DataStoreManager:UpdateLeaderboard(leaderboardName, key, value)
    local success, err = pcall(function()
        local orderedDataStore = DataStoreService:GetOrderedDataStore(leaderboardName, ENVIRONMENT)
        orderedDataStore:SetAsync(tostring(key), tonumber(value))
    end)
    if not success then
        warn("[DataStoreManager] Gagal memperbarui leaderboard '" .. leaderboardName .. "': " .. tostring(err))
    end
end

function DataStoreManager:GetPlayerRankInLeaderboard(leaderboardName, userId)
    local success, result = pcall(function()
        local orderedDataStore = DataStoreService:GetOrderedDataStore(leaderboardName, ENVIRONMENT)
        local playerScore = orderedDataStore:GetAsync(tostring(userId))
        if not playerScore then
            return nil, nil -- Pemain tidak ada di papan peringkat
        end

        -- Dapatkan peringkat pemain
        local rankPages = orderedDataStore:GetSortedAsync(false, 100, playerScore)
        local rankPage = rankPages:GetCurrentPage()

        local playerRank = nil
        for i, entry in ipairs(rankPage) do
            if entry.key == tostring(userId) then
                playerRank = i
                break
            end
        end

        return playerScore, playerRank
    end)

    if success then
        return result
    else
        warn("[DataStoreManager] Gagal mendapatkan peringkat pemain untuk '" .. leaderboardName .. "': " .. tostring(result))
        return nil, nil
    end
end

function DataStoreManager:GetLeaderboardData(leaderboardName, isAscending, pageSize)
    isAscending = isAscending or false
    pageSize = pageSize or 50 -- Sesuaikan dengan kebutuhan LeaderboardManager

    local success, result = pcall(function()
        local orderedDataStore = DataStoreService:GetOrderedDataStore(leaderboardName, ENVIRONMENT)
        local pages = orderedDataStore:GetSortedAsync(isAscending, pageSize)
        return pages:GetCurrentPage()
    end)

    if success then
        return result
    else
        warn("[DataStoreManager] Gagal mengambil data leaderboard '" .. leaderboardName .. "': " .. tostring(result))
        return {}
    end
end

-- =============================================================================
-- API UNTUK DATA GLOBAL GENERIC (NON-LEADERBOARD)
-- =============================================================================

function DataStoreManager:SetGlobalData(key, value)
    local success, err = pcall(function()
        GlobalDS:SetAsync(key, value)
    end)
    if not success then
        warn("[DataStoreManager] Gagal menyimpan data global untuk kunci '" .. key .. "': " .. tostring(err))
    end
    return success
end

function DataStoreManager:GetGlobalData(key)
    local success, result = pcall(function()
        return GlobalDS:GetAsync(key)
    end)
    if success then
        return result
    else
        warn("[DataStoreManager] Gagal mengambil data global untuk kunci '" .. key .. "': " .. tostring(result))
        return nil
    end
end

-- =============================================================================
-- API UNTUK ADMIN
-- =============================================================================

function DataStoreManager:LoadOfflinePlayerData(userId)
    local key = "Player_" .. userId
    local success, result = pcall(function()
        return PlayerDS:GetAsync(key)
    end)
    if success then
        return { data = result } -- Kembalikan dalam format yang mirip dengan cache
    else
        warn("[DataStoreManager] Gagal memuat data offline untuk UserId '" .. userId .. "': " .. tostring(result))
        return nil
    end
end

function DataStoreManager:SaveOfflinePlayerData(userId, data)
    local key = "Player_" .. userId
    local success, err = pcall(function()
        PlayerDS:SetAsync(key, data)
    end)
    if not success then
        warn("[DataStoreManager] Gagal menyimpan data offline untuk UserId '" .. userId .. "': " .. tostring(err))
    end
    return success
end

function DataStoreManager:DeletePlayerData(userId)
    local key = "Player_" .. userId
    local success, err = pcall(function()
        -- Implementasi "soft delete" dengan memindahkan data ke backup akan lebih aman,
        -- tapi untuk saat ini kita akan melakukan hard delete sesuai permintaan.
        PlayerDS:RemoveAsync(key)
    end)
    if not success then
        warn("[DataStoreManager] Gagal menghapus data untuk UserId '" .. userId .. "': " .. tostring(err))
    end
    return success
end

function DataStoreManager:LogAdminAction(adminPlayer, action, targetUserId)
    -- Implementasi logging yang sebenarnya bisa lebih kompleks (misalnya, menyimpan ke DataStore terpisah)
    print(string.format("ADMIN ACTION: %s (%d) melakukan '%s' pada UserId %d", adminPlayer.Name, adminPlayer.UserId, action, targetUserId))
end

function DataStoreManager:RestorePlayerDataFromBackup(adminPlayer, targetUserId)
    warn("Fungsi RestorePlayerDataFromBackup belum diimplementasikan.")
    -- Logika pemulihan dari cadangan akan ditempatkan di sini.
    self:LogAdminAction(adminPlayer, "restore_attempt", targetUserId)
    return false
end

DataStoreManager.DEFAULT_PLAYER_DATA = DEFAULT_PLAYER_DATA

return DataStoreManager
