-- MuzzleFlashClient.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/MuzzleFlashClient.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local MuzzleFlashBroadcast = RemoteEvents:WaitForChild("MuzzleFlashBroadcast")

MuzzleFlashBroadcast.OnClientEvent:Connect(function(flashCFrame, weaponName)
	-- Create flash part
	local flash = Instance.new("Part")
	flash.Name = "MuzzleFlash"
	flash.Size = Vector3.new(0.5, 0.5, 0.5)
	flash.Shape = Enum.PartType.Ball
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(255, 100, 0)
	flash.Transparency = 1
	flash.Anchored = true
	flash.CanCollide = false
	flash.CFrame = flashCFrame

	-- Create fire effect
	local fire = Instance.new("Fire")
	fire.Heat = 25
	fire.Size = 0.01
	fire.Parent = flash

	-- Create point light
	local light = Instance.new("PointLight")
	light.Brightness = 5
	light.Range = 15
	light.Color = Color3.fromRGB(255, 100, 0)
	light.Parent = flash

	flash.Parent = workspace
	Debris:AddItem(flash, 0.06)
end)
