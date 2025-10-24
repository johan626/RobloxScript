-- Boss3VFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/Boss3VFXModule.lua
-- Script Place: ACT 1: Village

local Boss3VFXModule = {}

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))

-- Helper function to create an advanced beam between two points
local function createAdvancedBeam(fromPart, toPart, color, parent)
	local attachment0 = Instance.new("Attachment")
	attachment0.Parent = fromPart
	attachment0.Position = Vector3.new(0, 0, 0)

	local attachment1 = Instance.new("Attachment")
	attachment1.Parent = toPart
	attachment1.Position = Vector3.new(0, 0, 0)

	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Color = ColorSequence.new(color)
	beam.Width0 = 0.4
	beam.Width1 = 0.4
	beam.FaceCamera = true
	beam.LightEmission = 1.0
	beam.LightInfluence = 0
	beam.Texture = "rbxassetid://2592365271" -- Default Roblox beam texture
	beam.TextureSpeed = 2.5
	beam.TextureLength = 8
	beam.Segments = 100
	beam.CurveSize0 = 0.3
	beam.CurveSize1 = 0.3
	beam.Parent = parent

	-- Create secondary glow beam
	local glowBeam = Instance.new("Beam")
	glowBeam.Attachment0 = attachment0
	glowBeam.Attachment1 = attachment1
	glowBeam.Color = ColorSequence.new(Color3.new(1, 1, 1))
	glowBeam.Width0 = 0.2
	glowBeam.Width1 = 0.2
	glowBeam.Transparency = NumberSequence.new(0.7)
	glowBeam.FaceCamera = true
	glowBeam.LightEmission = 0.5
	glowBeam.LightInfluence = 0
	glowBeam.Parent = parent

	-- Add pulsing effect with smooth easing
	coroutine.wrap(function()
		local startTime = time()
		while beam and beam.Parent do
			local t = time() - startTime
			local pulse = 0.8 + math.sin(t * 6) * 0.2
			beam.Width0 = 0.4 * pulse
			beam.Width1 = 0.4 * pulse
			glowBeam.Width0 = 0.2 * pulse
			glowBeam.Width1 = 0.2 * pulse

			-- Dynamic color shifting for more organic feel
			local hueShift = math.sin(t * 0.3) * 0.05
			local baseColor = color
			local shiftedColor = Color3.new(
				math.clamp(baseColor.R + hueShift, 0, 1),
				math.clamp(baseColor.G + hueShift * 0.3, 0, 1),
				math.clamp(baseColor.B - hueShift * 0.2, 0, 1)
			)
			beam.Color = ColorSequence.new(shiftedColor)

			-- Texture animation
			beam.TextureSpeed = 2 + math.sin(t * 2) * 1

			RunService.Heartbeat:Wait()
		end
	end)()

	return {Beam = beam, GlowBeam = glowBeam, Attachment0 = attachment0, Attachment1 = attachment1}
end

-- Helper function to create a realistic mirror surface with improved visuals
local function createMirrorSurface(parentPart)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.AlwaysOnTop = true
	surfaceGui.Parent = parentPart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(200, 200, 240)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = surfaceGui

	-- Create realistic reflection effect using multiple layers
	local reflection = Instance.new("Frame")
	reflection.Size = UDim2.new(1, 0, 1, 0)
	reflection.BackgroundColor3 = Color3.fromRGB(220, 220, 255)
	reflection.BackgroundTransparency = 0.7
	reflection.BorderSizePixel = 0
	reflection.Parent = frame

	-- Add animated distortion effect
	local distortion = Instance.new("Frame")
	distortion.Size = UDim2.new(1, 0, 1, 0)
	distortion.BackgroundColor3 = Color3.fromRGB(180, 180, 220)
	distortion.BackgroundTransparency = 0.9
	distortion.BorderSizePixel = 0
	distortion.Parent = frame

	-- Animate distortion
	coroutine.wrap(function()
		while distortion and distortion.Parent do
			local t = time()
			distortion.BackgroundTransparency = 0.85 + math.sin(t * 3) * 0.05
			RunService.Heartbeat:Wait()
		end
	end)()

	-- Add multiple shimmer effects for more realism
	for i = 1, 4 do
		coroutine.wrap(function()
			while surfaceGui and surfaceGui.Parent do
				local shimmer = Instance.new("Frame")
				shimmer.Size = UDim2.new(0.03, 0, 1.5, 0)
				shimmer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				shimmer.BackgroundTransparency = 0.9
				shimmer.BorderSizePixel = 0
				shimmer.Position = UDim2.new(-0.03, 0, -0.25, 0)
				shimmer.Rotation = math.random(-15, 15)
				shimmer.Parent = frame

				local tween = TweenService:Create(shimmer, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Position = UDim2.new(1.03, 0, -0.25, 0),
					BackgroundTransparency = 0.98
				})
				tween:Play()

				Debris:AddItem(shimmer, 2)
				wait(math.random(2, 4))
			end
		end)()
	end

	return surfaceGui
end

