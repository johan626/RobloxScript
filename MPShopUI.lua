-- MPShopUI.lua (LocalScript)
-- Path: StarterGui/MPShopUI.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hapus UI lama jika ada
if playerGui:FindFirstChild("MPShopUI") then
	playerGui.MPShopUI:Destroy()
end

-- ======================================================
-- PEMBUATAN UI
-- ======================================================

-- ScreenGui Utama
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MPShopUI"
screenGui.Enabled = true
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Frame Utama
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.6, 0, 0.9, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 48, 59)
mainFrame.Visible = false
mainFrame.Parent = screenGui
local frameCorner = Instance.new("UICorner", mainFrame)
frameCorner.CornerRadius = UDim.new(0.03, 0)

local uIListLayoutMainFrame = Instance.new("UIListLayout")
uIListLayoutMainFrame.Padding = UDim.new(0.01, 0)
uIListLayoutMainFrame.SortOrder = Enum.SortOrder.LayoutOrder
uIListLayoutMainFrame.Parent = mainFrame
local uIPaddingMainFrame = Instance.new("UIPadding")
uIPaddingMainFrame.PaddingTop = UDim.new(0.01, 0)
uIPaddingMainFrame.PaddingLeft = UDim.new(0.01, 0)
uIPaddingMainFrame.PaddingBottom = UDim.new(0.01, 0)
uIPaddingMainFrame.PaddingRight = UDim.new(0.01, 0)
uIPaddingMainFrame.Parent = mainFrame

-- Header
local titleText = Instance.new("TextLabel")
titleText.Name = "Title"
titleText.Size = UDim2.new(1, 0, 0.1, 0)
titleText.Text = "Toko Mission Points"
titleText.Font = Enum.Font.SourceSansBold
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 24
titleText.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
titleText.Parent = mainFrame
local titleCorner = Instance.new("UICorner", titleText)
titleCorner.CornerRadius = UDim.new(0, 12)

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -10, 0.5, 0)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 20
closeButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Parent = titleText
local closeCorner = Instance.new("UICorner", closeButton)
closeCorner.CornerRadius = UDim.new(0, 8)

-- Kontainer Item
local itemContainer = Instance.new("ScrollingFrame")
itemContainer.Name = "ItemContainer"
itemContainer.Size = UDim2.new(1, 0, 0.89, 0)
itemContainer.Position = UDim2.new(0.5, 0, 0.55, 0)
itemContainer.AnchorPoint = Vector2.new(0, 0)
itemContainer.BackgroundTransparency = 1
itemContainer.BorderSizePixel = 0
itemContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
itemContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
itemContainer.ScrollBarThickness = 7
itemContainer.Parent = mainFrame
local itemListLayout = Instance.new("UIGridLayout", itemContainer)
itemListLayout.CellPadding = UDim2.new(0.01, 0, 0.01, 0)
itemListLayout.CellSize = UDim2.new(0.485, 0, 0.7, 0)
itemListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Template Item
local itemTemplate = Instance.new("Frame")
itemTemplate.Name = "ItemTemplate"
itemTemplate.Visible = false
itemTemplate.Size = UDim2.new(1, 0, 1, 0)
itemTemplate.BackgroundColor3 = Color3.fromRGB(60, 64, 78)
itemTemplate.Parent = itemContainer
local uIListLayoutitemTemplate = Instance.new("UIListLayout")
uIListLayoutitemTemplate.Padding = UDim.new(0.01, 0)
uIListLayoutitemTemplate.SortOrder = Enum.SortOrder.LayoutOrder
uIListLayoutitemTemplate.HorizontalAlignment = Enum.HorizontalAlignment.Center
uIListLayoutitemTemplate.VerticalAlignment = Enum.VerticalAlignment.Center
uIListLayoutitemTemplate.Parent = itemTemplate

local templateCorner = Instance.new("UICorner", itemTemplate)
templateCorner.CornerRadius = UDim.new(0, 8)

local itemViewport = Instance.new("ViewportFrame", itemTemplate)
itemViewport.Name = "ItemViewport"
itemViewport.Size = UDim2.new(0.9, 0, 0.5, 0)
itemViewport.Position = UDim2.new(0.5, 0, 0.3, 0)
itemViewport.AnchorPoint = Vector2.new(0.5, 0.5)
itemViewport.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
local vpCorner = Instance.new("UICorner", itemViewport)
vpCorner.CornerRadius = UDim.new(0, 8)

local itemName = Instance.new("TextLabel", itemTemplate)
itemName.Name = "ItemName"
itemName.Size = UDim2.new(0.9, 0, 0.15, 0)
itemName.Position = UDim2.new(0.5, 0, 0.6, 0)
itemName.AnchorPoint = Vector2.new(0.5, 0)
itemName.Font = Enum.Font.SourceSansBold
itemName.TextColor3 = Color3.fromRGB(255, 255, 255)
itemName.TextSize = 18
itemName.BackgroundTransparency = 1

