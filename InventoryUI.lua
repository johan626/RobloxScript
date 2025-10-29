-- InventoryUI.lua (LocalScript)
-- Path: StarterGui/InventoryUI.lua
-- Script Place: Lobby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Module & Event References
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ReplicatedStorage.ModuleScript:WaitForChild("ModelPreviewModule"))
local inventoryRemote = ReplicatedStorage:WaitForChild("GetInventoryData")
local skinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SkinManagementEvent")

-- Booster-related events and functions
local BoosterUpdateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BoosterUpdateEvent")
local ActivateBoosterEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ActivateBoosterEvent")
local GetBoosterConfig = ReplicatedStorage.RemoteFunctions:WaitForChild("GetBoosterConfig")

-- UI Elements
local inventoryScreenGui = Instance.new("ScreenGui")
inventoryScreenGui.Name = "InventoryScreenGui"
inventoryScreenGui.Enabled = true
inventoryScreenGui.Parent = player:WaitForChild("PlayerGui")

-- ... (Creation of all other UI elements like inventoryButton, mainFrame, etc. remains the same)
local inventoryButton = Instance.new("TextButton")
inventoryButton.Name = "InventoryButton"
inventoryButton.Parent = inventoryScreenGui
inventoryButton.AnchorPoint = Vector2.new(0.5, 1)
inventoryButton.Size = UDim2.new(0.2, 0, 0.1, 0)
inventoryButton.Position = UDim2.new(0.5, 0, 0.98, 0)
inventoryButton.Text = "Inventory"
inventoryButton.Font = Enum.Font.GothamSemibold
inventoryButton.TextSize = 20
inventoryButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
inventoryButton.TextColor3 = Color3.new(1, 1, 1)
local btnCorner = Instance.new("UICorner", inventoryButton)
btnCorner.CornerRadius = UDim.new(0, 8)

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = inventoryScreenGui
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
mainFrame.Active = true
mainFrame.Visible = false
local frameCorner = Instance.new("UICorner", mainFrame)
frameCorner.CornerRadius = UDim.new(0, 8)

local aspectRatioConstraint = Instance.new("UIAspectRatioConstraint", mainFrame)
aspectRatioConstraint.AspectRatio = 1.6
aspectRatioConstraint.DominantAxis = Enum.DominantAxis.Width

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0.1, 0)
title.Text = "INVENTORY"
title.Font = Enum.Font.GothamSemibold
title.TextSize = 28
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
local titleCorner = Instance.new("UICorner", title)
titleCorner.CornerRadius = UDim.new(0, 8)

local backButton = Instance.new("TextButton", mainFrame)
backButton.Size = UDim2.new(0.1, 0, 0.08, 0)
backButton.Position = UDim2.new(0.02, 0, 0.01, 0)
backButton.Text = "Back"
backButton.Font = Enum.Font.GothamSemibold
backButton.TextSize = 16
backButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
backButton.TextColor3 = Color3.new(1, 1, 1)
local backCorner = Instance.new("UICorner", backButton)
backCorner.CornerRadius = UDim.new(0, 6)

-- Tab System
local tabsFrame = Instance.new("Frame", mainFrame)
tabsFrame.Name = "TabsFrame"
tabsFrame.Size = UDim2.new(1, 0, 0.08, 0)
tabsFrame.Position = UDim2.new(0, 0, 0.1, 0)
tabsFrame.BackgroundTransparency = 1
local tabsLayout = Instance.new("UIListLayout", tabsFrame)
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabsLayout.Padding = UDim.new(0, 10)

local skinsTabButton = Instance.new("TextButton", tabsFrame)
skinsTabButton.Name = "SkinsTab"
skinsTabButton.Size = UDim2.new(0.2, 0, 0.8, 0)
skinsTabButton.Text = "Skins"
skinsTabButton.Font = Enum.Font.GothamSemibold
skinsTabButton.TextSize = 16
skinsTabButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
skinsTabButton.TextColor3 = Color3.new(1, 1, 1)
local skinsCorner = Instance.new("UICorner", skinsTabButton)
skinsCorner.CornerRadius = UDim.new(0, 6)

local boostersTabButton = Instance.new("TextButton", tabsFrame)
boostersTabButton.Name = "BoostersTab"
boostersTabButton.Size = UDim2.new(0.2, 0, 0.8, 0)
boostersTabButton.Text = "Boosters"
boostersTabButton.Font = Enum.Font.GothamSemibold
boostersTabButton.TextSize = 16
boostersTabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
boostersTabButton.TextColor3 = Color3.fromRGB(160, 160, 160)
local boostersCorner = Instance.new("UICorner", boostersTabButton)
boostersCorner.CornerRadius = UDim.new(0, 6)