-- Fungsi ini akan dipanggil oleh ZombieModule untuk memulai mekanik.
function Boss3VFXModule.StartMirrorQuartet(bossModel, config)
	local mechanicContext = {
		Objects = {}, -- Tabel untuk menyimpan semua objek yang dibuat
		OnMirrorLocked = Instance.new("BindableEvent"), -- Event untuk sinyal interaksi
		Mirrors = {}, -- Untuk menyimpan referensi ke cermin dan sinarnya
		BeamComponents = {}, -- Untuk menyimpan komponen beam
		CleanupFunctions = {} -- Untuk menyimpan fungsi cleanup
	}

	-- Store original lighting
	local originalBrightness = Lighting.Brightness
	local originalAmbient = Lighting.Ambient
	local originalOutdoorAmbient = Lighting.OutdoorAmbient
	local originalFogEnd = Lighting.FogEnd

	-- Change lighting for dramatic effect
	Lighting.Brightness = 0.6
	Lighting.Ambient = Color3.fromRGB(30, 30, 50)
	Lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 70)
	Lighting.FogEnd = 200
	Lighting.FogColor = Color3.fromRGB(40, 40, 60)

	-- Add cleanup function for lighting
	table.insert(mechanicContext.CleanupFunctions, function()
		Lighting.Brightness = originalBrightness
		Lighting.Ambient = originalAmbient
		Lighting.OutdoorAmbient = originalOutdoorAmbient
		Lighting.FogEnd = originalFogEnd
	end)

	-- 1. Buat Prisma Tengah yang lebih realistis dengan efek partikel yang ditingkatkan
	local bossPos = bossModel.PrimaryPart.Position
	local prism = Instance.new("Part")
	prism.Name = "QuartetPrism"
	prism.Size = Vector3.new(5, 8, 5)
	prism.Material = Enum.Material.Glass
	prism.Color = Color3.fromRGB(180, 180, 255)
	prism.Anchored = true
	prism.CanCollide = false
	prism.Position = bossPos + Vector3.new(0, 15, 0)
	prism.Shape = Enum.PartType.Cylinder
	prism.Transparency = 0.1
	prism.Parent = workspace

	-- Add crystal-like details to prism
	local crystalDetail = Instance.new("Part")
	crystalDetail.Name = "CrystalDetail"
	crystalDetail.Size = Vector3.new(4.5, 7.5, 4.5)
	crystalDetail.Material = Enum.Material.Neon
	crystalDetail.Color = Color3.fromRGB(120, 120, 200)
	crystalDetail.Anchored = true
	crystalDetail.CanCollide = false
	crystalDetail.Position = prism.Position
	crystalDetail.Shape = Enum.PartType.Cylinder
	crystalDetail.Transparency = 0.3
	crystalDetail.Parent = workspace

	-- Add advanced prism light with flickering
	local prismLight = Instance.new("PointLight")
	prismLight.Brightness = 25
	prismLight.Range = 40
	prismLight.Color = Color3.fromRGB(140, 140, 255)
	prismLight.Shadows = true
	prismLight.Parent = prism

	-- Add rotating animation to prism
	coroutine.wrap(function()
		local startTime = time()
		while prism and prism.Parent do
			local t = time() - startTime
			prism.CFrame = CFrame.new(prism.Position) * CFrame.Angles(0, t * 0.5, 0)
			crystalDetail.CFrame = prism.CFrame
			RunService.Heartbeat:Wait()
		end
	end)()

	table.insert(mechanicContext.Objects, prism)
	table.insert(mechanicContext.Objects, crystalDetail)

	-- 2. Buat Cermin untuk setiap pemain dengan desain yang lebih realistis
	local players = game:GetService("Players"):GetPlayers()
	local requiredPlayers = math.min(#players, config.RequiredPlayers or 4)

	for i = 1, requiredPlayers do
		local angle = (i / requiredPlayers) * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * 28, 0, math.sin(angle) * 28)

		-- Raycast ke bawah untuk menempatkan cermin di tanah
		local rayOrigin = bossPos + offset + Vector3.new(0, 50, 0)
		local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -100, 0))
		local mirrorPos = rayResult and rayResult.Position or (bossPos + offset)

		-- Buat base untuk cermin dengan detail lebih
		local mirrorBase = Instance.new("Part")
		mirrorBase.Name = "MirrorBase" .. i
		mirrorBase.Size = Vector3.new(8, 1.5, 8)
		mirrorBase.Material = Enum.Material.Granite
		mirrorBase.Color = Color3.fromRGB(70, 70, 90)
		mirrorBase.Anchored = true
		mirrorBase.CanCollide = false
		mirrorBase.Position = mirrorPos
		mirrorBase.Parent = workspace

		-- Add base details with ornate design
		local baseDetail = Instance.new("Part")
		baseDetail.Name = "BaseDetail" .. i
		baseDetail.Size = Vector3.new(7, 0.4, 7)
		baseDetail.Material = Enum.Material.Metal
		baseDetail.Color = Color3.fromRGB(120, 120, 140)
		baseDetail.Anchored = true
		baseDetail.CanCollide = false
		baseDetail.Position = mirrorPos + Vector3.new(0, 0.75, 0)
		baseDetail.Parent = workspace

		-- Add base ornamentation
		for j = 1, 4 do
			local ornamentAngle = (j / 4) * math.pi * 2
			local ornamentOffset = Vector3.new(math.cos(ornamentAngle) * 3.5, 0, math.sin(ornamentAngle) * 3.5)
			local ornament = Instance.new("Part")
			ornament.Name = "BaseOrnament" .. j
			ornament.Size = Vector3.new(1, 0.3, 1)
			ornament.Material = Enum.Material.Neon
			ornament.Color = Color3.fromRGB(100, 100, 150)
			ornament.Anchored = true
			ornament.CanCollide = false
			ornament.Position = mirrorPos + ornamentOffset + Vector3.new(0, 1.1, 0)
			ornament.Shape = Enum.PartType.Cylinder
			ornament.Parent = workspace
			table.insert(mechanicContext.Objects, ornament)
		end

		table.insert(mechanicContext.Objects, mirrorBase)
		table.insert(mechanicContext.Objects, baseDetail)

		-- Buat frame cermin dengan detail lebih
		local mirrorFrame = Instance.new("Part")
		mirrorFrame.Name = "MirrorFrame" .. i
		mirrorFrame.Size = Vector3.new(6.5, 8, 0.8)
		mirrorFrame.Material = Enum.Material.Metal
		mirrorFrame.Color = Color3.fromRGB(110, 110, 140)
		mirrorFrame.Anchored = true
		mirrorFrame.CanCollide = false
		mirrorFrame.Position = mirrorPos + Vector3.new(0, 5, 0)
		mirrorFrame.Parent = workspace

		-- Add frame details with intricate design
		local frameOrnamentTop = Instance.new("Part")
		frameOrnamentTop.Name = "FrameOrnamentTop" .. i
		frameOrnamentTop.Size = Vector3.new(7, 0.4, 1)
		frameOrnamentTop.Material = Enum.Material.Neon
		frameOrnamentTop.Color = Color3.fromRGB(160, 160, 200)
		frameOrnamentTop.Anchored = true
		frameOrnamentTop.CanCollide = false
		frameOrnamentTop.Position = mirrorFrame.Position + Vector3.new(0, 4.2, 0)
		frameOrnamentTop.Parent = workspace

		local frameOrnamentBottom = frameOrnamentTop:Clone()
		frameOrnamentBottom.Name = "FrameOrnamentBottom" .. i
		frameOrnamentBottom.Position = mirrorFrame.Position + Vector3.new(0, -4.2, 0)
		frameOrnamentBottom.Parent = workspace

		-- Add side ornaments
		local frameOrnamentLeft = Instance.new("Part")
		frameOrnamentLeft.Name = "FrameOrnamentLeft" .. i
		frameOrnamentLeft.Size = Vector3.new(0.4, 8.4, 1)
		frameOrnamentLeft.Material = Enum.Material.Neon
		frameOrnamentLeft.Color = Color3.fromRGB(160, 160, 200)
		frameOrnamentLeft.Anchored = true
		frameOrnamentLeft.CanCollide = false
		frameOrnamentLeft.Position = mirrorFrame.Position + Vector3.new(-3.3, 0, 0)
		frameOrnamentLeft.Parent = workspace

		local frameOrnamentRight = frameOrnamentLeft:Clone()
		frameOrnamentRight.Name = "FrameOrnamentRight" .. i
		frameOrnamentRight.Position = mirrorFrame.Position + Vector3.new(3.3, 0, 0)
		frameOrnamentRight.Parent = workspace

		table.insert(mechanicContext.Objects, mirrorFrame)
		table.insert(mechanicContext.Objects, frameOrnamentTop)
		table.insert(mechanicContext.Objects, frameOrnamentBottom)
		table.insert(mechanicContext.Objects, frameOrnamentLeft)
		table.insert(mechanicContext.Objects, frameOrnamentRight)

		-- Buat permukaan cermin dengan efek lebih realistis
		local mirrorSurface = Instance.new("Part")
		mirrorSurface.Name = "MirrorSurface" .. i
		mirrorSurface.Size = Vector3.new(5, 7, 0.1)
		mirrorSurface.Material = Enum.Material.Glass
		mirrorSurface.Color = Color3.fromRGB(220, 220, 250)
		mirrorSurface.Anchored = true
		mirrorSurface.CanCollide = false
		mirrorSurface.Position = mirrorPos + Vector3.new(0, 5, 0)
		mirrorSurface.Transparency = 0.02
		mirrorSurface.Parent = workspace
		table.insert(mechanicContext.Objects, mirrorSurface)

		-- Add enhanced mirror surface effect
		createMirrorSurface(mirrorSurface)

		-- Random rotation untuk variasi
		local randomYRotation = CFrame.Angles(0, math.rad(math.random(-120, 120)), 0)
		mirrorFrame.CFrame = CFrame.new(mirrorFrame.Position) * randomYRotation
		mirrorSurface.CFrame = mirrorFrame.CFrame
		frameOrnamentTop.CFrame = mirrorFrame.CFrame * CFrame.new(0, 4.2, 0.1)
		frameOrnamentBottom.CFrame = mirrorFrame.CFrame * CFrame.new(0, -4.2, 0.1)
		frameOrnamentLeft.CFrame = mirrorFrame.CFrame * CFrame.new(-3.3, 0, 0.1)
		frameOrnamentRight.CFrame = mirrorFrame.CFrame * CFrame.new(3.3, 0, 0.1)

		local initialCFrameValue = Instance.new("CFrameValue")
		initialCFrameValue.Name = "InitialCFrame"
		initialCFrameValue.Value = mirrorSurface.CFrame
		initialCFrameValue.Parent = mirrorSurface

		-- Enhanced hover animation yang lebih halus
		local hoverCoroutine = coroutine.create(function()
			local amplitude = 0.8
			local frequency = 0.5
			local startTime = time()
			while mirrorSurface and mirrorSurface.Parent do
				local t = time() - startTime
				local hoverOffset = Vector3.new(
					math.sin(t * frequency * 0.7) * amplitude * 0.3,
					math.sin(t * frequency) * amplitude,
					math.cos(t * frequency * 0.5) * amplitude * 0.2
				)
				local newCFrame = initialCFrameValue.Value * CFrame.new(hoverOffset)
				mirrorSurface.CFrame = newCFrame
				mirrorFrame.CFrame = newCFrame
				frameOrnamentTop.CFrame = newCFrame * CFrame.new(0, 4.2, 0.1)
				frameOrnamentBottom.CFrame = newCFrame * CFrame.new(0, -4.2, 0.1)
				frameOrnamentLeft.CFrame = newCFrame * CFrame.new(-3.3, 0, 0.1)
				frameOrnamentRight.CFrame = newCFrame * CFrame.new(3.3, 0, 0.1)
				RunService.Heartbeat:Wait()
			end
		end)
		coroutine.resume(hoverCoroutine)
		table.insert(mechanicContext.CleanupFunctions, function() 
			if hoverCoroutine then 
				coroutine.close(hoverCoroutine) 
			end 
		end)

		-- Add enhanced glow effect to mirror
		local mirrorGlow = Instance.new("PointLight")
		mirrorGlow.Brightness = 15
		mirrorGlow.Range = 15
		mirrorGlow.Color = Color3.fromRGB(160, 160, 220)
		mirrorGlow.Parent = mirrorSurface

		-- Buat target untuk beam
		local beamTarget = Instance.new("Part")
		beamTarget.Name = "BeamTarget" .. i
		beamTarget.Anchored = true
		beamTarget.CanCollide = false
		beamTarget.Transparency = 1
		beamTarget.Size = Vector3.new(1, 1, 1)

		-- Arahkan beam ke posisi acak awal
		local randomDirection = (mirrorSurface.CFrame.LookVector)
		beamTarget.Position = mirrorSurface.Position + randomDirection * 35
		beamTarget.Parent = workspace
		table.insert(mechanicContext.Objects, beamTarget)

		-- Buat beam yang lebih advanced dengan multiple beams untuk efek tebal
		local mainBeamComponents = createAdvancedBeam(mirrorSurface, beamTarget, Color3.fromRGB(255, 120, 120), workspace)

		-- Add impact effect at beam target
		local targetGlow = Instance.new("Part")
		targetGlow.Name = "TargetGlow" .. i
		targetGlow.Size = Vector3.new(2, 2, 2)
		targetGlow.Shape = Enum.PartType.Ball
		targetGlow.Material = Enum.Material.Neon
		targetGlow.Color = Color3.fromRGB(255, 150, 150)
		targetGlow.Anchored = true
		targetGlow.CanCollide = false
		targetGlow.Transparency = 0.3
		targetGlow.Position = beamTarget.Position
		targetGlow.Parent = workspace

		local targetLight = Instance.new("PointLight")
		targetLight.Brightness = 10
		targetLight.Range = 8
		targetLight.Color = Color3.fromRGB(255, 150, 150)
		targetLight.Parent = targetGlow

		table.insert(mechanicContext.Objects, mainBeamComponents.Beam)
		table.insert(mechanicContext.Objects, mainBeamComponents.GlowBeam)
		table.insert(mechanicContext.Objects, mainBeamComponents.Attachment0)
		table.insert(mechanicContext.Objects, mainBeamComponents.Attachment1)
		table.insert(mechanicContext.Objects, targetGlow)

		mechanicContext.BeamComponents[i] = {
			MainBeam = mainBeamComponents.Beam,
			GlowBeam = mainBeamComponents.GlowBeam,
			Attachment0 = mainBeamComponents.Attachment0,
			Attachment1 = mainBeamComponents.Attachment1,
			TargetGlow = targetGlow
		}

		-- Simpan referensi
		mechanicContext.Mirrors[i] = {
			mirrorBase = mirrorBase, 
			mirrorFrame = mirrorFrame, 
			mirrorSurface = mirrorSurface, 
			beamComponents = mechanicContext.BeamComponents[i], 
			beamTarget = beamTarget, 
			locked = false,
			frameOrnamentTop = frameOrnamentTop,
			frameOrnamentBottom = frameOrnamentBottom,
			frameOrnamentLeft = frameOrnamentLeft,
			frameOrnamentRight = frameOrnamentRight,
			baseDetail = baseDetail
		}

		-- Fungsi untuk memperbarui beam
		local function updateBeam()
			local newDirection = mirrorSurface.CFrame.LookVector

			-- Logika untuk memeriksa apakah sinar mengarah ke prisma
			local directionToPrism = (prism.Position - mirrorSurface.Position).Unit
			local beamDirection = mirrorSurface.CFrame.LookVector.Unit
			local angle = math.acos(directionToPrism:Dot(beamDirection))

			-- Jika sudutnya cukup kecil (dalam 5 derajat), kunci ke prisma
			if angle < math.rad(5) then
				beamTarget.Position = prism.Position
				targetGlow.Position = prism.Position

				if mainBeamComponents.Beam.Color ~= ColorSequence.new(Color3.fromRGB(120, 255, 120)) then
					mainBeamComponents.Beam.Color = ColorSequence.new(Color3.fromRGB(120, 255, 120))
					mainBeamComponents.GlowBeam.Color = ColorSequence.new(Color3.new(1, 1, 1))
					targetGlow.Color = Color3.fromRGB(120, 255, 120)
					targetLight.Color = Color3.fromRGB(120, 255, 120)
					mirrorGlow.Color = Color3.fromRGB(120, 255, 150)
					frameOrnamentTop.Color = Color3.fromRGB(120, 255, 150)
					frameOrnamentBottom.Color = Color3.fromRGB(120, 255, 150)
					frameOrnamentLeft.Color = Color3.fromRGB(120, 255, 150)
					frameOrnamentRight.Color = Color3.fromRGB(120, 255, 150)

					-- Trigger lock event
					if not mechanicContext.Mirrors[i].locked then
						mechanicContext.Mirrors[i].locked = true
						mechanicContext.OnMirrorLocked:Fire(i)

						-- Play lock sound effect
						local lockSound = AudioManager.playSound("Boss.Alert", mirrorSurface, {Volume = 0.6})
						Debris:AddItem(lockSound, 3)

						-- Add lock visual effect
						local lockEffect = Instance.new("Part")
						lockEffect.Name = "LockEffect"
						lockEffect.Size = Vector3.new(3, 3, 3)
						lockEffect.Shape = Enum.PartType.Ball
						lockEffect.Material = Enum.Material.Neon
						lockEffect.Color = Color3.fromRGB(120, 255, 150)
						lockEffect.Anchored = true
						lockEffect.CanCollide = false
						lockEffect.Transparency = 0.5
						lockEffect.Position = mirrorSurface.Position
						lockEffect.Parent = workspace

						local lockLight = Instance.new("PointLight")
						lockLight.Brightness = 20
						lockLight.Range = 10
						lockLight.Color = Color3.fromRGB(120, 255, 150)
						lockLight.Parent = lockEffect

						-- Animate lock effect
						local tween = TweenService:Create(lockEffect, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
							Size = Vector3.new(0.1, 0.1, 0.1),
							Transparency = 1
						})
						tween:Play()
						Debris:AddItem(lockEffect, 0.6)
					end
				end
			else
				beamTarget.Position = mirrorSurface.Position + newDirection * 35
				targetGlow.Position = beamTarget.Position

				if mainBeamComponents.Beam.Color ~= ColorSequence.new(Color3.fromRGB(255, 120, 120)) then
					mainBeamComponents.Beam.Color = ColorSequence.new(Color3.fromRGB(255, 120, 120))
					mainBeamComponents.GlowBeam.Color = ColorSequence.new(Color3.new(1, 1, 1))
					targetGlow.Color = Color3.fromRGB(255, 150, 150)
					targetLight.Color = Color3.fromRGB(255, 150, 150)
					mirrorGlow.Color = Color3.fromRGB(160, 160, 220)
					frameOrnamentTop.Color = Color3.fromRGB(160, 160, 200)
					frameOrnamentBottom.Color = Color3.fromRGB(160, 160, 200)
					frameOrnamentLeft.Color = Color3.fromRGB(160, 160, 200)
					frameOrnamentRight.Color = Color3.fromRGB(160, 160, 200)
					mechanicContext.Mirrors[i].locked = false
				end
			end
		end

		-- Enhanced Tombol Penyesuaian Manual yang lebih imersif
		local function createAdjustmentButton(name, text, positionOffset, cframeAdjustment)
			local buttonPart = Instance.new("Part")
			buttonPart.Name = name .. "Button" .. i
			buttonPart.Size = Vector3.new(1.5, 1.5, 0.4)
			buttonPart.Material = Enum.Material.Neon
			buttonPart.Color = Color3.fromRGB(90, 90, 130)
			buttonPart.Anchored = true
			buttonPart.CanCollide = false
			buttonPart.Shape = Enum.PartType.Cylinder

			-- Posisikan tombol relatif terhadap cermin
			local initialCFrame = mirrorSurface:FindFirstChild("InitialCFrame")
			if initialCFrame then
				buttonPart.CFrame = initialCFrame.Value * CFrame.new(positionOffset)
			end
			buttonPart.Parent = mirrorFrame

			-- Add button glow with pulsating effect
			local buttonGlow = Instance.new("PointLight")
			buttonGlow.Brightness = 10
			buttonGlow.Range = 5
			buttonGlow.Color = Color3.fromRGB(110, 110, 180)
			buttonGlow.Parent = buttonPart

			-- Pulsating glow effect
			coroutine.wrap(function()
				while buttonPart and buttonPart.Parent do
					local pulse = 0.5 + math.sin(time() * 4) * 0.5
					buttonGlow.Brightness = 5 + pulse * 5
					RunService.Heartbeat:Wait()
				end
			end)()

			local promptAdjust = Instance.new("ProximityPrompt")
			promptAdjust.Name = name .. "Prompt"
			promptAdjust.ActionText = text
			promptAdjust.ObjectText = "Tahan untuk Menyesuaikan Cermin"
			promptAdjust.KeyboardKeyCode = Enum.KeyCode.E
			promptAdjust.RequiresLineOfSight = false
			promptAdjust.MaxActivationDistance = 10
			promptAdjust.HoldDuration = 0.08
			promptAdjust.Parent = buttonPart

			local isHolding = false
			local holdCoroutine

			promptAdjust.PromptButtonHoldBegan:Connect(function()
				if mechanicContext.Mirrors[i].locked then return end
				isHolding = true

				holdCoroutine = coroutine.create(function()
					while isHolding and initialCFrame do
						initialCFrame.Value = initialCFrame.Value * cframeAdjustment
						updateBeam()

						-- Enhanced button feedback
						buttonPart.Color = Color3.fromRGB(160, 160, 200)
						buttonGlow.Color = Color3.fromRGB(160, 160, 255)
						wait(0.04)
						buttonPart.Color = Color3.fromRGB(90, 90, 130)
						buttonGlow.Color = Color3.fromRGB(110, 110, 180)

						RunService.Heartbeat:Wait()
					end
				end)
				coroutine.resume(holdCoroutine)
			end)

			promptAdjust.PromptButtonHoldEnded:Connect(function()
				isHolding = false
				if holdCoroutine then
					coroutine.close(holdCoroutine)
				end
			end)

			table.insert(mechanicContext.Objects, buttonPart)
		end

		local ADJUST_ANGLE = CFrame.Angles(0, math.rad(2), 0)  -- Lebih halus
		local ADJUST_ANGLE_NEG = CFrame.Angles(0, math.rad(-2), 0)
		local ADJUST_PITCH = CFrame.Angles(math.rad(2), 0, 0)
		local ADJUST_PITCH_NEG = CFrame.Angles(math.rad(-2), 0, 0)

		-- Tombol Kiri
		createAdjustmentButton("AdjustLeft", "Putar Kiri", Vector3.new(-4, 0, 0), ADJUST_ANGLE_NEG)
		-- Tombol Kanan
		createAdjustmentButton("AdjustRight", "Putar Kanan", Vector3.new(4, 0, 0), ADJUST_ANGLE)
		-- Tombol Atas
		createAdjustmentButton("AdjustUp", "Miringkan Atas", Vector3.new(0, 4, 0), ADJUST_PITCH)
		-- Tombol Bawah
		createAdjustmentButton("AdjustDown", "Miringkan Bawah", Vector3.new(0, -4, 0), ADJUST_PITCH_NEG)

		-- Panggil updateBeam untuk inisialisasi
		updateBeam()
	end

	-- Add ambient sound effect
	local ambientSound = AudioManager.createSound("Boss.Alert", prism, {Volume = 0.5, Looped = true})
	ambientSound:Play()
	table.insert(mechanicContext.Objects, ambientSound)

	-- Add completion effect when all mirrors are locked
	mechanicContext.OnMirrorLocked.Event:Connect(function(mirrorIndex)
		local allLocked = true
		for i, mirror in ipairs(mechanicContext.Mirrors) do
			if not mirror.locked then
				allLocked = false
				break
			end
		end

		if allLocked then
			-- Play completion sound
			local completionSound = AudioManager.playSound("Boss.Complete", prism, {Volume = 1.0})
			Debris:AddItem(completionSound, 3)

			-- Enhanced visual feedback for completion
			for i, mirror in ipairs(mechanicContext.Mirrors) do
				-- Flash effect on mirror frame
				local flashTween = TweenService:Create(mirror.frameOrnamentTop, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 4, true), {
					Color = Color3.fromRGB(255, 255, 200)
				})
				flashTween:Play()

				-- Create completion beam to prism
				local completionBeam = Instance.new("Beam")
				completionBeam.Attachment0 = Instance.new("Attachment")
				completionBeam.Attachment0.Parent = mirror.mirrorSurface
				completionBeam.Attachment1 = Instance.new("Attachment")
				completionBeam.Attachment1.Parent = prism
				completionBeam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 200))
				completionBeam.Width0 = 0.8
				completionBeam.Width1 = 0.8
				completionBeam.FaceCamera = true
				completionBeam.LightEmission = 1.0
				completionBeam.Parent = workspace

				-- Animate completion beam
				coroutine.wrap(function()
					local startTime = time()
					while time() - startTime < 3 do
						local t = time() - startTime
						local pulse = 0.7 + math.sin(t * 10) * 0.3
						completionBeam.Width0 = 0.8 * pulse
						completionBeam.Width1 = 0.8 * pulse
						RunService.Heartbeat:Wait()
					end
					completionBeam:Destroy()
				end)()
			end

			-- Enhance prism effects
			prismLight.Brightness = 40
			prismLight.Color = Color3.fromRGB(255, 255, 200)
			prism.Color = Color3.fromRGB(220, 220, 255)
			crystalDetail.Color = Color3.fromRGB(180, 180, 255)
		end
	end)

	-- Mengembalikan konteks mekanik
	return mechanicContext
