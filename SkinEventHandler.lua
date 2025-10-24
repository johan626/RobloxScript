-- SkinEventHandler.lua (Script)
-- Path: ServerScriptService/Script/SkinEventHandler.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SkinManager = require(ServerScriptService.ModuleScript:WaitForChild("SkinManager"))

-- Pastikan folder RemoteEvents ada
local RemoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEventsFolder then
	RemoteEventsFolder = Instance.new("Folder")
	RemoteEventsFolder.Name = "RemoteEvents"
	RemoteEventsFolder.Parent = ReplicatedStorage
end

-- Buat RemoteEvent jika belum ada
local SkinManagementEvent = RemoteEventsFolder:FindFirstChild("SkinManagementEvent")
if not SkinManagementEvent then
	SkinManagementEvent = Instance.new("RemoteEvent")
	SkinManagementEvent.Name = "SkinManagementEvent"
	SkinManagementEvent.Parent = RemoteEventsFolder
end

-- Menghubungkan event ke fungsi di SkinManager
SkinManagementEvent.OnServerEvent:Connect(function(player, action, weaponName, skinName)
	if action == "EquipSkin" then
		-- Memanggil fungsi dari SkinManager untuk mengganti skin.
		-- Hasilnya (berhasil/gagal) akan dicetak di log server oleh SkinManager.
		SkinManager.EquipSkin(player, weaponName, skinName)
	end
end)
