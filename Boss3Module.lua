-- Boss3Module.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BossModule/Boss3Module.lua
-- Script Place: ACT 1: Village

local Boss3 = {}

-- Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Boss3VFXModule = require(ReplicatedStorage.ZombieVFX:WaitForChild("Boss3VFXModule"))
local Boss2VFXModule = require(ReplicatedStorage.ZombieVFX:WaitForChild("Boss2VFXModule")) -- For some shared UI
local ElementModule = require(ServerScriptService.ModuleScript:WaitForChild("ElementConfigModule"))
local ShieldModule = require(ServerScriptService.ModuleScript:WaitForChild("ShieldModule"))
local BossTimerEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BossTimerEvent")
local ZombieModule -- Forward declaration

function Boss3.Init(zombie, humanoid, config, executeHardWipe, zombieModuleRef)
	ZombieModule = zombieModuleRef -- Set the reference

	-- Tag the zombie as a boss
	local bossTag = Instance.new("BoolValue")
	bossTag.Name = "IsBoss"
	bossTag.Parent = zombie

	-- Fire the "Boss Incoming" alert
	local bossAlert = ReplicatedStorage.RemoteEvents:FindFirstChild("BossIncoming")
	if not bossAlert then
		bossAlert = Instance.new("RemoteEvent")
		bossAlert.Name = "BossIncoming"
		bossAlert.Parent = ReplicatedStorage.RemoteEvents
	end
	bossAlert:FireAllClients()

	-- Timer & wipe on timeout
	local specialTimeout = (config and config.SpecialTimeout) or 300
	local bossStartTime = tick()
	BossTimerEvent:FireAllClients(specialTimeout, specialTimeout)
	task.spawn(function()
		while zombie.Parent and humanoid and humanoid.Health > 0 do
			local remaining = math.max(0, specialTimeout - (tick() - bossStartTime))
			BossTimerEvent:FireAllClients(remaining, specialTimeout)
			if remaining <= 0 then
				executeHardWipe(zombie, humanoid)
				break
			end
			task.wait(1)
		end
	end)

	-- Radiation Aura
	task.spawn(function()
		local r = config and config.Radiation
		local tickTime = (r and r.Tick) or 0.5
		local hr = (r and r.HorizontalRadius) or 6
		local vy = (r and r.VerticalHalfHeight) or 1000
		local dpsPct = (r and r.DamagePerSecondPct) or 0.01
		while zombie.Parent and humanoid and humanoid.Health > 0 do
			local bossPos = (zombie.PrimaryPart and zombie.PrimaryPart.Position) or zombie:GetModelCFrame().p
			for _, plr in ipairs(game.Players:GetPlayers()) do
				local char = plr.Character
				if char and not ElementModule.IsPlayerInvincible(plr) then
					local hum = char:FindFirstChildOfClass("Humanoid")
					local hrp = char:FindFirstChild("HumanoidRootPart")
					if hum and hum.Health > 0 and hrp then
						if (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(bossPos.X, bossPos.Z)).Magnitude <= hr and math.abs(hrp.Position.Y - bossPos.Y) <= vy then
							local dmg = ElementModule.ApplyDamageReduction(plr, hum.MaxHealth * dpsPct * tickTime)
							local leftoverDamage = ShieldModule.Damage(plr, dmg)
							if leftoverDamage > 0 then hum:TakeDamage(leftoverDamage) end
						end
					end
				end
			end
			task.wait(tickTime)
		end
	end)

	-- Corrupting Blast Attack
	task.spawn(function()
		local blastConf = config and config.CorruptingBlast
		if not blastConf then return end
		while zombie.Parent and humanoid and humanoid.Health > 0 do
			task.wait(blastConf.Cooldown or 10)
			if not zombie.Parent or not humanoid or humanoid.Health <= 0 then break end
			local target = ZombieModule.GetNearestPlayer(zombie)
			if target and target.Character then
				local targetPos = target.Character.HumanoidRootPart.Position
				Boss3VFXModule.CreateCorruptingBlastTelegraph(targetPos, blastConf.BlastRadius or 15, blastConf.TelegraphDuration or 1.5)
				task.wait(blastConf.TelegraphDuration or 1.5)
				if not zombie.Parent or not humanoid or humanoid.Health <= 0 then break end
				Boss3VFXModule.CreateCorruptingBlastEffect(targetPos, blastConf.BlastRadius or 15, blastConf.PuddleDuration or 3)
				for _, plr in ipairs(game.Players:GetPlayers()) do
					if plr.Character and not ElementModule.IsPlayerInvincible(plr) then
						local hum, hrp = plr.Character:FindFirstChildOfClass("Humanoid"), plr.Character:FindFirstChild("HumanoidRootPart")
						if hum and hum.Health > 0 and hrp and (hrp.Position - targetPos).Magnitude <= (blastConf.BlastRadius or 15) then
							local damage = ElementModule.ApplyDamageReduction(plr, blastConf.BlastDamage or 35)
							local leftoverDamage = ShieldModule.Damage(plr, damage)
							if leftoverDamage > 0 then hum:TakeDamage(leftoverDamage) end
						end
					end
				end
				local puddleEndTime = tick() + (blastConf.PuddleDuration or 3)
				while tick() < puddleEndTime do
					if not zombie.Parent or not humanoid or humanoid.Health <= 0 then break end
					for _, plr in ipairs(game.Players:GetPlayers()) do
						if plr.Character and not ElementModule.IsPlayerInvincible(plr) then
							local hum, hrp = plr.Character:FindFirstChildOfClass("Humanoid"), plr.Character:FindFirstChild("HumanoidRootPart")
							if hum and hum.Health > 0 and hrp and (hrp.Position - targetPos).Magnitude <= (blastConf.BlastRadius or 15) then
								local damage = ElementModule.ApplyDamageReduction(plr, blastConf.PuddleDamagePerTick or 5)
								local leftoverDamage = ShieldModule.Damage(plr, damage)
								if leftoverDamage > 0 then hum:TakeDamage(leftoverDamage) end
							end
						end
					end
					task.wait(blastConf.PuddleTickInterval or 0.5)
				end
			end
		end
	end)

	-- Grasping Souls Attack
	task.spawn(function()
		local soulConf = config and config.GraspingSouls
		if not soulConf then return end
		while zombie.Parent and humanoid and humanoid.Health > 0 do
			task.wait(soulConf.Cooldown or 12)
			if not zombie.Parent or not humanoid or humanoid.Health <= 0 then break end
			local players = game:GetService("Players"):GetPlayers()
			local availablePlayers = {}
			for _, p in ipairs(players) do
				if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and not p.Character:FindFirstChild("Knocked") then
					table.insert(availablePlayers, p)
				end
			end
			if #availablePlayers > 0 then
				local soulCount = math.min(math.random(soulConf.SoulCount[1], soulConf.SoulCount[2]), #availablePlayers)
				Boss3VFXModule.CreateGraspingSoulsTelegraph(zombie, soulCount, soulConf.TelegraphDuration or 1.5)
				task.wait(soulConf.TelegraphDuration or 1.5)
				if not zombie.Parent or not humanoid or humanoid.Health <= 0 then break end
				-- Shuffle players
				for i = #availablePlayers, 2, -1 do
					local j = math.random(i)
					availablePlayers[i], availablePlayers[j] = availablePlayers[j], availablePlayers[i]
				end
				for i = 1, soulCount do
					local targetPlayer = availablePlayers[i]
					if targetPlayer and targetPlayer.Character then
						local startPos = zombie.PrimaryPart.Position + Vector3.new(0, 5, 0)
						local soul = Boss3VFXModule.CreateGraspingSoul(startPos, soulConf)
						local bv = Instance.new("BodyVelocity", soul)
						bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
						bv.P = 5000
						task.spawn(function()
							local startTime = tick()
							local lifetime = 15
							local soulConnection
							soulConnection = game:GetService("RunService").Heartbeat:Connect(function()
								if not soul or not soul.Parent or not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") or (tick() - startTime > lifetime) or (soul.Position - targetPlayer.Character.HumanoidRootPart.Position).Magnitude < 3 then
									soulConnection:Disconnect()
									local explosionPos = (tick() - startTime > lifetime) and soul.Position or targetPlayer.Character.HumanoidRootPart.Position
									Boss3VFXModule.CreateSoulExplosion(explosionPos, soulConf.BlastRadius or 8)
									for _, plr in ipairs(game.Players:GetPlayers()) do
										if plr.Character and not ElementModule.IsPlayerInvincible(plr) then
											local hum, hrp = plr.Character:FindFirstChildOfClass("Humanoid"), plr.Character:FindFirstChild("HumanoidRootPart")
											if hum and hum.Health > 0 and hrp and (hrp.Position - explosionPos).Magnitude <= (soulConf.BlastRadius or 8) then
												local damage = ElementModule.ApplyDamageReduction(plr, soulConf.BlastDamage or 25)
												local leftoverDamage = ShieldModule.Damage(plr, damage)
												if leftoverDamage > 0 then hum:TakeDamage(leftoverDamage) end
												pcall(require(script.Parent.Parent:WaitForChild("DebuffModule")).ApplySpeedDebuff, plr, "SoulTaint", 1 - soulConf.DebuffSlowPct, soulConf.DebuffDuration)
											end
										end
									end
									if soul and soul.Parent then soul:Destroy() end
								else
									bv.Velocity = (targetPlayer.Character.HumanoidRootPart.Position - soul.Position).Unit * soulConf.SoulSpeed
								end
							end)
						end)
					end
				end
			end
		end
	end)

	-- Mirror Quartet Mechanic
	local mqTriggered = false
	local function startMirrorQuartet()
		if mqTriggered then return end
		mqTriggered = true
		zombie:SetAttribute("Immune", true)
		zombie:SetAttribute("MechanicFreeze", true) -- Fix: Freeze the boss
		local prevWalk, prevAutoR = humanoid.WalkSpeed, humanoid.AutoRotate
		humanoid.WalkSpeed, humanoid.JumpPower, humanoid.AutoRotate = 0, 0, false
		local mqConfig = config.MirrorQuartet
		local duration = mqConfig.Duration or 25
		local requiredPlayers = math.min(#game:GetService("Players"):GetPlayers(), mqConfig.RequiredPlayers or 4)
		local mechGui = Boss2VFXModule.ShowMechanicCountdownUI(zombie, "Align the Mirrors", duration)
		local mechanicContext = Boss3VFXModule.StartMirrorQuartet(zombie, mqConfig)
		task.spawn(function()
			local success, mechanicStartTime, allMirrorsLockedStartTime = false, tick(), nil
			while tick() - mechanicStartTime < duration do
				local allLocked = true
				for i = 1, requiredPlayers do
					if not mechanicContext.Mirrors[i] or not mechanicContext.Mirrors[i].locked then allLocked, allMirrorsLockedStartTime = false, nil break end
				end
				if allLocked then
					if not allMirrorsLockedStartTime then allMirrorsLockedStartTime = tick() end
					if tick() - allMirrorsLockedStartTime >= 3 then success = true; break end
				end
				task.wait(0.1)
			end
			Boss3VFXModule.Cleanup(mechanicContext)
			if mechGui and mechGui.Parent then mechGui:Destroy() end
			humanoid.WalkSpeed, humanoid.AutoRotate = prevWalk, prevAutoR
			if not success then
				local dr, drDuration = mqConfig.FailDR or 0.5, mqConfig.FailDRDuration or 30
				zombie:SetAttribute("DamageReductionPct", dr)
				Boss2VFXModule.ShowDamageReductionUI(zombie, dr, drDuration)
				task.delay(drDuration, function() if zombie and zombie.Parent then zombie:SetAttribute("DamageReductionPct", 0) end end)
			end
			zombie:SetAttribute("Immune", false)
			zombie:SetAttribute("MechanicFreeze", false) -- Fix: Unfreeze the boss
		end)
	end

	-- Chromatic Requiem Mechanic
	local crTriggered = false
	local function startChromaticRequiem()
		if crTriggered then return end
		crTriggered = true
		zombie:SetAttribute("Immune", true)
		zombie:SetAttribute("MechanicFreeze", true) -- Fix: Freeze the boss
		local prevWalk = humanoid.WalkSpeed
		humanoid.WalkSpeed = 0
		local crConfig = config.ChromaticRequiem
		local duration = crConfig.Duration or 30
		local mechanicContext = Boss3VFXModule.StartChromaticRequiem(zombie, crConfig)
		local alivePlayers = {}
		for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
				table.insert(alivePlayers, p)
			end
		end
		local activeCrystalsCount = math.max(1, math.min(#alivePlayers, 4))
		local allColors = {"North", "East", "South", "West"}
		local purificationOrder = {}
		for i = #allColors, 2, -1 do local j = math.random(i); allColors[i], allColors[j] = allColors[j], allColors[i] end
		for i = 1, activeCrystalsCount do table.insert(purificationOrder, allColors[i]) end
		local uiEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("ChromaticRequiemUIEvent") or Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
		uiEvent.Name = "ChromaticRequiemUIEvent"
		uiEvent:FireAllClients("show", table.clone(purificationOrder), zombie)
		task.spawn(function()
			local success, mechanicStartTime, currentPrompt = false, tick(), nil
			local function updatePrompt()
				if currentPrompt and currentPrompt.Parent then currentPrompt:Destroy() end
				if #purificationOrder > 0 then
					local crystal = mechanicContext.Crystals[purificationOrder[1]]
					if crystal then
						currentPrompt = Instance.new("ProximityPrompt", crystal)
						currentPrompt.ActionText, currentPrompt.ObjectText, currentPrompt.HoldDuration, currentPrompt.MaxActivationDistance, currentPrompt.RequiresLineOfSight = "Purify", "Purify " .. purificationOrder[1] .. " Crystal", 1.5, 15, false
						table.insert(mechanicContext.Objects, currentPrompt)
						currentPrompt.Triggered:Connect(function()
							local purifiedColor = table.remove(purificationOrder, 1)
							uiEvent:FireAllClients("update", purificationOrder, zombie)
							if mechanicContext.Crystals[purifiedColor] then mechanicContext.Crystals[purifiedColor].Color = Color3.fromRGB(50, 50, 50) end
							if mechanicContext.Beams[purifiedColor] and mechanicContext.Beams[purifiedColor].Parent then mechanicContext.Beams[purifiedColor]:Destroy() end
							updatePrompt()
						end)
					end
				end
			end
			updatePrompt()
			while tick() - mechanicStartTime < duration do
				if #purificationOrder == 0 then success = true; break end
				task.wait(0.2)
			end
			uiEvent:FireAllClients("hide")
			Boss3VFXModule.CleanupChromaticRequiem(mechanicContext)
			humanoid.WalkSpeed = prevWalk
			if success then
				zombie:SetAttribute("Stunned", true)
				task.wait(crConfig.SuccessStunDuration or 5)
				zombie:SetAttribute("Stunned", false)
			else
				local dr, drDuration = crConfig.FailDR or 0.5, crConfig.FailDRDuration or 30
				zombie:SetAttribute("DamageReductionPct", dr)
				task.delay(drDuration, function() if zombie and zombie.Parent then zombie:SetAttribute("DamageReductionPct", 0) end end)
			end
			zombie:SetAttribute("Immune", false)
			zombie:SetAttribute("MechanicFreeze", false) -- Fix: Unfreeze the boss
		end)
	end

	-- Trigger mechanics based on health
	humanoid.HealthChanged:Connect(function(h)
		if humanoid.MaxHealth > 0 then
			if config.MirrorQuartet and not mqTriggered and (h / humanoid.MaxHealth) <= (config.MirrorQuartet.TriggerHPPercent or 0.5) then
				startMirrorQuartet()
			end
			if config.ChromaticRequiem and not crTriggered and (h / humanoid.MaxHealth) <= (config.ChromaticRequiem.TriggerHPPercent or 0.25) then
				startChromaticRequiem()
			end
		end
	end)

	-- Stop timer on death
	humanoid.Died:Connect(function()
		if BossTimerEvent then BossTimerEvent:FireAllClients(0, 0) end
	end)
end

return Boss3
