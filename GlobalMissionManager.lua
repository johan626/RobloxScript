-- GlobalMissionManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/GlobalMissionManager.lua
-- Script Place: Lobby & ACT 1: Village

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Muat modul yang diperlukan
local GlobalMissionConfig = require(ReplicatedStorage.ModuleScript:WaitForChild("GlobalMissionConfig"))
local MissionPointsModule = require(ServerScriptService.ModuleScript:WaitForChild("MissionPointsModule"))
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))

local GlobalMissionManager = {}

-- Cache untuk data misi global
local missionCache = {
	IsLoaded = false,
	ActiveMissionID = nil,
	GlobalProgress = 0,
	StartTime = 0,
	PreviousMission = nil,
	-- Flags untuk memastikan notifikasi hanya dikirim sekali per misi
	Notified50 = false,
	Notified75 = false,
	Notified100 = false
}

local DATA_SCOPE = GlobalMissionConfig.DATA_SCOPE
local GLOBAL_KEY = GlobalMissionConfig.GLOBAL_DATA_KEY

-- Cache untuk leaderboard spesifik misi agar tidak perlu memanggil GetOrderedDataStore berulang kali
local missionLeaderboards = {}
local LEADERBOARD_PREFIX = "GlobalMissionLeaderboard_V2_" -- V2 untuk memastikan tidak ada konflik data lama

-- Fungsi untuk mendapatkan leaderboard untuk misi tertentu
local function getLeaderboard(missionID)
	if not missionID then return nil end
	-- Jika belum ada di cache, buat dan simpan
	if not missionLeaderboards[missionID] then
		local storeName = LEADERBOARD_PREFIX .. missionID
		missionLeaderboards[missionID] = DataStoreService:GetOrderedDataStore(storeName)
	end
	return missionLeaderboards[missionID]
end

-- ==================================================
-- FUNGSI INTERNAL
-- ==================================================

-- Memuat data misi global
function GlobalMissionManager:_loadGlobalData()
	local data = DataStoreManager.GetGenericData(GLOBAL_KEY, DATA_SCOPE)
	if data and type(data) == "table" then
		missionCache.ActiveMissionID = data.ActiveMissionID
		missionCache.GlobalProgress = data.GlobalProgress
		missionCache.StartTime = data.StartTime
		missionCache.PreviousMission = data.PreviousMission
		missionCache.Notified50 = data.Notified50 or false
		missionCache.Notified75 = data.Notified75 or false
		missionCache.Notified100 = data.Notified100 or false
	else
		warn("[GlobalMissionManager] Tidak ada data global, akan memulai misi baru jika perlu.")
		missionCache.StartTime = 0 -- Paksa reset
	end
	missionCache.IsLoaded = true
end

-- Menyimpan data misi global
function GlobalMissionManager:_saveGlobalData()
	if not missionCache.IsLoaded then return end
	local dataToSave = {
		ActiveMissionID = missionCache.ActiveMissionID,
		GlobalProgress = missionCache.GlobalProgress,
		StartTime = missionCache.StartTime,
		PreviousMission = missionCache.PreviousMission,
		Notified50 = missionCache.Notified50,
		Notified75 = missionCache.Notified75,
		Notified100 = missionCache.Notified100
	}
	DataStoreManager.SaveGenericData(GLOBAL_KEY, DATA_SCOPE, dataToSave)
end

