-- TitleManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/TitleManager.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

local TitleManager = {}

-- RemoteEvents & RemoteFunctions
if ReplicatedStorage:FindFirstChild("GetTitleData") then
	ReplicatedStorage.GetTitleData:Destroy()
end
local getTitleDataFunc = Instance.new("RemoteFunction", ReplicatedStorage)
getTitleDataFunc.Name = "GetTitleData"

local setEquippedTitleEvent = ReplicatedStorage:FindFirstChild("SetEquippedTitleEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
setEquippedTitleEvent.Name = "SetEquippedTitleEvent"

local titleChangedEvent = ReplicatedStorage:FindFirstChild("TitleChangedEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
titleChangedEvent.Name = "TitleChangedEvent"

-- =============================================================================
-- FUNGSI INTI
-- =============================================================================

function TitleManager.GetData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[TitleManager] Gagal mendapatkan data untuk pemain: " .. player.Name)
		return {}
	end

	-- Pastikan sub-tabel titles ada
	if not playerData.data.titles then
		local defaultData = require(script.Parent:WaitForChild("DataStoreManager")).DEFAULT_PLAYER_DATA
		playerData.data.titles = {}
		for k, v in pairs(defaultData.titles) do
			playerData.data.titles[k] = v
		end
		DataStoreManager:UpdatePlayerData(player, playerData.data)
	end

	return playerData.data.titles
end

function TitleManager.SaveData(player, titleData)
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.data then return end

	playerData.data.titles = titleData
	DataStoreManager:UpdatePlayerData(player, playerData.data)
end

-- =============================================================================
-- API PUBLIK
-- =============================================================================

function TitleManager.UnlockTitle(player, title)
	if not player or not title then return end
	local data = TitleManager.GetData(player)
	if table.find(data.UnlockedTitles, title) then return end -- Sudah dimiliki
	table.insert(data.UnlockedTitles, title)
	TitleManager.SaveData(player, data)
end

function TitleManager.SetEquippedTitle(player, titleToEquip)
	local data = TitleManager.GetData(player)

	if titleToEquip == "" or table.find(data.UnlockedTitles, titleToEquip) then
		data.EquippedTitle = titleToEquip
		TitleManager.SaveData(player, data)
		titleChangedEvent:FireAllClients(player, titleToEquip)
		return true
	else
		warn("Pemain " .. player.Name .. " mencoba menggunakan judul yang tidak dimiliki: " .. titleToEquip)
		return false
	end
end

-- =============================================================================
-- KONEKSI EVENT
-- =============================================================================

getTitleDataFunc.OnServerInvoke = function(invokingPlayer, targetPlayer)
	local playerToFetch = targetPlayer or invokingPlayer
	return TitleManager.GetData(playerToFetch)
end

setEquippedTitleEvent.OnServerEvent:Connect(function(player, titleToEquip)
	TitleManager.SetEquippedTitle(player, titleToEquip)
end)

return TitleManager
