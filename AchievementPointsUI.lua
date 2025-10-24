-- AchievementPointsUI.lua (LocalScript)
-- Path: StarterGui/AchievementPointsUI.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hapus UI lama jika ada untuk mencegah duplikasi saat respawn
if playerGui:FindFirstChild("AchievementPointsUI") then
	playerGui.AchievementPointsUI:Destroy()
end

-- ======================================================
-- PEMBUATAN UI
-- ======================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AchievementPointsUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local pointsLabel = Instance.new("TextLabel")
pointsLabel.Name = "AchievementPointsLabel"
pointsLabel.Size = UDim2.new(0, 200, 0, 40)
pointsLabel.AnchorPoint = Vector2.new(1, 0)
-- Posisi di bawah Mission Points UI
pointsLabel.Position = UDim2.new(0.98, 0, 0.08, 0) 
pointsLabel.BackgroundColor3 = Color3.fromRGB(45, 48, 59)
pointsLabel.BackgroundTransparency = 0.3
pointsLabel.Font = Enum.Font.SourceSansBold
pointsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
pointsLabel.TextSize = 18
pointsLabel.Text = "AP: ..."
pointsLabel.TextXAlignment = Enum.TextXAlignment.Right
pointsLabel.Parent = screenGui

local labelCorner = Instance.new("UICorner", pointsLabel)
labelCorner.CornerRadius = UDim.new(0, 8)

local textPadding = Instance.new("UIPadding", pointsLabel)
textPadding.PaddingRight = UDim.new(0, 10)

-- ======================================================
-- LOGIKA UI
-- ======================================================

local getInitialAP = ReplicatedStorage:WaitForChild("GetInitialAchievementPoints")
local apChanged = ReplicatedStorage:WaitForChild("AchievementPointsChanged")

-- Fungsi untuk memperbarui teks label
local function updatePointsLabel(points)
	pointsLabel.Text = string.format("AP: %d", points)
end

-- Memuat poin awal saat skrip dimulai
local function loadInitialPoints()
	local success, initialPoints = pcall(function()
		return getInitialAP:InvokeServer()
	end)
	if success then
		updatePointsLabel(initialPoints)
	else
		warn("Gagal mendapatkan Achievement Points awal: ", initialPoints)
		pointsLabel.Text = "AP: Error"
	end
end

-- Mendengarkan perubahan poin dari server
apChanged.OnClientEvent:Connect(function(newPoints)
	updatePointsLabel(newPoints)
end)

-- Inisialisasi
loadInitialPoints()

print("Skrip UI Achievement Points berhasil dimuat.")
