-- DamageFlashUI.lua (LocalScript)
-- Path: StarterGui/DamageFlashUI.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LOCAL_PLAYER = Players.LocalPlayer

-- === Konfigurasi Efek ===
local FLASH_MAX_OPACITY = 0.45    -- Opacity puncak saat kena damage biasa (0..1)
local FLASH_MIN_OPACITY = 0.0     -- Transparansi akhir
local FLASH_TIME_IN   = 0.08      -- Durasi naik ke merah
local FLASH_TIME_OUT  = 0.35      -- Durasi pudar kembali
local KNOCKED_OPACITY = 0.65      -- Opacity saat status Knocked
local LOW_HP_THRESHOLD = 0.2      -- Jika Health di bawah 20% → warna sedikit lebih kuat

-- Semakin besar damage relatif terhadap MaxHealth, semakin kuat flash
local function computeFlashStrength(oldHealth, newHealth, maxHealth)
	if not maxHealth or maxHealth <= 0 then return FLASH_MAX_OPACITY end
	local delta = math.max(0, oldHealth - newHealth) -- damage yang diterima
	local ratio = delta / maxHealth                  -- 0..1
	-- Skala dasar + akhiri di batas maksimum
	local scaled = math.clamp(0.15 + ratio * 0.9, 0.15, 1.0)
	-- Kembalikan target opacity dengan topi di FLASH_MAX_OPACITY (akan ditambah sedikit jika Low HP)
	return math.min(FLASH_MAX_OPACITY, scaled)
end

-- === Utility: Buat UI overlay merah ===
local ScreenGui, Overlay, Vignette, tweenIn, tweenOut

local function destroyOverlay()
	if tweenIn then tweenIn:Cancel() end
	if tweenOut then tweenOut:Cancel() end
	if ScreenGui then
		ScreenGui:Destroy()
		ScreenGui, Overlay, Vignette, tweenIn, tweenOut = nil, nil, nil, nil, nil
	end
end

local function createOverlay()
	destroyOverlay()

	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "DamageFlashUI"
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	ScreenGui.DisplayOrder = 9999
	ScreenGui.Parent = LOCAL_PLAYER:WaitForChild("PlayerGui")

	-- Layer merah polos (mengisi layar)
	Overlay = Instance.new("Frame")
	Overlay.Name = "RedFlash"
	Overlay.Size = UDim2.fromScale(1, 1)
	Overlay.Position = UDim2.fromScale(0, 0)
	Overlay.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
	Overlay.BackgroundTransparency = 1.0
	Overlay.BorderSizePixel = 0
	Overlay.ZIndex = 10000
	Overlay.Parent = ScreenGui

	-- Vignette (gelap di tepi, membantu efek dramatis)
	Vignette = Instance.new("ImageLabel")
	Vignette.Name = "Vignette"
	Vignette.BackgroundTransparency = 1
	Vignette.Size = UDim2.fromScale(1, 1)
	Vignette.Position = UDim2.fromScale(0, 0)
	Vignette.Image = "rbxassetid://13547204142" -- tekstur vignette halus (opsional; ganti jika perlu)
	Vignette.ScaleType = Enum.ScaleType.Stretch
	Vignette.ImageTransparency = 1.0
	Vignette.ZIndex = 10001
	Vignette.Parent = ScreenGui
end

-- Tween helper
local function playFlash(targetOpacity)
	if not Overlay then return end
	if tweenIn then tweenIn:Cancel() end
	if tweenOut then tweenOut:Cancel() end

	-- Naik cepat
	tweenIn = TweenService:Create(
		Overlay,
		TweenInfo.new(FLASH_TIME_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 1 - targetOpacity}
	)
	tweenIn:Play()

	-- Vignette selaras (sedikit lebih transparan agar tidak terlalu pekat)
	if Vignette then
		local vigTarget = math.clamp(1 - (targetOpacity * 0.6), 0, 1)
		TweenService:Create(
			Vignette,
			TweenInfo.new(FLASH_TIME_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ImageTransparency = vigTarget}
		):Play()
	end

	-- Lalu pudar
	tweenIn.Completed:Connect(function()
		if not Overlay then return end
		tweenOut = TweenService:Create(
			Overlay,
			TweenInfo.new(FLASH_TIME_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{BackgroundTransparency = 1 - FLASH_MIN_OPACITY}
		)
		tweenOut:Play()

		if Vignette then
			TweenService:Create(
				Vignette,
				TweenInfo.new(FLASH_TIME_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ImageTransparency = 1.0}
			):Play()
		end
	end)
end

-- Efek “knocked” (lebih kuat & agak bertahan till pulih)
local knockedConn
local function bindKnockEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	local knockEvent = remoteFolder and remoteFolder:FindFirstChild("KnockEvent")
	if not knockEvent then return end

	if knockedConn then knockedConn:Disconnect() end
	knockedConn = knockEvent.OnClientEvent:Connect(function(isKnocked)
		if not Overlay then return end
		if isKnocked then
			-- Tampil kuat saat knocked
			if tweenIn then tweenIn:Cancel() end
			if tweenOut then tweenOut:Cancel() end
			Overlay.BackgroundTransparency = 1 - KNOCKED_OPACITY
			if Vignette then Vignette.ImageTransparency = 0.25 end
		else
			-- Pulih: pudar balik
			playFlash(FLASH_MAX_OPACITY * 0.6)
		end
	end)
end

-- Health listener : flash saat turun
local healthConn, diedConn
local lastHealth

local function onCharacter(char)
	-- Siapkan UI
	createOverlay()
	bindKnockEvents()

	local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
	if not hum then return end

	lastHealth = hum.Health

	if healthConn then healthConn:Disconnect() end
	if diedConn then diedConn:Disconnect() end

	healthConn = hum.HealthChanged:Connect(function(newHealth)
		if not Overlay then return end
		if lastHealth == nil then
			lastHealth = newHealth
			return
		end

		-- Flash hanya ketika health TURUN
		if newHealth < lastHealth then
			local target = computeFlashStrength(lastHealth, newHealth, hum.MaxHealth)

			-- Sedikit tambah bila HP rendah (di bawah threshold)
			if hum.MaxHealth > 0 and (newHealth / hum.MaxHealth) <= LOW_HP_THRESHOLD then
				target = math.min(1.0, target + 0.15)
			end

			playFlash(target)
		end

		lastHealth = newHealth
	end)

	diedConn = hum.Died:Connect(function()
		-- Saat mati, pudar perlahan
		if Overlay then
			if tweenIn then tweenIn:Cancel() end
			if tweenOut then tweenOut:Cancel() end
			TweenService:Create(
				Overlay,
				TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 1.0}
			):Play()
			if Vignette then
				TweenService:Create(
					Vignette,
					TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ImageTransparency = 1.0}
				):Play()
			end
		end
	end)
end

-- Bind ke karakter
local function bindCharacter()
	local char = LOCAL_PLAYER.Character or LOCAL_PLAYER.CharacterAdded:Wait()
	onCharacter(char)
end

-- Start
bindCharacter()
LOCAL_PLAYER.CharacterAdded:Connect(onCharacter)

-- Housekeeping (optional): pastikan UI tetap ada
RunService.Stepped:Connect(function()
	if not ScreenGui or not ScreenGui.Parent then
		createOverlay()
	end
end)
