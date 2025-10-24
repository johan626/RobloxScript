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

-- Struktur data default
local DEFAULT_INVENTORY = {
	Coins = 0,
	Skins = { Owned = {}, Equipped = {} },
	PityCount = 0,
	LastFreeGachaClaimUTC = 0
}

-- =============================================================================
-- FUNGSI INTI
-- =============================================================================

function CoinsManager.GetData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[CoinsManager] Gagal mendapatkan data bahkan setelah menunggu untuk pemain: " .. player.Name)
		return table.clone(DEFAULT_INVENTORY)
	end

	if not playerData.data.inventory then
		playerData.data.inventory = table.clone(DEFAULT_INVENTORY)
	end

	local inventory = playerData.data.inventory
	local hasChanges = false

	-- Validasi dan migrasi data
	for key, value in pairs(DEFAULT_INVENTORY) do
		if inventory[key] == nil then
			inventory[key] = value
			hasChanges = true
		end
	end

	-- Inisialisasi skin default
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
		CoinsManager.SaveData(player, inventory)
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

local function initializePlayerData(player)
	task.spawn(function()
		local data = CoinsManager.GetData(player)
		CoinsUpdateEvent:FireClient(player, data.Coins)
	end)
end

Players.PlayerAdded:Connect(function(player)
	DataStoreManager:OnPlayerDataLoaded(player, function()
		initializePlayerData(player)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	DataStoreManager:OnPlayerDataLoaded(player, function()
		initializePlayerData(player)
	end)
end

return CoinsManager
