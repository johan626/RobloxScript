-- WeaponUpgradeConfigModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/WeaponUpgradeConfigModule.lua
-- Script Place: ACT 1: Village

local WeaponUpgradeModule = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))

local playerLevels = {}

local DefaultConfig = {
	BaseCost = 500,
	CostMultiplier = 1.55,
	CostExpo = 1.32,
	DamagePerLevel = 5,
	MaxLevel = 10
}

local function mergeConfig(base, override)
	local out = {}
	for k, v in pairs(base) do out[k] = v end
	if override then
		for k, v in pairs(override) do out[k] = v end
	end
	return out
end

function WeaponUpgradeModule.GetLevel(player, weaponId)
	if not player or not weaponId then return 0 end
	local t = playerLevels[player]
	if not t then return 0 end
	return t[weaponId] or 0
end

function WeaponUpgradeModule.SetLevel(player, weaponId, level)
	if not playerLevels[player] then
		playerLevels[player] = {}
	end
	playerLevels[player][weaponId] = level
end

function WeaponUpgradeModule.CalculateCost(weaponName, nextLevel)
	local cfg = DefaultConfig
	if WeaponModule.Weapons[weaponName] and WeaponModule.Weapons[weaponName].UpgradeConfig then
		cfg = mergeConfig(cfg, WeaponModule.Weapons[weaponName].UpgradeConfig)
	end
	local cost = math.floor(cfg.BaseCost * (nextLevel ^ cfg.CostExpo) * (cfg.CostMultiplier ^ (nextLevel - 1)))
	return math.max(1, cost)
end

function WeaponUpgradeModule.GetDamageFor(player, weaponId, weaponName)
	local base = 0
	if WeaponModule.Weapons[weaponName] and WeaponModule.Weapons[weaponName].Damage then
		base = WeaponModule.Weapons[weaponName].Damage
	end
	local lvl = WeaponUpgradeModule.GetLevel(player, weaponId)
	local cfg = DefaultConfig
	if WeaponModule.Weapons[weaponName] and WeaponModule.Weapons[weaponName].UpgradeConfig then
		cfg = mergeConfig(cfg, WeaponModule.Weapons[weaponName].UpgradeConfig)
	end
	return base + (cfg.DamagePerLevel * lvl)
end

function WeaponUpgradeModule.AttemptUpgrade(player, weaponId, weaponName, overrideCost)
	if not player or not player:IsA("Player") then return false, "Invalid player" end
	if not weaponId or not weaponName or not WeaponModule.Weapons[weaponName] then return false, "Senjata tidak valid" end

	local current = WeaponUpgradeModule.GetLevel(player, weaponId)
	local nextLevel = current + 1

	local cfg = DefaultConfig
	if WeaponModule.Weapons[weaponName] and WeaponModule.Weapons[weaponName].UpgradeConfig then
		cfg = mergeConfig(cfg, WeaponModule.Weapons[weaponName].UpgradeConfig)
	end

	if nextLevel > cfg.MaxLevel then return false, "Sudah level maksimal" end

	-- Gunakan overrideCost jika ada, jika tidak, hitung secara normal
	local cost = overrideCost
	if cost == nil then
		cost = WeaponUpgradeModule.CalculateCost(weaponName, nextLevel)
	end

	-- Pemeriksaan poin sudah dilakukan di UpgradeManager, jadi kita bisa langsung mengurangi
	local success = PointsSystem.AddPoints(player, -cost)

	if success then
		WeaponUpgradeModule.SetLevel(player, weaponId, nextLevel)
		return true, "Upgrade sukses", nextLevel, cost
	else
		-- Jika pengurangan poin gagal (meskipun seharusnya tidak terjadi karena pemeriksaan sebelumnya),
		-- kembalikan kegagalan.
		return false, "Gagal mengurangi poin"
	end
end

Players.PlayerAdded:Connect(function(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
	playerLevels[plr] = nil
end)

return WeaponUpgradeModule