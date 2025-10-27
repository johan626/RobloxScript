-- RandomWeaponShopUI.lua (LocalScript)
-- Path: StarterGui/RandomWeaponShopUI.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions

local openReplaceUI = RemoteEvents:WaitForChild("OpenReplaceUI")
local replaceChoiceEv = RemoteEvents:WaitForChild("ReplaceChoice")

local purchaseRF = RemoteFunctions:WaitForChild("PurchaseRandomWeapon")

local randomPart = workspace:WaitForChild("Random", 5)
local isUIOpen = false
local wasBackpackEnabled = false

-- Modern UI Elements
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RandomWeaponShopUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Notification System
local notificationFrame = Instance.new("Frame")
notificationFrame.Size = UDim2.new(0, 350, 0, 70)
notificationFrame.Position = UDim2.new(0.5, -175, 0.2, 0)
notificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
notificationFrame.BackgroundTransparency = 0.9
notificationFrame.BorderSizePixel = 0
notificationFrame.Visible = false
notificationFrame.ZIndex = 10
notificationFrame.Parent = screenGui

-- Mobile adjustments for notification
if UserInputService.TouchEnabled then
	notificationFrame.Size = UDim2.new(0, 280, 0, 60)
	notificationFrame.Position = UDim2.new(0.5, -140, 0.2, 0)
end

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 12)
notifCorner.Parent = notificationFrame

local notifStroke = Instance.new("UIStroke")
notifStroke.Color = Color3.fromRGB(80, 80, 120)
notifStroke.Thickness = 2
notifStroke.Parent = notificationFrame

local notifLabel = Instance.new("TextLabel")
notifLabel.Size = UDim2.new(1, 0, 1, 0)
notifLabel.BackgroundTransparency = 1
notifLabel.Text = ""
notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notifLabel.TextScaled = true
notifLabel.Font = Enum.Font.GothamBold
notifLabel.ZIndex = 11
notifLabel.Parent = notificationFrame

-- NEW: Variables for replace UI
local replaceUIOverlay = nil
local replaceUIContainer = nil

-- NEW: Function to handle backpack UI visibility
local function setBackpackVisible(visible)
	if UserInputService.TouchEnabled then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, visible)
	end
end

-- NEW: Function to close replace UI
local function closeReplaceUI(wasCancelled)
	if wasCancelled then
		replaceChoiceEv:FireServer(-1)
	end

	-- NEW: Restore backpack UI when closing shop on mobile
	if UserInputService.TouchEnabled then
		setBackpackVisible(true)
	end

	if replaceUIOverlay then
		replaceUIOverlay:Destroy()
		replaceUIOverlay = nil
	end
	if replaceUIContainer then
		replaceUIContainer:Destroy()
		replaceUIContainer = nil
	end
	isUIOpen = false
	-- ===== Patch: Unbind kontrol keyboard ketika UI replace ditutup =====
	do
		local CAS = game:GetService("ContextActionService")
		local RW_ARROW_ACTION = "RandomReplace_Arrows"
		local RW_ENTER_ACTION = "RandomReplace_Enter"

		-- Bungkus closeReplaceUI lama supaya selalu unbind dulu
		local _oldCloseReplaceUI = closeReplaceUI
		closeReplaceUI = function(wasCancelled)
			-- Unbind aman (pakai pcall agar tidak error kalau belum pernah bind)
			pcall(function() CAS:UnbindAction(RW_ARROW_ACTION) end)
			pcall(function() CAS:UnbindAction(RW_ENTER_ACTION) end)
			_oldCloseReplaceUI(wasCancelled)
		end
	end
end

-- Helper function untuk menampilkan notifikasi
local function showNotification(message, color, duration)
	notifLabel.Text = message
	notifLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	notificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)

	notificationFrame.Visible = true

	-- Mobile adjustments
	if UserInputService.TouchEnabled then
		notificationFrame.Position = UDim2.new(0.5, -140, 0.15, 0)
	else
		notificationFrame.Position = UDim2.new(0.5, -175, 0.15, 0)
	end

	local tweenIn = TweenService:Create(notificationFrame, TweenInfo.new(0.3), {
		Position = UserInputService.TouchEnabled and UDim2.new(0.5, -140, 0.2, 0) or UDim2.new(0.5, -175, 0.2, 0)
	})
	tweenIn:Play()

	task.wait(duration or 3)

	local tweenOut = TweenService:Create(notificationFrame, TweenInfo.new(0.3), {
		Position = UserInputService.TouchEnabled and UDim2.new(0.5, -140, 0.15, 0) or UDim2.new(0.5, -175, 0.15, 0)
	})
	tweenOut:Play()

	task.wait(0.3)
	notificationFrame.Visible = false
