-- Boss2VFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/Boss2VFXModule.lua
-- Script Place: ACT 1: Village

local Boss2VFXModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ServerScriptService = game:GetService("ServerScriptService")
local WalkSpeedManager = require(ServerScriptService:WaitForChild("WalkSpeedManager"))

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local Boss2GravityLocalPull = RemoteEvents:WaitForChild("Boss2GravityLocalPull")
local Boss2TimeoutVFXEvent = RemoteEvents:WaitForChild("Boss2TimeoutVFXEvent")

-- Helper function untuk membuat partikel yang lebih realistis
local function createEnergyParticle(parent, color, lifetime, size, transparency, velocity)
	local particle = Instance.new("Part")
	particle.Name = "EnergyParticle"
	particle.Shape = Enum.PartType.Ball
	particle.Size = Vector3.new(size, size, size)
	particle.Anchored = false
	particle.CanCollide = false
	particle.Material = Enum.Material.Neon
	particle.Color = color
	particle.Transparency = transparency
	particle.CastShadow = false
	particle.Parent = parent

	-- Velocity
	if velocity then
		particle.Velocity = velocity
	end

	-- Point light untuk partikel
	local light = Instance.new("PointLight")
	light.Brightness = 12
	light.Range = size * 8
	light.Color = color
	light.Shadows = true
	light.Parent = particle

	-- Tween untuk fade out yang lebih smooth
	local tweenInfo = TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(particle, tweenInfo, {
		Transparency = 1, 
		Size = Vector3.new(size * 0.1, size * 0.1, size * 0.1)
	}):Play()

	TweenService:Create(light, tweenInfo, {
		Brightness = 0,
		Range = size * 2
	}):Play()

	game:GetService("Debris"):AddItem(particle, lifetime + 0.1)
	return particle
end

-- Helper function untuk membuat distortion effect yang lebih realistis
local function createDistortionEffect(parent, size, duration)
	local distortion = Instance.new("Part")
	distortion.Name = "DistortionField"
	distortion.Shape = Enum.PartType.Ball
	distortion.Size = Vector3.new(size, size, size)
	distortion.Anchored = true
	distortion.CanCollide = false
	distortion.Transparency = 1
	distortion.Parent = parent

	-- AtmoSphere effect untuk distorsi udara
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Decay = Color3.new(0.2, 0.3, 0.8)
	atmosphere.Glare = 0
	atmosphere.Haze = 5
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(150, 180, 255)
	atmosphere.Parent = distortion

	game:GetService("Debris"):AddItem(distortion, duration + 0.5)
	return distortion
end

