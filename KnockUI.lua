-- KnockUI.lua (LocalScript)
-- Path: StarterGui/KnockUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local KnockEvent = RemoteEvents:WaitForChild("KnockEvent")

-- Create main screen GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KnockUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = true
screenGui.Parent = gui

-- Create blood splatter effect (multiple layers for depth)
local bloodSplatters = {}
local splatterCount = 5

for i = 1, splatterCount do
	local bloodSplatter = Instance.new("ImageLabel")
	bloodSplatter.Name = "BloodSplatter" .. i
	bloodSplatter.Size = UDim2.new(1, 0, 1, 0)
	bloodSplatter.Position = UDim2.new(0, 0, 0, 0)
	bloodSplatter.BackgroundTransparency = 1
	bloodSplatter.Image = "rbxassetid://9421998421" -- Blood splatter texture
	bloodSplatter.ImageColor3 = Color3.fromRGB(120, 0, 0)
	bloodSplatter.ImageTransparency = 0.8
	bloodSplatter.ZIndex = 1
	bloodSplatter.Visible = false
	bloodSplatter.Parent = screenGui

	bloodSplatters[i] = bloodSplatter
end

-- Create vignette effect
local vignette = Instance.new("Frame")
vignette.Name = "Vignette"
vignette.Size = UDim2.new(1, 0, 1, 0)
vignette.Position = UDim2.new(0, 0, 0, 0)
vignette.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
vignette.BackgroundTransparency = 0.7
vignette.ZIndex = 2
vignette.Visible = false

-- Add radial gradient using UIGradient
local vignetteGradient = Instance.new("UIGradient")
vignetteGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(0.5, 0.7),
	NumberSequenceKeypoint.new(1, 1)
})
vignetteGradient.Rotation = 90
vignetteGradient.Parent = vignette

vignette.Parent = screenGui

-- Create pulsing heartbeat effect
local heartbeat = Instance.new("Frame")
heartbeat.Name = "Heartbeat"
heartbeat.Size = UDim2.new(1, 0, 1, 0)
heartbeat.Position = UDim2.new(0, 0, 0, 0)
heartbeat.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
heartbeat.BackgroundTransparency = 0.9
heartbeat.ZIndex = 3
heartbeat.Visible = false
heartbeat.Parent = screenGui

-- Main down overlay
local downOverlay = Instance.new("Frame")
downOverlay.Name = "DownOverlay"
downOverlay.Size = UDim2.new(1, 0, 1, 0)
downOverlay.Position = UDim2.new(0, 0, 0, 0)
downOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
downOverlay.BackgroundTransparency = 0.6
downOverlay.ZIndex = 4
downOverlay.Visible = false
downOverlay.Parent = screenGui

-- Add a subtle gradient to the overlay
local overlayGradient = Instance.new("UIGradient")
overlayGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 0, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 0, 0))
})
overlayGradient.Transparency = NumberSequence.new(0.6)
overlayGradient.Rotation = 45
overlayGradient.Parent = downOverlay

-- Create the icon (skull) with glow effect
local downIconContainer = Instance.new("Frame")
downIconContainer.Name = "DownIconContainer"
downIconContainer.Size = UDim2.new(0, 150, 0, 150)
downIconContainer.Position = UDim2.new(0.5, -75, 0.25, -75)
downIconContainer.BackgroundTransparency = 1
downIconContainer.ZIndex = 5
downIconContainer.Parent = downOverlay

-- Glow effect behind the skull
local iconGlow = Instance.new("ImageLabel")
iconGlow.Name = "IconGlow"
iconGlow.Size = UDim2.new(1.5, 0, 1.5, 0)
iconGlow.Position = UDim2.new(-0.25, 0, -0.25, 0)
iconGlow.BackgroundTransparency = 1
iconGlow.Image = "rbxassetid://9920747664" -- Glow effect
iconGlow.ImageColor3 = Color3.fromRGB(255, 50, 50)
iconGlow.ImageTransparency = 0.7
iconGlow.ZIndex = 4
iconGlow.Parent = downIconContainer

-- The skull icon
local downIcon = Instance.new("ImageLabel")
downIcon.Name = "DownIcon"
downIcon.Size = UDim2.new(1, 0, 1, 0)
downIcon.Position = UDim2.new(0, 0, 0, 0)
downIcon.BackgroundTransparency = 1
downIcon.Image = "rbxassetid://9176098815" -- skull icon asset
downIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
downIcon.ZIndex = 5
downIcon.Parent = downIconContainer

