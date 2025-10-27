-- Boss1VFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/BossVFXModule.lua
-- Script Place: ACT 1: Village

local BossVFXModule = {}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))
local ElementModule = require(ModuleScriptServerScriptService:WaitForChild("ElementConfigModule"))

-- === Helpers khusus Boss ===
function BossVFXModule.ApplyPlayerPoisonEffect(character, isSpecial, duration)
	if not character or not character:FindFirstChild("Humanoid") then return end
	local existingEffect = character:FindFirstChild("PoisonEffect")
	if existingEffect then existingEffect:Destroy() end

	local poisonEffect = Instance.new("Folder")
	poisonEffect.Name = "PoisonEffect"

	local attachPoint = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head") or character.PrimaryPart
	if not attachPoint then return end

	-- Main poison gas particles (more realistic)
	local poisonParticles = Instance.new("ParticleEmitter")
	poisonParticles.Parent = attachPoint
	poisonParticles.Color = isSpecial and ColorSequence.new(Color3.fromRGB(180, 0, 0)) or ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 120, 40)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 180, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 100, 30))
	})
	poisonParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.3, 1.2),
		NumberSequenceKeypoint.new(0.7, 2.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	poisonParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.2, 0.4),
		NumberSequenceKeypoint.new(0.6, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	poisonParticles.Lifetime = NumberRange.new(1.5, 3)
	poisonParticles.Rate = 80
	poisonParticles.SpreadAngle = Vector2.new(60, 60)
	poisonParticles.VelocitySpread = 360
	poisonParticles.Speed = NumberRange.new(1, 4)
	poisonParticles.Rotation = NumberRange.new(0, 360)
	poisonParticles.RotSpeed = NumberRange.new(-45, 45)
	poisonParticles.LightEmission = 0.3
	poisonParticles.LightInfluence = 0
	poisonParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	poisonParticles.Drag = 2

	-- Toxic bubble particles (improved)
	local bubbleParticles = Instance.new("ParticleEmitter")
	bubbleParticles.Parent = attachPoint
	bubbleParticles.Color = ColorSequence.new(isSpecial and Color3.fromRGB(220, 80, 80) or Color3.fromRGB(100, 200, 80))
	bubbleParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.4, 0.6),
		NumberSequenceKeypoint.new(0.8, 0.3),
		NumberSequenceKeypoint.new(1, 0)
	})
	bubbleParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.3, 0.3),
		NumberSequenceKeypoint.new(0.7, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	bubbleParticles.Lifetime = NumberRange.new(1, 2.5)
	bubbleParticles.Rate = 25
	bubbleParticles.SpreadAngle = Vector2.new(35, 35)
	bubbleParticles.Shape = Enum.ParticleEmitterShape.Sphere
	bubbleParticles.VelocitySpread = 180
	bubbleParticles.Speed = NumberRange.new(0.5, 2)
	bubbleParticles.Acceleration = Vector3.new(0, 3, 0) -- Bubbles rise up
	bubbleParticles.Drag = 1

	-- Add dripping poison effect
	local dripParticles = Instance.new("ParticleEmitter")
	dripParticles.Parent = attachPoint
	dripParticles.Color = ColorSequence.new(isSpecial and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(70, 160, 50))
	dripParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 0)
	})
	dripParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1)
	})
	dripParticles.Lifetime = NumberRange.new(0.5, 1.2)
	dripParticles.Rate = 15
	dripParticles.SpreadAngle = Vector2.new(15, 15)
	dripParticles.VelocitySpread = 90
	dripParticles.Speed = NumberRange.new(1, 3)
	dripParticles.Acceleration = Vector3.new(0, -10, 0) -- Drips fall down
	dripParticles.Drag = 0.5

	-- Add poison glow using point light
	local poisonLight = Instance.new("PointLight")
	poisonLight.Brightness = isSpecial and 8 or 4
	poisonLight.Range = 15
	poisonLight.Color = isSpecial and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(60, 200, 60)
	poisonLight.Shadows = true
	poisonLight.Parent = attachPoint

	-- Add screen blur effect for immersed feeling
	if character == game.Players.LocalPlayer then
		local blurEffect = Instance.new("BlurEffect")
		blurEffect.Size = 8
		blurEffect.Name = "PoisonBlur"
		blurEffect.Parent = game.Lighting

		-- Animate blur intensity
		task.spawn(function()
			local startTime = tick()
			while tick() - startTime < duration and blurEffect.Parent do
				local tween1 = TweenService:Create(blurEffect, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = 12})
				tween1:Play()
				tween1.Completed:Wait()
				local tween2 = TweenService:Create(blurEffect, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = 8})
				tween2:Play()
				tween2.Completed:Wait()
			end
			if blurEffect.Parent then
				blurEffect:Destroy()
			end
		end)
	end

	local sound = AudioManager.createSound("VFX.Poison", poisonEffect, {Volume = isSpecial and 1.0 or 0.7})

	poisonParticles.Name = "PoisonParticles"
	bubbleParticles.Name = "BubbleParticles"
	dripParticles.Name = "DripParticles"
	poisonLight.Name = "PoisonLight"
	poisonParticles.Parent = poisonEffect
	bubbleParticles.Parent = poisonEffect
	dripParticles.Parent = poisonEffect
	poisonLight.Parent = poisonEffect
	poisonEffect.Parent = character

	if sound then sound:Play() end

	-- Pulsing light effect
	task.spawn(function()
		local startTime = tick()
		while tick() - startTime < duration and poisonLight and poisonLight.Parent do
			local tween1 = TweenService:Create(poisonLight, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = isSpecial and 12 or 6})
			local tween2 = TweenService:Create(poisonParticles, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 120})
			tween1:Play()
			tween2:Play()
			tween1.Completed:Wait()
			local tween3 = TweenService:Create(poisonLight, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = isSpecial and 8 or 4})
			local tween4 = TweenService:Create(poisonParticles, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 80})
			tween3:Play()
			tween4:Play()
			tween3.Completed:Wait()
		end
	end)

	Debris:AddItem(poisonEffect, duration)
