-- ProfileUI.lua (LocalScript)
-- Path: StarterGui/ProfileUI.lua
-- Script Place: Lobby
-- Last Revision: [Current Date] - Complete UI Overhaul

--[[ SERVICES ]]--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

--[[ LOCAL PLAYER ]]--
local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")

--[[ CONSTANTS ]]--
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then
	script:Destroy()
	return
end

--[[ ASSETS ]]--
local profileRemoteFunction = ReplicatedStorage:WaitForChild("GetProfileData")
local getTitleDataFunc = ReplicatedStorage:WaitForChild("GetTitleData")
local setEquippedTitleEvent = ReplicatedStorage:WaitForChild("SetEquippedTitle")
local getWeaponStatsFunc = ReplicatedStorage:WaitForChild("GetWeaponStats")
local LevelUpdateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("LevelUpdateEvent")

--[[ MAIN UI DECLARATION ]]--
-- ScreenGui container for all UI elements
local profileScreenGui = Instance.new("ScreenGui")
profileScreenGui.Name = "ProfileUI"
profileScreenGui.Parent = playerGui
profileScreenGui.Enabled = true
profileScreenGui.ResetOnSpawn = false
profileScreenGui.IgnoreGuiInset = true

--[[ HELPER FUNCTIONS ]]--
local function create(instanceType, properties)
	local obj = Instance.new(instanceType)
	for prop, value in pairs(properties or {}) do
		obj[prop] = value
	end
	return obj
end

-- Helper to format large numbers
local function formatNumber(n)
	if n >= 1000000 then return string.format("%.1fM", n / 1000000) end
	if n >= 1000 then return string.format("%.1fK", n / 1000) end
	return tostring(n)
end

-- Helper function to create a stat group
local function createStatGroup(title, parent)
	local groupFrame = create("Frame", {
		Name = title .. "Group",
		Parent = parent,
		BackgroundColor3 = Color3.fromRGB(50, 52, 64),
	})
	create("UICorner", { Parent = groupFrame })
	local layout = create("UIListLayout", { Parent = groupFrame, Padding = UDim.new(0, 8) })
	create("UIPadding", { Parent = groupFrame, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10) })
	create("TextLabel", {
		Name = "Title",
		Parent = groupFrame,
		Size = UDim2.new(1, 0, 0, 25),
		Text = title,
		Font = Enum.Font.SourceSansBold,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Left
	})
	return groupFrame
end

-- Helper function to create a single stat display
local function createStatDisplay(name, parent)
	local statLabel = create("TextLabel", {
		Name = name .. "Label",
		Parent = parent,
		Size = UDim2.new(1, 0, 0, 22),
		Text = name .. ": 0",
		Font = Enum.Font.SourceSans,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextXAlignment = Enum.TextXAlignment.Left
	})
	return statLabel
end

-- Helper function to create a styled button
local function createNavButton(name, text, color)
	local button = create("TextButton", {
		Name = name .. "Button",
		Parent = nil, -- Will be assigned later
		Text = text,
		Font = Enum.Font.SourceSansBold,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = color
	})
	create("UICorner", { Parent = button })
	return button
end

