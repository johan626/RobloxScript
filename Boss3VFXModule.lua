-- Boss3VFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/Boss3VFXModule.lua
-- Script Place: ACT 1: Village

local Boss3VFXModule = {}

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- === FUNGSI VFX BARU UNTUK BOSS 3 V2 ===

function Boss3VFXModule.CreateMovementTransition(bossModel, movementName)
	local color = Color3.fromRGB(255, 255, 255)
	if movementName == "Allegro" then
		color = Color3.fromRGB(100, 255, 100)
	elseif movementName == "Adagio" then
		color = Color3.fromRGB(150, 100, 255)
	elseif movementName == "Fortissimo" then
		color = Color3.fromRGB(255, 100, 100)
	end

	local shockwave = Instance.new("Part")
	shockwave.Size = Vector3.new(0.5, 1, 1)
	shockwave.Shape = Enum.PartType.Cylinder
	shockwave.CFrame = CFrame.new(bossModel.PrimaryPart.Position) * CFrame.Angles(0,0,math.rad(90))
	shockwave.Anchored = true
	shockwave.CanCollide = false
	shockwave.Material = Enum.Material.Neon
	shockwave.Color = color
	shockwave.Parent = Workspace

	local duration = 1.5
	local expandTween = TweenService:Create(shockwave, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = Vector3.new(0.5, 200, 200), Transparency = 1})
	expandTween:Play()
	Debris:AddItem(shockwave, duration)
end

function Boss3VFXModule.CreateSoulStreamProjectile(startPos, direction, config)
	local projectile = Instance.new("Part")
	projectile.Shape = Enum.PartType.Ball
	projectile.Size = Vector3.new(3, 3, 3)
	projectile.CFrame = CFrame.new(startPos)
	projectile.Material = Enum.Material.Neon
	projectile.Color = Color3.fromRGB(100, 255, 100)
	projectile.CanCollide = false
	projectile.Anchored = false
	projectile.Velocity = direction * config.ProjectileSpeed
	projectile.Parent = Workspace
	Debris:AddItem(projectile, 5)
end

function Boss3VFXModule.CreateNecroticEruptionTelegraph(position, config)
	local telegraph = Instance.new("Part")
	telegraph.Shape = Enum.PartType.Cylinder
	telegraph.Size = Vector3.new(0.5, config.Radius * 2, config.Radius * 2)
	telegraph.CFrame = CFrame.new(position) * CFrame.Angles(0,0,math.rad(90))
    telegraph.Anchored = true
    telegraph.CanCollide = false
    telegraph.Material = Enum.Material.ForceField
    telegraph.Color = Color3.fromRGB(100, 255, 100)
    telegraph.Transparency = 0.5
    telegraph.Parent = Workspace
    Debris:AddItem(telegraph, config.TelegraphDuration)
end

function Boss3VFXModule.CreateCorruptingBlastTelegraph(position, config)
	local telegraph = Instance.new("Part")
	telegraph.Shape = Enum.PartType.Cylinder
	telegraph.Size = Vector3.new(0.5, config.BlastRadius * 2, config.BlastRadius * 2)
	telegraph.CFrame = CFrame.new(position) * CFrame.Angles(0,0,math.rad(90))
    telegraph.Anchored = true
    telegraph.CanCollide = false
    telegraph.Material = Enum.Material.ForceField
    telegraph.Color = Color3.fromRGB(150, 100, 255)
    telegraph.Transparency = 0.5
    telegraph.Parent = Workspace
    Debris:AddItem(telegraph, config.TelegraphDuration)
end

function Boss3VFXModule.ExecuteCorruptingBlast(position, config)
	local puddle = Instance.new("Part")
	puddle.Shape = Enum.PartType.Cylinder
	puddle.Size = Vector3.new(0.5, config.BlastRadius * 2, config.BlastRadius * 2)
	puddle.CFrame = CFrame.new(position) * CFrame.Angles(0,0,math.rad(90))
    puddle.Anchored = true
    puddle.CanCollide = false
    puddle.Material = Enum.Material.Neon
    puddle.Color = Color3.fromRGB(150, 100, 255)
    puddle.Transparency = 0.8
    puddle.Parent = Workspace
	Debris:AddItem(puddle, config.PuddleDuration)
end

function Boss3VFXModule.CreateChainsOfTorment(player1, player2, config)
	local p1Attach = Instance.new("Attachment", player1.Character.HumanoidRootPart)
	local p2Attach = Instance.new("Attachment", player2.Character.HumanoidRootPart)

	local chain = Instance.new("Beam")
	chain.Attachment0 = p1Attach
	chain.Attachment1 = p2Attach
	chain.Color = ColorSequence.new(Color3.fromRGB(255, 100, 100))
	chain.Width0 = 1
	chain.Width1 = 1
	chain.Segments = 10
	chain.Parent = player1.Character.HumanoidRootPart

	Debris:AddItem(chain, config.Duration)
	Debris:AddItem(p1Attach, config.Duration)
	Debris:AddItem(p2Attach, config.Duration)
	return chain
end

function Boss3VFXModule.CreateCrescendoOfSoulsTelegraph(bossModel, config)
	local pillars = Workspace:FindFirstChild("ArenaPillars") -- Assuming pillars are grouped
	if not pillars then return nil end

	local safePillar = pillars:GetChildren()[math.random(#pillars:GetChildren())]

	for _, pillar in ipairs(pillars:GetChildren()) do
		local light = Instance.new("SpotLight", pillar)
		light.Range = 200
		light.Angle = 180
		if pillar == safePillar then
			light.Color = Color3.fromRGB(255, 255, 255)
		else
			light.Color = Color3.fromRGB(255, 0, 0)
		end
		Debris:AddItem(light, config.ChargeDuration)
	end

	return safePillar
end

function Boss3VFXModule.ExecuteCrescendoOfSouls(bossModel, safePillar, config)
	local explosion = Instance.new("Part")
	explosion.Shape = Enum.PartType.Ball
	explosion.Size = Vector3.new(500, 500, 500)
	explosion.Position = bossModel.PrimaryPart.Position
	explosion.Material = Enum.Material.Neon
	explosion.Color = Color3.fromRGB(255, 100, 100)
	explosion.Anchored = true
	explosion.CanCollide = false

	local tween = TweenService:Create(explosion, TweenInfo.new(0.5), {Transparency = 1})
	tween:Play()
	explosion.Parent = Workspace
	Debris:AddItem(explosion, 0.5)
end

return Boss3VFXModule