end

function BossVFXModule.CreateBossPoisonAura(bossModel)
	if not bossModel or not bossModel.PrimaryPart then return end

	local aura = Instance.new("Part")
	aura.Size = Vector3.new(20, 20, 20)
	aura.Shape = Enum.PartType.Ball
	aura.CFrame = bossModel.PrimaryPart.CFrame
	aura.Anchored = true
	aura.CanCollide = false
	aura.Transparency = 1
	aura.Material = Enum.Material.Neon
	aura.Color = Color3.fromRGB(40, 120, 40)
	aura.Name = "BossPoisonAura"

	-- Main poison particles (more toxic look)
	local mainParticles = Instance.new("ParticleEmitter")
	mainParticles.Parent = aura
	mainParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 100, 30)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 180, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 80, 20))
	})
	mainParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.3, 2),
		NumberSequenceKeypoint.new(0.7, 4),
		NumberSequenceKeypoint.new(1, 0)
	})
	mainParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.4, 0.1),
		NumberSequenceKeypoint.new(0.8, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	mainParticles.Lifetime = NumberRange.new(2, 4)
	mainParticles.Rate = 150
	mainParticles.SpreadAngle = Vector2.new(180, 180)
	mainParticles.Shape = Enum.ParticleEmitterShape.Sphere
	mainParticles.VelocitySpread = 360
	mainParticles.Speed = NumberRange.new(1, 5)
	mainParticles.Rotation = NumberRange.new(0, 360)
	mainParticles.RotSpeed = NumberRange.new(-30, 30)
	mainParticles.LightEmission = 0.6
	mainParticles.LightInfluence = 0
	mainParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mainParticles.Drag = 1.5

	-- Toxic bubble particles (improved)
	local bubbleParticles = Instance.new("ParticleEmitter")
	bubbleParticles.Parent = aura
	bubbleParticles.Color = ColorSequence.new(Color3.fromRGB(80, 220, 80))
	bubbleParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(0.8, 0.8),
		NumberSequenceKeypoint.new(1, 0)
	})
	bubbleParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.3, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	bubbleParticles.Lifetime = NumberRange.new(1.5, 3)
	bubbleParticles.Rate = 60
	bubbleParticles.SpreadAngle = Vector2.new(120, 120)
	bubbleParticles.Shape = Enum.ParticleEmitterShape.Sphere
	bubbleParticles.VelocitySpread = 270
	bubbleParticles.Speed = NumberRange.new(0.5, 3)
	bubbleParticles.Acceleration = Vector3.new(0, 2, 0)
	bubbleParticles.Drag = 1

	-- Toxic mist rising from the ground
	local mistParticles = Instance.new("ParticleEmitter")
	mistParticles.Parent = aura
	mistParticles.Color = ColorSequence.new(Color3.fromRGB(60, 150, 60))
	mistParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(0.6, 6),
		NumberSequenceKeypoint.new(1, 0)
	})
	mistParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.2, 0.4),
		NumberSequenceKeypoint.new(0.8, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	})
	mistParticles.Lifetime = NumberRange.new(3, 6)
	mistParticles.Rate = 40
	mistParticles.SpreadAngle = Vector2.new(30, 30)
	mistParticles.Shape = Enum.ParticleEmitterShape.Cylinder
	mistParticles.VelocitySpread = 45
	mistParticles.Speed = NumberRange.new(1, 3)
	mistParticles.LockedToPart = true
	mistParticles.Acceleration = Vector3.new(0, 1, 0)
	mistParticles.Texture = "rbxasset://textures/particles/cloud_main.dds"

	local light = Instance.new("PointLight")
	light.Brightness = 10
	light.Range = 30
	light.Color = Color3.fromRGB(40, 200, 40)
	light.Shadows = true
	light.Parent = aura

	-- Pulsing effect for particles and light
	task.spawn(function()
		while aura and aura.Parent do
			local tween1 = TweenService:Create(light, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = 6})
			local tween2 = TweenService:Create(mainParticles, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 100})
			local tween3 = TweenService:Create(bubbleParticles, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 40})
			tween1:Play()
			tween2:Play()
			tween3:Play()
			tween1.Completed:Wait()

			local tween4 = TweenService:Create(light, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = 10})
			local tween5 = TweenService:Create(mainParticles, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 150})
			local tween6 = TweenService:Create(bubbleParticles, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 60})
			tween4:Play()
			tween5:Play()
			tween6:Play()
			tween4.Completed:Wait()
		end
	end)

	aura.Parent = workspace
	task.spawn(function()
		while bossModel and bossModel.Parent and aura do
			if bossModel.PrimaryPart then 
				aura.CFrame = bossModel.PrimaryPart.CFrame 
			end
			task.wait(0.1)
		end
		if aura then aura:Destroy() end
	end)

	return aura
