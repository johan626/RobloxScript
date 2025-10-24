-- AmmoUI.lua (LocalScript)
-- Path: StarterGui/AmmoUI.lua
-- Script Place = ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local AmmoUpdateEvent = RemoteEvents:WaitForChild("AmmoUpdateEvent")

-- Create or find ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AmmoUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = true
screenGui.Parent = playerGui

-- Function to determine if device is mobile
local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- Create ammo display container
local ammoContainer = Instance.new("Frame")
ammoContainer.Name = "AmmoContainer"
ammoContainer.Size = UDim2.new(0, 280, 0, 140)
ammoContainer.AnchorPoint = Vector2.new(1, 1) -- Anchor to bottom right by default
ammoContainer.BackgroundTransparency = 0.9
ammoContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ammoContainer.BorderSizePixel = 0
ammoContainer.Visible = false
ammoContainer.Parent = screenGui

-- Function to load custom settings from the settings folder
local function loadCustomSettings()
	local settingsFolder = playerGui:FindFirstChild("MobileButtonsSettings")
	if not settingsFolder then return false end

	local settingsNode = settingsFolder:FindFirstChild("AmmoContainer")
	if not settingsNode or not settingsNode:IsA("StringValue") then return false end

	local ok, data = pcall(function()
		return game:GetService("HttpService"):JSONDecode(settingsNode.Value)
	end)

	if ok and data and data.position and data.size then
		ammoContainer.Position = UDim2.new(data.position.X, data.position.OffsetX, data.position.Y, data.position.OffsetY)
		ammoContainer.Size = UDim2.new(data.size.X, data.size.OffsetX, data.size.Y, data.size.OffsetY)
		return true
	end

	return false
end

-- Function to update position and size based on device
local function updateAmmoDisplayPosition()
	-- Do not auto-position if in settings mode
	if ammoContainer:GetAttribute("IsInSettingsMode") then return end

	-- Try to load custom settings first
	if loadCustomSettings() then
		return
	end

	-- Fallback to default logic if no custom settings are found
	local screenSize = workspace.CurrentCamera.ViewportSize

	-- Adjust size based on screen dimensions
	local width = math.clamp(screenSize.X * 0.25, 200, 320)
	local height = math.clamp(screenSize.Y * 0.12, 100, 160)
	ammoContainer.Size = UDim2.new(0, width, 0, height)

	-- Adjust position based on device type
	if isMobile() then
		-- Mobile: position at bottom left with safe area padding
		ammoContainer.AnchorPoint = Vector2.new(0, 1)
		ammoContainer.Position = UDim2.new(0, 10, 1, -10)
	else
		-- Desktop: position at bottom right
		ammoContainer.AnchorPoint = Vector2.new(1, 1)
		ammoContainer.Position = UDim2.new(1, -10, 1, -10)
	end
end

-- Update position initially and when screen size changes
task.wait(0.1) -- Wait a moment for attributes to be set
updateAmmoDisplayPosition()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateAmmoDisplayPosition)
UserInputService.LastInputTypeChanged:Connect(updateAmmoDisplayPosition)

-- Add corner rounding
local uICorner = Instance.new("UICorner")
uICorner.CornerRadius = UDim.new(0, 12)
uICorner.Parent = ammoContainer

-- Add subtle shadow effect
local uIStroke = Instance.new("UIStroke")
uIStroke.Color = Color3.fromRGB(60, 60, 60)
uIStroke.Thickness = 2
uIStroke.Parent = ammoContainer

-- Add inner glow effect
local innerGlow = Instance.new("Frame")
innerGlow.Name = "InnerGlow"
innerGlow.Size = UDim2.new(1, 0, 1, 0)
innerGlow.Position = UDim2.new(0, 0, 0, 0)
innerGlow.BackgroundTransparency = 1
innerGlow.BorderSizePixel = 0
innerGlow.ZIndex = 2
innerGlow.Parent = ammoContainer

local uIStroke2 = Instance.new("UIStroke")
uIStroke2.Color = Color3.fromRGB(120, 120, 120)
uIStroke2.Thickness = 1
uIStroke2.Transparency = 0.7
uIStroke2.Parent = innerGlow

-- Weapon name label
local weaponNameLabel = Instance.new("TextLabel")
weaponNameLabel.Name = "WeaponNameLabel"
weaponNameLabel.Size = UDim2.new(0.65, 0, 0.25, 0)
weaponNameLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
weaponNameLabel.BackgroundTransparency = 1
weaponNameLabel.Text = "WEAPON"
weaponNameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
weaponNameLabel.TextScaled = true
weaponNameLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponNameLabel.Font = Enum.Font.GothamBold
weaponNameLabel.TextStrokeTransparency = 0.8
weaponNameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
weaponNameLabel.Parent = ammoContainer

