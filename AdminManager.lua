-- AdminManager.lua (Script)
-- Path: ServerScriptService/Script/AdminManager.lua
-- Script Place: Lobby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreManager = require(script.Parent.Parent.ModuleScript:WaitForChild("DataStoreManager"))
local AdminConfig = require(ServerScriptService.ModuleScript:WaitForChild("AdminConfig"))

local AdminManager = {}

-- Folder & Event
local adminEventsFolder = ReplicatedStorage:FindFirstChild("AdminEvents") or Instance.new("Folder", ReplicatedStorage)
adminEventsFolder.Name = "AdminEvents"

local requestDataFunc = adminEventsFolder:FindFirstChild("AdminRequestData") or Instance.new("RemoteFunction", adminEventsFolder)
requestDataFunc.Name = "AdminRequestData"

local updateDataEvent = adminEventsFolder:FindFirstChild("AdminUpdateData") or Instance.new("RemoteEvent", adminEventsFolder)
updateDataEvent.Name = "AdminUpdateData"

local deleteDataEvent = adminEventsFolder:FindFirstChild("AdminDeleteData") or Instance.new("RemoteEvent", adminEventsFolder)
deleteDataEvent.Name = "AdminDeleteData"

local restoreDataEvent = adminEventsFolder:FindFirstChild("AdminRestoreData") or Instance.new("RemoteEvent", adminEventsFolder)
restoreDataEvent.Name = "AdminRestoreData"

-- Fungsi untuk menggabungkan tabel secara rekursif
local function deepMerge(t1, t2)
	for k, v in pairs(t2) do
		if type(v) == "table" and type(t1[k]) == "table" then
			deepMerge(t1[k], v)
		else
			t1[k] = v
		end
	end
	return t1
end

-- =============================================================================
-- HANDLER REMOTE
-- =============================================================================

requestDataFunc.OnServerInvoke = function(adminPlayer, targetUserId)
	if not AdminConfig.IsAdmin(adminPlayer) then return nil, "Unauthorized" end
	if type(targetUserId) ~= "number" then return nil, "Invalid UserID" end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	local data

	if targetPlayer then
		data = DataStoreManager:GetPlayerData(targetPlayer)
	else
		data = DataStoreManager:LoadOfflinePlayerData(targetUserId) 
	end

	if not data or not data.data then return nil, "No data found" end

	return data.data -- Kirim data mentah
end

updateDataEvent.OnServerEvent:Connect(function(adminPlayer, targetUserId, newData)
	if not AdminConfig.IsAdmin(adminPlayer) then return end
	if type(targetUserId) ~= "number" or type(newData) ~= "table" then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	local currentData

	if targetPlayer then
		currentData = DataStoreManager:GetPlayerData(targetPlayer)
	else
		currentData = DataStoreManager:LoadOfflinePlayerData(targetUserId)
	end

	if not currentData or not currentData.data then return end

	local mergedData = deepMerge(currentData.data, newData)

	if targetPlayer then
		DataStoreManager:UpdatePlayerData(targetPlayer, mergedData)
	else
		DataStoreManager:SaveOfflinePlayerData(targetUserId, mergedData)
	end

	DataStoreManager:LogAdminAction(adminPlayer, "update", targetUserId)
end)

deleteDataEvent.OnServerEvent:Connect(function(adminPlayer, targetUserId)
	if not AdminConfig.IsAdmin(adminPlayer) then return end
	if type(targetUserId) ~= "number" then return end

	DataStoreManager:DeletePlayerData(targetUserId)
	DataStoreManager:LogAdminAction(adminPlayer, "delete", targetUserId)
end)

restoreDataEvent.OnServerEvent:Connect(function(adminPlayer, targetUserId)
	if not AdminConfig.IsAdmin(adminPlayer) then return end
	if type(targetUserId) ~= "number" then return end

	DataStoreManager:RestorePlayerDataFromBackup(adminPlayer, targetUserId)
	-- Logging dapat ditangani di dalam fungsi Restore jika diimplementasikan
end)

-- =============================================================================
-- INISIALISASI
-- =============================================================================

Players.PlayerAdded:Connect(function(player)
	if AdminConfig.IsAdmin(player) then
		player:SetAttribute("IsAdmin", true)
	end
end)

return AdminManager
