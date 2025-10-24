-- PointsUI.lua (LocalScript)
-- Path: StarterGui/PointsUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local PointsUpdate = RemoteEvents:WaitForChild("PointsUpdate")

-- Create main ScreenGui if it doesn't exist
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PointsUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = true
screenGui.Parent = playerGui

-- Function to check if device is mobile
local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- Create blood dripping effect container
local bloodContainer = Instance.new("Frame")
bloodContainer.Name = "BloodContainer"
bloodContainer.BackgroundTransparency = 1
bloodContainer.ClipsDescendants = true
bloodContainer.Parent = screenGui

-- Set size and position based on device type
if isMobile() then
	-- Mobile layout
	bloodContainer.Size = UDim2.new(0, 200, 0, 80)
	bloodContainer.Position = UDim2.new(0.77, 0, -0.02, 0)  -- Top right
	bloodContainer.AnchorPoint = Vector2.new(1, 0)
else
	-- Desktop layout
	bloodContainer.Size = UDim2.new(0, 280, 0, 120)
	bloodContainer.Position = UDim2.new(0.71, 0, -0.01, 0)  -- Top right
	bloodContainer.AnchorPoint = Vector2.new(1, 0)
end

-- Add constraints for responsive sizing
local uiSizeConstraint = Instance.new("UISizeConstraint")
uiSizeConstraint.MinSize = Vector2.new(150, 60)
uiSizeConstraint.MaxSize = Vector2.new(300, 120)
uiSizeConstraint.Parent = bloodContainer

-- Create blood splatter background (decorative)
local bloodSplatter = Instance.new("ImageLabel")
bloodSplatter.Name = "BloodSplatter"
bloodSplatter.Size = UDim2.new(1, 0, 1, 0)
bloodSplatter.Position = UDim2.new(0, 0, 0, 0)
bloodSplatter.BackgroundTransparency = 1
bloodSplatter.Image = "rbxassetid://10888332825" -- Blood splatter texture
bloodSplatter.ImageColor3 = Color3.fromRGB(120, 0, 0)
bloodSplatter.ImageTransparency = 0.7
bloodSplatter.ScaleType = Enum.ScaleType.Slice
bloodSplatter.SliceScale = 0.1
bloodSplatter.Parent = bloodContainer

-- Create main points text with horror style
local PointsLabel = Instance.new("TextLabel")
PointsLabel.Name = "PointsLabel"
PointsLabel.Size = UDim2.new(1, 0, 1, 0)
PointsLabel.Position = UDim2.new(0, 0, 0, 0)
PointsLabel.BackgroundTransparency = 1
PointsLabel.Text = "BP: 0"
PointsLabel.TextColor3 = Color3.fromRGB(255, 40, 40)
PointsLabel.TextStrokeColor3 = Color3.fromRGB(20, 0, 0)
PointsLabel.TextStrokeTransparency = 0.5
PointsLabel.Font = Enum.Font.SourceSansBold

-- Set text size based on device
if isMobile() then
	PointsLabel.TextSize = 28
else
	PointsLabel.TextSize = 36
end

PointsLabel.TextScaled = false
PointsLabel.TextWrapped = true
PointsLabel.Parent = bloodContainer

-- Create glow effect
local glow = Instance.new("ImageLabel")
glow.Name = "TextGlow"
glow.Size = UDim2.new(1.5, 0, 1.5, 0)
glow.Position = UDim2.new(-0.25, 0, -0.25, 0)
glow.BackgroundTransparency = 1
glow.Image = "rbxassetid://9925180039" -- Circular glow texture
glow.ImageColor3 = Color3.fromRGB(255, 0, 0)
glow.ImageTransparency = 0.9
glow.ScaleType = Enum.ScaleType.Slice
glow.SliceScale = 0.1
glow.ZIndex = -1
glow.Parent = PointsLabel

-- Create particles for blood mist effect
local particleEmitter = Instance.new("ParticleEmitter")
particleEmitter.Name = "BloodMist"

