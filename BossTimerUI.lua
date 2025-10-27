-- BossTimerUI.lua (LocalScript)
-- Path: StarterGui/BossTimerUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local BossTimerEvent = RemoteEvents:WaitForChild("BossTimerEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BossTimerUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = true
screenGui.Parent = playerGui

local timerContainer = nil -- Akan dibuat on-demand

local function createTimerUI()
	if timerContainer then return end -- UI sudah ada

	local isMobile = UserInputService.TouchEnabled

	timerContainer = Instance.new("Frame")
	timerContainer.Name = "BossTimerContainer"
	if isMobile then
		timerContainer.Size = UDim2.new(0.3, 0, 0.08, 0)
		timerContainer.Position = UDim2.new(0.5, 0, 0.12, 0)
	else
		timerContainer.Size = UDim2.new(0.3, 0, 0.08, 0)
		timerContainer.Position = UDim2.new(0.5, 0, 0.10, 0)
	end
	timerContainer.AnchorPoint = Vector2.new(0.5, 0)
	timerContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	timerContainer.BackgroundTransparency = 0.7
	timerContainer.BorderSizePixel = 0
	timerContainer.Visible = true -- Langsung terlihat saat dibuat
	timerContainer.Parent = screenGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 8)
	containerCorner.Parent = timerContainer

	local timerText = Instance.new("TextLabel")
	timerText.Name = "TimerText"
	timerText.Size = UDim2.new(1, 0, 0.6, 0)
	timerText.Position = UDim2.new(0, 0, 0, 0)
	timerText.BackgroundTransparency = 1
	timerText.Text = "BOSS TIMER: 00:00"
	timerText.TextColor3 = Color3.fromRGB(255, 50, 50)
	timerText.TextScaled = true
	timerText.Font = Enum.Font.GothamBlack
	timerText.TextStrokeTransparency = 0
	timerText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	timerText.Parent = timerContainer

	local progressBarBg = Instance.new("Frame")
	progressBarBg.Name = "ProgressBarBg"
	progressBarBg.Size = UDim2.new(0.9, 0, 0, isMobile and 6 or 8)
	progressBarBg.Position = UDim2.new(0.05, 0, 0.7, 0)
	progressBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	progressBarBg.BorderSizePixel = 0
	progressBarBg.Parent = timerContainer

	local progressBarBgCorner = Instance.new("UICorner")
	progressBarBgCorner.CornerRadius = UDim.new(1, 0)
	progressBarBgCorner.Parent = progressBarBg

	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(1, 0, 1, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressBarBg

	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(1, 0)
	progressBarCorner.Parent = progressBar
end

local function destroyTimerUI()
	if timerContainer then
		timerContainer:Destroy()
		timerContainer = nil
	end
end

local function updateTimerUI(remainingTime, totalTime)
	if not timerContainer then return end

	local timerText = timerContainer:FindFirstChild("TimerText")
	local progressBar = timerContainer.ProgressBarBg:FindFirstChild("ProgressBar")

	if not timerText or not progressBar then return end

	local minutes = math.floor(remainingTime / 60)
	local seconds = math.floor(remainingTime % 60)
	timerText.Text = string.format("BOSS TIMER: %02d:%02d", minutes, seconds)

	local progress = remainingTime / totalTime
	progressBar.Size = UDim2.new(progress, 0, 1, 0)

	if remainingTime < 60 then
		timerText.TextColor3 = Color3.fromRGB(255, 0, 0)
		progressBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		local pulseInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true)
		local pulseTween = TweenService:Create(timerText, pulseInfo, {TextTransparency = 0.3})
		pulseTween:Play()
	elseif remainingTime < 120 then
		timerText.TextColor3 = Color3.fromRGB(255, 100, 0)
		progressBar.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
	else
		timerText.TextColor3 = Color3.fromRGB(255, 50, 50)
		progressBar.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
	end
end

BossTimerEvent.OnClientEvent:Connect(function(remainingTime, totalTime)
	if remainingTime <= 0 or totalTime <= 0 then
		destroyTimerUI()
	else
		if not timerContainer then
			createTimerUI()
		end
		updateTimerUI(remainingTime, totalTime)
	end
end)