-- Memilih misi baru
function GlobalMissionManager:_selectNewMission()
	local availableMissions = {}
	for _, mission in ipairs(GlobalMissionConfig.Missions) do
		if not missionCache.PreviousMission or mission.ID ~= missionCache.PreviousMission.ID then
			table.insert(availableMissions, mission)
		end
	end
	if #availableMissions == 0 then return GlobalMissionConfig.Missions[1] end
	return availableMissions[math.random(#availableMissions)]
end

-- Memulai misi mingguan baru
function GlobalMissionManager:_startNewWeeklyMission()
	print("[GlobalMissionManager] Memulai misi mingguan baru...")
	local newMission = self:_selectNewMission()
	if not newMission then
		warn("[GlobalMissionManager] Tidak ada misi global yang bisa dimulai!")
		return
	end

	local currentConfig = self:GetCurrentMissionConfig()
	if currentConfig then
		missionCache.PreviousMission = {
			ID = currentConfig.ID,
			RewardTiers = currentConfig.RewardTiers
		}
	else
		missionCache.PreviousMission = nil
	end

	missionCache.ActiveMissionID = newMission.ID
	missionCache.GlobalProgress = 0
	missionCache.StartTime = os.time()
	missionCache.Notified50 = false
	missionCache.Notified75 = false
	missionCache.Notified100 = false

	-- Dengan sistem leaderboard per-misi, tidak perlu lagi menghapus data lama secara manual.
	-- Cukup dengan membuat leaderboard baru dengan ID misi yang baru.
	getLeaderboard(newMission.ID) -- Ini akan membuat atau mengambil DataStore baru untuk misi ini

	self:_saveGlobalData()
	print(string.format("[GlobalMissionManager] Misi baru dimulai: %s", newMission.Description))

	-- Kirim notifikasi global
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder", ReplicatedStorage)
	remoteEvents.Name = "RemoteEvents"
	local notificationEvent = remoteEvents:FindFirstChild("GlobalMissionNotification") or Instance.new("RemoteEvent", remoteEvents)
	notificationEvent.Name = "GlobalMissionNotification"
	notificationEvent:FireAllClients("Misi Baru Dimulai!", newMission.Description)
end

-- Memeriksa reset mingguan
function GlobalMissionManager:CheckForWeeklyReset()
	if not missionCache.IsLoaded then return end
	local timeSinceStart = os.time() - (missionCache.StartTime or 0)
	if not missionCache.StartTime or missionCache.StartTime == 0 or timeSinceStart >= GlobalMissionConfig.MISSION_DURATION then
		self:_startNewWeeklyMission()
	end
end

-- ==================================================
-- FUNGSI PUBLIK
-- ==================================================

function GlobalMissionManager:GetCurrentMissionConfig()
	if not missionCache.ActiveMissionID then return nil end
	for _, mission in ipairs(GlobalMissionConfig.Missions) do
		if mission.ID == missionCache.ActiveMissionID then return mission end
	end
	return nil
end

function GlobalMissionManager:IncrementProgress(eventType, amount, player)
	if not missionCache.IsLoaded or not missionCache.ActiveMissionID then return end

	local config = self:GetCurrentMissionConfig()
	if not config or config.Type ~= eventType then return end

	-- Update progres global
	missionCache.GlobalProgress = missionCache.GlobalProgress + amount

	-- Update kontribusi pemain
	local stats = DataStoreManager.GetData(player, DATA_SCOPE)
	if not stats or type(stats) ~= "table" then stats = {} end

	if not stats.GlobalMissions then
		stats.GlobalMissions = {}
	end

	local missionID = config.ID
	if not stats.GlobalMissions[missionID] then
		stats.GlobalMissions[missionID] = { Contribution = 0, Claimed = false }
	end

	stats.GlobalMissions[missionID].Contribution = stats.GlobalMissions[missionID].Contribution + amount
	DataStoreManager.SaveData(player, DATA_SCOPE, stats)

	-- Update leaderboard
	local leaderboard = getLeaderboard(missionID)
	if leaderboard then
		local newTotalContribution = stats.GlobalMissions[missionID].Contribution
		local success, err = pcall(function()
			leaderboard:SetAsync(player.UserId, newTotalContribution)
		end)
		if not success then
			warn(string.format("[GlobalMissionManager] Gagal update leaderboard untuk Player %d: %s", player.UserId, err))
		end
	end

	-- Cek dan kirim notifikasi progres
	local progressPercent = missionCache.GlobalProgress / config.GlobalTarget
	local notificationEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("GlobalMissionNotification")

	if notificationEvent then
		if not missionCache.Notified100 and progressPercent >= 1 then
			missionCache.Notified100 = true
			notificationEvent:FireAllClients("Target Tercapai!", string.format("Komunitas telah menyelesaikan misi: %s", config.Description))
		elseif not missionCache.Notified75 and progressPercent >= 0.75 then
			missionCache.Notified75 = true
			notificationEvent:FireAllClients("Progres Misi 75%!", "Kerja bagus! Terus berjuang!")
		elseif not missionCache.Notified50 and progressPercent >= 0.5 then
			missionCache.Notified50 = true
			notificationEvent:FireAllClients("Progres Misi 50%!", "Kita sudah setengah jalan!")
		end
	end
end

function GlobalMissionManager:ClaimReward(player)
	local prevMission = missionCache.PreviousMission
	if not prevMission or not prevMission.ID then
		return { Success = false, Reason = "Tidak ada hadiah dari misi sebelumnya." }
	end

	local stats = DataStoreManager.GetData(player, DATA_SCOPE)
	if not stats or not stats.GlobalMissions or not stats.GlobalMissions[prevMission.ID] then
		return { Success = false, Reason = "Anda tidak berpartisipasi dalam misi minggu lalu." }
	end

	local playerDataForMission = stats.GlobalMissions[prevMission.ID]
	if playerDataForMission.Claimed then
		return { Success = false, Reason = "Anda sudah mengklaim hadiah untuk misi ini." }
	end

	local rewardToGive = nil
	for i = #prevMission.RewardTiers, 1, -1 do
		local tier = prevMission.RewardTiers[i]
		if playerDataForMission.Contribution >= tier.Contribution then
			rewardToGive = tier.Reward
			break
		end
	end

	if not rewardToGive then
		return { Success = false, Reason = "Kontribusi Anda tidak mencapai tingkatan hadiah." }
	end

	MissionPointsModule:AddMissionPoints(player, rewardToGive.Value)

	playerDataForMission.Claimed = true
	DataStoreManager.SaveData(player, DATA_SCOPE, stats)

	return { Success = true, Reward = rewardToGive }
end

-- ==================================================
-- INISIALISASI & KONEKSI
-- ==================================================

function GlobalMissionManager:Init()
	self:_loadGlobalData()
	self:CheckForWeeklyReset()

	coroutine.wrap(function()
		while true do
			task.wait(60)
			self:_saveGlobalData()
		end
	end)()

	coroutine.wrap(function()
		while true do
			task.wait(3600)
			self:CheckForWeeklyReset()
		end
	end)()
end

-- RemoteFunctions
local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions") or Instance.new("Folder", ReplicatedStorage)
remoteFunctions.Name = "RemoteFunctions"

local getGlobalMissionState = remoteFunctions:FindFirstChild("GetGlobalMissionState") or Instance.new("RemoteFunction", remoteFunctions)
getGlobalMissionState.Name = "GetGlobalMissionState"
getGlobalMissionState.OnServerInvoke = function(player)
	if not missionCache.IsLoaded then return nil end
	local config = GlobalMissionManager:GetCurrentMissionConfig()
	if not config then return nil end

	local playerContribution = 0
	local stats = DataStoreManager.GetData(player, DATA_SCOPE)
	if stats and stats.GlobalMissions and stats.GlobalMissions[config.ID] then
		playerContribution = stats.GlobalMissions[config.ID].Contribution
	end

	return {
		Description = config.Description,
		GlobalProgress = missionCache.GlobalProgress,
		GlobalTarget = config.GlobalTarget,
		PlayerContribution = playerContribution,
		EndTime = missionCache.StartTime + GlobalMissionConfig.MISSION_DURATION,
		RewardTiers = config.RewardTiers
	}
end

local claimGlobalMissionReward = remoteFunctions:FindFirstChild("ClaimGlobalMissionReward") or Instance.new("RemoteFunction", remoteFunctions)
claimGlobalMissionReward.Name = "ClaimGlobalMissionReward"
claimGlobalMissionReward.OnServerInvoke = function(player)
	return GlobalMissionManager:ClaimReward(player)
end

local getGlobalMissionLeaderboard = remoteFunctions:FindFirstChild("GetGlobalMissionLeaderboard") or Instance.new("RemoteFunction", remoteFunctions)
getGlobalMissionLeaderboard.Name = "GetGlobalMissionLeaderboard"
getGlobalMissionLeaderboard.OnServerInvoke = function(player)
	local activeMissionID = missionCache.ActiveMissionID
	local leaderboard = getLeaderboard(activeMissionID)
	if not leaderboard then return {} end

	local success, pages = pcall(function()
		return leaderboard:GetSortedAsync(false, 10)
	end)

	if not success then
		warn("Gagal mengambil leaderboard untuk misi " .. activeMissionID .. ": " .. tostring(pages))
		return {}
	end

	local leaderboardData = {}
	local success2, err = pcall(function()
		local currentPage = pages:GetCurrentPage()
		for rank, data in ipairs(currentPage) do
			local userId = tonumber(data.key)
			local value = data.value
			local userName = "???"
			local success3, playerObject = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
			if success3 and playerObject then
				userName = playerObject
			end
			table.insert(leaderboardData, { Rank = rank, Name = userName, Contribution = value })
		end
	end)

	if not success2 then
		warn("Error saat memproses halaman leaderboard: " .. err)
		return {}
	end

	return leaderboardData
end

local getPlayerGlobalMissionRank = remoteFunctions:FindFirstChild("GetPlayerGlobalMissionRank") or Instance.new("RemoteFunction", remoteFunctions)
getPlayerGlobalMissionRank.Name = "GetPlayerGlobalMissionRank"
getPlayerGlobalMissionRank.OnServerInvoke = function(player)
	local activeMissionID = missionCache.ActiveMissionID
	local leaderboard = getLeaderboard(activeMissionID)
	if not leaderboard then return "N/A" end

	local success, contribution = pcall(function()
		return leaderboard:GetAsync(player.UserId)
	end)

	if not success or not contribution then
		return "N/A" -- Tidak memiliki peringkat
	end

	local rank = "N/A"
	local pages
	local pcallSuccess, result = pcall(function()
		pages = leaderboard:GetSortedAsync(false, 100) -- Ukuran halaman 100 untuk efisiensi
	end)

	if not pcallSuccess then
		warn("Tidak dapat mengambil halaman leaderboard untuk mencari peringkat: " .. tostring(result))
		return "Error"
	end

	local pageCount = 0
	while true do
		local currentPage = pages:GetCurrentPage()
		for i, data in ipairs(currentPage) do
			if tonumber(data.key) == player.UserId then
				rank = (pageCount * 100) + i
				return rank -- Ditemukan, langsung kembalikan
			end
		end

		if pages.IsFinished then
			break
		end

		pageCount = pageCount + 1
		local pcallSuccess2, err = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)
        if not pcallSuccess2 then
            warn("Error saat melanjutkan halaman: "..tostring(err))
            return "Error"
        end
	end

	return rank
end


GlobalMissionManager:Init()

return GlobalMissionManager