-- Helper to create secondary panels
local function createSecondaryPanel(name, titleText)
	local panel = create("Frame", {
		Name = name .. "Frame",
		Parent = profileScreenGui,
		Size = UDim2.new(0, 400, 0, 450),
		Position = UDim2.new(0.5, -200, 0.5, -225),
		BackgroundColor3 = Color3.fromRGB(40, 42, 54),
		BorderColor3 = Color3.fromRGB(150, 150, 150),
		BorderSizePixel = 1,
		Visible = false
	})
	create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = panel })
	local titleBar = create("Frame", {
		Name = "TitleBar",
		Parent = panel,
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = Color3.fromRGB(50, 52, 64)
	})
	create("TextLabel", {
		Name = "TitleLabel",
		Parent = titleBar,
		Size = UDim2.new(1, 0, 1, 0),
		Text = titleText,
		Font = Enum.Font.SourceSansBold,
		TextSize = 24,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1
	})
	local backButton = create("TextButton", {
		Name = "BackButton",
		Parent = titleBar,
		Size = UDim2.new(0, 80, 0, 40),
		Position = UDim2.new(0, 5, 0.5, -20),
		Text = " Back",
		Font = Enum.Font.SourceSansBold,
		TextSize = 18,
		BackgroundColor3 = Color3.fromRGB(80, 80, 80),
		TextColor3 = Color3.fromRGB(255, 255, 255)
	})
	create("UICorner", { Parent = backButton, CornerRadius = UDim.new(0, 6) })
	local closeButton = create("TextButton", {
		Name = "CloseButton",
		Parent = titleBar,
		Size = UDim2.new(0, 40, 0, 40),
		Position = UDim2.new(1, -45, 0.5, -20),
		Text = "X",
		Font = Enum.Font.SourceSansBold,
		TextSize = 20,
		BackgroundColor3 = Color3.fromRGB(220, 80, 80),
		TextColor3 = Color3.fromRGB(255, 255, 255)
	})
	create("UICorner", { Parent = closeButton, CornerRadius = UDim.new(0, 6) })
	local scrollingFrame = create("ScrollingFrame", {
		Name = "ContentList",
		Parent = panel,
		Size = UDim2.new(1, -20, 1, -70),
		Position = UDim2.new(0, 10, 0, 60),
		BackgroundColor3 = Color3.fromRGB(30, 31, 41),
		BorderSizePixel = 0,
		ScrollBarThickness = 6
	})
	create("UIListLayout", { Parent = scrollingFrame, Padding = UDim.new(0, 5) })
	return panel, scrollingFrame, backButton, closeButton
end

--[[ PROFILE BUTTON (Always Visible) ]]--
local profileButton = create("TextButton", {
	Name = "ProfileButton",
	Parent = profileScreenGui,
	Size = UDim2.new(0.15, 0, 0.1, 0),
	Position = UDim2.new(0.839, 0, 0.019, 0),
	Text = "Profile",
	Font = Enum.Font.SourceSansBold,
	TextSize = 18,
	BackgroundColor3 = Color3.fromRGB(65, 65, 65),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	TextScaled = true
})
create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = profileButton })

--================================================================================--
--[[ MAIN PROFILE PANEL (Overhauled) ]]--
--================================================================================--
local mainFrame = create("Frame", {
	Name = "MainFrame",
	Parent = profileScreenGui,
	Size = UDim2.new(0, 500, 0, 650),
	Position = UDim2.new(0.5, -250, 0.5, -325),
	BackgroundColor3 = Color3.fromRGB(40, 42, 54),
	BorderColor3 = Color3.fromRGB(150, 150, 150),
	BorderSizePixel = 1,
	Visible = false -- Initially hidden
})
create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = mainFrame })
local mainFrameLayout = create("UIListLayout", {
	Parent = mainFrame,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 15)
})
create("UIPadding", {
	Parent = mainFrame,
	PaddingTop = UDim.new(0, 15),
	PaddingBottom = UDim.new(0, 15),
	PaddingLeft = UDim.new(0, 15),
	PaddingRight = UDim.new(0, 15)
})

--[[ 1. HEADER SECTION ]]--
local headerFrame = create("Frame", {
	Name = "HeaderFrame",
	Parent = mainFrame,
	Size = UDim2.new(1, 0, 0, 80),
	BackgroundTransparency = 1
})
local headerLayout = create("UIListLayout", {
	Parent = headerFrame,
	FillDirection = Enum.FillDirection.Vertical,
	SortOrder = Enum.SortOrder.Name,
	HorizontalAlignment = Enum.HorizontalAlignment.Center
})
local nameLabel = create("TextLabel", {
	Name = "NameLabel",
	Parent = headerFrame,
	Size = UDim2.new(1, 0, 0, 40),
	Text = "PLAYER NAME",
	Font = Enum.Font.SourceSansBold,
	TextSize = 32,
	TextColor3 = Color3.fromRGB(255, 255, 255)
})
local playerTitleLabel = create("TextLabel", {
	Name = "PlayerTitleLabel",
	Parent = headerFrame,
	Size = UDim2.new(1, 0, 0, 25),
	Text = "No Title Equipped",
	Font = Enum.Font.SourceSansItalic,
	TextSize = 18,
	TextColor3 = Color3.fromRGB(180, 180, 180)
})

