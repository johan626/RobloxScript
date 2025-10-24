-- IceVFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ElementVFX/IceVFXModule.lua
-- Script Place: ACT 1: Village

local IceVFX = {}

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))

function IceVFX.SpawnImpact(part: BasePart, life: number)
	if not part then return end

	-- Main ice sphere
	local iceSphere = Instance.new("Part")
	iceSphere.Name = "IceImpact"
	iceSphere.Shape = Enum.PartType.Ball
	iceSphere.Size = Vector3.new(2.5, 2.5, 2.5)
	iceSphere.Material = Enum.Material.Ice
	iceSphere.Color = Color3.fromRGB(170, 230, 255)
	iceSphere.Transparency = 0.6
	iceSphere.CanCollide = false
	iceSphere.Anchored = true
	iceSphere.CFrame = part.CFrame
	iceSphere.Parent = workspace

	-- Ice light source
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(150, 220, 255)
	light.Brightness = 6
	light.Range = 12
	light.Parent = iceSphere

	-- Ice shard particles
	local shards = Instance.new("ParticleEmitter")
	shards.Name = "IceShards"
	shards.Rate = 60
	shards.Lifetime = NumberRange.new(0.5, 1.2)
	shards.Speed = NumberRange.new(8, 15)
	shards.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.4, 0.9),
		NumberSequenceKeypoint.new(1, 0)
	})
	shards.Color = ColorSequence.new(
		Color3.fromRGB(200, 240, 255),
		Color3.fromRGB(150, 220, 250)
	)
	shards.LightEmission = 0.8
	shards.Transparency = NumberSequence.new(0.3)
	shards.VelocitySpread = 360
	shards.Rotation = NumberRange.new(-180, 180)
	shards.Parent = iceSphere

	-- Frost mist particles
	local mist = Instance.new("ParticleEmitter")
	mist.Name = "IceMist"
	mist.Rate = 40
	mist.Lifetime = NumberRange.new(0.8, 1.5)
	mist.Speed = NumberRange.new(3, 6)
	mist.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(0.6, 2.0),
		NumberSequenceKeypoint.new(1, 0)
	})
	mist.Color = ColorSequence.new(
		Color3.fromRGB(220, 240, 255),
		Color3.fromRGB(180, 220, 240)
	)
	mist.LightEmission = 0.5
	mist.Transparency = NumberSequence.new(0.5)
	mist.VelocitySpread = 180
	mist.Parent = iceSphere

	-- Fade out animation
	local tweenInfo = TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(iceSphere, tweenInfo, {
		Size = Vector3.new(0.1, 0.1, 0.1), 
		Transparency = 1
	})
	tween:Play()

	Debris:AddItem(iceSphere, life)
end

