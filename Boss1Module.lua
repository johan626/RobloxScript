-- Boss1Module.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BossModule/Boss1Module.lua
-- Script Place: ACT 1: Village

local Boss1 = {}

-- Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Boss1VFXModule = require(ReplicatedStorage.ZombieVFX:WaitForChild("Boss1VFXModule"))
local ElementModule = require(ServerScriptService.ModuleScript:WaitForChild("ElementConfigModule"))
local ShieldModule = require(ServerScriptService.ModuleScript:WaitForChild("ShieldModule"))
local BossTimerEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BossTimerEvent")

function Boss1.Init(zombie, humanoid, config, executeHardWipe)
	-- Tag the zombie as a boss
	local bossTag = Instance.new("BoolValue")
	bossTag.Name = "IsBoss"
	bossTag.Parent = zombie

	-- Fire the "Boss Incoming" alert to all clients
	local bossAlert = ReplicatedStorage.RemoteEvents:FindFirstChild("BossIncoming")
	if not bossAlert then
		bossAlert = Instance.new("RemoteEvent")
		bossAlert.Name = "BossIncoming"
		bossAlert.Parent = ReplicatedStorage.RemoteEvents
	end
	bossAlert:FireAllClients()

	-- Start the boss timer and wipe-out mechanic
	local pconf = config.Poison
	local bossStartTime = tick()
	local specialTimeout = pconf.SpecialTimeout or 300
	BossTimerEvent:FireAllClients(specialTimeout, specialTimeout)

	task.spawn(function()
		while zombie.Parent and humanoid and humanoid.Health > 0 do
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

	-- Start the radiation damage aura
	task.spawn(function()
		local rconf = config.Radiation
		local tickTime = (rconf and rconf.Tick) or 0.5
		local hr = (rconf and rconf.HorizontalRadius) or 10
		local vy = (rconf and rconf.VerticalHalfHeight) or 1000
		local dpsPct = (rconf and rconf.DamagePerSecondPct) or 0.02

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
							local dmg = hum.MaxHealth * dpsPct * tickTime
							dmg = ElementModule.ApplyDamageReduction(plr, dmg)
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

	-- Start the poison attack skill
	task.spawn(function()
		local pconf = config.Poison
		Boss1VFXModule.CreateBossPoisonAura(zombie)

		local function doPoisonOnce()
			for _, plr in ipairs(game.Players:GetPlayers()) do
				if plr.Character then
					local pos = (plr.Character:FindFirstChild("Head") and plr.Character.Head.Position) or (plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character.HumanoidRootPart.Position)
					if pos then
						Boss1VFXModule.CreateBossPoisonEffectFollow(plr.Character, false, (config.Poison and config.Poison.Duration) or 5)
					end
				end
			end

			for _, plr in pairs(game.Players:GetPlayers()) do
				if plr.Character and not ElementModule.IsPlayerInvincible(plr) then
					local hum = plr.Character:FindFirstChild("Humanoid")
					if hum and hum.Health > 0 then
						Boss1VFXModule.ApplyPlayerPoisonEffect(plr.Character, false, pconf.Duration)
						local totalDamage = hum.MaxHealth * pconf.SinglePoisonPct
						local ticks = math.max(1, math.floor(pconf.Duration / 0.5))
						local dmgPerTick = totalDamage / ticks
						for t=1, ticks do
							if hum.Health > 0 and not ElementModule.IsPlayerInvincible(plr) then
								local damage = ElementModule.ApplyDamageReduction(plr, dmgPerTick)
								local leftoverDamage = ShieldModule.Damage(plr, damage)
								if leftoverDamage > 0 then
									hum:TakeDamage(leftoverDamage)
								end
							end
							task.wait(pconf.Duration / ticks)
						end
					end
				end
			end
		end

		for i=1, (pconf.InitialCount or 4) do
			if not zombie.Parent or not humanoid or humanoid.Health <= 0 then break end
			doPoisonOnce()
			if i < (pconf.InitialCount or 4) then
				task.wait(pconf.Interval or 60)
			end
		end
	end)

	-- Connect the Died event to stop the timer
	humanoid.Died:Connect(function()
		BossTimerEvent:FireAllClients(0, 0)
	end)
end

return Boss1