end

-- Fungsi ini akan membersihkan semua objek yang dibuat untuk mekanik.
function Boss3VFXModule.Cleanup(context)
	if not context then return end

	-- Run all cleanup functions
	if context.CleanupFunctions then
		for _, cleanupFunc in ipairs(context.CleanupFunctions) do
			pcall(cleanupFunc)
		end
	end

	if context.Objects then
		for _, item in ipairs(context.Objects) do
			if typeof(item) == "table" and item.cancel then
				pcall(item.cancel)
			elseif typeof(item) == "Instance" and item.Parent then
				item:Destroy()
			end
		end
	end

	-- Hancurkan BindableEvent juga
	if context.OnMirrorLocked then
		context.OnMirrorLocked:Destroy()
	end

	print("Membersihkan objek Mirror Quartet.")
end

-- Fungsi untuk memulai mekanik "Chromatic Requiem"
function Boss3VFXModule.StartChromaticRequiem(bossModel, config)
	local mechanicContext = {
		Objects = {},
		Crystals = {},
		Beams = {}
	}

	local bossPos = bossModel.PrimaryPart.Position
	local arenaCenter = bossPos -- Asumsi pusat arena adalah posisi bos

	-- Warna dan posisi untuk kristal
	local crystalData = {
		{Name = "North", Color = Color3.fromRGB(255, 0, 0), Position = Vector3.new(0, 0, -40)},  -- Merah
		{Name = "East", Color = Color3.fromRGB(0, 255, 0), Position = Vector3.new(40, 0, 0)},   -- Hijau
		{Name = "South", Color = Color3.fromRGB(0, 0, 255), Position = Vector3.new(0, 0, 40)},  -- Biru
		{Name = "West", Color = Color3.fromRGB(255, 255, 0), Position = Vector3.new(-40, 0, 0)} -- Kuning
	}

	for i, data in ipairs(crystalData) do
		-- Buat Kristal
		local crystal = Instance.new("Part")
		crystal.Name = "RequiemCrystal_" .. data.Name
		crystal.Size = Vector3.new(6, 12, 6)
		crystal.Material = Enum.Material.Neon
		crystal.Color = data.Color
		crystal.Anchored = true
		crystal.CanCollide = false

		-- Raycast ke bawah untuk menempatkan kristal di tanah
		local rayOrigin = arenaCenter + data.Position + Vector3.new(0, 50, 0)
		local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -100, 0))
		local crystalPos = rayResult and rayResult.Position or (arenaCenter + data.Position)

		crystal.Position = crystalPos + Vector3.new(0, crystal.Size.Y / 2, 0)
		crystal.Parent = workspace
		table.insert(mechanicContext.Objects, crystal)

		-- Buat Sinar Energi Kacau awal
		local beamComponents = createAdvancedBeam(bossModel.PrimaryPart, crystal, Color3.fromRGB(80, 80, 80), workspace)
		beamComponents.Beam.Name = "UnstableBeam_" .. data.Name
		table.insert(mechanicContext.Objects, beamComponents.Beam)
		table.insert(mechanicContext.Objects, beamComponents.GlowBeam)
		table.insert(mechanicContext.Objects, beamComponents.Attachment0)
		table.insert(mechanicContext.Objects, beamComponents.Attachment1)

		mechanicContext.Crystals[data.Name] = crystal
		mechanicContext.Beams[data.Name] = beamComponents.Beam
	end

	return mechanicContext
