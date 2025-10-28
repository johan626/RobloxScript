-- SkinManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/SkinManager.lua
-- Script Place: Lobby, ACT 1: Village

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Memuat modul yang diperlukan
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))
local CoinsManager = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))

local SkinManager = {}

-- Fungsi untuk mendapatkan data inventaris pemain
function SkinManager.GetInventoryData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[SkinManager] Gagal mendapatkan data inventaris untuk pemain: " .. player.Name)
		return nil
	end
	return playerData.data.inventory
end

-- Fungsi untuk mendapatkan skin yang sedang dipakai pemain untuk senjata tertentu
function SkinManager.GetEquippedSkin(player, weaponName)
	if not player or not weaponName then return nil end

	local inventoryData = SkinManager.GetInventoryData(player)
	if inventoryData and inventoryData.Skins and inventoryData.Skins.Equipped then
		return inventoryData.Skins.Equipped[weaponName]
	end

	return nil
end

-- Fungsi untuk mengganti skin yang dipakai pemain
function SkinManager.EquipSkin(player, weaponName, skinName)
	if not player or not weaponName or not skinName then
		return {Success = false, Message = "Argumen tidak valid."}
	end

	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		return {Success = false, Message = "Gagal mengambil data pemain."}
	end

	local inventoryData = playerData.data.inventory
	local weaponConfig = WeaponModule.Weapons[weaponName]

	if not weaponConfig or not weaponConfig.Skins[skinName] then
		return {Success = false, Message = "Skin atau senjata tidak valid."}
	end

	local ownedSkins = inventoryData.Skins.Owned[weaponName]
	if not table.find(ownedSkins, skinName) then
		return {Success = false, Message = "Anda tidak memiliki skin ini."}
	end

	inventoryData.Skins.Equipped[weaponName] = skinName
	DataStoreManager:UpdatePlayerData(player, playerData.data) -- Simpan seluruh data pemain

	print(player.Name .. " berhasil menggunakan skin '" .. skinName .. "' untuk senjata '" .. weaponName .. "'.")
	return {Success = true, Message = "Skin berhasil digunakan!"}
end

-- Fungsi untuk memberikan skin acak (logika tidak berubah)
function SkinManager.GiveRandomSkin(player)
	if not player then return {Success = false, Message = "Player tidak valid."} end

	local inventoryData = SkinManager.GetInventoryData(player)
	local allWeapons = WeaponModule.Weapons
	local allPossibleSkins = {}
	for weaponName, weaponData in pairs(allWeapons) do
		for skinName, skinData in pairs(weaponData.Skins) do
			if skinData.Rarity ~= "Default" then
				table.insert(allPossibleSkins, {Weapon = weaponName, Skin = skinName})
			end
		end
	end

	local unownedSkins = {}
	for _, possibleSkin in ipairs(allPossibleSkins) do
		local ownedSkinsForWeapon = inventoryData.Skins.Owned[possibleSkin.Weapon] or {}
		if not table.find(ownedSkinsForWeapon, possibleSkin.Skin) then
			table.insert(unownedSkins, possibleSkin)
		end
	end

	if #unownedSkins == 0 then
		CoinsManager.AddCoins(player, 1000)
		return {Success = true, Message = "Semua skin dimiliki, memberikan 1000 koin.", CompensatoryCoins = 1000}
	end

	local chosenReward = unownedSkins[math.random(#unownedSkins)]
	local success = CoinsManager.AddSkin(player, chosenReward.Weapon, chosenReward.Skin)
	if success then
		return {Success = true, Weapon = chosenReward.Weapon, Skin = chosenReward.Skin}
	else
		return {Success = false, Message = "Gagal menambahkan skin."}
	end
end

return SkinManager
