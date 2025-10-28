-- MissionPointsModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/MissionPointsModule.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

local MissionPointsModule = {}

-- RemoteEvents & RemoteFunctions
local missionPointsChangedEvent = ReplicatedStorage:FindFirstChild("MissionPointsChanged") or Instance.new("RemoteEvent", ReplicatedStorage)
missionPointsChangedEvent.Name = "MissionPointsChanged"

if ReplicatedStorage:FindFirstChild("GetInitialMissionPoints") then
	ReplicatedStorage.GetInitialMissionPoints:Destroy()
end
local getInitialPointsFunc = Instance.new("RemoteFunction", ReplicatedStorage)
getInitialPointsFunc.Name = "GetInitialMissionPoints"

-- =============================================================================
-- FUNGSI INTI
-- =============================================================================

function MissionPointsModule.GetData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[MissionPointsModule] Gagal mendapatkan data untuk pemain: " .. player.Name)
		return { MissionPoints = 0 }
	end

	-- Poin misi sekarang disimpan di dalam data Stats
	if not playerData.data.stats then
		-- Inisialisasi jika tidak ada
		local defaultData = require(script.Parent:WaitForChild("DataStoreManager")).DEFAULT_PLAYER_DATA
		playerData.data.stats = {}
		for k, v in pairs(defaultData.stats) do playerData.data.stats[k] = v end
		DataStoreManager:UpdatePlayerData(player, playerData.data)
	end

	if playerData.data.stats.MissionPoints == nil then
		playerData.data.stats.MissionPoints = 0
	end

	return { MissionPoints = playerData.data.stats.MissionPoints }
end

function MissionPointsModule.SaveData(player, mpData)
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.data then return end

	if not playerData.data.stats then
		playerData.data.stats = {}
	end

	playerData.data.stats.MissionPoints = mpData.MissionPoints
	DataStoreManager:UpdatePlayerData(player, playerData.data)
end

-- =============================================================================
-- API PUBLIK
-- =============================================================================

function MissionPointsModule:AddMissionPoints(player, amount)
	if not player or not tonumber(amount) or amount <= 0 then return end
	local data = self.GetData(player)
	data.MissionPoints += amount
	self.SaveData(player, data)

	DataStoreManager:UpdateLeaderboard("MPLeaderboard_v1", player.UserId, data.MissionPoints)
	missionPointsChangedEvent:FireClient(player, data.MissionPoints)
end

function MissionPointsModule:RemoveMissionPoints(player, amount)
	if not player or not tonumber(amount) or amount <= 0 then return false end
	local data = self.GetData(player)
	if data.MissionPoints < amount then return false end
	data.MissionPoints -= amount
	self.SaveData(player, data)
	missionPointsChangedEvent:FireClient(player, data.MissionPoints)
	return true
end

function MissionPointsModule:GetMissionPoints(player)
	return self.GetData(player).MissionPoints
end

-- =============================================================================
-- KONEKSI EVENT
-- =============================================================================

getInitialPointsFunc.OnServerInvoke = function(player)
	return MissionPointsModule:GetMissionPoints(player)
end

local function onPlayerAdded(player)
	task.spawn(function()
		local points = MissionPointsModule:GetMissionPoints(player)
		missionPointsChangedEvent:FireClient(player, points)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

return MissionPointsModule