-- Main content area that will hold the different tab contents
local tabContentFrame = Instance.new("Frame", mainFrame)
tabContentFrame.Name = "TabContentFrame"
tabContentFrame.Size = UDim2.new(0.95, 0, 0.8, 0)
tabContentFrame.Position = UDim2.new(0.5, 0, 0.59, 0)
tabContentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
tabContentFrame.BackgroundTransparency = 1

-- Container for the skins content
local skinsContentFrame = Instance.new("Frame", tabContentFrame)
skinsContentFrame.Name = "SkinsContentFrame"
skinsContentFrame.Size = UDim2.new(1, 0, 1, 0)
skinsContentFrame.BackgroundTransparency = 1
skinsContentFrame.Visible = true

-- Container for the boosters content (initially hidden)
local boostersContentFrame = Instance.new("Frame", tabContentFrame)
boostersContentFrame.Name = "BoostersContentFrame"
boostersContentFrame.Size = UDim2.new(1, 0, 1, 0)
boostersContentFrame.BackgroundTransparency = 1
boostersContentFrame.Visible = false

-- The original contentFrame is now parented to the skinsContentFrame
local contentFrame = Instance.new("Frame", skinsContentFrame)
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, 0, 1, 0)
contentFrame.Position = UDim2.new(0, 0, 0, 0)
contentFrame.AnchorPoint = Vector2.new(0, 0)
contentFrame.BackgroundTransparency = 1
local contentLayout = Instance.new("UIListLayout", contentFrame)
contentLayout.FillDirection = Enum.FillDirection.Horizontal
contentLayout.Padding = UDim.new(0, 10)
contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local leftColumn = Instance.new("Frame", contentFrame)
leftColumn.Name = "LeftColumn"
leftColumn.Size = UDim2.new(0.25, 0, 1, 0)
leftColumn.BackgroundTransparency = 1
leftColumn.LayoutOrder = 1
local leftColumnLayout = Instance.new("UIListLayout", leftColumn)
leftColumnLayout.FillDirection = Enum.FillDirection.Vertical
leftColumnLayout.Padding = UDim.new(0, 12)

local categoryFilterFrame = Instance.new("Frame", leftColumn)
categoryFilterFrame.Name = "CategoryFilterFrame"
categoryFilterFrame.Size = UDim2.new(1, 0, 0, 70)
categoryFilterFrame.BackgroundTransparency = 1
local cf_layout = Instance.new("UIGridLayout", categoryFilterFrame)
cf_layout.CellPadding = UDim2.new(0, 5, 0, 5)
cf_layout.CellSize = UDim2.new(0.45, 0, 0.45, 0)
cf_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cf_layout.VerticalAlignment = Enum.VerticalAlignment.Center

local searchBar = Instance.new("TextBox", leftColumn)
searchBar.Name = "SearchBar"
searchBar.Size = UDim2.new(1, 0, 0, 30)
searchBar.Font = Enum.Font.Gotham
searchBar.TextSize = 14
searchBar.PlaceholderText = "Search for a weapon..."
searchBar.Text = ""
searchBar.TextColor3 = Color3.new(1, 1, 1)
searchBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
searchBar.ClearTextOnFocus = false
local sb_corner = Instance.new("UICorner", searchBar)
sb_corner.CornerRadius = UDim.new(0, 6)
local sb_padding = Instance.new("UIPadding", searchBar)
sb_padding.PaddingLeft = UDim.new(0, 8)

local weaponListFrame = Instance.new("ScrollingFrame", leftColumn)
weaponListFrame.Name = "WeaponListFrame"
weaponListFrame.Size = UDim2.new(1, 0, 1, -120) -- 70(filter) + 10(pad) + 30(search) + 10(pad) = 120
weaponListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
local wl_corner = Instance.new("UICorner", weaponListFrame)
wl_corner.CornerRadius = UDim.new(0, 8)
local wl_layout = Instance.new("UIListLayout", weaponListFrame)
wl_layout.Padding = UDim.new(0, 5)
wl_layout.SortOrder = Enum.SortOrder.Name
local wl_padding = Instance.new("UIPadding", weaponListFrame)
wl_padding.PaddingLeft = UDim.new(0, 10)
wl_padding.PaddingRight = UDim.new(0, 10)
wl_padding.PaddingTop = UDim.new(0, 5)
wl_padding.PaddingBottom = UDim.new(0, 5)