-- Weapon level badge
local levelBadge = Instance.new("Frame")
levelBadge.Name = "LevelBadge"
levelBadge.Size = UDim2.new(0.25, 0, 0.25, 0)
levelBadge.Position = UDim2.new(0.7, 0, 0.05, 0)
levelBadge.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
levelBadge.BackgroundTransparency = 0.5
levelBadge.BorderSizePixel = 0
levelBadge.Parent = ammoContainer

local levelCorner = Instance.new("UICorner")
levelCorner.CornerRadius = UDim.new(0, 8)
levelCorner.Parent = levelBadge

local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "LevelLabel"
levelLabel.Size = UDim2.new(1, 0, 1, 0)
levelLabel.Position = UDim2.new(0, 0, 0, 0)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "LV.0"
levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color for level
levelLabel.TextScaled = true
levelLabel.Font = Enum.Font.GothamBlack
levelLabel.TextStrokeTransparency = 0.8
levelLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
levelLabel.Parent = levelBadge

-- Ammo count label
local ammoLabel = Instance.new("TextLabel")
ammoLabel.Name = "AmmoLabel"
ammoLabel.Size = UDim2.new(1, 0, 0.5, 0)
ammoLabel.Position = UDim2.new(0, 0, 0.35, 0)
ammoLabel.BackgroundTransparency = 1
ammoLabel.Text = "0 / 0"
ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ammoLabel.TextScaled = true
ammoLabel.Font = Enum.Font.GothamBlack
ammoLabel.TextStrokeTransparency = 0.8
ammoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
ammoLabel.Parent = ammoContainer

-- Progress bar for reloading
local reloadBarContainer = Instance.new("Frame")
reloadBarContainer.Name = "ReloadBarContainer"
reloadBarContainer.Size = UDim2.new(0.9, 0, 0.05, 0)
reloadBarContainer.Position = UDim2.new(0.05, 0, 0.85, 0)
reloadBarContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
reloadBarContainer.BackgroundTransparency = 0.7
reloadBarContainer.BorderSizePixel = 0
reloadBarContainer.Visible = false
reloadBarContainer.Parent = ammoContainer

local reloadBarCorner = Instance.new("UICorner")
reloadBarCorner.CornerRadius = UDim.new(1, 0)
reloadBarCorner.Parent = reloadBarContainer

local reloadBar = Instance.new("Frame")
reloadBar.Name = "ReloadBar"
reloadBar.Size = UDim2.new(0, 0, 1, 0)
reloadBar.Position = UDim2.new(0, 0, 0, 0)
reloadBar.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
reloadBar.BorderSizePixel = 0
reloadBar.Parent = reloadBarContainer

local reloadBarInnerCorner = Instance.new("UICorner")
reloadBarInnerCorner.CornerRadius = UDim.new(1, 0)
reloadBarInnerCorner.Parent = reloadBar


AmmoUpdateEvent.OnClientEvent:Connect(function(weaponName, ammo, reserveAmmo, isVisible, isReloading)
	-- Check if this is for the currently equipped weapon
	local currentTool = player.Character and player.Character:FindFirstChildOfClass("Tool")
	if currentTool and currentTool.Name ~= weaponName then
		return
	end

	if isReloading then
		ammoLabel.Text = "RELOADING: " .. tostring(ammo) .. "%"
		reloadBarContainer.Visible = true
		reloadBar.Size = UDim2.new(ammo/100, 0, 1, 0)
	else
		ammoLabel.Text = tostring(ammo) .. " / " .. tostring(reserveAmmo)
		reloadBarContainer.Visible = false
	end

	-- Update weapon name and level
	if currentTool then
		local level = currentTool:GetAttribute("UpgradeLevel") or 0
		weaponNameLabel.Text = string.upper(weaponName)
		levelLabel.Text = "LV." .. tostring(level)
	end

	-- Change color when ammo is low and show indicator
	if ammo <= 1 and not isReloading then
		ammoLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	else
		ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	ammoContainer.Visible = isVisible
end)

-- Function to update weapon level
local function updateWeaponNameLabel(tool)
	if tool and tool:IsA("Tool") then
		local level = tool:GetAttribute("UpgradeLevel") or 0
		local weaponName = tool.Name
		weaponNameLabel.Text = string.upper(weaponName)
		levelLabel.Text = "LV." .. tostring(level)
	end
end

-- Hide ammo display when no tool is equipped
local function onCharacterAdded(character)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			-- Smooth fade in animation
			ammoContainer.Visible = true
			ammoContainer.BackgroundTransparency = 1

			local tween = TweenService:Create(
				ammoContainer,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 0.9}
			)
			tween:Play()

			updateWeaponNameLabel(child)

			-- Listen for upgrade level changes
			child:GetAttributeChangedSignal("UpgradeLevel"):Connect(function()
				updateWeaponNameLabel(child)
			end)
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and not character:FindFirstChildOfClass("Tool") then
			-- Smooth fade out animation
			local tween = TweenService:Create(
				ammoContainer,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 1}
			)
			tween:Play()

			tween.Completed:Connect(function()
				ammoContainer.Visible = false
			end)
		end
	end)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end
