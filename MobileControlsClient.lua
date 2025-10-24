-- MobileControlsClient.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/MobileControlsClient.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local BindableEvents = game.ReplicatedStorage.BindableEvents

-- Pastikan BindableEvent untuk refresh UI ada
local refreshMobileButtonsEvent = BindableEvents:FindFirstChild("RefreshMobileButtons")
if not refreshMobileButtonsEvent then
    refreshMobileButtonsEvent = Instance.new("BindableEvent")
    refreshMobileButtonsEvent.Name = "RefreshMobileButtons"
    refreshMobileButtonsEvent.Parent = BindableEvents
end

-- Ambil event untuk kontrol tembak
local startAutoFireEvent = BindableEvents:WaitForChild("StartAutoFireEvent")
local stopAutoFireEvent = BindableEvents:WaitForChild("StopAutoFireEvent")

-- Pastikan BindableEvent untuk toggle aim ada
local toggleAimEvent = BindableEvents:FindFirstChild("ToggleAimEvent")
if not toggleAimEvent then
    toggleAimEvent = Instance.new("BindableEvent")
    toggleAimEvent.Name = "ToggleAimEvent"
    toggleAimEvent.Parent = BindableEvents
end

-- Event untuk sinkronisasi status ADS ke UI
local aimStatusChangedEvent = BindableEvents:FindFirstChild("AimStatusChangedEvent")
if not aimStatusChangedEvent then
	aimStatusChangedEvent = Instance.new("BindableEvent")
	aimStatusChangedEvent.Name = "AimStatusChangedEvent"
	aimStatusChangedEvent.Parent = BindableEvents
end

local KnockEvent = RemoteEvents:WaitForChild("KnockEvent")

-- Bindable Event for Reload Request
local requestReloadEvent = BindableEvents:FindFirstChild("RequestReloadEvent") or Instance.new("BindableEvent", BindableEvents)
requestReloadEvent.Name = "RequestReloadEvent"

-- Utility: cari Tool bersenjata yang sedang dipegang
local function getEquippedWeapon()
	local char = player.Character
	if not char then return nil end
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
			-- anggap semua Tool dengan Handle adalah senjata di proyek ini
			return tool
		end
	end
	return nil
end

-- UI maker sederhana (match style yang lama)
local function createRoundButton(name, text, pos, size)
	local screenGui = playerGui:FindFirstChild("ScreenGui") or Instance.new("ScreenGui")
	screenGui.Name = "ScreenGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local button = Instance.new("ImageButton")
	button.Name = name
	button.Position = pos
	button.Size = size
	button.BackgroundTransparency = 1
	button.ImageTransparency = 1
	button.ZIndex = 10
	button.Visible = false
	button.Parent = screenGui

	local bg = Instance.new("Frame")
	bg.Name = "BG"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	bg.BackgroundTransparency = 0.7
	bg.BorderSizePixel = 0
	bg.ZIndex = 10
	bg.Parent = button

	local corner = Instance.new("UICorner", bg)
	corner.CornerRadius = UDim.new(1, 0)

	local stroke = Instance.new("UIStroke", bg)
	stroke.Name = "Stroke"
	stroke.Thickness = 2
	stroke.Transparency = 0.7
	stroke.Color = Color3.fromRGB(255, 255, 255)

	local grad = Instance.new("UIGradient", bg)
	grad.Name = "BGGradient"
	grad.Rotation = 90
	grad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 80, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 50, 50))
	}

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -10, 1, -10)
	label.Position = UDim2.new(0, 5, 0, 5)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.ZIndex = 11
	label.TextWrapped = true
	label.Parent = bg

	return button
end

-- Buat tombol hanya untuk perangkat sentuh
if not UserInputService.TouchEnabled then
	return
end

-- Hilangkan tombol lompat bawaan
local function hideDefaultJumpButton()
	local touchGui = playerGui:WaitForChild("TouchGui")
	local touchControlFrame = touchGui:WaitForChild("TouchControlFrame")
	if touchControlFrame then
		local jumpButton = touchControlFrame:FindFirstChild("JumpButton")
		if jumpButton then
			jumpButton:Destroy()
		end
	end
end

