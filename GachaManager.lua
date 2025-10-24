-- GachaManager.lua (Script)
-- Path: ServerScriptService/Script/GachaManager.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

-- Memuat modul yang diperlukan
local GachaModule = require(ServerScriptService.ModuleScript:WaitForChild("GachaModule"))
local GachaConfig = require(ServerScriptService.ModuleScript:WaitForChild("GachaConfig"))

-- Mencari RemoteFunction untuk mengambil konfigurasi
local getConfigFuncName = "GetGachaConfig"
local GetGachaConfig = ReplicatedStorage.RemoteFunctions:FindFirstChild(getConfigFuncName)
if not GetGachaConfig then
	GetGachaConfig = Instance.new("RemoteFunction", ReplicatedStorage.RemoteFunctions)
	GetGachaConfig.Name = getConfigFuncName
end

-- Atur callback untuk RemoteFunction
GetGachaConfig.OnServerInvoke = function(player)
	-- Hanya kirim data yang aman untuk dilihat klien
	return GachaConfig.RARITY_CHANCES
end

-- Mencari RemoteEvent untuk komunikasi gacha
local gachaEventName = "GachaRollEvent"
local GachaRollEvent = ReplicatedStorage.RemoteEvents:FindFirstChild(gachaEventName)
if not GachaRollEvent then
	GachaRollEvent = Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
	GachaRollEvent.Name = gachaEventName
end

-- Fungsi ini akan dieksekusi ketika client mengirim permintaan roll dari UI
-- [MODIFIED] Fungsi ini sekarang menerima 'weaponName' dari klien
local function onGachaRollRequested(player, weaponName)
	-- Panggil fungsi Roll dari GachaModule secara aman menggunakan pcall, teruskan weaponName
	local success, resultOrError = pcall(GachaModule.Roll, player, weaponName)

	if success then
		GachaRollEvent:FireClient(player, resultOrError)
	else
		warn("GachaManager Error: Terjadi error saat menjalankan GachaModule.Roll - " .. tostring(resultOrError))
		local errorResult = {
			Success = false,
			Message = "Terjadi kesalahan internal pada server. Silakan coba lagi nanti."
		}
		GachaRollEvent:FireClient(player, errorResult)
	end
end

GachaRollEvent.OnServerEvent:Connect(onGachaRollRequested)

-- Endpoint untuk Multi-Roll
local gachaMultiRollEventName = "GachaMultiRollEvent"
local GachaMultiRollEvent = ReplicatedStorage.RemoteEvents:FindFirstChild(gachaMultiRollEventName)
if not GachaMultiRollEvent then
	GachaMultiRollEvent = Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
	GachaMultiRollEvent.Name = gachaMultiRollEventName
end

-- [MODIFIED] Fungsi ini sekarang menerima 'weaponName' dari klien
local function onGachaMultiRollRequested(player, weaponName)
	-- Panggil fungsi RollMultiple dari GachaModule, teruskan weaponName
	local success, resultOrError = pcall(GachaModule.RollMultiple, player, weaponName)
	if success then
		GachaMultiRollEvent:FireClient(player, resultOrError)
	else
		warn("GachaManager Error: Terjadi error saat menjalankan GachaModule.RollMultiple - " .. tostring(resultOrError))
		local errorResult = {
			Success = false,
			Message = "Terjadi kesalahan internal pada server. Silakan coba lagi nanti."
		}
		GachaMultiRollEvent:FireClient(player, errorResult)
	end
end

GachaMultiRollEvent.OnServerEvent:Connect(onGachaMultiRollRequested)

-- Endpoint untuk Free Daily Roll
local gachaFreeRollEventName = "GachaFreeRollEvent"
local GachaFreeRollEvent = ReplicatedStorage.RemoteEvents:FindFirstChild(gachaFreeRollEventName)
if not GachaFreeRollEvent then
	GachaFreeRollEvent = Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
	GachaFreeRollEvent.Name = gachaFreeRollEventName
end

-- [MODIFIED] Fungsi ini sekarang menerima 'weaponName' dari klien
local function onGachaFreeRollRequested(player, weaponName)
	-- Panggil fungsi RollFreeDaily dari GachaModule, teruskan weaponName
	local success, resultOrError = pcall(GachaModule.RollFreeDaily, player, weaponName)
	if success then
		-- Hasil dari RollFreeDaily memiliki format yang sama dengan Roll tunggal
		GachaRollEvent:FireClient(player, resultOrError)
	else
		warn("GachaManager Error: Terjadi error saat menjalankan GachaModule.RollFreeDaily - " .. tostring(resultOrError))
		local errorResult = {
			Success = false,
			Message = "Terjadi kesalahan internal pada server saat mencoba roll gratis."
		}
		GachaRollEvent:FireClient(player, errorResult)
	end
end

GachaFreeRollEvent.OnServerEvent:Connect(onGachaFreeRollRequested)

-- RemoteFunction untuk mendapatkan status gacha pemain
local getGachaStatusFuncName = "GetGachaStatus"
local GetGachaStatus = ReplicatedStorage.RemoteFunctions:FindFirstChild(getGachaStatusFuncName)
if not GetGachaStatus then
	GetGachaStatus = Instance.new("RemoteFunction", ReplicatedStorage.RemoteFunctions)
	GetGachaStatus.Name = getGachaStatusFuncName
end

GetGachaStatus.OnServerInvoke = function(player)
	local playerData = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule")).GetData(player)
	if playerData then
		return {
			PityCount = playerData.PityCount,
			LastFreeGachaClaimUTC = playerData.LastFreeGachaClaimUTC,
			PityThreshold = GachaConfig.PITY_THRESHOLD
		}
	end
	return nil
end

-- Hapus koneksi ke ProximityPrompt dari sisi server
-- Kode di bawah ini tidak lagi diperlukan dan telah dihapus.
-- local gachaShopPart = Workspace:WaitForChild("GachaShopSkin")
-- ... proximityPrompt.Triggered:Connect(...)

print("GachaManager.lua now correctly listening to GachaRollEvent from the client.")
