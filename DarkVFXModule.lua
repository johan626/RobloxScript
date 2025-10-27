-- DarkVFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ElementVFX/DarkVFXModule.lua
-- Script Place: ACT 1: Village

local DarkVFX = {}

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))

local function _makeAttachment(parent: Instance, name: string)
	local a = Instance.new("Attachment")
	a.Name = name
	a.Parent = parent
	return a
end

function DarkVFX.SpawnImpact(part: BasePart, life: number)
	if not part then return end

	-- Main dark sphere
	local darkSphere = Instance.new("Part")
	darkSphere.Name = "DarkImpact"
	darkSphere.Shape = Enum.PartType.Ball
	darkSphere.Size = Vector3.new(3, 3, 3)
	darkSphere.Material = Enum.Material.Neon
	darkSphere.Color = Color3.fromRGB(30, 0, 40)
	darkSphere.Transparency = 0.6
	darkSphere.CanCollide = false
	darkSphere.Anchored = true
	darkSphere.CFrame = part.CFrame
	darkSphere.Parent = workspace

	-- Dark energy light source
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(60, 0, 80)
	light.Brightness = 6
	light.Range = 12
	light.Parent = darkSphere

	-- Dark energy particles
	local energy = Instance.new("ParticleEmitter")
	energy.Name = "DarkEnergy"
	energy.Rate = 60
	energy.Lifetime = NumberRange.new(0.5, 1.2)
	energy.Speed = NumberRange.new(8, 15)
	energy.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.5, 1.2),
		NumberSequenceKeypoint.new(1, 0)
	})
	energy.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 0, 100)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(60, 0, 80)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(40, 0, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 0, 30))
	})
	energy.LightEmission = 0.8
	energy.Transparency = NumberSequence.new(0.4)
	energy.VelocitySpread = 360
	energy.Rotation = NumberRange.new(-180, 180)
	energy.Parent = darkSphere

	-- Shadow mist particles
	local mist = Instance.new("ParticleEmitter")
	mist.Name = "DarkMist"
	mist.Rate = 40
	mist.Lifetime = NumberRange.new(0.8, 1.5)
	mist.Speed = NumberRange.new(3, 6)
	mist.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(0.6, 2.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	mist.Color = ColorSequence.new(
		Color3.fromRGB(40, 0, 50),
		Color3.fromRGB(20, 0, 30)
	)
	mist.LightEmission = 0.3
	mist.Transparency = NumberSequence.new(0.6)
	mist.VelocitySpread = 180
	mist.Parent = darkSphere

	-- Void tendrils effect
	local tendrils = Instance.new("ParticleEmitter")
	tendrils.Name = "DarkTendrils"
	tendrils.Rate = 20
	tendrils.Lifetime = NumberRange.new(0.7, 1.0)
	tendrils.Speed = NumberRange.new(5, 10)
	tendrils.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.3, 0.6),
		NumberSequenceKeypoint.new(1, 0)
	})
	tendrils.Color = ColorSequence.new(
		Color3.fromRGB(100, 0, 120),
		Color3.fromRGB(60, 0, 80)
	)
	tendrils.LightEmission = 0.9
	tendrils.Transparency = NumberSequence.new(0.3)
	tendrils.VelocitySpread = 90
	tendrils.Rotation = NumberRange.new(-180, 180)
	tendrils.Parent = darkSphere

	-- Fade out animation
	local tweenInfo = TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(darkSphere, tweenInfo, {
		Size = Vector3.new(0.1, 0.1, 0.1), 
		Transparency = 1
	})
	tween:Play()

	Debris:AddItem(darkSphere, life)
end

function DarkVFX.SpawnLifestealVFX(sourceModel: Model, targetCharacter: Model, amount: number)
	if not (sourceModel and targetCharacter) then return end

	local sourcePart = sourceModel.PrimaryPart or sourceModel:FindFirstChild("HumanoidRootPart") or sourceModel:FindFirstChildWhichIsA("BasePart")
	local targetPart = targetCharacter:FindFirstChild("HumanoidRootPart") or targetCharacter.PrimaryPart

	if not (sourcePart and targetPart) then return end

	-- Create a dark energy beam between source and target
	local a0 = _makeAttachment(sourcePart, "DarkBeamA0")
	local a1 = _makeAttachment(targetPart, "DarkBeamA1")

	-- Create the beam
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 0.2
	beam.Width1 = 0.2
	beam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 0, 150)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 0, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 60))
	})
	beam.Brightness = 3
	beam.LightEmission = 0.7
	beam.Segments = 10
	beam.CurveSize0 = 2
	beam.CurveSize1 = -2

	-- Pulsating effect
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.3, 0.5),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 0.2)
	})

	beam.Parent = a0

	-- Life particles flowing from source to target
	local lifeParticles = Instance.new("ParticleEmitter")
	lifeParticles.Name = "LifeParticles"
	lifeParticles.Rate = 30
	lifeParticles.Lifetime = NumberRange.new(0.5, 0.8)
	lifeParticles.Speed = NumberRange.new(10, 15)
	lifeParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	lifeParticles.Color = ColorSequence.new(
		Color3.fromRGB(180, 0, 220),
		Color3.fromRGB(120, 0, 150)
	)
	lifeParticles.LightEmission = 0.8
	lifeParticles.Transparency = NumberSequence.new(0.3)
	lifeParticles.VelocityInheritance = 0
	lifeParticles.Parent = beam

	-- Target healing effect
	local healGlow = Instance.new("Part")
	healGlow.Name = "HealGlow"
	healGlow.Shape = Enum.PartType.Ball
	healGlow.Size = Vector3.new(2, 2, 2)
	healGlow.Material = Enum.Material.Neon
	healGlow.Color = Color3.fromRGB(100, 0, 120)
	healGlow.Transparency = 1
	healGlow.CanCollide = false
	healGlow.Anchored = true
	healGlow.CFrame = targetPart.CFrame
	healGlow.Parent = workspace

	local healLight = Instance.new("PointLight")
	healLight.Color = Color3.fromRGB(120, 0, 150)
	healLight.Brightness = 5
	healLight.Range = 8
	healLight.Parent = healGlow

	-- Fade out effects after short duration
	local life = 1.0
	Debris:AddItem(beam, life)
	Debris:AddItem(a0, life)
	Debris:AddItem(a1, life)
	Debris:AddItem(healGlow, life * 0.5)