hideDefaultJumpButton()
-- Coba lagi jika GUI dimuat ulang
playerGui.ChildAdded:Connect(function(child)
	if child:IsA("ScreenGui") and child.Name == "TouchGui" then
		hideDefaultJumpButton()
	end
end)

-- Pastikan atribut preferensi kontrol ada
if player:GetAttribute("DoubleTapUsesADS") == nil then
	player:SetAttribute("DoubleTapUsesADS", true)
end
if player:GetAttribute("FireControlType") == nil then
	player:SetAttribute("FireControlType", "FireButton") -- Default baru
end

local reloadBtn = createRoundButton(
	"MobileReloadButton",
	"RELOAD",
	UDim2.new(0.74, 0, 0.52, 0),
	UDim2.new(0, 72, 0, 72)
)
local adsBtn = createRoundButton(
	"MobileAimButton",
	"ADS",
	UDim2.new(0.86, 0, 0.36, 0),
	UDim2.new(0, 72, 0, 72)
)

local jumpBtn = createRoundButton(
	"MobileJumpButton",
	"JUMP",
	UDim2.new(0.85, 0, 0.65, 0),
	UDim2.new(0, 90, 0, 90)
)

local fireBtn = createRoundButton(
	"MobileFireButton",
	"FIRE",
	UDim2.new(0.72, 0, 0.78, 0), -- Di kanan bawah
	UDim2.new(0, 100, 0, 100)
)


local function setAdsStyle()
	local bg = adsBtn:FindFirstChild("BG")
	if not bg then return end
	local stroke = bg:FindFirstChild("Stroke")
	if not stroke then return end
	if player:GetAttribute("DoubleTapUsesADS") then
		stroke.Color = Color3.fromRGB(80, 200, 120) -- aktif
	else
		stroke.Color = Color3.fromRGB(255, 255, 255) -- non-aktif
	end
end

-- Show/hide tombol berdasarkan apakah ada weapon yang di-equip
local function refreshButtonsVisibility()
	local tool = getEquippedWeapon()
	local isKnocked = player.Character and player.Character:FindFirstChild("Knocked") ~= nil
	local weaponControlsVisible = tool ~= nil and not isKnocked
	local fireControlType = player:GetAttribute("FireControlType")

	reloadBtn.Visible = weaponControlsVisible
	adsBtn.Visible = weaponControlsVisible
	jumpBtn.Visible = not isKnocked
	fireBtn.Visible = weaponControlsVisible and (fireControlType == "FireButton")

	setAdsStyle()
end

-- Dengarkan event untuk me-refresh UI
refreshMobileButtonsEvent.Event:Connect(refreshButtonsVisibility)

-- Events agar visibilitas selalu sinkron:
player.CharacterAdded:Connect(function(char)
	char.ChildAdded:Connect(refreshButtonsVisibility)
	char.ChildRemoved:Connect(refreshButtonsVisibility)
	refreshButtonsVisibility()
end)
if player.Character then
	player.Character.ChildAdded:Connect(refreshButtonsVisibility)
	player.Character.ChildRemoved:Connect(refreshButtonsVisibility)
end

-- Reaksi knock
KnockEvent.OnClientEvent:Connect(function(knockStatus)
	local hasWeapon = getEquippedWeapon() ~= nil
	local fireControlType = player:GetAttribute("FireControlType")
	reloadBtn.Visible = not knockStatus and hasWeapon
	adsBtn.Visible = not knockStatus and hasWeapon
	jumpBtn.Visible = not knockStatus
	fireBtn.Visible = not knockStatus and hasWeapon and (fireControlType == "FireButton")
end)

-- Klik: Reload
reloadBtn.MouseButton1Click:Connect(function()
	-- Cukup fire event bindable. WeaponClient akan menangani logika & validasi.
	requestReloadEvent:Fire()
end)

-- Klik: Toggle preferensi ADS (double-tap uses ADS vs HIP)
-- Klik: Toggle ADS (mode tombol tembak) atau Toggle Preferensi (mode double tap)
adsBtn.MouseButton1Click:Connect(function()
	local fireControlType = player:GetAttribute("FireControlType")

	if fireControlType == "FireButton" then
		-- Mode tombol tembak: kirim event untuk toggle ADS
		toggleAimEvent:Fire()
	else
		-- Mode double tap: ubah preferensi double tap
		local cur = player:GetAttribute("DoubleTapUsesADS")
		player:SetAttribute("DoubleTapUsesADS", not cur)
		setAdsStyle()
	end
end)