function IceVFX.AttachEffect(zombieModel: Model, dur: number)
	if not (zombieModel and dur) then return end
	local mainPart = zombieModel.PrimaryPart or zombieModel:FindFirstChild("HumanoidRootPart") or zombieModel:FindFirstChildWhichIsA("BasePart")
	if not mainPart then return end

	-- Prevent stacking
	local existing = mainPart:FindFirstChild("Element_IceVFX")
	if existing then
		Debris:AddItem(existing, dur)
		return
	end

	-- Create container for all ice effects
	local iceContainer = Instance.new("Part")
	iceContainer.Name = "Element_IceVFX"
	iceContainer.Size = Vector3.new(1, 1, 1)
	iceContainer.Transparency = 1
	iceContainer.CanCollide = false
	iceContainer.Anchored = false
	iceContainer.Massless = true
	iceContainer.Parent = mainPart

	-- Weld to main part
	local weld = Instance.new("Weld")
	weld.Part0 = mainPart
	weld.Part1 = iceContainer
	weld.C0 = CFrame.new(0, 0, 0)
	weld.Parent = iceContainer

	-- Frost covering effect
	local frost = Instance.new("ParticleEmitter")
	frost.Name = "IceFrost"
	frost.Rate = 30
	frost.Lifetime = NumberRange.new(1.0, 1.8)
	frost.Speed = NumberRange.new(1, 3)
	frost.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(0.7, 2.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	frost.Color = ColorSequence.new(
		Color3.fromRGB(220, 240, 255),
		Color3.fromRGB(180, 220, 240)
	)
	frost.LightEmission = 0.6
	frost.Transparency = NumberSequence.new(0.4)
	frost.VelocitySpread = 180
	frost.Parent = iceContainer

	-- Floating ice crystals
	local crystals = Instance.new("ParticleEmitter")
	crystals.Name = "IceCrystals"
	crystals.Rate = 20
	crystals.Lifetime = NumberRange.new(1.2, 2.0)
	crystals.Speed = NumberRange.new(2, 4)
	crystals.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.7),
		NumberSequenceKeypoint.new(1, 0)
	})
	crystals.Color = ColorSequence.new(
		Color3.fromRGB(200, 235, 255),
		Color3.fromRGB(170, 220, 250)
	)
	crystals.LightEmission = 0.7
	crystals.Transparency = NumberSequence.new(0.2)
	crystals.VelocitySpread = 90
	crystals.Rotation = NumberRange.new(-180, 180)
	crystals.Parent = iceContainer

	-- Ice glow light
	local light = Instance.new("PointLight")
	light.Name = "IceLight"
	light.Brightness = 4
	light.Range = 10
	light.Color = Color3.fromRGB(150, 220, 255)
	light.Parent = iceContainer

	-- Create ice shell effect on the zombie
	local iceShell = Instance.new("Part")
	iceShell.Name = "IceShell"
	iceShell.Size = mainPart.Size * 1.1
	iceShell.Shape = mainPart.Shape
	iceShell.Material = Enum.Material.Ice
	iceShell.Color = Color3.fromRGB(180, 230, 255)
	iceShell.Transparency = 0.5
	iceShell.CanCollide = false
	iceShell.Anchored = false
	iceShell.Massless = true
	iceShell.CFrame = mainPart.CFrame
	iceShell.Parent = iceContainer

	-- Weld shell to main part
	local shellWeld = Instance.new("Weld")
	shellWeld.Part0 = mainPart
	shellWeld.Part1 = iceShell
	shellWeld.C0 = CFrame.new(0, 0, 0)
	shellWeld.Parent = iceShell

	Debris:AddItem(iceContainer, dur)
end

function IceVFX.SpawnBreak(part: BasePart, life: number)
	if not part then return end

	-- Ice shatter effect
	local shatter = Instance.new("Part")
	shatter.Name = "IceBreak"
	shatter.Shape = Enum.PartType.Ball
	shatter.Size = Vector3.new(2.0, 2.0, 2.0)
	shatter.Material = Enum.Material.Ice
	shatter.Color = Color3.fromRGB(180, 230, 255)
	shatter.Transparency = 0.7
	shatter.CanCollide = false
	shatter.Anchored = true
	shatter.CFrame = part.CFrame
	shatter.Parent = workspace

	-- Bright flash for break effect
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(180, 230, 255)
	light.Brightness = 10
	light.Range = 15
	light.Parent = shatter

	-- Shatter particles
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "IceShatter"
	particles.Rate = 80
	particles.Lifetime = NumberRange.new(0.3, 0.8)
	particles.Speed = NumberRange.new(12, 20)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.3, 1.2),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Color = ColorSequence.new(
		Color3.fromRGB(220, 240, 255),
		Color3.fromRGB(180, 220, 250)
	)
	particles.LightEmission = 0.9
	particles.Transparency = NumberSequence.new(0.2)
	particles.VelocitySpread = 360
	particles.Rotation = NumberRange.new(-180, 180)
	particles.Parent = shatter

	-- Quick expansion and fade
	local tweenInfo = TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(shatter, tweenInfo, {
		Size = Vector3.new(0.1, 0.1, 0.1), 
		Transparency = 1
	})
	tween:Play()

	Debris:AddItem(shatter, life)
end

function IceVFX.PlaySound(part: BasePart)
	if not part then return end
	local sound = AudioManager.playSound("Elements.Ice", part, {
		Name = "IceSFX",
		Volume = 0.7,
		PlaybackSpeed = 1.0,
		RollOffMaxDistance = 35
	})
	if sound then
		Debris:AddItem(sound, 5)
	end
end

return IceVFX