-- Gravity Well yang mengikuti target (VFX yang jauh lebih realistis)
function Boss2VFXModule.CreateGravityWellFollow(targetCharacter, bossModel, duration, radius, slowMultiplier, pullForce)
	if not targetCharacter then return end
	local hrp = targetCharacter:FindFirstChild("HumanoidRootPart") or targetCharacter:FindFirstChild("Head")
	if not hrp then return end

	local wellContainer = Instance.new("Folder")
	wellContainer.Name = "GravityWellFollowContainer"
	wellContainer.Parent = workspace

	-- Part utama dengan material khusus
	local well = Instance.new("Part")
	well.Name = "GravityWellCore"
	well.Shape = Enum.PartType.Ball
	well.Size = Vector3.new((radius or 10)*2, (radius or 10)*2, (radius or 10)*2)
	well.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 8, 0))
	well.Anchored = true
	well.CanCollide = false
	well.Transparency = 0.3
	well.Material = Enum.Material.Glass
	well.Color = Color3.fromRGB(40, 60, 200)
	well.CastShadow = false
	well.Reflectance = 0.2

	-- Lighting utama yang lebih intens
	local coreLight = Instance.new("PointLight")
	coreLight.Brightness = 45
	coreLight.Range = radius * 4
	coreLight.Color = Color3.fromRGB(30, 50, 255)
	coreLight.Shadows = true
	coreLight.Parent = well

	-- Beam effect dari atas ke bawah
	local beam = Instance.new("Part")
	beam.Name = "GravityBeam"
	beam.Shape = Enum.PartType.Cylinder
	beam.Size = Vector3.new(radius * 0.3, radius * 3, radius * 0.3)
	beam.CFrame = well.CFrame * CFrame.new(0, -radius * 1.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	beam.Anchored = true
	beam.CanCollide = false
	beam.Transparency = 0.4
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(70, 90, 255)
	beam.Parent = wellContainer

	-- Beam light
	local beamLight = Instance.new("PointLight")
	beamLight.Brightness = 25
	beamLight.Range = radius * 2
	beamLight.Color = Color3.fromRGB(80, 100, 255)
	beamLight.Parent = beam

	-- Multiple rings dengan animasi berbeda dan material yang lebih baik
	for i = 1, 4 do
		local ring = Instance.new("Part")
		ring.Name = "GravityRing" .. i
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.2, radius * (2 + i * 0.3), radius * (2 + i * 0.3))
		ring.CFrame = well.CFrame * CFrame.Angles(0, 0, math.rad(90))
		ring.Anchored = true
		ring.CanCollide = false
		ring.Transparency = 0.2
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(80 - i*10, 100 - i*10, 255)
		ring.Parent = wellContainer

		-- Ring light
		local ringLight = Instance.new("PointLight")
		ringLight.Brightness = 15 - i * 2
		ringLight.Range = radius * 1.5
		ringLight.Color = ring.Color
		ringLight.Parent = ring

		-- Animasi ring berdenyut dengan timing berbeda
		local tweenInfo = TweenInfo.new(1.2 + i * 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		local tween = TweenService:Create(ring, tweenInfo, {
			Transparency = 0.7, 
			Size = Vector3.new(0.2, radius * (2.8 + i * 0.3), radius * (2.8 + i * 0.3)),
			Color = Color3.fromRGB(100 - i*10, 120 - i*10, 255)
		})
		tween:Play()
	end

	-- Distortion effect yang ditingkatkan
	local distortion = createDistortionEffect(wellContainer, radius * 2.2, duration)

	well.Parent = wellContainer

	-- Partikel kecil yang tertarik ke pusat dengan pola spiral
	local function spawnAttractionParticles()
		for i = 1, 8 do
			local angle = math.random() * math.pi * 2
			local distance = radius * 1.8
			local height = math.random(-radius * 0.5, radius * 0.5)
			local pos = well.Position + Vector3.new(
				math.cos(angle) * distance,
				height,
				math.sin(angle) * distance
			)

			-- Velocity spiral menuju pusat
			local toCenter = (well.Position - pos).Unit
			local tangent = Vector3.new(-toCenter.Z, 0, toCenter.X) -- Vector tangen
			local spiralVel = (toCenter * 15 + tangent * 8)

			local particle = createEnergyParticle(
				wellContainer,
				Color3.fromRGB(60, 80, 255),
				2.0,
				math.random(1, 4),
				0.2,
				spiralVel
			)
			particle.Position = pos
		end
	end

	local t0 = tick()
	local lastTick = tick()
	local PULL_SCALE = 0.5
	local particleSpawnTime = 0

	-- Screen shake effect untuk player target
	local function applyScreenShake(player, intensity)
		local shakeEvent = RemoteEvents:WaitForChild()("ScreenShakeEvent")
		if shakeEvent then
			shakeEvent:FireClient(player, "GravityWell", intensity, duration)
		end
	end

	-- Connection untuk update visual
	local renderConnection
	renderConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not wellContainer.Parent then 
			renderConnection:Disconnect()
			return 
		end

		-- Update posisi mengikuti target
		if hrp and hrp.Parent then
			local targetPos = hrp.Position + Vector3.new(0, 8, 0)
			well.CFrame = CFrame.new(targetPos)
			beam.CFrame = well.CFrame * CFrame.new(0, -radius * 1.5, 0) * CFrame.Angles(0, 0, math.rad(90))
			distortion.CFrame = well.CFrame

			-- Update rings position
			for _, ring in ipairs(wellContainer:GetChildren()) do
				if ring.Name:find("GravityRing") then
					ring.CFrame = well.CFrame * CFrame.Angles(0, 0, math.rad(90))
				end
			end
		end

		-- Spawn partikel secara berkala
		particleSpawnTime = particleSpawnTime + deltaTime
		if particleSpawnTime >= 0.15 then
			spawnAttractionParticles()
			particleSpawnTime = 0
		end

		-- Logic tarik dan perlambat
		local targetHum = targetCharacter:FindFirstChildOfClass("Humanoid")
		local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
		if targetHum and targetRoot and targetHum.Health > 0 then
			local d = (targetRoot.Position - well.Position).Magnitude
			if d <= (radius or 10) then
				local plr = Players:GetPlayerFromCharacter(targetCharacter)
				if plr then
					local currentSpeed = targetHum.WalkSpeed
					-- Calculate the amount to reduce speed by. slowMultiplier is a percentage (e.g., 0.35 means 35% of original speed).
					-- The modifier should be the *change* in speed.
					local speedReduction = currentSpeed * (1 - (slowMultiplier or 0.65)) -- slowMultiplier now represents remaining speed, so we subtract from 1.
					WalkSpeedManager.add_modifier(plr, "gravityWell", -speedReduction)
				end

				-- Apply screen shake
				local plr = Players:GetPlayerFromCharacter(targetCharacter)
				if plr then
					applyScreenShake(plr, 0.3)
				end

				-- Tarik ke ARAH BOSS
				if pullForce and pullForce > 0 and bossModel then
					local bossPos = (bossModel.PrimaryPart and bossModel.PrimaryPart.Position)
						or (bossModel.GetModelCFrame and bossModel:GetModelCFrame().p)
					if bossPos then
						local dir = (bossPos - targetRoot.Position).Unit
						local now = tick()
						local dt = math.clamp(now - lastTick, 1/120, 0.25)
						lastTick = now

						local newVel = targetRoot.AssemblyLinearVelocity + dir * (pullForce * PULL_SCALE * dt)
						targetRoot.AssemblyLinearVelocity = newVel

						local plr = Players:GetPlayerFromCharacter(targetCharacter)
						if plr and Boss2GravityLocalPull then
							Boss2GravityLocalPull:FireClient(plr, bossPos, pullForce)
						end
					end
				end
			end
		end

		-- Cek durasi
		if (tick() - t0) >= (duration or 6) then
			renderConnection:Disconnect()
		end
	end)

	-- Cleanup setelah durasi
	task.spawn(function()
		task.wait(duration or 6)

		if renderConnection then
			renderConnection:Disconnect()
		end

		-- Fade out effect yang lebih smooth dan dramatis
		local fadeTween = TweenService:Create(
			well,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Transparency = 1, Size = well.Size * 1.5}
		)
		fadeTween:Play()

		TweenService:Create(
			coreLight,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Brightness = 0, Range = 1}
		):Play()

		-- Fade beam
		TweenService:Create(
			beam,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Transparency = 1, Size = beam.Size * 0.5}
		):Play()

		-- Fade rings
		for _, ring in ipairs(wellContainer:GetChildren()) do
			if ring:IsA("Part") and ring.Name:find("GravityRing") then
				TweenService:Create(
					ring,
					TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Transparency = 1, Size = ring.Size * 0.8}
				):Play()

				local ringLight = ring:FindFirstChildOfClass("PointLight")
				if ringLight then
					TweenService:Create(
						ringLight,
						TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{Brightness = 0}
					):Play()
				end
			end
		end

		task.wait(1.5)
		if wellContainer and wellContainer.Parent then
			wellContainer:Destroy()
		end

		-- Restore walk speed
		local plr = targetCharacter and Players:GetPlayerFromCharacter(targetCharacter)
		if plr then
			WalkSpeedManager.remove_modifier(plr, "gravityWell")
		end
	end)

	return wellContainer
end

