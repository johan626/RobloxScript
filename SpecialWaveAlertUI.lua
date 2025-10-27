-- SpecialWaveAlertUI.lua (LocalScript)
-- Path: StarterGui/SpecialWaveAlertUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local specialWaveAlertEvent = RemoteEvents:WaitForChild("SpecialWaveAlertEvent")

-- Konfigurasi untuk setiap tipe gelombang
local waveConfigs = {
	["Blood Moon"] = {
		Title = "BLOOD MOON",
		Color = Color3.fromRGB(200, 0, 0),
		Icon = "🩸",
	},
	["Fast Wave"] = {
		Title = "FAST WAVE!",
		Color = Color3.fromRGB(255, 150, 0),
		Icon = "💨",
	},
	["Special Wave"] = {
		Title = "SPECIAL WAVE!",
		Color = Color3.fromRGB(150, 0, 255),
		Icon = "✨",
	}
}

local function showAlert(waveType)
	local config = waveConfigs[waveType]
	if not config then
		warn("Tipe gelombang tidak dikenal:", waveType)
		return
	end

	-- Buat ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpecialWaveAlertUI"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = gui

	-- Buat kontainer utama
	local container = Instance.new("Frame")
	container.Name = "AlertContainer"
	container.Size = UDim2.new(0.6, 0, 0.2, 0)
	container.Position = UDim2.new(0.5, 0, -0.25, 0) -- Mulai di luar layar atas
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	container.BackgroundTransparency = 0.2
	container.BorderSizePixel = 0
	container.Parent = screenGui
	container.ZIndex = 10

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = config.Color
	stroke.Thickness = 4
	stroke.Transparency = 0.5
	stroke.Parent = container

	-- Buat ikon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0.2, 0, 0.8, 0)
	iconLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = config.Icon
	iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBlack
	iconLabel.Parent = container

	-- Buat teks judul
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(0.7, 0, 0.6, 0)
	titleLabel.Position = UDim2.new(0.25, 0, 0.2, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = config.Title
	titleLabel.TextColor3 = config.Color
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextStrokeTransparency = 0.8
	titleLabel.Parent = container

	-- Animasi Masuk
	local function animateIn()
		container.Position = UDim2.new(0.5, 0, 0.15, 0) -- Posisi awal sebelum animasi
		container.Size = UDim2.new(0, 0, 0, 0)
		container.AnchorPoint = Vector2.new(0.5, 0.5)

		local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
		local goal = {
			Size = UDim2.new(0.6, 0, 0.2, 0),
			Position = UDim2.new(0.5, 0, 0.2, 0)
		}
		local tween = TweenService:Create(container, tweenInfo, goal)
		tween:Play()
	end

	-- Animasi Keluar
	local function animateOut()
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
		local goal = {
			Position = UDim2.new(0.5, 0, -0.3, 0),
		}
		local tween = TweenService:Create(container, tweenInfo, goal)
		tween:Play()

		tween.Completed:Connect(function()
			screenGui:Destroy()
		end)
	end

	-- Jalankan animasi
	animateIn()

	-- Tunggu beberapa detik sebelum menghilang
	task.wait(4)
	animateOut()
end

-- Dengarkan event dari server
specialWaveAlertEvent.OnClientEvent:Connect(showAlert)