end

-- Fungsi untuk membersihkan semua objek visual dari "Chromatic Requiem"
function Boss3VFXModule.CleanupChromaticRequiem(context)
	if not context or not context.Objects then return end

	for _, obj in ipairs(context.Objects) do
		if obj and obj.Parent then
			obj:Destroy()
		end
	end
	print("Membersihkan objek Chromatic Requiem.")
end

-- Fungsi untuk membuat tanda serangan Corrupting Blast yang lebih realistis dan imersif
function Boss3VFXModule.CreateCorruptingBlastTelegraph(position, radius, duration)
	-- Efek pusat energi yang lebih kompleks
	local energyCore = Instance.new("Part")
	energyCore.Name = "CorruptingBlastCore"
	energyCore.Size = Vector3.new(6, 6, 6)
	energyCore.Shape = Enum.PartType.Ball
	energyCore.Material = Enum.Material.Neon
	energyCore.Color = Color3.fromRGB(160, 0, 220)
	energyCore.Anchored = true
	energyCore.CanCollide = false
	energyCore.Transparency = 0.1
	energyCore.Position = position
	energyCore.Parent = workspace

	-- Advanced lighting effects
	local coreLight = Instance.new("PointLight")
	coreLight.Brightness = 30
	coreLight.Range = 25
	coreLight.Color = Color3.fromRGB(180, 0, 240)
	coreLight.Shadows = true
	coreLight.Parent = energyCore

	-- Create a sphere of orbiting energy particles
	for i = 1, 16 do
		local angle = (i / 16) * math.pi * 2
		local orbitPart = Instance.new("Part")
		orbitPart.Name = "OrbitParticle"
		orbitPart.Size = Vector3.new(1, 1, 1)
		orbitPart.Shape = Enum.PartType.Ball
		orbitPart.Material = Enum.Material.Neon
		orbitPart.Color = Color3.fromRGB(180, 50, 220)
		orbitPart.Anchored = true
		orbitPart.CanCollide = false
		orbitPart.Parent = workspace

		-- Animate orbiting particles
		coroutine.wrap(function()
			local startTime = time()
			while time() - startTime < duration do
				local t = time() - startTime
				local orbitRadius = 5 + math.sin(t * 3) * 2
				local orbitPos = position + Vector3.new(
					math.cos(angle + t * 4) * orbitRadius,
					math.sin(t * 5) * 2,
					math.sin(angle + t * 4) * orbitRadius
				)
				orbitPart.Position = orbitPos
				orbitPart.Color = Color3.fromHSV((t * 0.3 + i/16) % 1, 1, 1)
				RunService.Heartbeat:Wait()
			end
			orbitPart:Destroy()
		end)()
	end

	-- Create a more sophisticated ring system
	for ringNum = 1, 3 do
		local ring = Instance.new("Part")
		ring.Name = "EnergyRing" .. ringNum
		ring.Size = Vector3.new(0.2, 0.2, 0.2)
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(180, 50, 220)
		ring.Anchored = true
		ring.CanCollide = false
		ring.Transparency = 0.2
		ring.CFrame = CFrame.new(position) * CFrame.Angles(math.pi/2, 0, 0)
		ring.Parent = workspace

		-- Animate ring expansion
		local ringTween = TweenService:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(radius * 2 * ringNum/3, 0.2, radius * 2 * ringNum/3),
			Transparency = 1
		})
		ringTween:Play()
		Debris:AddItem(ring, duration + 0.5)
	end

	-- Create energy beams radiating from center
	for i = 1, 36 do
		local angle = (i / 36) * math.pi * 2
		local endPos = position + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)

		local energyBeam = Instance.new("Part")
		energyBeam.Name = "RadialBeam"
		energyBeam.Size = Vector3.new(0.15, 0.15, (position - endPos).Magnitude)
		energyBeam.Material = Enum.Material.Neon
		energyBeam.Color = Color3.fromRGB(200, 100, 255)
		energyBeam.Anchored = true
		energyBeam.CanCollide = false
		energyBeam.Transparency = 0.3
		energyBeam.CFrame = CFrame.new(position, endPos) * CFrame.new(0, 0, -(position - endPos).Magnitude / 2)
		energyBeam.Parent = workspace

		-- Pulsing animation for beams
		local beamTween = TweenService:Create(energyBeam, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Transparency = 0.7,
			Color = Color3.fromRGB(220, 120, 255)
		})
		beamTween:Play()
		Debris:AddItem(energyBeam, duration)
	end

	-- Ground crack effect
	local crackPart = Instance.new("Part")
	crackPart.Name = "GroundCrack"
	crackPart.Size = Vector3.new(radius * 2, 0.1, radius * 2)
	crackPart.Shape = Enum.PartType.Cylinder
	crackPart.Material = Enum.Material.Slate
	crackPart.Color = Color3.fromRGB(40, 0, 60)
	crackPart.Anchored = true
	crackPart.CanCollide = false
	crackPart.Transparency = 1
	crackPart.CFrame = CFrame.new(position) * CFrame.Angles(math.pi/2, 0, 0)
	crackPart.Parent = workspace

	-- Crack particles
	local crackParticles = Instance.new("ParticleEmitter")
	crackParticles.LightEmission = 0.7
	crackParticles.Color = ColorSequence.new(Color3.fromRGB(120, 0, 180))
	crackParticles.Size = NumberSequence.new(0.2, 0.8)
	crackParticles.Lifetime = NumberRange.new(0.5, 1.2)
	crackParticles.Rate = 40
	crackParticles.SpreadAngle = Vector2.new(30, 30)
	crackParticles.Speed = NumberRange.new(1, 3)
	crackParticles.Parent = crackPart

	-- Core animation
	coroutine.wrap(function()
		local startTime = time()
		while time() - startTime < duration do
			local t = time() - startTime
			local pulse = 0.7 + math.sin(t * 12) * 0.3
			energyCore.Size = Vector3.new(6, 6, 6) * (0.9 + pulse * 0.2)
			coreLight.Brightness = 30 + math.sin(t * 15) * 15
			energyCore.Transparency = 0.1 + math.sin(t * 10) * 0.1

			-- Color cycling for more dynamic effect
			local hue = (t * 0.2) % 1
			energyCore.Color = Color3.fromHSV(hue, 1, 1)
			coreLight.Color = Color3.fromHSV(hue, 1, 1)
			RunService.Heartbeat:Wait()
		end
	end)()

	-- Warning sound
	local warningSound = AudioManager.playSound("Boss.Alert", workspace, {Volume = 0.8})

	-- Cleanup
	Debris:AddItem(energyCore, duration + 1)
	Debris:AddItem(crackPart, duration + 1)
	Debris:AddItem(warningSound, duration + 1)
