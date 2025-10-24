-- LobbyManager.lua (Script)
-- Path: ServerScriptService/Script/LobbyManager.lua
-- Script Place: Lobby

local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))
DataStoreManager:Init()

-- Memanggil modul-modul yang diperlukan agar event PlayerAdded-nya aktif di Lobby
local LevelManager = require(ServerScriptService.ModuleScript:WaitForChild("LevelModule"))
local CoinsManager = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))
local ProfileModule = require(ServerScriptService.ModuleScript:WaitForChild("ProfileModule"))
local SkillModule = require(ServerScriptService.ModuleScript:WaitForChild("SkillModule")) -- Tambahkan ini
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteFunction for Profile Data
if ReplicatedStorage:FindFirstChild("GetProfileData") then
	ReplicatedStorage.GetProfileData:Destroy()
end
local profileRemoteFunction = Instance.new("RemoteFunction")
profileRemoteFunction.Name = "GetProfileData"
profileRemoteFunction.Parent = ReplicatedStorage

profileRemoteFunction.OnServerInvoke = function(player)
	return ProfileModule.GetProfileData(player)
end

-- Create RemoteFunction for Inventory Data
if ReplicatedStorage:FindFirstChild("GetInventoryData") then
	ReplicatedStorage.GetInventoryData:Destroy()
end
local inventoryRemoteFunction = Instance.new("RemoteFunction")
inventoryRemoteFunction.Name = "GetInventoryData"
inventoryRemoteFunction.Parent = ReplicatedStorage

inventoryRemoteFunction.OnServerInvoke = function(player)
	return CoinsManager.GetData(player)
end

-- Integrasi Sistem Hadiah Harian
local DailyRewardManager = require(ServerScriptService.ModuleScript.DailyRewardManager)
local MissionManager = require(ServerScriptService.ModuleScript.MissionManager)
local AchievementManager = require(ServerScriptService.ModuleScript:WaitForChild("AchievementManager"))

-- Integrasi Sistem Misi
if ReplicatedStorage.RemoteEvents:FindFirstChild("GetMissionData") then
	ReplicatedStorage.RemoteEvents.GetMissionData:Destroy()
end
local getMissionData = Instance.new("RemoteFunction")
getMissionData.Name = "GetMissionData"
getMissionData.Parent = ReplicatedStorage.RemoteEvents

getMissionData.OnServerInvoke = function(player)
	-- Fungsi ini sekarang akan mengambil data yang sudah diformat untuk klien
	return MissionManager:GetMissionDataForClient(player)
end

if ReplicatedStorage.RemoteEvents:FindFirstChild("ClaimMissionReward") then
	ReplicatedStorage.RemoteEvents.ClaimMissionReward:Destroy()
end
local claimMissionReward = Instance.new("RemoteFunction")
claimMissionReward.Name = "ClaimMissionReward"
claimMissionReward.Parent = ReplicatedStorage.RemoteEvents

claimMissionReward.OnServerInvoke = function(player, missionID)
	return MissionManager:ClaimMissionReward(player, missionID)
end

-- Integrasi Sistem Achievement

-- 1. Buat RemoteFunction untuk mendapatkan info hadiah
if ReplicatedStorage.RemoteEvents:FindFirstChild("GetDailyRewardInfo") then
	ReplicatedStorage.RemoteEvents.GetDailyRewardInfo:Destroy()
end
local getRewardInfo = Instance.new("RemoteFunction")
getRewardInfo.Name = "GetDailyRewardInfo"
getRewardInfo.Parent = ReplicatedStorage.RemoteEvents

getRewardInfo.OnServerInvoke = function(player)
	return DailyRewardManager:GetPlayerState(player)
end

-- 2. Buat RemoteFunction untuk mengklaim hadiah
if ReplicatedStorage.RemoteEvents:FindFirstChild("ClaimDailyReward") then
	ReplicatedStorage.RemoteEvents.ClaimDailyReward:Destroy()
end
local claimRewardEvent = Instance.new("RemoteFunction")
claimRewardEvent.Name = "ClaimDailyReward"
claimRewardEvent.Parent = ReplicatedStorage.RemoteEvents

claimRewardEvent.OnServerInvoke = function(player)
	return DailyRewardManager:ClaimReward(player)
end

-- 3. Buat RemoteEvent untuk memicu UI
local showRewardUIEvent = Instance.new("RemoteEvent")
showRewardUIEvent.Name = "ShowDailyRewardUI"
showRewardUIEvent.Parent = ReplicatedStorage.RemoteEvents

-- 4. Cek saat pemain bergabung
game.Players.PlayerAdded:Connect(function(player)
	DataStoreManager:LoadPlayerData(player)
	-- Tunggu sebentar agar semua data pemain dimuat
	task.wait(2)

	local playerState = DailyRewardManager:GetPlayerState(player)
	if playerState and playerState.CanClaim then
		showRewardUIEvent:FireClient(player)
	end
end)