end

function DarkVFX.SpawnForPlayer(player: Player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	if not hrp then return end

	-- Clear previous dark aura
	local old = char:FindFirstChild("DarkAura")
	if old then old:Destroy() end

	-- Create aura container
	local auraFolder = Instance.new("Folder")
	auraFolder.Name = "DarkAura"
	auraFolder.Parent = char

	-- Dark energy orb around player
	local energyOrb = Instance.new("Part")
	energyOrb.Name = "DarkEnergyOrb"
	energyOrb.Shape = Enum.PartType.Ball
	energyOrb.Size = Vector3.new(8, 8, 8)
	energyOrb.Material = Enum.Material.Neon
	energyOrb.Color = Color3.fromRGB(40, 0, 50)
	energyOrb.Transparency = 0.8
	energyOrb.CanCollide = false
	energyOrb.Massless = true
	energyOrb.Anchored = false
	energyOrb.CFrame = hrp.CFrame
	energyOrb.Parent = auraFolder

	-- Weld to HRP
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = energyOrb
	weld.Parent = energyOrb

	-- Dark energy particles
	local energyParticles = Instance.new("ParticleEmitter")
	energyParticles.Name = "DarkAuraParticles"
	energyParticles.Rate = 50
	energyParticles.Lifetime = NumberRange.new(1.0, 1.5)
	energyParticles.Speed = NumberRange.new(2, 4)
	energyParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.5, 1.2),
		NumberSequenceKeypoint.new(1, 0)
	})
	energyParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 0, 100)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 0, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 0, 60))
	})
	energyParticles.LightEmission = 0.7
	energyParticles.Transparency = NumberSequence.new(0.5)
	energyParticles.VelocitySpread = 360
	energyParticles.Parent = energyOrb

	-- Floating dark orbs around player
	for i = 1, 4 do
		task.wait(0.1)
		local orb = Instance.new("Part")
		orb.Name = "DarkOrb" .. i
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(1.5, 1.5, 1.5)
		orb.Material = Enum.Material.Neon
		orb.Color = Color3.fromRGB(60, 0, 80)
		orb.Transparency = 0.4
		orb.CanCollide = false
		orb.Massless = true
		orb.Anchored = false
		orb.Parent = auraFolder

		-- Orb light
		local orbLight = Instance.new("PointLight")
		orbLight.Color = Color3.fromRGB(80, 0, 100)
		orbLight.Brightness = 3
		orbLight.Range = 6
		orbLight.Parent = orb

		-- Orb particles
		local orbParticles = Instance.new("ParticleEmitter")
		orbParticles.Name = "OrbParticles"
		orbParticles.Rate = 20
		orbParticles.Lifetime = NumberRange.new(0.5, 1.0)
		orbParticles.Speed = NumberRange.new(1, 2)
		orbParticles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 0)
		})
		orbParticles.Color = ColorSequence.new(
			Color3.fromRGB(100, 0, 120),
			Color3.fromRGB(60, 0, 80)
		)
		orbParticles.LightEmission = 0.8
		orbParticles.Transparency = NumberSequence.new(0.3)
		orbParticles.Parent = orb

		-- Orb orbit animation
		task.spawn(function()
			local angle = (i - 1) * math.pi / 2
			local radius = 4
			local height = 2

			while orb and orb.Parent do
				angle = angle + 0.02
				local x = math.cos(angle) * radius
				local z = math.sin(angle) * radius
				local y = math.sin(angle * 2) * height / 2 + height / 2

				orb.CFrame = hrp.CFrame * CFrame.new(x, y, z)
				task.wait()
			end
		end)
	end
end

function DarkVFX.RemoveForPlayer(player: Player)
	local char = player.Character
	if not char then return end
	local auraFolder = char:FindFirstChild("DarkAura")
	if auraFolder then auraFolder:Destroy() end
end

function DarkVFX.PlaySoundAt(part: BasePart)
	if not part then return end
	local sound = AudioManager.playSound("Elements.Placeholder", part, {
		Name = "DarkSFX",
		Volume = 0.7,
		PlaybackSpeed = 1.0,
		RollOffMaxDistance = 35
	})
	if sound then
		Debris:AddItem(sound, 5)
	end
end

return DarkVFX
