-- GlobalNotificationClient.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/GlobalNotificationClient.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Cari RemoteEvent
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local notificationEvent = remoteEvents:WaitForChild("GlobalMissionNotification")

-- Fungsi untuk menampilkan notifikasi
local function onNotificationReceived(title, text)
	-- Gunakan API notifikasi bawaan Roblox
	StarterGui:SetCore("SendNotification", {
		Title = title,
		Text = text,
		Duration = 10, -- Notifikasi akan tampil selama 10 detik
		Icon = "rbxassetid://284402773", -- Ikon piala/trofi sebagai contoh
	})
end

-- Hubungkan fungsi ke event
notificationEvent.OnClientEvent:Connect(onNotificationReceived)

print("[GlobalNotificationClient] Berhasil terhubung ke event notifikasi misi global.")