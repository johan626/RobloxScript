-- SpawnerModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/SpawnerModule.lua
-- Script Place: ACT 1: Village

local SpawnerModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local ZombieConfig = require(ModuleScriptReplicatedStorage.ZombieConfig)
local GameConfig = require(ServerScriptService.ModuleScript.GameConfig)

local ZombieModule = require(ModuleScriptServerScriptService:WaitForChild("ZombieModule"))
local BuildingManager = require(ModuleScriptServerScriptService:WaitForChild("BuildingModule"))

-- Track boss spawn per interval window (ChanceWaveMin..ChanceWaveMax)
local bossWindowSpawned = false
local boss2WindowSpawned = false

local function resetBossWindowIfNeeded(currentWave)
	local bossConf = ZombieConfig.Types.Boss
	if not bossConf then
		bossWindowSpawned = false
		return
	end
	local minW = bossConf.ChanceWaveMin or 10
	local maxW = bossConf.ChanceWaveMax or 15
	-- Jika wave di luar interval, reset supaya periode berikutnya bisa spawn lagi
	if currentWave < minW or currentWave > maxW then
		-- reset boss 1
		bossWindowSpawned = false
		-- reset boss 2
		local boss2Conf = ZombieConfig.Types.Boss2
		if boss2Conf then
			local min2 = boss2Conf.ChanceWaveMin or 30
			local max2 = boss2Conf.ChanceWaveMax or 35
			if currentWave < min2 or currentWave > max2 then
				boss2WindowSpawned = false
			end
		end
	end
end

function SpawnerModule.SpawnWave(amount, wave, playerCount, gameMode, difficulty, waveModifiers)
	waveModifiers = waveModifiers or {} -- Pastikan tidak nil
	local spawners = workspace:FindFirstChild("Spawners")
	if not spawners then return false end
	resetBossWindowIfNeeded(wave)

	local isBossWave = false
	local bossTypeToSpawn = nil

	-- Only check for bosses if the game mode is not Endless
	if gameMode == "Story" then
		-- Determine if this is a boss wave BEFORE the loop starts
		-- Check for Boss3 (Maestro Nekrosis) on wave 50
		if wave == 50 then
			isBossWave = true
			bossTypeToSpawn = "Boss3"
		end

		-- Check for Boss2 if no other boss has been decided
		local boss2Conf = ZombieConfig.Types.Boss2
		if not isBossWave and not boss2WindowSpawned and boss2Conf and
			wave >= (boss2Conf.ChanceWaveMin or 30) and
			wave <= (boss2Conf.ChanceWaveMax or 35) and
			math.random() < (boss2Conf.ChanceToSpawn or 0.10) then
			isBossWave = true
			bossTypeToSpawn = "Boss2"
			boss2WindowSpawned = true -- Mark as spawned for this window to prevent re-spawning
		end

		-- Check for Boss1 if no other boss has been decided
		local bossConf = ZombieConfig.Types.Boss
		if not isBossWave and not bossWindowSpawned and bossConf and
			wave >= (bossConf.ChanceWaveMin or 10) and
			wave <= (bossConf.ChanceWaveMax or 15) and
			math.random() < (bossConf.ChanceToSpawn or 0.10) then
			isBossWave = true
			bossTypeToSpawn = "Boss"
			bossWindowSpawned = true -- Mark as spawned for this window
		end
	end

	-- If it's a boss wave, hide the buildings
	if isBossWave then
		print("Boss wave detected! Hiding buildings.")
		BuildingManager.hideBuildings()
	end

	local bossHasBeenSpawned = false

	for i = 1, amount do
		local spawnPoints = spawners:GetChildren()
		local randomSpawn = spawnPoints[math.random(1, #spawnPoints)]
		local chosenType = nil

		-- If it's a boss wave and the boss hasn't been spawned yet, spawn it.
		-- We spawn it on the first iteration to ensure it appears.
		if isBossWave and not bossHasBeenSpawned then
			chosenType = bossTypeToSpawn
			bossHasBeenSpawned = true
		elseif waveModifiers.isSpecial then
			-- Logika untuk Gelombang Spesial: pilih acak dari tipe yang diizinkan
			local allowedTypes = GameConfig.SpecialWave.AllowedTypes
			if allowedTypes and #allowedTypes > 0 then
				chosenType = allowedTypes[math.random(1, #allowedTypes)]
			end
		else
			-- Standard zombie type selection for non-bosses or remaining spawns
			if wave and wave >= 3 and math.random() < (ZombieConfig.Types.Runner.Chance or 0.30) then
				chosenType = "Runner"
			elseif wave and wave >= 6 and math.random() < (ZombieConfig.Types.Shooter.Chance or 0.25) then
				chosenType = "Shooter"
			elseif wave and wave >= 9 and math.random() < (ZombieConfig.Types.Tank.Chance or 0.10) then
				chosenType = "Tank"
			end
		end

		-- Spawn the chosen zombie type (or default if none chosen)
		ZombieModule.SpawnZombie(randomSpawn, chosenType, playerCount, difficulty, waveModifiers)
		task.wait(1) -- Wait between spawns
	end

	return isBossWave
end

return SpawnerModule