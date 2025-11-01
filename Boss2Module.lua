-- Boss2Module.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BossModule/Boss2Module.lua
-- Script Place: ACT 1: Village

local Boss2 = {}

-- Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Boss2VFXModule = require(ReplicatedStorage.ZombieVFX:WaitForChild("Boss2VFXModule"))
local ElementModule = require(ServerScriptService.ModuleScript:WaitForChild("ElementConfigModule"))
local ShieldModule = require(ServerScriptService.ModuleScript:WaitForChild("ShieldModule"))

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

function Boss2.Init(zombie, humanoid, config, executeHardWipe)
	-- === INITIALIZATION ===
	local bossTag = Instance.new("BoolValue")
	bossTag.Name = "IsBoss"
	bossTag.Parent = zombie
	BossAlertEvent:FireAllClients(config.Name or "Boss")

	local currentState = "Phase1"
	local transitioning = false
	local attackCooldowns = {
		OrbOfAnnihilation = 0,
		PlatformShatter = 0,
		DualOrbSummon = 0,
		CelestialRain = 0,
	}
	local arenaPlatforms = {}
	local activeOrbs = {}

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

	-- === ORB OF ANNIHILATION LOGIC ===
	local function spawnOrb(targetPlayer)
		local orbConfig = config.OrbOfAnnihilation
		local orb = Boss2VFXModule.CreateOrbOfAnnihilation(zombie.PrimaryPart.Position)
		table.insert(activeOrbs, orb)

		local orbCoroutine = task.spawn(function()
			local startTime = tick()
			while orb and orb.Parent and (tick() - startTime) < orbConfig.Lifetime do
				local target = targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
				if not target then break end

				orb.CFrame = CFrame.new(orb.Position, target.Position)
				orb.Velocity = orb.CFrame.LookVector * orbConfig.OrbSpeed

				if (orb.Position - target.Position).Magnitude < 5 then
					-- Explode
					Boss2VFXModule.ExecuteOrbExplosion(orb.Position, orbConfig)
					for _, player in ipairs(Players:GetPlayers()) do
						local char = player.Character
						if char and not ElementModule.IsPlayerInvincible(player) then
							local hum = char:FindFirstChildOfClass("Humanoid")
							local hrp = char:FindFirstChild("HumanoidRootPart")
							if hum and hum.Health > 0 and hrp and (hrp.Position - orb.Position).Magnitude <= orbConfig.ExplosionRadius then
								local damage = ElementModule.ApplyDamageReduction(player, orbConfig.ExplosionDamage)
								local leftoverDamage = ShieldModule.Damage(player, damage)
								if leftoverDamage > 0 then hum:TakeDamage(leftoverDamage) end
							end
						end
					end
					break
				end
				task.wait()
			end
			if orb and orb.Parent then orb:Destroy() end
			for i, activeOrb in ipairs(activeOrbs) do
				if activeOrb == orb then
					table.remove(activeOrbs, i)
					break
				end
			end
		end)
	end

	-- === HEALTH CHANGE & PHASE TRANSITION ===
	humanoid.HealthChanged:Connect(function(health)
		if transitioning or currentState ~= "Phase1" then return end

		if health / humanoid.MaxHealth <= config.Upheaval.TriggerHPPercent then
			transitioning = true
			currentState = "Transition"
			humanoid.WalkSpeed = 0

			arenaPlatforms = Boss2VFXModule.CreateUpheaval(zombie.PrimaryPart.Position, config.Upheaval)

			task.wait(config.Upheaval.Duration)

			humanoid.WalkSpeed = config.WalkSpeed
			currentState = "Phase2"
			transitioning = false
		end
	end)

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
				if now > attackCooldowns.OrbOfAnnihilation then
					attackCooldowns.OrbOfAnnihilation = now + config.OrbOfAnnihilation.Cooldown
					local orbTarget = findTarget(zombie)
					if orbTarget then spawnOrb(orbTarget) end
				end
			elseif currentState == "Phase2" then
				if now > attackCooldowns.CelestialRain then
					attackCooldowns.CelestialRain = now + config.CelestialRain.Cooldown
					humanoid:MoveTo(zombie.PrimaryPart.Position)
					for i = 1, config.CelestialRain.ProjectileCount do
						local platform = arenaPlatforms[math.random(#arenaPlatforms)]
						local targetPos = platform.Position + Vector3.new(math.random(-config.Upheaval.PlatformSize.X/2, config.Upheaval.PlatformSize.X/2), 0, math.random(-config.Upheaval.PlatformSize.Z/2, config.Upheaval.PlatformSize.Z/2))
						Boss2VFXModule.CreateCelestialRainTelegraph(targetPos, config.CelestialRain)
						task.wait(config.CelestialRain.TelegraphDuration)
						Boss2VFXModule.ExecuteCelestialRain(targetPos, config.CelestialRain)
						-- Damage
						for _, player in ipairs(Players:GetPlayers()) do
							local char = player.Character
							if char and not ElementModule.IsPlayerInvincible(player) then
								local hum = char:FindFirstChildOfClass("Humanoid")
								local hrp = char:FindFirstChild("HumanoidRootPart")
								if hum and hum.Health > 0 and hrp and (hrp.Position - targetPos).Magnitude <= config.CelestialRain.BlastRadius then
									local damage = ElementModule.ApplyDamageReduction(player, config.CelestialRain.BlastDamage)
									local leftoverDamage = ShieldModule.Damage(player, damage)
									if leftoverDamage > 0 then hum:TakeDamage(leftoverDamage) end
								end
							end
						end
						task.wait(config.CelestialRain.Interval)
					end
				elseif now > attackCooldowns.DualOrbSummon then
					attackCooldowns.DualOrbSummon = now + config.DualOrbSummon.Cooldown
					local targets = Players:GetPlayers()
					if #targets > 0 then spawnOrb(targets[math.random(#targets)]) end
					if #targets > 1 then spawnOrb(targets[math.random(#targets)]) end
				elseif now > attackCooldowns.PlatformShatter then
					attackCooldowns.PlatformShatter = now + config.PlatformShatter.Cooldown
					local platform = arenaPlatforms[math.random(#arenaPlatforms)]
					Boss2VFXModule.CreatePlatformShatterTelegraph(platform, config.PlatformShatter)
					task.wait(config.PlatformShatter.TelegraphDuration)
					Boss2VFXModule.ExecutePlatformShatter(platform, config.PlatformShatter)
					-- Damage dealt via VFX module through touch events
				end
			end

			task.wait(0.5)
		end
	end)

	-- === CLEANUP ===
	humanoid.Died:Connect(function()
		BossTimerEvent:FireAllClients(0, 0)
		for _, orb in ipairs(activeOrbs) do if orb and orb.Parent then orb:Destroy() end end
		for _, platform in ipairs(arenaPlatforms) do if platform and platform.Parent then platform:Destroy() end end
		task.cancel(timerCoroutine)
		task.cancel(attackCoroutine)
	end)
end

return Boss2
