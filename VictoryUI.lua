-- VictoryUI.lua (LocalScript)
-- Path: StarterGui/VictoryUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local MissionCompleteEvent = RemoteEvents:WaitForChild("MissionCompleteEvent")

-- Fungsi untuk membuat dan menampilkan UI kemenangan
local function showVictoryScreen()
	-- Pastikan UI tidak dibuat ganda
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	if playerGui:FindFirstChild("VictoryScreen") then return end

	-- Buat ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VictoryScreen"
	screenGui.Parent = playerGui
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	screenGui.IgnoreGuiInset = true -- Menutupi seluruh layar

	-- Buat latar belakang hitam transparan
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Parent = screenGui
	background.BackgroundColor3 = Color3.new(0, 0, 0)
	background.BackgroundTransparency = 0.5
	background.Size = UDim2.new(1, 0, 1, 0)
	background.Position = UDim2.new(0, 0, 0, 0)

	-- Buat judul "MISI SELESAI"
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Parent = background
	titleLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
	titleLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
	titleLabel.BackgroundColor3 = Color3.new(1, 1, 1)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.Text = "MISI SELESAI"
	titleLabel.TextColor3 = Color3.new(1, 0.84, 0) -- Emas
	titleLabel.TextScaled = true

	-- Buat sub-judul
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.Parent = background
	subtitleLabel.Size = UDim2.new(0.6, 0, 0.1, 0)
	subtitleLabel.Position = UDim2.new(0.2, 0, 0.5, 0)
	subtitleLabel.BackgroundColor3 = Color3.new(1, 1, 1)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Font = Enum.Font.SourceSans
	subtitleLabel.Text = "Anda akan kembali ke lobi dalam 10 detik."
	subtitleLabel.TextColor3 = Color3.new(1, 1, 1)
	subtitleLabel.TextScaled = true
end

-- Hubungkan fungsi ke event
MissionCompleteEvent.OnClientEvent:Connect(showVictoryScreen)
