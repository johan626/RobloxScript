-- ElementConfigModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/ElementConfigModule.lua
-- Script Place: ACT 1: Village

local ElementModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ElementVFX = ReplicatedStorage.ElementVFX

local AudioManager      = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))

local ElementActivated     = RemoteEvents:WaitForChild("ElementActivated")
local ElementDeactivated   = RemoteEvents:WaitForChild("ElementDeactivated")
local ActivateElementEvent = RemoteEvents:WaitForChild("ActivateElementEvent")
local InvincibilityEffectEvent = RemoteEvents:WaitForChild("InvincibilityEffectEvent")

--// Config Elements
local ElementsConfig = {
	Fire   = {
		Cost = 1000, Duration = 10,
		DamageMultiplier = 0.3,
		BurnPercentPerTick = 0.10,
		BurnTicks = 3,
		BurnInterval = 1,
		SFX_SoundId = "rbxassetid://123456789", SFX_Volume = 1, SFX_Pitch = 1,
	},
	Ice    = {
		Cost = 1000,
		Duration = 20,
		SlowPercent = 0.30,
		SlowDuration = 4,
		SFX_SoundId = "rbxassetid://123456789", SFX_Volume = 1, SFX_Pitch = 1,
	},
	Poison = {
		Cost = 1000,
		Duration = 10,
		PoisonDPS = 5,
		PoisonDuration = 6,
		SFX_SoundId = "rbxassetid://123456789", SFX_Volume = 1, SFX_Pitch = 1,
	},
	Shock  = {
		Cost = 1000, Duration = 10,
		ChainRange = 6, ChainDamageMultiplier = 0.5,
		SFX_SoundId = "rbxassetid://123456789", SFX_Volume = 1, SFX_Pitch = 1,
	},
	Wind   = {
		Cost = 1000,
		Duration = 10,
		SpeedMultiplier = 1.5,
		PushSpeed = 60,
		PushDuration = 0.35,
		SFX_SoundId = "rbxassetid://123456789", SFX_Volume = 1, SFX_Pitch = 1,
	},
	Earth  = {
		Cost = 1000,
		Duration = 10,
		DamageReduction = 0.20,
		SFX_SoundId = "rbxassetid://123456789", SFX_Volume = 1, SFX_Pitch = 1,
	},
	Light  = { Cost = 3000, Duration = 3, InvincibilityDuration = 3, SFX_SoundId = "rbxassetid://123456789", SFX_Volume = 1, SFX_Pitch = 1 },
	Dark   = {
		Cost = 5000,
		Duration = 5,
		LifeStealPercent = 0.1,
		SFX_SoundId = "rbxassetid://123456789", SFX_Volume = 1, SFX_Pitch = 1,
	},
}

--// State
-- active[player] = { elements = { [name] = expires }, last = name }
local active = {}
-- purchased[player] = elementName (string) atau nil
local purchasedElements = {}
local boughtThisWave    = {}
-- players dengan invincibility sementara (Light)
local invinciblePlayers = {}

--// Helpers
local function getRemaining(player, name)
	local p = active[player]
	if not p or not p.elements[name] then return nil end
	local expires   = p.elements[name]
	local remaining = math.max(0, expires - tick())
	if remaining <= 0 then
		p.elements[name] = nil
		if p.last == name then p.last = nil end
		return nil
	end
	return remaining
end

function ElementModule.GetConfig()
	return ElementsConfig
end

-- Returns primary active element name (or nil)
function ElementModule.GetActiveElement(player)
	local p = active[player]
	if not p or not p.last then return nil end
	-- validate expiry
	local rem = getRemaining(player, p.last)
	if not rem then
		for n, expires in pairs(p.elements) do
			if expires and expires > tick() then
				p.last = n
				return n
			end
		end
		return nil
	end
	return p.last
end

function ElementModule.GetActiveElements(player)
	local out = {}
	local p = active[player]
	if not p then return out end
	for name, expires in pairs(p.elements) do
		local r = math.max(0, expires - tick())
		if r > 0 then out[name] = r end
	end
	return out
