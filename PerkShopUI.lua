-- PerkShopUI.lua (LocalScript)
-- Path: StarterGui/PerkShopUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local openEv = RemoteEvents:WaitForChild("OpenPerkShop")
local perkUpdateEv = RemoteEvents:WaitForChild("PerkUpdate")
local requestOpenEvent = RemoteEvents:WaitForChild("RequestOpenPerkShop")
local closeShopEvent = RemoteEvents:WaitForChild("ClosePerkShop")

local purchaseRF = RemoteFunctions:WaitForChild("PurchasePerk")

local perksPart = workspace:WaitForChild("Perks")
local perksPrompt = perksPart:WaitForChild("Attachment"):WaitForChild("PerksPrompt")
local isMobile = UserInputService.TouchEnabled
local originalCoreGuiStates = {}
local hasStoredCoreGuiStates = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PerkShopUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false

local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.BorderSizePixel = 0
overlay.ZIndex = 1
overlay.Parent = screenGui

-- Ukuran container utama untuk mobile
local mainContainer = Instance.new("Frame")
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainContainer.BorderSizePixel = 0
mainContainer.ZIndex = 2
mainContainer.Parent = screenGui

-- Responsive sizing untuk mobile
if isMobile then
	mainContainer.Size = UDim2.new(0.9, 0, 0.85, 0)
else
	mainContainer.Size = UDim2.new(0.8, 0, 0.7, 0)
end

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = mainContainer

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(80, 80, 100)
UIStroke.Thickness = 3
UIStroke.Parent = mainContainer

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.12, 0)
header.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
header.BorderSizePixel = 0
header.ZIndex = 3
header.Parent = mainContainer

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.7, 0, 1, 0)
title.Position = UDim2.new(0.15, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "PERK SHOP"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.TextScaled = true
title.Font = Enum.Font.GothamBlack
title.ZIndex = 4
title.Parent = header

local closeBtn = Instance.new("ImageButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(0.93, 0, 0.35, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Image = "rbxassetid://3926305904"
closeBtn.ImageRectOffset = Vector2.new(924, 724)
closeBtn.ImageRectSize = Vector2.new(36, 36)
closeBtn.ZIndex = 4
closeBtn.Parent = header

-- Perbesar close button untuk mobile
if isMobile then
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(0.92, 0, 0.3, 0)
end

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.95, 0, 0.8, 0)
scrollFrame.Position = UDim2.new(0.025, 0, 0.15, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = isMobile and 6 or 0
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.ZIndex = 3
scrollFrame.Parent = mainContainer

-- === Keyboard navigation (desktop) ===
local ContextActionService = game:GetService("ContextActionService")
local ARROW_ACTION = "PerkShop_Arrows"
local ENTER_ACTION = "PerkShop_Enter"

local perkButtons = {}      -- list Frame tombol perk, urut sesuai build
local selectedIndex = 0     -- 0 = belum ada

-- Fungsi untuk menyembunyikan CoreGui elements di mobile
local function hideCoreGuiOnMobile()
	if not isMobile then return end

	-- Simpan state asli CoreGui jika belum disimpan
	if not hasStoredCoreGuiStates then
		originalCoreGuiStates.Backpack = game.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
		originalCoreGuiStates.Health = game.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health)
		originalCoreGuiStates.PlayerList = game.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
		hasStoredCoreGuiStates = true
	end

	-- Sembunyikan CoreGui elements
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end

-- Fungsi untuk mengembalikan CoreGui elements ke state semula
local function restoreCoreGuiOnMobile()
	if not isMobile or not hasStoredCoreGuiStates then return end

	-- Kembalikan ke state asli
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, originalCoreGuiStates.Backpack)
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, originalCoreGuiStates.Health)
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, originalCoreGuiStates.PlayerList)
end