-- Klik: Lompat
local isJumping = false
jumpBtn.MouseButton1Click:Connect(function()
	local char = player.Character
	if not char or isJumping then return end

	-- Cek stamina kustom dari SprintClient
	local currentStamina = char:GetAttribute("ClientStamina")
	if currentStamina and currentStamina < 5 then
		return -- Tidak cukup stamina, jangan lompat
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
		isJumping = true
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

-- Koneksi Tombol Tembak
fireBtn.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        startAutoFireEvent:Fire(input)
    end
end)

fireBtn.InputEnded:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        stopAutoFireEvent:Fire()
    end
end)


local function resetJumpState()
	isJumping = false
end

local function onStateChanged(old, new)
	if new == Enum.HumanoidStateType.Landed then
		resetJumpState()
	elseif new == Enum.HumanoidStateType.Dead then
		resetJumpState()
	end
end

local function onCharAdded(char)
	resetJumpState()
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.StateChanged:Connect(onStateChanged)
end

-- Hubungkan ke karakter saat ini dan masa depan
if player.Character then
	onCharAdded(player.Character)
end
player.CharacterAdded:Connect(onCharAdded)

-- Visual feedback untuk tombol lompat berdasarkan stamina
RunService.RenderStepped:Connect(function()
	local char = player.Character
	if not char or not jumpBtn.Visible then return end

	local stamina = char:GetAttribute("ClientStamina")
	-- Anggap bisa jika atribut belum ada
	local canJump = (stamina == nil or stamina >= 5)

	local bg = jumpBtn:FindFirstChild("BG")
	if not bg then return end
	local label = bg:FindFirstChild("Label")
	local stroke = bg:FindFirstChild("Stroke")

	if canJump then
		-- Kembalikan ke state normal/aktif
		bg.BackgroundTransparency = 0.7
		if label then
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.TextTransparency = 0
		end
		if stroke then
			stroke.Color = Color3.fromRGB(255, 255, 255)
			stroke.Transparency = 0.7
		end
	else
		-- Ubah ke state non-aktif/redup
		bg.BackgroundTransparency = 0.85
		if label then
			label.TextColor3 = Color3.fromRGB(150, 150, 150)
			label.TextTransparency = 0.5
		end
		if stroke then
			stroke.Color = Color3.fromRGB(100, 100, 100)
			stroke.Transparency = 0.85
		end
	end
end)

-- Inisialisasi pertama
refreshButtonsVisibility()
setAdsStyle()

-- Fungsi untuk update warna tombol ADS berdasarkan status
local function updateAdsButtonColor(isAiming)
	local fireControlType = player:GetAttribute("FireControlType")
	if fireControlType ~= "FireButton" then
		-- Jika bukan mode tombol tembak, kembalikan ke style default (berdasarkan preferensi double tap)
		setAdsStyle()
		return
	end

	local bg = adsBtn:FindFirstChild("BG")
	if not bg then return end
	local stroke = bg:FindFirstChild("Stroke")
	if not stroke then return end

	if isAiming then
		stroke.Color = Color3.fromRGB(80, 200, 120) -- Hijau (aktif)
	else
		stroke.Color = Color3.fromRGB(255, 255, 255) -- Putih (non-aktif)
	end
end

-- Dengarkan perubahan status ADS dari WeaponClient
aimStatusChangedEvent.Event:Connect(updateAdsButtonColor)

-- Pastikan warna direset saat equip/unequip senjata
local function onWeaponEquippedChanged()
	task.wait(0.1) -- Beri waktu agar `getEquippedWeapon` mendapatkan status terbaru
	if not getEquippedWeapon() then
		updateAdsButtonColor(false) -- Reset ke status off jika tidak ada senjata
	end
end

if player.Character then
	player.Character.ChildAdded:Connect(onWeaponEquippedChanged)
	player.Character.ChildRemoved:Connect(onWeaponEquippedChanged)
end
player.CharacterAdded:Connect(function(char)
	char.ChildAdded:Connect(onWeaponEquippedChanged)
	char.ChildRemoved:Connect(onWeaponEquippedChanged)
end)
