-- BossAlertUI.lua (LocalScript)
-- Path: StarterGui/BossAlertUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local bossIncoming = RemoteEvents:WaitForChild("BossIncoming")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BossAlertUI"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = gui

bossIncoming.OnClientEvent:Connect(function(bossName)
	-- Screen shake effect
	local camera = workspace.CurrentCamera
	local originalPosition = camera.CFrame
	local shakeIntensity = 0.5
	local shakeDuration = 0.5

	local shakeStart = tick()
	local shakeConnection
	shakeConnection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - shakeStart
		if elapsed < shakeDuration then
			local intensity = shakeIntensity * (1 - elapsed/shakeDuration)
			local offset = Vector3.new(
				(math.random() * 2 - 1) * intensity,
				(math.random() * 2 - 1) * intensity,
				(math.random() * 2 - 1) * intensity
			)
			camera.CFrame = originalPosition * CFrame.new(offset)
		else
			camera.CFrame = originalPosition
			shakeConnection:Disconnect()
		end
	end)

	-- Create main alert container
	local container = Instance.new("Frame")
	container.Name = "BossAlertContainer"
	container.Size = UDim2.new(0.7, 0, 0.25, 0)
	container.Position = UDim2.new(0.5, 0, -0.25, 0) -- Start off-screen at top
	container.AnchorPoint = Vector2.new(0.5, 0) -- Anchor to center-top
	container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.Parent = screenGui
	container.ZIndex = 10

	-- Add gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 0, 0)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(120, 0, 0)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(60, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 0, 0))
	}
	gradient.Transparency = NumberSequence.new(0.3)
	gradient.Parent = container

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = container

	-- Add multiple glowing border effects
	local outerStroke = Instance.new("UIStroke")
	outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outerStroke.Color = Color3.fromRGB(255, 50, 50)
	outerStroke.Thickness = 5
	outerStroke.Transparency = 0.7
	outerStroke.Parent = container

	local innerStroke = Instance.new("UIStroke")
	innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	innerStroke.Color = Color3.fromRGB(255, 150, 150)
	innerStroke.Thickness = 2
	innerStroke.Transparency = 0.5
	innerStroke.Parent = container

	-- Create animated skull icon
	local skullContainer = Instance.new("Frame")
	skullContainer.Name = "SkullContainer"
	skullContainer.Size = UDim2.new(0.2, 0, 0.8, 0)
	skullContainer.Position = UDim2.new(0.05, 0, 0.1, 0)
	skullContainer.BackgroundTransparency = 1
	skullContainer.Parent = container

	local skull = Instance.new("TextLabel")
	skull.Name = "SkullIcon"
	skull.Size = UDim2.new(1, 0, 1, 0)
	skull.Position = UDim2.new(0, 0, 0, 0)
	skull.BackgroundTransparency = 1
	skull.Text = "💀"
	skull.TextColor3 = Color3.fromRGB(255, 255, 255)
	skull.TextScaled = true
	skull.Font = Enum.Font.GothamBlack
	skull.ZIndex = 12
	skull.Parent = skullContainer

	-- Create pulsing glow behind skull
	local skullGlow = Instance.new("Frame")
	skullGlow.Name = "SkullGlow"
	skullGlow.Size = UDim2.new(1.5, 0, 1.5, 0)
	skullGlow.Position = UDim2.new(-0.25, 0, -0.25, 0)
	skullGlow.BackgroundTransparency = 1
	skullGlow.Parent = skullContainer

	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0.5, 0)
	glowCorner.Parent = skullGlow

	local glowGradient = Instance.new("UIGradient")
	glowGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 50))
	}
	glowGradient.Rotation = 90
	glowGradient.Parent = skullGlow

	-- Create main warning text
	local warningText = Instance.new("TextLabel")
	warningText.Name = "WarningText"
	warningText.Size = UDim2.new(0.6, 0, 0.4, 0)
	warningText.Position = UDim2.new(0.25, 0, 0.1, 0)
	warningText.BackgroundTransparency = 1
	warningText.Text = "BOSS INCOMING!"
	warningText.TextColor3 = Color3.fromRGB(255, 100, 100)
	warningText.TextScaled = true
	warningText.Font = Enum.Font.GothamBlack
	warningText.TextStrokeTransparency = 0.7
	warningText.TextStrokeColor3 = Color3.fromRGB(255, 0, 0)
	warningText.ZIndex = 12
	warningText.Parent = container

	-- Create sub warning text
	local subText = Instance.new("TextLabel")
	subText.Name = "SubText"
	subText.Size = UDim2.new(0.6, 0, 0.3, 0)
	subText.Position = UDim2.new(0.25, 0, 0.5, 0)
	subText.BackgroundTransparency = 1
	subText.Text = bossName or "Zombie Boss Approaching!"
	subText.TextColor3 = Color3.fromRGB(255, 180, 180)
	subText.TextScaled = true
	subText.Font = Enum.Font.GothamBold
	subText.ZIndex = 12
	subText.Parent = container

	-- Animation functions
	local function animateIn()
		-- Initial scale up with bounce effect
		container.Size = UDim2.new(0.1, 0, 0.05, 0)
		container.Position = UDim2.new(0.5, 0, 0.5, 0) -- Start at center
		container.AnchorPoint = Vector2.new(0.5, 0.5) -- Center anchor

		local scaleTweenInfo = TweenInfo.new(
			0.8, -- Time
			Enum.EasingStyle.Elastic, -- Easing style
			Enum.EasingDirection.Out, -- Easing direction
			0, -- Repeat count
			false, -- Reverses
			0 -- Delay
		)

		local scaleGoals = {
			Size = UDim2.new(0.7, 0, 0.25, 0)
		}

		local scaleTween = TweenService:Create(container, scaleTweenInfo, scaleGoals)
		scaleTween:Play()

		-- Slide down from top at the same time
		local slideTweenInfo = TweenInfo.new(
			0.6, -- Time
			Enum.EasingStyle.Back, -- Easing style
			Enum.EasingDirection.Out, -- Easing direction
			0, -- Repeat count
			false, -- Reverses
			0 -- Delay
		)

		local slideGoals = {
			Position = UDim2.new(0.5, 0, 0.4, 0) -- Final position (centered vertically)
		}

		local slideTween = TweenService:Create(container, slideTweenInfo, slideGoals)
		slideTween:Play()
	end

	local function animateOut()
		local tweenInfo = TweenInfo.new(
			0.8, -- Time
			Enum.EasingStyle.Cubic, -- Easing style
			Enum.EasingDirection.In, -- Easing direction
			0, -- Repeat count
			false, -- Reverses
			0 -- Delay
		)

		local goals = {
			Position = UDim2.new(0.5, 0, -0.3, 0), -- Move off-screen to top
			BackgroundTransparency = 1
		}

		local tween = TweenService:Create(container, tweenInfo, goals)
		tween:Play()

		-- Also fade out all text and elements
		for _, child in pairs(container:GetDescendants()) do
			if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("Frame") then
				if child.BackgroundTransparency < 1 then
					local bgTween = TweenService:Create(child, tweenInfo, {BackgroundTransparency = 1})
					bgTween:Play()
				end
				if child:IsA("TextLabel") or child:IsA("TextButton") then
					local textTween = TweenService:Create(child, tweenInfo, {TextTransparency = 1, TextStrokeTransparency = 1})
					textTween:Play()
				end
			end
			if child:IsA("UIStroke") then
				local strokeTween = TweenService:Create(child, tweenInfo, {Transparency = 1})
				strokeTween:Play()
			end
		end

		tween.Completed:Connect(function()
			container:Destroy()
		end)
	end

	-- Start animation sequence
	animateIn()

	-- Start pulse effects
	local pulseTime = 0
	local pulseConnection = RunService.Heartbeat:Connect(function(delta)
		pulseTime = pulseTime + delta
		local pulse = math.abs(math.sin(pulseTime * 3)) * 0.5
		local pulse2 = math.abs(math.sin(pulseTime * 2 + 0.5)) * 0.5

		outerStroke.Transparency = 0.3 + pulse * 0.5
		innerStroke.Transparency = 0.2 + pulse2 * 0.3

		-- Animate skull glow
		local glowSize = 1.5 + pulse * 0.3
		skullGlow.Size = UDim2.new(glowSize, 0, glowSize, 0)
		skullGlow.Position = UDim2.new(-glowSize/2 + 0.5, 0, -glowSize/2 + 0.5, 0)
	end)

	-- Animate skull rotation
	local skullTime = 0
	local skullConnection = RunService.Heartbeat:Connect(function(delta)
		skullTime = skullTime + delta
		skullContainer.Rotation = 5 * math.sin(skullTime * 2)
	end)

	-- Play sound if possible
	if game:GetService("SoundService"):FindFirstChild("BossAlertSound") then
		local sound = game:GetService("SoundService"):FindFirstChild("BossAlertSound")
		sound:Play()
	end

	-- Auto-remove after 5 seconds
	wait(5)
	animateOut()
	if pulseConnection then pulseConnection:Disconnect() end
	if skullConnection then skullConnection:Disconnect() end
end)