-- Gravity Well statis: tarik SEMUA player di radius ke titik well
function Boss2VFXModule.CreateGravityWellStatic(centerPos, duration, radius, pullForce)
	local wellContainer = Instance.new("Folder")
	wellContainer.Name = "GravityWellStaticContainer"
	wellContainer.Parent = workspace

	-- Core part dengan material yang lebih baik
	local well = Instance.new("Part")
	well.Name = "GravityWellCore"
	well.Shape = Enum.PartType.Ball
	well.Size = Vector3.new((radius or 15)*2, (radius or 15)*2, (radius or 15)*2)
	well.CFrame = CFrame.new((centerPos or Vector3.new()) + Vector3.new(0, 12, 0))
	well.Anchored = true
	well.CanCollide = false
	well.Transparency = 0.2
	well.Material = Enum.Material.Glass
	well.Color = Color3.fromRGB(40, 60, 200)
	well.CastShadow = false
	well.Reflectance = 0.3

	-- Core lighting yang lebih intens
	local coreLight = Instance.new("PointLight")
	coreLight.Brightness = 55
	coreLight.Range = radius * 5
	coreLight.Color = Color3.fromRGB(30, 50, 255)
	coreLight.Shadows = true
	coreLight.Parent = well

	-- Beam effect vertikal
	local centerBeam = Instance.new("Part")
	centerBeam.Name = "CenterBeam"
	centerBeam.Shape = Enum.PartType.Cylinder
	centerBeam.Size = Vector3.new(radius * 0.4, radius * 4, radius * 0.4)
	centerBeam.CFrame = well.CFrame * CFrame.new(0, -radius * 2, 0) * CFrame.Angles(0, 0, math.rad(90))
	centerBeam.Anchored = true
	centerBeam.CanCollide = false
	centerBeam.Transparency = 0.3
	centerBeam.Material = Enum.Material.Neon
	centerBeam.Color = Color3.fromRGB(60, 80, 255)
	centerBeam.Parent = wellContainer

	local beamLight = Instance.new("PointLight")
	beamLight.Brightness = 30
	beamLight.Range = radius * 3
	beamLight.Color = Color3.fromRGB(70, 90, 255)
	beamLight.Parent = centerBeam

	-- Multiple rings dengan variasi dan animasi yang lebih kompleks
	for i = 1, 5 do
		local ring = Instance.new("Part")
		ring.Name = "StaticGravityRing" .. i
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.3, radius * (2 + i * 0.4), radius * (2 + i * 0.4))
		ring.CFrame = well.CFrame * CFrame.Angles(0, 0, math.rad(90))
		ring.Anchored = true
		ring.CanCollide = false
		ring.Transparency = 0.15
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(70 - i*8, 90 - i*8, 255)
		ring.Parent = wellContainer

		local ringLight = Instance.new("PointLight")
		ringLight.Brightness = 20 - i * 3
		ringLight.Range = radius * 2
		ringLight.Color = ring.Color
		ringLight.Parent = ring

		local delay = (i-1) * 0.3
		task.delay(delay, function()
			local tweenInfo = TweenInfo.new(2.8 - i * 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			local tween = TweenService:Create(ring, tweenInfo, {
				Transparency = 0.6, 
				Size = Vector3.new(0.3, radius * (2.8 + i * 0.4), radius * (2.8 + i * 0.4)),
				Color = Color3.fromRGB(90 - i*8, 110 - i*8, 255)
			})
			tween:Play()
		end)
	end

	-- Distortion effect yang lebih besar
	local distortion = createDistortionEffect(wellContainer, radius * 2.5, duration)

	well.Parent = wellContainer

	local PULL_SCALE = 0.5
	local lastTick = tick()
	local t0 = tick()
	local particleTime = 0

	-- Screen shake untuk semua player dalam radius
	local function applyScreenShakeToPlayers()
		for _, plr in ipairs(Players:GetPlayers()) do
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local d = (hrp.Position - well.Position).Magnitude
				if d <= radius * 1.5 then
					local intensity = 0.2 * (1 - d / (radius * 1.5))
					local shakeEvent = RemoteEvents:WaitForChild("ScreenShakeEvent")
					if shakeEvent then
						shakeEvent:FireClient(plr, "GravityWellStatic", intensity, 0.1)
					end
				end
			end
		end
	end

	-- Render loop untuk efek visual dan physics
	local renderConnection
	renderConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not wellContainer.Parent then 
			renderConnection:Disconnect()
			return 
		end

		-- Update partikel vortex
		particleTime = particleTime + deltaTime
		if particleTime >= 0.12 then
			applyScreenShakeToPlayers()
			particleTime = 0
		end

		-- Physics pull untuk semua player
		local wellPos = well.Position
		for _, plr in ipairs(Players:GetPlayers()) do
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local d = (hrp.Position - wellPos).Magnitude
				if d <= (radius or 15) then
					local now = tick()
					local dt = math.clamp(now - lastTick, 1/120, 0.25)
					lastTick = now

					local dir = (wellPos - hrp.Position).Unit
					hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + dir * ((pullForce or 0) * PULL_SCALE * dt)

					local re = ReplicatedStorage.RemoteEvents:FindFirstChild("Boss2GravityLocalPull")
					if re then
						re:FireClient(plr, wellPos, pullForce or 0)
					end
				end
			end
		end

		-- Cek durasi
		if (tick() - t0) >= (duration or 6) then
			renderConnection:Disconnect()
		end
	end)

	-- Cleanup sequence yang lebih dramatis
	task.spawn(function()
		task.wait(duration or 6)

		if renderConnection then
			renderConnection:Disconnect()
		end

		-- Dramatic implosion sebelum fade out
		local implodeTween = TweenService:Create(
			well,
			TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{Size = well.Size * 0.3, Transparency = 0.8}
		)
		implodeTween:Play()

		TweenService:Create(
			coreLight,
			TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{Brightness = 80, Range = radius}
		):Play()

		task.wait(0.8)

		local explosionTween = TweenService:Create(
			well,
			TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = well.Size * 4, Transparency = 1}
		)
		explosionTween:Play()

		TweenService:Create(
			coreLight,
			TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Brightness = 0, Range = 1}
		):Play()

		-- Fade semua rings dengan efek cascade
		for i, ring in ipairs(wellContainer:GetChildren()) do
			if ring:IsA("Part") and ring.Name:find("StaticGravityRing") then
				task.delay(i * 0.1, function()
					TweenService:Create(
						ring,
						TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{Transparency = 1, Size = ring.Size * 1.2}
					):Play()

					local ringLight = ring:FindFirstChildOfClass("PointLight")
					if ringLight then
						TweenService:Create(
							ringLight,
							TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{Brightness = 0}
						):Play()
					end
				end)
			end
		end

		-- Fade beam
		TweenService:Create(
			centerBeam,
			TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Transparency = 1, Size = centerBeam.Size * 0.3}
		):Play()

		task.wait(1.5)
		if wellContainer and wellContainer.Parent then
			wellContainer:Destroy()
		end
	end)

	return wellContainer
end