local separator1 = Instance.new("Frame", contentFrame)
separator1.Name = "Separator1"
separator1.Size = UDim2.new(0.005, 0, 0.9, 0)
separator1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
separator1.BackgroundTransparency = 0.5
separator1.BorderSizePixel = 0
separator1.LayoutOrder = 2

local middleColumn = Instance.new("Frame", contentFrame)
middleColumn.Name = "MiddleColumn"
middleColumn.Size = UDim2.new(0.44, 0, 1, 0)
middleColumn.BackgroundTransparency = 1
middleColumn.LayoutOrder = 3

local separator2 = Instance.new("Frame", contentFrame)
separator2.Name = "Separator2"
separator2.Size = UDim2.new(0.005, 0, 0.9, 0)
separator2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
separator2.BackgroundTransparency = 0.5
separator2.BorderSizePixel = 0
separator2.LayoutOrder = 4

local rightColumn = Instance.new("Frame", contentFrame)
rightColumn.Name = "RightColumn"
rightColumn.Size = UDim2.new(0.3, 0, 1, 0)
rightColumn.BackgroundTransparency = 1
rightColumn.LayoutOrder = 5
local rightColumnLayout = Instance.new("UIListLayout", rightColumn)
rightColumnLayout.Padding = UDim.new(0, 10)
rightColumnLayout.SortOrder = Enum.SortOrder.LayoutOrder

local weaponTitleLabel = Instance.new("TextLabel", rightColumn)
weaponTitleLabel.Name = "WeaponTitleLabel"
weaponTitleLabel.Size = UDim2.new(1, 0, 0, 40)
weaponTitleLabel.Font = Enum.Font.GothamBold
weaponTitleLabel.Text = "SELECT A WEAPON"
weaponTitleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
weaponTitleLabel.TextSize = 26
weaponTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponTitleLabel.BackgroundTransparency = 1
weaponTitleLabel.LayoutOrder = 1
weaponTitleLabel.Visible = true

local statsFrame = Instance.new("Frame", rightColumn)
statsFrame.Name = "StatsFrame"
statsFrame.Size = UDim2.new(1, 0, 0, 100)
statsFrame.BackgroundTransparency = 1
statsFrame.LayoutOrder = 2
local statsLayout = Instance.new("UIListLayout", statsFrame)
statsLayout.Padding = UDim.new(0, 8)

local function createStatBar(name, parent)
	local statFrame = Instance.new("Frame", parent)
	statFrame.Name = name .. "Stat"
	statFrame.Size = UDim2.new(1, 0, 0, 24)
	statFrame.BackgroundTransparency = 1
	local layout = Instance.new("UIListLayout", statFrame)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 2)
	local title = Instance.new("TextLabel", statFrame)
	title.Size = UDim2.new(1, 0, 0, 12)
	title.Text = string.upper(name)
	title.Font = Enum.Font.GothamSemibold
	title.TextColor3 = Color3.fromRGB(200, 200, 200)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.BackgroundTransparency = 1
	local barTrack = Instance.new("Frame", statFrame)
	barTrack.Size = UDim2.new(1, 0, 0, 8)
	barTrack.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	local trackCorner = Instance.new("UICorner", barTrack)
	trackCorner.CornerRadius = UDim.new(1, 0)
	local barFill = Instance.new("Frame", barTrack)
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	local fillCorner = Instance.new("UICorner", barFill)
	fillCorner.CornerRadius = UDim.new(1, 0)
	return barFill
end

local damageBar = createStatBar("Damage", statsFrame)
local ammoBar = createStatBar("Ammo", statsFrame)
local recoilBar = createStatBar("Recoil", statsFrame)

local skinsTitle = Instance.new("TextLabel", rightColumn)
skinsTitle.Name = "SkinsTitle"
skinsTitle.Size = UDim2.new(1, 0, 0, 20)
skinsTitle.Text = "AVAILABLE SKINS"
skinsTitle.Font = Enum.Font.GothamBold
skinsTitle.TextSize = 16
skinsTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
skinsTitle.BackgroundTransparency = 1
skinsTitle.LayoutOrder = 3

