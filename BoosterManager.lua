-- BoosterManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BoosterManager.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

local BoosterManager = {}

function BoosterManager.GetBoosterData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then return {} end

	if not playerData.data.boosters then
		playerData.data.boosters = { Owned = {}, Active = {} }
		DataStoreManager:UpdatePlayerData(player, playerData.data)
	end

	return playerData.data.boosters
end

function BoosterManager.SaveData(player, boosterData)
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.data then return end

	playerData.data.boosters = boosterData
	DataStoreManager:UpdatePlayerData(player, playerData.data)
end

function BoosterManager.AddBooster(player, itemID, itemConfig)
	local data = BoosterManager.GetBoosterData(player)

	if not data.Owned[itemID] then
		data.Owned[itemID] = 0
	end
	data.Owned[itemID] += 1

	BoosterManager.SaveData(player, data)
	-- Di masa depan, kita bisa mengirim event ke client untuk update UI di sini
end

-- Fungsi ini akan dipanggil oleh UI pemain untuk mengaktifkan booster
function BoosterManager:ActivateBooster(player, itemID)
	local data = self.GetBoosterData(player)

	if not data.Owned[itemID] or data.Owned[itemID] <= 0 then
		return { Success = false, Reason = "Anda tidak memiliki booster ini." }
	end

	-- Hapus dari inventaris
	data.Owned[itemID] -= 1

	-- Tambahkan ke booster aktif
	local config = require(script.Parent:WaitForChild("MPShopConfig")).Items[itemID]
	if config.Duration then -- Booster berbasis waktu
		data.Active[itemID] = { EndTime = os.time() + config.Duration }
	else -- Booster berbasis game
		data.Active[itemID] = { GamesRemaining = 1 }
	end

	self.SaveData(player, data)
	return { Success = true }
end

function BoosterManager.IsBoosterActive(player, itemID)
	local data = BoosterManager.GetBoosterData(player)
	local activeBooster = data.Active[itemID]

	if not activeBooster then return false end

	if activeBooster.EndTime and os.time() < activeBooster.EndTime then
		return true
	elseif activeBooster.GamesRemaining and activeBooster.GamesRemaining > 0 then
		return true
	end

	-- Booster sudah kedaluwarsa, hapus
	data.Active[itemID] = nil
	BoosterManager.SaveData(player, data)
	return false
end

function BoosterManager.ConsumeGameBooster(player, itemID)
	local data = BoosterManager.GetBoosterData(player)
	local activeBooster = data.Active[itemID]

	if activeBooster and activeBooster.GamesRemaining then
		activeBooster.GamesRemaining -= 1
		if activeBooster.GamesRemaining <= 0 then
			data.Active[itemID] = nil
		end
		BoosterManager.SaveData(player, data)
	end
end

-- RemoteFunction untuk aktivasi
local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
local activateBoosterFunc = Instance.new("RemoteFunction", remoteFunctions)
activateBoosterFunc.Name = "ActivateBooster"
activateBoosterFunc.OnServerInvoke = function(player, itemID)
	return BoosterManager:ActivateBooster(player, itemID)
end

return BoosterManager
