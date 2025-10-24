-- EarthVFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ElementVFX/EarthVFXModule.lua
-- Script Place: ACT 1: Village

local EarthVFX = {}

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))

local function _ensureEarthFolder(char)
	local f = char:FindFirstChild("EarthVFX")
	if not f then
		f = Instance.new("Folder")
		f.Name = "EarthVFX"
		f.Parent = char
	end
	return f
end

function EarthVFX.SpawnForPlayer(player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	if not hrp then return end

	-- Clear previous earth VFX
	local old = char:FindFirstChild("EarthVFX")
	if old then old:Destroy() end
	local folder = _ensureEarthFolder(char)

	-- Earth aura effect (rotating rock particles)
	local earthAura = Instance.new("Part")
	earthAura.Name = "EarthAura"
	earthAura.Shape = Enum.PartType.Ball
	earthAura.Size = Vector3.new(10, 10, 10)
	earthAura.Material = Enum.Material.Granite
	earthAura.Color = Color3.fromRGB(101, 67, 33)  -- Brown earth tone
	earthAura.Transparency = 0.9
	earthAura.CanCollide = false
	earthAura.Massless = true
	earthAura.Anchored = false
	earthAura.CFrame = hrp.CFrame
	earthAura.Parent = folder

	-- Weld to HRP
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = earthAura
	weld.Parent = earthAura

	-- Earth particles (floating rocks and debris)
	local earthParticles = Instance.new("ParticleEmitter")
	earthParticles.Name = "EarthParticles"
	earthParticles.Rate = 50
	earthParticles.Lifetime = NumberRange.new(1.5, 2.0)
	earthParticles.Speed = NumberRange.new(2, 4)
	earthParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.5, 1.2),
		NumberSequenceKeypoint.new(1, 0)
	})
	earthParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(121, 85, 72)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(93, 64, 55)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(62, 39, 35))
	})
	earthParticles.LightEmission = 0.4
	earthParticles.Transparency = NumberSequence.new(0.5)
	earthParticles.VelocitySpread = 360
	earthParticles.Rotation = NumberRange.new(-180, 180)
	earthParticles.Parent = earthAura

	-- Create orbiting rocks around player
	for i = 1, 8 do
		local rock = Instance.new("Part")
		rock.Name = "EarthRock" .. i
		rock.Shape = Enum.PartType.Block
		rock.Size = Vector3.new(1.2, 1.2, 1.2)
		rock.Material = Enum.Material.Slate
		rock.Color = Color3.fromRGB(93, 64, 55)
		rock.Transparency = 0.2
		rock.CanCollide = false
		rock.Massless = true
		rock.Anchored = false
		rock.Parent = folder

		-- Rock particles
		local rockParticles = Instance.new("ParticleEmitter")
		rockParticles.Name = "RockParticles"
		rockParticles.Rate = 15
		rockParticles.Lifetime = NumberRange.new(0.5, 1.0)
		rockParticles.Speed = NumberRange.new(0.5, 1)
		rockParticles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 0)
		})
		rockParticles.Color = ColorSequence.new(
			Color3.fromRGB(121, 85, 72),
			Color3.fromRGB(93, 64, 55)
		)
		rockParticles.LightEmission = 0.3
		rockParticles.Transparency = NumberSequence.new(0.4)
		rockParticles.Parent = rock

		-- Rock orbit animation
		task.spawn(function()
			local angle = (i - 1) * math.pi / 4
			local radius = 6
			local height = 3

			while rock and rock.Parent do
				angle = angle + 0.01
				local x = math.cos(angle) * radius
				local z = math.sin(angle) * radius
				local y = math.sin(angle * 2) * height / 2 + height / 2

				rock.CFrame = hrp.CFrame * CFrame.new(x, y, z) * CFrame.Angles(math.random() * math.pi, math.random() * math.pi, math.random() * math.pi)
				task.wait()
			end
		end)
	end

	-- Ground crack effect at player's feet
	local groundCrack = Instance.new("Part")
	groundCrack.Name = "GroundCrack"
	groundCrack.Size = Vector3.new(8, 0.3, 8)
	groundCrack.Material = Enum.Material.Cobblestone
	groundCrack.Color = Color3.fromRGB(62, 39, 35)
	groundCrack.Transparency = 1
	groundCrack.CanCollide = false
	groundCrack.Anchored = true
	groundCrack.CFrame = hrp.CFrame * CFrame.new(0, -3.5, 0)
	groundCrack.Parent = folder

	-- Ground particles
	local groundParticles = Instance.new("ParticleEmitter")
	groundParticles.Name = "GroundParticles"
	groundParticles.Rate = 20
	groundParticles.Lifetime = NumberRange.new(1.0, 1.5)
	groundParticles.Speed = NumberRange.new(1, 3)
	groundParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.7, 1.0),
		NumberSequenceKeypoint.new(1, 0)
	})
	groundParticles.Color = ColorSequence.new(
		Color3.fromRGB(93, 64, 55),
		Color3.fromRGB(62, 39, 35)
	)
	groundParticles.LightEmission = 0.3
	groundParticles.Transparency = NumberSequence.new(0.6)
	groundParticles.VelocitySpread = 90
	groundParticles.Parent = groundCrack

	-- Earth light source
	local earthLight = Instance.new("PointLight")
	earthLight.Name = "EarthLight"
	earthLight.Brightness = 4
	earthLight.Range = 12
	earthLight.Color = Color3.fromRGB(101, 67, 33)
	earthLight.Parent = earthAura
