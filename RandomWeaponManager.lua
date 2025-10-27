-- RandomWeaponManager.lua (Script)
-- Path: ServerScriptService/Script/RandomWeaponManager.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local RandomConfig = require(ModuleScriptServerScriptService:WaitForChild("RandomWeaponConfig"))
local SessionDataManager = require(ModuleScriptServerScriptService:WaitForChild("SessionDataManager"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))
local CoinsManager = require(ModuleScriptServerScriptService:WaitForChild("CoinsModule"))
local BoosterModule = require(ModuleScriptServerScriptService:WaitForChild("BoosterModule"))

local openReplaceUI = RemoteEvents:WaitForChild("OpenReplaceUI")
local replaceChoiceEv = RemoteEvents:WaitForChild("ReplaceChoice")

local purchaseRF = RemoteFunctions:WaitForChild("PurchaseRandomWeapon")

-- pendingOffers[player] = {weaponName = "...", cost = X, hasDiscount = Y, timestamp = tick()}
local pendingOffers = {}

local function getPlayerWeapons(player)
	local weapons = {}
	local function checkContainer(container)
		if not container then return end
		for _, obj in pairs(container:GetChildren()) do
			if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
				local isTemp = obj:GetAttribute("TemporaryDrop") == true
				if WeaponModule.Weapons[obj.Name] and not isTemp then
					table.insert(weapons, obj)
				end
			end
		end
	end
	checkContainer(player:FindFirstChild("Backpack"))
	if player.Character then checkContainer(player.Character) end
	return weapons
end

local function findWeaponTemplate(name)
	local weaponsFolder = ServerStorage:FindFirstChild("Weapons")
	if weaponsFolder and weaponsFolder:FindFirstChild(name) then
		return weaponsFolder:FindFirstChild(name)
	end
	return ServerStorage:FindFirstChild(name)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.1)
		local backpack = player:FindFirstChild("Backpack")
		if not backpack then return end

		-- Cek apakah sudah punya senjata awal atau senjata apapun
		local hasStarter = false
		for _, tool in pairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.Name == RandomConfig.StarterWeapon then
				hasStarter = true
				break
			end
		end
		if char:FindFirstChildOfClass("Tool") then
			hasStarter = true
		end

		if hasStarter then return end

		-- Logika Booster "Legion's Legacy"
		local boosterData = BoosterModule.GetData(player)
		local usedLegacyBooster = false
		if boosterData and boosterData.Active == "LegionsLegacy" then
			local success, usedBoosterName = pcall(BoosterModule.UseActiveBooster, player)
			if success and usedBoosterName == "LegionsLegacy" then
				usedLegacyBooster = true
			end
		end

		local weaponNameToGive
		if usedLegacyBooster then
			-- Pilih senjata acak dari daftar
			local pool = RandomConfig.AvailableWeapons
			if #pool > 0 then
				weaponNameToGive = pool[math.random(1, #pool)]
				print(player.Name .. " used Legion's Legacy and got: " .. weaponNameToGive)
			else
				-- Fallback jika daftar kosong
				weaponNameToGive = RandomConfig.StarterWeapon
			end
		else
			-- Berikan senjata awal biasa
			weaponNameToGive = RandomConfig.StarterWeapon
		end

		local template = findWeaponTemplate(weaponNameToGive)
		if template then
			local HttpService = game:GetService("HttpService")
			local clone = template:Clone()
			clone:SetAttribute("WeaponId", HttpService:GenerateGUID(false))

			local inventoryData = CoinsManager.GetData(player)
			if inventoryData and inventoryData.Skins and inventoryData.Skins.Equipped then
				local equippedSkin = inventoryData.Skins.Equipped[clone.Name]
				if equippedSkin then
					clone:SetAttribute("EquippedSkin", equippedSkin)
				end
			end

			clone.Parent = player:FindFirstChild("Backpack") or player
		end
	end)
end)