-- === Gravity Slam VFX (Ditingkatkan) ===
function Boss2VFXModule.ShowSlamTelegraph(centerPos, radius, telegraphTime)
	local Debris = game:GetService("Debris")

	local telegraphContainer = Instance.new("Folder")
	telegraphContainer.Name = "SlamTelegraphContainer"
	telegraphContainer.Parent = workspace

	-- Ground distortion effect dengan particles
	local groundEffect = Instance.new("Part")
	groundEffect.Name = "GroundDistortion"
	groundEffect.Anchored = true
	groundEffect.CanCollide = false
	groundEffect.Material = Enum.Material.Slate
	groundEffect.Color = Color3.fromRGB(60, 30, 15)
	groundEffect.Transparency = 0.6
	groundEffect.Size = Vector3.new(radius*2.2, 0.1, radius*2.2)
	groundEffect.CFrame = CFrame.new(centerPos + Vector3.new(0, 0.05, 0))

	local groundMesh = Instance.new("CylinderMesh")
	groundMesh.Parent = groundEffect

	-- Ring utama dengan efek lebih kompleks
	local mainRing = Instance.new("Part")
	mainRing.Name = "SlamTelegraphMain"
	mainRing.Anchored = true
	mainRing.CanCollide = false
	mainRing.Material = Enum.Material.Neon
	mainRing.Color = Color3.fromRGB(255, 80, 0)
	mainRing.Transparency = 0.05
	mainRing.Size = Vector3.new((radius*2), 0.4, (radius*2))
	mainRing.CFrame = CFrame.new(centerPos + Vector3.new(0, 0.2, 0))

	local mainMesh = Instance.new("CylinderMesh")
	mainMesh.Parent = mainRing

	-- Lighting intens
	local mainLight = Instance.new("PointLight")
	mainLight.Brightness = 25
	mainLight.Range = radius * 3
	mainLight.Color = Color3.fromRGB(255, 40, 0)
	mainLight.Shadows = true
	mainLight.Parent = mainRing

	-- Ring sekunder
	local secondaryRing = Instance.new("Part")
	secondaryRing.Name = "SlamTelegraphSecondary"
	secondaryRing.Anchored = true
	secondaryRing.CanCollide = false
	secondaryRing.Material = Enum.Material.Neon
	secondaryRing.Color = Color3.fromRGB(255, 160, 60)
	secondaryRing.Transparency = 0.15
	secondaryRing.Size = Vector3.new((radius*2.4), 0.3, (radius*2.4))
	secondaryRing.CFrame = CFrame.new(centerPos + Vector3.new(0, 0.15, 0))

	local secondaryMesh = Instance.new("CylinderMesh")
	secondaryMesh.Parent = secondaryRing

	groundEffect.Parent = telegraphContainer
	mainRing.Parent = telegraphContainer
	secondaryRing.Parent = telegraphContainer

	-- Animasi berdenyut multi-layer
	local mainTween = TweenService:Create(mainRing, TweenInfo.new(telegraphTime/2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Transparency = 0.5,
		Size = Vector3.new(radius*2.3, 0.4, radius*2.3),
		Color = Color3.fromRGB(255, 120, 0)
	})
	mainTween:Play()

	local secondaryTween = TweenService:Create(secondaryRing, TweenInfo.new(telegraphTime/2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {
		Transparency = 0.6,
		Size = Vector3.new(radius*2.7, 0.3, radius*2.7),
		Color = Color3.fromRGB(255, 200, 100)
	})
	secondaryTween:Play()

	-- Ground effect pulse
	local groundTween = TweenService:Create(groundEffect, TweenInfo.new(telegraphTime/3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Transparency = 0.8,
		Color = Color3.fromRGB(100, 50, 25)
	})
	groundTween:Play()

	Debris:AddItem(telegraphContainer, telegraphTime + 1)
	return telegraphContainer
end

function Boss2VFXModule.PlaySlamExplosion(centerPos, radius)
	local Debris = game:GetService("Debris")

	local shockContainer = Instance.new("Folder")
	shockContainer.Name = "SlamShockwaveContainer"
	shockContainer.Parent = workspace

	-- Shockwave utama dengan partikel
	local mainShock = Instance.new("Part")
	mainShock.Name = "SlamShockwaveMain"
	mainShock.Anchored = true
	mainShock.CanCollide = false
	mainShock.Material = Enum.Material.Neon
	mainShock.Color = Color3.fromRGB(255, 160, 40)
	mainShock.Transparency = 0.02
	mainShock.Size = Vector3.new(2, 0.5, 2)
	mainShock.CFrame = CFrame.new(centerPos + Vector3.new(0, 0.2, 0))

	local mainMesh = Instance.new("CylinderMesh")
	mainMesh.Parent = mainShock

	-- Lighting ledakan
	local explosionLight = Instance.new("PointLight")
	explosionLight.Brightness = 40
	explosionLight.Range = radius * 6
	explosionLight.Color = Color3.fromRGB(255, 80, 10)
	explosionLight.Shadows = true
	explosionLight.Parent = mainShock

	-- Shockwave sekunder
	local secondaryShock = Instance.new("Part")
	secondaryShock.Name = "SlamShockwaveSecondary"
	secondaryShock.Anchored = true
	secondaryShock.CanCollide = false
	secondaryShock.Material = Enum.Material.Neon
	secondaryShock.Color = Color3.fromRGB(255, 120, 20)
	secondaryShock.Transparency = 0.08
	secondaryShock.Size = Vector3.new(1, 0.4, 1)
	secondaryShock.CFrame = CFrame.new(centerPos + Vector3.new(0, 0.15, 0))

	local secondaryMesh = Instance.new("CylinderMesh")
	secondaryMesh.Parent = secondaryShock

	mainShock.Parent = shockContainer
	secondaryShock.Parent = shockContainer

	-- Tween shockwave utama
	TweenService:Create(
		mainShock,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(radius*3.5, 0.5, radius*3.5), Transparency = 1}
	):Play()

	-- Tween shockwave sekunder dengan delay
	task.wait(0.12)
	TweenService:Create(
		secondaryShock,
		TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(radius*3.8, 0.4, radius*3.8), Transparency = 1}
	):Play()

	-- Ground crack effect yang lebih detail
	local crack = Instance.new("Part")
	crack.Name = "SlamGroundCrack"
	crack.Anchored = true
	crack.CanCollide = false
	crack.Material = Enum.Material.Slate
	crack.Color = Color3.fromRGB(20, 10, 5)
	crack.Transparency = 0.05
	crack.Size = Vector3.new(radius*2.2, 0.3, radius*2.2)
	crack.CFrame = CFrame.new(centerPos + Vector3.new(0, 0.08, 0))

	local crackMesh = Instance.new("CylinderMesh")
	crackMesh.Parent = crack

	crack.Parent = workspace

	-- Tween untuk crack
	TweenService:Create(
		crack,
		TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Transparency = 1, Size = Vector3.new(radius*2.6, 0.3, radius*2.6)}
	):Play()

	-- Debris management
	Debris:AddItem(shockContainer, 2)
	Debris:AddItem(crack, 3)
end