local skinListFrame = Instance.new("ScrollingFrame", rightColumn)
skinListFrame.Name = "SkinListFrame"
skinListFrame.Size = UDim2.new(1, 0, 0, 100)
skinListFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
skinListFrame.BackgroundTransparency = 0.5
skinListFrame.BorderSizePixel = 0
skinListFrame.LayoutOrder = 4
skinListFrame.CanvasSize = UDim2.new(2, 0, 0, 0)
skinListFrame.ScrollBarThickness = 4
skinListFrame.ScrollingDirection = Enum.ScrollingDirection.X
local sl_layout = Instance.new("UIListLayout", skinListFrame)
sl_layout.FillDirection = Enum.FillDirection.Horizontal
sl_layout.Padding = UDim.new(0, 10)
sl_layout.VerticalAlignment = Enum.VerticalAlignment.Center

local equipButton = Instance.new("TextButton", rightColumn)
equipButton.Name = "EquipButton"
equipButton.Size = UDim2.new(1, 0, 0, 40)
equipButton.Text = "EQUIP SKIN"
equipButton.Font = Enum.Font.GothamBold
equipButton.TextSize = 16
equipButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
equipButton.TextColor3 = Color3.new(1, 1, 1)
equipButton.LayoutOrder = 5
local equipCorner = Instance.new("UICorner", equipButton)
equipCorner.CornerRadius = UDim.new(0, 8)
equipButton.AutoButtonColor = false

-- Add hover and press animations for the equip button
equipButton.MouseEnter:Connect(function()
	if equipButton.AutoButtonColor then
		TweenService:Create(equipButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(100, 100, 100)}):Play()
	end
end)

equipButton.MouseLeave:Connect(function()
	if equipButton.AutoButtonColor then
		TweenService:Create(equipButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}):Play()
	end
end)

equipButton.MouseButton1Down:Connect(function()
	if equipButton.AutoButtonColor then
		TweenService:Create(equipButton, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 36)}):Play()
	end
end)

equipButton.MouseButton1Up:Connect(function()
	if equipButton.AutoButtonColor then
		TweenService:Create(equipButton, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 40)}):Play()
	end
end)

local viewportFrame = Instance.new("ViewportFrame", middleColumn)
viewportFrame.Name = "ViewportFrame"
viewportFrame.Size = UDim2.new(1, 0, 1, 0)
viewportFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
viewportFrame.BorderSizePixel = 0
viewportFrame.LightColor = Color3.new(1, 1, 1)
viewportFrame.LightDirection = Vector3.new(-1, -1, -1)
local viewportCorner = Instance.new("UICorner", viewportFrame)
viewportCorner.CornerRadius = UDim.new(0, 8)

local loadingIndicator = Instance.new("TextLabel", viewportFrame)
loadingIndicator.Name = "LoadingIndicator"
loadingIndicator.Size = UDim2.new(0.5, 0, 0.2, 0)
loadingIndicator.Position = UDim2.new(0.5, 0, 0.5, 0)
loadingIndicator.AnchorPoint = Vector2.new(0.5, 0.5)
loadingIndicator.Text = "Loading..."
loadingIndicator.Font = Enum.Font.SourceSansBold
loadingIndicator.TextSize = 24
loadingIndicator.TextColor3 = Color3.fromRGB(200, 200, 200)
loadingIndicator.BackgroundTransparency = 1
loadingIndicator.Visible = false -- Hidden by default

local sliderTrack = Instance.new("Frame", viewportFrame)
sliderTrack.Name = "SliderTrack"
sliderTrack.Size = UDim2.new(0.8, 0, 0, 10)
sliderTrack.Position = UDim2.new(0.1, 0, 1, -25)
sliderTrack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
sliderTrack.BorderSizePixel = 0
local trackCorner = Instance.new("UICorner", sliderTrack)
trackCorner.CornerRadius = UDim.new(0, 5)
sliderTrack.Visible = false

local sliderFill = Instance.new("Frame", sliderTrack)
sliderFill.Name = "SliderFill"
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
sliderFill.BorderSizePixel = 0
local fillCorner = Instance.new("UICorner", sliderFill)
fillCorner.CornerRadius = UDim.new(0, 5)

local sliderHandle = Instance.new("ImageButton", sliderTrack)
sliderHandle.Name = "SliderHandle"
sliderHandle.Size = UDim2.new(0, 20, 0, 20)
sliderHandle.AnchorPoint = Vector2.new(0.5, 0.5)
sliderHandle.Position = UDim2.new(0.5, 0, 0.5, 0)
sliderHandle.BackgroundColor3 = Color3.new(1, 1, 1)
sliderHandle.BorderSizePixel = 0
local handleCorner = Instance.new("UICorner", sliderHandle)
handleCorner.CornerRadius = UDim.new(1, 0)