-- Adjust particle size based on device
if isMobile() then
	particleEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 2)
	})
	particleEmitter.Rate = 4
else
	particleEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 3)
	})
	particleEmitter.Rate = 5
end

particleEmitter.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.8),
	NumberSequenceKeypoint.new(1, 1)
})
particleEmitter.Color = ColorSequence.new(Color3.fromRGB(120, 0, 0))
particleEmitter.Acceleration = Vector3.new(0, 2, 0)
particleEmitter.Lifetime = NumberRange.new(1, 2)
particleEmitter.Rotation = NumberRange.new(0, 360)
particleEmitter.Speed = NumberRange.new(2, 5)
particleEmitter.Parent = PointsLabel
particleEmitter.Enabled = false

-- Function to create text shake animation
local function shakeText(intensity, duration)
	local originalPosition = PointsLabel.Position
	local startTime = os.clock()

	local connection
	connection = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		if elapsed > duration then
			PointsLabel.Position = originalPosition
			connection:Disconnect()
			return
		end

		local offsetX = (math.random() * 2 - 1) * intensity * (1 - elapsed/duration)
		local offsetY = (math.random() * 2 - 1) * intensity * (1 - elapsed/duration)
		PointsLabel.Position = UDim2.new(
			originalPosition.X.Scale, 
			originalPosition.X.Offset + offsetX,
			originalPosition.Y.Scale, 
			originalPosition.Y.Offset + offsetY
		)
	end)
end

-- Function to animate points change
local function animatePointsChange(oldPoints, newPoints)
	-- Enable particles
	particleEmitter.Enabled = true

	-- Text color pulse animation
	local pulseText = TweenService:Create(PointsLabel, TweenInfo.new(0.2), {
		TextColor3 = Color3.fromRGB(255, 100, 100),
		TextStrokeColor3 = Color3.fromRGB(60, 0, 0)
	})

	local glowPulse = TweenService:Create(glow, TweenInfo.new(0.2), {
		ImageColor3 = Color3.fromRGB(255, 50, 50),
		ImageTransparency = 0.7
	})

	local returnText = TweenService:Create(PointsLabel, TweenInfo.new(0.4), {
		TextColor3 = Color3.fromRGB(255, 40, 40),
		TextStrokeColor3 = Color3.fromRGB(20, 0, 0)
	})

	local glowReturn = TweenService:Create(glow, TweenInfo.new(0.4), {
		ImageColor3 = Color3.fromRGB(255, 0, 0),
		ImageTransparency = 0.9
	})

	-- Play animations
	pulseText:Play()
	glowPulse:Play()

	-- Shake effect
	shakeText(5, 0.6)

	-- Points counting animation
	if newPoints > oldPoints then
		local increment = oldPoints
		local target = newPoints
		local step = math.max(1, math.floor((target - increment) / 10))

		while increment < target do
			increment = math.min(target, increment + step)
			PointsLabel.Text = "BP: " .. tostring(increment)
			task.wait(0.03)
		end
	end
	PointsLabel.Text = "BP: " .. tostring(newPoints)

	pulseText.Completed:Connect(function()
		returnText:Play()
		glowReturn:Play()

		returnText.Completed:Connect(function()
			particleEmitter.Enabled = false
		end)
	end)
end

-- Hide initially
bloodContainer.Visible = false

PointsUpdate.OnClientEvent:Connect(function(points)
	if not bloodContainer.Visible then
		bloodContainer.Visible = true
	end

	local oldPoints = tonumber(PointsLabel.Text:match("%d+")) or 0
	animatePointsChange(oldPoints, points)
end)

-- Responsive adjustment when screen size changes
screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if isMobile() then
		bloodContainer.Size = UDim2.new(0, 200, 0, 80)
		PointsLabel.TextSize = 22
	else
		bloodContainer.Size = UDim2.new(0, 280, 0, 120)
		PointsLabel.TextSize = 36
	end
end)