end

function BossVFXModule.CreateBossPoisonEffect(position, isSpecial)
	local duration = isSpecial and 10 or 6
	local scale = isSpecial and 3 or 1.5

	local cloud = Instance.new("Part")
	cloud.Size = Vector3.new(15 * scale, 8 * scale, 15 * scale)
	cloud.Shape = Enum.PartType.Ball
	cloud.CFrame = CFrame.new(position + Vector3.new(0, 4, 0))
	cloud.Anchored = true
	cloud.CanCollide = false
	cloud.Transparency = 1
	cloud.Material = Enum.Material.Neon
	cloud.Color = isSpecial and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(40, 120, 40)
	cloud.Name = isSpecial and "SpecialPoisonCloud" or "PoisonCloud"

	-- Main toxic gas particles (more realistic)
	local gasParticles = Instance.new("ParticleEmitter")
	gasParticles.Parent = cloud
	gasParticles.Color = isSpecial and ColorSequence.new(Color3.fromRGB(200, 50, 50)) or ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 90, 30)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 160, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 70, 20))
	})
	gasParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 4 * scale),
		NumberSequenceKeypoint.new(0.8, 3 * scale),
		NumberSequenceKeypoint.new(1, 0)
	})
	gasParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.3, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	gasParticles.Lifetime = NumberRange.new(2.5, 5)
	gasParticles.Rate = 200 * scale
	gasParticles.SpreadAngle = Vector2.new(180, 180)
	gasParticles.Shape = Enum.ParticleEmitterShape.Sphere
	gasParticles.VelocitySpread = 360
	gasParticles.Speed = NumberRange.new(0.5, 3)
	gasParticles.Rotation = NumberRange.new(0, 360)
	gasParticles.RotSpeed = NumberRange.new(-20, 20)
	gasParticles.LightEmission = 0.5
	gasParticles.LightInfluence = 0
	gasParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	gasParticles.Drag = 1

	-- Rising toxic mist (improved)
	local mistParticles = Instance.new("ParticleEmitter")
	mistParticles.Parent = cloud
	mistParticles.Color = isSpecial and ColorSequence.new(Color3.fromRGB(180, 80, 80)) or ColorSequence.new(Color3.fromRGB(60, 140, 60))
	mistParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2 * scale),
		NumberSequenceKeypoint.new(0.5, 6 * scale),
		NumberSequenceKeypoint.new(0.9, 4 * scale),
		NumberSequenceKeypoint.new(1, 0)
	})
	mistParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.2, 0.3),
		NumberSequenceKeypoint.new(0.8, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	})
	mistParticles.Lifetime = NumberRange.new(4, 8)
	mistParticles.Rate = 100 * scale
	mistParticles.SpreadAngle = Vector2.new(60, 60)
	mistParticles.Shape = Enum.ParticleEmitterShape.Cylinder
	mistParticles.VelocitySpread = 120
	mistParticles.Speed = NumberRange.new(1, 4)
	mistParticles.LockedToPart = true
	mistParticles.Acceleration = Vector3.new(0, 0.5, 0)
	mistParticles.Texture = "rbxasset://textures/particles/cloud_main.dds"

	-- Toxic droplets falling from the cloud
	local dripParticles = Instance.new("ParticleEmitter")
	dripParticles.Parent = cloud
	dripParticles.Color = ColorSequence.new(isSpecial and Color3.fromRGB(220, 100, 100) or Color3.fromRGB(70, 150, 50))
	dripParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	dripParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.4, 0.3),
		NumberSequenceKeypoint.new(0.8, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	})
	dripParticles.Lifetime = NumberRange.new(1, 2.5)
	dripParticles.Rate = 50 * scale
	dripParticles.SpreadAngle = Vector2.new(90, 90)
	dripParticles.VelocitySpread = 180
	dripParticles.Speed = NumberRange.new(2, 6)
	dripParticles.Acceleration = Vector3.new(0, -15, 0)
	dripParticles.Drag = 0.3

	if isSpecial then
		local ring = Instance.new("Part")
		ring.Size = Vector3.new(1, 1, 1)
		ring.Shape = Enum.PartType.Cylinder
		ring.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(90), 0, 0)
		ring.Anchored = true
		ring.CanCollide = false
		ring.Transparency = 0.2
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(255, 50, 50)
		ring.Name = "PoisonShockwave"

		local ringMesh = Instance.new("CylinderMesh")
		ringMesh.Parent = ring
		ring.Parent = workspace

		local expandTween = TweenService:Create(ring, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(100, 1, 100), Transparency = 1})
		expandTween:Play()
		expandTween.Completed:Connect(function() ring:Destroy() end)

		-- Toxic tendrils effect
		for i = 1, 12 do
			local angle = (i / 12) * math.pi * 2
			local crackPos = position + Vector3.new(math.cos(angle) * 20, 0, math.sin(angle) * 20)
			local crack = Instance.new("Part")
			crack.Size = Vector3.new(8, 0.2, 3)
			crack.CFrame = CFrame.new(crackPos) * CFrame.Angles(0, angle, 0)
			crack.Anchored = true
			crack.CanCollide = false
			crack.Transparency = 0.3
			crack.Material = Enum.Material.Neon
			crack.Color = Color3.fromRGB(255, 80, 80)
			crack.Name = "PoisonCrack"

			-- Add particles to cracks
			local crackParticles = Instance.new("ParticleEmitter")
			crackParticles.Parent = crack
			crackParticles.Color = ColorSequence.new(Color3.fromRGB(255, 100, 100))
			crackParticles.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 1.5)
			})
			crackParticles.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.4),
				NumberSequenceKeypoint.new(0.7, 0.8),
				NumberSequenceKeypoint.new(1, 1)
			})
			crackParticles.Lifetime = NumberRange.new(0.8, 2)
			crackParticles.Rate = 40
			crackParticles.SpreadAngle = Vector2.new(25, 25)
			crackParticles.Speed = NumberRange.new(1, 4)
			crackParticles.Drag = 2

			crack.Parent = workspace
			Debris:AddItem(crack, 5)
		end
	end

	local light = Instance.new("PointLight")
	light.Brightness = isSpecial and 18 or 12
	light.Range = isSpecial and 50 or 35
	light.Color = isSpecial and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 200, 50)
	light.Shadows = true
	light.Parent = cloud

	-- Pulsing effect for particles and light
	task.spawn(function()
		while cloud and cloud.Parent do
			local tween1 = TweenService:Create(light, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = isSpecial and 12 or 8})
			local tween2 = TweenService:Create(gasParticles, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 150 * scale})
			local tween3 = TweenService:Create(mistParticles, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 70 * scale})
			tween1:Play()
			tween2:Play()
			tween3:Play()
			tween1.Completed:Wait()

			local tween4 = TweenService:Create(light, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = isSpecial and 18 or 12})
			local tween5 = TweenService:Create(gasParticles, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 200 * scale})
			local tween6 = TweenService:Create(mistParticles, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 100 * scale})
			tween4:Play()
			tween5:Play()
			tween6:Play()
			tween4.Completed:Wait()
		end
	end)

	local sound = AudioManager.createSound("VFX.Poison", cloud, {Volume = isSpecial and 1.0 or 0.7})
	if sound then sound:Play() end

	cloud.Parent = workspace
	cloud.Size = Vector3.new(3 * scale, 2 * scale, 3 * scale)
	local growTween = TweenService:Create(cloud, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(15 * scale, 8 * scale, 15 * scale)})
	growTween:Play()
	Debris:AddItem(cloud, duration)
	return cloud
end

function BossVFXModule.CreateBossPoisonEffectFollow(targetCharacter, isSpecial, durationOverride)
	if not targetCharacter then return end
	local hrp = targetCharacter:FindFirstChild("HumanoidRootPart") or targetCharacter:FindFirstChild("Head")
	if not hrp then return end

	local duration = durationOverride or (isSpecial and 10 or 6)
	local cloud = BossVFXModule.CreateBossPoisonEffect(hrp.Position + Vector3.new(0, 12, 0), isSpecial)
	if not cloud then return end

	task.spawn(function()
		local t0 = tick()
		while cloud and cloud.Parent and targetCharacter.Parent do
			if tick() - t0 >= duration then break end
			local p = hrp and hrp.Position or nil
			if not p then break end
			cloud.CFrame = CFrame.new(p + Vector3.new(0, 12, 0))
			task.wait(0.05)
		end
		if cloud and cloud.Parent then cloud:Destroy() end
	end)
	return cloud
end

return BossVFXModule
