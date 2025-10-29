-- APShopUI.lua (LocalScript)
-- Path: StarterGui/APShopUI.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local WeaponModule = require(ReplicatedStorage:WaitForChild("ModuleScript"):WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ReplicatedStorage:WaitForChild("ModuleScript"):WaitForChild("ModelPreviewModule"))
local purchaseSkinFunc = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("PurchaseSkinWithAP")
local apChangedEvent = ReplicatedStorage:WaitForChild("AchievementPointsChanged")

local apShopUI = {}

-- Store UI elements and state
local mainFrame = nil
local apLabel = nil
local activePreview = nil
local previewViewport = nil
local previewNameLabel = nil
local zoomSlider = {}

-- Fungsi untuk membuat UI Toko AP
function apShopUI:Create()
	if player.PlayerGui:FindFirstChild("APShopGui") then
		mainFrame = player.PlayerGui.APShopGui.MainFrame
		-- In a real scenario, you'd re-link all variables here, but for this script, we assume it's created once.
		return
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "APShopGui"
	screenGui.Parent = player.PlayerGui

	-- Main window is now wider
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	mainFrame.Visible = false
	mainFrame.Parent = screenGui
	local uIListLayoutmainFrame = Instance.new("UIListLayout")
	uIListLayoutmainFrame.Padding = UDim.new(0.01, 0)
	uIListLayoutmainFrame.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayoutmainFrame.Parent = mainFrame
	local uIPaddingMainFrame = Instance.new("UIPadding")
	uIPaddingMainFrame.PaddingTop = UDim.new(0.01, 0)
	uIPaddingMainFrame.PaddingLeft = UDim.new(0.01, 0)
	uIPaddingMainFrame.PaddingBottom = UDim.new(0.01, 0)
	uIPaddingMainFrame.PaddingRight = UDim.new(0.01, 0)
	uIPaddingMainFrame.Parent = mainFrame

	-- Modernisasi: Sudut membulat dan garis tepi
	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 8)
	mainCorner.Parent = mainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = Color3.fromRGB(255, 200, 80)
	mainStroke.Thickness = 2
	mainStroke.Parent = mainFrame
	
	-- Title bar remains mostly the same
	local titleFrame = Instance.new("Frame")
	titleFrame.Name = "Title"
	titleFrame.Size = UDim2.new(1, 0, 0.1, 0)
	titleFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	titleFrame.BorderSizePixel = 0
	titleFrame.Parent = mainFrame

	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(85, 85, 85)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 45))
	})
	titleGradient.Rotation = 90
	titleGradient.Parent = titleFrame
	
	local mainFrameChild = Instance.new("Frame")
	mainFrameChild.Name = "Childframe"
	mainFrameChild.Position = UDim2.new(0, 0, 0.1, 0)
	mainFrameChild.Size = UDim2.new(1, 0, 0.89, 0)
	mainFrameChild.Transparency = 1
	mainFrameChild.Parent = mainFrame
	local uIListLayoutMainFrameChild = Instance.new("UIListLayout")
	uIListLayoutMainFrameChild.Padding = UDim.new(0.001, 0)
	uIListLayoutMainFrameChild.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayoutMainFrameChild.FillDirection = Enum.FillDirection.Horizontal
	uIListLayoutMainFrameChild.Parent = mainFrameChild

	-- Title text and AP Label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(0.4, 0, 0.8, 0)
	titleLabel.Position = UDim2.new(0.3, 0, 0.1, 0)
	titleLabel.Text = "Toko Achievement"
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextSize = 28
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Thickness = 1.5
	titleStroke.Parent = titleLabel
	titleLabel.Parent = titleFrame

	apLabel = Instance.new("TextLabel")
	apLabel.Name = "APLabel"
	apLabel.Size = UDim2.new(0.3, 0, 0.8, 0)
	apLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
	apLabel.Font = Enum.Font.GothamBold
	apLabel.TextSize = 22
	apLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
	apLabel.TextXAlignment = Enum.TextXAlignment.Left
	apLabel.BackgroundTransparency = 1
	apLabel.Parent = titleFrame

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0.039, 0, 0.65, 0)
	closeButton.Position = UDim2.new(0.955, 0, 0.175, 0)
	closeButton.Text = "X"
	closeButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.BorderSizePixel = 0
	closeButton.Parent = titleFrame

	local closeButtonCorner = Instance.new("UICorner")
	closeButtonCorner.CornerRadius = UDim.new(0, 6)
	closeButtonCorner.Parent = closeButton

	local closeButtonGradient = Instance.new("UIGradient")
	closeButtonGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 80, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 50))
	})
	closeButtonGradient.Rotation = 90
	closeButtonGradient.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		apShopUI:Hide()
	end)

	-- Left Panel for item list
	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = "DescScrollingFrame"
	scrollingFrame.Size = UDim2.new(0.5, 0, 1, 0)
	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollingFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	scrollingFrame.BorderSizePixel = 0
	scrollingFrame.ScrollBarThickness = 7
	scrollingFrame.Parent = mainFrameChild

	local scrollingFrameCorner = Instance.new("UICorner")
	scrollingFrameCorner.CornerRadius = UDim.new(0, 6)
	scrollingFrameCorner.Parent = scrollingFrame

	-- Right Panel for preview
	local previewPanel = Instance.new("Frame")
	previewPanel.Name = "PreviewPanel"
	previewPanel.Size = UDim2.new(0.5, 0, 1, 0)
	previewPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	previewPanel.BorderSizePixel = 0
	previewPanel.Parent = mainFrameChild

	local previewPanelCorner = Instance.new("UICorner")
	previewPanelCorner.CornerRadius = UDim.new(0, 6)
	previewPanelCorner.Parent = previewPanel

	previewNameLabel = Instance.new("TextLabel")
	previewNameLabel.Name = "PreviewNameLabel"
	previewNameLabel.Size = UDim2.new(1, -10, 0, 30)
	previewNameLabel.Position = UDim2.new(0, 5, 0, 5)
	previewNameLabel.Font = Enum.Font.SourceSansBold
	previewNameLabel.TextSize = 18
	previewNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	previewNameLabel.Text = "Pilih item untuk pratinjau"
	previewNameLabel.Parent = previewPanel

	previewViewport = Instance.new("ViewportFrame")
	previewViewport.Name = "PreviewViewport"
	previewViewport.Size = UDim2.new(1, -10, 1, -80)
	previewViewport.Position = UDim2.new(0, 5, 0, 40)
	previewViewport.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	previewViewport.Ambient = Color3.new(0.5, 0.5, 0.5)
	previewViewport.LightColor = Color3.new(0.8, 0.8, 0.8)
	previewViewport.LightDirection = Vector3.new(-1, -1, -1)
	previewViewport.Parent = previewPanel

	local previewViewportCorner = Instance.new("UICorner")
	previewViewportCorner.CornerRadius = UDim.new(0, 6)
	previewViewportCorner.Parent = previewViewport

	-- Zoom Slider elements
	local sliderTrack = Instance.new("Frame")
	sliderTrack.Name = "ZoomSliderTrack"
	sliderTrack.Size = UDim2.new(1, -20, 0, 10)
	sliderTrack.Position = UDim2.new(0, 10, 1, -30)
	sliderTrack.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	sliderTrack.Parent = previewPanel
	zoomSlider.Track = sliderTrack

	local sliderTrackCorner = Instance.new("UICorner")
	sliderTrackCorner.CornerRadius = UDim.new(0, 5)
	sliderTrackCorner.Parent = sliderTrack

	local sliderFill = Instance.new("Frame")
	sliderFill.Name = "ZoomSliderFill"
	sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderTrack
	zoomSlider.Fill = sliderFill

	local sliderHandle = Instance.new("TextButton")
	sliderHandle.Name = "ZoomSliderHandle"
	sliderHandle.Text = ""
	sliderHandle.Size = UDim2.new(0, 20, 0, 20)
	sliderHandle.Position = UDim2.new(0.5, 0, 0.5, 0)
	sliderHandle.AnchorPoint = Vector2.new(0.5, 0.5)
	sliderHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sliderHandle.ZIndex = 2
	sliderHandle.Parent = sliderTrack
	zoomSlider.Handle = sliderHandle

	local sliderHandleCorner = Instance.new("UICorner")
	sliderHandleCorner.CornerRadius = UDim.new(0, 10)
	sliderHandleCorner.Parent = sliderHandle

	-- Populate the item list
	self:PopulateShop(scrollingFrame)
