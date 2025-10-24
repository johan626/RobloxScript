-- LightVFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ElementVFX/LightVFXModule.lua
-- Script Place: ACT 1: Village

local LightVFX = {}

local Debris = game:GetService("Debris")

local function ensureFolder(char: Model)
	local f = char:FindFirstChild("LightVFX")
	if not f then
		f = Instance.new("Folder")
		f.Name = "LightVFX"
		f.Parent = char
	end
	return f
end

function LightVFX.SpawnForPlayer(player: Player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	if not hrp then return end

	-- clear previous
	local old = char:FindFirstChild("LightVFX")
	if old then old:Destroy() end
	local folder = ensureFolder(char)

	-- glow sphere
	local sphere = Instance.new("Part")
	sphere.Name = "LightGlow"
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = Vector3.new(7, 7, 7)
	sphere.Material = Enum.Material.Neon
	sphere.Color = Color3.fromRGB(255, 255, 200)
	sphere.Transparency = 0.8
	sphere.CanCollide = false
	sphere.Massless = true
	sphere.Anchored = false
	sphere.CFrame = hrp.CFrame
	sphere.Parent = folder

	-- point light
	local light = Instance.new("PointLight")
	light.Brightness = 8
	light.Range = 15
	light.Color = Color3.fromRGB(255, 255, 150)
	light.Parent = sphere

	-- particles
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "LightParticles"
	particles.Rate = 20
	particles.Lifetime = NumberRange.new(0.5, 1.2)
	particles.Speed = NumberRange.new(2, 4)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Color = ColorSequence.new(
		Color3.fromRGB(255, 255, 180),
		Color3.fromRGB(255, 255, 100)
	)
	particles.LightEmission = 0.8
	particles.Transparency = NumberSequence.new(0.5)
	particles.VelocitySpread = 360
	particles.Parent = sphere

	-- weld ke HRP
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = sphere
	weld.Parent = sphere
end

function LightVFX.RemoveForPlayer(player: Player)
	local char = player.Character
	if not char then return end
	local folder = char:FindFirstChild("LightVFX")
	if folder then folder:Destroy() end
end


return LightVFX
