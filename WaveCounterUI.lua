-- WaveCounterUI.lua (LocalScript)
-- Path: StarterGui/WaveCounterUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local WaveUpdateEvent = RemoteEvents:WaitForChild("WaveUpdateEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WaveCounterUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = true
screenGui.Parent = playerGui

-- Buat container untuk wave counter
local waveContainer = Instance.new("Frame")
waveContainer.Name = "WaveContainer"
waveContainer.Size = UDim2.new(0.7, 0, 0.1, 0)  -- 70% width, 10% height
waveContainer.Position = UDim2.new(0.5, 0, 0.03, 0)  -- Centered at top
waveContainer.AnchorPoint = Vector2.new(0.5, 0)
waveContainer.BackgroundTransparency = 1
waveContainer.Parent = screenGui

-- Add constraints for responsive sizing
local uiSizeConstraint = Instance.new("UISizeConstraint")
uiSizeConstraint.MinSize = Vector2.new(250, 60)  -- Minimum size
uiSizeConstraint.MaxSize = Vector2.new(500, 100)  -- Maximum size
uiSizeConstraint.Parent = waveContainer

-- Label untuk wave number
local waveLabel = Instance.new("TextLabel")
waveLabel.Name = "WaveLabel"
waveLabel.Size = UDim2.new(1, 0, 0.6, 0)
waveLabel.Position = UDim2.new(0, 0, 0, 0)
waveLabel.BackgroundTransparency = 1
waveLabel.TextColor3 = Color3.new(1, 1, 1)
waveLabel.TextScaled = true
waveLabel.Font = Enum.Font.Fantasy
waveLabel.TextStrokeTransparency = 0
waveLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
waveLabel.Text = "Wave: 0"
waveLabel.Visible = false
waveLabel.Parent = waveContainer

-- Label untuk countdown
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name = "CountdownLabel"
countdownLabel.Size = UDim2.new(1, 0, 0.4, 0)
countdownLabel.Position = UDim2.new(0, 0, 0.6, 0)
countdownLabel.BackgroundTransparency = 1
countdownLabel.TextColor3 = Color3.new(1, 0.8, 0)
countdownLabel.TextScaled = true
countdownLabel.Font = Enum.Font.Fantasy
countdownLabel.TextStrokeTransparency = 0
countdownLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
countdownLabel.Text = "Next wave in: 0"
countdownLabel.Visible = false
countdownLabel.Parent = waveContainer

-- Animasi untuk countdown
local function animateCountdown()
	local goalSize = UDim2.new(1.2, 0, 0.6, 0)
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(countdownLabel, tweenInfo, {Size = goalSize})
	tween:Play()

	task.wait(0.2)

	local tweenInfo2 = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	local tween2 = TweenService:Create(countdownLabel, tweenInfo2, {Size = UDim2.new(1, 0, 0.4, 0)})
	tween2:Play()
end

WaveUpdateEvent.OnClientEvent:Connect(function(wave)
	waveLabel.Text = "Wave: " .. tostring(wave)
	waveLabel.Visible = true
	countdownLabel.Visible = false
end)

-- Terima event countdown dari server
local WaveCountdownEvent = ReplicatedStorage.RemoteEvents:WaitForChild("WaveCountdownEvent")
WaveCountdownEvent.OnClientEvent:Connect(function(seconds)
	if seconds > 0 then
		countdownLabel.Text = "Next wave in: " .. seconds
		countdownLabel.Visible = true
		animateCountdown()
	else
		countdownLabel.Visible = false
	end
end)
