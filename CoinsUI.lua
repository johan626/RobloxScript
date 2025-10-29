-- CoinsUI.lua (LocalScript)
-- Path: StarterGui/CoinsUI.lua
-- Script Place: Lobby
-- Revisi: Peningkatan Visual

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- Tambahkan TweenService

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CoinsUpdateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("CoinsUpdateEvent")

-- Hapus UI lama jika ada untuk mencegah duplikasi
if playerGui:FindFirstChild("CoinsUI") then
	playerGui.CoinsUI:Destroy()
end

-- ======================================================
-- PEMBUATAN UI
-- ======================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinsUI"
screenGui.Parent = playerGui
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Container utama di pojok kanan atas dengan desain baru
local container = Instance.new("Frame")
container.Name = "Container"
container.AnchorPoint = Vector2.new(0, 0)
container.Position = UDim2.new(0.524, 0, 0.007, 0)
container.Size = UDim2.new(0.15, 0, 0.1, 0)
container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
container.BackgroundTransparency = 0.1 -- Sedikit lebih transparan
container.BorderSizePixel = 0 -- Hapus border lama
container.Parent = screenGui

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0.01, 0)
padding.PaddingLeft = UDim.new(0.01, 0)
padding.PaddingBottom = UDim.new(0.01, 0)
padding.PaddingRight = UDim.new(0.01, 0)
padding.Parent = container

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10) -- Sudut lebih bulat
corner.Parent = container

-- Tambahkan stroke modern
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(150, 100, 180) -- Warna stroke ungu muda
stroke.Thickness = 2
stroke.Transparency = 0.5
stroke.Parent = container

-- Label untuk menampilkan jumlah koin dengan font dan posisi baru
local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "CoinsLabel"
coinsLabel.Size = UDim2.new(1, 0, 1, 0)
coinsLabel.Position = UDim2.new(0, 0, 0, 0) 
coinsLabel.Text = "🩸Blood Coins: ..."
coinsLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Warna merah muda terang
coinsLabel.Font = Enum.Font.GothamMedium -- Font lebih modern
coinsLabel.TextSize = 18 -- Ukuran teks spesifik
coinsLabel.TextScaled = true -- Matikan penskalaan otomatis
coinsLabel.TextXAlignment = Enum.TextXAlignment.Center -- Rata kiri
coinsLabel.TextYAlignment = Enum.TextYAlignment.Center -- Tengah vertikal
coinsLabel.BackgroundTransparency = 1
coinsLabel.ZIndex = 2
coinsLabel.Parent = container

-- ======================================================
-- LOGIKA UI
-- ======================================================

local currentCoins = 0 -- Untuk animasi hitung

-- Fungsi untuk memperbarui UI dengan animasi
local function updateCoinsUI(newCoins)
	if not newCoins then return end

	-- Hentikan tween yang sedang berjalan jika ada
	if container:FindFirstChild("CountTween") then
		container.CountTween:Cancel()
		container.CountTween:Destroy()
	end

	local startValue = currentCoins
	local diff = newCoins - startValue

	-- Buat NumberValue sementara untuk di-tween
	local tweenValue = Instance.new("NumberValue")
	tweenValue.Name = "CountTween"
	tweenValue.Value = startValue
	tweenValue.Parent = container

	-- Animasi hitung angka
	local countTween = TweenService:Create(tweenValue, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Value = newCoins})
	countTween:Play()

	-- Update teks label setiap frame selama tween berjalan
	local connection
	connection = tweenValue:GetPropertyChangedSignal("Value"):Connect(function()
		coinsLabel.Text = string.format("Blood Coins: %d", math.floor(tweenValue.Value + 0.5))
	end)

	-- Setelah tween selesai
	countTween.Completed:Connect(function()
		if connection then connection:Disconnect() end
		coinsLabel.Text = string.format("🩸Blood Coins: %d", newCoins) -- Pastikan nilai akhir benar
		currentCoins = newCoins -- Update nilai saat ini
		tweenValue:Destroy() -- Hapus NumberValue sementara
	end)

	-- Animasi highlight singkat saat koin bertambah
	if diff > 0 then
		local highlightTween = TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {BackgroundColor3 = Color3.fromRGB(75, 60, 80)})
		highlightTween:Play()
		-- Efek suara (opsional)
		-- local sound = Instance.new("Sound", container)
		-- sound.SoundId = "rbxassetid://YOUR_SOUND_ID" -- Ganti dengan ID suara
		-- sound.Volume = 0.5
		-- sound:Play()
		-- game:GetService("Debris"):AddItem(sound, 2)
	end
end

-- Dengarkan event dari server
CoinsUpdateEvent.OnClientEvent:Connect(updateCoinsUI)

-- Muat nilai awal (jika diperlukan)
-- Anda bisa menggunakan RemoteFunction untuk meminta nilai awal saat pemain masuk
-- Contoh:
-- local getInitialCoins = ReplicatedStorage.RemoteFunctions:WaitForChild("GetInitialCoins")
-- local initialCoins = getInitialCoins:InvokeServer()
-- updateCoinsUI(initialCoins)
-- Note: Pastikan RemoteFunction GetInitialCoins dibuat di server.
-- Untuk saat ini, kita anggap nilai awal akan dikirim oleh server via CoinsUpdateEvent.
