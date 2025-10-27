-- ShooterVFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/ShooterVFXModule.lua
-- Script Place: ACT 1: Village

local ShooterVFXModule = {}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ServerScriptService = game:GetService("ServerScriptService")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))
local ElementModule = require(ModuleScriptServerScriptService:WaitForChild("ElementConfigModule"))
local ShieldModule = require(ModuleScriptServerScriptService:WaitForChild("ShieldModule"))

-- === Helpers khusus Shooter ===
function ShooterVFXModule.CreateAcidPool(position, config)
	-- (isi = salin dari ZombieVFXModule.CreateAcidPool yang lama, tanpa perubahan)
	-- --- MULAI SALINAN ---
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {workspace.Terrain}
	raycastParams.FilterType = Enum.RaycastFilterType.Include

	local raycastResult = workspace:Raycast(position, Vector3.new(0, -50, 0), raycastParams)
	local groundPosition = position
	if raycastResult then groundPosition = raycastResult.Position end

	local pool = Instance.new("Part")
	pool.Size = Vector3.new(8, 0.3, 8)
	pool.Position = groundPosition + Vector3.new(0, 0.1, 0)
	pool.Anchored = true
	pool.CanCollide = false
	pool.Material = Enum.Material.Neon
	pool.Color = Color3.fromRGB(80, 200, 60)
	pool.Transparency = 0.7
	pool.Name = "AcidPool"
	pool.TopSurface = Enum.SurfaceType.Smooth
	pool.BottomSurface = Enum.SurfaceType.Smooth

	local mesh = Instance.new("CylinderMesh")
	mesh.Parent = pool

	local particles = Instance.new("ParticleEmitter")
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 20
	particles.Speed = NumberRange.new(1, 3)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	particles.Color = ColorSequence.new(Color3.fromRGB(80, 200, 60))
	particles.Acceleration = Vector3.new(0, 2, 0)
	particles.Parent = pool

	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Lifetime = NumberRange.new(1, 2)
	bubbles.Rate = 10
	bubbles.Speed = NumberRange.new(1, 2)
	bubbles.Size = NumberSequence.new(0.3)
	bubbles.Transparency = NumberSequence.new(0.5)
	bubbles.Color = ColorSequence.new(Color3.fromRGB(200, 255, 200))
	bubbles.Acceleration = Vector3.new(0, 5, 0)
	bubbles.Parent = pool

	local light = Instance.new("PointLight")
	light.Brightness = 5
	light.Range = 10
	light.Color = Color3.fromRGB(80, 200, 60)
	light.Parent = pool

	AudioManager.playSound("VFX.Acid", pool, { Volume = 0.5 })

	pool.Parent = workspace

	local touchedPlayers = {}
	local corrosionEffects = {}

	local function onTouch(hit)
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if not player or touchedPlayers[player] then return end
		if ElementModule.IsPlayerInvincible and ElementModule.IsPlayerInvincible(player) then return end

		touchedPlayers[player] = true

		if not corrosionEffects[hit] then
			corrosionEffects[hit] = true
			if hit:IsA("BasePart") then
				local corrosionParticles = Instance.new("ParticleEmitter")
				corrosionParticles.Lifetime = NumberRange.new(1, 2)
				corrosionParticles.Rate = 5
				corrosionParticles.Speed = NumberRange.new(0.5, 1)
				corrosionParticles.Size = NumberSequence.new(0.2)
				corrosionParticles.Transparency = NumberSequence.new(0.5)
				corrosionParticles.Color = ColorSequence.new(Color3.fromRGB(80, 200, 60))
				corrosionParticles.LightEmission = 0.3
				corrosionParticles.Parent = hit

				hit.Transparency = math.min(0.8, hit.Transparency + 0.2)
				hit.Color = Color3.fromRGB(
					math.floor(hit.Color.R * 0.7),
					math.floor(hit.Color.G * 0.9),
					math.floor(hit.Color.B * 0.7)
				)
				Debris:AddItem(corrosionParticles, 10)
			end
		end

		task.spawn(function()
			local hum = player.Character and player.Character:FindFirstChild("Humanoid")
			if not hum then
				touchedPlayers[player] = nil
				return
			end

			local remaining = config.DoT_Duration or 5
			while remaining > 0 and hum and hum.Health > 0 and pool.Parent do
				local damage = config.DoT_DamagePerTick or 5
				damage = ElementModule.ApplyDamageReduction(player, damage)
				local leftoverDamage = ShieldModule.Damage(player, damage)
				if leftoverDamage > 0 then
					hum:TakeDamage(leftoverDamage)
				end
				remaining = remaining - (config.DoT_Tick or 1)
				task.wait(config.DoT_Tick or 1)
			end

			task.wait(1)
			touchedPlayers[player] = nil
		end)
	end

	pool.Touched:Connect(onTouch)

	pool.Size = Vector3.new(0.1, 0.1, 0.1)
	local growTween = TweenService:Create(pool, TweenInfo.new(0.5), {Size = Vector3.new(8, 0.3, 8)})
	growTween:Play()

	Debris:AddItem(pool, config.PoolDuration or 8)
	-- --- AKHIR SALINAN ---
end

function ShooterVFXModule.ShootAcidProjectile(fromPos, targetPos, speed, shooterModel, config)
	-- (isi = salin dari ZombieVFXModule.ShootAcidProjectile yang lama, hanya ganti pemanggilan CreateAcidPool -> ShooterVFXModule.CreateAcidPool)
	local dir = (targetPos - fromPos).Unit
	local proj = Instance.new("Part")
	proj.Size = Vector3.new(0.8, 0.8, 0.8)
	proj.Shape = Enum.PartType.Ball
	proj.CFrame = CFrame.new(fromPos)
	proj.CanCollide = false
	proj.Anchored = false
	proj.Material = Enum.Material.Neon
	proj.Color = Color3.fromRGB(80, 200, 80)
	proj.Name = "AcidProjectile"
	proj.Velocity = dir * speed
	proj.Parent = workspace

	local trail = Instance.new("Trail")
	trail.Attachment0 = Instance.new("Attachment", proj)
	trail.Attachment1 = Instance.new("Attachment", proj)
	trail.Attachment1.Position = Vector3.new(0, 0, -0.5)
	trail.Color = ColorSequence.new(Color3.fromRGB(80, 200, 80))
	trail.LightEmission = 0.8
	trail.Transparency = NumberSequence.new(0.5)
	trail.Lifetime = 0.3
	trail.Parent = proj

	local light = Instance.new("PointLight")
	light.Brightness = 10
	light.Range = 10
	light.Color = Color3.fromRGB(80, 200, 80)
	light.Parent = proj

	local conn
	conn = proj.Touched:Connect(function(hit)
		if shooterModel and hit:IsDescendantOf(shooterModel) then return end
		ShooterVFXModule.CreateAcidPool(proj.Position, config)
		if conn then conn:Disconnect() end
		proj:Destroy()
	end)
	Debris:AddItem(proj, 6)
end

return ShooterVFXModule
