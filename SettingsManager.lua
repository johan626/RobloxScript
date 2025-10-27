-- SettingsManager.lua (Script)
-- Path: ServerScriptService/SettingsManager.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))

local UpdateSettingsEvent = ReplicatedStorage.RemoteEvents:WaitForChild("UpdateSettingsEvent")
local LoadSettingsEvent = ReplicatedStorage.RemoteEvents:WaitForChild("LoadSettingsEvent")

-- Fungsi validasi mendalam untuk UDim2 yang disimpan sebagai tabel
local function validateUDim2(udimTable)
	if type(udimTable) ~= "table" then return false end
	if type(udimTable.X) ~= "table" or type(udimTable.Y) ~= "table" then return false end
	if type(udimTable.X.Scale) ~= "number" or type(udimTable.X.Offset) ~= "number" then return false end
	if type(udimTable.Y.Scale) ~= "number" or type(udimTable.Y.Offset) ~= "number" then return false end
	return true
end

-- Fungsi untuk memvalidasi data pengaturan yang diterima dari klien
local function validateSettings(settings)
	if type(settings) ~= "table" then return nil end

	-- Validasi suara
	if type(settings.sound) ~= "table" then return nil, "Invalid sound table" end
	local sound = settings.sound
	if type(sound.enabled) ~= "boolean" then return nil, "Invalid sound.enabled" end
	if type(sound.sfxVolume) ~= "number" or not (sound.sfxVolume >= 0 and sound.sfxVolume <= 1) then return nil, "Invalid sfxVolume" end

	-- Validasi kontrol (opsional, tapi jika ada, harus benar)
	if settings.controls then
		if type(settings.controls) ~= "table" then return nil, "Invalid controls table" end
		local controls = settings.controls
		if controls.fireControlType and not (controls.fireControlType == "FireButton" or controls.fireControlType == "DoubleTap") then
			return nil, "Invalid fireControlType"
		end
	end

	-- Validasi HUD
	if type(settings.hud) ~= "table" then return nil, "Invalid hud table" end
	for elementName, data in pairs(settings.hud) do
		if type(data) ~= "table" then return nil, "Invalid hud element data" end
		if not validateUDim2(data.pos) or not validateUDim2(data.size) then
			warn("Data HUD tidak valid untuk elemen: " .. tostring(elementName))
			return nil, "Invalid hud UDim2 data"
		end
	end

	return settings
end


-- Fungsi untuk mengubah tabel kembali menjadi UDim2
local function deserializeUDim2(tbl)
	return UDim2.new(tbl.X.Scale, tbl.X.Offset, tbl.Y.Scale, tbl.Y.Offset)
end


-- Saat klien mengirim pembaruan pengaturan
UpdateSettingsEvent.OnServerEvent:Connect(function(player, clientSettings)
	-- Klien sekarang mengirim data yang sudah diserialisasi
	local validatedSettings, reason = validateSettings(clientSettings)
	if not validatedSettings then
		warn("Pembaruan pengaturan ditolak untuk " .. player.Name .. " karena data tidak valid: " .. (reason or "Unknown"))
		return
	end

	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.data then
		warn("Tidak dapat menyimpan pengaturan karena data pemain belum dimuat untuk " .. player.Name)
		return
	end

	-- Pastikan tabel pengaturan ada
	if not playerData.data.settings then
		playerData.data.settings = {}
	end

	-- Gabungkan pengaturan yang divalidasi
	playerData.data.settings.sound = validatedSettings.sound
	playerData.data.settings.hud = validatedSettings.hud
	playerData.data.settings.controls = validatedSettings.controls or { fireControlType = "FireButton" } -- Default jika tidak ada

	DataStoreManager:UpdatePlayerData(player, playerData.data)
	print("Pengaturan berhasil disimpan untuk " .. player.Name)
end)


-- Fungsi untuk mengirim pengaturan ke pemain
local function sendSettingsToClient(player)
	DataStoreManager:OnPlayerDataLoaded(player, function(playerData)
		if playerData and playerData.data and playerData.data.settings then
			local settings = playerData.data.settings
			-- Ubah kembali data HUD yang disimpan ke format UDim2 sebelum mengirim ke klien
			local settingsToSend = {
				sound = settings.sound,
				controls = settings.controls or { fireControlType = "FireButton" }, -- Kirim default jika tidak ada
				hud = {}
			}
			if settings.hud then
				for name, data in pairs(settings.hud) do
					settingsToSend.hud[name] = {
						pos = deserializeUDim2(data.pos),
						size = deserializeUDim2(data.size)
					}
				end
			end
			LoadSettingsEvent:FireClient(player, settingsToSend)
			print("Pengaturan yang ada telah dikirim ke " .. player.Name)
		else
			print("Tidak ada data pengaturan custom untuk " .. player.Name .. ". Klien akan menggunakan default.")
			-- Kirim pengaturan default jika tidak ada sama sekali
			LoadSettingsEvent:FireClient(player, {
				sound = { enabled = true, sfxVolume = 0.8 },
				controls = { fireControlType = "FireButton" },
				hud = {}
			})
		end
	end)
end


Players.PlayerAdded:Connect(sendSettingsToClient)
for _, player in ipairs(Players:GetPlayers()) do
	sendSettingsToClient(player)
end
