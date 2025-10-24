-- LevelUI.lua
-- Path: StarterGui/LevelUI.lua
-- Script Place: Lobby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local LevelUpdateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("LevelUpdateEvent")

-- Buat UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LevelUI"
screenGui.Parent = playerGui

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 200, 0, 60)
container.Position = UDim2.new(0.5, -100, 0.05, 0)
container.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
container.BorderSizePixel = 0
container.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = container

local levelLabel = Instance.new("TextLabel")
levelLabel.Size = UDim2.new(0.3, 0, 1, 0)
levelLabel.Text = "LVL 1"
levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
levelLabel.TextScaled = true
levelLabel.Font = Enum.Font.GothamBold
levelLabel.BackgroundTransparency = 1
levelLabel.Parent = container

local xpBarBg = Instance.new("Frame")
xpBarBg.Size = UDim2.new(0.65, 0, 0.4, 0)
xpBarBg.Position = UDim2.new(0.35, 0, 0.3, 0)
xpBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
xpBarBg.Parent = container

local xpBar = Instance.new("Frame")
xpBar.Size = UDim2.new(0, 0, 1, 0)
xpBar.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
xpBar.Parent = xpBarBg

local xpLabel = Instance.new("TextLabel")
xpLabel.Size = UDim2.new(1, 0, 1, 0)
xpLabel.Text = "0/1000 XP"
xpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
xpLabel.TextScaled = true
xpLabel.Font = Enum.Font.Gotham
xpLabel.BackgroundTransparency = 1
xpLabel.Parent = xpBarBg

-- Fungsi untuk update UI
local function updateUI(level, xp, xpNeeded)
	levelLabel.Text = "LVL " .. level
	xpLabel.Text = string.format("%d/%d XP", xp, xpNeeded)

	local progress = xp / xpNeeded
	TweenService:Create(xpBar, TweenInfo.new(0.5), { Size = UDim2.new(progress, 0, 1, 0) }):Play()
end

-- Event listener
LevelUpdateEvent.OnClientEvent:Connect(updateUI)