local function setSelected(i)
	if selectedIndex > 0 and perkButtons[selectedIndex] and perkButtons[selectedIndex].Parent then
		local prev = perkButtons[selectedIndex]
		local stroke = prev:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = 2
			stroke.Color = Color3.fromRGB(100, 100, 120)
		end
		prev.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	end

	selectedIndex = math.clamp(i, 1, #perkButtons)
	local btn = perkButtons[selectedIndex]
	if not btn then return end

	local stroke = btn:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Thickness = 3
		stroke.Color = Color3.fromRGB(255, 215, 0)
	end
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)

	-- auto-scroll agar tombol terpilih terlihat
	local topY = btn.AbsolutePosition.Y
	local bottomY = topY + btn.AbsoluteSize.Y
	local viewTop = scrollFrame.AbsolutePosition.Y
	local viewBottom = viewTop + scrollFrame.AbsoluteWindowSize.Y

	if topY < viewTop then
		scrollFrame.CanvasPosition = Vector2.new(
			scrollFrame.CanvasPosition.X,
			math.max(0, scrollFrame.CanvasPosition.Y - (viewTop - topY) - 12)
		)
	elseif bottomY > viewBottom then
		scrollFrame.CanvasPosition = Vector2.new(
			scrollFrame.CanvasPosition.X,
			scrollFrame.CanvasPosition.Y + (bottomY - viewBottom) + 12
		)
	end
end

local function unbindDesktopControls()
	ContextActionService:UnbindAction(ARROW_ACTION)
	ContextActionService:UnbindAction(ENTER_ACTION)
end

local function closeShop()
	screenGui.Enabled = false
	if not isMobile then
		unbindDesktopControls()
	end

	-- Kembalikan CoreGui elements di mobile
	restoreCoreGuiOnMobile()

	game:GetService("UserInputService").MouseIconEnabled = false
end

local function purchaseSelected()
	local btn = perkButtons[selectedIndex]
	if not btn then return end
	local perkName = btn:GetAttribute("perkName")
	if not perkName then return end

	local ok, result = pcall(function()
		return purchaseRF:InvokeServer(perkName)
	end)
	if ok and result and result.Success then
		-- notifikasi sudah ditangani existing code di createPerkButton; cukup tutup
		closeShop()
	end
end

