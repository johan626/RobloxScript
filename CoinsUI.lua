-- CoinsUI.lua (LocalScript)
-- Path: StarterGui/CoinsUI.lua
-- Script Place: Lobby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CoinsUpdateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("CoinsUpdateEvent")

-- Buat UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinsUI"
screenGui.Parent = playerGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Container utama di pojok kanan atas
local container = Instance.new("Frame")
container.Name = "Container"
container.AnchorPoint = Vector2.new(1, 0) -- Jangkar di pojok kanan atas frame
container.Position = UDim2.new(1, -10, 0, 10) -- Posisi di pojok kanan atas layar dengan padding
container.Size = UDim2.new(0, 180, 0, 40)
container.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
container.BorderColor3 = Color3.fromRGB(255, 80, 80)
container.BorderSizePixel = 1
container.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = container

-- Label untuk menampilkan jumlah koin
local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "CoinsLabel"
coinsLabel.Size = UDim2.new(1, 0, 1, 0)
coinsLabel.Text = "Blood Coins: 0"
coinsLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
coinsLabel.TextScaled = true
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.BackgroundTransparency = 1
coinsLabel.Parent = container

-- Fungsi untuk memperbarui UI
local function updateCoinsUI(coins)
	if coins then
		coinsLabel.Text = string.format("Blood Coins: %d", coins)
	end
end

-- Dengarkan event dari server
CoinsUpdateEvent.OnClientEvent:Connect(updateCoinsUI)