end

-- Fungsi untuk membuat efek ledakan dan genangan korup yang lebih realistis
function Boss3VFXModule.CreateCorruptingBlastEffect(position, radius, puddleDuration)
	-- Initial flash effect (more intense)
	local flash = Instance.new("Part")
	flash.Name = "ExplosionFlash"
	flash.Size = Vector3.new(3, 3, 3)
	flash.Shape = Enum.PartType.Ball
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(255, 255, 255)
	flash.Anchored = true
	flash.CanCollide = false
	flash.Transparency = 0
	flash.Position = position
	flash.Parent = workspace

	local flashLight = Instance.new("PointLight")
	flashLight.Brightness = 100
	flashLight.Range = radius * 4
	flashLight.Color = Color3.fromRGB(255, 200, 255)
	flashLight.Shadows = true
	flashLight.Parent = flash

	-- Quick fade for flash
	local tweenInfoFlash = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tweenFlash = TweenService:Create(flashLight, tweenInfoFlash, {Brightness = 0})
	local tweenFlashTrans = TweenService:Create(flash, tweenInfoFlash, {Transparency = 1})
	tweenFlash:Play()
	tweenFlashTrans:Play()

	-- Main explosion particle system
	local explosionCenter = Instance.new("Part")
	explosionCenter.Size = Vector3.new(0.1, 0.1, 0.1)
	explosionCenter.Anchored = true
	explosionCenter.CanCollide = false
	explosionCenter.Transparency = 1
	explosionCenter.Position = position
	explosionCenter.Parent = workspace

	-- Secondary debris particles
	local debrisParticles = Instance.new("ParticleEmitter")
	debrisParticles.LightEmission = 0.6
	debrisParticles.Color = ColorSequence.new(Color3.fromRGB(120, 120, 120))
	debrisParticles.Size = NumberSequence.new(0.5, 2)
	debrisParticles.Lifetime = NumberRange.new(1.5, 3)
	debrisParticles.Rate = 200
	debrisParticles.SpreadAngle = Vector2.new(180, 180)
	debrisParticles.Speed = NumberRange.new(10, 25)
	debrisParticles.Parent = explosionCenter
	debrisParticles:Emit(150)

	-- Energy tendrils effect
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local tendril = Instance.new("Part")
		tendril.Name = "EnergyTendril"
		tendril.Size = Vector3.new(0.3, 0.3, radius * 1.5)
		tendril.Material = Enum.Material.Neon
		tendril.Color = Color3.fromRGB(180, 80, 220)
		tendril.Anchored = true
		tendril.CanCollide = false
		tendril.CFrame = CFrame.new(position) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -radius * 0.75)
		tendril.Parent = workspace

		-- Animate tendril growth and fade
		local tendrilTween = TweenService:Create(tendril, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.1, 0.1, radius * 0.5),
			Transparency = 1
		})
		tendrilTween:Play()
		Debris:AddItem(tendril, 1)
	end

	-- Corruption puddle with more detail
	local corruptionPuddle = Instance.new("Part")
	corruptionPuddle.Name = "CorruptionPuddle"
	corruptionPuddle.Size = Vector3.new(radius * 1.8, 0.3, radius * 1.8)
	corruptionPuddle.Shape = Enum.PartType.Cylinder
	corruptionPuddle.Material = Enum.Material.Slate
	corruptionPuddle.Color = Color3.fromRGB(50, 0, 80)
	corruptionPuddle.Anchored = true
	corruptionPuddle.CanCollide = false
	corruptionPuddle.Transparency = 1
	corruptionPuddle.CFrame = CFrame.new(position) * CFrame.Angles(math.pi/2, 0, 0)
	corruptionPuddle.Parent = workspace

	-- Puddle light effect
	local puddleLight = Instance.new("PointLight")
	puddleLight.Brightness = 8
	puddleLight.Range = radius * 1.2
	puddleLight.Color = Color3.fromRGB(140, 0, 200)
	puddleLight.Shadows = true
	puddleLight.Parent = corruptionPuddle

	-- Animate puddle formation
	corruptionPuddle.Size = Vector3.new(0.1, 0.3, 0.1)
	local puddleTween = TweenService:Create(corruptionPuddle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(radius * 1.8, 0.3, radius * 1.8)
	})
	puddleTween:Play()

	-- Explosion sound
	local explosionSound = AudioManager.playSound("Boss.Complete", workspace, {Volume = 1.2})

	-- Bass effect for more impact
	local bassSound = AudioManager.createSound("Boss.Bass", workspace, {Volume = 0.9})
	delay(0.1, function()
		if bassSound then bassSound:Play() end
	end)

	-- Cleanup
	Debris:AddItem(flash, 0.5)
	Debris:AddItem(explosionCenter, 3)
	Debris:AddItem(corruptionPuddle, puddleDuration)
	Debris:AddItem(explosionSound, 3)
	Debris:AddItem(bassSound, 3)
