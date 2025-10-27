-- TracerHandler.lua (Script)
-- Path: ServerScriptService/Script/TracerHandler.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local TracerEvent = ReplicatedStorage.RemoteEvents:WaitForChild("TracerEvent")
local TracerBroadcast = ReplicatedStorage.RemoteEvents:WaitForChild("TracerBroadcast")

local TRACER_COLOR = Color3.fromRGB(255, 200, 50)
local TRACER_WIDTH = 0.1

TracerEvent.OnServerEvent:Connect(function(player, startPos, endPos, weaponName)
	local weaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))
	local weaponStats = weaponModule.Weapons[weaponName]
	if not weaponStats then return end

	-- Broadcast ke semua client untuk render tracer di sisi client
	TracerBroadcast:FireAllClients(player, startPos, endPos, weaponName)
end)