--[[ 2. CORE PROGRESS SECTION ]]--
local progressFrame = create("Frame", {
	Name = "ProgressFrame",
	Parent = mainFrame,
	Size = UDim2.new(1, 0, 0, 80),
	BackgroundTransparency = 1
})
local levelLabel = create("TextLabel", {
	Name = "LevelLabel",
	Parent = progressFrame,
	Size = UDim2.new(0, 80, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	Text = "LVL\n100",
	Font = Enum.Font.SourceSansBold,
	TextSize = 30,
	TextColor3 = Color3.fromRGB(255, 215, 0),
	TextWrapped = true,
	LineHeight = 0.9
})
local xpContainer = create("Frame", {
	Name = "XPContainer",
	Parent = progressFrame,
	Size = UDim2.new(1, -90, 0, 50),
	Position = UDim2.new(0, 90, 0.5, -25),
	BackgroundTransparency = 1
})
local xpLabel = create("TextLabel", {
	Name = "XPLabel",
	Parent = xpContainer,
	Size = UDim2.new(1, 0, 0, 20),
	Text = "Experience",
	Font = Enum.Font.SourceSans,
	TextColor3 = Color3.fromRGB(220, 220, 220),
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left
})
local xpBarBg = create("Frame", {
	Name = "XPBarBackground",
	Parent = xpContainer,
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0, 0, 0, 25),
	BackgroundColor3 = Color3.fromRGB(24, 25, 32)
})
create("UICorner", { Parent = xpBarBg })
local xpBarFill = create("Frame", {
	Name = "XPBarFill",
	Parent = xpBarBg,
	Size = UDim2.new(0.5, 0, 1, 0),
	BackgroundColor3 = Color3.fromRGB(78, 180, 255)
})
create("UICorner", { Parent = xpBarFill })
local xpValueLabel = create("TextLabel", {
	Name = "XPValueLabel",
	Parent = xpBarBg,
	Size = UDim2.new(1, 0, 1, 0),
	Text = "12,345 / 25,000 XP",
	Font = Enum.Font.SourceSansBold,
	TextSize = 14,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 1
})

--[[ 3. STATS SECTION ]]--
local statsContainerFrame = create("Frame", {
	Name = "StatsContainerFrame",
	Parent = mainFrame,
	Size = UDim2.new(1, 0, 0, 220),
	BackgroundTransparency = 1
})
local statsLayout = create("UIGridLayout", {
	Parent = statsContainerFrame,
	CellSize = UDim2.new(0.5, -5, 1, 0),
	SortOrder = Enum.SortOrder.LayoutOrder
})

-- Create Stat Groups and individual stat labels
local combatGroup = createStatGroup("Combat", statsContainerFrame)
local totalKillsLabel = createStatDisplay("Total Kills", combatGroup)
local totalDamageLabel = createStatDisplay("Total Damage", combatGroup)
local totalKnocksLabel = createStatDisplay("Total Knocks", combatGroup)
local totalRevivesLabel = createStatDisplay("Total Revives", combatGroup)

local progressionGroup = createStatGroup("Progression", statsContainerFrame)
local lifetimeCoinsLabel = createStatDisplay("Lifetime Coins", progressionGroup)
local lifetimeAPLabel = createStatDisplay("Lifetime AP", progressionGroup)
local lifetimeMPLabel = createStatDisplay("Lifetime MP", progressionGroup)

--[[ 4. NAVIGATION / BUTTONS SECTION ]]--
local navFrame = create("Frame", {
	Name = "NavFrame",
	Parent = mainFrame,
	Size = UDim2.new(1, 0, 0, 120),
	BackgroundTransparency = 1
})
local navLayout = create("UIGridLayout", {
	Parent = navFrame,
	CellSize = UDim2.new(0.5, -5, 0.5, -5),
	SortOrder = Enum.SortOrder.LayoutOrder,
	FillDirection = Enum.FillDirection.Vertical
})

local skillsButton = createNavButton("Skills", "Skills", Color3.fromRGB(88, 110, 200))
skillsButton.Parent = navFrame
local achievementsButton = createNavButton("Achievements", "Achievements", Color3.fromRGB(60, 62, 74))
achievementsButton.Parent = navFrame
local titlesButton = createNavButton("Titles", "Titles", Color3.fromRGB(60, 62, 74))
titlesButton.Parent = navFrame
local weaponStatsButton = createNavButton("WeaponStats", "Weapon Stats", Color3.fromRGB(60, 62, 74))
weaponStatsButton.Parent = navFrame