end

-- This function will be expanded in the next step. For now, it's the same.
-- Fungsi untuk mengisi daftar skin di toko dan menghubungkan pratinjau
function apShopUI:PopulateShop(scrollingFrame)
	local yOffset = 5
	for weaponName, weaponData in pairs(WeaponModule.Weapons) do
		for skinName, skinData in pairs(weaponData.Skins) do
			if skinData.APCost and skinData.APCost > 0 then
				local itemFrame = Instance.new("TextButton") -- Changed to TextButton for click detection
				itemFrame.Name = skinName
				itemFrame.Size = UDim2.new(1, -10, 0, 70)
				itemFrame.Position = UDim2.new(0, 5, 0, yOffset)
				itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				itemFrame.Text = ""
				itemFrame.AutoButtonColor = false
				itemFrame.Parent = scrollingFrame

				local itemFrameCorner = Instance.new("UICorner")
				itemFrameCorner.CornerRadius = UDim.new(0, 6)
				itemFrameCorner.Parent = itemFrame

				local itemStroke = Instance.new("UIStroke")
				itemStroke.Thickness = 1
				itemStroke.Color = Color3.fromRGB(70, 70, 70)
				itemStroke.Parent = itemFrame

				-- Hover effect
				itemFrame.MouseEnter:Connect(function()
					itemFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
					itemStroke.Color = Color3.fromRGB(255, 200, 80)
				end)

				itemFrame.MouseLeave:Connect(function()
					itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
					itemStroke.Color = Color3.fromRGB(70, 70, 70)
				end)

				local skinLabel = Instance.new("TextLabel")
				skinLabel.Size = UDim2.new(0.65, 0, 0.4, 0)
				skinLabel.Position = UDim2.new(0.04, 0, 0.15, 0)
				skinLabel.Text = skinName
				skinLabel.Font = Enum.Font.GothamBold
				skinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				skinLabel.TextXAlignment = Enum.TextXAlignment.Left
				skinLabel.TextSize = 18
				skinLabel.BackgroundTransparency = 1
				skinLabel.Parent = itemFrame

				local weaponTypeLabel = Instance.new("TextLabel")
				weaponTypeLabel.Size = UDim2.new(0.65, 0, 0.3, 0)
				weaponTypeLabel.Position = UDim2.new(0.04, 0, 0.55, 0)
				weaponTypeLabel.Text = weaponName
				weaponTypeLabel.Font = Enum.Font.SourceSans
				weaponTypeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
				weaponTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
				weaponTypeLabel.TextSize = 14
				weaponTypeLabel.BackgroundTransparency = 1
				weaponTypeLabel.Parent = itemFrame

				local priceLabel = Instance.new("TextLabel")
				priceLabel.Size = UDim2.new(0.3, 0, 0.8, 0)
				priceLabel.Position = UDim2.new(0.35, 0, 0.1, 0)
				priceLabel.Text = tostring(skinData.APCost) .. " AP"
				priceLabel.Font = Enum.Font.GothamBold
				priceLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
				priceLabel.TextXAlignment = Enum.TextXAlignment.Right
				priceLabel.TextSize = 18
				priceLabel.BackgroundTransparency = 1
				priceLabel.Parent = itemFrame

				local buyButton = Instance.new("TextButton")
				buyButton.Name = "BuyButton"
				buyButton.Size = UDim2.new(0.251, 0, 0.8, 0)
				buyButton.Position = UDim2.new(0.725, 0, 0.1, 0)
				buyButton.Text = "Beli"
				buyButton.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
				buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
				buyButton.Font = Enum.Font.SourceSansBold
				buyButton.TextYAlignment = Enum.TextYAlignment.Center
				buyButton.TextXAlignment = Enum.TextXAlignment.Center
				buyButton.BorderSizePixel = 0
				buyButton.Parent = itemFrame

				local buyButtonCorner = Instance.new("UICorner")
				buyButtonCorner.CornerRadius = UDim.new(0, 6)
				buyButtonCorner.Parent = buyButton

				local buyButtonGradient = Instance.new("UIGradient")
				buyButtonGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 180, 100)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 160, 80))
				})
				buyButtonGradient.Rotation = 90
				buyButtonGradient.Parent = buyButton

				buyButton.MouseButton1Click:Connect(function()
					local result = purchaseSkinFunc:InvokeServer(weaponName, skinName)
					if result.Success then
						buyButton.Text = "Dimiliki"
						buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
						buyButton.Enabled = false
					else
						local originalText = buyButton.Text
						buyButton.Text = result.Reason or "Gagal"
						task.wait(2)
						buyButton.Text = originalText
					end
				end)

				-- Handle preview on item click
				itemFrame.MouseButton1Click:Connect(function()
					-- Destroy the old preview if it exists
					if activePreview then
						ModelPreviewModule.destroy(activePreview)
					end

					-- Create the new preview
					activePreview = ModelPreviewModule.create(previewViewport, weaponData, skinData)
					ModelPreviewModule.startRotation(activePreview, 5) -- Start with a default zoom of 5
					ModelPreviewModule.connectZoomSlider(activePreview, zoomSlider.Track, zoomSlider.Handle, zoomSlider.Fill, 2, 10)

					-- Update the name label
					previewNameLabel.Text = string.format("%s - %s", weaponName, skinName)
				end)

				yOffset = yOffset + 75
			end
		end
	end
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
end

