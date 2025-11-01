-- Boss3Module.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BossModule/Boss3Module.lua
-- Script Place: ACT 1: Village

local Boss3 = {}

-- Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Boss3VFXModule = require(ReplicatedStorage.ZombieVFX:WaitForChild("Boss3VFXModule"))
local ElementModule = require(ServerScriptService.ModuleScript:WaitForChild("ElementConfigModule"))
local ShieldModule = require(ServerScriptService.ModuleScript:WaitForChild("ShieldModule"))
local SpawnerModule -- Akan diinisialisasi melalui Init

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

function Boss3.Init(zombie, humanoid, config, executeHardWipe, spawnerModuleRef)
	SpawnerModule = spawnerModuleRef
	-- === INITIALIZATION ===
	local bossTag = Instance.new("BoolValue")
	bossTag.Name = "IsBoss"
	bossTag.Parent = zombie
	BossAlertEvent:FireAllClients(config.Name or "Boss")

	local currentMovement = nil
	local transitioning = false
	local attackCooldowns = {
		SoulStream = 0,
		NecroticEruption = 0,
		CorruptingBlast = 0,
		ChainsOfTorment = 0,
		EchoesOfTheMaestro = 0,
		CrescendoOfSouls = 0,
	}
	local activeEchoes = {}
	local chainedPlayers = {}

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

	-- === MOVEMENT (PHASE) MANAGER ===
	local movementCoroutine = task.spawn(function()
		local movements = {"Allegro", "Adagio", "Fortissimo"}
		while zombie.Parent and humanoid.Health > 0 do
			transitioning = true
			local nextMovement = movements[math.random(#movements)]
			currentMovement = nextMovement
			Boss3VFXModule.CreateMovementTransition(zombie, currentMovement)
			task.wait(3) -- Durasi transisi
			transitioning = false

			local movementDuration = math.random(config.Movements.Duration.min, config.Movements.Duration.max)
			task.wait(movementDuration)
		end
	end)

	-- === ATTACK LOGIC ===
	local attackCoroutine = task.spawn(function()
		while zombie.Parent and humanoid.Health > 0 do
			if transitioning or not currentMovement then
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

			if currentMovement == "Allegro" then
				local movementConfig = config.Movements.Allegro
				if now > attackCooldowns.SoulStream then
					attackCooldowns.SoulStream = now + movementConfig.SoulStream.Cooldown
					local streamTarget = findTarget(zombie)
					if streamTarget then
						task.spawn(function()
							for i = 1, movementConfig.SoulStream.ProjectileCount do
								if not zombie or not zombie.Parent or not streamTarget or not streamTarget.Parent then break end
								local startPos = zombie.PrimaryPart.Position
								local targetPos = streamTarget.Character.HumanoidRootPart.Position
								local direction = (targetPos - startPos).Unit
								Boss3VFXModule.CreateSoulStreamProjectile(startPos, direction, movementConfig.SoulStream)
								task.wait(movementConfig.SoulStream.Interval)
							end
						end)
					end
				elseif now > attackCooldowns.NecroticEruption then
					attackCooldowns.NecroticEruption = now + movementConfig.NecroticEruption.Cooldown
					task.spawn(function()
						local players = Players:GetPlayers()
						for i = 1, movementConfig.NecroticEruption.PillarCount do
							if #players == 0 then break end
							local player = players[math.random(#players)]
							local char = player.Character
							if char then
								local pos = char.HumanoidRootPart.Position
								Boss3VFXModule.CreateNecroticEruptionTelegraph(pos, movementConfig.NecroticEruption)
							end
						end
						task.wait(movementConfig.NecroticEruption.TelegraphDuration)
						-- Damage is handled by the VFX module via touch events for pillars
					end)
				end
			elseif currentMovement == "Adagio" then
				local movementConfig = config.Movements.Adagio
				if now > attackCooldowns.CorruptingBlast then
					attackCooldowns.CorruptingBlast = now + movementConfig.CorruptingBlast.Cooldown
					local blastTarget = findTarget(zombie)
					if blastTarget then
						task.spawn(function()
							local targetPos = blastTarget.Character.HumanoidRootPart.Position
							Boss3VFXModule.CreateCorruptingBlastTelegraph(targetPos, movementConfig.CorruptingBlast)
							task.wait(movementConfig.CorruptingBlast.TelegraphDuration)
							Boss3VFXModule.ExecuteCorruptingBlast(targetPos, movementConfig.CorruptingBlast)
							-- Damage logic for puddle
							local puddleEndTime = tick() + movementConfig.CorruptingBlast.PuddleDuration
							while tick() < puddleEndTime do
								for _, plr in ipairs(Players:GetPlayers()) do
									if plr.Character and (plr.Character.HumanoidRootPart.Position - targetPos).Magnitude < movementConfig.CorruptingBlast.BlastRadius then
										plr.Character.Humanoid:TakeDamage(movementConfig.CorruptingBlast.PuddleDamagePerTick)
									end
								end
								task.wait(movementConfig.CorruptingBlast.PuddleTickInterval)
							end
						end)
					end
				elseif now > attackCooldowns.ChainsOfTorment then
					attackCooldowns.ChainsOfTorment = now + movementConfig.ChainsOfTorment.Cooldown
					local players = Players:GetPlayers()
					if #players >= 2 then
						local p1 = players[math.random(#players)]
						local p2 = players[math.random(#players)]
						while p1 == p2 do p2 = players[math.random(#players)] end

						local chain = Boss3VFXModule.CreateChainsOfTorment(p1, p2, movementConfig.ChainsOfTorment)
						table.insert(chainedPlayers, {p1, p2, chain, tick()})
					end
				end
			elseif currentMovement == "Fortissimo" then
				local movementConfig = config.Movements.Fortissimo
				if now > attackCooldowns.CrescendoOfSouls then
					attackCooldowns.CrescendoOfSouls = now + movementConfig.CrescendoOfSouls.Cooldown
					humanoid:MoveTo(zombie.PrimaryPart.Position)
					task.spawn(function()
						local safePillar = Boss3VFXModule.CreateCrescendoOfSoulsTelegraph(zombie, movementConfig.CrescendoOfSouls)
						task.wait(movementConfig.CrescendoOfSouls.ChargeDuration)
						Boss3VFXModule.ExecuteCrescendoOfSouls(zombie, safePillar, movementConfig.CrescendoOfSouls)
						for _, plr in ipairs(Players:GetPlayers()) do
							if plr.Character then
								local hrp = plr.Character.HumanoidRootPart
								if hrp and safePillar and (hrp.Position - safePillar.Position).Magnitude > 20 then -- Assuming 20 is a safe radius
									plr.Character.Humanoid:TakeDamage(movementConfig.CrescendoOfSouls.Damage)
								end
							end
						end
					end)
				elseif now > attackCooldowns.EchoesOfTheMaestro then
					attackCooldowns.EchoesOfTheMaestro = now + movementConfig.EchoesOfTheMaestro.Cooldown
					local echoCount = math.min(movementConfig.MaxEchoes, math.floor(#Players:GetPlayers() / 2))
					for i = 1, echoCount do
						local echo = SpawnerModule.SpawnEcho(zombie.PrimaryPart.Position, movementConfig.EchoesOfTheMaestro)
						if echo then
							table.insert(activeEchoes, echo)
						end
					end
				end
			end

			-- Handle Chains of Torment damage
			for i = #chainedPlayers, 1, -1 do
				local chainInfo = chainedPlayers[i]
				local p1, p2, chain, startTime = chainInfo[1], chainInfo[2], chainInfo[3], chainInfo[4]
				if not p1 or not p1.Parent or not p2 or not p2.Parent or (tick() - startTime) > config.Movements.Adagio.ChainsOfTorment.Duration then
					if chain and chain.Parent then chain:Destroy() end
					table.remove(chainedPlayers, i)
				else
					if (p1.Character.HumanoidRootPart.Position - p2.Character.HumanoidRootPart.Position).Magnitude > config.Movements.Adagio.ChainsOfTorment.MaxDistance then
						p1.Character.Humanoid:TakeDamage(config.Movements.Adagio.ChainsOfTorment.DamagePerSecond)
						p2.Character.Humanoid:TakeDamage(config.Movements.Adagio.ChainsOfTorment.DamagePerSecond)
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
		task.cancel(attackCoroutine)
		task.cancel(movementCoroutine)
		for _, echo in ipairs(activeEchoes) do if echo and echo.Parent then echo:Destroy() end end
	end)
end

return Boss3
