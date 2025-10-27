-- MuzzleFlashHandler.lua (Script)
-- Path: ServerScriptService/Script/MuzzleFlashHandler.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))

local MuzzleFlashEvent = RemoteEvents:WaitForChild("MuzzleFlashEvent")
local MuzzleFlashBroadcast = RemoteEvents:WaitForChild("MuzzleFlashBroadcast")

MuzzleFlashEvent.OnServerEvent:Connect(function(player, handle, weaponName)
	local char = player.Character
	if not char then return end

	-- Cari tool yang sesuai dengan weaponName di karakter
	local tool = char:FindFirstChild(weaponName)
	if not tool or not tool:IsA("Tool") then return end

	local handle = tool:FindFirstChild("Handle")
	if not handle then return end

	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return end

	local muzzleOffset = weaponStats.MuzzleOffset or Vector3.new(0, 0, -1)
	local flashCFrame = handle.CFrame * CFrame.new(muzzleOffset)

	-- Broadcast ke semua klien
	MuzzleFlashBroadcast:FireAllClients(flashCFrame, weaponName)
end)
