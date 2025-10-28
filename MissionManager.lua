-- MissionManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/MissionManager.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

-- Modul lain
local MissionConfig = require(ReplicatedStorage.ModuleScript:WaitForChild("MissionConfig"))
local MissionPointsModule = require(script.Parent:WaitForChild("MissionPointsModule"))
local StatsModule = require(script.Parent:WaitForChild("StatsModule"))
local GlobalMissionManager = require(script.Parent:WaitForChild("GlobeMissionManager"))

local MissionManager = {}

-- RemoteEvents & RemoteFunctions
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local missionProgressUpdatedEvent = RemoteEvents:WaitForChild("MissionProgressUpdated")
local missionsResetEvent = RemoteEvents:WaitForChild("MissionsReset")

if RemoteEvents:FindFirstChild("RerollMissionFunc") then
	RemoteEvents.RerollMissionFunc:Destroy()
end
local rerollMissionFunc = Instance.new("RemoteFunction", RemoteEvents)
rerollMissionFunc.Name = "RerollMissionFunc"


-- =============================================================================
-- FUNGSI INTI
-- =============================================================================

function MissionManager.GetData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[MissionManager] Gagal mendapatkan data untuk pemain: " .. player.Name)
		return {}
	end

	-- Pastikan sub-tabel missions ada
	if not playerData.data.missions then
		local defaultData = require(script.Parent:WaitForChild("DataStoreManager")).DEFAULT_PLAYER_DATA
		playerData.data.missions = {}
		for k, v in pairs(defaultData.missions) do
			playerData.data.missions[k] = v
		end
		DataStoreManager:UpdatePlayerData(player, playerData.data)
	end

	return playerData.data.missions
end

function MissionManager.SaveData(player, missionsData)
	-- Pastikan data ada sebelum mencoba menyimpan.
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.data then
		-- Jika data belum ada, kita tidak bisa menyimpan. Ini mencegah error.
		return
	end

	playerData.data.missions = missionsData
	DataStoreManager:UpdatePlayerData(player, playerData.data)
end

-- =============================================================================
-- LOGIKA MISI (Reset, Generate, Update, Claim)
-- =============================================================================

function MissionManager:_shouldResetDaily(lastReset, current)
	if lastReset == 0 then return true end
	local lastResetDate = os.date("*t", lastReset)
	local currentDate = os.date("*t", current)
	return currentDate.year > lastResetDate.year or currentDate.yday > lastResetDate.yday
end

function MissionManager:_shouldResetWeekly(lastReset, current)
	if lastReset == 0 then return true end
	local currentDate = os.date("*t", current)
	local daysSinceMonday = (currentDate.wday - 2 + 7) % 7
	local lastMonday_UTC = os.time({year=currentDate.year, month=currentDate.month, day=currentDate.day-daysSinceMonday, hour=0, min=0, sec=0})
	return lastReset < lastMonday_UTC
end

