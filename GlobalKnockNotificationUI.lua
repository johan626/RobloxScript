-- GlobalKnockNotificationUI.lua (LocalScript)
-- Path: StarterGui/GlobalKnockNotificationUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local GlobalKnockNotificationEvent = RemoteEvents:WaitForChild("GlobalKnockNotificationEvent")

-- Preload assets
ContentProvider:PreloadAsync({
	"rbxassetid://10151247863",  -- Skull icon
	"rbxassetid://10151249576",  -- Heart icon
	"rbxassetid://8992236421",   -- Pulse effect
})

-- Create ScreenGui for notifications
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GlobalKnockNotificationUI"
screenGui.Parent = gui
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false

-- Notification queue
local notificationQueue = {}
local isShowingNotification = false
local currentNotification = nil

-- Cache for profile pictures
local profilePictureCache = {}

-- Function to get player profile picture
local function getPlayerProfilePicture(playerName, callback)
	if profilePictureCache[playerName] then
		callback(profilePictureCache[playerName])
		return
	end

	coroutine.wrap(function()
		local success, result = pcall(function()
			local targetPlayer = Players:FindFirstChild(playerName)
			if targetPlayer then
				return Players:GetUserThumbnailAsync(targetPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			end
			return nil
		end)

		if success and result then
			profilePictureCache[playerName] = result
			callback(result)
		else
			-- Fallback to default icons if profile picture can't be loaded
			callback(nil)
		end
	end)()
end

-- Template for knock notification
local function createKnockNotification(playerName, position, isKnocked, callback)
	-- Main container with elegant design
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 400, 0, 100)
	container.Position = UDim2.new(0.5, -200, 0.15, 0)
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	container.BackgroundTransparency = 0.2
	container.BorderSizePixel = 0
	container.ZIndex = 10
	container.ClipsDescendants = true

	-- Gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 30))
	}
	gradient.Rotation = 90
	gradient.Parent = container

	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = container

	-- Glowing border
	local stroke = Instance.new("UIStroke")
	stroke.Color = isKnocked and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 120)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = container

	-- Inner shadow
	local innerShadow = Instance.new("Frame")
	innerShadow.Size = UDim2.new(1, 0, 1, 0)
	innerShadow.Position = UDim2.new(0, 0, 0, 0)
	innerShadow.BackgroundTransparency = 1
	innerShadow.BorderSizePixel = 0
	innerShadow.ZIndex = container.ZIndex + 1

	local innerShadowCorner = Instance.new("UICorner")
	innerShadowCorner.CornerRadius = UDim.new(0, 16)
	innerShadowCorner.Parent = innerShadow

	local innerStroke = Instance.new("UIStroke")
	innerStroke.Color = Color3.fromRGB(0, 0, 0)
	innerStroke.Thickness = 2
	innerStroke.Transparency = 0.7
	innerStroke.Parent = innerShadow
	innerShadow.Parent = container

	-- Icon background (circular)
	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.new(0, 60, 0, 60)
	iconBg.Position = UDim2.new(0.05, 0, 0.2, 0)
	iconBg.BackgroundColor3 = isKnocked and Color3.fromRGB(80, 20, 20) or Color3.fromRGB(20, 80, 30)
	iconBg.BackgroundTransparency = 0.3
	iconBg.BorderSizePixel = 0
	iconBg.ZIndex = container.ZIndex + 1

	local iconBgCorner = Instance.new("UICorner")
	iconBgCorner.CornerRadius = UDim.new(1, 0)
	iconBgCorner.Parent = iconBg

	local iconBgStroke = Instance.new("UIStroke")
	iconBgStroke.Color = isKnocked and Color3.fromRGB(200, 60, 60) or Color3.fromRGB(60, 200, 90)
	iconBgStroke.Thickness = 2
	iconBgStroke.Parent = iconBg
	iconBg.Parent = container

	-- Player profile picture
	local profileImage = Instance.new("ImageLabel")
	profileImage.Size = UDim2.new(0, 54, 0, 54)
	profileImage.Position = UDim2.new(0.5, -27, 0.5, -27)
	profileImage.AnchorPoint = Vector2.new(0.5, 0.5)
	profileImage.BackgroundTransparency = 1
	profileImage.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- Placeholder
	profileImage.ScaleType = Enum.ScaleType.Crop
	profileImage.ZIndex = container.ZIndex + 2
	profileImage.Parent = iconBg

	-- Apply circular mask to profile picture
	local profileMask = Instance.new("UICorner")
	profileMask.CornerRadius = UDim.new(1, 0)
	profileMask.Parent = profileImage

	-- Status indicator (small circle in corner)
	local statusIndicator = Instance.new("Frame")
	statusIndicator.Size = UDim2.new(0, 14, 0, 14)
	statusIndicator.Position = UDim2.new(1, -14, 1, -14)
	statusIndicator.AnchorPoint = Vector2.new(1, 1)
	statusIndicator.BackgroundColor3 = isKnocked and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 255, 100)
	statusIndicator.BorderSizePixel = 0
	statusIndicator.ZIndex = container.ZIndex + 3

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(1, 0)
	statusCorner.Parent = statusIndicator

	local statusStroke = Instance.new("UIStroke")
	statusStroke.Color = Color3.fromRGB(255, 255, 255)
	statusStroke.Thickness = 2
	statusStroke.Parent = statusIndicator
	statusIndicator.Parent = profileImage

	-- Load player profile picture
	getPlayerProfilePicture(playerName, function(imageUrl)
		if imageUrl and profileImage then
			profileImage.Image = imageUrl
		else
			-- Fallback to default icons if profile picture fails to load
			profileImage.Image = isKnocked and "rbxassetid://10151247863" or "rbxassetid://10151249576"
			profileImage.ImageColor3 = isKnocked and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 140)
			profileImage.ScaleType = Enum.ScaleType.Fit
		end
	end)

	-- Pulse effect for icon
	local pulse = Instance.new("ImageLabel")
	pulse.Size = UDim2.new(1.5, 0, 1.5, 0)
	pulse.Position = UDim2.new(-0.25, 0, -0.25, 0)
	pulse.BackgroundTransparency = 1
	pulse.Image = "rbxassetid://8992236421"
	pulse.ImageColor3 = isKnocked and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 120)
	pulse.ImageTransparency = 0.8
	pulse.ScaleType = Enum.ScaleType.Fit
	pulse.ZIndex = container.ZIndex
	pulse.Parent = iconBg

	-- Text container
	local textContainer = Instance.new("Frame")
	textContainer.Size = UDim2.new(0.65, 0, 0.8, 0)
	textContainer.Position = UDim2.new(0.25, 0, 0.1, 0)
	textContainer.BackgroundTransparency = 1
	textContainer.ZIndex = container.ZIndex + 1
	textContainer.Parent = container

	-- Player name and status
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 0.6, 0)
	textLabel.Position = UDim2.new(0, 0, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = isKnocked and playerName .. " is down!" or playerName .. " has been revived!"
	textLabel.TextColor3 = isKnocked and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 140)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0.7
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.ZIndex = container.ZIndex + 1
	textLabel.Parent = textContainer

	-- Distance indicator
	local distanceLabel = Instance.new("TextLabel")
	distanceLabel.Size = UDim2.new(1, 0, 0.4, 0)
	distanceLabel.Position = UDim2.new(0, 0, 0.6, 0)
	distanceLabel.BackgroundTransparency = 1
	distanceLabel.Text = ""
	distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	distanceLabel.TextScaled = true
	distanceLabel.Font = Enum.Font.Gotham
	distanceLabel.TextStrokeTransparency = 0.8
	distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
	distanceLabel.ZIndex = container.ZIndex + 1
	distanceLabel.Parent = textContainer

	-- Progress bar for notification duration
	local progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(0.9, 0, 0, 4)
	progressBar.Position = UDim2.new(0.05, 0, 0.9, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	progressBar.BorderSizePixel = 0
	progressBar.ZIndex = container.ZIndex + 1

	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(1, 0)
	progressBarCorner.Parent = progressBar

	local progressFill = Instance.new("Frame")
	progressFill.Size = UDim2.new(1, 0, 1, 0)
	progressFill.Position = UDim2.new(0, 0, 0, 0)
	progressFill.BackgroundColor3 = isKnocked and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 120)
	progressFill.BorderSizePixel = 0
	progressFill.ZIndex = container.ZIndex + 2

	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(1, 0)
	progressFillCorner.Parent = progressFill
	progressFill.Parent = progressBar
	progressBar.Parent = container

	-- Calculate and update distance
	local function updateDistance()
		if not container or not container.Parent then return end

		local localChar = player.Character
		if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
			distanceLabel.Text = ""
			return
		end

		local localPos = localChar.HumanoidRootPart.Position
		local distance = (localPos - position).Magnitude

		if distance > 500 then
			distanceLabel.Text = "Too far away"
		else
			distanceLabel.Text = string.format("%d meters away", math.floor(distance))
		end
	end

	-- Update distance each frame
	local connection
	if isKnocked then
		connection = RunService.RenderStepped:Connect(updateDistance)
		updateDistance() -- Initial call
	else
		distanceLabel.Text = "Nearby"
	end

	container.Parent = screenGui
	currentNotification = container

	-- Initial transparent state
	container.BackgroundTransparency = 1
	textLabel.TextTransparency = 1
	distanceLabel.TextTransparency = 1
	profileImage.ImageTransparency = 1
	iconBg.BackgroundTransparency = 1
	iconBgStroke.Transparency = 1
	stroke.Transparency = 1
	progressBar.BackgroundTransparency = 1
	progressFill.BackgroundTransparency = 1
	pulse.ImageTransparency = 1
	statusIndicator.BackgroundTransparency = 1
	statusStroke.Transparency = 1

	-- Entrance animation
	local entranceTween = TweenService:Create(
		container,
		TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0.2, Position = UDim2.new(0.5, -200, 0.2, 0)}
	)

	local textTweenIn = TweenService:Create(
		textLabel,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	)

	local distanceTweenIn = TweenService:Create(
		distanceLabel,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	)

	local profileImageTweenIn = TweenService:Create(
		profileImage,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ImageTransparency = 0}
	)

	local iconBgTweenIn = TweenService:Create(
		iconBg,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0.3}
	)

	local strokeTweenIn = TweenService:Create(
		iconBgStroke,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Transparency = 0}
	)

	local containerStrokeTweenIn = TweenService:Create(
		stroke,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Transparency = 0.3}
	)

	local progressBarTweenIn = TweenService:Create(
		progressBar,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0}
	)

	local progressFillTweenIn = TweenService:Create(
		progressFill,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0}
	)

	local pulseTweenIn = TweenService:Create(
		pulse,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ImageTransparency = 0.8}
	)

	local statusTweenIn = TweenService:Create(
		statusIndicator,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0}
	)

	local statusStrokeTweenIn = TweenService:Create(
		statusStroke,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Transparency = 0}
	)

	-- Play entrance animations
	entranceTween:Play()
	task.wait(0.1)
	iconBgTweenIn:Play()
	profileImageTweenIn:Play()
	strokeTweenIn:Play()
	containerStrokeTweenIn:Play()
	textTweenIn:Play()
	distanceTweenIn:Play()
	progressBarTweenIn:Play()
	progressFillTweenIn:Play()
	pulseTweenIn:Play()
	statusTweenIn:Play()
	statusStrokeTweenIn:Play()

	-- Animate pulse effect
	local pulseSizeTween = TweenService:Create(
		pulse,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, true),
		{Size = UDim2.new(2, 0, 2, 0), ImageTransparency = 0.9}
	)
	pulseSizeTween:Play()

	-- Progress bar animation
	local progressTween = TweenService:Create(
		progressFill,
		TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 0, 1, 0)}
	)
	progressTween:Play()

	-- Exit animation after 5 seconds
	task.delay(5, function()
		if connection then
			connection:Disconnect()
		end

		pulseSizeTween:Cancel()

		local exitTween = TweenService:Create(
			container,
			TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{BackgroundTransparency = 1, Position = UDim2.new(0.5, -200, 0.15, 0)}
		)

		local textTweenOut = TweenService:Create(
			textLabel,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{TextTransparency = 1}
		)

		local distanceTweenOut = TweenService:Create(
			distanceLabel,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{TextTransparency = 1}
		)

		local profileImageTweenOut = TweenService:Create(
			profileImage,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ImageTransparency = 1}
		)

		local iconBgTweenOut = TweenService:Create(
			iconBg,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1}
		)

		local strokeTweenOut = TweenService:Create(
			iconBgStroke,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Transparency = 1}
		)

		local containerStrokeTweenOut = TweenService:Create(
			stroke,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Transparency = 1}
		)

		local progressBarTweenOut = TweenService:Create(
			progressBar,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1}
		)

		local progressFillTweenOut = TweenService:Create(
			progressFill,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1}
		)

		local pulseTweenOut = TweenService:Create(
			pulse,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ImageTransparency = 1}
		)

		local statusTweenOut = TweenService:Create(
			statusIndicator,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1}
		)

		local statusStrokeTweenOut = TweenService:Create(
			statusStroke,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Transparency = 1}
		)

		exitTween:Play()
		textTweenOut:Play()
		distanceTweenOut:Play()
		profileImageTweenOut:Play()
		iconBgTweenOut:Play()
		strokeTweenOut:Play()
		containerStrokeTweenOut:Play()
		progressBarTweenOut:Play()
		progressFillTweenOut:Play()
		pulseTweenOut:Play()
		statusTweenOut:Play()
		statusStrokeTweenOut:Play()

		exitTween.Completed:Connect(function()
			if container and container.Parent then
				container:Destroy()
				currentNotification = nil
				if callback then
					callback()
				end
			end
		end)
	end)
