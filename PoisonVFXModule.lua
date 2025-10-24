-- PoisonVFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ElementVFX/PoisonVFXModule.lua
-- Script Place: ACT 1: Village

local PoisonVFX = {}

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))

-- Helper function
local function GetMainPart(model: Model)
	return model.PrimaryPart
		or model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("Torso")
		or model:FindFirstChildWhichIsA("BasePart")
end

function PoisonVFX.SpawnImpact(part: BasePart, life: number)
	if not part then return end

	-- Main toxic splash effect
	local splashContainer = Instance.new("Part")
	splashContainer.Name = "PoisonImpact"
	splashContainer.Shape = Enum.PartType.Cylinder
	splashContainer.Size = Vector3.new(0.2, 4, 4)
	splashContainer.Material = Enum.Material.Neon
	splashContainer.Color = Color3.fromRGB(50, 220, 50)
	splashContainer.Transparency = 0.8
	splashContainer.CanCollide = false
	splashContainer.Anchored = true
	splashContainer.CFrame = part.CFrame * CFrame.Angles(0, 0, math.rad(90))
	splashContainer.Parent = workspace

	-- Main toxic sphere
	local flash = Instance.new("Part")
	flash.Name = "PoisonCore"
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.new(2.5, 2.5, 2.5)
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(30, 200, 30)
	flash.Transparency = 0.5
	flash.CanCollide = false
	flash.Anchored = true
	flash.CFrame = part.CFrame
	flash.Parent = splashContainer

	-- Toxic light source
	local L = Instance.new("PointLight")
	L.Color = Color3.fromRGB(50, 220, 50)
	L.Brightness = 8
	L.Range = 12
	L.Shadows = true
	L.Parent = flash

	-- Toxic ripple effect
	local ripple = Instance.new("Part")
	ripple.Name = "PoisonRipple"
	ripple.Shape = Enum.PartType.Cylinder
	ripple.Size = Vector3.new(0.1, 1, 1)
	ripple.Material = Enum.Material.Neon
	ripple.Color = Color3.fromRGB(40, 180, 40)
	ripple.Transparency = 0.7
	ripple.CanCollide = false
	ripple.Anchored = true
	ripple.CFrame = part.CFrame * CFrame.Angles(0, 0, math.rad(90))
	ripple.Parent = splashContainer

	-- Main toxic burst particles
	local burst = Instance.new("ParticleEmitter")
	burst.Name = "PoisonBurst"
	burst.Rate = 60
	burst.Lifetime = NumberRange.new(0.7, 1.2)
	burst.Speed = NumberRange.new(8, 14)
	burst.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.3, 1.5),
		NumberSequenceKeypoint.new(0.7, 2.0),
		NumberSequenceKeypoint.new(1, 0)
	})
	burst.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 255, 150)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(100, 220, 100)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(60, 180, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 100, 20))
	})
	burst.LightEmission = 0.9
	burst.VelocitySpread = 360
	burst.Rotation = NumberRange.new(-180, 180)
	burst.Parent = flash

	-- Toxic gas particles
	local gas = Instance.new("ParticleEmitter")
	gas.Name = "PoisonGas"
	gas.Rate = 40
	gas.Lifetime = NumberRange.new(1.5, 2.5)
	gas.Speed = NumberRange.new(3, 6)
	gas.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.8),
		NumberSequenceKeypoint.new(0.5, 3.0),
		NumberSequenceKeypoint.new(1, 0)
	})
	gas.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 255, 100)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(70, 200, 70)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 120, 40))
	})
	gas.LightEmission = 0.6
	gas.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	gas.VelocitySpread = 180
	gas.Acceleration = Vector3.new(0, 3, 0)
	gas.Parent = flash

	-- Toxic droplets
	local droplets = Instance.new("ParticleEmitter")
	droplets.Name = "PoisonDroplets"
	droplets.Rate = 20
	droplets.Lifetime = NumberRange.new(0.8, 1.5)
	droplets.Speed = NumberRange.new(6, 12)
	droplets.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.3, 0.5),
		NumberSequenceKeypoint.new(0.8, 0.2),
		NumberSequenceKeypoint.new(1, 0)
	})
	droplets.Color = ColorSequence.new(
		Color3.fromRGB(120, 255, 120),
		Color3.fromRGB(80, 200, 80)
	)
	droplets.LightEmission = 0.7
	droplets.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.8)
	})
	droplets.VelocitySpread = 90
	droplets.Acceleration = Vector3.new(0, -15, 0)
	droplets.Drag = 5
	droplets.Parent = flash

	-- Animation for the splash
	local splashTween = TweenService:Create(
		splashContainer, 
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(0.2, 8, 8)}
	)
	splashTween:Play()

	-- Animation for the ripple
	local rippleTween = TweenService:Create(
		ripple, 
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(0.1, 10, 10), Transparency = 1}
	)
	rippleTween:Play()

	-- Fade out animation for the core
	local coreTweenInfo = TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local coreTween = TweenService:Create(flash, coreTweenInfo, {
		Size = Vector3.new(0.1, 0.1, 0.1), 
		Transparency = 1
	})
	coreTween:Play()

	-- Fade out animation for the splash
	local splashFadeTween = TweenService:Create(
		splashContainer, 
		TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Transparency = 1}
	)
	splashFadeTween:Play()

	Debris:AddItem(splashContainer, life)
