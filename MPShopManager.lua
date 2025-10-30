-- MPShopManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/MPShopManager.lua
-- Script Place: Lobby

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Muat modul yang diperlukan
local MPShopConfig = require(ServerScriptService.ModuleScript:WaitForChild("MPShopConfig"))
local MissionPointsModule = require(ServerScriptService.ModuleScript:WaitForChild("MissionPointsModule"))
local SkinManager = require(ServerScriptService.ModuleScript:WaitForChild("SkinManager"))
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))
local CoinsManager = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))

local MPShopManager = {}

function MPShopManager:PurchaseGenericItem(player, itemID)
	if not player or not itemID then
		return { Success = false, Reason = "Argumen tidak valid." }
	end

	local itemConfig = MPShopConfig.Items[itemID]
	if not itemConfig then
		return { Success = false, Reason = "Item tidak ditemukan." }
	end

	local cost = itemConfig.MPCost
	local currentPoints = MissionPointsModule:GetMissionPoints(player)
	if currentPoints < cost then
		return { Success = false, Reason = "Mission Points tidak cukup." }
	end

	local pointsRemoved = MissionPointsModule:RemoveMissionPoints(player, cost)
	if not pointsRemoved then
		return { Success = false, Reason = "Gagal mengurangi Mission Points." }
	end

	-- Berikan item berdasarkan tipenya
	if itemID == "DAILY_MISSION_REROLL" then
		local MissionManager = require(script.Parent:WaitForChild("MissionManager"))
		local success, reason = MissionManager:RerollDailyMission(player)
		if not success then
			-- Kembalikan poin jika gagal
			MissionPointsModule:AddMissionPoints(player, cost)
			return { Success = false, Reason = reason }
		end
	else -- Untuk booster
		local BoosterManager = require(script.Parent:WaitForChild("BoosterManager"))
		BoosterManager.AddBooster(player, itemID, itemConfig)
	end

	print(string.format("%s berhasil membeli item '%s' seharga %d MP.", player.Name, itemConfig.Name, cost))
	return { Success = true, Reason = "Pembelian berhasil!" }
end

-- Fungsi untuk membeli skin
function MPShopManager:PurchaseSkin(player, weaponName, skinName)
	if not player or not weaponName or not skinName then
		return { Success = false, Reason = "Argumen tidak valid." }
	end

	-- Validasi 1: Apakah senjata dan skin ada di konfigurasi?
	local weaponConfig = WeaponModule.Weapons[weaponName]
	if not weaponConfig or not weaponConfig.Skins[skinName] then
		return { Success = false, Reason = "Skin atau senjata tidak ditemukan." }
	end

	local skinConfig = weaponConfig.Skins[skinName]
	local cost = skinConfig.MPCost

	-- Validasi 2: Apakah skin ini bisa dibeli (punya harga)?
	if not cost or cost <= 0 then
		return { Success = false, Reason = "Skin ini tidak untuk dijual." }
	end

	-- Validasi 3: Apakah pemain sudah memiliki skin ini?
	local inventoryData = CoinsManager.GetData(player)
	if inventoryData and inventoryData.Skins and inventoryData.Skins.Owned and inventoryData.Skins.Owned[weaponName] then
		if table.find(inventoryData.Skins.Owned[weaponName], skinName) then
			return { Success = false, Reason = "Anda sudah memiliki skin ini." }
		end
	end

	-- Validasi 4: Apakah pemain memiliki cukup Mission Points?
	local currentPoints = MissionPointsModule:GetMissionPoints(player)
	if currentPoints < cost then
		return { Success = false, Reason = "Mission Points tidak cukup." }
	end

	-- Semua validasi lolos, lanjutkan transaksi
	local pointsRemoved = MissionPointsModule:RemoveMissionPoints(player, cost)
	if not pointsRemoved then
		-- Ini seharusnya tidak terjadi jika pengecekan di atas benar, tapi sebagai pengaman
		return { Success = false, Reason = "Gagal mengurangi Mission Points." }
	end

	-- Berikan skin kepada pemain
	local skinAdded = CoinsManager.AddSkin(player, weaponName, skinName)
	if not skinAdded then
		-- Jika gagal menambahkan skin, kembalikan poin pemain untuk mencegah kerugian
		MissionPointsModule:AddMissionPoints(player, cost)
		return { Success = false, Reason = "Gagal menambahkan skin ke inventaris." }
	end

	print(string.format("%s berhasil membeli skin '%s' untuk '%s' seharga %d MP.", player.Name, skinName, weaponName, cost))
	return { Success = true, Reason = "Pembelian berhasil!" }
end


-- Inisialisasi RemoteFunction untuk pembelian
local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
if not remoteFunctions then
	remoteFunctions = Instance.new("Folder")
	remoteFunctions.Name = "RemoteFunctions"
	remoteFunctions.Parent = ReplicatedStorage
end

local purchaseSkinFunc = Instance.new("RemoteFunction", remoteFunctions)
purchaseSkinFunc.Name = "PurchaseSkin"
purchaseSkinFunc.OnServerInvoke = function(player, weaponName, skinName)
	return MPShopManager:PurchaseSkin(player, weaponName, skinName)
end

local purchaseGenericItemFunc = Instance.new("RemoteFunction", remoteFunctions)
purchaseGenericItemFunc.Name = "PurchaseGenericItem"
purchaseGenericItemFunc.OnServerInvoke = function(player, itemID)
	return MPShopManager:PurchaseGenericItem(player, itemID)
end

return MPShopManager
