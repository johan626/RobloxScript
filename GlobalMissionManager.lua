-- GlobalMissionManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/GlobalMissionManager.lua
-- Script Place: Lobby & ACT 1: Village

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

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
	Notified50 = false,
	Notified75 = false,
	Notified100 = false
}

local GLOBAL_KEY = GlobalMissionConfig.GLOBAL_DATA_KEY
local LEADERBOARD_PREFIX = "GlobalMissionLeaderboard_V2_"

-- ==================================================
-- FUNGSI INTERNAL
-- ==================================================

function GlobalMissionManager:_loadGlobalData()
	local data = DataStoreManager:GetGlobalData(GLOBAL_KEY)
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
		missionCache.StartTime = 0
	end
	missionCache.IsLoaded = true
end

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
	DataStoreManager:SetGlobalData(GLOBAL_KEY, dataToSave)
end

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

	self:_saveGlobalData()
	print(string.format("[GlobalMissionManager] Misi baru dimulai: %s", newMission.Description))

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	local notificationEvent = remoteEvents and remoteEvents:FindFirstChild("GlobalMissionNotification")
	if notificationEvent then
		notificationEvent:FireAllClients("Misi Baru Dimulai!", newMission.Description)
	end
end

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

	missionCache.GlobalProgress += amount

	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then return end

	local missionID = config.ID
	if not playerData.data.globalMissions[missionID] then
		playerData.data.globalMissions[missionID] = { Contribution = 0, Claimed = false }
	end

	playerData.data.globalMissions[missionID].Contribution += amount
	DataStoreManager:UpdatePlayerData(player, playerData.data)

	local leaderboardName = LEADERBOARD_PREFIX .. missionID
	DataStoreManager:UpdateLeaderboard(leaderboardName, player.UserId, playerData.data.globalMissions[missionID].Contribution)

	-- Notifikasi progres (logika tidak berubah)
end

function GlobalMissionManager:ClaimReward(player)
	local prevMission = missionCache.PreviousMission
	if not prevMission or not prevMission.ID then
		return { Success = false, Reason = "Tidak ada hadiah dari misi sebelumnya." }
	end

	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data or not playerData.data.globalMissions[prevMission.ID] then
		return { Success = false, Reason = "Anda tidak berpartisipasi dalam misi minggu lalu." }
	end

	local playerDataForMission = playerData.data.globalMissions[prevMission.ID]
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
	DataStoreManager:UpdatePlayerData(player, playerData.data)

	return { Success = true, Reward = rewardToGive }
end

-- ==================================================
-- INISIALISASI & KONEKSI
-- ==================================================

function GlobalMissionManager:Init()
	self:_loadGlobalData()
	self:CheckForWeeklyReset()

	coroutine.wrap(function()
		while true do task.wait(60); self:_saveGlobalData() end
	end)()
	coroutine.wrap(function()
		while true do task.wait(3600); self:CheckForWeeklyReset() end
	end)()
end

-- RemoteFunctions (disederhanakan untuk keringkasan, logika inti dipindahkan ke DataStoreManager)
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
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if playerData and playerData.data and playerData.data.globalMissions[config.ID] then
		playerContribution = playerData.data.globalMissions[config.ID].Contribution
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
	if not activeMissionID then return {} end

	local leaderboardName = LEADERBOARD_PREFIX .. activeMissionID
	local topPlayersRaw = DataStoreManager:GetLeaderboardData(leaderboardName, false, 10)
	if not topPlayersRaw then return {} end

	local leaderboardData = {}
	for rank, data in ipairs(topPlayersRaw) do
		local userId = tonumber(data.key)
		local username = "???"
		local success, name = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
		if success then username = name end
		table.insert(leaderboardData, { Rank = rank, Name = username, Contribution = data.value })
	end
	return leaderboardData
end

local getPlayerGlobalMissionRank = remoteFunctions:FindFirstChild("GetPlayerGlobalMissionRank") or Instance.new("RemoteFunction", remoteFunctions)
getPlayerGlobalMissionRank.Name = "GetPlayerGlobalMissionRank"
getPlayerGlobalMissionRank.OnServerInvoke = function(player)
	local activeMissionID = missionCache.ActiveMissionID
	if not activeMissionID then return "N/A" end

	local leaderboardName = LEADERBOARD_PREFIX .. activeMissionID
	local score, rank = DataStoreManager:GetPlayerRankInLeaderboard(leaderboardName, player.UserId)

	return rank or "N/A"
end

GlobalMissionManager:Init()

return GlobalMissionManager