-- Crack effect on the skull
local crackEffect = Instance.new("ImageLabel")
crackEffect.Name = "CrackEffect"
crackEffect.Size = UDim2.new(1, 0, 1, 0)
crackEffect.Position = UDim2.new(0, 0, 0, 0)
crackEffect.BackgroundTransparency = 1
crackEffect.Image = "rbxassetid://9422002490" -- Crack texture
crackEffect.ImageTransparency = 0.7
crackEffect.ZIndex = 6
crackEffect.Parent = downIcon

-- Create the main text label with more styling
local downLabel = Instance.new("TextLabel")
downLabel.Name = "DownLabel"
downLabel.Size = UDim2.new(0.8, 0, 0.15, 0)
downLabel.Position = UDim2.new(0.1, 0, 0.45, 0)
downLabel.BackgroundTransparency = 1
downLabel.Text = "YOU ARE DOWN"
downLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
downLabel.TextScaled = true
downLabel.Font = Enum.Font.GothamBlack
downLabel.TextStrokeTransparency = 0
downLabel.TextStrokeColor3 = Color3.fromRGB(50, 0, 0)
downLabel.TextStrokeTransparency = 0.5
downLabel.ZIndex = 5
downLabel.Parent = downOverlay

-- Add multiple text effects
local labelStroke = Instance.new("UIStroke")
labelStroke.Color = Color3.fromRGB(255, 0, 0)
labelStroke.Thickness = 2
labelStroke.Transparency = 0.5
labelStroke.Parent = downLabel

local labelShadow = Instance.new("ImageLabel")
labelShadow.Name = "LabelShadow"
labelShadow.Size = UDim2.new(1.1, 0, 1.1, 0)
labelShadow.Position = UDim2.new(-0.05, 0, -0.05, 0)
labelShadow.BackgroundTransparency = 1
labelShadow.Image = "rbxassetid://9920747664" -- Soft glow
labelShadow.ImageColor3 = Color3.fromRGB(150, 0, 0)
labelShadow.ImageTransparency = 0.8
labelShadow.ZIndex = 4
labelShadow.Parent = downLabel

-- Subtitle with more styling
local subText = Instance.new("TextLabel")
subText.Name = "SubText"
subText.Size = UDim2.new(0.7, 0, 0.08, 0)
subText.Position = UDim2.new(0.15, 0, 0.62, 0)
subText.BackgroundTransparency = 1
subText.Text = "Waiting for the others to revive..."
subText.TextColor3 = Color3.fromRGB(255, 200, 200)
subText.TextScaled = true
subText.Font = Enum.Font.GothamMedium
subText.TextStrokeTransparency = 0.7
subText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
subText.ZIndex = 5
subText.Parent = downOverlay

-- Ping button for knocked players
local pingButton = Instance.new("TextButton")
pingButton.Name = "PingButton"
pingButton.Size = UDim2.new(0.3, 0, 0.1, 0)
pingButton.Position = UDim2.new(0.35, 0, 0.8, 0)
pingButton.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
pingButton.BorderSizePixel = 0
pingButton.ZIndex = 5
pingButton.Font = Enum.Font.GothamBold
pingButton.Text = "PING FOR HELP (H)"
pingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
pingButton.TextScaled = true
pingButton.Parent = downOverlay

local pingButtonCorner = Instance.new("UICorner")
pingButtonCorner.CornerRadius = UDim.new(0, 8)
pingButtonCorner.Parent = pingButton

local pingButtonStroke = Instance.new("UIStroke")
pingButtonStroke.Color = Color3.fromRGB(255, 255, 255)
pingButtonStroke.Thickness = 1.5
pingButtonStroke.Transparency = 0.5
pingButtonStroke.Parent = pingButton

local cooldownText = Instance.new("TextLabel")
cooldownText.Name = "CooldownText"
cooldownText.Size = UDim2.new(1, 0, 1, 0)
cooldownText.BackgroundTransparency = 1
cooldownText.ZIndex = 6
cooldownText.Font = Enum.Font.GothamBold
cooldownText.Text = ""
cooldownText.TextColor3 = Color3.fromRGB(255, 255, 255)
cooldownText.TextScaled = true
cooldownText.Visible = false
cooldownText.Parent = pingButton