end

-- Fungsi untuk membuat telegraph Grasping Souls yang lebih realistis
function Boss3VFXModule.CreateGraspingSoulsTelegraph(bossModel, soulCount, telegraphDuration)
	local souls = {}
	local bossCFrame = bossModel.PrimaryPart.CFrame

	for i = 1, soulCount do
		local angle = (i / soulCount) * math.pi * 2
		local radius = 12
		local initialOffset = Vector3.new(math.cos(angle) * radius, 3, math.sin(angle) * radius)
		local soulPos = (bossCFrame * CFrame.new(initialOffset)).Position

		-- Container untuk semua efek soul
		local soulContainer = Instance.new("Part")
		soulContainer.Name = "GraspingSoulContainer"
		soulContainer.Size = Vector3.new(0.1, 0.1, 0.1)
		soulContainer.Transparency = 1
		soulContainer.Anchored = true
		soulContainer.CanCollide = false
		soulContainer.Position = soulPos
		soulContainer.Parent = workspace

		-- Efek aura spektral utama
		local soulAura = Instance.new("Part")
		soulAura.Name = "SoulAura"
		soulAura.Size = Vector3.new(4, 4, 4)
		soulAura.Shape = Enum.PartType.Ball
		soulAura.Material = Enum.Material.Neon
		soulAura.Color = Color3.fromRGB(138, 43, 226)
		soulAura.Anchored = true
		soulAura.CanCollide = false
		soulAura.Transparency = 0.3
		soulAura.Parent = soulContainer

		-- Efek cahaya spektral yang lebih dramatis
		local auraLight = Instance.new("PointLight")
		auraLight.Brightness = 25
		auraLight.Range = 15
		auraLight.Color = Color3.fromRGB(200, 150, 255)
		auraLight.Shadows = true
		auraLight.Parent = soulAura

		-- Efek partikel aura yang lebih kompleks
		local auraParticles = Instance.new("ParticleEmitter")
		auraParticles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(175, 100, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 255))
		})
		auraParticles.LightEmission = 0.9
		auraParticles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(0.5, 1.5),
			NumberSequenceKeypoint.new(1, 0.5)
		})
		auraParticles.Lifetime = NumberRange.new(1.5, 3)
		auraParticles.Rate = 80
		auraParticles.SpreadAngle = Vector2.new(180, 180)
		auraParticles.Speed = NumberRange.new(3, 8)
		auraParticles.Parent = soulAura

		-- Efek partikel orbital yang lebih kompleks
		local orbitParticles = Instance.new("ParticleEmitter")
		orbitParticles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 200, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 150, 255))
		})
		orbitParticles.LightEmission = 0.8
		orbitParticles.Size = NumberSequence.new(0.4, 1.2)
		orbitParticles.Lifetime = NumberRange.new(1, 2)
		orbitParticles.Rate = 50
		orbitParticles.Rotation = NumberRange.new(0, 360)
		orbitParticles.RotSpeed = NumberRange.new(-50, 50)
		orbitParticles.VelocitySpread = 180
		orbitParticles.Parent = soulAura

		-- Efek sinar energi internal
		local attachment1 = Instance.new("Attachment", soulAura)
		local attachment2 = Instance.new("Attachment", soulAura)
		attachment1.Position = Vector3.new(-2, 0, 0)
		attachment2.Position = Vector3.new(2, 0, 0)

		-- Animasikan semua efek
		coroutine.wrap(function()
			local startTime = time()
			while time() - startTime < telegraphDuration do
				local t = time() - startTime
				local progress = t / telegraphDuration

				-- Pulsasi aura utama
				local pulse = 0.8 + math.sin(t * 10) * 0.2
				soulAura.Size = Vector3.new(4, 4, 4) * pulse
				auraLight.Brightness = 25 * pulse
				soulAura.Transparency = 0.2 + math.sin(t * 8) * 0.15

				-- Animasi warna dinamis
				local hue = (t * 0.3) % 1
				soulAura.Color = Color3.fromHSV(hue, 0.8, 1)
				auraLight.Color = Color3.fromHSV(hue, 0.6, 1)

				-- Rotasi halus
				soulAura.CFrame = CFrame.new(soulPos) * CFrame.Angles(0, t * 2, 0)

				RunService.Heartbeat:Wait()
			end

			-- Fade out sebelum menghilang
			local fadeTween = TweenService:Create(soulContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
				Transparency = 1
			})
			fadeTween:Play()
			Debris:AddItem(soulContainer, 0.6)
		end)()

		-- Efek suara telegraph
		AudioManager.playSound("Boss.Alert", soulContainer, {Volume = 0.6})

		table.insert(souls, soulContainer)
	end

	return souls