-- State variables
local inventoryData = nil
local selectedWeapon = nil
local selectedSkin = nil
local selectedCategory = "All"
local categoryButtons = {}
local currentPreview = nil -- [REFACTORED]
local currentTab = "Skins" -- Can be "Skins" or "Boosters"
local boosterConfig = nil
local boosterData = nil
local assetCache = {} -- Cache for loaded preview assets

task.wait()

-- Booster UI Logic
local function fetchBoosterConfig()
	if boosterConfig then return true end

	local success, result = pcall(function()
		return GetBoosterConfig:InvokeServer()
	end)

	if success and type(result) == "table" then
		boosterConfig = result
		return true
	else
		warn("Could not fetch booster config: " .. tostring(result))
		return false
	end
end

local function updateBoosterTab()
	-- Clear previous items
	for _, child in ipairs(boostersContentFrame:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	if not boosterData then
		warn("Booster data not available for UI update.")
		return
	end

	if not fetchBoosterConfig() then return end

	-- Create a scrolling frame for boosters
	local inventoryScrollingFrame = Instance.new("ScrollingFrame")
	inventoryScrollingFrame.Name = "BoosterListFrame"
	inventoryScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
	inventoryScrollingFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	inventoryScrollingFrame.BorderSizePixel = 0
	inventoryScrollingFrame.Parent = boostersContentFrame

	local inventoryList = Instance.new("UIListLayout", inventoryScrollingFrame)
	inventoryList.Padding = UDim.new(0, 8)
	inventoryList.FillDirection = Enum.FillDirection.Vertical
	inventoryList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	inventoryList.SortOrder = Enum.SortOrder.LayoutOrder

	local ownedBoosters = 0
	for boosterName, count in pairs(boosterData.Owned) do
		if count > 0 then
			ownedBoosters = ownedBoosters + 1
			local boosterInfo = boosterConfig[boosterName] or {}

			local entryFrame = Instance.new("Frame")
			entryFrame.Name = boosterName
			entryFrame.Size = UDim2.new(0.95, 0, 0, 90)
			entryFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			entryFrame.BorderSizePixel = 0
			entryFrame.Parent = inventoryScrollingFrame
			local corner = Instance.new("UICorner", entryFrame)
			corner.CornerRadius = UDim.new(0, 8)

			local iconFrame = Instance.new("Frame")
			iconFrame.Name = "IconFrame"
			iconFrame.Size = UDim2.new(0, 50, 0, 50)
			iconFrame.Position = UDim2.new(0, 10, 0.5, -25)
			iconFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			iconFrame.Parent = entryFrame
			local iconCorner = Instance.new("UICorner", iconFrame)
			iconCorner.CornerRadius = UDim.new(0, 8)

			local iconLabel = Instance.new("TextLabel")
			iconLabel.Name = "IconLabel"
			iconLabel.Size = UDim2.new(1, 0, 1, 0)
			iconLabel.Font = Enum.Font.GothamBold
			iconLabel.TextSize = 20
			iconLabel.TextColor3 = Color3.new(1,1,1)
			iconLabel.BackgroundTransparency = 1
			iconLabel.Text = boosterInfo.Icon or "?"
			iconLabel.Parent = iconFrame

			local infoFrame = Instance.new("Frame")
			infoFrame.Name = "InfoFrame"
			infoFrame.Size = UDim2.new(1, -160, 1, -20)
			infoFrame.Position = UDim2.new(0, 70, 0, 10)
			infoFrame.BackgroundTransparency = 1
			infoFrame.Parent = entryFrame

			local listLayout = Instance.new("UIListLayout", infoFrame)
			listLayout.Padding = UDim.new(0, 2)
			listLayout.SortOrder = Enum.SortOrder.LayoutOrder

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "NameLabel"
			nameLabel.Size = UDim2.new(1, 0, 0, 20)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 16
			nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
			nameLabel.Text = (boosterInfo.Name or boosterName) .. " (x" .. count .. ")"
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.BackgroundTransparency = 1
			nameLabel.LayoutOrder = 1
			nameLabel.Parent = infoFrame

			local descLabel = Instance.new("TextLabel")
			descLabel.Name = "DescLabel"
			descLabel.Size = UDim2.new(1, 0, 0, 36)
			descLabel.Font = Enum.Font.Gotham
			descLabel.TextSize = 12
			descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			descLabel.Text = boosterInfo.Description or ""
			descLabel.TextWrapped = true
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.TextYAlignment = Enum.TextYAlignment.Top
			descLabel.BackgroundTransparency = 1
			descLabel.LayoutOrder = 2
			descLabel.Parent = infoFrame

			local equipButton = Instance.new("TextButton")
			equipButton.Size = UDim2.new(0, 80, 0, 36)
			equipButton.Position = UDim2.new(1, -90, 0.5, -18)
			equipButton.Font = Enum.Font.GothamBold
			equipButton.TextSize = 14
			equipButton.TextColor3 = Color3.new(1,1,1)
			equipButton.Parent = entryFrame
			local equipCorner = Instance.new("UICorner", equipButton)
			equipCorner.CornerRadius = UDim.new(0, 6)

			if boosterData.Active == boosterName then
				equipButton.Text = "EQUIPPED"
				equipButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242) -- Modern Blue
			else
				equipButton.Text = "EQUIP"
				equipButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			end

			equipButton.MouseButton1Click:Connect(function()
				ActivateBoosterEvent:FireServer(boosterName)
			end)
		end
	end

	if ownedBoosters == 0 then
		local noBoostersLabel = Instance.new("TextLabel")
		noBoostersLabel.Name = "NoBoosters"
		noBoostersLabel.Size = UDim2.new(1, -20, 0, 50)
		noBoostersLabel.Position = UDim2.new(0.5, -noBoostersLabel.Size.X.Offset/2, 0, 20)
		noBoostersLabel.Font = Enum.Font.Gotham
		noBoostersLabel.TextSize = 16
		noBoostersLabel.TextColor3 = Color3.fromRGB(181, 181, 181)
		noBoostersLabel.TextWrapped = true
		noBoostersLabel.Text = "You don't own any boosters. Visit the shop to buy some!"
		noBoostersLabel.BackgroundTransparency = 1
		noBoostersLabel.Parent = inventoryScrollingFrame
	end