-- === Special Timeout VFX (Gravity Collapse) ===
function Boss2VFXModule.PlayTimeoutVFX(bossPosition)
	-- Kirim event ke semua client untuk memulai VFX timeout
	Boss2TimeoutVFXEvent:FireAllClients(bossPosition)

	-- Server-side VFX yang sangat ditingkatkan
	local radius = 80

	-- Global light effect
	local globalLight = Instance.new("PointLight")
	globalLight.Brightness = 0.5
	globalLight.Range = 500
	globalLight.Color = Color3.fromRGB(50, 70, 255)
	globalLight.Shadows = true
	globalLight.Parent = workspace

	-- 1. Global Telegraph (3 detik)
	local function createRuneRing()
		local ringContainer = Instance.new("Folder")
		ringContainer.Name = "TimeoutRuneContainer"
		ringContainer.Parent = workspace

		-- Ring utama dengan partikel
		local mainRing = Instance.new("Part")
		mainRing.Name = "TimeoutRuneRingMain"
		mainRing.Anchored = true
		mainRing.CanCollide = false
		mainRing.Material = Enum.Material.Neon
		mainRing.Color = Color3.fromRGB(50, 70, 255)
		mainRing.Transparency = 0.1
		mainRing.Size = Vector3.new(radius*2, 1, radius*2)
		mainRing.CFrame = CFrame.new(bossPosition + Vector3.new(0, 0.15, 0))

		local mainMesh = Instance.new("CylinderMesh")
		mainMesh.Parent = mainRing

		-- Lighting dramatis
		local ringLight = Instance.new("PointLight")
		ringLight.Brightness = 50
		ringLight.Range = radius * 4
		ringLight.Color = Color3.fromRGB(30, 50, 255)
		ringLight.Shadows = true
		ringLight.Parent = mainRing

		-- Ring sekunder
		local secondaryRing = Instance.new("Part")
		secondaryRing.Name = "TimeoutRuneRingSecondary"
		secondaryRing.Anchored = true
		secondaryRing.CanCollide = false
		secondaryRing.Material = Enum.Material.Neon
		secondaryRing.Color = Color3.fromRGB(70, 90, 255)
		secondaryRing.Transparency = 0.25
		secondaryRing.Size = Vector3.new(radius*2.3, 0.8, radius*2.3)
		secondaryRing.CFrame = CFrame.new(bossPosition + Vector3.new(0, 0.1, 0))

		local secondaryMesh = Instance.new("CylinderMesh")
		secondaryMesh.Parent = secondaryRing

		mainRing.Parent = ringContainer
		secondaryRing.Parent = ringContainer

		-- Animasi berdenyut multilayer
		TweenService:Create(
			mainRing,
			TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Transparency = 0.4, Size = Vector3.new(radius*2.4, 1, radius*2.4)}
		):Play()

		TweenService:Create(
			secondaryRing,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
			{Transparency = 0.5, Size = Vector3.new(radius*2.6, 0.8, radius*2.6)}
		):Play()

		-- Increase global light
		TweenService:Create(
			globalLight,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Brightness = 1.2}
		):Play()

		return ringContainer
	end

	-- 2. Charge-Up (2 detik)
	local function createChargeBeam()
		local beamContainer = Instance.new("Folder")
		beamContainer.Name = "TimeoutBeamContainer"
		beamContainer.Parent = workspace

		-- Beam utama dengan partikel
		local mainBeam = Instance.new("Part")
		mainBeam.Name = "TimeoutChargeBeamMain"
		mainBeam.Anchored = true
		mainBeam.CanCollide = false
		mainBeam.Material = Enum.Material.Neon
		mainBeam.Color = Color3.fromRGB(0, 80, 255)
		mainBeam.Transparency = 0.05
		mainBeam.Size = Vector3.new(14, 160, 14)
		mainBeam.CFrame = CFrame.new(bossPosition) * CFrame.new(0, 80, 0)

		local mainMesh = Instance.new("CylinderMesh")
		mainMesh.Parent = mainBeam

		-- Lighting beam intens
		local beamLight = Instance.new("PointLight")
		beamLight.Brightness = 60
		beamLight.Range = 150
		beamLight.Color = Color3.fromRGB(0, 140, 255)
		beamLight.Shadows = true
		beamLight.Parent = mainBeam

		-- Beam sekunder
		local secondaryBeam = Instance.new("Part")
		secondaryBeam.Name = "TimeoutChargeBeamSecondary"
		secondaryBeam.Anchored = true
		secondaryBeam.CanCollide = false
		secondaryBeam.Material = Enum.Material.Neon
		secondaryBeam.Color = Color3.fromRGB(0, 160, 255)
		secondaryBeam.Transparency = 0.15
		secondaryBeam.Size = Vector3.new(10, 150, 10)
		secondaryBeam.CFrame = CFrame.new(bossPosition) * CFrame.new(0, 75, 0)

		local secondaryMesh = Instance.new("CylinderMesh")
		secondaryMesh.Parent = secondaryBeam

		mainBeam.Parent = beamContainer
		secondaryBeam.Parent = beamContainer

		-- Energy orbs melingkar dengan particle effects
		for i = 1, 20 do
			local angle = (i/20) * math.pi * 2
			local orb = Instance.new("Part")
			orb.Name = "TimeoutEnergyOrb"
			orb.Anchored = true
			orb.CanCollide = false
			orb.Material = Enum.Material.Neon
			orb.Color = Color3.fromRGB(0, 140, 255)
			orb.Transparency = 0.05
			orb.Size = Vector3.new(5, 5, 5)

			local distance = radius/1.1 + math.sin(i * 0.8) * 12
			orb.CFrame = CFrame.new(bossPosition) * CFrame.Angles(0, angle, 0) * CFrame.new(distance, 15, 0)

			local orbLight = Instance.new("PointLight")
			orbLight.Brightness = 30
			orbLight.Range = 45
			orbLight.Color = Color3.fromRGB(0, 180, 255)
			orbLight.Parent = orb

			orb.Parent = beamContainer

			-- Animasi orb berdenyut
			TweenService:Create(
				orb,
				TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Size = Vector3.new(7, 7, 7), Transparency = 0.3}
			):Play()
		end

		-- Intensify global light
		TweenService:Create(
			globalLight,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Brightness = 2.0, Color = Color3.fromRGB(0, 100, 255)}
		):Play()

		return beamContainer
	end

	-- 3. Micro-Implode (0.2 detik)
	local function createImplodeRing()
		local implodeContainer = Instance.new("Folder")
		implodeContainer.Name = "TimeoutImplodeContainer"
		implodeContainer.Parent = workspace

		-- Implode utama dengan partikel
		local mainImplode = Instance.new("Part")
		mainImplode.Name = "TimeoutImplodeRingMain"
		mainImplode.Anchored = true
		mainImplode.CanCollide = false
		mainImplode.Material = Enum.Material.Neon
		mainImplode.Color = Color3.fromRGB(255, 20, 20)
		mainImplode.Transparency = 0.02
		mainImplode.Size = Vector3.new(radius*2, 1, radius*2)
		mainImplode.CFrame = CFrame.new(bossPosition + Vector3.new(0, 0.15, 0))

		local mainMesh = Instance.new("CylinderMesh")
		mainMesh.Parent = mainImplode

		-- Lighting implode sangat intens
		local implodeLight = Instance.new("PointLight")
		implodeLight.Brightness = 80
		implodeLight.Range = radius * 3
		implodeLight.Color = Color3.fromRGB(255, 30, 30)
		implodeLight.Shadows = true
		implodeLight.Parent = mainImplode

		mainImplode.Parent = implodeContainer

		-- Tween untuk efek menyusut dramatis
		TweenService:Create(
			mainImplode,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{Size = Vector3.new(2, 1, 2), Transparency = 0.9}
		):Play()

		TweenService:Create(
			implodeLight,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{Brightness = 120, Range = radius * 0.5}
		):Play()

		-- Flash global light
		TweenService:Create(
			globalLight,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Brightness = 3.0, Color = Color3.fromRGB(255, 50, 50)}
		):Play()

		return implodeContainer
	end

	-- 4. Detonasi Gravitasi
	local function createDetonation()
		local detonationContainer = Instance.new("Folder")
		detonationContainer.Name = "TimeoutDetonationContainer"
		detonationContainer.Parent = workspace

		-- Multiple ring shockwaves dengan particle effects
		for i = 1, 8 do
			task.wait(0.05) -- Staggered rings

			local ring = Instance.new("Part")
			ring.Name = "TimeoutDetonationRing" .. i
			ring.Anchored = true
			ring.CanCollide = false
			ring.Material = Enum.Material.Neon
			ring.Color = Color3.fromRGB(255, 80 - i*8, 80 - i*8)
			ring.Transparency = 0.02
			ring.Size = Vector3.new(3, 0.8, 3)
			ring.CFrame = CFrame.new(bossPosition + Vector3.new(0, 0.15, 0))

			local mesh = Instance.new("CylinderMesh")
			mesh.Parent = ring

			-- Lighting untuk setiap ring
			local ringLight = Instance.new("PointLight")
			ringLight.Brightness = 35 - i*3
			ringLight.Range = radius * (1.3 + i*0.4)
			ringLight.Color = Color3.fromRGB(255, 100 - i*10, 80 - i*8)
			ringLight.Shadows = true
			ringLight.Parent = ring

			ring.Parent = detonationContainer

			TweenService:Create(
				ring,
				TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = Vector3.new(radius*4 + i*20, 0.8, radius*4 + i*20), Transparency = 1}
			):Play()

			game:GetService("Debris"):AddItem(ring, 1.5)
		end

		-- Rock shards dengan physics yang realistis dan particle effects
		for i = 1, 100 do
			task.wait()
			local rock = Instance.new("Part")
			rock.Name = "TimeoutRockShard"
			rock.Anchored = false
			rock.CanCollide = true
			rock.Material = Enum.Material.Slate
			rock.Color = Color3.fromRGB(50, 35, 20)
			rock.Size = Vector3.new(math.random(2, 8), math.random(2, 8), math.random(2, 8))
			rock.CFrame = CFrame.new(bossPosition) * CFrame.new(
				math.random(-radius/1.05, radius/1.05),
				math.random(15, 40),
				math.random(-radius/1.05, radius/1.05)
			)

			-- Terapkan gaya ledakan yang realistis
			rock.Velocity = Vector3.new(
				math.random(-120, 120),
				math.random(80, 150),
				math.random(-120, 120)
			)
			rock.RotVelocity = Vector3.new(
				math.random(-20, 20),
				math.random(-20, 20),
				math.random(-20, 20)
			)

			rock.Parent = workspace
			game:GetService("Debris"):AddItem(rock, 10)
		end

		-- PointLight merah yang sangat terang
		local explosionLight = Instance.new("PointLight")
		explosionLight.Name = "TimeoutExplosionLight"
		explosionLight.Brightness = 90
		explosionLight.Range = 250
		explosionLight.Color = Color3.fromRGB(255, 20, 20)
		explosionLight.Shadows = true
		explosionLight.Parent = workspace

		-- Flash effect dramatis
		task.spawn(function()
			for i = 1, 8 do
				explosionLight.Brightness = 90 - i*10
				task.wait(0.05)
			end
		end)

		-- Fade out light
		TweenService:Create(
			explosionLight,
			TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Brightness = 0}
		):Play()

		-- Fade global light
		TweenService:Create(
			globalLight,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Brightness = 0}
		):Play()

		game:GetService("Debris"):AddItem(explosionLight, 3.5)
		game:GetService("Debris"):AddItem(globalLight, 3.5)
		return detonationContainer
	end

	-- 5. Aftermath
	local function createAftermath()
		local aftermathContainer = Instance.new("Folder")
		aftermathContainer.Name = "TimeoutAftermathContainer"
		aftermathContainer.Parent = workspace

		-- Ground fog effect
		local fog = Instance.new("Part")
		fog.Name = "TimeoutAftermathFog"
		fog.Anchored = true
		fog.CanCollide = false
		fog.Material = Enum.Material.SmoothPlastic
		fog.Color = Color3.fromRGB(50, 50, 50)
		fog.Transparency = 0.4
		fog.Size = Vector3.new(radius*2.2, 15, radius*2.2)
		fog.CFrame = CFrame.new(bossPosition + Vector3.new(0, 7.5, 0))

		local mesh = Instance.new("BlockMesh")
		mesh.Parent = fog

		fog.Parent = aftermathContainer

		-- Residual energy field
		local energyField = Instance.new("Part")
		energyField.Name = "ResidualEnergyField"
		energyField.Anchored = true
		energyField.CanCollide = false
		energyField.Material = Enum.Material.Neon
		energyField.Color = Color3.fromRGB(30, 50, 100)
		energyField.Transparency = 0.7
		energyField.Size = Vector3.new(radius*1.5, 0.5, radius*1.5)
		energyField.CFrame = CFrame.new(bossPosition + Vector3.new(0, 0.2, 0))

		local energyMesh = Instance.new("CylinderMesh")
		energyMesh.Parent = energyField

		local energyLight = Instance.new("PointLight")
		energyLight.Brightness = 20
		energyLight.Range = radius
		energyLight.Color = Color3.fromRGB(40, 60, 120)
		energyLight.Parent = energyField

		energyField.Parent = aftermathContainer

		return aftermathContainer
	end

	-- Jalankan sequence VFX
	local runeRing = createRuneRing()
	task.wait(3)

	local chargeBeam = createChargeBeam()
	task.wait(2)

	local implodeRing = createImplodeRing()
	task.wait(0.2)

	local detonation = createDetonation()
	task.wait(0.5)

	local aftermath = createAftermath()
	task.wait(3)

	-- Cleanup dengan fade out
	local cleanupParts = {runeRing, chargeBeam, implodeRing, detonation, aftermath}
	for _, part in ipairs(cleanupParts) do
		if part then
			if part:IsA("Folder") then
				for _, child in ipairs(part:GetChildren()) do
					if child:IsA("Part") then
						TweenService:Create(
							child,
							TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{Transparency = 1}
						):Play()

						local childLight = child:FindFirstChildOfClass("PointLight")
						if childLight then
							TweenService:Create(
								childLight,
								TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
								{Brightness = 0}
							):Play()
						end
					end
				end
			end
			task.delay(1.6, function() 
				if part and part.Parent then 
					part:Destroy() 
				end 
			end)
		end
	end