end

function ElementModule.GetPurchasedElement(player)
	return purchasedElements[player]
end

function ElementModule.IsPlayerInvincible(player)
	return invinciblePlayers[player] == true
end

function ElementModule.ApplyDamageReduction(player, damage)
	local activeElement = ElementModule.GetActiveElement(player)
	if activeElement == "Earth" then
		local cfg = ElementsConfig.Earth
		return damage * (1 - cfg.DamageReduction)
	end
	return damage
end

--// VFX Module
local LightVFXModule = require(ElementVFX.LightVFXModule)
local EarthVFXModule = require(ElementVFX.EarthVFXModule)
local FireVFXModule = require(ElementVFX.FireVFXModule)
local ShockVFXModule = require(ElementVFX.ShockVFXModule)
local PoisonVFXModule = require(ElementVFX.PoisonVFXModule)
local IceVFXModule = require(ElementVFX.IceVFXModule)
local WindVFXModule = require(ElementVFX.WindVFXModule)
local DarkVFXModule = require(ElementVFX.DarkVFXModule)

--// Helper functions
function ElementModule.GetMainPart(model: Model)
	return model.PrimaryPart
		or model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("Torso")
		or model:FindFirstChildWhichIsA("BasePart")
end

--// ===== Purchase & Activate flow =====
function ElementModule.ActivateElement(player, elementName)
	-- Must be purchased for this wave
	if purchasedElements[player] ~= elementName then
		return false, "Element not purchased or already activated"
	end

	local cfg = ElementsConfig[elementName]
	if not cfg then return false, "Unknown element" end

	if not active[player] then
		active[player] = { elements = {}, last = nil }
	end

	local expires = tick() + cfg.Duration
	local p = active[player]

	-- extend or set
	if p.elements[elementName] and p.elements[elementName] > tick() then
		p.elements[elementName] = math.max(p.elements[elementName], expires)
	else
		p.elements[elementName] = expires
	end

	p.last = elementName
	purchasedElements[player] = nil

	-- LIGHT: invincibility + server VFX
	if elementName == "Light" then
		invinciblePlayers[player] = true
		LightVFXModule.SpawnForPlayer(player)
		task.spawn(function()
			task.wait(cfg.InvincibilityDuration)
			invinciblePlayers[player] = nil
			LightVFXModule.RemoveForPlayer(player)
		end)
	end

	-- DARK: VFX activation
	if elementName == "Dark" then
		DarkVFXModule.SpawnForPlayer(player)
		task.spawn(function()
			task.wait(cfg.Duration)
			DarkVFXModule.RemoveForPlayer(player)
		end)
	end

	-- EARTH: VFX activation
	if elementName == "Earth" then
		EarthVFXModule.SpawnForPlayer(player)
		task.spawn(function()
			task.wait(cfg.Duration)
			EarthVFXModule.RemoveForPlayer(player)
		end)
	end

	-- notify client about activation (UI)
	local remaining = p.elements[elementName] - tick()
	pcall(function()
		ElementActivated:FireClient(player, elementName, math.ceil(remaining))
	end)

	-- lifetime watcher -> notify deactivated (UI)
	task.spawn(function()
		while true do
			local rem = getRemaining(player, elementName)
			if not rem then
				pcall(function() ElementDeactivated:FireClient(player, elementName) end)
				break
			end
			task.wait(math.min(1, rem))
		end
	end)

	return true, "Element activated"
end

function ElementModule.GrantElement(player, name)
	if not player or not player:IsA("Player") then return false, "Invalid player" end
	local cfg = ElementsConfig[name]
	if not cfg then return false, "Unknown element" end

	if boughtThisWave[player] or purchasedElements[player] then
		return false, "Already purchased an element this wave"
	end

	purchasedElements[player] = name
	boughtThisWave[player] = true
	return true, "Element purchased"
end

