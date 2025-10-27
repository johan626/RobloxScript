-- CoinsModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/CoinsModule.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

-- Modul lain
local StatsModule = require(script.Parent:WaitForChild("StatsModule"))
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))

local CoinsManager = {}

-- RemoteEvent
local CoinsUpdateEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("CoinsUpdateEvent") or Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
CoinsUpdateEvent.Name = "CoinsUpdateEvent"

-- =============================================================================
-- FUNGSI INTI
-- =============================================================================

function CoinsManager.GetData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[CoinsManager] Gagal mendapatkan data untuk pemain: " .. player.Name)
		return {} -- Kembalikan tabel kosong untuk mencegah error
	end

	-- Pastikan sub-tabel inventory ada
	if not playerData.data.inventory then
		-- Jika tidak ada, salin dari struktur default di DataStoreManager
		local defaultData = require(script.Parent:WaitForChild("DataStoreManager")).DEFAULT_PLAYER_DATA
		playerData.data.inventory = {}
		for k, v in pairs(defaultData.inventory) do
			playerData.data.inventory[k] = v
		end
		DataStoreManager:UpdatePlayerData(player, playerData.data)
	end

	local inventory = playerData.data.inventory
	local hasChanges = false

	-- Inisialisasi skin default untuk senjata yang mungkin belum ada di data pemain
	for weaponName, _ in pairs(WeaponModule.Weapons) do
		if not inventory.Skins.Owned[weaponName] then
			inventory.Skins.Owned[weaponName] = {"Default Skin"}
			hasChanges = true
		end
		if not inventory.Skins.Equipped[weaponName] then
			inventory.Skins.Equipped[weaponName] = "Default Skin"
			hasChanges = true
		end
	end

	if hasChanges then
		DataStoreManager:UpdatePlayerData(player, playerData.data)
	end

	return inventory
end

function CoinsManager.SaveData(player, inventoryData)
    local playerData = DataStoreManager:GetPlayerData(player)
    if not playerData or not playerData.data then return end

    playerData.data.inventory = inventoryData
    DataStoreManager:UpdatePlayerData(player, playerData.data)
end

-- =============================================================================
-- API PUBLIK
-- =============================================================================

function CoinsManager.AddCoins(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return end
	local data = CoinsManager.GetData(player)
	data.Coins += amount
	CoinsManager.SaveData(player, data)
	CoinsUpdateEvent:FireClient(player, data.Coins)
	StatsModule.AddCoin(player, amount)
	return data.Coins
end

function CoinsManager.SubtractCoins(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return false end
	local data = CoinsManager.GetData(player)
	if data.Coins < amount then return false end
	data.Coins -= amount
	CoinsManager.SaveData(player, data)
	CoinsUpdateEvent:FireClient(player, data.Coins)
	return true
end

function CoinsManager.AddSkin(player, weaponName, skinName)
	if not player or not weaponName or not skinName then return false end
	local data = CoinsManager.GetData(player)
	if table.find(data.Skins.Owned[weaponName], skinName) then return false end
	table.insert(data.Skins.Owned[weaponName], skinName)
	CoinsManager.SaveData(player, data)
	return true
end

function CoinsManager.UpdatePityCount(player, newCount)
	if not player or type(newCount) ~= "number" then return false end
	local data = CoinsManager.GetData(player)
	data.PityCount = newCount
	CoinsManager.SaveData(player, data)
	return true
end

function CoinsManager.UpdateLastFreeGachaClaim(player, timestamp)
	if not player or type(timestamp) ~= "number" then return false end
	local data = CoinsManager.GetData(player)
	data.LastFreeGachaClaimUTC = timestamp
	CoinsManager.SaveData(player, data)
	return true
end

-- =============================================================================
-- =-===========================================================================
-- KONEKSI EVENT
-- =============================================================================

local function onPlayerAdded(player)
    -- Memulai inisialisasi dalam thread baru.
    -- GetData akan secara internal menunggu data dimuat.
    task.spawn(function()
        local data = CoinsManager.GetData(player)
        CoinsUpdateEvent:FireClient(player, data.Coins)
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

return CoinsManager
