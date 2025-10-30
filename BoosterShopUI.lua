-- BoosterShopUI.lua (LocalScript)
-- Path: StarterGui/BoosterShopUI.lua
-- Script Place: Lobby
-- New "Armory" UI/UX Overhaul

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==================================
-- ======== SERVICE SETUP ===========
-- ==================================
local ToggleBoosterShopEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ToggleBoosterShopEvent")
local PurchaseBoosterFunction = ReplicatedStorage.RemoteFunctions:WaitForChild("PurchaseBoosterFunction")
local GetBoosterConfig = ReplicatedStorage.RemoteFunctions:WaitForChild("GetBoosterConfig")
local ActivateBoosterEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ActivateBoosterEvent")

-- ==================================
-- ======== UI SETUP ================
-- ==================================
local PALETTE = {
	Background = Color3.fromRGB(28, 28, 32),
	Primary = Color3.fromRGB(38, 38, 44),
	Secondary = Color3.fromRGB(48, 48, 56),
	Accent = Color3.fromRGB(88, 101, 242),
	AccentDark = Color3.fromRGB(71, 82, 194),
	Success = Color3.fromRGB(87, 242, 135),
	Failure = Color3.fromRGB(237, 66, 69),
	TextPrimary = Color3.fromRGB(242, 242, 242),
	TextSecondary = Color3.fromRGB(181, 181, 181),
	Gold = Color3.fromRGB(255, 215, 0),
	Transparent = Color3.fromRGB(0, 0, 0)
}

local FONTS = {
	Title = Enum.Font.GothamMedium,
	Body = Enum.Font.Gotham,
	Button = Enum.Font.GothamBold,
	Icon = Enum.Font.GothamBold
}

