-- DamageDisplay.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/DamageDisplay.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DamageDisplayEvent = ReplicatedStorage.RemoteEvents:WaitForChild("DamageDisplayEvent")

-- Fungsi yang diperbarui untuk menerima model zombi
local function createDamageDisplay(damage, zombieModel, isHeadshot)
	-- Validasi bahwa kita memiliki model dan memiliki bagian Head
	if not zombieModel or not zombieModel:IsA("Model") or not zombieModel:FindFirstChild("Head") then
		return
	end

	local zombieHead = zombieModel.Head

	-- Atur ukuran awal dan akhir berdasarkan apakah itu headshot
	local startSize, endSize
	if isHeadshot then
		startSize = UDim2.new(0, 250, 0, 65) -- Ukuran headshot lebih besar
		endSize = UDim2.new(0, 150, 0, 40)
	else
		startSize = UDim2.new(0, 200, 0, 50) -- Ukuran normal
		endSize = UDim2.new(0, 100, 0, 25)
	end

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Adornee = zombieHead
	billboardGui.Size = startSize -- Ukuran awal yang lebih besar untuk efek "pop"
	-- Tentukan offset horizontal acak
	local randomXOffset = (math.random() * 6) - 3 -- Menyebar antara -3 dan 3 stud
	billboardGui.StudsOffset = Vector3.new(0, 2, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = zombieHead

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.Text = tostring(math.floor(damage))
	-- Merah terang untuk headshot, putih untuk tembakan biasa
	textLabel.TextColor3 = isHeadshot and Color3.fromRGB(255, 80, 80) or Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.TextStrokeTransparency = 0
	textLabel.BackgroundTransparency = 1
	textLabel.Parent = billboardGui

	-- Animasikan GUI
	local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Tujuan animasi: bergerak ke atas dengan offset X, mengecil, dan memudar
	local goal = {
		StudsOffset = Vector3.new(randomXOffset, 8, 0), -- Bergerak ke atas dan menyebar
		Size = endSize -- Mengecil
	}

	local goalFade = {
		TextStrokeTransparency = 1,
		TextTransparency = 1
	}

	local tweenMoveAndResize = TweenService:Create(billboardGui, tweenInfo, goal)
	local tweenFade = TweenService:Create(textLabel, tweenInfo, goalFade)

	tweenMoveAndResize:Play()
	tweenFade:Play()

	Debris:AddItem(billboardGui, 1.3)
end

DamageDisplayEvent.OnClientEvent:Connect(createDamageDisplay)