function ElementModule.ClearPurchasedElements(player)
	if player then
		purchasedElements[player] = nil
		boughtThisWave[player]    = nil
	else
		purchasedElements = {}
		boughtThisWave    = {}
	end
end

--// ===== Weapon hit hooks =====
function ElementModule.OnPlayerHit(player, hitModel, baseDamage)
	local name = ElementModule.GetActiveElement(player)
	if not name then return baseDamage end
	local cfg = ElementsConfig[name]
	if not cfg then return baseDamage end

	if name == "Fire" then
		-- Calculate the immediate damage boost for Fire element
		local dmg = math.ceil(baseDamage * (1 + cfg.DamageMultiplier))
		-- Determine burn damage per tick
		local burnDmg = math.max(1, math.floor(baseDamage * cfg.BurnPercentPerTick))
		-- Spawn a fiery impact effect at the hit target and play crackling sound
		do
			local mp = ElementModule.GetMainPart(hitModel)
			if mp then
				-- short-lived burst of flame at the impact
				FireVFXModule.SpawnImpact(mp, 0.5)
				-- persistent burning effect attached for the duration of the burn debuff
				local burnDuration = (cfg.BurnTicks or 1) * (cfg.BurnInterval or 1)
				FireVFXModule.AttachEffect(hitModel, burnDuration)
				-- play fire sound at impact location
				FireVFXModule.PlaySound(mp, cfg.SFX_SoundId, cfg.SFX_Volume, cfg.SFX_Pitch)
			end
		end
		-- Apply damage over time via burn debuff
		if ElementModule._applyBurnToZombie then
			ElementModule._applyBurnToZombie(
				hitModel,
				burnDmg,
				cfg.BurnTicks,
				cfg.BurnInterval
			)
		end
		return dmg

	elseif name == "Ice" then
		-- Spawn ice impact VFX and play sound
		local mp = ElementModule.GetMainPart(hitModel)
		if mp then
			IceVFXModule.SpawnImpact(mp, 0.5)
			IceVFXModule.PlaySound(mp, cfg.SFX_SoundId, cfg.SFX_Volume, cfg.SFX_Pitch)
		end
		-- Apply slow effect with VFX
		if ElementModule._applyIceSlow then
			ElementModule._applyIceSlow(hitModel, cfg.SlowPercent, cfg.SlowDuration)
		end
		return baseDamage

	elseif name == "Poison" then
		-- Spawn visual and sound effects for poison upon impact
		do
			local mp = ElementModule.GetMainPart(hitModel)
			if mp then
				PoisonVFXModule.SpawnImpact(mp, 0.5)
				PoisonVFXModule.AttachEffect(hitModel, cfg.PoisonDuration)
				PoisonVFXModule.PlaySound(mp, cfg.SFX_SoundId, cfg.SFX_Volume, cfg.SFX_Pitch)
			end
		end
		-- Apply poison damage over time
		if ElementModule._applyPoison then
			ElementModule._applyPoison(hitModel, cfg.PoisonDPS, cfg.PoisonDuration)
		end
		return baseDamage

	elseif name == "Shock" then
		if ElementModule._applyShockChain then
			ElementModule._applyShockChain(hitModel, baseDamage, cfg.ChainRange, cfg.ChainDamageMultiplier)
		end
		return baseDamage

	elseif name == "Wind" then
		-- try to spawn a push effect on the hit zombie
		local mp = ElementModule.GetMainPart(hitModel)
		-- read push parameters from config or use defaults
		local pushSpeed = cfg.PushSpeed or cfg.SpeedMultiplier and (cfg.SpeedMultiplier * 40) or 60
		local pushDur   = cfg.PushDuration or 0.35

		if mp and ElementModule._applyWindPush then
			-- apply push away from the player who hit
			ElementModule._applyWindPush(hitModel, player, pushSpeed, pushDur)
			-- Add wind VFX and SFX
			WindVFXModule.SpawnImpact(mp, 1.0)
			WindVFXModule.PlaySound(mp, cfg.SFX_SoundId, cfg.SFX_Volume, cfg.SFX_Pitch)
		end
		return baseDamage

	elseif name == "Earth" then
		-- Spawn earth impact VFX and play sound
		local mp = ElementModule.GetMainPart(hitModel)
		if mp then
			EarthVFXModule.SpawnImpact(mp, 0.5)
			EarthVFXModule.PlaySoundAt(mp, cfg.SFX_SoundId, cfg.SFX_Volume, cfg.SFX_Pitch)
		end
		return baseDamage

	elseif name == "Light" then
		-- invincibility handled elsewhere; damage stays the same
		return baseDamage

	elseif name == "Dark" then
		local lifeStealPercent = cfg.LifeStealPercent or 0.10
		local lifeStealAmount  = baseDamage * lifeStealPercent
		local ch = player.Character
		if ch then
			local hum = ch:FindFirstChild("Humanoid")
			if hum then
				hum.Health = math.min(hum.MaxHealth, hum.Health + lifeStealAmount)
				-- Add dark lifesteal VFX
				DarkVFXModule.SpawnLifestealVFX(hitModel, ch, lifeStealAmount)
			end
		end

		-- Add dark impact VFX
		local mp = ElementModule.GetMainPart(hitModel)
		if mp then
			DarkVFXModule.SpawnImpact(mp, 0.5)
			DarkVFXModule.PlaySoundAt(mp, cfg.SFX_SoundId, cfg.SFX_Volume, cfg.SFX_Pitch)
		end

		return baseDamage
	end

	return baseDamage
