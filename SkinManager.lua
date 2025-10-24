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

-- Fungsi untuk mendapatkan skin yang sedang dipakai pemain untuk senjata tertentu
function SkinManager.GetEquippedSkin(player, weaponName)
	if not player or not weaponName then return nil end

	local inventoryData = CoinsManager.GetData(player)
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

	local inventoryData = CoinsManager.GetData(player)
	local weaponConfig = WeaponModule.Weapons[weaponName]

	-- Validasi 1: Apakah senjata ada di konfigurasi?
	if not weaponConfig then
		return {Success = false, Message = "Senjata tidak ditemukan: " .. weaponName}
	end

	-- Validasi 2: Apakah skin ada di konfigurasi untuk senjata ini?
	if not weaponConfig.Skins[skinName] then
		return {Success = false, Message = "Skin tidak ditemukan untuk senjata ini: " .. skinName}
	end

	-- Validasi 3: Apakah pemain memiliki skin ini?
	local ownedSkins = inventoryData.Skins.Owned[weaponName]
	if not table.find(ownedSkins, skinName) then
		return {Success = false, Message = "Anda tidak memiliki skin ini."}
	end

	-- Semua validasi lolos, ganti skin yang dipakai
	inventoryData.Skins.Equipped[weaponName] = skinName

	-- Simpan perubahan ke DataStore
	DataStoreManager.SaveData(player, "Inventory", inventoryData)

	print(player.Name .. " berhasil menggunakan skin '" .. skinName .. "' untuk senjata '" .. weaponName .. "'.")
	return {Success = true, Message = "Skin berhasil digunakan!"}
end

-- Fungsi untuk memberikan skin acak yang belum dimiliki pemain
function SkinManager.GiveRandomSkin(player)
	if not player then return {Success = false, Message = "Player tidak valid."} end

	local inventoryData = CoinsManager.GetData(player)
	local allWeapons = WeaponModule.Weapons

	-- 1. Buat daftar semua skin yang mungkin didapatkan
	local allPossibleSkins = {}
	for weaponName, weaponData in pairs(allWeapons) do
		for skinName, skinData in pairs(weaponData.Skins) do
			if skinData.Rarity ~= "Default" then -- Jangan berikan skin default
				table.insert(allPossibleSkins, {Weapon = weaponName, Skin = skinName})
			end
		end
	end

	-- 2. Buat daftar skin yang belum dimiliki pemain
	local unownedSkins = {}
	for _, possibleSkin in ipairs(allPossibleSkins) do
		local ownedSkinsForWeapon = inventoryData.Skins.Owned[possibleSkin.Weapon]
		if not table.find(ownedSkinsForWeapon, possibleSkin.Skin) then
			table.insert(unownedSkins, possibleSkin)
		end
	end

	-- 3. Pilih satu skin secara acak dari daftar yang belum dimiliki
	if #unownedSkins == 0 then
		-- Tidak ada lagi skin untuk diberikan, berikan kompensasi koin
		CoinsManager.AddCoins(player, 1000)
		print("Pemain " .. player.Name .. " sudah memiliki semua skin. Memberikan 1000 koin sebagai kompensasi.")
		return {Success = true, Message = "Semua skin dimiliki, memberikan 1000 koin.", CompensatoryCoins = 1000}
	end

	local randomIndex = math.random(1, #unownedSkins)
	local chosenReward = unownedSkins[randomIndex]

	-- 4. Tambahkan skin ke inventaris pemain
	local success = CoinsManager.AddSkin(player, chosenReward.Weapon, chosenReward.Skin)
	if success then
		print("Memberikan skin acak '" .. chosenReward.Skin .. "' untuk senjata '" .. chosenReward.Weapon .. "' kepada " .. player.Name)
		return {Success = true, Weapon = chosenReward.Weapon, Skin = chosenReward.Skin}
	else
		-- Ini seharusnya tidak terjadi jika logika di atas benar
		return {Success = false, Message = "Gagal menambahkan skin yang sudah dimiliki."}
	end
end

return SkinManager
