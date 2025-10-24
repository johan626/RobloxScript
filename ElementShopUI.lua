-- ElementShopUI.lua (LocalScript)
-- Path: StarterGui/ElementShopUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions

local openEv = RemoteEvents:WaitForChild("OpenElementShop")
local requestOpenEvent = RemoteEvents:WaitForChild("RequestOpenElementShop")
local closeShop = RemoteEvents:WaitForChild("CloseElementShop")

local purchaseRF = RemoteFunctions:WaitForChild("PurchaseElement")

local elementsPart = workspace:WaitForChild("Elements")
local ProximityPromptService = game:GetService("ProximityPromptService")
local elementsPrompt = workspace.Elements:WaitForChild("Attachment"):WaitForChild("ElementsPrompt")
local originalCoreGuiStates = {}
local hasStoredCoreGuiStates = false

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ElementShopUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false

-- Deteksi perangkat mobile
local isMobile = UserInputService.TouchEnabled

-- Background overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.BorderSizePixel = 0
overlay.ZIndex = 1
overlay.Parent = screenGui

-- Main container - Responsive size dengan penyesuaian untuk mobile
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

-- Add responsive corner rounding
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = mainContainer

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(80, 80, 100)
UIStroke.Thickness = 3
UIStroke.Parent = mainContainer

-- Header with title and close button
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.12, 0)
header.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
header.BorderSizePixel = 0
header.ZIndex = 3
header.Parent = mainContainer

-- === Keyboard selection state (desktop) ===
local elementButtons = {}     -- urutan tombol elemen di grid
local selectedIndex  = 1      -- indeks yang sedang terseleksi (1-based)

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

local function styleButton(btn, active)
	if not btn then return end
	local stroke = btn:FindFirstChildOfClass("UIStroke")
	if active then
		if stroke then stroke.Thickness = 4; stroke.Color = Color3.fromRGB(255, 215, 0) end
		btn.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
	else
		if stroke then stroke.Thickness = 2; stroke.Color = Color3.fromRGB(100, 100, 120) end
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	end
end

-- Element display area
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.95, 0, 0.8, 0)
scrollFrame.Position = UDim2.new(0.025, 0, 0.15, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = isMobile and 6 or 0
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.ZIndex = 3
scrollFrame.Parent = mainContainer

local function setSelected(newIndex)
	if #elementButtons == 0 then return end
	newIndex = math.clamp(newIndex, 1, #elementButtons)
	if elementButtons[selectedIndex] then styleButton(elementButtons[selectedIndex], false) end
	selectedIndex = newIndex
	styleButton(elementButtons[selectedIndex], true)

	-- Pastikan item terlihat di ScrollFrame
	local btn = elementButtons[selectedIndex]
	-- Auto-scroll agar tombol yang terseleksi selalu terlihat
	local sf = scrollFrame
	if sf and btn and btn.AbsolutePosition and btn.AbsoluteSize then
		-- Batas tampilan (viewport) ScrollingFrame
		local viewTop = sf.AbsolutePosition.Y
		local viewBottom = viewTop + sf.AbsoluteWindowSize.Y

		-- Batas tombol yang terseleksi
		local btnTop = btn.AbsolutePosition.Y
		local btnBottom = btnTop + btn.AbsoluteSize.Y

		-- Hitung pergeseran yang dibutuhkan
		local deltaY = 0
		local padding = 8 -- sedikit jarak aman

		if btnTop < viewTop then
			deltaY = (btnTop - viewTop) - padding
		elseif btnBottom > viewBottom then
			deltaY = (btnBottom - viewBottom) + padding
		end

		-- Geser CanvasPosition bila perlu
		if deltaY ~= 0 then
			sf.CanvasPosition = sf.CanvasPosition + Vector2.new(0, deltaY)
		end
	end

	if btn and btn.AbsolutePosition and btn.AbsoluteSize and btn.Parent and btn.Parent:FindFirstChildOfClass("ScrollingFrame") then
		-- noop: ScrollFrame.AutomaticCanvasSize sudah aktif; biarkan Roblox handle
	end
end

local function purchaseSelected()
	if not screenGui.Enabled then return end
	local btn = elementButtons[selectedIndex]
	if not btn then return end
	local elementName = btn:GetAttribute("ElementName")
	if not elementName then return end

	-- panggil server
	local ok, msg = purchaseRF:InvokeServer(elementName)
	-- Tampilkan notifikasi sederhana (hijau = sukses, merah = gagal)
	local notification = Instance.new("TextLabel")
	notification.Size = UDim2.new(0.8, 0, 0, 40)
	notification.Position = UDim2.new(0.1, 0, 0.9, 0)
	notification.BackgroundColor3 = ok and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0)
	notification.Text = ok and ("Purchased " .. elementName .. "!") or (msg or "Purchase failed")
	notification.TextColor3 = Color3.fromRGB(255,255,255)
	notification.TextScaled = true
	notification.ZIndex = 10
	notification.Parent = mainContainer
	local corner = Instance.new("UICorner"); corner.Parent = notification
	game:GetService("TweenService"):Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.1,0,0.8,0)}):Play()
	task.wait(2)
	game:GetService("TweenService"):Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.1,0,0.9,0)}):Play()
	task.wait(0.5)
	notification:Destroy()

	-- Tutup shop saat sukses (opsional)
	if ok and type(closeShop) == "function" then closeShop() end