end

function PoisonVFX.AttachEffect(zombieModel: Model, dur: number)
	if not (zombieModel and dur) then return end
	local mainPart = GetMainPart(zombieModel)
	if not mainPart then return end

	-- Prevent stacking
	local existing = mainPart:FindFirstChild("Element_PoisonVFX")
	if existing then
		Debris:AddItem(existing, dur)
		return
	end

	-- Create container for all poison effects
	local poisonContainer = Instance.new("Part")
	poisonContainer.Name = "Element_PoisonVFX"
	poisonContainer.Size = Vector3.new(1, 1, 1)
	poisonContainer.Transparency = 1
	poisonContainer.CanCollide = false
	poisonContainer.Anchored = false
	poisonContainer.Massless = true
	poisonContainer.Parent = mainPart

	-- Weld to main part
	local weld = Instance.new("Weld")
	weld.Part0 = mainPart
	weld.Part1 = poisonContainer
	weld.C0 = CFrame.new(0, 2, 0) -- Position above the main part
	weld.Parent = poisonContainer

	-- Toxic gas cloud
	local gas = Instance.new("ParticleEmitter")
	gas.Name = "PoisonGas"
	gas.Rate = 30
	gas.Lifetime = NumberRange.new(1.8, 3.0)
	gas.Speed = NumberRange.new(2, 5)
	gas.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.5),
		NumberSequenceKeypoint.new(0.5, 4.0),
		NumberSequenceKeypoint.new(1, 0)
	})
	gas.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 255, 120)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(90, 230, 90)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(70, 190, 70)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 140, 50))
	})
	gas.LightEmission = 0.7
	gas.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	gas.VelocitySpread = 360
	gas.Acceleration = Vector3.new(0, 2.5, 0)
	gas.Parent = poisonContainer

	-- Poison bubbles/particles
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Name = "PoisonBubbles"
	bubbles.Rate = 20
	bubbles.Lifetime = NumberRange.new(1.0, 2.0)
	bubbles.Speed = NumberRange.new(3, 6)
	bubbles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.5, 1.2),
		NumberSequenceKeypoint.new(1, 0)
	})
	bubbles.Color = ColorSequence.new(
		Color3.fromRGB(140, 255, 140),
		Color3.fromRGB(100, 220, 100)
	)
	bubbles.LightEmission = 0.9
	bubbles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1)
	})
	bubbles.VelocitySpread = 180
	bubbles.Rotation = NumberRange.new(-180, 180)
	bubbles.Parent = poisonContainer

	-- Dripping poison effect
	local drips = Instance.new("ParticleEmitter")
	drips.Name = "PoisonDrips"
	drips.Rate = 15
	drips.Lifetime = NumberRange.new(0.5, 1.2)
	drips.Speed = NumberRange.new(2, 5)
	drips.EmissionDirection = Enum.NormalId.Bottom
	drips.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.3, 0.6),
		NumberSequenceKeypoint.new(0.8, 0.3),
		NumberSequenceKeypoint.new(1, 0)
	})
	drips.Color = ColorSequence.new(
		Color3.fromRGB(100, 255, 100),
		Color3.fromRGB(70, 200, 70)
	)
	drips.LightEmission = 0.6
	drips.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.8)
	})
	drips.VelocitySpread = 30
	drips.Acceleration = Vector3.new(0, -20, 0)
	drips.Drag = 3
	drips.Parent = poisonContainer

	-- Toxic glow light
	local light = Instance.new("PointLight")
	light.Name = "PoisonLight"
	light.Brightness = 4
	light.Range = 10
	light.Color = Color3.fromRGB(80, 220, 80)
	light.Shadows = true
	light.Parent = poisonContainer

	-- Pulsing effect for the light
	local pulseTime = 0
	local pulseConn = RunService.Heartbeat:Connect(function(deltaTime)
		pulseTime = pulseTime + deltaTime
		local pulse = math.sin(pulseTime * 3) * 0.5 + 1
		light.Brightness = 3 * pulse
	end)

	-- Clean up the connection when the effect is removed
	poisonContainer.AncestryChanged:Connect(function()
		if poisonContainer.Parent == nil then
			pulseConn:Disconnect()
		end
	end)

	Debris:AddItem(poisonContainer, dur)
end

function PoisonVFX.PlaySound(part: BasePart)
	if not part then return end
	local sound = AudioManager.playSound("Elements.Poison", part, {
		Name = "PoisonSFX",
		Volume = 0.6,
		PlaybackSpeed = 1.0,
		RollOffMaxDistance = 35
	})
	if sound then
		Debris:AddItem(sound, 5)
	end
end

return PoisonVFX