end

function EarthVFX.RemoveForPlayer(player)
	local char = player.Character
	if not char then return end
	local earthFolder = char:FindFirstChild("EarthVFX")
	if earthFolder then earthFolder:Destroy() end
end

function EarthVFX.SpawnImpact(part, life)
	if not part then return end

	-- Main earth impact effect
	local earthImpact = Instance.new("Part")
	earthImpact.Name = "EarthImpact"
	earthImpact.Shape = Enum.PartType.Ball
	earthImpact.Size = Vector3.new(4, 4, 4)
	earthImpact.Material = Enum.Material.Slate
	earthImpact.Color = Color3.fromRGB(101, 67, 33)
	earthImpact.Transparency = 0.7
	earthImpact.CanCollide = false
	earthImpact.Anchored = true
	earthImpact.CFrame = part.CFrame
	earthImpact.Parent = workspace

	-- Earth light source
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(101, 67, 33)
	light.Brightness = 6
	light.Range = 12
	light.Parent = earthImpact

	-- Rock debris particles
	local rocks = Instance.new("ParticleEmitter")
	rocks.Name = "EarthRocks"
	rocks.Rate = 60
	rocks.Lifetime = NumberRange.new(0.8, 1.2)
	rocks.Speed = NumberRange.new(10, 15)
	rocks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.4, 1.2),
		NumberSequenceKeypoint.new(1, 0)
	})
	rocks.Color = ColorSequence.new({
		NumberSequenceKeypoint.new(0, Color3.fromRGB(121, 85, 72)),
		NumberSequenceKeypoint.new(0.5, Color3.fromRGB(93, 64, 55)),
		NumberSequenceKeypoint.new(1, Color3.fromRGB(62, 39, 35))
	})
	rocks.LightEmission = 0.5
	rocks.Transparency = NumberSequence.new(0.4)
	rocks.VelocitySpread = 360
	rocks.Rotation = NumberRange.new(-180, 180)
	rocks.Parent = earthImpact

	-- Dust cloud particles
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "EarthDust"
	dust.Rate = 50
	dust.Lifetime = NumberRange.new(1.0, 1.6)
	dust.Speed = NumberRange.new(4, 8)
	dust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.0),
		NumberSequenceKeypoint.new(0.6, 3.0),
		NumberSequenceKeypoint.new(1, 0)
	})
	dust.Color = ColorSequence.new(
		Color3.fromRGB(140, 120, 100),
		Color3.fromRGB(100, 80, 60)
	)
	dust.LightEmission = 0.4
	dust.Transparency = NumberSequence.new(0.7)
	dust.VelocitySpread = 180
	dust.Parent = earthImpact

	-- Stone spikes effect
	for i = 1, 6 do
		local spike = Instance.new("Part")
		spike.Name = "EarthSpike"
		spike.Shape = Enum.PartType.Block
		spike.Size = Vector3.new(0.8, 2.5, 0.8)
		spike.Material = Enum.Material.Slate
		spike.Color = Color3.fromRGB(93, 64, 55)
		spike.Transparency = 0.3
		spike.CanCollide = false
		spike.Anchored = true

		-- Position spikes in a circle around impact point
		local angle = (i - 1) * math.pi / 3
		local offset = Vector3.new(math.cos(angle) * 3, 0, math.sin(angle) * 3)
		spike.CFrame = part.CFrame * CFrame.new(offset) * CFrame.Angles(math.pi/2, 0, 0)
		spike.Parent = workspace

		-- Add debris to remove spikes
		Debris:AddItem(spike, life * 1.5)
	end

	-- Fade out animation
	local tweenInfo = TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(earthImpact, tweenInfo, {
		Size = Vector3.new(0.1, 0.1, 0.1), 
		Transparency = 1
	})
	tween:Play()

	Debris:AddItem(earthImpact, life)
end

function EarthVFX.PlaySoundAt(part)
	if not part then return end
	local sound = AudioManager.playSound("Elements.Earth", part, {
		Name = "EarthSFX",
		Volume = 0.7,
		PlaybackSpeed = 1.0,
		RollOffMaxDistance = 35
	})
	if sound then
		Debris:AddItem(sound, 5)
	end
end

return EarthVFX