end

-- Function to process notification queue
local function processQueue()
	if isShowingNotification or #notificationQueue == 0 then
		return
	end

	isShowingNotification = true
	local nextNotification = table.remove(notificationQueue, 1)

	createKnockNotification(nextNotification.playerName, nextNotification.position, nextNotification.isKnocked, function()
		isShowingNotification = false
		processQueue()
	end)
end

-- Event handler for knock notifications
GlobalKnockNotificationEvent.OnClientEvent:Connect(function(playerName, isKnocked, position)
	-- Don't show notifications for self
	if playerName == player.Name then return end

	-- Add notification to queue
	table.insert(notificationQueue, {
		playerName = playerName,
		position = position,
		isKnocked = isKnocked
	})

	-- Process queue if not currently showing a notification
	if not isShowingNotification then
		processQueue()
	end
end)

-- Tutup semua knock notification saat Game Over
local GameOverEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GameOverEvent")
GameOverEvent.OnClientEvent:Connect(function()
	-- Bersihkan antrean & status
	if type(notificationQueue) == "table" then
		table.clear(notificationQueue)
	end
	isShowingNotification = false

	-- Hancurkan notifikasi yang sedang tampil (jika ada)
	if currentNotification and currentNotification.Parent then
		currentNotification:Destroy()
	end
	currentNotification = nil

	-- Sembunyikan/disable GUI container notifikasi
	local containerGui = gui:FindFirstChild("GlobalKnockNotifications")
	if containerGui then
		for _, child in ipairs(containerGui:GetChildren()) do
			child:Destroy()
		end
		-- ScreenGui punya properti Enabled; kita matikan sekalian
		if containerGui:IsA("ScreenGui") then
			containerGui.Enabled = false
		end
	end
end)