local function handleArrowAction(actionName, inputState, inputObj)
	if inputState ~= Enum.UserInputState.Begin then return end
	if #perkButtons == 0 then return end

	local cols = 2  -- Selalu 2 kolom untuk semua platform
	local cur = (selectedIndex > 0) and selectedIndex or 1

	if inputObj.KeyCode == Enum.KeyCode.Right then
		cur = math.clamp(cur + 1, 1, #perkButtons)
	elseif inputObj.KeyCode == Enum.KeyCode.Left then
		cur = math.clamp(cur - 1, 1, #perkButtons)
	elseif inputObj.KeyCode == Enum.KeyCode.Down then
		cur = math.clamp(cur + cols, 1, #perkButtons)
	elseif inputObj.KeyCode == Enum.KeyCode.Up then
		cur = math.clamp(cur - cols, 1, #perkButtons)
	else
		return
	end
	setSelected(cur)
end

local function bindDesktopControls()
	if isMobile then return end
	ContextActionService:BindActionAtPriority(
		ARROW_ACTION,
		function(_, state, input) handleArrowAction(ARROW_ACTION, state, input) end,
		false, 10000,
		Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right
	)
	ContextActionService:BindActionAtPriority(
		ENTER_ACTION,
		function(_, state, input)
			if state == Enum.UserInputState.Begin
				and (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter) then
				purchaseSelected()
			end
		end,
		false, 10000, Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter
	)
end

-- Selalu gunakan UIGridLayout dengan 2 kolom untuk semua platform
local UIGridLayout = Instance.new("UIGridLayout")
if isMobile then
	UIGridLayout.CellSize = UDim2.new(0.48, 0, 0, 200)  -- Perbesar tinggi sel untuk mobile
else
	UIGridLayout.CellSize = UDim2.new(0.48, 0, 0, 160)  -- Tingkatkan tinggi sel untuk desktop agar ada ruang margin bawah
end
UIGridLayout.CellPadding = UDim2.new(0.02, 0, 0, 15)
UIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIGridLayout.StartCorner = Enum.StartCorner.TopLeft
UIGridLayout.Parent = scrollFrame

local function createPerkButton(perkName, config, hasDiscount)
	local button = Instance.new("Frame")
	button.Size = UDim2.new(1, 0, 1, 0)  -- Mengisi seluruh cell grid
	button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	button.BorderSizePixel = 0
	button.ZIndex = 4

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 10)
	buttonCorner.Parent = button

	local buttonStroke = Instance.new("UIStroke")
	buttonStroke.Color = Color3.fromRGB(100, 100, 120)
	buttonStroke.Thickness = 2
	buttonStroke.Parent = button

	-- Sesuaikan ukuran icon untuk mobile
	local iconSize = isMobile and 40 or 50
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, iconSize, 0, iconSize)
	icon.Position = UDim2.new(0.05, 0, 0.05, 0)
	icon.BackgroundTransparency = 1
	icon.Text = config.Icon or "?"
	icon.TextColor3 = Color3.fromRGB(255, 215, 0)
	icon.TextScaled = true
	icon.ZIndex = 5
	icon.Parent = button

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(isMobile and 0.6 or 0.5, 0, 0.2, 0)
	nameLabel.Position = UDim2.new(isMobile and 0.25 or 0.2, 0, 0.05, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = perkName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.ZIndex = 5
	nameLabel.Parent = button

	-- Ubah posisi costLabel untuk mobile
	local costLabel = Instance.new("TextLabel")
	if isMobile then
		-- Posisi untuk mobile: di atas tombol beli
		costLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
		costLabel.Position = UDim2.new(0.05, 0, 0.65, 0)
		costLabel.TextXAlignment = Enum.TextXAlignment.Center
	else
		-- Posisi untuk desktop: di pojok kanan atas
		costLabel.Size = UDim2.new(0.3, 0, 0.2, 0)
		costLabel.Position = UDim2.new(0.7, 0, 0.05, 0)
		costLabel.TextXAlignment = Enum.TextXAlignment.Left
	end
	costLabel.BackgroundTransparency = 1
	local finalCost = config.Cost
	if hasDiscount then
		finalCost = math.floor(finalCost / 2)
		costLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green for discount
	else
		costLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	end
	costLabel.Text = finalCost .. " BP"
	costLabel.TextScaled = true
	costLabel.Font = Enum.Font.GothamBold
	costLabel.ZIndex = 5
	costLabel.Parent = button

	local descLabel = Instance.new("TextLabel")
	-- Perbaikan: Ubah posisi deskripsi untuk desktop agar tidak terlalu dekat dengan icon
	if isMobile then
		descLabel.Size = UDim2.new(0.9, 0, 0.35, 0)
		descLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
	else
		-- Untuk desktop: turunkan posisi deskripsi dan perkecil tinggi
		descLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
		descLabel.Position = UDim2.new(0.05, 0, 0.35, 0)
	end
	descLabel.BackgroundTransparency = 1
	descLabel.Text = config.Description or "No description available."
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.TextWrapped = true
	descLabel.TextScaled = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.Font = Enum.Font.Gotham
	descLabel.ZIndex = 5
	descLabel.Parent = button

	-- Sesuaikan tombol purchase untuk mobile
	local purchaseBtn = Instance.new("TextButton")
	if isMobile then
		purchaseBtn.Size = UDim2.new(0.4, 0, 0.15, 0)
		purchaseBtn.Position = UDim2.new(0.3, 0, 0.8, 0)  -- Posisi lebih bawah untuk mobile
	else
		purchaseBtn.Size = UDim2.new(0.4, 0, 0.15, 0)  -- Perkecil tinggi tombol
		-- Perbaikan: Turunkan posisi tombol untuk desktop dan tambahkan margin bawah
		purchaseBtn.Position = UDim2.new(0.3, 0, 0.75, 0)  -- Ubah dari 0.78 menjadi 0.75
	end
	purchaseBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	purchaseBtn.Text = "BUY"
	purchaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	purchaseBtn.TextScaled = true
	purchaseBtn.Font = Enum.Font.GothamBold
	purchaseBtn.ZIndex = 5
	purchaseBtn.Parent = button

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = purchaseBtn

	purchaseBtn.MouseEnter:Connect(function()
		game:GetService("TweenService"):Create(purchaseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 200, 0)}):Play()
	end)

	purchaseBtn.MouseLeave:Connect(function()
		game:GetService("TweenService"):Create(purchaseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 170, 0)}):Play()
	end)

	purchaseBtn.MouseButton1Click:Connect(function()
		local ok, result = pcall(function()
			return purchaseRF:InvokeServer(perkName)
		end)

		if not ok then
			-- Show error notification
			local notification = Instance.new("TextLabel")
			notification.Size = UDim2.new(0.8, 0, 0, 40)
			notification.Position = UDim2.new(0.1, 0, 0.9, 0)
			notification.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
			notification.Text = "Purchase failed (network)"
			notification.TextColor3 = Color3.fromRGB(255, 255, 255)
			notification.TextScaled = true
			notification.ZIndex = 10
			notification.Parent = mainContainer
			local corner = Instance.new("UICorner"); corner.Parent = notification
			game:GetService("TweenService"):Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.1, 0, 0.8, 0)}):Play()
			task.wait(2)
			game:GetService("TweenService"):Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.1, 0, 0.9, 0)}):Play()
			task.wait(0.5)
			notification:Destroy()
			return
		end

		if result.Success then
			-- Show success notification
			local notification = Instance.new("TextLabel")
			notification.Size = UDim2.new(0.8, 0, 0, 40)
			notification.Position = UDim2.new(0.1, 0, 0.9, 0)
			notification.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
			notification.Text = result.Message or "Perk purchased!"
			notification.TextColor3 = Color3.fromRGB(255, 255, 255)
			notification.TextScaled = true
			notification.ZIndex = 10
			notification.Parent = mainContainer
			local corner = Instance.new("UICorner"); corner.Parent = notification
			game:GetService("TweenService"):Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.1, 0, 0.8, 0)}):Play()
			task.wait(2)
			game:GetService("TweenService"):Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.1, 0, 0.9, 0)}):Play()
			task.wait(0.5)
			notification:Destroy()

			-- Close shop after purchase
			if type(closeShop) == "function" then
				closeShop()
			end
		else
			-- Show error notification
			local notification = Instance.new("TextLabel")
			notification.Size = UDim2.new(0.8, 0, 0, 40)
			notification.Position = UDim2.new(0.1, 0, 0.9, 0)
			notification.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
			notification.Text = result.Message or "Purchase failed"
			notification.TextColor3 = Color3.fromRGB(255, 255, 255)
			notification.TextScaled = true
			notification.ZIndex = 10
			notification.Parent = mainContainer
			local corner = Instance.new("UICorner"); corner.Parent = notification
			game:GetService("TweenService"):Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.1, 0, 0.8, 0)}):Play()
			task.wait(2)
			game:GetService("TweenService"):Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.1, 0, 0.9, 0)}):Play()
			task.wait(0.5)
			notification:Destroy()
		end
	end)
	button:SetAttribute("perkName", perkName)
	return button
