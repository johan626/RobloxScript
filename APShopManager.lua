-- APShopManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/APShopManager.lua
-- Script Place: Lobby

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Muat modul yang diperlukan
local StatsModule = require(script.Parent:WaitForChild("StatsModule"))
local SkinManager = require(script.Parent:WaitForChild("SkinManager"))
local WeaponModule = require(ReplicatedStorage:WaitForChild("ModuleScript"):WaitForChild("WeaponModule"))
local CoinsManager = require(script.Parent:WaitForChild("CoinsModule"))

local APShopManager = {}

-- Fungsi untuk membeli skin dengan AP
function APShopManager:PurchaseSkinWithAP(player, weaponName, skinName)
	if not player or not weaponName or not skinName then
		return { Success = false, Reason = "Argumen tidak valid." }
	end

	-- Validasi 1: Apakah senjata dan skin ada di konfigurasi?
	local weaponConfig = WeaponModule.Weapons[weaponName]
	if not weaponConfig or not weaponConfig.Skins[skinName] then
		return { Success = false, Reason = "Skin atau senjata tidak ditemukan." }
	end

	local skinConfig = weaponConfig.Skins[skinName]
	local cost = skinConfig.APCost

	-- Validasi 2: Apakah skin ini bisa dibeli dengan AP (punya harga)?
	if not cost or cost <= 0 then
		return { Success = false, Reason = "Skin ini tidak untuk dijual dengan AP." }
	end

	-- Validasi 3: Apakah pemain sudah memiliki skin ini?
	local inventoryData = CoinsManager.GetData(player)
	if inventoryData and inventoryData.Skins and inventoryData.Skins.Owned and inventoryData.Skins.Owned[weaponName] then
		if table.find(inventoryData.Skins.Owned[weaponName], skinName) then
			return { Success = false, Reason = "Anda sudah memiliki skin ini." }
		end
	end

	-- Validasi 4: Apakah pemain memiliki cukup Achievement Points?
	local currentPoints = StatsModule.GetAchievementPoints(player)
	if currentPoints < cost then
		return { Success = false, Reason = "Achievement Points tidak cukup." }
	end

	-- Semua validasi lolos, lanjutkan transaksi
	local pointsRemoved = StatsModule.RemoveAchievementPoints(player, cost)
	if not pointsRemoved then
		-- Ini seharusnya tidak terjadi jika pengecekan di atas benar, tapi sebagai pengaman
		return { Success = false, Reason = "Gagal mengurangi Achievement Points." }
	end

	-- Berikan skin kepada pemain
	local skinAdded = CoinsManager.AddSkin(player, weaponName, skinName)
	if not skinAdded then
		-- Jika gagal menambahkan skin, kembalikan poin pemain untuk mencegah kerugian
		StatsModule.AddAchievementPoints(player, cost)
		return { Success = false, Reason = "Gagal menambahkan skin ke inventaris." }
	end

	print(string.format("%s berhasil membeli skin '%s' untuk '%s' seharga %d AP.", player.Name, skinName, weaponName, cost))
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
purchaseSkinFunc.Name = "PurchaseSkinWithAP"
purchaseSkinFunc.OnServerInvoke = function(player, weaponName, skinName)
	return APShopManager:PurchaseSkinWithAP(player, weaponName, skinName)
end

return APShopManager