end

-- === DR Billboard (di atas kepala Boss2) ===
function Boss2VFXModule.ShowDamageReductionUI(bossModel: Model, drPct: number, duration: number)
	drPct = math.clamp(drPct or 0, 0, 0.95)
	duration = math.max(0, math.floor(duration or 0))

	local adorn = bossModel:FindFirstChild("Head")
		or bossModel:FindFirstChild("HumanoidRootPart")
		or (bossModel.PrimaryPart)

	if not adorn then return end

	-- Hapus UI lama jika ada
	local existing = bossModel:FindFirstChild("Boss2DR_UI")
	if existing then existing:Destroy() end

	local gui = Instance.new("BillboardGui")
	gui.Name = "Boss2DR_UI"
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Size = UDim2.new(0, 260, 0, 70)
	gui.StudsOffsetWorldSpace = Vector3.new(0, (adorn.Size and adorn.Size.Y or 4) + 4.5, 0)
	gui.Adornee = adorn
	gui.Parent = bossModel

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(20,20,20)
	bg.BackgroundTransparency = 0.25
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(255,140,0)
	stroke.Parent = bg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = bg

	-- Glow effect
	local glow = Instance.new("ImageLabel")
	glow.Size = UDim2.new(1.1, 0, 1.1, 0)
	glow.Position = UDim2.new(-0.05, 0, -0.05, 0)
	glow.BackgroundTransparency = 1
	glow.Image = "rbxasset://textures/ui/Tooltip/TooltipBackground.png"
	glow.ImageColor3 = Color3.fromRGB(255, 140, 0)
	glow.ScaleType = Enum.ScaleType.Slice
	glow.SliceCenter = Rect.new(10, 10, 18, 18)
	glow.ImageTransparency = 0.8
	glow.Parent = bg

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -10, 0.6, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 220, 160)
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.fromRGB(40, 40, 40)
	label.Text = ("Damage Reduction %d%%"):format(math.floor(drPct * 100))
	label.Parent = bg

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -10, 0.25, 0)
	barBg.Position = UDim2.new(0, 5, 0.65, 0)
	barBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
	barBg.BorderSizePixel = 0
	barBg.Parent = bg

	local barBgCorner = Instance.new("UICorner")
	barBgCorner.CornerRadius = UDim.new(0, 8)
	barBgCorner.Parent = barBg

	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = Color3.fromRGB(255,140,0)
	bar.BorderSizePixel = 0
	bar.Size = UDim2.new(1, 0, 1, 0)
	bar.Parent = barBg

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 8)
	barCorner.Parent = bar

	-- Bar glow effect
	local barGlow = Instance.new("ImageLabel")
	barGlow.Size = UDim2.new(1.05, 0, 1.1, 0)
	barGlow.Position = UDim2.new(-0.025, 0, -0.05, 0)
	barGlow.BackgroundTransparency = 1
	barGlow.Image = "rbxasset://textures/ui/Tooltip/TooltipBackground.png"
	barGlow.ImageColor3 = Color3.fromRGB(255, 160, 0)
	barGlow.ScaleType = Enum.ScaleType.Slice
	barGlow.SliceCenter = Rect.new(10, 10, 18, 18)
	barGlow.ImageTransparency = 0.7
	barGlow.Parent = bar

	-- Update progress & hitung mundur
	task.spawn(function()
		if duration <= 0 then
			task.wait(0.1)
			if gui and gui.Parent then gui:Destroy() end
			return
		end
		local t0 = tick()
		while gui and gui.Parent and bossModel and bossModel.Parent do
			local elapsed = tick() - t0
			local left = math.max(0, duration - math.floor(elapsed))
			local pct = 1 - (elapsed / duration)
			bar.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
			if elapsed >= duration then break end
			task.wait(0.1)
		end
		if gui and gui.Parent then gui:Destroy() end
	end)

	-- Bersih otomatis jika boss mati
	local hum = bossModel:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Died:Connect(function()
			if gui and gui.Parent then gui:Destroy() end
		end)
	end

	return gui