-- Progress bar for revive anticipation
local reviveProgress = Instance.new("Frame")
reviveProgress.Name = "ReviveProgress"
reviveProgress.Size = UDim2.new(0.4, 0, 0.03, 0)
reviveProgress.Position = UDim2.new(0.3, 0, 0.72, 0)
reviveProgress.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
reviveProgress.BorderSizePixel = 0
reviveProgress.ZIndex = 5
reviveProgress.Visible = false
reviveProgress.Parent = downOverlay

local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.Position = UDim2.new(0, 0, 0, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
progressBar.BorderSizePixel = 0
progressBar.ZIndex = 6
progressBar.Parent = reviveProgress

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 10)
progressCorner.Parent = reviveProgress

local progressBarCorner = Instance.new("UICorner")
progressBarCorner.CornerRadius = UDim.new(0, 10)
progressBarCorner.Parent = progressBar

-- Animation variables
local pulseTween
local glowTween
local crackTween
local bloodTweens = {}
local vignetteTween
local heartbeatTween
local progressTween

-- Function to create random movement for blood splatters
local function randomizeBloodSplatters()
	for _, splatter in ipairs(bloodSplatters) do
		splatter.Position = UDim2.new(
			math.random(-20, 20) / 100,
			0,
			math.random(-20, 20) / 100,
			0
		)
		splatter.Rotation = math.random(-30, 30)
		splatter.ImageTransparency = math.random(7, 9) / 10
	end
end

-- Function to start all knockdown animations
local function startKnockdownAnimations()
	-- Show all elements
	downOverlay.Visible = true
	vignette.Visible = true
	heartbeat.Visible = true

	for _, splatter in ipairs(bloodSplatters) do
		splatter.Visible = true
	end

	-- Randomize blood splatter positions
	randomizeBloodSplatters()

	-- Pulse animation for the main text
	if pulseTween then pulseTween:Cancel() end
	local pulseInfo = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	pulseTween = TweenService:Create(downLabel, pulseInfo, {
		TextColor3 = Color3.fromRGB(255, 150, 150),
		TextTransparency = 0.2
	})
	pulseTween:Play()

	-- Glow animation for the icon
	if glowTween then glowTween:Cancel() end
	local glowInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	glowTween = TweenService:Create(iconGlow, glowInfo, {
		ImageTransparency = 0.3,
		Rotation = 360
	})
	glowTween:Play()

	-- Crack effect animation
	if crackTween then crackTween:Cancel() end
	local crackInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	crackTween = TweenService:Create(crackEffect, crackInfo, {
		ImageTransparency = 0.4
	})
	crackTween:Play()

	-- Blood splatter animations
	for i, splatter in ipairs(bloodSplatters) do
		if bloodTweens[i] then bloodTweens[i]:Cancel() end

		local bloodInfo = TweenInfo.new(
			math.random(15, 25)/10,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1,
			true
		)

		bloodTweens[i] = TweenService:Create(splatter, bloodInfo, {
			ImageTransparency = math.random(5, 9)/10
		})
		bloodTweens[i]:Play()
	end

	-- Vignette pulse animation
	if vignetteTween then vignetteTween:Cancel() end
	local vignetteInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	vignetteTween = TweenService:Create(vignette, vignetteInfo, {
		BackgroundTransparency = 0.6
	})
	vignetteTween:Play()

	-- Heartbeat effect (screen pulse)
	if heartbeatTween then heartbeatTween:Cancel() end
	local heartbeatInfo = TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out, -1, true)
	heartbeatTween = TweenService:Create(heartbeat, heartbeatInfo, {
		BackgroundTransparency = 0.95
	})
	heartbeatTween:Play()
end

