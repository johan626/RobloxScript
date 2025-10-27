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

-- Struktur data default
local DEFAULT_MISSION_POINTS = {
	MissionPoints = 0
}

-- =============================================================================
-- FUNGSI INTI
-- =============================================================================

function MissionPointsModule.GetData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[MissionPointsModule] Gagal mendapatkan data bahkan setelah menunggu untuk pemain: " .. player.Name)
		return table.clone(DEFAULT_MISSION_POINTS)
	end

	-- Poin misi disimpan di dalam data Inventory
	if not playerData.data.inventory then
		playerData.data.inventory = {}
	end

	if playerData.data.inventory.MissionPoints == nil then
		playerData.data.inventory.MissionPoints = 0
	end

	return { MissionPoints = playerData.data.inventory.MissionPoints }
end

function MissionPointsModule.SaveData(player, mpData)
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.data then return end

	if not playerData.data.inventory then
		playerData.data.inventory = {}
	end

	playerData.data.inventory.MissionPoints = mpData.MissionPoints
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

	-- Update leaderboard
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

local function initializePlayerData(player)
	task.spawn(function()
		local points = MissionPointsModule:GetMissionPoints(player)
		missionPointsChangedEvent:FireClient(player, points)
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

return MissionPointsModule