function MissionManager:_generateNewMissions(player, missionType)
	local missionsData = self.GetData(player)
	local newMissions, source, count, history = {}, nil, 0, missionsData.RecentMissions

	if missionType == "Daily" then
		source = MissionConfig.DailyMissions
		count = MissionConfig.DailyMissionCount or 3
	else
		source = MissionConfig.WeeklyMissions
		count = MissionConfig.WeeklyMissionCount or 3
	end

	local available = {}
	for _, m in ipairs(source) do
		if not table.find(history, m.ID) then
			table.insert(available, m)
		end
	end

	if #available < count then -- Jika tidak cukup misi unik, reset history
		history = {}
		available = source
	end

	for i = 1, count do
		if #available == 0 then break end
		local mission = table.remove(available, math.random(#available))
		newMissions[mission.ID] = { Progress = 0, Completed = false, Claimed = false }
		table.insert(history, mission.ID)
	end

	while #history > 15 do table.remove(history, 1) end

	return newMissions
end

function MissionManager:CheckAndResetMissions(player)
	local missionsData = self.GetData(player)
	local currentTime = os.time()
	local wasReset = false

	if self:_shouldResetDaily(missionsData.Daily.LastReset, currentTime) then
		missionsData.Daily = { Missions = self:_generateNewMissions(player, "Daily"), LastReset = currentTime, RerollUsed = false }
		wasReset = true
	end

	if self:_shouldResetWeekly(missionsData.Weekly.LastReset, currentTime) then
		missionsData.Weekly = { Missions = self:_generateNewMissions(player, "Weekly"), LastReset = currentTime, RerollUsed = false }
		wasReset = true
	end

	if wasReset then
		self.SaveData(player, missionsData)
		missionsResetEvent:FireClient(player)
	end
end

function MissionManager:UpdateMissionProgress(player, updateParams)
	local missionsData = self.GetData(player)
	local eventType, amount, weaponType = updateParams.eventType, updateParams.amount or 1, updateParams.weaponType

	local function findConfig(id)
		for _, m in ipairs(MissionConfig.DailyMissions) do if m.ID == id then return m end end
		for _, m in ipairs(MissionConfig.WeeklyMissions) do if m.ID == id then return m end end
		return nil
	end

	local function updateCategory(missions)
		for id, data in pairs(missions) do
			if not data.Completed then
				local config = findConfig(id)
				if config and config.Type == eventType and (not config.WeaponType or config.WeaponType == weaponType) then
					data.Progress = math.min(data.Progress + amount, config.Target)
					if data.Progress >= config.Target then
						data.Completed = true
					end
					missionProgressUpdatedEvent:FireClient(player, {missionID=id, newProgress=data.Progress, completed=data.Completed})
				end
			end
		end
	end

	updateCategory(missionsData.Daily.Missions)
	updateCategory(missionsData.Weekly.Missions)
	self.SaveData(player, missionsData)

	GlobalMissionManager:IncrementProgress(eventType, amount, player)
end

function MissionManager:ClaimMissionReward(player, missionID)
	local missionsData = self.GetData(player)
	local missionCat, missionData = nil, nil

	if missionsData.Daily.Missions[missionID] then
		missionCat, missionData = "Daily", missionsData.Daily.Missions[missionID]
	elseif missionsData.Weekly.Missions[missionID] then
		missionCat, missionData = "Weekly", missionsData.Weekly.Missions[missionID]
	end

	if not missionData or not missionData.Completed or missionData.Claimed then
		return { Success = false, Reason = "Misi tidak valid." }
	end

	local config = (function()
		for _, m in ipairs(MissionConfig[missionCat.."Missions"]) do if m.ID == missionID then return m end end
	end)()

	if not config then return { Success = false, Reason = "Konfigurasi tidak ditemukan." } end

	missionData.Claimed = true
	MissionPointsModule:AddMissionPoints(player, config.Reward.Value)
	StatsModule.IncrementStat(player, "MissionsCompleted", 1)
	self.SaveData(player, missionsData)

	return { Success = true, Reward = config.Reward }
end

function MissionManager:RerollMission(player, missionID)
	-- Implementasi reroll disederhanakan, dapat diperluas jika diperlukan
	return { Success = false, Reason = "Fitur Reroll sedang dalam pengembangan." }
end

function MissionManager:GetMissionDataForClient(player)
	local missionsData = self.GetData(player)
	if not missionsData then return nil end

	local clientData = {
		Daily = { Missions = {}, RerollUsed = missionsData.Daily.RerollUsed },
		Weekly = { Missions = {}, RerollUsed = missionsData.Weekly.RerollUsed }
	}

	local function findConfig(id)
		for _, m in ipairs(MissionConfig.DailyMissions) do if m.ID == id then return m end end
		for _, m in ipairs(MissionConfig.WeeklyMissions) do if m.ID == id then return m end end
		return nil
	end

	local function populate(source, dest)
		for id, data in pairs(source) do
			local config = findConfig(id)
			if config then
				dest[id] = {
					Description = config.Description,
					Target = config.Target,
					Reward = config.Reward,
					Progress = data.Progress,
					Completed = data.Completed,
					Claimed = data.Claimed
				}
			end
		end
	end

	populate(missionsData.Daily.Missions, clientData.Daily.Missions)
	populate(missionsData.Weekly.Missions, clientData.Weekly.Missions)

	return clientData
end


-- =============================================================================
-- KONEKSI EVENT
-- =============================================================================

-- Fungsi yang dipanggil saat pemain bergabung
local function onPlayerAdded(player)
	-- Memulai pemeriksaan misi dalam thread baru.
	-- GetData akan secara internal menunggu data dimuat.
	task.spawn(function()
		MissionManager:CheckAndResetMissions(player)
	end)
end

-- Dengarkan event untuk setiap pemain yang bergabung
Players.PlayerAdded:Connect(onPlayerAdded)

-- Jalankan juga untuk pemain yang mungkin sudah ada saat skrip ini dimuat
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end


rerollMissionFunc.OnServerInvoke = function(player, missionID)
	return MissionManager:RerollMission(player, missionID)
end

return MissionManager