end

local function buildShop(config, hasDiscount)
	-- Clear existing elements
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Create perk buttons
	perkButtons = {}
	selectedIndex = 0
	for name, cfg in pairs(config) do
		local perkBtn = createPerkButton(name, cfg, hasDiscount)
		perkBtn.Parent = scrollFrame
		perkBtn:SetAttribute("perkName", name)
		table.insert(perkButtons, perkBtn)
	end
end

local function openShop(config, hasDiscount)
	buildShop(config or {}, hasDiscount)
	screenGui.Enabled = true

	-- Sembunyikan CoreGui elements di mobile
	hideCoreGuiOnMobile()

	if not isMobile then
		if #perkButtons > 0 then
			setSelected(1)
		end
		bindDesktopControls()
	end
	game:GetService("UserInputService").MouseIconEnabled = true
end

closeBtn.MouseButton1Click:Connect(closeShop)

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Escape and screenGui.Enabled then
		closeShop()
	end
end)

-- Listen for shop open event
openEv.OnClientEvent:Connect(openShop)

-- Close when moving away from perk machine
game:GetService("RunService").RenderStepped:Connect(function()
	if screenGui.Enabled then
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local perkPart = workspace:FindFirstChild("Perks")
			if perkPart and perkPart:IsA("BasePart") then
				local dist = (char.HumanoidRootPart.Position - perkPart.Position).Magnitude
				if dist > 12 then
					closeShop()
				end
			end
		end
	end
end)

-- Perk update handler
perkUpdateEv.OnClientEvent:Connect(function(perks)
	-- Update UI untuk menampilkan perk yang sudah dimiliki
	-- (Bisa ditambahkan indikator pada tombol perk yang sudah dimiliki)
end)

-- Pastikan CoreGui dikembalikan jika GUI dihancurkan
screenGui.Destroying:Connect(function()
	restoreCoreGuiOnMobile()
end)

-- Handler untuk ProximityPrompt
ProximityPromptService.PromptTriggered:Connect(function(prompt, plr)
	if prompt ~= perksPrompt or plr ~= player then return end

	-- Kirim event ke server untuk membuka toko perk
	requestOpenEvent:FireServer()
end)