local itemPrice = Instance.new("TextLabel", itemTemplate)
itemPrice.Name = "ItemPrice"
itemPrice.Size = UDim2.new(0.9, 0, 0.1, 0)
itemPrice.Position = UDim2.new(0.5, 0, 0.75, 0)
itemPrice.AnchorPoint = Vector2.new(0.5, 0)
itemPrice.Font = Enum.Font.SourceSans
itemPrice.TextColor3 = Color3.fromRGB(255, 193, 7) -- Gold
itemPrice.TextSize = 16
itemPrice.BackgroundTransparency = 1

local buyButton = Instance.new("TextButton", itemTemplate)
buyButton.Name = "BuyButton"
buyButton.Size = UDim2.new(0.8, 0, 0.15, 0)
buyButton.Position = UDim2.new(0.5, 0, 0.9, 0)
buyButton.AnchorPoint = Vector2.new(0.5, 0.5)
buyButton.Font = Enum.Font.SourceSansBold
buyButton.Text = "Beli"
buyButton.TextSize = 18
buyButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Green
buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
local buyCorner = Instance.new("UICorner", buyButton)
buyCorner.CornerRadius = UDim.new(0, 8)

-- ======================================================
-- LOGIKA UI
-- ======================================================

local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ReplicatedStorage.ModuleScript:WaitForChild("ModelPreviewModule"))
local PurchaseSkinFunc = ReplicatedStorage.RemoteFunctions:WaitForChild("PurchaseSkin")

local itemPreviews = {}

local function clearPreviews()
	for _, preview in pairs(itemPreviews) do
		ModelPreviewModule.destroy(preview)
	end
	table.clear(itemPreviews)
end

local function populateShop()
	-- Hapus item lama
	for _, child in ipairs(itemContainer:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "ItemTemplate" then
			child:Destroy()
		end
	end
	clearPreviews()

	-- Buat item untuk setiap skin yang dijual
	for weaponName, weaponData in pairs(WeaponModule.Weapons) do
		for skinName, skinData in pairs(weaponData.Skins) do
			if skinData.MPCost and skinData.MPCost > 0 then
				local frame = itemTemplate:Clone()
				frame.Name = weaponName .. "_" .. skinName
				frame.ItemName.Text = skinName
				frame.ItemPrice.Text = tostring(skinData.MPCost) .. " MP"
				frame.Visible = true
				frame.Parent = itemContainer

				-- Buat preview model
				local preview = ModelPreviewModule.create(frame.ItemViewport, weaponData, skinData)
				ModelPreviewModule.startRotation(preview, 5)
				itemPreviews[frame] = preview

				-- Hubungkan tombol beli
				frame.BuyButton.MouseButton1Click:Connect(function()
					frame.BuyButton.Text = "..."
					frame.BuyButton.Interactable = false

					local success, result = pcall(function()
						return PurchaseSkinFunc:InvokeServer(weaponName, skinName)
					end)

					if success then
						if result.Success then
							StarterGui:SetCore("SendNotification", { Title = "Berhasil!", Text = "Anda telah membeli skin " .. skinName .. ".", Duration = 5 })
							frame.BuyButton.Text = "Dimiliki"
							frame.BuyButton.BackgroundColor3 = Color3.fromRGB(80, 84, 98)
						else
							StarterGui:SetCore("SendNotification", { Title = "Gagal", Text = result.Reason, Duration = 5 })
							frame.BuyButton.Text = "Beli"
							frame.BuyButton.Interactable = true
						end
					else
						StarterGui:SetCore("SendNotification", { Title = "Error", Text = "Terjadi kesalahan saat menghubungi server.", Duration = 5 })
						frame.BuyButton.Text = "Beli"
						frame.BuyButton.Interactable = true
						warn("Error saat memanggil PurchaseSkinFunc: ", result)
					end
				end)
			end
		end
	end
end

local function openUI()
	screenGui.Enabled = true
	mainFrame.Visible = true
	populateShop()
end

local function closeUI()
	mainFrame.Visible = false
	screenGui.Enabled = false
	clearPreviews()
end

closeButton.MouseButton1Click:Connect(closeUI)

-- Koneksi ProximityPrompt
local shopPart = Workspace.Shop:WaitForChild("MPShop")
if shopPart then
	local prompt = shopPart:WaitForChild("ProximityPrompt")
	if prompt then
		prompt.Triggered:Connect(openUI)
	else
		warn("ProximityPrompt tidak ditemukan di dalam MPShop")
	end
else
	warn("Part MPShop tidak ditemukan di Workspace")
end

print("Skrip MPShopUI berhasil dimuat dan siap digunakan.")
