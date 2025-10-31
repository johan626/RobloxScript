-- Boss2Module.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BossModule/Boss2Module.lua
-- Script Place: ACT 1: Village

local Boss2 = {}

-- Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Boss2VFXModule = require(ReplicatedStorage.ZombieVFX:WaitForChild("Boss2VFXModule"))
local ElementModule = require(ServerScriptService.ModuleScript:WaitForChild("ElementConfigModule"))
local ShieldModule = require(ServerScriptService.ModuleScript:WaitForChild("ShieldModule"))
local BossTimerEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BossTimerEvent")
local ZombieModule -- Forward declaration

function Boss2.Init(zombie, humanoid, config, executeHardWipe, zombieModuleRef)
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
		local dpsPct = (r and r.DamagePerSecondPct) or 0.02
		while zombie.Parent and humanoid and humanoid.Health > 0 do
			local bossPos = (zombie.PrimaryPart and zombie.PrimaryPart.Position) or zombie:GetModelCFrame().p
			for _, plr in ipairs(game.Players:GetPlayers()) do
				local char = plr.Character
				if char and not ElementModule.IsPlayerInvincible(plr) then
					local hum = char:FindFirstChildOfClass("Humanoid")
					local hrp = char:FindFirstChild("HumanoidRootPart")
					if hum and hum.Health > 0 and hrp then
						local dxz = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(bossPos.X, bossPos.Z)).Magnitude
						local dy  = math.abs(hrp.Position.Y - bossPos.Y)
						if dxz <= hr and dy <= vy then
							local dmg = ElementModule.ApplyDamageReduction(plr, hum.MaxHealth * dpsPct * tickTime)
							local leftoverDamage = ShieldModule.Damage(plr, dmg)
							if leftoverDamage > 0 then
								hum:TakeDamage(leftoverDamage)
							end
						end
					end
				end
			end
			task.wait(tickTime)
		end
	end)

	-- Gravity Well Follow Attack
	task.spawn(function()
		local g = config and config.Gravity
		while zombie.Parent and humanoid and humanoid.Health > 0 do
			local target = ZombieModule.GetNearestPlayer(zombie)
			if target and target.Character then
				local hrp = target.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					Boss2VFXModule.CreateGravityWellStatic(
						hrp.Position,
						(g and g.Duration) or 6,
						15,
						(g and g.PullForce) or 0
					)
				end
			end
			task.wait((g and g.Interval) or 12)
		end
	end)

	-- Gravity Slam Attack
	task.spawn(function()
		local s = config and config.GravitySlam
		local function groundAt(pos)
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {workspace.Terrain}
			rayParams.FilterType = Enum.RaycastFilterType.Include
			local res = workspace:Raycast(pos + Vector3.new(0, 100, 0), Vector3.new(0, -300, 0), rayParams)
			return res and Vector3.new(pos.X, res.Position.Y + 0.05, pos.Z) or (pos + Vector3.new(0, 0.05, 0))
		end

		while zombie.Parent and humanoid and humanoid.Health > 0 do
			local radius    = (s and s.Radius) or 18
			local warnTime  = (s and s.TelegraphTime) or 2
			local implodeT  = (s and s.ImplodeDuration) or 0.3
			local implodeF  = (s and s.ImplodeForce) or 1200
			local explodeF  = (s and s.ExplodeForce) or 1600
			local dmgPct    = (s and s.DamagePct) or 0.15
			local center = (zombie.PrimaryPart and zombie.PrimaryPart.Position) or zombie:GetModelCFrame().p
			center = groundAt(center)

			Boss2VFXModule.ShowSlamTelegraph(center, radius, warnTime)
			task.wait(warnTime)

			do
				local t0 = tick()
				while tick() - t0 < implodeT do
					for _, plr in ipairs(game.Players:GetPlayers()) do
						local char = plr.Character
						local hrp  = char and char:FindFirstChild("HumanoidRootPart")
						if hrp and hrp.Parent and (hrp.Position - center).Magnitude <= radius then
							hrp.AssemblyLinearVelocity = (center - hrp.Position).Unit * implodeF
						end
					end
					task.wait()
				end
			end

			Boss2VFXModule.PlaySlamExplosion(center, radius)
			for _, plr in ipairs(game.Players:GetPlayers()) do
				local char = plr.Character
				local hrp  = char and char:FindFirstChild("HumanoidRootPart")
				local hum  = char and char:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 and (hrp.Position - center).Magnitude <= radius then
					hrp.AssemblyLinearVelocity = (hrp.Position - center).Unit * explodeF
					if not ElementModule.IsPlayerInvincible(plr) then
						local damage = ElementModule.ApplyDamageReduction(plr, hum.MaxHealth * dmgPct)
						local leftoverDamage = ShieldModule.Damage(plr, damage)
						if leftoverDamage > 0 then
							hum:TakeDamage(leftoverDamage)
						end
					end
				end
			end
			task.wait((s and s.Cooldown) or 14)
		end
	end)

	-- 4-Player Coop Mechanic
	local coopTriggered = false
	local function startCoop()
		if coopTriggered then return end
		coopTriggered = true
		zombie:SetAttribute("Immune", true)
		zombie:SetAttribute("MechanicFreeze", true) -- Fix: Freeze the boss during the mechanic
		local prevWalk  = humanoid and humanoid.WalkSpeed or 16
		humanoid.WalkSpeed  = 0

		local c = config and config.Coop
		local duration = (c and c.Duration) or 20
		local mechGui = Boss2VFXModule.ShowMechanicCountdownUI(zombie, "Destroy pad", duration)
		local required = math.max(1, math.min((c and c.RequiredPlayers) or 4, #game.Players:GetPlayers()))
		local okPlayers = {}
		local destroyedBy = {}
		local limitPerPlayer = (#game:GetService("Players"):GetPlayers() > 1)
		local center = zombie.PrimaryPart and zombie.PrimaryPart.Position or zombie:GetModelCFrame().p
		local pads = Boss2VFXModule.SpawnCoopPads(center, required, duration, limitPerPlayer, destroyedBy, okPlayers)

		task.spawn(function()
			local startTime = tick()
			local success = false
			while tick() - startTime < duration do
				if #okPlayers >= required then
					success = true
					break
				end
				task.wait(0.25)
			end

			for _, p in ipairs(pads) do if p and p.Parent then p:Destroy() end end
			if mechGui and mechGui.Parent then mechGui:Destroy() end

			humanoid.WalkSpeed = prevWalk
			if not success then
				local dr = (c and c.FailDR) or 0.5
				local durn = (c and c.FailDRDuration) or 30
				zombie:SetAttribute("DamageReductionPct", dr)
				Boss2VFXModule.ShowDamageReductionUI(zombie, dr, durn)
				task.delay(durn, function()
					if zombie and zombie.Parent then
						zombie:SetAttribute("DamageReductionPct", 0)
					end
				end)
			end
			zombie:SetAttribute("Immune", false)
			zombie:SetAttribute("MechanicFreeze", false) -- Fix: Unfreeze the boss
		end)
	end

	humanoid.HealthChanged:Connect(function(h)
		if humanoid.MaxHealth > 0 then
			if (h / humanoid.MaxHealth) <= ((config and config.Coop and config.Coop.TriggerHPPercent) or 0.5) then
				startCoop()
			end
		end
	end)

	humanoid.Died:Connect(function()
		BossTimerEvent:FireAllClients(0, 0)
	end)
end

return Boss2