-- Function to stop all animations
local function stopKnockdownAnimations()
	-- Stop all tweens
	if pulseTween then pulseTween:Cancel() end
	if glowTween then glowTween:Cancel() end
	if crackTween then crackTween:Cancel() end
	if vignetteTween then vignetteTween:Cancel() end
	if heartbeatTween then heartbeatTween:Cancel() end
	if progressTween then progressTween:Cancel() end

	for i, tween in ipairs(bloodTweens) do
		if tween then tween:Cancel() end
	end

	-- Hide all elements with a fade out animation
	local fadeOutInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local downFade = TweenService:Create(downOverlay, fadeOutInfo, {
		BackgroundTransparency = 1
	})

	local vignetteFade = TweenService:Create(vignette, fadeOutInfo, {
		BackgroundTransparency = 1
	})

	local heartbeatFade = TweenService:Create(heartbeat, fadeOutInfo, {
		BackgroundTransparency = 1
	})

	downFade:Play()
	vignetteFade:Play()
	heartbeatFade:Play()

	for _, splatter in ipairs(bloodSplatters) do
		local bloodFade = TweenService:Create(splatter, fadeOutInfo, {
			ImageTransparency = 1
		})
		bloodFade:Play()
	end

	-- Hide elements after fade completes
	downFade.Completed:Connect(function()
		downOverlay.Visible = false
		vignette.Visible = false
		heartbeat.Visible = false

		for _, splatter in ipairs(bloodSplatters) do
			splatter.Visible = false
		end
	end)
end

-- Function to show revive progress
local function showReviveProgress(duration)
	reviveProgress.Visible = true
	progressBar.Size = UDim2.new(0, 0, 1, 0)

	if progressTween then progressTween:Cancel() end

	local progressInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	progressTween = TweenService:Create(progressBar, progressInfo, {
		Size = UDim2.new(1, 0, 1, 0)
	})
	progressTween:Play()
end

-- Function to hide revive progress
local function hideReviveProgress()
	reviveProgress.Visible = false
	if progressTween then progressTween:Cancel() end
end

-- START PING SYSTEM
local UserInputService = game:GetService("UserInputService")
local PingKnockedPlayerEvent = game:GetService("ReplicatedStorage").RemoteEvents:WaitForChild("PingKnockedPlayerEvent")

local PING_COOLDOWN = 15
local lastPingTime = 0
local onCooldown = false

local function handlePing()
	local now = time()
	if now - lastPingTime > PING_COOLDOWN then
		lastPingTime = now
		PingKnockedPlayerEvent:FireServer()

		-- Start cooldown visual feedback
		onCooldown = true
		pingButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		pingButton.Text = ""
		cooldownText.Visible = true

		for i = PING_COOLDOWN, 1, -1 do
			cooldownText.Text = tostring(i)
			wait(1)
		end

		-- Cooldown finished
		onCooldown = false
		pingButton.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
		pingButton.Text = "PING FOR HELP (H)"
		cooldownText.Visible = false
	end
end

pingButton.MouseButton1Click:Connect(handlePing)
UserInputService.InputBegan:Connect(function(input, gameProcessingEvent)
	if gameProcessingEvent then return end
	if input.KeyCode == Enum.KeyCode.H and downOverlay.Visible then
		handlePing()
	end
end)
-- END PING SYSTEM

-- Optional: Add screen shake effect when knocked
local camera = workspace.CurrentCamera
local originalCameraPosition = camera.CFrame
local shakeConnection

local function startScreenShake()
	if shakeConnection then shakeConnection:Disconnect() end

	local shakeIntensity = 0.5
	local shakeDuration = 0.5
	local shakeEndTime = time() + shakeDuration

	shakeConnection = RunService.Heartbeat:Connect(function()
		if time() < shakeEndTime then
			local offset = Vector3.new(
				(math.random() - 0.5) * shakeIntensity,
				(math.random() - 0.5) * shakeIntensity,
				(math.random() - 0.5) * shakeIntensity
			)
			camera.CFrame = originalCameraPosition * CFrame.new(offset)
			shakeIntensity = shakeIntensity * 0.9 -- Reduce intensity over time
		else
			camera.CFrame = originalCameraPosition
			shakeConnection:Disconnect()
			shakeConnection = nil
		end
	end)
end

-- Update event connection to include screen shake
KnockEvent.OnClientEvent:Connect(function(isKnocked, reviveTime)
	if isKnocked then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		originalCameraPosition = camera.CFrame
		startScreenShake()
		startKnockdownAnimations()

		if reviveTime and reviveTime > 0 then
			showReviveProgress(reviveTime)
		end
	else
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
		if shakeConnection then
			shakeConnection:Disconnect()
			shakeConnection = nil
		end
		if camera and originalCameraPosition then
			camera.CFrame = originalCameraPosition
		end
		stopKnockdownAnimations()
		hideReviveProgress()
	end
end)
