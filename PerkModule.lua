-- PerkModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/PerkModule.lua
-- Script Place: ACT 1: Village

local playerPerks = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local PerkConfig = require(ModuleScriptReplicatedStorage:WaitForChild("PerkConfig"))
local GameConfig = require(ModuleScriptServerScriptService:WaitForChild("GameConfig"))
local GameStatus = require(ModuleScriptServerScriptService:WaitForChild("GameStatus"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))
local SkillModule = require(ModuleScriptServerScriptService:WaitForChild("SkillModule"))
local BoosterModule = require(ModuleScriptServerScriptService:WaitForChild("BoosterModule"))
local SkillConfig = require(ModuleScriptReplicatedStorage:WaitForChild("SkillConfig"))

local purchasePerkRF = RemoteFunctions:WaitForChild("PurchasePerk")
local perkUpdateEvent = RemoteEvents:WaitForChild("PerkUpdate")
local openPerkShopEvent = RemoteEvents:WaitForChild("OpenPerkShop")
local requestOpenPerkShopEvent = RemoteEvents:WaitForChild("RequestOpenPerkShop")

local PerkCosts = {
	-- Jenjang Utilitas
	RevivePlus = 2000,
	Medic = 2000,
	-- Jenjang Inti
	HPPlus = 4000,
	StaminaPlus = 4000,
	ReloadPlus = 4000,
	-- Jenjang Elit
	RateBoost = 6000,
	ExplosiveRounds = 6000
}

local function isPlayerNearPerkMachine(player)
	local perkPart = workspace:FindFirstChild("Perks")
	if not perkPart then return false end

	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return false end

	local dist = (char.HumanoidRootPart.Position - perkPart.Position).Magnitude
	return dist <= 10
end

function grantPerk(player, perkName)
	if not playerPerks[player] then
		playerPerks[player] = {}
	end

	-- Cek apakah sudah memiliki perk ini
	if table.find(playerPerks[player], perkName) then
		return false, "Already have this perk"
	end

	-- Logika batas perk dinamis
	local currentDifficulty = GameStatus:GetDifficulty()
	local difficultyRules = GameConfig.Difficulty[currentDifficulty] and GameConfig.Difficulty[currentDifficulty].Rules
	local maxPerks = (difficultyRules and difficultyRules.MaxPerks) or 99

	if #playerPerks[player] >= maxPerks then
		return false, ("Max perks reached (%d)"):format(maxPerks)
	end

	table.insert(playerPerks[player], perkName)

	-- Terapkan efek perk segera setelah dibeli
	applyPerkEffects(player)

	return true, "Perk granted"
end

function getPlayerPerks(player)
	return playerPerks[player] or {}
end

function clearPlayerPerks(player)
	if playerPerks[player] then
		-- Hapus efek perk sebelum membersihkan
		local character = player.Character
		if character then
			character:SetAttribute("StaminaBoost", nil)
			character:SetAttribute("RateBoost", nil)
			character:SetAttribute("ReloadBoost", nil)
			character:SetAttribute("ReviveBoost", nil)
			character:SetAttribute("MedicBoost", nil)
			character:SetAttribute("ExplosiveRoundsBoost", nil)

			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.MaxHealth = 100
				if humanoid.Health > 100 then
					humanoid.Health = 100
				end
			end
		end
	end
	playerPerks[player] = nil
end

-- Remote Function untuk membeli perk
-- Logika ini berada di PerkModule (sisi server) untuk keamanan.
-- PerkShopUI (sisi klien) hanya memicu fungsi ini.
purchasePerkRF.OnServerInvoke = function(player, perkName)
	if not isPlayerNearPerkMachine(player) then
		return {Success = false, Message = "Not near perk machine"}
	end

	local perkDetails = PerkConfig.Perks[perkName]
	if not perkDetails then
		return {Success = false, Message = "Invalid perk"}
	end

	local cost = PerkCosts[perkName]
	if not cost then
		return {Success = false, Message = "Perk cost not found"}
	end

	local hasDiscount = false
	local boosterData = BoosterModule.GetData(player)
	if boosterData and boosterData.Active == "CouponDiscount" then
		hasDiscount = true
		cost = math.floor(cost / 2)
	end

	local points = PointsSystem.GetPoints(player) or 0
	if points < cost then
		return {Success = false, Message = "Not enough points"}
	end

	local success, message = grantPerk(player, perkName)
	if not success then
		return {Success = false, Message = message}
	end

	-- Potong points
	PointsSystem.AddPoints(player, -cost)

	-- Jika ada diskon, gunakan booster
	if hasDiscount then
		BoosterModule.UseActiveBooster(player)
	end

	-- Kirim update ke client
	perkUpdateEvent:FireClient(player, getPlayerPerks(player))

	return {Success = true, Message = "Perk purchased!"}
