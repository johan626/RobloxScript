-- GameOverUI.lua (LocalScript)
-- Path: StarterGui/GameOverUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local GameOverEvent = RemoteEvents:WaitForChild("GameOverEvent")
local ExitGameEvent = RemoteEvents:WaitForChild("ExitGameEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameOverUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = true
screenGui.Parent = gui

-- Create a container frame for the game over UI
local gameOverContainer = Instance.new("Frame")
gameOverContainer.Name = "GameOverContainer"
gameOverContainer.Size = UDim2.new(1, 0, 1, 0)
gameOverContainer.Position = UDim2.new(0, 0, 0, 0)
gameOverContainer.BackgroundTransparency = 1
gameOverContainer.Visible = false
gameOverContainer.ZIndex = 10
gameOverContainer.Parent = screenGui

-- Animated background
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.Position = UDim2.new(0, 0, 0, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 1
background.ZIndex = 10
background.Parent = gameOverContainer

-- Label "GAME OVER"
local gameOverLabel = Instance.new("TextLabel")
gameOverLabel.Name = "GameOverLabel"
gameOverLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
gameOverLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
gameOverLabel.BackgroundTransparency = 1
gameOverLabel.TextScaled = true
gameOverLabel.Font = Enum.Font.SourceSansBold
gameOverLabel.TextColor3 = Color3.fromRGB(200, 0, 0)
gameOverLabel.Text = "GAME OVER"
gameOverLabel.ZIndex = 11
gameOverLabel.Parent = gameOverContainer

-- Exit button
local exitBtn = Instance.new("TextButton")
exitBtn.Name = "ExitBtn"
exitBtn.Size = UDim2.new(0.3, 0, 0.1, 0)
exitBtn.Position = UDim2.new(0.35, 0, 0.6, 0)
exitBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
exitBtn.TextScaled = true
exitBtn.Font = Enum.Font.SourceSansBold
exitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
exitBtn.Text = "Return to Lobby"
exitBtn.ZIndex = 11
exitBtn.Parent = gameOverContainer

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.1, 0)
corner.Parent = exitBtn

-- Animation function
local function animateGameOver()
	gameOverContainer.Visible = true
	TweenService:Create(background, TweenInfo.new(1), { BackgroundTransparency = 0.5 }):Play()
end

-- Event listener for GameOverEvent
GameOverEvent.OnClientEvent:Connect(function()
	animateGameOver()
end)

-- Event listener for the exit button
exitBtn.MouseButton1Click:Connect(function()
	ExitGameEvent:FireServer()
end)