end

-- === Mechanic Countdown (di atas kepala Boss2) ===
function Boss2VFXModule.ShowMechanicCountdownUI(bossModel: Model, titleText: string, duration: number)
	duration = math.max(0, math.floor(duration or 0))

	local adorn = bossModel:FindFirstChild("Head")
		or bossModel:FindFirstChild("HumanoidRootPart")
		or (bossModel.PrimaryPart)
	if not adorn then return end

	-- Hapus UI lama kalau ada
	local existing = bossModel:FindFirstChild("Boss2Mechanic_UI")
	if existing then existing:Destroy() end

	local gui = Instance.new("BillboardGui")
	gui.Name = "Boss2Mechanic_UI"
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Size = UDim2.new(0, 260, 0, 70)
	gui.StudsOffsetWorldSpace = Vector3.new(0, (adorn.Size and adorn.Size.Y or 4) + 4.5, 0)
	gui.Adornee = adorn
	gui.Parent = bossModel

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(20,20,20)
	bg.BackgroundTransparency = 0.25
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(255,140,0)
	stroke.Parent = bg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = bg

	-- Glow effect
	local glow = Instance.new("ImageLabel")
	glow.Size = UDim2.new(1.1, 0, 1.1, 0)
	glow.Position = UDim2.new(-0.05, 0, -0.05, 0)
	glow.BackgroundTransparency = 1
	glow.Image = "rbxasset://textures/ui/Tooltip/TooltipBackground.png"
	glow.ImageColor3 = Color3.fromRGB(255, 140, 0)
	glow.ScaleType = Enum.ScaleType.Slice
	glow.SliceCenter = Rect.new(10, 10, 18, 18)
	glow.ImageTransparency = 0.8
	glow.Parent = bg

	-- Judul di atas bar
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -10, 0.6, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 220, 160)
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.fromRGB(40, 40, 40)
	label.Text = (titleText and titleText ~= "" and titleText) or "Destroy pad"
	label.Parent = bg

	-- Bar background
	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -10, 0.25, 0)
	barBg.Position = UDim2.new(0, 5, 0.65, 0)
	barBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
	barBg.BorderSizePixel = 0
	barBg.Parent = bg

	local barBgCorner = Instance.new("UICorner")
	barBgCorner.CornerRadius = UDim.new(0, 8)
	barBgCorner.Parent = barBg

	-- Fill bar (menyusut sesuai waktu)
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = Color3.fromRGB(255,140,0)
	bar.BorderSizePixel = 0
	bar.Size = UDim2.new(1, 0, 1, 0)
	bar.Parent = barBg

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 8)
	barCorner.Parent = bar

	-- Bar glow effect
	local barGlow = Instance.new("ImageLabel")
	barGlow.Size = UDim2.new(1.05, 0, 1.1, 0)
	barGlow.Position = UDim2.new(-0.025, 0, -0.05, 0)
	barGlow.BackgroundTransparency = 1
	barGlow.Image = "rbxasset://textures/ui/Tooltip/TooltipBackground.png"
	barGlow.ImageColor3 = Color3.fromRGB(255, 160, 0)
	barGlow.ScaleType = Enum.ScaleType.Slice
	barGlow.SliceCenter = Rect.new(10, 10, 18, 18)
	barGlow.ImageTransparency = 0.7
	barGlow.Parent = bar

	-- Hitung mundur & auto-destroy
	task.spawn(function()
		if duration <= 0 then
			task.wait(0.1)
			if gui and gui.Parent then gui:Destroy() end
			return
		end
		local t0 = tick()
		while gui and gui.Parent and bossModel and bossModel.Parent do
			local elapsed = tick() - t0
			local pct = 1 - (elapsed / duration)
			bar.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
			if elapsed >= duration then break end
			task.wait(0.1)
		end
		if gui and gui.Parent then gui:Destroy() end
	end)

	-- Bersih otomatis kalau boss mati
	local hum = bossModel:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Died:Connect(function()
			if gui and gui.Parent then gui:Destroy() end
		end)
	end

	return gui