end

-- Fungsi untuk membuat UI replace yang lebih menarik
local function showReplaceUI(currentNames, newName, cost, hasDiscount)
	-- NEW: Hide backpack UI when opening shop on mobile
	if UserInputService.TouchEnabled then
		setBackpackVisible(false)
	end

	-- Background overlay
	replaceUIOverlay = Instance.new("Frame")
	replaceUIOverlay.Size = UDim2.new(1, 0, 1, 0)
	replaceUIOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	replaceUIOverlay.BackgroundTransparency = 0.7
	replaceUIOverlay.BorderSizePixel = 0
	replaceUIOverlay.ZIndex = 5
	replaceUIOverlay.Parent = screenGui

	-- Main container - Mobile adjustments
	local containerWidth = UserInputService.TouchEnabled and 320 or 400
	local containerHeight = UserInputService.TouchEnabled and 300 or 350

	replaceUIContainer = Instance.new("Frame")
	replaceUIContainer.Size = UDim2.new(0, containerWidth, 0, containerHeight)
	replaceUIContainer.Position = UDim2.new(0.5, -containerWidth/2, 0.5, -containerHeight/2)
	replaceUIContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	replaceUIContainer.BorderSizePixel = 0
	replaceUIContainer.ZIndex = 6
	replaceUIContainer.Parent = screenGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 15)
	containerCorner.Parent = replaceUIContainer

	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color = Color3.fromRGB(80, 80, 120)
	containerStroke.Thickness = 3
	containerStroke.Parent = replaceUIContainer

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, UserInputService.TouchEnabled and 50 or 60)
	header.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	header.BorderSizePixel = 0
	header.ZIndex = 7
	header.Parent = replaceUIContainer

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 15)
	headerCorner.Parent = header

	local headerText = Instance.new("TextLabel")
	headerText.Size = UDim2.new(0.8, 0, 1, 0)
	headerText.Position = UDim2.new(0.1, 0, 0, 0)
	headerText.BackgroundTransparency = 1
	headerText.Text = "REPLACE WEAPON"
	headerText.TextColor3 = Color3.fromRGB(255, 215, 0)
	headerText.TextScaled = true
	headerText.Font = Enum.Font.GothamBlack
	headerText.ZIndex = 8
	headerText.Parent = header

	-- New weapon info
	local newWeaponFrame = Instance.new("Frame")
	newWeaponFrame.Size = UDim2.new(0.9, 0, 0, UserInputService.TouchEnabled and 60 or 70)
	newWeaponFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
	newWeaponFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	newWeaponFrame.BorderSizePixel = 0
	newWeaponFrame.ZIndex = 7
	newWeaponFrame.Parent = replaceUIContainer

	local newWeaponCorner = Instance.new("UICorner")
	newWeaponCorner.CornerRadius = UDim.new(0, 10)
	newWeaponCorner.Parent = newWeaponFrame

	local newWeaponIcon = Instance.new("TextLabel")
	newWeaponIcon.Size = UDim2.new(0, UserInputService.TouchEnabled and 40 or 50, 0, UserInputService.TouchEnabled and 40 or 50)
	newWeaponIcon.Position = UDim2.new(0.05, 0, 0.1, 0)
	newWeaponIcon.BackgroundTransparency = 1
	newWeaponIcon.Text = "🎯"
	newWeaponIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
	newWeaponIcon.TextScaled = true
	newWeaponIcon.ZIndex = 8
	newWeaponIcon.Parent = newWeaponFrame

	local newWeaponText = Instance.new("TextLabel")
	newWeaponText.Size = UDim2.new(0.7, 0, 0.6, 0)
	newWeaponText.Position = UDim2.new(0.2, 0, 0.2, 0)
	newWeaponText.BackgroundTransparency = 1
	newWeaponText.Text = "New: " .. newName
	newWeaponText.TextColor3 = Color3.fromRGB(255, 255, 255)
	newWeaponText.TextScaled = true
	newWeaponText.TextXAlignment = Enum.TextXAlignment.Left
	newWeaponText.Font = Enum.Font.GothamBold
	newWeaponText.ZIndex = 8
	newWeaponText.Parent = newWeaponFrame

	local newWeaponCost = Instance.new("TextLabel")
	newWeaponCost.Size = UDim2.new(0.7, 0, 0.4, 0)
	newWeaponCost.Position = UDim2.new(0.2, 0, 0.5, 0)
	newWeaponCost.BackgroundTransparency = 1
	newWeaponCost.Text = "Cost: " .. cost .. " BP"
	if hasDiscount then
		newWeaponCost.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		newWeaponCost.TextColor3 = Color3.fromRGB(255, 215, 0)
	end
	newWeaponCost.TextScaled = true
	newWeaponCost.TextXAlignment = Enum.TextXAlignment.Left
	newWeaponCost.Font = Enum.Font.Gotham
	newWeaponCost.ZIndex = 8
	newWeaponCost.Parent = newWeaponFrame

	-- Weapons frame (replaced scrolling frame with regular frame)
	local weaponsFrame = Instance.new("Frame")
	weaponsFrame.Size = UDim2.new(0.9, 0, 0, UserInputService.TouchEnabled and 100 or 120) -- fixed height for 2 weapons
	weaponsFrame.Position = UDim2.new(0.05, 0, 0.45, 0)
	weaponsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	weaponsFrame.BorderSizePixel = 0
	weaponsFrame.ZIndex = 7
	weaponsFrame.Parent = replaceUIContainer

	local weaponsCorner = Instance.new("UICorner")
	weaponsCorner.CornerRadius = UDim.new(0, 10)
	weaponsCorner.Parent = weaponsFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Parent = weaponsFrame

	-- Create weapon buttons
	for i, name in ipairs(currentNames) do
		local weaponBtn = Instance.new("TextButton")
		weaponBtn.Size = UDim2.new(0.95, 0, 0, UserInputService.TouchEnabled and 40 or 50)
		weaponBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		weaponBtn.Text = "Replace: " .. name
		weaponBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		weaponBtn.TextScaled = true
		weaponBtn.LayoutOrder = i
		weaponBtn.ZIndex = 8
		weaponBtn.Parent = weaponsFrame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = weaponBtn

		weaponBtn.MouseButton1Click:Connect(function()
			replaceChoiceEv:FireServer(i)
			closeReplaceUI()
		end)
	end

	-- ===== MODIFIED: Keyboard navigation (desktop) untuk semua pilihan termasuk CANCEL =====
	local CAS = game:GetService("ContextActionService")
	local UIS = game:GetService("UserInputService")
	local RW_ARROW_ACTION = "RandomReplace_Arrows"
	local RW_ENTER_ACTION = "RandomReplace_Enter"

	-- Kumpulkan semua tombol yang bisa dipilih
	local selectableButtons = {}
	for _, child in ipairs(weaponsFrame:GetChildren()) do
		if child:IsA("TextButton") then
			table.insert(selectableButtons, child)
		end
	end

	-- Cancel button
	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0.9, 0, 0, UserInputService.TouchEnabled and 35 or 40)
	cancelBtn.Position = UDim2.new(0.05, 0, 0.85, 0)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	cancelBtn.Text = "CANCEL"
	cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelBtn.TextScaled = true
	cancelBtn.ZIndex = 7
	cancelBtn.Parent = replaceUIContainer

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 10)
	cancelCorner.Parent = cancelBtn

	cancelBtn.MouseButton1Click:Connect(function()
		closeReplaceUI(true)
	end)

	-- Tambahkan cancel button ke daftar tombol yang bisa dipilih
	table.insert(selectableButtons, cancelBtn)

	-- State selection
	local selectedIndex = (#selectableButtons > 0) and 1 or 0

	-- Utility: beri highlight pada tombol terpilih
	local function setSelected(i)
		-- Reset semua tombol ke tampilan normal
		for index, btn in ipairs(selectableButtons) do
			btn.BackgroundColor3 = (btn == cancelBtn) and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(50, 50, 60)
			local s = btn:FindFirstChildOfClass("UIStroke")
			if s then s.Thickness = 0 end
		end

		selectedIndex = math.clamp(i, 1, #selectableButtons)
		local btn = selectableButtons[selectedIndex]
		if not btn then return end

		btn.BackgroundColor3 = (btn == cancelBtn) and Color3.fromRGB(200, 70, 70) or Color3.fromRGB(65, 65, 85)
		local stroke = btn:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
		stroke.Parent = btn
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(255, 215, 0)
	end

	-- Set selected button jika bukan perangkat touch
	if not UIS.TouchEnabled and #selectableButtons > 0 then
		setSelected(1)
	end

	-- Aksi: panah untuk navigasi
	local function handleArrows(actionName, inputState, inputObj)
		if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if #selectableButtons == 0 then return Enum.ContextActionResult.Pass end

		local cur = (selectedIndex > 0) and selectedIndex or 1
		if inputObj.KeyCode == Enum.KeyCode.Down then
			cur = math.clamp(cur + 1, 1, #selectableButtons)
		elseif inputObj.KeyCode == Enum.KeyCode.Up then
			cur = math.clamp(cur - 1, 1, #selectableButtons)
		else
			return Enum.ContextActionResult.Pass
		end
		setSelected(cur)
		return Enum.ContextActionResult.Sink
	end

	-- Aksi: Enter untuk konfirmasi pilihan
	local function handleEnter(actionName, inputState, inputObj)
		if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if inputObj.KeyCode ~= Enum.KeyCode.Return and inputObj.KeyCode ~= Enum.KeyCode.KeypadEnter then
			return Enum.ContextActionResult.Pass
		end
		if selectedIndex > 0 and selectableButtons[selectedIndex] then
			-- Jika yang dipilih adalah tombol cancel
			if selectableButtons[selectedIndex] == cancelBtn then
				closeReplaceUI(true)
			else
				-- Jika yang dipilih adalah tombol senjata
				replaceChoiceEv:FireServer(selectedIndex)
				closeReplaceUI(false)
			end
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end

	-- Bind saat UI terbuka (prioritas tinggi)
	if not UIS.TouchEnabled then
		CAS:BindActionAtPriority(RW_ARROW_ACTION, handleArrows, false, Enum.ContextActionPriority.High.Value,
			Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.W, Enum.KeyCode.S
		)
		CAS:BindActionAtPriority(RW_ENTER_ACTION, handleEnter, false, Enum.ContextActionPriority.High.Value,
			Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter
		)
	end

	-- Animation
	replaceUIContainer.Size = UDim2.new(0, 0, 0, 0)
	local tween = TweenService:Create(replaceUIContainer, TweenInfo.new(0.3), {
		Size = UDim2.new(0, containerWidth, 0, containerHeight),
		Position = UDim2.new(0.5, -containerWidth/2, 0.5, -containerHeight/2)
	})
	tween:Play()

	-- NEW: Set UI state to open
	isUIOpen = true
end

-- Server akan memanggil ini untuk membuka UI replace
openReplaceUI.OnClientEvent:Connect(function(currentNames, newName, cost, hasDiscount)
	-- NEW: Check if UI is already open
	if isUIOpen then
		return
	end
	showReplaceUI(currentNames, newName, cost, hasDiscount)
end)

-- Gunakan ProximityPrompt di Workspace.Random.Attachment.RandomPrompt
local randomPrompt = workspace.Random:WaitForChild("Attachment"):WaitForChild("RandomPrompt")

-- Fungsi untuk menangani pembelian senjata random
local function purchaseRandomWeapon()
	-- NEW: Check if UI is already open
	if isUIOpen then
		return
	end

	-- Panggil remote function untuk membeli
	local ok, result = pcall(function() return purchaseRF:InvokeServer() end)
	if not ok then
		showNotification("Purchase error", Color3.fromRGB(255, 100, 100), 2)
		return
	end

	-- Result adalah table dari server
	if type(result) == "table" then
		if result.success == true then
			showNotification("You got: " .. (result.weaponName or "Weapon"), Color3.fromRGB(100, 255, 100), 3)
		elseif result.success == false and result.message == "choose" then
			-- UI replace akan dibuka oleh server melalui event OpenReplaceUI
		else
			showNotification(result.message or "Purchase failed", Color3.fromRGB(255, 100, 100), 3)
		end
	end
end

-- Tangani ProximityPrompt
ProximityPromptService.PromptTriggered:Connect(function(prompt, plr)
	if prompt ~= randomPrompt or plr ~= player then return end

	purchaseRandomWeapon()
end)

-- Tutup UI jika pemain menjauh dari part
RunService.RenderStepped:Connect(function()
	if isUIOpen then
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and randomPart then
			local dist = (char.HumanoidRootPart.Position - randomPart.Position).Magnitude
			if dist > 8 then
				closeReplaceUI(true)
			end
		end
	end
end)