end

-- Fungsi untuk membuat Grasping Soul yang lebih realistis dan imersif
function Boss3VFXModule.CreateGraspingSoul(startPosition, config)
	-- Container utama untuk semua efek soul
	local soulContainer = Instance.new("Part")
	soulContainer.Name = "GraspingSoul"
	soulContainer.Size = Vector3.new(3, 3, 3)
	soulContainer.Shape = Enum.PartType.Ball
	soulContainer.Material = Enum.Material.Glass
	soulContainer.Color = Color3.fromRGB(138, 43, 226)
	soulContainer.CanCollide = false
	soulContainer.Anchored = false
	soulContainer.Position = startPosition
	soulContainer.Transparency = 0.3
	soulContainer.Parent = workspace

	-- Efek cahaya utama
	local mainLight = Instance.new("PointLight")
	mainLight.Brightness = 15
	mainLight.Range = 20
	mainLight.Color = Color3.fromRGB(200, 150, 255)
	mainLight.Shadows = true
	mainLight.Parent = soulContainer

	-- Trail yang lebih kompleks
	local trail = Instance.new("Trail")
	local attachment0 = Instance.new("Attachment", soulContainer)
	local attachment1 = Instance.new("Attachment", soulContainer)
	attachment1.Position = Vector3.new(0, 0, -1.5)
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(175, 100, 255)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(200, 150, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(138, 43, 226))
	})
	trail.Lifetime = 2
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(0.5, 2.5),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	trail.LightEmission = 0.9
	trail.FaceCamera = true
	trail.Parent = soulContainer

	-- Efek suara untuk soul
	local sound = AudioManager.createSound("Boss.Alert", soulContainer, {Volume = 0.7, Looped = true})
	if sound then sound:Play() end

	-- Sinar energi internal yang kompleks
	local beamAttach1 = Instance.new("Attachment", soulContainer)
	local beamAttach2 = Instance.new("Attachment", soulContainer)
	beamAttach1.Position = Vector3.new(0, -1.5, 0)
	beamAttach2.Position = Vector3.new(0, 1.5, 0)

	local internalBeam = Instance.new("Beam")
	internalBeam.Attachment0 = beamAttach1
	internalBeam.Attachment1 = beamAttach2
	internalBeam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 180, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
	})
	internalBeam.FaceCamera = true
	internalBeam.LightEmission = 1
	internalBeam.LightInfluence = 0
	internalBeam.Transparency = NumberSequence.new(0.2)
	internalBeam.Width0 = 0.5
	internalBeam.Width1 = 0.5
	internalBeam.CurveSize0 = 1.5
	internalBeam.CurveSize1 = 1.5
	internalBeam.Segments = 25
	internalBeam.TextureMode = Enum.TextureMode.Wrap
	internalBeam.TextureSpeed = 5
	internalBeam.Parent = soulContainer

	-- Sistem partikel orbital yang lebih kompleks
	coroutine.wrap(function()
		local orbitingParts = {}
		local numOrbits = 12
		local baseOrbitRadius = 4

		-- Buat partikel orbital
		for i = 1, numOrbits do
			local orbitPart = Instance.new("Part")
			orbitPart.Name = "OrbitParticle"
			orbitPart.Size = Vector3.new(0.8, 0.8, 0.8)
			orbitPart.Shape = Enum.PartType.Ball
			orbitPart.Material = Enum.Material.Neon
			orbitPart.Color = Color3.fromRGB(220, 200, 255)
			orbitPart.Anchored = true
			orbitPart.CanCollide = false
			orbitPart.Parent = soulContainer

			-- Trail untuk partikel orbital
			local orbitTrail = Instance.new("Trail")
			local trailAttach = Instance.new("Attachment", orbitPart)
			orbitTrail.Attachment0 = trailAttach
			orbitTrail.Color = ColorSequence.new(orbitPart.Color)
			orbitTrail.Lifetime = 0.8
			orbitTrail.LightEmission = 0.7
			orbitTrail.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1)
			})
			orbitTrail.WidthScale = NumberSequence.new(0.5, 0.1)
			orbitTrail.Parent = orbitPart

			table.insert(orbitingParts, orbitPart)
		end

		-- Animasi orbital
		while soulContainer and soulContainer.Parent do
			local t = time()
			for i, orbitPart in ipairs(orbitingParts) do
				if not orbitPart.Parent then continue end

				local orbitSpeed = 3 + (i % 3) * 1.5
				local orbitRadius = baseOrbitRadius + math.sin(t * 0.5 + i) * 1.5
				local orbitType = i % 3

				local angle = t * orbitSpeed + (i / numOrbits) * math.pi * 2
				local offset

				if orbitType == 1 then -- Orbit horizontal
					offset = Vector3.new(math.cos(angle) * orbitRadius, math.sin(angle) * orbitRadius * 0.3, math.sin(angle) * orbitRadius)
				elseif orbitType == 2 then -- Orbit vertikal
					offset = Vector3.new(math.cos(angle) * orbitRadius * 0.5, math.sin(angle) * orbitRadius, math.sin(angle) * orbitRadius * 0.5)
				else -- Orbit spiral
					offset = Vector3.new(
						math.cos(angle) * orbitRadius * 0.7,
						math.sin(t * 4 + i) * 2,
						math.sin(angle) * orbitRadius * 0.7
					)
				end

				orbitPart.Position = soulContainer.Position + offset
				orbitPart.Color = Color3.fromHSV((t * 0.2 + i/numOrbits) % 1, 0.8, 1)
			end
			RunService.Heartbeat:Wait()
		end

		-- Cleanup
		for _, part in ipairs(orbitingParts) do
			if part.Parent then
				part:Destroy()
			end
		end
	end)()

	-- Animasi utama soul
	coroutine.wrap(function()
		local startTime = time()
		local originalSize = soulContainer.Size

		while soulContainer and soulContainer.Parent do
			local t = time() - startTime

			-- Pulsasi ukuran
			local pulse = 0.9 + math.sin(t * 8) * 0.1
			soulContainer.Size = originalSize * pulse

			-- Pulsasi cahaya
			mainLight.Brightness = 15 + math.sin(t * 10) * 5

			-- Perubahan warna dinamis
			local hue = (t * 0.15) % 1
			soulContainer.Color = Color3.fromHSV(hue, 0.8, 1)
			mainLight.Color = Color3.fromHSV(hue, 0.6, 1)

			-- Animasi transparansi
			soulContainer.Transparency = 0.2 + math.sin(t * 6) * 0.15

			-- Animasi beam internal
			internalBeam.Width0 = 0.4 + math.sin(t * 12) * 0.1
			internalBeam.Width1 = 0.4 + math.cos(t * 12) * 0.1
			internalBeam.Transparency = NumberSequence.new(0.1 + math.sin(t * 10) * 0.1)

			-- Rotasi halus
			soulContainer.CFrame = soulContainer.CFrame * CFrame.Angles(
				math.rad(math.sin(t * 0.7) * 0.5),
				math.rad(t * 3),
				math.rad(math.cos(t * 0.9) * 0.5)
			)

			RunService.Heartbeat:Wait()
		end
	end)()

	return soulContainer