end

function Boss2VFXModule.SpawnCoopPads(center, required, duration, limitPerPlayer, destroyedBy, okPlayers)
	local Debris = game:GetService("Debris")
	local pads = {}

	-- util: proyeksikan posisi ke tanah (mengikuti pola Gravity Slam)
	local function groundAt(pos: Vector3)
		local rp = RaycastParams.new()
		rp.FilterDescendantsInstances = {workspace.Terrain}
		rp.FilterType = Enum.RaycastFilterType.Include
		local hit = workspace:Raycast(pos + Vector3.new(0, 100, 0), Vector3.new(0, -1000, 0), rp)
		return hit and Vector3.new(pos.X, hit.Position.Y, pos.Z) or pos
	end
	-- pastikan pusat referensi sudah di tanah
	center = groundAt(center)

	-- spawn 4 pad interaksi di sekitar boss
	for i=1,required do
		local angle = (i/required)*math.pi*2
		local pad = Instance.new("Part")
		pad.Name = "CoopPad"..i
		pad.Size = Vector3.new(5, 0.6, 5)
		pad.Anchored = true
		pad.CanCollide = false
		pad.Material = Enum.Material.Neon
		pad.Color = Color3.fromRGB(255, 180, 40)
		pad.Reflectance = 0.2
		-- tempatkan pad di ring sekitar boss, diproyeksikan ke tanah
		local offset = Vector3.new(math.cos(angle)*12, 0, math.sin(angle)*12)
		local padPos = groundAt(center + offset) + Vector3.new(0, pad.Size.Y*0.5, 0) -- naikkan setengah tinggi pad agar duduk di permukaan
		pad.CFrame = CFrame.new(padPos)
		pad.Parent = workspace

		-- Lighting untuk pad
		local padLight = Instance.new("PointLight")
		padLight.Brightness = 20
		padLight.Range = 10
		padLight.Color = Color3.fromRGB(255, 180, 40)
		padLight.Parent = pad

		-- GANTI mekanik: pad sentuh -> hold E 3 detik (ProximityPrompt)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CoopPrompt"
		prompt.ActionText = "Hold E to Activate"
		prompt.ObjectText = "Cooperation Pad"
		prompt.KeyboardKeyCode = Enum.KeyCode.E   -- desktop key "E"
		prompt.HoldDuration = 3                   -- tahan 3 detik
		prompt.RequiresLineOfSight = false        -- lebih ramah medan
		prompt.MaxActivationDistance = 12
		prompt.Parent = pad

		-- Saat player berhasil hold 3 detik, tandai dia "ok"
		prompt.Triggered:Connect(function(plr)
			-- Jika multi-player & player sudah menghancurkan 1 pad, abaikan
			if limitPerPlayer and destroyedBy[plr.UserId] then
				return
			end
			destroyedBy[plr.UserId] = true
			okPlayers[plr.UserId] = true
			-- Matikan prompt supaya tidak dipakai ulang
			prompt.Enabled = false
			prompt:Destroy()

			-- Efek visual saat pad dihancurkan
			local explosion = Instance.new("Part")
			explosion.Size = Vector3.new(1, 1, 1)
			explosion.Position = pad.Position
			explosion.Anchored = true
			explosion.CanCollide = false
			explosion.Transparency = 1
			explosion.Parent = workspace

			local explodeLight = Instance.new("PointLight")
			explodeLight.Brightness = 40
			explodeLight.Range = 18
			explodeLight.Color = Color3.fromRGB(255, 80, 0)
			explodeLight.Parent = explosion

			TweenService:Create(
				explodeLight,
				TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Brightness = 0}
			):Play()

			game:GetService("Debris"):AddItem(explosion, 0.7)

			-- HANCURKAN PAD SETELAH HOLD 3 DETIK
			if pad and pad.Parent then
				pad:Destroy()
			end
		end)

		table.insert(pads, pad)
		Debris:AddItem(pad, duration + 1)
	end

	return pads
end

return Boss2VFXModule