end

-- Tangkap arrow keys + enter saat shop terbuka
local ARROW_ACTION = "ElementShopArrows"

local function handleShopArrows(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	-- kalau user sedang mengetik di TextBox, biarkan lewat
	if UserInputService:GetFocusedTextBox() then
		return Enum.ContextActionResult.Pass
	end
	if not screenGui.Enabled then
		return Enum.ContextActionResult.Pass
	end

	local kc = inputObject.KeyCode
	if kc == Enum.KeyCode.Left then
		if setSelected then setSelected(selectedIndex - 1) end
	elseif kc == Enum.KeyCode.Right then
		if setSelected then setSelected(selectedIndex + 1) end
	elseif kc == Enum.KeyCode.Up then
		if setSelected then setSelected(selectedIndex - 2) end
	elseif kc == Enum.KeyCode.Down then
		if setSelected then setSelected(selectedIndex + 2) end
	elseif kc == Enum.KeyCode.Return or kc == Enum.KeyCode.KeypadEnter then
		if purchaseSelected then purchaseSelected() end
	end

	-- "Sink" supaya tidak diteruskan ke movement/camera
	return Enum.ContextActionResult.Sink
end

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.7, 0, 1, 0)
title.Position = UDim2.new(0.15, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "ELEMENT SHOP"
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

-- Selalu gunakan UIGridLayout dengan 2 kolom untuk semua platform
local UIGridLayout = Instance.new("UIGridLayout")
if isMobile then
	UIGridLayout.CellSize = UDim2.new(0.48, 0, 0, 200)  -- Perbesar tinggi sel untuk mobile
else
	UIGridLayout.CellSize = UDim2.new(0.48, 0, 0, 180)
end
UIGridLayout.CellPadding = UDim2.new(0.02, 0, 0, 15)
UIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIGridLayout.StartCorner = Enum.StartCorner.TopLeft
UIGridLayout.Parent = scrollFrame

-- Element descriptions
local elementDescriptions = {
	Fire = "Adds fire damage to your bullets. Enemies burn over time.",
	Ice = "Slows enemies on hit. Reduces movement speed significantly.",
	Poison = "Poisons enemies, dealing damage over time.",
	Shock = "Electric damage that chains to nearby enemies.",
	Wind = "Push enemy.",
	Earth = "Reduces damage taken.",
	Light = "invincible.",
	Dark = "Steals health from enemies on hit."
}

-- Element icons replaced with text
local elementText = {
	Fire = "🔥",
	Ice = "❄️",
	Poison = "☠️",
	Shock = "⚡",
	Wind = "💨",
	Earth = "🌍",
	Light = "✨",
	Dark = "🌑"
}

-- Element templates function
local function createElementButton(elementName, config, hasDiscount)
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

	-- Simpan nama elemen pada frame untuk dipakai Enter-buy
	button:SetAttribute("ElementName", elementName)

	-- Sesuaikan ukuran icon untuk mobile
	local iconSize = isMobile and 40 or 50
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, iconSize, 0, iconSize)
	icon.Position = UDim2.new(0.05, 0, 0.05, 0)
	icon.BackgroundTransparency = 1
	icon.Text = elementText[elementName] or elementName:sub(1, 1)
	icon.TextColor3 = Color3.fromRGB(255, 215, 0)
	icon.TextScaled = true
	icon.ZIndex = 5
	icon.Parent = button

	-- Element name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(isMobile and 0.6 or 0.5, 0, 0.2, 0)
	nameLabel.Position = UDim2.new(isMobile and 0.25 or 0.2, 0, 0.05, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = elementName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.ZIndex = 5
	nameLabel.Parent = button

	-- Element cost - DIPINDAHKAN KE ATAS TOMBEL BELI UNTUK MOBILE
	local costLabel = Instance.new("TextLabel")
	if isMobile then
		-- Posisi baru untuk mobile: di atas tombol beli
		costLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
		costLabel.Position = UDim2.new(0.05, 0, 0.65, 0)  -- Dipindahkan ke atas tombol beli
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

	-- Element duration
	local durationLabel = Instance.new("TextLabel")
	if isMobile then
		durationLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
		durationLabel.Position = UDim2.new(0.05, 0, 0.55, 0)  -- Dipindahkan sedikit ke atas
		durationLabel.TextXAlignment = Enum.TextXAlignment.Center
	else
		durationLabel.Size = UDim2.new(0.3, 0, 0.2, 0)
		durationLabel.Position = UDim2.new(0.2, 0, 0.25, 0)
		durationLabel.TextXAlignment = Enum.TextXAlignment.Left
	end
	durationLabel.BackgroundTransparency = 1
	durationLabel.Text = "Duration: " .. tostring(config.Duration) .. "s"
	durationLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	durationLabel.TextScaled = true
	durationLabel.Font = Enum.Font.Gotham
	durationLabel.ZIndex = 5
	durationLabel.Parent = button

	-- Element description
	local descLabel = Instance.new("TextLabel")
	if isMobile then
		-- Sesuaikan ukuran dan posisi deskripsi untuk memberi ruang bagi harga
		descLabel.Size = UDim2.new(0.9, 0, 0.3, 0)  -- Diperkecil sedikit
		descLabel.Position = UDim2.new(0.05, 0, 0.25, 0)  -- Dipindahkan ke atas
	else
		descLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
		descLabel.Position = UDim2.new(0.05, 0, 0.45, 0)
	end
	descLabel.BackgroundTransparency = 1
	descLabel.Text = elementDescriptions[elementName] or "No description available."
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.TextWrapped = true
	descLabel.TextScaled = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.Font = Enum.Font.Gotham
	descLabel.ZIndex = 5
	descLabel.Parent = button

	-- Purchase button
	local purchaseBtn = Instance.new("TextButton")
	if isMobile then
		purchaseBtn.Size = UDim2.new(0.4, 0, 0.15, 0)
		purchaseBtn.Position = UDim2.new(0.3, 0, 0.8, 0)  -- Posisi lebih bawah untuk mobile
	else
		purchaseBtn.Size = UDim2.new(0.4, 0, 0.15, 0)
		purchaseBtn.Position = UDim2.new(0.3, 0, 0.75, 0)
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

	-- Hover effects (hanya untuk non-mobile)
	if not isMobile then
		purchaseBtn.MouseEnter:Connect(function()
			game:GetService("TweenService"):Create(purchaseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 200, 0)}):Play()
		end)

		purchaseBtn.MouseLeave:Connect(function()
			game:GetService("TweenService"):Create(purchaseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 170, 0)}):Play()
		end)
	end

	-- Purchase functionality
	purchaseBtn.MouseButton1Click:Connect(function()
		-- panggil server cuma sekali, pakai pcall untuk network safety
		local ok, resultOrErr = pcall(function()
			return purchaseRF:InvokeServer(elementName)
		end)

		if not ok then
			-- network / runtime error saat invoke
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

		-- resultOrErr bisa: boolean true/false OR string OR table { success=true, message="..." }
		local success = resultOrErr == true or (type(resultOrErr) == "table" and resultOrErr.success == true)
		local msg = nil
		if type(resultOrErr) == "string" then msg = resultOrErr end
		if type(resultOrErr) == "table" then msg = resultOrErr.message end

		if success then
			-- tampilkan notifikasi sukses (kamu bisa pakai styling yang ada)
			local notification = Instance.new("TextLabel")
			notification.Size = UDim2.new(0.8, 0, 0, 40)
			notification.Position = UDim2.new(0.1, 0, 0.9, 0)
			notification.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
			notification.Text = "Purchased "..elementName.."!"
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

			-- tutup shop SAFELY (cek dulu apakah closeShop ada)
			if type(closeShop) == "function" then
				closeShop()
			end
		else
			-- tampilkan pesan error yang dikirim server
			local reasonText = msg or "Purchase failed"
			local notification = Instance.new("TextLabel")
			notification.Size = UDim2.new(0.8, 0, 0, 40)
			notification.Position = UDim2.new(0.1, 0, 0.9, 0)
			notification.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
			notification.Text = reasonText
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
	return button
end

-- Build shop function
local function buildShop(config, hasDiscount)
	-- Reset koleksi tombol & selection setiap kali build
	table.clear(elementButtons)
	selectedIndex = 1
	-- Clear existing elements
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Create element buttons
	for name, cfg in pairs(config) do
		local elementBtn = createElementButton(name, cfg, hasDiscount)
		table.insert(elementButtons, elementBtn)
		elementBtn.Parent = scrollFrame
	end
end

-- Open shop function
local function openShop(config, hasDiscount)
	buildShop(config or {}, hasDiscount)
	screenGui.Enabled = true

	-- Sembunyikan CoreGui elements di mobile
	hideCoreGuiOnMobile()

	if not isMobile then
		-- Ikat arrow keys + enter khusus ketika shop aktif
		ContextActionService:BindActionAtPriority(
			ARROW_ACTION,
			handleShopArrows,
			false,
			Enum.ContextActionPriority.High.Value,
			Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.Up, Enum.KeyCode.Down,
			Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter
		)
		if #elementButtons > 0 then
			setSelected(1)
		end
	end
	UserInputService.MouseIconEnabled = not isMobile
end

-- Close shop function
closeShop = function()
	-- Lepas ikatan agar kontrol player normal kembali
	if not isMobile then
		ContextActionService:UnbindAction(ARROW_ACTION)
	end

	-- Kembalikan CoreGui elements di mobile
	restoreCoreGuiOnMobile()

	screenGui.Enabled = false
	UserInputService.MouseIconEnabled = false
end

-- Close button functionality
closeBtn.MouseButton1Click:Connect(closeShop)

-- ESC to close (hanya untuk non-mobile)
if not isMobile then
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.Escape and screenGui.Enabled then
			if type(closeShop) == "function" then closeShop() end
		end
	end)
end

-- Listen for shop open event
openEv.OnClientEvent:Connect(openShop)

-- Close when moving away from vending machine
game:GetService("RunService").RenderStepped:Connect(function()
	if screenGui.Enabled then
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local vendingPart = workspace:FindFirstChild("Elements")
			if vendingPart and vendingPart:IsA("BasePart") then
				local dist = (char.HumanoidRootPart.Position - vendingPart.Position).Magnitude
				if dist > 12 then
					if type(closeShop) == "function" then closeShop() end
				end
			end
		end
	end
end)

-- Pastikan CoreGui dikembalikan jika GUI dihancurkan
screenGui.Destroying:Connect(function()
	restoreCoreGuiOnMobile()
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, plr)
	if prompt ~= elementsPrompt or plr ~= player then return end

	-- Kirim permintaan buka toko ke server
	local ok, result = pcall(function()
		return requestOpenEvent:FireServer()
	end)
end)