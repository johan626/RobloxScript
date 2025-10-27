-- ShockVFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ElementVFX/ShockVFXModule.lua
-- Script Place: ACT 1: Village

local ShockVFXModule = {}

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))

-- Helper functions
local function _makeAttachment(parent: Instance, name: string)
	local a = Instance.new("Attachment")
	a.Name = name
	a.Parent = parent
	return a
end

function ShockVFXModule.SpawnShockImpact(part: BasePart, life: number)
	if not part then return end

	-- Main flash sphere with improved lightning effect
	local flash = Instance.new("Part")
	flash.Name = "ShockImpact"
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.new(0.6, 0.6, 0.6)
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(180, 220, 255)
	flash.Transparency = 0.3
	flash.CanCollide = false
	flash.Anchored = true
	flash.CFrame = part.CFrame
	flash.Parent = workspace

	-- Bright light source
	local L = Instance.new("PointLight")
	L.Color = Color3.fromRGB(180, 220, 255)
	L.Brightness = 8
	L.Range = 12
	L.Parent = flash

	-- Lightning burst particles
	local burst = Instance.new("ParticleEmitter")
	burst.Name = "ShockBurst"
	burst.Rate = 50
	burst.Lifetime = NumberRange.new(0.2, 0.4)
	burst.Speed = NumberRange.new(8, 15)
	burst.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0)
	})
	burst.Color = ColorSequence.new(
		Color3.fromRGB(200, 235, 255),
		Color3.fromRGB(150, 210, 255)
	)
	burst.LightEmission = 1
	burst.VelocitySpread = 360
	burst.Parent = flash

	-- Quick fade out animation
	local tweenInfo = TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(flash, tweenInfo, {Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1})
	tween:Play()

	Debris:AddItem(flash, life)
end

function ShockVFXModule.SpawnShockBeam(p0: BasePart, p1: BasePart, life: number)
	if not (p0 and p1) then return end
	local a0 = _makeAttachment(p0, "ShockA0")
	local a1 = _makeAttachment(p1, "ShockA1")

	-- Create more dynamic lightning beam
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 0.15
	beam.Width1 = 0.15
	beam.Brightness = 8
	beam.LightEmission = 1
	beam.Segments = 12  -- More segments for smoother curve
	beam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(225, 245, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 220, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 200, 255))
	})

	-- More pronounced lightning curve
	beam.CurveSize0 = (math.random() - 0.5) * 12
	beam.CurveSize1 = (math.random() - 0.5) * 12

	-- Add texture for lightning effect
	beam.Texture = "rbxassetid://9864638822"  -- Lightning texture
	beam.TextureSpeed = 5
	beam.TextureLength = 3

	-- Pulsating effect
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.2, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(0.8, 0.4),
		NumberSequenceKeypoint.new(1, 0)
	})

	beam.Parent = a0

	-- Short-lived
	Debris:AddItem(beam, life)
	Debris:AddItem(a0, life)
	Debris:AddItem(a1, life)
end

function ShockVFXModule.SpawnBranchArcs(originPart: BasePart, life: number)
	if not originPart then return end
	-- 4-5 arcs around origin for more realistic lightning
	for i = 1, 5 do
		local ghost = Instance.new("Part")
		ghost.Name = "ShockArc"..i
		ghost.Size = Vector3.new(0.15, 0.15, 0.15)
		ghost.Anchored = true
		ghost.CanCollide = false
		ghost.Material = Enum.Material.Neon
		ghost.Color = Color3.fromRGB(200, 235, 255)
		ghost.Transparency = 0.3

		-- More varied and dynamic positioning
		local offset = Vector3.new(
			(math.random()-0.5)*4,
			(math.random()-0.2)*3,
			(math.random()-0.5)*4
		)
		ghost.CFrame = originPart.CFrame + offset
		ghost.Parent = workspace

		-- Add small light to arc endpoints
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(180, 220, 255)
		light.Brightness = 4
		light.Range = 5
		light.Parent = ghost

		ShockVFXModule.SpawnShockBeam(originPart, ghost, life * 0.75)
		Debris:AddItem(ghost, life * 0.75)
	end
end

function ShockVFXModule.PlayShockSoundAt(part: BasePart)
	if not part then return end
	local sound = AudioManager.playSound("Elements.Placeholder", part, {
		Name = "ShockSFX",
		Volume = 0.65,
		PlaybackSpeed = 1.0,
		RollOffMaxDistance = 45
	})
	if sound then
		Debris:AddItem(sound, 3)
	end
end

return ShockVFXModule
