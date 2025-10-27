-- ReviveUI.lua (LocalScript)
-- Path: StarterGui/ReviveUI.lua
-- Script Place: ACT 1: Village

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local ReviveEvent = RemoteEvents:WaitForChild("ReviveEvent")
local CancelReviveEvent = RemoteEvents:WaitForChild("CancelReviveEvent")
local ReviveProgressEvent = RemoteEvents:WaitForChild("ReviveProgressEvent")
local GameSettingsUpdateEvent = RemoteEvents:WaitForChild("GameSettingsUpdateEvent")

local currentDifficulty = "Easy" -- Default

GameSettingsUpdateEvent.OnClientEvent:Connect(function(settings)
	if settings and settings.difficulty then
		currentDifficulty = settings.difficulty
	end
end)

-- Revive progress UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ReviveUI"
screenGui.Parent = playerGui

local progressFrame = Instance.new("Frame")
progressFrame.Size = UDim2.new(0.3, 0, 0.05, 0)
progressFrame.Position = UDim2.new(0.35, 0, 0.5, 0)
progressFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
progressFrame.BackgroundTransparency = 0.3
progressFrame.BorderSizePixel = 0
progressFrame.Visible = false
progressFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = progressFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Thickness = 2
frameStroke.Color = Color3.fromRGB(255, 255, 255)
frameStroke.Parent = progressFrame

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressFrame

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 10)
barCorner.Parent = progressBar

local barGradient = Instance.new("UIGradient")
barGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 0))
})
barGradient.Rotation = 0
barGradient.Parent = progressBar

local progressText = Instance.new("TextLabel")
progressText.Size = UDim2.new(1, 0, 1, 0)
progressText.BackgroundTransparency = 1
progressText.Text = "Reviving: 0%"
progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
progressText.TextScaled = true
progressText.Parent = progressFrame

local mobileReviveBtn = Instance.new("TextButton")
mobileReviveBtn.Size = UDim2.new(0, 100, 0, 100)
mobileReviveBtn.Position = UDim2.new(0.5, -50, 0.7, -50)
mobileReviveBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
mobileReviveBtn.BackgroundTransparency = 0.5
mobileReviveBtn.Text = "+"
mobileReviveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mobileReviveBtn.TextScaled = true
mobileReviveBtn.Visible = false
mobileReviveBtn.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 50)
corner.Parent = mobileReviveBtn

local revivePrompt = Instance.new("TextLabel")
revivePrompt.Size = UDim2.new(0, 200, 0, 50)
revivePrompt.Position = UDim2.new(0.5, -100, 0.6, 0)
revivePrompt.BackgroundTransparency = 1
revivePrompt.Text = "Press E to Revive"
revivePrompt.TextColor3 = Color3.fromRGB(255, 255, 255)
revivePrompt.TextScaled = true
revivePrompt.Visible = false
revivePrompt.Parent = screenGui

local isReviving = false
local currentTarget = nil
local totalReviveTime = 6

ReviveProgressEvent.OnClientEvent:Connect(function(progress, cancelled, reviveTime)
	if cancelled then
		progressFrame.Visible = false
		isReviving = false
		currentTarget = nil
		return
	end

	if reviveTime then
		totalReviveTime = reviveTime
	end

	progressBar.Size = UDim2.new(progress, 0, 1, 0)
	progressText.Text = string.format("Reviving: %d%% (%.1fs)", math.floor(progress * 100), totalReviveTime * (1 - progress))
	progressFrame.Visible = true

	if progress >= 1 then
		progressFrame.Visible = false
		isReviving = false
		currentTarget = nil
	end
end)

local function startRevive(target)
	if player.Character and player.Character:FindFirstChild("Knocked") then
		return
	end

	if isReviving then return end
	isReviving = true
	currentTarget = target
	ReviveEvent:FireServer(target)
end

local function cancelRevive()
	if isReviving then
		CancelReviveEvent:FireServer()
		isReviving = false
		currentTarget = nil
		progressFrame.Visible = false
	end
end

UIS.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if isReviving then
			cancelRevive()
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if isReviving then
		if UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.A) or
			UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.D) or
			UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.R) or
			UIS:IsKeyDown(Enum.KeyCode.Q) then
			cancelRevive()
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if currentDifficulty == "Crazy" then
		revivePrompt.Visible = false
		mobileReviveBtn.Visible = false
		return
	end

	local char = player.Character
	if char and char:FindFirstChild("Knocked") then
		revivePrompt.Visible = false
		mobileReviveBtn.Visible = false
		isReviving = false
		currentTarget = nil
		return
	end

	local targetToRevive = nil
	if not char or not char:FindFirstChild("HumanoidRootPart") then
		revivePrompt.Visible = false
		mobileReviveBtn.Visible = false
		return
	end

	for _, other in pairs(game.Players:GetPlayers()) do
		local success, foundPlayer = pcall(function()
			if other ~= player and other.Character and other.Character:FindFirstChild("Knocked") then
				local dist = (char.HumanoidRootPart.Position - other.Character.HumanoidRootPart.Position).Magnitude
				if dist < 8 then
					return other
				end
			end
		end)

		if success and foundPlayer then
			targetToRevive = foundPlayer
			break
		elseif not success then
			warn("Error occurred during revive check: " .. tostring(foundPlayer))
		end
	end

	if UIS.TouchEnabled then
		mobileReviveBtn.Visible = targetToRevive ~= nil and not isReviving
		revivePrompt.Visible = false
	else
		revivePrompt.Visible = targetToRevive ~= nil and not isReviving
		mobileReviveBtn.Visible = false
	end

	if targetToRevive and UIS:IsKeyDown(Enum.KeyCode.E) and not isReviving then
		startRevive(targetToRevive)
	end
end)

mobileReviveBtn.MouseButton1Down:Connect(function()
	local char = player.Character
	if not char then return end

	for _, other in pairs(game.Players:GetPlayers()) do
		local success, foundPlayer = pcall(function()
			if other ~= player and other.Character and other.Character:FindFirstChild("Knocked") then
				local dist = (char.HumanoidRootPart.Position - other.Character.HumanoidRootPart.Position).Magnitude
				if dist < 8 and not isReviving then
					return other
				end
			end
		end)

		if success and foundPlayer then
			startRevive(foundPlayer)
			break
		elseif not success then
			warn("Error occurred during mobile revive check: " .. tostring(foundPlayer))
		end
	end
end)
