-- GachaModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/GachaModule.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Memuat modul yang diperlukan
local CoinsManager = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))
local GachaConfig = require(ServerScriptService.ModuleScript:WaitForChild("GachaConfig"))
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))
local BoosterModule = require(ServerScriptService.ModuleScript:WaitForChild("BoosterModule"))
local StatsModule = require(ServerScriptService.ModuleScript:WaitForChild("StatsModule"))

local GachaModule = {}

-- Fungsi untuk mendapatkan daftar semua skin yang *belum* dimiliki pemain
-- [MODIFIED] Fungsi untuk mendapatkan daftar skin yang belum dimiliki pemain UNTUK SENJATA TERTENTU
local function getAvailableSkinsForWeapon(player, weaponName)
	local inventoryData = CoinsManager.GetData(player)
	local ownedSkins = inventoryData.Skins.Owned
	local availableSkins = {}

	-- Validasi apakah nama senjata ada di WeaponModule
	if not WeaponModule.Weapons[weaponName] then
		warn("GachaModule: Senjata '" .. tostring(weaponName) .. "' tidak ditemukan di WeaponModule.")
		return availableSkins -- Kembalikan tabel kosong
	end

	local weaponData = WeaponModule.Weapons[weaponName]
	for skinName, _ in pairs(weaponData.Skins) do
		if skinName ~= "Default Skin" then
			-- Cek apakah pemain sudah memiliki skin ini
			local hasSkin = false
			if ownedSkins[weaponName] then
				for _, ownedSkinName in ipairs(ownedSkins[weaponName]) do
					if ownedSkinName == skinName then
						hasSkin = true
						break
					end
				end
			end

			-- Jika belum dimiliki, tambahkan ke daftar
			if not hasSkin then
				table.insert(availableSkins, {Weapon = weaponName, Skin = skinName})
			end
		end
	end

	return availableSkins
end

-- RemoteEvent untuk pengumuman global (tidak ada perubahan di sini)
local GachaSkinWonEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("GachaSkinWonEvent")
if not GachaSkinWonEvent then
	GachaSkinWonEvent = Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
	GachaSkinWonEvent.Name = "GachaSkinWonEvent"
end

-- [MODIFIED] Fungsi inti untuk melakukan roll gacha, sekarang menerima weaponName
local function performSingleRoll(player, playerData, weaponName)
	-- 1. Logika Pity (Tetap Global)
	playerData.PityCount = (playerData.PityCount or 0) + 1
	local isPityTriggered = playerData.PityCount >= GachaConfig.PITY_THRESHOLD

	-- 2. Tentukan hadiah berdasarkan peluang
	local randomNumber = math.random(1, 100)
	local chosenRarity

	if isPityTriggered or randomNumber <= GachaConfig.RARITY_CHANCES.Legendary then
		chosenRarity = "Legendary"
	elseif randomNumber <= GachaConfig.RARITY_CHANCES.Legendary + GachaConfig.RARITY_CHANCES.Booster then
		chosenRarity = "Booster"
	else
		chosenRarity = "Common"
	end

	-- 3. Proses hadiah berdasarkan kelangkaan
	local availableSkins = getAvailableSkinsForWeapon(player, weaponName)

	-- Fallback jika pemain sudah punya semua skin Legendary untuk senjata ini
	if chosenRarity == "Legendary" and #availableSkins == 0 then
		chosenRarity = "Booster"
	end

	if chosenRarity == "Legendary" then
		playerData.PityCount = 0 -- Reset pity
		local randomSkinIndex = math.random(1, #availableSkins)
		local prize = availableSkins[randomSkinIndex]
		CoinsManager.AddSkin(player, prize.Weapon, prize.Skin)
		GachaSkinWonEvent:FireAllClients(player, prize.Skin)
		return { Type = "Skin", WeaponName = prize.Weapon, SkinName = prize.Skin }
	elseif chosenRarity == "Booster" then
		local boosterPrize = "SelfRevive"
		BoosterModule.AddBooster(player, boosterPrize, 1)
		return { Type = "Booster", Name = boosterPrize, Amount = 1 }
	else -- Common
		local prizeAmount = math.random(GachaConfig.COMMON_REWARD_RANGE.Min, GachaConfig.COMMON_REWARD_RANGE.Max)
		CoinsManager.AddCoins(player, prizeAmount)
		return { Type = "Coins", Amount = prizeAmount }
	end
end

-- [MODIFIED] Fungsi roll tunggal, sekarang menerima weaponName
function GachaModule.Roll(player, weaponName)
	if not weaponName or not WeaponModule.Weapons[weaponName] then
		return { Success = false, Message = "Senjata yang dipilih tidak valid." }
	end

	local playerData = CoinsManager.GetData(player)

	if playerData.Coins < GachaConfig.GACHA_COST then
		return { Success = false, Message = "BloodCoins tidak cukup." }
	end

	if not CoinsManager.SubtractCoins(player, GachaConfig.GACHA_COST) then
		return { Success = false, Message = "Gagal mengurangi BloodCoins." }
	end

	StatsModule.IncrementStat(player, "GachaSpins", 1)

	local prize = performSingleRoll(player, playerData, weaponName)
	CoinsManager.UpdatePityCount(player, playerData.PityCount)

	return { Success = true, Prize = prize }
end

-- [MODIFIED] Fungsi multi-roll, sekarang menerima weaponName
function GachaModule.RollMultiple(player, weaponName)
	if not weaponName or not WeaponModule.Weapons[weaponName] then
		return { Success = false, Message = "Senjata yang dipilih tidak valid." }
	end

	local playerData = CoinsManager.GetData(player)
	local totalCost = GachaConfig.GACHA_COST * GachaConfig.MULTI_ROLL_COST_MULTIPLIER

	if playerData.Coins < totalCost then
		return { Success = false, Message = "BloodCoins tidak cukup untuk 10+1 roll." }
	end

	if not CoinsManager.SubtractCoins(player, totalCost) then
		return { Success = false, Message = "Gagal mengurangi BloodCoins." }
	end

	StatsModule.IncrementStat(player, "GachaSpins", GachaConfig.MULTI_ROLL_COUNT)

	local prizes = {}
	for i = 1, GachaConfig.MULTI_ROLL_COUNT do
		local prize = performSingleRoll(player, playerData, weaponName)
		table.insert(prizes, prize)
	end

	CoinsManager.UpdatePityCount(player, playerData.PityCount)

	return { Success = true, Prizes = prizes }
end

-- [MODIFIED] Fungsi gacha harian gratis, sekarang menerima weaponName
function GachaModule.RollFreeDaily(player, weaponName)
	if not weaponName or not WeaponModule.Weapons[weaponName] then
		return { Success = false, Message = "Senjata yang dipilih tidak valid." }
	end

	local playerData = CoinsManager.GetData(player)
	local currentTime = os.time()
	local lastClaim = playerData.LastFreeGachaClaimUTC or 0

	-- Menghitung awal hari UTC saat ini dan terakhir klaim
	local currentDayStart = math.floor(currentTime / 86400) * 86400
	local lastClaimDayStart = math.floor(lastClaim / 86400) * 86400

	if currentDayStart <= lastClaimDayStart then
		return { Success = false, Message = "Anda sudah mengklaim gacha gratis hari ini." }
	end

	StatsModule.IncrementStat(player, "GachaSpins", 1)

	local prize = performSingleRoll(player, playerData, weaponName)

	CoinsManager.UpdatePityCount(player, playerData.PityCount)
	CoinsManager.UpdateLastFreeGachaClaim(player, currentTime)

	return { Success = true, Prize = prize }
end

return GachaModule