-- Helper functions
local function addCorner(ui, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = ui
	return corner
end

local function addStroke(ui, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or PALETTE.Secondary
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = ui
	return stroke
end

local screenGui = playerGui:FindFirstChild("BoosterSystemUI") or Instance.new("ScreenGui")
screenGui.Name = "BoosterSystemUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Size = UDim2.new(0.7, 0, 0.8, 0)
mainFrame.Position = UDim2.new(0.5, 0, 1.5, 0) -- Start off-screen
mainFrame.BackgroundColor3 = PALETTE.Primary
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui
addCorner(mainFrame, 12)
addStroke(mainFrame, PALETTE.Background, 2)

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = PALETTE.Secondary
titleBar.Parent = mainFrame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar
local titleClip = Instance.new("UICorner")
titleClip.Parent = titleCorner

local shopTitle = Instance.new("TextLabel")
shopTitle.Name = "Title"
shopTitle.Size = UDim2.new(1, -120, 1, 0)
shopTitle.Position = UDim2.new(0, 20, 0, 0)
shopTitle.Text = "BOOSTER ARMORY"
shopTitle.Font = FONTS.Title
shopTitle.TextSize = 22
shopTitle.TextColor3 = PALETTE.TextPrimary
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.BackgroundTransparency = 1
shopTitle.Parent = titleBar

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "CoinsLabel"
coinsLabel.Size = UDim2.new(0, 150, 1, 0)
coinsLabel.Position = UDim2.new(1, -190, 0, 0)
coinsLabel.Font = FONTS.Title
coinsLabel.TextSize = 18
coinsLabel.TextColor3 = PALETTE.Gold
coinsLabel.TextXAlignment = Enum.TextXAlignment.Right
coinsLabel.BackgroundTransparency = 1
coinsLabel.Text = "COINS: ..."
coinsLabel.Parent = titleBar

local shopCloseButton = Instance.new("TextButton")
shopCloseButton.Name = "CloseButton"
shopCloseButton.Size = UDim2.new(0, 32, 0, 32)
shopCloseButton.Position = UDim2.new(1, -42, 0.5, -16)
shopCloseButton.Text = "X"
shopCloseButton.Font = FONTS.Button
shopCloseButton.TextSize = 18
shopCloseButton.TextColor3 = PALETTE.TextPrimary
shopCloseButton.BackgroundColor3 = PALETTE.Failure
shopCloseButton.Parent = titleBar
addCorner(shopCloseButton, 8)

-- Content Frame
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -20, 1, -60)
contentFrame.Position = UDim2.new(0.5, 0, 0.5, 25)
contentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Details Panel
local detailsPanel = Instance.new("Frame")
detailsPanel.Name = "DetailsPanel"
detailsPanel.Size = UDim2.new(0.3, -10, 1, 0)
detailsPanel.BackgroundColor3 = PALETTE.Secondary
detailsPanel.Parent = contentFrame
addCorner(detailsPanel)

local detailsListLayout = Instance.new("UIListLayout")
detailsListLayout.Padding = UDim.new(0, 10)
detailsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
detailsListLayout.Parent = detailsPanel

local detailsPadding = Instance.new("UIPadding")
detailsPadding.PaddingTop = UDim.new(0, 15)
detailsPadding.PaddingLeft = UDim.new(0, 15)
detailsPadding.PaddingRight = UDim.new(0, 15)
detailsPadding.Parent = detailsPanel

local detailsTitle = Instance.new("TextLabel")
detailsTitle.Name = "DetailsTitle"
detailsTitle.Size = UDim2.new(1, 0, 0, 30)
detailsTitle.Font = FONTS.Title
detailsTitle.TextSize = 20
detailsTitle.TextColor3 = PALETTE.TextPrimary
detailsTitle.BackgroundTransparency = 1
detailsTitle.TextWrapped = true
detailsTitle.TextXAlignment = Enum.TextXAlignment.Left
detailsTitle.Text = "SELECT AN ITEM"
detailsTitle.LayoutOrder = 1
detailsTitle.Parent = detailsPanel

local detailsDesc = Instance.new("TextLabel")
detailsDesc.Name = "DetailsDesc"
detailsDesc.Size = UDim2.new(1, 0, 0, 0)
detailsDesc.AutomaticSize = Enum.AutomaticSize.Y
detailsDesc.Font = FONTS.Body
detailsDesc.TextSize = 16
detailsDesc.TextColor3 = PALETTE.TextSecondary
detailsDesc.TextWrapped = true
detailsDesc.TextXAlignment = Enum.TextXAlignment.Left
detailsDesc.TextYAlignment = Enum.TextYAlignment.Top
detailsDesc.BackgroundTransparency = 1
detailsDesc.Text = "Select a booster from the grid to see its details here."
detailsDesc.LayoutOrder = 2
detailsDesc.Parent = detailsPanel

local actionButton = Instance.new("TextButton")
actionButton.Name = "ActionButton"
actionButton.Size = UDim2.new(1, -40, 0, 60)
actionButton.Position = UDim2.new(0.5, 0, 1, -20)
actionButton.AnchorPoint = Vector2.new(0.5, 1)
actionButton.Font = FONTS.Button
actionButton.TextSize = 20
actionButton.TextColor3 = PALETTE.TextPrimary
actionButton.BackgroundColor3 = PALETTE.AccentDark
actionButton.TextWrapped = true
actionButton.Text = "---"
actionButton.Visible = false
actionButton.Parent = detailsPanel
addCorner(actionButton)

-- Item Grid
local gridContainer = Instance.new("ScrollingFrame")
gridContainer.Name = "GridContainer"
gridContainer.Size = UDim2.new(0.7, -10, 1, 0)
gridContainer.Position = UDim2.new(1, 0, 0.5, 0)
gridContainer.AnchorPoint = Vector2.new(1, 0.5)
gridContainer.BackgroundColor3 = PALETTE.Secondary
gridContainer.BorderSizePixel = 0
gridContainer.ScrollBarImageColor3 = PALETTE.Accent
gridContainer.ScrollBarThickness = 6
gridContainer.Parent = contentFrame
addCorner(gridContainer)

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
gridLayout.CellSize = UDim2.new(0, 130, 0, 160)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.Parent = gridContainer

-- Confirmation Popup
local confirmationPopup = Instance.new("Frame")
confirmationPopup.Name = "ConfirmationPopup"
confirmationPopup.Size = UDim2.new(0.4, 0, 0.3, 0)
confirmationPopup.Position = UDim2.new(0.5, 0, 0.5, 0)
confirmationPopup.AnchorPoint = Vector2.new(0.5, 0.5)
confirmationPopup.BackgroundColor3 = PALETTE.Secondary
confirmationPopup.BorderSizePixel = 2
confirmationPopup.BorderColor3 = PALETTE.Background
confirmationPopup.Visible = false
confirmationPopup.ZIndex = 3
confirmationPopup.Parent = mainFrame
addCorner(confirmationPopup, 12)

local popupText = Instance.new("TextLabel")
popupText.Name = "PopupText"
popupText.Size = UDim2.new(1, -20, 0.5, 0)
popupText.Position = UDim2.new(0.5, 0, 0.1, 0)
popupText.AnchorPoint = Vector2.new(0.5, 0)
popupText.Font = FONTS.Body
popupText.TextSize = 18
popupText.TextColor3 = PALETTE.TextPrimary
popupText.TextWrapped = true
popupText.BackgroundTransparency = 1
popupText.Parent = confirmationPopup

local confirmButton = Instance.new("TextButton")
confirmButton.Name = "ConfirmButton"
confirmButton.Size = UDim2.new(0.4, 0, 0, 40)
confirmButton.Position = UDim2.new(0.28, 0, 1, -60)
confirmButton.AnchorPoint = Vector2.new(0.5, 0)
confirmButton.BackgroundColor3 = PALETTE.Success
confirmButton.Font = FONTS.Button
confirmButton.Text = "CONFIRM"
confirmButton.TextColor3 = PALETTE.TextPrimary
confirmButton.Parent = confirmationPopup
addCorner(confirmButton)

local cancelButton = Instance.new("TextButton")
cancelButton.Name = "CancelButton"
cancelButton.Size = UDim2.new(0.4, 0, 0, 40)
cancelButton.Position = UDim2.new(0.72, 0, 1, -60)
cancelButton.AnchorPoint = Vector2.new(0.5, 0)
cancelButton.BackgroundColor3 = PALETTE.Failure
cancelButton.Font = FONTS.Button
cancelButton.Text = "CANCEL"
cancelButton.TextColor3 = PALETTE.TextPrimary
cancelButton.Parent = confirmationPopup
addCorner(cancelButton)

-- ==================================
-- ====== UI LOGIC ==================
-- ==================================
local boosterConfigCache = nil
local currentPlayerData = nil
local selectedBoosterId = nil

local function updateDetailsPanel(boosterId)
	selectedBoosterId = boosterId
	actionButton.Visible = false

	if not boosterId or not boosterConfigCache[boosterId] then
		detailsTitle.Text = "SELECT AN ITEM"
		detailsDesc.Text = "Select a booster from the grid to see its details here."
		return
	end

	local boosterInfo = boosterConfigCache[boosterId]
	detailsTitle.Text = boosterInfo.Name
	detailsDesc.Text = boosterInfo.Description

	actionButton.Visible = true
	local owned = currentPlayerData.inventory[boosterId] and currentPlayerData.inventory[boosterId] > 0

	if owned then
		local isActive = currentPlayerData.activeBooster == boosterId
		actionButton.Text = isActive and "ACTIVE" or "ACTIVATE"
		actionButton.BackgroundColor3 = isActive and PALETTE.Success or PALETTE.Accent
	else
		actionButton.Text = "BUY (" .. boosterInfo.Price .. ")"
		if currentPlayerData.coins < boosterInfo.Price then
			actionButton.BackgroundColor3 = PALETTE.AccentDark
			actionButton.Text = "INSUFFICIENT FUNDS"
		else
			actionButton.BackgroundColor3 = PALETTE.Accent
		end
	end
end

local function populateShop()
	if not boosterConfigCache then return end

	for _, child in ipairs(gridContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for boosterId, boosterInfo in pairs(boosterConfigCache) do
		local card = Instance.new("Frame")
		card.Name = boosterId
		card.BackgroundColor3 = PALETTE.Primary
		card.LayoutOrder = boosterInfo.Price
		card.Parent = gridContainer
		addCorner(card)
		addStroke(card, PALETTE.Background)

		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(1, -20, 0, 60)
		icon.Position = UDim2.new(0.5, 0, 0.1, 0)
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Font = FONTS.Icon
		icon.TextSize = 36
		icon.TextColor3 = PALETTE.TextPrimary
		icon.BackgroundTransparency = 1
		icon.Text = boosterInfo.Icon
		icon.Parent = card

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, -10, 0.25, 0)
		nameLabel.Position = UDim2.new(0.5, 0, 0.6, 0)
		nameLabel.AnchorPoint = Vector2.new(0.5, 0)
		nameLabel.Font = FONTS.Body
		nameLabel.TextSize = 16
		nameLabel.TextColor3 = PALETTE.TextSecondary
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextWrapped = true
		nameLabel.Text = boosterInfo.Name
		nameLabel.Parent = card

		local statusIndicator = Instance.new("Frame")
		statusIndicator.Name = "Status"
		statusIndicator.Size = UDim2.new(1, 0, 0.15, 0)
		statusIndicator.Position = UDim2.new(0, 0, 1, 0)
		statusIndicator.AnchorPoint = Vector2.new(0, 1)
		statusIndicator.BackgroundColor3 = PALETTE.Transparent
		statusIndicator.Parent = card
		addCorner(statusIndicator)

		local statusText = Instance.new("TextLabel")
		statusText.Name = "StatusText"
		statusText.Size = UDim2.new(1, 0, 1, 0)
		statusText.Font = FONTS.Button
		statusText.TextSize = 14
		statusText.TextColor3 = PALETTE.TextPrimary
		statusText.BackgroundTransparency = 1
		statusText.Parent = statusIndicator

		local owned = currentPlayerData.inventory[boosterId] and currentPlayerData.inventory[boosterId] > 0
		if owned then
			local isActive = currentPlayerData.activeBooster == boosterId
			statusIndicator.BackgroundColor3 = isActive and PALETTE.Success or PALETTE.Gold
			statusText.Text = isActive and "ACTIVE" or "OWNED"
		else
			statusIndicator.BackgroundColor3 = PALETTE.Secondary
			statusText.Text = boosterInfo.Price .. " COINS"
		end

		local cardButton = Instance.new("TextButton")
		cardButton.Name = "CardButton"
		cardButton.Size = UDim2.new(1,0,1,0)
		cardButton.BackgroundTransparency = 1
		cardButton.Text = ""
		cardButton.Parent = card
		cardButton.MouseButton1Click:Connect(function()
			updateDetailsPanel(boosterId)
		end)
	end
end

local function handlePurchase()
	if not selectedBoosterId then return end

	local boosterInfo = boosterConfigCache[selectedBoosterId]
	if not boosterInfo or currentPlayerData.coins < boosterInfo.Price then return end

	popupText.Text = "Are you sure you want to purchase '" .. boosterInfo.Name .. "' for " .. boosterInfo.Price .. " Coins?"
	confirmationPopup.Visible = true

	local conn1, conn2
	conn1 = confirmButton.MouseButton1Click:Connect(function()
		confirmationPopup.Visible = false
		conn1:Disconnect()
		conn2:Disconnect()

		local result = PurchaseBoosterFunction:InvokeServer(selectedBoosterId)
		if result.success then
			-- Manual update to reflect changes instantly
			currentPlayerData.coins = currentPlayerData.coins - boosterInfo.Price
			currentPlayerData.inventory[selectedBoosterId] = (currentPlayerData.inventory[selectedBoosterId] or 0) + 1
			coinsLabel.Text = "COINS: " .. currentPlayerData.coins
			populateShop()
			updateDetailsPanel(selectedBoosterId)
		end
	end)

	conn2 = cancelButton.MouseButton1Click:Connect(function()
		confirmationPopup.Visible = false
		conn1:Disconnect()
		conn2:Disconnect()
	end)
end

local function handleActivate()
	if not selectedBoosterId then return end

	local owned = currentPlayerData.inventory[selectedBoosterId] and currentPlayerData.inventory[selectedBoosterId] > 0
	if not owned then return end

	ActivateBoosterEvent:FireServer(selectedBoosterId)

	-- Instant visual feedback
	currentPlayerData.activeBooster = selectedBoosterId
	populateShop()
	updateDetailsPanel(selectedBoosterId)
end

actionButton.MouseButton1Click:Connect(function()
	local owned = currentPlayerData.inventory[selectedBoosterId] and currentPlayerData.inventory[selectedBoosterId] > 0
	if owned then
		handleActivate()
	else
		handlePurchase()
	end
end)

function toggleShop(visible, data)
	if visible then
		currentPlayerData = data
		if not currentPlayerData.inventory then
			currentPlayerData.inventory = {}
		end
		coinsLabel.Text = "COINS: " .. (data.coins or "N/A")
		populateShop()
		updateDetailsPanel(nil)
	end

	local targetPosition = visible and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0.5, 0, 1.5, 0)
	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(mainFrame, tweenInfo, {Position = targetPosition})

	if visible then mainFrame.Visible = true end
	tween:Play()

	if not visible then
		tween.Completed:Wait()
		mainFrame.Visible = false
	end
end

-- ==================================
-- ====== EVENT CONNECTIONS =========
-- ==================================
shopCloseButton.MouseButton1Click:Connect(function() toggleShop(false) end)

ToggleBoosterShopEvent.OnClientEvent:Connect(function(data)
	toggleShop(not mainFrame.Visible, data)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape and mainFrame.Visible then
		toggleShop(false)
	end
end)

-- ==================================
-- ======== INITIALIZATION ========
-- ==================================
local function initialize()
	boosterConfigCache = GetBoosterConfig:InvokeServer()
	print("BoosterShopUI Overhaul Loaded. Config cached.")
end

initialize()