--[[ 5. CLOSE BUTTON (Now in top-right of header) ]]--
local mainCloseButton = create("TextButton", {
	Name = "MainCloseButton",
	Parent = headerFrame,
	Size = UDim2.new(0, 40, 0, 40),
	Position = UDim2.new(1, -40, 0, 0),
	Text = "X",
	Font = Enum.Font.SourceSansBold,
	TextSize = 20,
	BackgroundColor3 = Color3.fromRGB(220, 80, 80),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.2
})
create("UICorner", { Parent = mainCloseButton, CornerRadius = UDim.new(0, 6) })
mainFrameLayout.Padding = UDim.new(0, 10) -- Adjust padding after removing the bottom close button

--================================================================================--
--[[ PANELS FOR TITLES, WEAPON STATS, ETC. (Re-styling them to match) ]]--
--================================================================================--
local titlesFrame, titlesScrollingFrame, titlesBackButton, titlesCloseButton = createSecondaryPanel("Titles", "Select a Title")
local weaponStatsFrame, weaponStatsScrollingFrame, weaponStatsBackButton, weaponStatsCloseButton = createSecondaryPanel("WeaponStats", "Weapon Statistics")

--================================================================================--
--[[ LOGIC (Now fully implemented) ]]--
--================================================================================--
-- Main data update function
local function updateProfileData()
	local currentXP, xpForNextLevel = 0, 1000 -- Default values
	local success, profileData = pcall(function()
		return profileRemoteFunction:InvokeServer()
	end)
	if success and profileData then
		-- Header
		nameLabel.Text = profileData.Name or "N/A"
		-- Core Progress
		levelLabel.Text = "LVL\n" .. (profileData.Level or 0)
		local xp = profileData.XP or 0
		local needed = xpForNextLevel -- Use the value from LevelUpdateEvent
		-- Guard against nil or zero 'needed' value to prevent errors
		if needed and needed > 0 then
			xpValueLabel.Text = string.format("%s / %s XP", formatNumber(xp), formatNumber(needed))
			local progress = math.clamp(xp / needed, 0, 1)
			TweenService:Create(xpBarFill, TweenInfo.new(0.5), { Size = UDim2.new(progress, 0, 1, 0) }):Play()
		else
			-- Handle cases where XP needed is not available or player is max level
			xpValueLabel.Text = string.format("%s XP", formatNumber(xp))
			TweenService:Create(xpBarFill, TweenInfo.new(0.5), { Size = UDim2.new(1, 0, 1, 0) }):Play() -- Show full bar
		end
		-- Combat Stats
		totalKillsLabel.Text = "Total Kills: " .. formatNumber(profileData.TotalKills or 0)
		totalDamageLabel.Text = "Total Damage: " .. formatNumber(profileData.TotalDamageDealt or 0)
		totalKnocksLabel.Text = "Total Knocks: " .. formatNumber(profileData.TotalKnocks or 0)
		totalRevivesLabel.Text = "Total Revives: " .. formatNumber(profileData.TotalRevives or 0)
		-- Progression Stats
		lifetimeCoinsLabel.Text = "Lifetime Coins: " .. formatNumber(profileData.TotalCoins or 0)
		lifetimeAPLabel.Text = "Lifetime AP: " .. formatNumber(profileData.LifetimeAP or 0)
		lifetimeMPLabel.Text = "Lifetime MP: " .. formatNumber(profileData.LifetimeMP or 0)
	else
		warn("Failed to get profile data.")
	end
end

-- Navigation between panels
local function openPanel(panelToShow)
	mainFrame.Visible = false
	panelToShow.Visible = true
end

local function closeAllPanels()
	mainFrame.Visible = false
	titlesFrame.Visible = false
	weaponStatsFrame.Visible = false
end

