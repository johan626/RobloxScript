-- Boss2VFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/Boss2VFXModule.lua
-- Script Place: ACT 1: Village

local Boss2VFXModule = {}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))
local ElementModule = require(ModuleScriptServerScriptService:WaitForChild("ElementConfigModule"))

-- === FUNGSI VFX BARU UNTUK BOSS 2 V2 ===

function Boss2VFXModule.CreateOrbOfAnnihilation(startPosition)
	local orb = Instance.new("Part")
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(8, 8, 8)
	orb.CFrame = CFrame.new(startPosition)
	orb.Material = Enum.Material.ForceField
	orb.Color = Color3.fromRGB(170, 0, 255)
	orb.CanCollide = false
	orb.Anchored = false

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(200, 50, 255)
	light.Brightness = 3
	light.Range = 30
	light.Parent = orb

	local trail = Instance.new("Trail")
	trail.Attachment0 = Instance.new("Attachment", orb)
	trail.Attachment1 = Instance.new("Attachment", Workspace.Terrain) -- Temporary
	trail.Color = ColorSequence.new(Color3.fromRGB(170, 0, 255))
	trail.Lifetime = 0.5
	trail.WidthScale = NumberSequence.new(10, 0)
	trail.Parent = orb

	orb.Parent = Workspace
	return orb
end

function Boss2VFXModule.ExecuteOrbExplosion(position, config)
	local explosion = Instance.new("Part")
	explosion.Shape = Enum.PartType.Ball
	explosion.Size = Vector3.new(1, 1, 1)
	explosion.CFrame = CFrame.new(position)
	explosion.Anchored = true
	explosion.CanCollide = false
	explosion.Material = Enum.Material.Neon
	explosion.Color = Color3.fromRGB(200, 100, 255)

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(explosion, tweenInfo, {
		Size = Vector3.new(config.ExplosionRadius * 2, config.ExplosionRadius * 2, config.ExplosionRadius * 2),
		Transparency = 1
	})
	tween:Play()

	explosion.Parent = Workspace
	Debris:AddItem(explosion, 0.6)
end

function Boss2VFXModule.CreateUpheaval(centerPosition, config)
	local platforms = {}
	for i = 1, config.PlatformCount do
		local angle = (i / config.PlatformCount) * math.pi * 2
		local x = math.cos(angle) * config.ArenaRadius
		local z = math.sin(angle) * config.ArenaRadius

		local platform = Instance.new("Part")
		platform.Size = config.PlatformSize
		platform.Position = centerPosition + Vector3.new(x, -config.PlatformSize.Y, z)
		platform.Anchored = true
		platform.Material = Enum.Material.Rock

		local tweenInfo = TweenInfo.new(config.Duration, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
		local tween = TweenService:Create(platform, tweenInfo, {Position = centerPosition + Vector3.new(x, 0, z)})
		tween:Play()

		platform.Parent = Workspace
		table.insert(platforms, platform)
	end
	return platforms
end

function Boss2VFXModule.CreatePlatformShatterTelegraph(platform, config)
	local telegraph = Instance.new("BoxHandleAdornment")
	telegraph.Adornee = platform
	telegraph.Size = platform.Size
	telegraph.Color3 = Color3.fromRGB(255, 0, 0)
	telegraph.Transparency = 0.5
	telegraph.AlwaysOnTop = true
	telegraph.Parent = platform
	Debris:AddItem(telegraph, config.TelegraphDuration)
end

function Boss2VFXModule.ExecutePlatformShatter(platform, config)
	platform:Destroy()
end

function Boss2VFXModule.CreateCelestialRainTelegraph(position, config)
	local telegraph = Instance.new("Part")
	telegraph.Shape = Enum.PartType.Cylinder
	telegraph.Size = Vector3.new(0.5, config.BlastRadius * 2, config.BlastRadius * 2)
	telegraph.CFrame = CFrame.new(position) * CFrame.Angles(0,0,math.rad(90))
    telegraph.Anchored = true
    telegraph.CanCollide = false
    telegraph.Material = Enum.Material.ForceField
    telegraph.Color = Color3.fromRGB(200, 100, 255)
    telegraph.Transparency = 0.5
	telegraph.Name = "RainTelegraph"
    telegraph.Parent = Workspace

    Debris:AddItem(telegraph, config.TelegraphDuration)
end

function Boss2VFXModule.ExecuteCelestialRain(position, config)
	local explosion = Instance.new("Part")
	explosion.Shape = Enum.PartType.Ball
	explosion.Size = Vector3.new(1, 1, 1)
	explosion.CFrame = CFrame.new(position)
	explosion.Anchored = true
	explosion.CanCollide = false
	explosion.Material = Enum.Material.Neon
	explosion.Color = Color3.fromRGB(200, 100, 255)

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(explosion, tweenInfo, {
		Size = Vector3.new(config.BlastRadius * 2, config.BlastRadius * 2, config.BlastRadius * 2),
		Transparency = 1
	})
	tween:Play()

	explosion.Parent = Workspace
	Debris:AddItem(explosion, 0.6)
end

return Boss2VFXModule