end

-- [REFACTORED] Centralized preview update function
local function updatePreview(weaponName, skinName)
	if currentPreview then
		ModelPreviewModule.destroy(currentPreview)
		currentPreview = nil
	end

	-- Find the loading indicator
	local loadingIndicator = viewportFrame:FindFirstChild("LoadingIndicator")

	if not weaponName or not skinName then
		sliderTrack.Visible = false
		if loadingIndicator then loadingIndicator.Visible = false end
		return
	end

	local weaponData = WeaponModule.Weapons[weaponName]
	local skinData = weaponData and weaponData.Skins[skinName]
	if not weaponData or not skinData then return end

	local cacheKey = weaponName .. "_" .. skinName
	local isCached = assetCache[cacheKey]

	-- Only show loading indicator if assets are not cached
	if not isCached and loadingIndicator then
		loadingIndicator.Visible = true
	end

	-- Create the preview, providing a callback for when it's loaded
	currentPreview = ModelPreviewModule.create(viewportFrame, weaponData, skinData, function(loadedPreview)
		-- This code runs AFTER assets are preloaded

		-- Add to cache on successful load
		assetCache[cacheKey] = true

		if loadingIndicator then loadingIndicator.Visible = false end

		-- Only start rotation if this preview is still the current one
		if loadedPreview == currentPreview then
			ModelPreviewModule.startRotation(currentPreview, 2.5) -- Start with a closer zoom
			sliderTrack.Visible = true
			ModelPreviewModule.connectZoomSlider(currentPreview, sliderTrack, sliderHandle, sliderFill, 2.5, 10)
		end
	end)
end

local function updateStatsDisplay(weaponName)
	local data = weaponName and WeaponModule.Weapons[weaponName]
	if not data then
		statsFrame.Visible = false
		weaponTitleLabel.Text = "SELECT A WEAPON"
		return
	end
	statsFrame.Visible = true
	weaponTitleLabel.Text = string.upper(weaponName)
	local MAX_DAMAGE = 150
	local MAX_AMMO = 200
	local MAX_RECOIL = 10
	local damagePercent = math.clamp(data.Damage / MAX_DAMAGE, 0, 1)
	local ammoPercent = math.clamp(data.MaxAmmo / MAX_AMMO, 0, 1)
	local recoilPercent = 1 - math.clamp(data.Recoil / MAX_RECOIL, 0, 1)
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local newBarColor = Color3.fromRGB(200, 200, 200)
	TweenService:Create(damageBar, tweenInfo, {Size = UDim2.new(damagePercent, 0, 1, 0)}):Play()
	TweenService:Create(ammoBar, tweenInfo, {Size = UDim2.new(ammoPercent, 0, 1, 0)}):Play()
	TweenService:Create(recoilBar, tweenInfo, {Size = UDim2.new(recoilPercent, 0, 1, 0)}):Play()
	damageBar.BackgroundColor3 = newBarColor
	ammoBar.BackgroundColor3 = newBarColor
	recoilBar.BackgroundColor3 = newBarColor