local function populateTitles()
	for _, child in ipairs(titlesScrollingFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local success, titleData = pcall(function() return getTitleDataFunc:InvokeServer() end)
	if not success then warn("Failed to get title data.") return end
	local unlockedTitles = titleData.UnlockedTitles or {}
	local equippedTitle = titleData.EquippedTitle or ""
	playerTitleLabel.Text = equippedTitle == "" and "No Title Equipped" or equippedTitle
	-- Unequip button
	local unequipButton = create("TextButton", {
		Name = "UnequipTitle", Parent = titlesScrollingFrame, Size = UDim2.new(1, 0, 0, 40),
		Text = "Unequip Title", Font = Enum.Font.SourceSans, TextSize = 18,
		BackgroundColor3 = equippedTitle == "" and Color3.fromRGB(100, 180, 100) or Color3.fromRGB(65, 65, 65),
		TextColor3 = Color3.fromRGB(255, 255, 255)
	})
	unequipButton.MouseButton1Click:Connect(function()
		setEquippedTitleEvent:FireServer("")
		closeAllPanels(titlesFrame)
	end)
	for _, title in ipairs(unlockedTitles) do
		local titleButton = create("TextButton", {
			Name = title, Parent = titlesScrollingFrame, Size = UDim2.new(1, 0, 0, 40),
			Text = title, Font = Enum.Font.SourceSans, TextSize = 18,
			BackgroundColor3 = title == equippedTitle and Color3.fromRGB(100, 180, 100) or Color3.fromRGB(65, 65, 65),
			TextColor3 = Color3.fromRGB(255, 255, 255)
		})
		titleButton.MouseButton1Click:Connect(function()
			setEquippedTitleEvent:FireServer(title)
			closeAllPanels(titlesFrame)
		end)
	end
end

local function populateWeaponStats()
	for _, child in ipairs(weaponStatsScrollingFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end
	local success, weaponStats = pcall(function() return getWeaponStatsFunc:InvokeServer() end)
	if not success then warn("Failed to get weapon stats.") return end
	if #weaponStats == 0 then
		create("TextLabel", { Parent = weaponStatsScrollingFrame, Size = UDim2.new(1, 0, 0, 40),
			Text = "No weapon stats recorded yet.", Font = Enum.Font.SourceSans, TextSize = 18,
			TextColor3 = Color3.fromRGB(200, 200, 200), BackgroundTransparency = 1
		})
		return
	end
	for _, stat in ipairs(weaponStats) do
		create("TextLabel", { Parent = weaponStatsScrollingFrame, Size = UDim2.new(1, 0, 0, 45),
			Text = string.format("  %s\n  Kills: %s | Damage: %s", stat.Name, formatNumber(stat.Kills), formatNumber(stat.Damage)),
			Font = Enum.Font.SourceSans, TextSize = 18, TextColor3 = Color3.fromRGB(220, 220, 220),
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, BackgroundTransparency = 1
		})
	end
end

-- Event listener for level updates (for XP bar)
local currentXP, xpForNextLevel = 0, 1000 -- Default values
LevelUpdateEvent.OnClientEvent:Connect(function(level, xp, xpNeeded)
	currentXP = xp
	xpForNextLevel = xpNeeded or 1000
	if mainFrame.Visible then
		updateProfileData() -- Refresh all data to ensure consistency
	end
end)

-- Button Visibility Logic
profileButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = true
end)

mainCloseButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

local function backToMain(panelToHide)
	panelToHide.Visible = false
	mainFrame.Visible = true
	updateProfileData() -- Refresh data when coming back
end

-- Titles Panel Logic
titlesButton.MouseButton1Click:Connect(function()
	openPanel(titlesFrame)
	populateTitles()
end)
titlesBackButton.MouseButton1Click:Connect(function() backToMain(titlesFrame) end)
titlesCloseButton.MouseButton1Click:Connect(closeAllPanels)

-- Weapon Stats Panel Logic
weaponStatsButton.MouseButton1Click:Connect(function()
	openPanel(weaponStatsFrame)
	populateWeaponStats()
end)
weaponStatsBackButton.MouseButton1Click:Connect(function() backToMain(weaponStatsFrame) end)
weaponStatsCloseButton.MouseButton1Click:Connect(closeAllPanels)

-- External UI Toggles
local bindableEvents = ReplicatedStorage:WaitForChild("BindableEvents")
local toggleSkillUIEvent = bindableEvents:WaitForChild("ToggleSkillUIEvent")
local toggleAchievementUIEvent = bindableEvents:WaitForChild("ToggleAchievementUIEvent")

-- Create a specific event for other UIs to call this one back
local toggleProfileUIEvent = Instance.new("BindableEvent", bindableEvents)
toggleProfileUIEvent.Name = "ToggleProfileUIEvent"
toggleProfileUIEvent.Event:Connect(function(visible)
	mainFrame.Visible = visible
end)

skillsButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	toggleSkillUIEvent:Fire(true)
end)

achievementsButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	toggleAchievementUIEvent:Fire(true)
end)

-- Main visibility change handler
mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	if mainFrame.Visible then
		updateProfileData()
	end
end)