-- Fungsi untuk menampilkan UI
function apShopUI:Show()
	if not mainFrame then self:Create() end
	mainFrame.Visible = true
	self:UpdateAP()
end

-- Fungsi untuk menyembunyikan UI
function apShopUI:Hide()
	if mainFrame then
		mainFrame.Visible = false
		-- Destroy active preview when closing the shop
		if activePreview then
			ModelPreviewModule.destroy(activePreview)
			activePreview = nil
			previewNameLabel.Text = "Pilih item untuk pratinjau"
		end
	end
end

-- Fungsi untuk memperbarui tampilan AP
function apShopUI:UpdateAP()
	if apLabel then
		local getInitialAPFunc = ReplicatedStorage:WaitForChild("GetInitialAchievementPoints")
		local currentAP = getInitialAPFunc:InvokeServer()
		apLabel.Text = "AP: " .. tostring(currentAP)
	end
end

-- Event listener untuk perubahan AP
apChangedEvent.OnClientEvent:Connect(function(newAP)
	if apLabel then
		apLabel.Text = "AP: " .. tostring(newAP)
	end
end)

-- Inisialisasi UI saat skrip dimulai
apShopUI:Create()

-- Logika Aktivator yang digabungkan
task.spawn(function()
	local Workspace = game:GetService("Workspace")
	local shopPart = Workspace.Shop:WaitForChild("APShop")
	if not shopPart then
		warn("APShop part not found in Workspace.")
		return
	end

	local proximityPrompt = shopPart:WaitForChild("ProximityPrompt")
	if not proximityPrompt then
		warn("ProximityPrompt not found in APShop part.")
		return
	end

	proximityPrompt.Triggered:Connect(function(promptedPlayer)
		if promptedPlayer == player then
			print("APShop prompt triggered by local player.")
			apShopUI:Show()
		end
	end)

	print("APShopUI script loaded and prompt listener connected.")
end)

return apShopUI
