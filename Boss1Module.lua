-- Boss1Module.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BossModule/Boss1Module.lua
-- Script Place: ACT 1: Village

local Boss1 = {}

-- Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Boss1VFXModule = require(ReplicatedStorage.ZombieVFX:WaitForChild("Boss1VFXModule"))
local ElementModule = require(ServerScriptService.ModuleScript:WaitForChild("ElementConfigModule"))
local ShieldModule = require(ServerScriptService.ModuleScript:WaitForChild("ShieldModule"))
local ZombieConfig = require(ReplicatedStorage.ModuleScript:WaitForChild("ZombieConfig"))

local BossTimerEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BossTimerEvent")
local BossAlertEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BossIncoming")

-- Helper function to find a valid target
local function findTarget(bossModel)
	local furthestTarget = nil
	local maxDistance = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
			local distance = (bossModel.PrimaryPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
			if distance > maxDistance then
				maxDistance = distance
				furthestTarget = player
			end
		end
	end
	return furthestTarget
end

function Boss1.Init(zombie, humanoid, config, executeHardWipe, SpawnerModule)
	-- === INITIALIZATION ===
	local bossTag = Instance.new("BoolValue")
	bossTag.Name = "IsBoss"
	bossTag.Parent = zombie
	BossAlertEvent:FireAllClients(config.Name or "Boss")

	local currentState = "Phase1"
	local transitioning = false
	local attackCooldowns = {
		CorrosiveSlam = 0,
		ToxicLob = 0,
		VolatileMinions = 0,
		FissionBarrage = 0,
	}

	-- === TIMER & WIPE MECHANIC ===
	local bossStartTime = tick()
	local specialTimeout = config.SpecialTimeout or 300
	BossTimerEvent:FireAllClients(specialTimeout, specialTimeout)
	local timerCoroutine = task.spawn(function()
		while zombie.Parent and humanoid.Health > 0 do
			local elapsed = tick() - bossStartTime
			local remaining = math.max(0, specialTimeout - elapsed)
			BossTimerEvent:FireAllClients(remaining, specialTimeout)
			if remaining <= 0 then
				executeHardWipe(zombie, humanoid)
				break
			end
			task.wait(1)
		end
	end)

	-- === RADIATION AURA ===
	local radiationCoroutine = task.spawn(function()
		local rconf = config.Radiation
		while zombie.Parent and humanoid.Health > 0 do
			local currentRadius = (currentState == "Phase2") and rconf.Phase2Radius or rconf.Phase1Radius
			local bossPos = zombie.PrimaryPart.Position

			for _, plr in ipairs(Players:GetPlayers()) do
				local char = plr.Character
				if char and not ElementModule.IsPlayerInvincible(plr) then
					local hum = char:FindFirstChildOfClass("Humanoid")
					local hrp = char:FindFirstChild("HumanoidRootPart")
					if hum and hum.Health > 0 and hrp then
						local dxz = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(bossPos.X, bossPos.Z)).Magnitude
						if dxz <= currentRadius then
							local dmg = hum.MaxHealth * rconf.DamagePerSecondPct * rconf.Tick
							dmg = ElementModule.ApplyDamageReduction(plr, dmg)
							local leftoverDamage = ShieldModule.Damage(plr, dmg)
							if leftoverDamage > 0 then
								hum:TakeDamage(leftoverDamage)
							end
						end
					end
				end
			end
			task.wait(rconf.Tick)
		end
	end)

	-- === HEALTH CHANGE & PHASE TRANSITION ===
	humanoid.HealthChanged:Connect(function(health)
		if transitioning or currentState ~= "Phase1" then return end

		if health / humanoid.MaxHealth <= config.PhaseTransition.TriggerHPPercent then
			transitioning = true
			currentState = "Transition"
			humanoid.WalkSpeed = 0

			Boss1VFXModule.CreatePhaseTransitionEffect(zombie)

			task.wait(config.PhaseTransition.RoarDuration)

			humanoid.WalkSpeed = config.WalkSpeed
			currentState = "Phase2"
			transitioning = false
		end
	end)

    -- Function to apply damage from a puddle
    local function handlePuddleDamage(puddlePosition, puddleConfig)
        local startTime = tick()
        while tick() - startTime < puddleConfig.PuddleDuration do
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if char and not ElementModule.IsPlayerInvincible(player) then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and hrp then
                        if (hrp.Position - puddlePosition).Magnitude <= puddleConfig.PuddleRadius then
                            local damage = puddleConfig.PuddleDamagePerTick
                            damage = ElementModule.ApplyDamageReduction(player, damage)
                            local leftoverDamage = ShieldModule.Damage(player, damage)
                            if leftoverDamage > 0 then
                                hum:TakeDamage(leftoverDamage)
                            end
                        end
                    end
                end
            end
            task.wait(puddleConfig.PuddleTickInterval)
        end
    end

	-- === ATTACK LOGIC ===
	local attackCoroutine = task.spawn(function()
		while zombie.Parent and humanoid.Health > 0 do
			if transitioning then
				task.wait(0.5)
				continue
			end

			local now = tick()
			local target = findTarget(zombie)
			if not target then
				task.wait(1)
				continue
			end

			humanoid:MoveTo(target.Character.HumanoidRootPart.Position)

			if currentState == "Phase1" then
				-- PHASE 1 ATTACK PATTERN
				if now > attackCooldowns.CorrosiveSlam then
					attackCooldowns.CorrosiveSlam = now + config.CorrosiveSlam.Cooldown
					humanoid:MoveTo(zombie.PrimaryPart.Position)
                    local slamPosition = zombie.PrimaryPart.Position
					Boss1VFXModule.CreateCorrosiveSlamTelegraph(zombie, config.CorrosiveSlam)
					task.wait(config.CorrosiveSlam.TelegraphDuration)
					Boss1VFXModule.ExecuteCorrosiveSlamVFX(slamPosition, config.CorrosiveSlam)
					-- Server-side damage logic for Corrosive Slam
                    for _, player in ipairs(Players:GetPlayers()) do
                        local char = player.Character
                        if char and not ElementModule.IsPlayerInvincible(player) then
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            if hum and hum.Health > 0 and hrp then
                                if (hrp.Position - slamPosition).Magnitude <= config.CorrosiveSlam.Radius then
                                    local damage = config.CorrosiveSlam.Damage
                                    damage = ElementModule.ApplyDamageReduction(player, damage)
                                    local leftoverDamage = ShieldModule.Damage(player, damage)
                                    if leftoverDamage > 0 then
                                        hum:TakeDamage(leftoverDamage)
                                    end
                                end
                            end
                        end
                    end
				elseif now > attackCooldowns.ToxicLob then
					attackCooldowns.ToxicLob = now + config.ToxicLob.Cooldown
					local lobTarget = findTarget(zombie)
					if lobTarget then
                        local targetPosition = lobTarget.Character.HumanoidRootPart.Position
						Boss1VFXModule.CreateToxicLobTelegraph(targetPosition, config.ToxicLob)
						task.wait(config.ToxicLob.TelegraphDuration)
						Boss1VFXModule.ExecuteToxicLob(targetPosition, config.ToxicLob)
                        task.spawn(handlePuddleDamage, targetPosition, config.ToxicLob)
					end
				end
			elseif currentState == "Phase2" then
				-- PHASE 2 ATTACK PATTERN
				if now > attackCooldowns.FissionBarrage then
					attackCooldowns.FissionBarrage = now + config.FissionBarrage.Cooldown
					humanoid:MoveTo(zombie.PrimaryPart.Position)
					for i = 1, config.FissionBarrage.ProjectileCount do
						local barrageTarget = findTarget(zombie)
						if barrageTarget then
                            local targetPosition = barrageTarget.Character.HumanoidRootPart.Position
							Boss1VFXModule.CreateToxicLobTelegraph(targetPosition, config.ToxicLob)
							task.wait(config.ToxicLob.TelegraphDuration)
							Boss1VFXModule.ExecuteToxicLob(targetPosition, config.ToxicLob)
                            task.spawn(handlePuddleDamage, targetPosition, config.ToxicLob)
							task.wait(config.FissionBarrage.IntervalBetweenShots)
						end
					end
				elseif now > attackCooldowns.VolatileMinions then
					attackCooldowns.VolatileMinions = now + config.VolatileMinions.Cooldown
					local spawnCount = math.random(config.VolatileMinions.SpawnCount[1], config.VolatileMinions.SpawnCount[2])
					for i = 1, spawnCount do
						SpawnerModule.SpawnVolatileMinion(zombie.PrimaryPart.Position, config.VolatileMinions)
					end
				elseif now > attackCooldowns.CorrosiveSlam then
					attackCooldowns.CorrosiveSlam = now + config.CorrosiveSlam.Cooldown
					humanoid:MoveTo(zombie.PrimaryPart.Position)
                    local slamPosition = zombie.PrimaryPart.Position
					Boss1VFXModule.CreateCorrosiveSlamTelegraph(zombie, config.CorrosiveSlam)
					task.wait(config.CorrosiveSlam.TelegraphDuration)
					Boss1VFXModule.ExecuteCorrosiveSlamVFX(slamPosition, config.CorrosiveSlam)
                    -- Server-side damage logic for Corrosive Slam
                    for _, player in ipairs(Players:GetPlayers()) do
                        local char = player.Character
                        if char and not ElementModule.IsPlayerInvincible(player) then
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            if hum and hum.Health > 0 and hrp then
                                if (hrp.Position - slamPosition).Magnitude <= config.CorrosiveSlam.Radius then
                                    local damage = config.CorrosiveSlam.Damage
                                    damage = ElementModule.ApplyDamageReduction(player, damage)
                                    local leftoverDamage = ShieldModule.Damage(player, damage)
                                    if leftoverDamage > 0 then
                                        hum:TakeDamage(leftoverDamage)
                                    end
                                end
                            end
                        end
                    end
				elseif now > attackCooldowns.ToxicLob then
					attackCooldowns.ToxicLob = now + config.ToxicLob.Cooldown
					local lobTarget = findTarget(zombie)
					if lobTarget then
                        local targetPosition = lobTarget.Character.HumanoidRootPart.Position
						Boss1VFXModule.CreateToxicLobTelegraph(targetPosition, config.ToxicLob)
						task.wait(config.ToxicLob.TelegraphDuration)
						Boss1VFXModule.ExecuteToxicLob(targetPosition, config.ToxicLob)
                        task.spawn(handlePuddleDamage, targetPosition, config.ToxicLob)
					end
				end
			end

			task.wait(0.5)
		end
	end)

	-- === CLEANUP ===
	humanoid.Died:Connect(function()
		BossTimerEvent:FireAllClients(0, 0)
		task.cancel(timerCoroutine)
		task.cancel(radiationCoroutine)
		task.cancel(attackCoroutine)
	end)
end

return Boss1
