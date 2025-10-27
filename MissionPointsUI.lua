-- MissionPointsUI.lua (LocalScript)
-- Path: StarterGui/MissionPointsUI.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hapus UI lama jika ada untuk mencegah duplikasi saat respawn
if playerGui:FindFirstChild("MissionPointsUI") then
	playerGui.MissionPointsUI:Destroy()
end

-- ======================================================
-- PEMBUATAN UI
-- ======================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MissionPointsUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local pointsLabel = Instance.new("TextLabel")
pointsLabel.Name = "MissionPointsLabel"
pointsLabel.Size = UDim2.new(0.15, 0, 0.1, 0)
pointsLabel.Position = UDim2.new(0.518, 0, 0.017, 0) -- Di pojok kanan atas
pointsLabel.BackgroundColor3 = Color3.fromRGB(45, 48, 59)
pointsLabel.BackgroundTransparency = 0.3
pointsLabel.Font = Enum.Font.SourceSansBold
pointsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
pointsLabel.TextSize = 18
pointsLabel.Text = "MP: ..."
pointsLabel.TextScaled = true
pointsLabel.TextXAlignment = Enum.TextXAlignment.Center
pointsLabel.TextYAlignment = Enum.TextYAlignment.Center
pointsLabel.Parent = screenGui

local labelCorner = Instance.new("UICorner", pointsLabel)
labelCorner.CornerRadius = UDim.new(0.15, 0)

-- ======================================================
-- LOGIKA UI
-- ======================================================

local getInitialMissionPoints = ReplicatedStorage:WaitForChild("GetInitialMissionPoints")
local missionPointsChanged = ReplicatedStorage:WaitForChild("MissionPointsChanged")

-- Fungsi untuk memperbarui teks label
local function updatePointsLabel(points)
	pointsLabel.Text = string.format("MP: %d", points)
end

-- Memuat poin awal saat skrip dimulai
local function loadInitialPoints()
	local success, initialPoints = pcall(function()
		return getInitialMissionPoints:InvokeServer()
	end)
	if success then
		updatePointsLabel(initialPoints)
	else
		warn("Gagal mendapatkan Mission Points awal: ", initialPoints)
		pointsLabel.Text = "MP: Error"
	end
end

-- Mendengarkan perubahan poin dari server
missionPointsChanged.OnClientEvent:Connect(function(newPoints)
	updatePointsLabel(newPoints)
end)

-- Inisialisasi
loadInitialPoints()

print("Skrip UI Mission Points berhasil dimuat.")