purchaseRF.OnServerInvoke = function(player)
	if not player or not player:IsA("Player") then
		return {success=false, message="Invalid player"}
	end

	local GameStatus = require(ModuleScriptServerScriptService:WaitForChild("GameStatus"))
	local GameConfig = require(ModuleScriptServerScriptService:WaitForChild("GameConfig"))

	local currentDifficulty = GameStatus:GetDifficulty()
	local difficultyRules = GameConfig.Difficulty[currentDifficulty] and GameConfig.Difficulty[currentDifficulty].Rules

	local cost
	if difficultyRules and difficultyRules.IncreaseRandomWeaponCost then
		local purchaseCount = SessionDataManager:GetRandomWeaponPurchases(player)
		cost = GameConfig.RandomWeapon.BaseCost + (purchaseCount * GameConfig.RandomWeapon.CostIncrease)
	else
		cost = GameConfig.RandomWeapon.BaseCost
	end

	local hasDiscount = false
	local boosterData = BoosterModule.GetData(player)
	if boosterData and boosterData.Active == "CouponDiscount" then
		hasDiscount = true
		cost = math.floor(cost / 2)
	end

	local points = PointsSystem.GetPoints(player) or 0
	if points < cost then
		return {success=false, message="Not enough points"}
	end

	local pool = RandomConfig.AvailableWeapons
	if #pool == 0 then
		return {success=false, message="No weapons configured"}
	end
	local newName = pool[math.random(1,#pool)]
	local template = findWeaponTemplate(newName)
	if not template then
		return {success=false, message="Weapon template not found on server: "..newName}
	end

	local weapons = getPlayerWeapons(player)
	if #weapons < RandomConfig.MaxWeapons then
		-- Punya slot, langsung selesaikan transaksi
		PointsSystem.AddPoints(player, -cost)
		SessionDataManager:IncrementRandomWeaponPurchases(player) -- Catat pembelian
		if hasDiscount then
			BoosterModule.UseActiveBooster(player)
		end

		local clone = template:Clone()
		local inventoryData = CoinsManager.GetData(player)
		if inventoryData and inventoryData.Skins and inventoryData.Skins.Equipped then
			local equippedSkin = inventoryData.Skins.Equipped[clone.Name]
			if equippedSkin then
				clone:SetAttribute("EquippedSkin", equippedSkin)
			end
		end
		clone.Parent = player:FindFirstChild("Backpack") or player
		return {success=true, message=("Purchased %s"):format(newName), weaponName=newName, replaced=false}
	else
		-- Senjata penuh, tunda transaksi
		pendingOffers[player] = {weaponName = newName, cost = cost, hasDiscount = hasDiscount, time = tick()}
		local names = {}
		for i, w in ipairs(weapons) do
			names[i] = w.Name
		end
		openReplaceUI:FireClient(player, names, newName, cost, hasDiscount)
		return {success=false, message="choose", weaponName=newName}
	end
end

replaceChoiceEv.OnServerEvent:Connect(function(player, index)
	local offer = pendingOffers[player]
	if not offer then return end

	-- Jika pemain membatalkan UI, index akan menjadi -1
	if index == -1 then
		pendingOffers[player] = nil
		return
	end

	if tick() - (offer.time or 0) > 30 then
		pendingOffers[player] = nil
		return
	end

	local weapons = getPlayerWeapons(player)
	if index < 1 or index > #weapons then return end

	-- Selesaikan transaksi SEKARANG, setelah pemain memilih
	local points = PointsSystem.GetPoints(player) or 0
	if points < offer.cost then
		pendingOffers[player] = nil
		return
	end

	PointsSystem.AddPoints(player, -offer.cost)
	if offer.hasDiscount then
		BoosterModule.UseActiveBooster(player)
	end
	SessionDataManager:IncrementRandomWeaponPurchases(player) -- FIX: Catat pembelian di sini juga

	-- Lakukan penggantian senjata
	local toRemove = weapons[index]
	if toRemove and toRemove:GetAttribute("TemporaryDrop") then return end
	if toRemove and toRemove.Parent then
		toRemove:Destroy()
	end

	local template = findWeaponTemplate(offer.weaponName)
	if template then
		local clone = template:Clone()

		local inventoryData = CoinsManager.GetData(player)
		if inventoryData and inventoryData.Skins and inventoryData.Skins.Equipped then
			local equippedSkin = inventoryData.Skins.Equipped[clone.Name]
			if equippedSkin then
				clone:SetAttribute("EquippedSkin", equippedSkin)
			end
		end

		clone.Parent = player:FindFirstChild("Backpack") or player
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and clone and clone.Parent then
				hum:EquipTool(clone)
			end
		end
	end

	pendingOffers[player] = nil
end)

Players.PlayerRemoving:Connect(function(player)
	pendingOffers[player] = nil
end)
