-- FireVFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ElementVFX/FireVFXModule.lua
-- Script Place: ACT 1: Village

local FireVFX = {}

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))

--// Helper functions
local function GetMainPart(model)
	return model.PrimaryPart
		or model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("Torso")
		or model:FindFirstChildWhichIsA("BasePart")
end

function FireVFX.SpawnImpact(part, life)
	if not part then return end

	-- Main explosion flash
	local flash = Instance.new("Part")
	flash.Name = "FireImpact"
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.new(1.2, 1.2, 1.2)
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(255, 160, 40)
	flash.Transparency = 0.2
	flash.CanCollide = false
	flash.Anchored = true
	flash.CFrame = part.CFrame
	flash.Parent = workspace

	-- Bright light source
	local L = Instance.new("PointLight")
	L.Color = Color3.fromRGB(255, 120, 20)
	L.Brightness = 12
	L.Range = 15
	L.Parent = flash

	-- Main explosion particles
	local explosion = Instance.new("ParticleEmitter")
	explosion.Name = "FireExplosion"
	explosion.Rate = 50
	explosion.Lifetime = NumberRange.new(0.3, 0.8)
	explosion.Speed = NumberRange.new(8, 12)
	explosion.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(0.5, 2.0),
		NumberSequenceKeypoint.new(1, 0)
	})
	explosion.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 180, 40)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 80, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 5))
	})
	explosion.LightEmission = 1
	explosion.VelocitySpread = 360
	explosion.Rotation = NumberRange.new(-180, 180)
	explosion.Parent = flash

	-- Secondary smoke effect
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "FireSmoke"
	smoke.Rate = 30
	smoke.Lifetime = NumberRange.new(1.0, 1.8)
	smoke.Speed = NumberRange.new(2, 4)
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.0),
		NumberSequenceKeypoint.new(0.5, 3.0),
		NumberSequenceKeypoint.new(1, 0)
	})
	smoke.Color = ColorSequence.new(
		Color3.fromRGB(80, 80, 80),
		Color3.fromRGB(20, 20, 20)
	)
	smoke.LightEmission = 0.1
	smoke.VelocitySpread = 180
	smoke.Acceleration = Vector3.new(0, 5, 0)
	smoke.Parent = flash

	Debris:AddItem(flash, life)
end

function FireVFX.AttachEffect(zombieModel, dur)
	if not (zombieModel and dur) then return end
	local mainPart = GetMainPart(zombieModel)
	if not mainPart then return end

	-- Prevent stacking
	local existing = mainPart:FindFirstChild("Element_FireVFX")
	if existing then
		Debris:AddItem(existing, dur)
		return
	end

	-- Create container for all fire effects
	local fireContainer = Instance.new("Part")
	fireContainer.Name = "Element_FireVFX"
	fireContainer.Size = Vector3.new(1, 1, 1)
	fireContainer.Transparency = 1
	fireContainer.CanCollide = false
	fireContainer.Anchored = false
	fireContainer.Massless = true
	fireContainer.Parent = mainPart

	-- Weld to main part
	local weld = Instance.new("Weld")
	weld.Part0 = mainPart
	weld.Part1 = fireContainer
	weld.C0 = CFrame.new(0, 0, 0)
	weld.Parent = fireContainer

	-- Main fire effect
	local fire = Instance.new("Fire")
	fire.Name = "MainFire"
	fire.Heat = 8
	fire.Size = 8
	fire.Color = Color3.fromRGB(255, 180, 60)
	fire.SecondaryColor = Color3.fromRGB(255, 60, 10)
	fire.Parent = fireContainer

	-- Glowing ember particles
	local embers = Instance.new("ParticleEmitter")
	embers.Name = "FireEmbers"
	embers.Rate = 25
	embers.Lifetime = NumberRange.new(0.8, 1.5)
	embers.Speed = NumberRange.new(2, 5)
	embers.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0)
	})
	embers.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 150, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 10))
	})
	embers.LightEmission = 1
	embers.VelocitySpread = 45
	embers.Rotation = NumberRange.new(-180, 180)
	embers.Parent = fireContainer

	-- Smoke effect
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "FireSmoke"
	smoke.Rate = 15
	smoke.Lifetime = NumberRange.new(1.2, 2.0)
	smoke.Speed = NumberRange.new(1, 3)
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(0.7, 2.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	smoke.Color = ColorSequence.new(
		Color3.fromRGB(100, 100, 100),
		Color3.fromRGB(30, 30, 30)
	)
	smoke.LightEmission = 0.2
	smoke.VelocitySpread = 180
	smoke.Acceleration = Vector3.new(0, 4, 0)
	smoke.Parent = fireContainer

	-- Point light for illumination
	local light = Instance.new("PointLight")
	light.Name = "FireLight"
	light.Brightness = 5
	light.Range = 12
	light.Color = Color3.fromRGB(255, 140, 40)
	light.Parent = fireContainer

	Debris:AddItem(fireContainer, dur)
end

function FireVFX.PlaySound(part)
	if not part then return end
	local sound = AudioManager.playSound("Elements.Fire", part, {
		Name = "FireSFX",
		Volume = 0.7,
		PlaybackSpeed = 1.0,
		RollOffMaxDistance = 35
	})
	if sound then
		Debris:AddItem(sound, 5)
	end
end

return FireVFX