end

local function updateSkinList()
	for _, child in ipairs(skinListFrame:GetChildren()) do
		if not child:IsA("UILayout") then child:Destroy() end
	end
	selectedSkin = nil
	local weaponData = selectedWeapon and WeaponModule.Weapons[selectedWeapon]
	if not weaponData or not weaponData.Skins or not inventoryData then
		skinListFrame.Visible = false
		skinsTitle.Visible = false
		equipButton.Visible = false
		return
	end
	skinListFrame.Visible = true
	skinsTitle.Visible = true
	equipButton.Visible = true
	local ownedSkins = inventoryData.Skins.Owned[selectedWeapon]
	local equippedSkin = inventoryData.Skins.Equipped[selectedWeapon]
	local function setEquipButtonState()
		if not selectedSkin then
			equipButton.Text = "SELECT A SKIN"
			equipButton.AutoButtonColor = false
			equipButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
		elseif selectedSkin == equippedSkin then
			equipButton.Text = "EQUIPPED"
			equipButton.AutoButtonColor = false
			equipButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242) -- Modern Blue
		else
			equipButton.Text = "EQUIP " .. string.upper(selectedSkin)
			equipButton.AutoButtonColor = true
			equipButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		end
	end
	local function resetAllBorders()
		for _, btn in ipairs(skinListFrame:GetChildren()) do
			if btn:IsA("ImageButton") and btn:FindFirstChild("UIStroke") then
				local btnBorder = btn:FindFirstChild("UIStroke")
				if btn.Name == equippedSkin then
					btnBorder.Color = Color3.fromRGB(88, 101, 242) -- Modern Blue
					btnBorder.Thickness = 3
				else
					btnBorder.Color = Color3.fromRGB(80, 80, 80)
					btnBorder.Thickness = 2
				end
			end
		end
	end
	table.sort(ownedSkins, function(a, b)
		if a == equippedSkin then return true end
		if b == equippedSkin then return false end
		return a < b
	end)
	for i, skinName in ipairs(ownedSkins) do
		local skinData = WeaponModule.Weapons[selectedWeapon].Skins[skinName]
		if skinData then
			local thumbButton = Instance.new("ImageButton")
			thumbButton.Name = skinName
			thumbButton.Size = UDim2.new(0, 80, 0, 80)
			thumbButton.Image = skinData.TextureId or ""
			thumbButton.ScaleType = Enum.ScaleType.Fit
			thumbButton.LayoutOrder = i
			thumbButton.Parent = skinListFrame
			local corner = Instance.new("UICorner", thumbButton)
			corner.CornerRadius = UDim.new(0, 6)
			local border = Instance.new("UIStroke", thumbButton)
			border.Thickness = 2
			border.Color = Color3.fromRGB(80, 80, 80)
			thumbButton.MouseButton1Click:Connect(function()
				selectedSkin = skinName
				updatePreview(selectedWeapon, selectedSkin)
				resetAllBorders()
				border.Color = Color3.fromRGB(120, 131, 255) -- Lighter Modern Blue for selection
				border.Thickness = 3
				setEquipButtonState()
			end)
		end
	end
	resetAllBorders()
	setEquipButtonState()
	sl_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Once(function()
		skinListFrame.CanvasSize = UDim2.new(0, sl_layout.AbsoluteContentSize.X, 0, 0)
	end)
end

function updateWeaponList(categoryFilter, searchFilter)
	for _, child in ipairs(weaponListFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end

	local lowerSearchFilter = searchFilter and string.lower(searchFilter) or ""

	local weaponNames = {}
	for name, data in pairs(WeaponModule.Weapons) do
		local passesCategory = categoryFilter == "All" or (data.Category and data.Category == categoryFilter)
		local passesSearch = lowerSearchFilter == "" or string.find(string.lower(name), lowerSearchFilter, 1, true)

		if passesCategory and passesSearch then
			table.insert(weaponNames, name)
		end
	end
	table.sort(weaponNames)
	for _, weaponName in ipairs(weaponNames) do
		local weaponButton = Instance.new("TextButton")
		weaponButton.Name = weaponName
		weaponButton.Size = UDim2.new(1, -10, 0, 40)
		weaponButton.Text = weaponName
		weaponButton.Font = Enum.Font.Gotham
		weaponButton.TextSize = 16
		weaponButton.TextColor3 = Color3.new(1, 1, 1)
		weaponButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		weaponButton.Parent = weaponListFrame
		weaponButton.MouseButton1Click:Connect(function()
			selectedWeapon = weaponName
			for _, btn in ipairs(weaponListFrame:GetChildren()) do
				if btn:IsA("TextButton") then btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60) end
			end
			weaponButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			updateStatsDisplay(weaponName)
			updateSkinList()
			local equippedSkin = inventoryData.Skins.Equipped[selectedWeapon]
			updatePreview(selectedWeapon, equippedSkin)
		end)
	end