end

-- Terapkan efek perk ke karakter
function applyPerkEffects(player)
	local perks = getPlayerPerks(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Reset semua efek perk terlebih dahulu
	character:SetAttribute("StaminaBoost", nil)
	character:SetAttribute("RateBoost", nil)
	character:SetAttribute("ReloadBoost", nil)
	character:SetAttribute("ReviveBoost", nil)
	character:SetAttribute("MedicBoost", nil)
	character:SetAttribute("ExplosiveRoundsBoost", nil)
	humanoid.MaxHealth = 100

	-- Terapkan efek perk berdasarkan yang dimiliki
	for _, perkName in ipairs(perks) do
		if perkName == "HPPlus" then
			humanoid.MaxHealth = 130
		elseif perkName == "StaminaPlus" then
			character:SetAttribute("StaminaBoost", true)
		elseif perkName == "ReloadPlus" then
			character:SetAttribute("ReloadBoost", true)
		elseif perkName == "RevivePlus" then
			character:SetAttribute("ReviveBoost", true)
		elseif perkName == "RateBoost" then
			character:SetAttribute("RateBoost", true)
		elseif perkName == "Medic" then
			character:SetAttribute("MedicBoost", true)
		elseif perkName == "ExplosiveRounds" then
			character:SetAttribute("ExplosiveRoundsBoost", true)
		end
	end

	-- Terapkan bonus dari skill MaxHealth
	local skillData = SkillModule.GetSkillData(player)
	if skillData and skillData.Skills then
		local healthSkillLevel = skillData.Skills.MaxHealth or 0
		if healthSkillLevel > 0 then
			local healthBonus = healthSkillLevel * (SkillConfig.MaxHealth.HPPerLevel or 1)
			humanoid.MaxHealth = humanoid.MaxHealth + healthBonus
		end
	end

	-- Pastikan health tidak melebihi max health baru setelah semua modifikasi
	if humanoid.Health > humanoid.MaxHealth then
		humanoid.Health = humanoid.MaxHealth
	end
end

-- Handler untuk membuka UI shop perk
requestOpenPerkShopEvent.OnServerEvent:Connect(function(player)
	if isPlayerNearPerkMachine(player) then
		local hasDiscount = false
		local boosterData = BoosterModule.GetData(player)
		if boosterData and boosterData.Active == "CouponDiscount" then
			hasDiscount = true
		end

		-- Create a new table to send to the client, merging perk details and costs
		local perksForClient = {}
		for perkName, perkDetails in pairs(PerkConfig.Perks) do
			local cost = PerkCosts[perkName]
			if cost then
				perksForClient[perkName] = {
					Description = perkDetails.Description,
					Icon = perkDetails.Icon,
					Cost = cost
				}
			end
		end
		openPerkShopEvent:FireClient(player, perksForClient, hasDiscount)
	end
end)

-- Reset perks ketika game dimulai ulang
local function onPlayerAdded(player)
	playerPerks[player] = {}

	player.CharacterAdded:Connect(function(character)
		-- Tunggu humanoid tersedia
		character:WaitForChild("Humanoid")
		-- Apply efek perk ketika karakter respawn
		task.wait(0.5)
		applyPerkEffects(player)
		perkUpdateEvent:FireClient(player, getPlayerPerks(player))
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	clearPlayerPerks(player)
	playerPerks[player] = nil
end)

-- Integrasi dengan sistem lain
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		applyPerkEffects(player)
	end)
end)

return {
	grantPerk = grantPerk,
	getPlayerPerks = getPlayerPerks,
	clearPlayerPerks = clearPlayerPerks,
	applyPerkEffects = applyPerkEffects
}
