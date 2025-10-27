-- HitmarkerUI.lua (LocalScript)
-- Path: StarterGui/HitmarkerUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local HitmarkerEvent = RemoteEvents:WaitForChild("HitmarkerEvent")

-- BUAT/PAKAI overlay khusus efek biar aman di mobile
local effectsGui = Instance.new("ScreenGui")
effectsGui.Name = "HitmarkerUI"
effectsGui.ResetOnSpawn = false
effectsGui.IgnoreGuiInset = false  -- kunci agar pusatnya benar di mobile
effectsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
effectsGui.DisplayOrder = 1000    -- pastikan di atas HUD lain
effectsGui.Parent = playerGui

-- Fungsi untuk membuat hitmarker
local function createHitmarker(isHeadshot)
	local hitmarkerColor = isHeadshot and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 0)

	local hitmarkerFrame = Instance.new("Frame")
	hitmarkerFrame.Name = "Hitmarker"
	hitmarkerFrame.Size = UDim2.new(0, 50, 0, 50)
	hitmarkerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	local UIS = game:GetService("UserInputService")

	-- Posisi yang dibedakan per platform
	local HITMARKER_POS_DESKTOP = UDim2.new(0.5, 0, 0.5, 0)   -- Desktop: tepat di tengah
	local HITMARKER_POS_MOBILE  = UDim2.new(0.5, 0, 0.5, 0)  -- Mobile: sedikit lebih bawah (aman notch)

	hitmarkerFrame.Position = UIS.TouchEnabled and HITMARKER_POS_MOBILE or HITMARKER_POS_DESKTOP
	hitmarkerFrame.BackgroundTransparency = 1
	hitmarkerFrame.Parent = effectsGui

	-- Garis diagonal pertama (bentuk /)
	local line1 = Instance.new("Frame")
	line1.Size = UDim2.new(1, 0, 0, 2)
	line1.Rotation = 45
	line1.AnchorPoint = Vector2.new(0.5, 0.5)
	line1.Position = UDim2.new(0.5, 0, -0.1, 0)
	line1.BackgroundColor3 = hitmarkerColor
	line1.BorderSizePixel = 0
	line1.Parent = hitmarkerFrame

	-- Garis diagonal kedua (bentuk \)
	local line2 = Instance.new("Frame")
	line2.Size = UDim2.new(1, 0, 0, 2)
	line2.Rotation = -45
	line2.AnchorPoint = Vector2.new(0.5, 0.5)
	line2.Position = UDim2.new(0.5, 0, -0.1, 0)
	line2.BackgroundColor3 = hitmarkerColor
	line2.BorderSizePixel = 0
	line2.Parent = hitmarkerFrame

	-- Animasi hitmarker
	local fadeInOutInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local function animateHitmarker(targetSize)
		local sizeTween1 = TweenService:Create(line1, fadeInOutInfo, {Size = targetSize})
		local sizeTween2 = TweenService:Create(line2, fadeInOutInfo, {Size = targetSize})
		sizeTween1:Play()
		sizeTween2:Play()
	end

	-- Mulai animasi hitmarker
	animateHitmarker(UDim2.new(0, 30, 0, 2))
	task.wait(0.15)
	Debris:AddItem(hitmarkerFrame, 0.1)
end

HitmarkerEvent.OnClientEvent:Connect(function(isHeadshot)
	createHitmarker(isHeadshot)
end)
