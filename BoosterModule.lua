-- BoosterModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BoosterModule.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

-- Modul lain
local BoosterConfig = require(script.Parent:WaitForChild("BoosterConfig"))
local StatsModule = require(script.Parent:WaitForChild("StatsModule"))

local BoosterModule = {}

-- RemoteEvents
local BoosterUpdateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BoosterUpdateEvent")
local UpdatePlayerBoosterStatusEvent = ReplicatedStorage.RemoteEvents:WaitForChild("UpdatePlayerBoosterStatusEvent")
local ActivateBoosterEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ActivateBoosterEvent")

-- Struktur data default
local DEFAULT_BOOSTERS = {
	Owned = {},
	Active = nil
}

-- =============================================================================
-- FUNGSI INTI
-- =============================================================================

function BoosterModule.GetData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[BoosterModule] Gagal mendapatkan data bahkan setelah menunggu untuk pemain: " .. player.Name)
		return table.clone(DEFAULT_BOOSTERS)
	end

	if not playerData.data.boosters then
		playerData.data.boosters = table.clone(DEFAULT_BOOSTERS)
	end

	local boosters = playerData.data.boosters
	local hasChanges = false

	-- Pastikan semua booster dari config ada di data pemain
	for boosterName, _ in pairs(BoosterConfig) do
		if boosters.Owned[boosterName] == nil then
			boosters.Owned[boosterName] = 0
			hasChanges = true
		end
	end

	if hasChanges then
		BoosterModule.SaveData(player, boosters)
	end

	return boosters
end

function BoosterModule.SaveData(player, boostersData)
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.data then return end

	playerData.data.boosters = boostersData
	DataStoreManager:UpdatePlayerData(player, playerData.data)
end

-- =============================================================================
-- API PUBLIK
-- =============================================================================

function BoosterModule.AddBooster(player, boosterName, amount)
	if not player or not BoosterConfig[boosterName] or not tonumber(amount) then return false end
	local data = BoosterModule.GetData(player)
	data.Owned[boosterName] = (data.Owned[boosterName] or 0) + amount
	BoosterModule.SaveData(player, data)
	BoosterUpdateEvent:FireClient(player, data)
	return true
end

function BoosterModule.ActivateBooster(player, boosterName)
	if not player or (boosterName and not BoosterConfig[boosterName]) then return end
	local data = BoosterModule.GetData(player)

	if data.Active == boosterName then -- Unequip
		data.Active = nil
	elseif boosterName and data.Owned[boosterName] > 0 then -- Equip
		data.Active = boosterName
	else -- Gagal equip
		return
	end

	BoosterModule.SaveData(player, data)
	BoosterUpdateEvent:FireClient(player, data)
	UpdatePlayerBoosterStatusEvent:FireAllClients(player.UserId, data.Active)
end

function BoosterModule.UseActiveBooster(player)
	local data = BoosterModule.GetData(player)
	local activeBooster = data.Active

	if not activeBooster or (data.Owned[activeBooster] or 0) <= 0 then
		return nil
	end

	data.Owned[activeBooster] -= 1
	data.Active = nil
	BoosterModule.SaveData(player, data)

	StatsModule.IncrementStat(player, "BoostersUsed", 1)
	BoosterUpdateEvent:FireClient(player, data)
	UpdatePlayerBoosterStatusEvent:FireAllClients(player.UserId, data.Active)

	return activeBooster
end

-- =============================================================================
-- KONEKSI EVENT
-- =============================================================================

local function initializePlayerData(player)
	task.spawn(function()
		local data = BoosterModule.GetData(player)
		BoosterUpdateEvent:FireClient(player, data)
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

ActivateBoosterEvent.OnServerEvent:Connect(function(player, boosterName)
	BoosterModule.ActivateBooster(player, boosterName)
end)

return BoosterModule