end

--// ===== Zombie debuff helpers =====
ElementModule._applyBurnToZombie = function(zombieModel, damagePerTick, ticks, interval)
	local humanoid = zombieModel and zombieModel:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	local tag = zombieModel:FindFirstChild("Element_Burn")
	local expireTag = zombieModel:FindFirstChild("Element_Burn_Expire")
	if not tag then tag = Instance.new("BoolValue"); tag.Name = "Element_Burn"; tag.Parent = zombieModel end
	if not expireTag then
		expireTag = Instance.new("NumberValue"); expireTag.Name = "Element_Burn_Expire"; expireTag.Value = tick() + ticks * interval; expireTag.Parent = zombieModel
	else
		expireTag.Value = math.max(expireTag.Value, tick() + ticks * interval)
	end
	if zombieModel:FindFirstChild("Element_Burn_Coroutine") then return end
	local marker = Instance.new("BoolValue"); marker.Name = "Element_Burn_Coroutine"; marker.Parent = zombieModel
	task.spawn(function()
		while expireTag.Value > tick() do
			if not humanoid or humanoid.Health <= 0 then break end
			humanoid:TakeDamage(damagePerTick)
			task.wait(interval)
		end
		if marker and marker.Parent then marker:Destroy() end
		if tag and tag.Parent then tag:Destroy() end
		if expireTag and expireTag.Parent then expireTag:Destroy() end
	end)
end

ElementModule._applyPoison = function(zombieModel, dps, duration)
	local humanoid = zombieModel and (zombieModel:FindFirstChild("Humanoid"))
	if not humanoid or humanoid.Health then return end
	local tag = zombieModel:FindFirstChild("Element_Poison")
	if tag then return end
	tag = Instance.new("BoolValue"); tag.Name = "Element_Poison"; tag.Parent = zombieModel
	task.spawn(function()
		local t = 0
		while t < duration and humanoid and humanoid.Health > 0 do
			humanoid:TakeDamage(dps)
			t += 1
			task.wait(1)
		end
		if tag and tag.Parent then tag:Destroy() end
	end)
end

