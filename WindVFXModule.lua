-- WindVFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ElementVFX/WindVFXModule.lua
-- Script Place: ACT 1: Village

local WindVFX = {}

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))

function WindVFX.SpawnImpact(part: BasePart, life: number)
	if not part then return end
	life = life or 1.0

	-- Main wind gust effect
	local gust = Instance.new("Part")
	gust.Name = "WindImpact"
	gust.Size = Vector3.new(6, 6, 6)
	gust.Shape = Enum.PartType.Ball
	gust.Material = Enum.Material.SmoothPlastic
	gust.Color = Color3.fromRGB(220, 220, 255)
	gust.Transparency = 0.8
	gust.CanCollide = false
	gust.Anchored = true
	gust.CFrame = part.CFrame
	gust.Parent = workspace

	-- Wind particles (swirling air)
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "WindParticles"
	particles.Rate = 150
	particles.Lifetime = NumberRange.new(0.4, 0.8)
	particles.Speed = NumberRange.new(15, 25)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.0),
		NumberSequenceKeypoint.new(0.5, 1.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Color = ColorSequence.new(
		Color3.fromRGB(240, 240, 255),
		Color3.fromRGB(200, 200, 230)
	)
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1)
	})
	particles.LightEmission = 0.3
	particles.VelocitySpread = 360
	particles.Rotation = NumberRange.new(-180, 180)
	particles.Texture = "rbxassetid://9864638822"
	particles.Parent = gust

	-- Dust particles kicked up by wind
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "WindDust"
	dust.Rate = 50
	dust.Lifetime = NumberRange.new(0.6, 1.2)
	dust.Speed = NumberRange.new(8, 15)
	dust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.7, 1.2),
		NumberSequenceKeypoint.new(1, 0)
	})
	dust.Color = ColorSequence.new(
		Color3.fromRGB(200, 200, 180),
		Color3.fromRGB(150, 150, 130)
	)
	dust.Transparency = NumberSequence.new(0.6)
	dust.LightEmission = 0.2
	dust.VelocitySpread = 180
	dust.Acceleration = Vector3.new(0, 8, 0)
	dust.Parent = gust

	-- Wind gust expansion effect
	local expandTween = TweenService:Create(
		gust,
		TweenInfo.new(life * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(12, 12, 12)}
	)
	expandTween:Play()

	-- Fade out animation
	local fadeTween = TweenService:Create(
		gust,
		TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Transparency = 1}
	)
	fadeTween:Play()

	Debris:AddItem(gust, life)
end

function WindVFX.PlaySound(part: BasePart)
	if not part then return end
	local sound = AudioManager.playSound("Elements.Wind", part, {
		Name = "WindSFX",
		Volume = 0.8,
		PlaybackSpeed = 1.0,
		RollOffMaxDistance = 40
	})
	if sound then
		Debris:AddItem(sound, 5)
	end
end

return WindVFX
