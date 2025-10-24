-- BoosterShopUI.lua (LocalScript)
-- Path: StarterGui/BoosterShopUI.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==================================
-- ======== SERVICE SETUP ===========
-- ==================================
local ToggleBoosterShopEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ToggleBoosterShopEvent")
local PurchaseBoosterFunction = ReplicatedStorage.RemoteFunctions:WaitForChild("PurchaseBoosterFunction")
local GetBoosterConfig = ReplicatedStorage.RemoteFunctions:WaitForChild("GetBoosterConfig")

-- ==================================
-- ======== UI SETUP ================
-- ==================================
local PALETTE = {
	Background = Color3.fromRGB(28, 28, 32),
	Primary = Color3.fromRGB(38, 38, 44),
	Secondary = Color3.fromRGB(48, 48, 56),
	Accent = Color3.fromRGB(88, 101, 242),
	Success = Color3.fromRGB(87, 242, 135),
	Failure = Color3.fromRGB(237, 66, 69),
	TextPrimary = Color3.fromRGB(242, 242, 242),
	TextSecondary = Color3.fromRGB(181, 181, 181),
	Gold = Color3.fromRGB(255, 215, 0)
}

local FONTS = {
	Title = Enum.Font.GothamMedium,
	Body = Enum.Font.Gotham,
	Button = Enum.Font.GothamBold,
	Icon = Enum.Font.GothamBold
}

local screenGui = playerGui:FindFirstChild("BoosterSystemUI") or Instance.new("ScreenGui")
screenGui.Name = "BoosterSystemUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

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

-- --------------------------
-- --- BOOSTER SHOP UI ------
-- --------------------------
local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
shopFrame.Size = UDim2.new(0.5, 0, 0.95, 0) -- Increased height
shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
shopFrame.BackgroundColor3 = PALETTE.Primary
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.Parent = screenGui
addCorner(shopFrame, 12)
addStroke(shopFrame, PALETTE.Background, 2)

local UIListLayoutShopFrame = Instance.new("UIListLayout")
UIListLayoutShopFrame.Padding = UDim.new(0.01, 0)
UIListLayoutShopFrame.HorizontalFlex = 1
UIListLayoutShopFrame.VerticalFlex = 1
UIListLayoutShopFrame.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayoutShopFrame.Parent = shopFrame

local shopTitle = Instance.new("TextLabel")
shopTitle.Name = "Title"
shopTitle.Size = UDim2.new(1, 0, 0, 50)
shopTitle.Text = "BOOSTER SHOP"
shopTitle.Font = FONTS.Title
shopTitle.TextSize = 22
shopTitle.TextColor3 = PALETTE.TextPrimary
shopTitle.BackgroundColor3 = PALETTE.Secondary
shopTitle.Parent = shopFrame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = shopTitle
local titleClip = Instance.new("UICorner")
titleClip.Parent = titleCorner

local shopCloseButton = Instance.new("TextButton")
shopCloseButton.Name = "CloseButton"
shopCloseButton.Size = UDim2.new(0, 32, 0, 32)
shopCloseButton.Position = UDim2.new(1, -42, 0.5, -16)
shopCloseButton.Text = "X"
shopCloseButton.Font = FONTS.Button
shopCloseButton.TextSize = 18
shopCloseButton.TextColor3 = PALETTE.TextPrimary
shopCloseButton.BackgroundColor3 = PALETTE.Failure
shopCloseButton.BorderSizePixel = 0
shopCloseButton.Parent = shopTitle
addCorner(shopCloseButton, 8)

local shopScrollingFrame = Instance.new("ScrollingFrame")
shopScrollingFrame.Name = "ItemContainer"
shopScrollingFrame.Size = UDim2.new(1, -20, 1, -60)
shopScrollingFrame.Position = UDim2.new(0.5, -shopScrollingFrame.Size.X.Offset/2, 0, 55)
shopScrollingFrame.BackgroundColor3 = PALETTE.Primary
shopScrollingFrame.BorderSizePixel = 0
shopScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
shopScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopScrollingFrame.ScrollBarImageColor3 = PALETTE.Accent
shopScrollingFrame.ScrollBarThickness = 6
shopScrollingFrame.Parent = shopFrame
local titleCorner2 = Instance.new("UICorner")
titleCorner2.CornerRadius = UDim.new(0, 12)
titleCorner2.Parent = shopScrollingFrame

local shopListLayout = Instance.new("UIListLayout")
shopListLayout.Padding = UDim.new(0, 10)
shopListLayout.FillDirection = Enum.FillDirection.Vertical
shopListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
shopListLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopListLayout.Parent = shopScrollingFrame