-- Push zombie away when hit by Wind element
ElementModule._applyWindPush = function(zombieModel, player, speed, dur)
	local humanoid = zombieModel and zombieModel:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local root = zombieModel:FindFirstChild("HumanoidRootPart") or zombieModel.PrimaryPart
	if not root or not root:IsA("BasePart") then return end

	-- determine direction: from player to zombie (push away from player)
	local dir = nil
	if player and player.Character then
		local plRoot = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
		if plRoot and plRoot:IsA("BasePart") then
			local delta = root.Position - plRoot.Position
			if delta.Magnitude > 0.001 then
				dir = delta.Unit
			end
		end
	end
	-- fallback: push in root's lookVector
	if not dir then
		dir = root.CFrame.LookVector
	end

	-- compute target velocity
	local pushSpeed = tonumber(speed) or 60
	local pushDuration = tonumber(dur) or 0.35
	local pushVelocity = dir * pushSpeed

	-- Apply immediate velocity. Using AssemblyLinearVelocity is simple and works server-side.
	-- Save old velocity to restore after duration (best-effort).
	local oldVel = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = pushVelocity

	-- small VFX (optional): create a short impulse particle or sound here if you want

	-- restore or dampen after duration
	task.delay(pushDuration, function()
		-- only restore if part still exists
		if root and root.Parent then
			-- dampen rather than full restore to avoid jolts from other motion
			root.AssemblyLinearVelocity = oldVel * 0.25
		end
	end)
end

ElementModule._applyIceSlow = function(zombieModel, percent, dur)
	local humanoid = zombieModel and zombieModel:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	local tag = zombieModel:FindFirstChild("Element_IceSlow")
	if tag then return end
	tag = Instance.new("BoolValue"); tag.Name = "Element_IceSlow"; tag.Parent = zombieModel

	-- Attach ice effect VFX
	IceVFXModule.AttachEffect(zombieModel, dur)

	local original = humanoid.WalkSpeed or 8
	humanoid.WalkSpeed = original * (1 - percent)
	task.spawn(function()
		task.wait(dur)
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = original
			-- Add ice break effect when slow ends
			if humanoid.Health > 0 then
				local mp = ElementModule.GetMainPart(zombieModel)
				if mp then
					IceVFXModule.SpawnBreak(mp, 0.3)  -- Use new ice break effect
				end
			end
		end
		if tag and tag.Parent then tag:Destroy() end
	end)
end

-- ===== UPDATED: Shock now with realistic VFX (server-side) =====
ElementModule._applyShockChain = function(zombieModel, baseDamage, chainRange, multiplier)
	local humanoid = zombieModel and zombieModel:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local originPart = ElementModule.GetMainPart(zombieModel)
	if not originPart then return end

	-- Origin impact visuals & sound
	ShockVFXModule.SpawnShockImpact(originPart, 0.18)
	ShockVFXModule.SpawnBranchArcs(originPart, 0.15)
	ShockVFXModule.PlayShockSoundAt(originPart, ElementsConfig.Shock.SFX_SoundId, ElementsConfig.Shock.SFX_Volume, ElementsConfig.Shock.SFX_Pitch)

	-- Chain to neighbors
	local originPos = originPart.Position
	for _, candidate in pairs(workspace:GetChildren()) do
		if candidate:IsA("Model") and candidate ~= zombieModel and candidate:FindFirstChild("IsZombie") then
			local part = ElementModule.GetMainPart(candidate)
			if part and (part.Position - originPos).Magnitude <= chainRange then
				local hm = candidate:FindFirstChild("Humanoid")
				if hm and hm.Health > 0 then
					-- Damage
					hm:TakeDamage(baseDamage * multiplier)
					-- Visual link
					ShockVFXModule.SpawnShockBeam(originPart, part, 0.2)
					ShockVFXModule.SpawnShockImpact(part, 0.12)
				end
			end
		end
	end
end

--// Housekeeping
Players.PlayerRemoving:Connect(function(plr)
	active[plr]            = nil
	purchasedElements[plr] = nil
	boughtThisWave[plr]    = nil
	invinciblePlayers[plr] = nil
end)

-- Allow client to ask activation (server validates purchase)
ActivateElementEvent.OnServerEvent:Connect(function(player, elementName)
	ElementModule.ActivateElement(player, elementName)
end)

return ElementModule
