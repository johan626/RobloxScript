-- CrosshairUI.lua (LocalScript)
-- Path: StarterGui/CrosshairUI.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local mouse = player:GetMouse()

-- Buat ScreenGui untuk menampung crosshair
local crosshairGui = Instance.new("ScreenGui")
crosshairGui.Name = "CrosshairUI"
crosshairGui.IgnoreGuiInset = true
crosshairGui.Parent = player:WaitForChild("PlayerGui")

-- Container utama untuk crosshair
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 50, 0, 50) -- Ukuran kontainer
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundTransparency = 1
container.Visible = false -- Sembunyikan secara default
container.Parent = crosshairGui

-- Atur posisi kontainer di tengah layar
function updateContainerPosition()
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
end

-- Buat empat garis untuk crosshair
local function createLine(name, size, position)
	local line = Instance.new("Frame")
	line.Name = name
	line.Size = size
	line.Position = position
	line.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Warna putih
	line.BorderSizePixel = 0
	line.Parent = container
	return line
end

-- Atur ukuran dan posisi garis
local lineThickness = 2
local lineLength = 15

local top = createLine("TopLine", UDim2.new(0, lineThickness, 0, lineLength), UDim2.new(0.5, -1, 0.5, -lineLength - 5))
local bottom = createLine("BottomLine", UDim2.new(0, lineThickness, 0, lineLength), UDim2.new(0.5, -1, 0.5, 5))
local left = createLine("LeftLine", UDim2.new(0, lineLength, 0, lineThickness), UDim2.new(0.5, -lineLength - 5, 0.5, -1))
local right = createLine("RightLine", UDim2.new(0, lineLength, 0, lineThickness), UDim2.new(0.5, 5, 0.5, -1))

-- Variabel untuk melacak tool yang sedang dipegang dan status aiming
local currentTool = nil
local isAiming = false
local weaponConfig = nil

-- Fungsi untuk memeriksa apakah tool yang sedang dipegang adalah senjata
local function isCurrentToolAWeapon()
	if currentTool and currentTool:FindFirstChild("Handle") then
		return true
	end
	return false
end

-- Fungsi untuk mendapatkan konfigurasi senjata
local function getWeaponConfig(tool)
	if not tool then return nil end
	local weaponName = tool.Name
	local WeaponModule = require(game.ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))
	return WeaponModule.Weapons[weaponName]
end

-- Fungsi untuk update visibility crosshair berdasarkan config dan aiming state
local function updateCrosshairVisibility()
	local isWeapon = isCurrentToolAWeapon()
	if not isWeapon then
		container.Visible = false
		UserInputService.MouseIconEnabled = true
		player.CameraMode = Enum.CameraMode.Classic
		return
	end

	weaponConfig = getWeaponConfig(currentTool)
	if not weaponConfig then
		container.Visible = false
		return
	end

	-- Tentukan visibility berdasarkan aiming state dan config
	if isAiming then
		container.Visible = weaponConfig.ShowCrosshairADS
	else
		container.Visible = weaponConfig.ShowCrosshair
	end

	-- Kontrol mode kamera dan mouse icon
	if isWeapon then
		UserInputService.MouseIconEnabled = false
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		updateContainerPosition()
	else
		UserInputService.MouseIconEnabled = true
		player.CameraMode = Enum.CameraMode.Classic
	end
end

-- Fungsi untuk memantau tool yang dipegang
local function onCharacterAdded(char)
	-- Memantau perubahan tool di karakter
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			currentTool = child
			-- Connect untuk attribute changed pada IsAiming
			child.AttributeChanged:Connect(function(attribute)
				if attribute == "IsAiming" then
					isAiming = child:GetAttribute("IsAiming") or false
					updateCrosshairVisibility()
				end
			end)
			-- Inisialisasi status aiming
			isAiming = child:GetAttribute("IsAiming") or false
			updateCrosshairVisibility()
		end
	end)

	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child == currentTool then
			currentTool = nil
			isAiming = false
			updateCrosshairVisibility()
		end
	end)

	-- Cek tool yang sudah ada
	for _, child in pairs(char:GetChildren()) do
		if child:IsA("Tool") then
			currentTool = child
			isAiming = child:GetAttribute("IsAiming") or false
			updateCrosshairVisibility()
			break
		end
	end
end

-- Hubungkan ke event karakter
player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end

-- Loop utama untuk mengontrol visibilitas crosshair (sebagai backup)
RunService.RenderStepped:Connect(function()
	updateCrosshairVisibility()
end)