end

local function createCategoryButtons()
	local categories = {"All", "Pistol", "Assault Rifle", "SMG", "Shotgun", "Sniper", "LMG"}
	local function highlightActiveButton()
		for name, button in pairs(categoryButtons) do
			if name == selectedCategory then
				button.BackgroundColor3 = Color3.fromRGB(88, 101, 242) -- Modern Blue
				button.TextColor3 = Color3.new(1, 1, 1)
			else
				button.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
				button.TextColor3 = Color3.new(0.8, 0.8, 0.8)
			end
		end
	end
	if #categoryFilterFrame:GetChildren() > 1 then
		highlightActiveButton()
		return
	end
	for _, categoryName in ipairs(categories) do
		local categoryButton = Instance.new("TextButton")
		categoryButton.Name = categoryName
		categoryButton.Text = categoryName
		categoryButton.Font = Enum.Font.Gotham
		categoryButton.TextSize = 12
		local btnCorner = Instance.new("UICorner", categoryButton)
		btnCorner.CornerRadius = UDim.new(0, 6)
		categoryButton.Parent = categoryFilterFrame
		categoryButtons[categoryName] = categoryButton
		categoryButton.MouseButton1Click:Connect(function()
			selectedCategory = categoryName
			highlightActiveButton()
			updateWeaponList(selectedCategory, searchBar.Text)
		end)
	end
	highlightActiveButton()
end

-- Event Connections
searchBar:GetPropertyChangedSignal("Text"):Connect(function()
	updateWeaponList(selectedCategory, searchBar.Text)
end)
local function switchTab(tabName)
	currentTab = tabName
	if tabName == "Skins" then
		skinsContentFrame.Visible = true
		boostersContentFrame.Visible = false
		skinsTabButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		skinsTabButton.TextColor3 = Color3.new(1, 1, 1)
		boostersTabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		boostersTabButton.TextColor3 = Color3.fromRGB(160, 160, 160)
	elseif tabName == "Boosters" then
		skinsContentFrame.Visible = false
		boostersContentFrame.Visible = true
		skinsTabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		skinsTabButton.TextColor3 = Color3.fromRGB(160, 160, 160)
		boostersTabButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		boostersTabButton.TextColor3 = Color3.new(1, 1, 1)
	end
end

skinsTabButton.MouseButton1Click:Connect(function()
	switchTab("Skins")
end)

boostersTabButton.MouseButton1Click:Connect(function()
	if not boosterData then
		-- Fetch initial data and render
		BoosterUpdateEvent:Fire()
	end
	switchTab("Boosters")
end)

BoosterUpdateEvent.OnClientEvent:Connect(function(newBoosterData)
	boosterData = newBoosterData
	-- Only update the tab if it's currently visible
	if boostersContentFrame.Visible then
		updateBoosterTab()
	end
end)

inventoryButton.MouseButton1Click:Connect(function()
	if not inventoryData then
		inventoryData = inventoryRemote:InvokeServer()
	end
	createCategoryButtons()
	updateWeaponList(selectedCategory, searchBar.Text)
	updateSkinList()
	inventoryButton.Visible = false
	mainFrame.Visible = true
	switchTab("Skins") -- Ensure skins tab is active by default
end)

backButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	inventoryButton.Visible = true
	updatePreview(nil, nil) -- This will also destroy the preview
	updateStatsDisplay(nil)
end)

equipButton.MouseButton1Click:Connect(function()
	if not equipButton.AutoButtonColor then return end
	if selectedWeapon and selectedSkin then
		skinEvent:FireServer("EquipSkin", selectedWeapon, selectedSkin)
		inventoryData.Skins.Equipped[selectedWeapon] = selectedSkin
		updateSkinList()
	end
end)
