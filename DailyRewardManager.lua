-- DailyRewardManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/DailyRewardManager.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Muat modul yang diperlukan
local DailyRewardConfig = require(ReplicatedStorage.ModuleScript:WaitForChild("DailyRewardConfig"))
local CoinsModule = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))
local BoosterModule = require(ServerScriptService.ModuleScript:WaitForChild("BoosterModule"))
local SkinManager = require(ServerScriptService.ModuleScript:WaitForChild("SkinManager"))
local StatsModule = require(ServerScriptService.ModuleScript:WaitForChild("StatsModule"))

local DailyRewardManager = {}

-- Konstanta
local THREE_DAYS_IN_SECONDS = 3 * 24 * 60 * 60
local ONE_DAY_IN_SECONDS = 24 * 60 * 60

-- Fungsi untuk mendapatkan status hadiah harian pemain dari StatsModule
function DailyRewardManager:GetPlayerState(player)
	local playerData = StatsModule.GetData(player)
	if not playerData then
		warn("Gagal mendapatkan data Stats untuk pemain: " .. player.Name)
		return nil
	end

	local lastClaimTimestamp = playerData.DailyRewardLastClaim or 0
	local currentDay = playerData.DailyRewardCurrentDay or 1

	-- Cek apakah sudah waktunya untuk reset karena tidak aktif
	local timeSinceLastClaim = os.time() - lastClaimTimestamp
	if lastClaimTimestamp > 0 and timeSinceLastClaim > THREE_DAYS_IN_SECONDS then
		print("Pemain " .. player.Name .. " tidak aktif lebih dari 3 hari. Mereset progres hadiah harian.")
		currentDay = 1
		playerData.DailyRewardCurrentDay = currentDay
		playerData.DailyRewardLastClaim = 0 -- Reset last claim untuk bisa klaim hari ke-1
		lastClaimTimestamp = 0 -- Update variabel lokal juga
		StatsModule.SaveData(player, playerData)
	end

	-- Tentukan apakah pemain bisa mengklaim hadiah hari ini
	local canClaim = false
	if lastClaimTimestamp == 0 then
		canClaim = true
	else
		local lastClaimDay = math.floor(lastClaimTimestamp / ONE_DAY_IN_SECONDS)
		local currentOsDay = math.floor(os.time() / ONE_DAY_IN_SECONDS)
		if currentOsDay > lastClaimDay then
			canClaim = true
		end
	end

	return {
		CurrentDay = currentDay,
		CanClaim = canClaim
	}
end

-- Fungsi untuk memberikan hadiah kepada pemain
function DailyRewardManager:ClaimReward(player)
	local playerState = self:GetPlayerState(player)

	if not playerState or not playerState.CanClaim then
		warn("Pemain " .. player.Name .. " mencoba mengklaim hadiah tetapi tidak memenuhi syarat.")
		return { Success = false, Reason = "Tidak memenuhi syarat" }
	end

	local currentDay = playerState.CurrentDay
	if currentDay > #DailyRewardConfig.Rewards then
		currentDay = 1
	end

	local rewardInfo = DailyRewardConfig.Rewards[currentDay]
	if not rewardInfo then
		warn("Tidak ada konfigurasi hadiah untuk hari ke-" .. currentDay)
		return { Success = false, Reason = "Konfigurasi hadiah tidak ditemukan" }
	end

	local actualReward
	-- Cek apakah ini hadiah misteri
	if rewardInfo.Type == "Mystery" then
		local mysteryRewards = DailyRewardConfig.MysteryRewards
		if mysteryRewards and #mysteryRewards > 0 then
			local randomIndex = math.random(1, #mysteryRewards)
			actualReward = mysteryRewards[randomIndex]
			print("Hadiah misteri untuk " .. player.Name .. " terpilih: " .. actualReward.Type)
		else
			warn("Kumpulan Hadiah Misteri kosong atau tidak ada. Memberikan hadiah fallback.")
			-- Fallback ke hadiah koin kecil jika terjadi kesalahan konfigurasi
			actualReward = { Type = "Coins", Value = 100 }
		end
	else
		actualReward = rewardInfo
	end

	-- Berikan hadiah berdasarkan tipenya
	if actualReward.Type == "Coins" then
		CoinsModule.AddCoins(player, actualReward.Value)
	elseif actualReward.Type == "Booster" then
		BoosterModule.AddBooster(player, actualReward.Value, 1)
	elseif actualReward.Type == "Skin" then
		SkinManager.GiveRandomSkin(player)
	end

	-- Perbarui data pemain melalui StatsModule
	local playerData = StatsModule.GetData(player)
	if not playerData then
		warn("Gagal mendapatkan data Stats untuk menyimpan progres hadiah: " .. player.Name)
		return { Success = false, Reason = "Gagal menyimpan data" }
	end

	local nextDay = currentDay + 1
	if nextDay > #DailyRewardConfig.Rewards then
		nextDay = 1
	end

	playerData.DailyRewardLastClaim = os.time()
	playerData.DailyRewardCurrentDay = nextDay

	StatsModule.SaveData(player, playerData)

	return { Success = true, ClaimedReward = actualReward, NextDay = nextDay }
end

return DailyRewardManager
