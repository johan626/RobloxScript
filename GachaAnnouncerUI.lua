-- GachaAnnouncerUI.lua (LocalScript)
-- Path: StarterGui/GachaAnnouncerUI.lua
-- Script Place: Lobby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Tunggu RemoteEvent
local GachaSkinWonEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GachaSkinWonEvent")

-- ================== PEMBUATAN UI ==================
local announcerGui = Instance.new("ScreenGui")
announcerGui.Name = "GachaAnnouncerGUI"
announcerGui.ResetOnSpawn = false
announcerGui.Parent = player:WaitForChild("PlayerGui")

local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "AnnounceMessage"
messageLabel.Size = UDim2.new(0.8, 0, 0, 40)
messageLabel.Position = UDim2.new(0.5, 0, -0.1, 0) -- Mulai di luar layar
messageLabel.AnchorPoint = Vector2.new(0.5, 0)
messageLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
messageLabel.BackgroundTransparency = 0.4
messageLabel.BorderColor3 = Color3.fromRGB(255, 215, 0) -- Warna emas untuk border
messageLabel.BorderSizePixel = 2
messageLabel.Font = Enum.Font.SourceSansItalic
messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
messageLabel.TextSize = 22
messageLabel.TextWrapped = true
messageLabel.Parent = announcerGui

-- ================== LOGIKA SCRIPT ==================

local function showAnnouncement(winner, skinName)
	messageLabel.Text = string.format("[Gacha] %s baru saja mendapatkan skin legendaris: %s!", winner.DisplayName, skinName)

	-- Animasi masuk
	messageLabel:TweenPosition(
		UDim2.new(0.5, 0, 0.1, 0), -- Posisi akhir
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quint,
		0.5, -- Durasi
		true
	)

	-- Tunggu beberapa detik
	wait(5)

	-- Animasi keluar
	messageLabel:TweenPosition(
		UDim2.new(0.5, 0, -0.1, 0), -- Kembali ke posisi awal (di luar layar)
		Enum.EasingDirection.In,
		Enum.EasingStyle.Quint,
		0.5, -- Durasi
		true
	)
end

-- Event listener untuk menerima pengumuman
GachaSkinWonEvent.OnClientEvent:Connect(showAnnouncement)

print("GachaAnnouncerUI.lua loaded for player.")