end

-- Fungsi untuk membuat efek ledakan dan debuff Soul Taint yang lebih dramatis
function Boss3VFXModule.CreateSoulExplosion(position, radius)
	-- Container untuk efek ledakan
	local explosionContainer = Instance.new("Part")
	explosionContainer.Name = "SoulExplosionContainer"
	explosionContainer.Size = Vector3.new(0.1, 0.1, 0.1)
	explosionContainer.Transparency = 1
	explosionContainer.Anchored = true
	explosionContainer.CanCollide = false
	explosionContainer.Position = position
	explosionContainer.Parent = workspace

	-- Flash utama
	local mainFlash = Instance.new("Part")
	mainFlash.Name = "MainFlash"
	mainFlash.Size = Vector3.new(1, 1, 1)
	mainFlash.Shape = Enum.PartType.Ball
	mainFlash.Material = Enum.Material.Neon
	mainFlash.Color = Color3.fromRGB(255, 255, 255)
	mainFlash.Anchored = true
	mainFlash.CanCollide = false
	mainFlash.Transparency = 0
	mainFlash.Position = position
	mainFlash.Parent = explosionContainer

	local flashLight = Instance.new("PointLight")
	flashLight.Brightness = 80
	flashLight.Range = radius * 3
	flashLight.Color = Color3.fromRGB(220, 200, 255)
	flashLight.Shadows = true
	flashLight.Parent = mainFlash

	-- Shockwave visual
	local shockwave = Instance.new("Part")
	shockwave.Name = "Shockwave"
	shockwave.Size = Vector3.new(0.2, 0.2, 0.2)
	shockwave.Shape = Enum.PartType.Cylinder
	shockwave.Material = Enum.Material.Neon
	shockwave.Color = Color3.fromRGB(200, 150, 255)
	shockwave.Anchored = true
	shockwave.CanCollide = false
	shockwave.Transparency = 1
	shockwave.CFrame = CFrame.new(position) * CFrame.Angles(math.pi/2, 0, 0)
	shockwave.Parent = explosionContainer

	-- Animasi ledakan
	coroutine.wrap(function()
		-- Ekspansi shockwave
		local shockwaveTween = TweenService:Create(shockwave, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(radius * 2, 0.2, radius * 2),
			Transparency = 1
		})
		shockwaveTween:Play()

		-- Fade flash
		local flashTween = TweenService:Create(mainFlash, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Transparency = 1,
			Size = Vector3.new(radius * 0.5, radius * 0.5, radius * 0.5)
		})
		flashTween:Play()

		local lightTween = TweenService:Create(flashLight, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Brightness = 0
		})
		lightTween:Play()

		-- Tunggu animasi selesai lalu bersihkan
		wait(1.5)
		if explosionContainer.Parent then
			explosionContainer:Destroy()
		end
	end)()

	-- Efek suara ledakan
	local explosionSound = AudioManager.playSound("Boss.Complete", explosionContainer, {Volume = 1})

	-- Efek suara bass
	local bassSound = AudioManager.createSound("Boss.Bass", explosionContainer, {Volume = 0.8})
	delay(0.05, function()
		if bassSound then bassSound:Play() end
	end)

	return explosionContainer
end

-- Fungsi untuk membersihkan Grasping Soul dengan benar
function Boss3VFXModule.CleanupGraspingSoul(soul)
	if soul and soul.Parent then
		-- Hentikan suara jika ada
		local sound = soul:FindFirstChildOfClass("Sound")
		if sound then
			sound:Stop()
		end

		-- Buat efek fade out sebelum menghancurkan
		local fadeTween = TweenService:Create(soul, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			Transparency = 1,
			Size = Vector3.new(0.1, 0.1, 0.1)
		})
		fadeTween:Play()

		-- Hancurkan setelah fade
		Debris:AddItem(soul, 0.4)
	end
end

return Boss3VFXModule