-- ==================================
-- ====== UI LOGIC ==================
-- ==================================
local function populateShop()
	for _, child in ipairs(shopScrollingFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local success, boosterConfig = pcall(function() return GetBoosterConfig:InvokeServer() end)
	if not success or not boosterConfig then
		warn("Could not get booster config: " .. tostring(boosterConfig))
		return
	end

	for boosterId, boosterInfo in pairs(boosterConfig) do
		local itemFrame = Instance.new("Frame")
		itemFrame.Name = boosterId
		itemFrame.Size = UDim2.new(1, -10, 0, 120) -- Increased height for new layout
		itemFrame.BackgroundColor3 = PALETTE.Secondary
		itemFrame.BorderSizePixel = 0
		itemFrame.LayoutOrder = boosterInfo.Price
		itemFrame.Parent = shopScrollingFrame
		addCorner(itemFrame, 8)
		addStroke(itemFrame, PALETTE.Background, 2)

		local iconFrame = Instance.new("Frame")
		iconFrame.Name = "IconFrame"
		iconFrame.Size = UDim2.new(0, 60, 0, 60)
		iconFrame.Position = UDim2.new(0, 15, 0.5, -30)
		iconFrame.BackgroundColor3 = PALETTE.Primary
		iconFrame.Parent = itemFrame
		addCorner(iconFrame, 8)

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "IconLabel"
		iconLabel.Size = UDim2.new(1, 0, 1, 0)
		iconLabel.Font = FONTS.Icon
		iconLabel.TextSize = 24
		iconLabel.TextColor3 = PALETTE.TextPrimary
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = boosterInfo.Icon or "?"
		iconLabel.Parent = iconFrame

		local infoFrame = Instance.new("Frame")
		infoFrame.Name = "InfoFrame"
		infoFrame.Size = UDim2.new(1, -210, 1, -20)
		infoFrame.Position = UDim2.new(0, 90, 0, 10)
		infoFrame.BackgroundTransparency = 1
		infoFrame.Parent = itemFrame

		local infoListLayout = Instance.new("UIListLayout")
		infoListLayout.Padding = UDim.new(0, 4)
		infoListLayout.FillDirection = Enum.FillDirection.Vertical
		infoListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		infoListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		infoListLayout.Parent = infoFrame

		local itemName = Instance.new("TextLabel")
		itemName.Name = "ItemName"
		itemName.Size = UDim2.new(1, 0, 0, 22)
		itemName.Font = FONTS.Title
		itemName.TextSize = 18
		itemName.TextColor3 = PALETTE.TextPrimary
		itemName.TextXAlignment = Enum.TextXAlignment.Left
		itemName.BackgroundTransparency = 1
		itemName.Text = boosterInfo.Name
		itemName.LayoutOrder = 1
		itemName.Parent = infoFrame

		local itemDesc = Instance.new("TextLabel")
		itemDesc.Name = "ItemDesc"
		itemDesc.Size = UDim2.new(1, 0, 0, 42)
		itemDesc.Font = FONTS.Body
		itemDesc.TextSize = 14
		itemDesc.TextColor3 = PALETTE.TextSecondary
		itemDesc.TextXAlignment = Enum.TextXAlignment.Left
		itemDesc.TextYAlignment = Enum.TextYAlignment.Center
		itemDesc.TextWrapped = true
		itemDesc.BackgroundTransparency = 1
		itemDesc.Text = boosterInfo.Description
		itemDesc.LayoutOrder = 2
		itemDesc.Parent = infoFrame

		local itemPrice = Instance.new("TextLabel")
		itemPrice.Name = "ItemPrice"
		itemPrice.Size = UDim2.new(1, 0, 0, 18)
		itemPrice.Font = FONTS.Body
		itemPrice.TextSize = 15
		itemPrice.TextColor3 = PALETTE.Gold
		itemPrice.TextXAlignment = Enum.TextXAlignment.Left
		itemPrice.BackgroundTransparency = 1
		itemPrice.Text = "Cost: " .. tostring(boosterInfo.Price)
		itemPrice.LayoutOrder = 3
		itemPrice.Parent = infoFrame

		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Size = UDim2.new(0, 100, 0, 40)
		buyButton.Position = UDim2.new(1, -110, 0.5, -20)
		buyButton.Font = FONTS.Button
		buyButton.TextSize = 16
		buyButton.TextColor3 = PALETTE.TextPrimary
		buyButton.BackgroundColor3 = PALETTE.Accent
		buyButton.BorderSizePixel = 0
		buyButton.Text = "BUY"
		buyButton.Parent = itemFrame
		addCorner(buyButton, 8)

		buyButton.MouseButton1Click:Connect(function()
			if not buyButton.AutoButtonColor then return end
			buyButton.AutoButtonColor = false
			buyButton.Text = "..."
			local result = PurchaseBoosterFunction:InvokeServer(boosterId)
			if result.success then
				buyButton.BackgroundColor3 = PALETTE.Success
				buyButton.Text = "DONE"
			else
				buyButton.BackgroundColor3 = PALETTE.Failure
				buyButton.Text = "FAIL"
			end
			task.wait(1.5)
			buyButton.AutoButtonColor = true
			buyButton.Text = "BUY"
			buyButton.BackgroundColor3 = PALETTE.Accent
		end)
	end
end

function toggleShop(visible)
	if visible and not shopFrame.Visible then populateShop() end
	shopFrame.Visible = visible
end

-- ==================================
-- ====== EVENT CONNECTIONS =========
-- ==================================
shopCloseButton.MouseButton1Click:Connect(function() toggleShop(false) end)
ToggleBoosterShopEvent.OnClientEvent:Connect(function() toggleShop(not shopFrame.Visible) end)

print("Modern BoosterShopUI.lua loaded.")
