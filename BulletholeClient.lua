-- BulletholeClient.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/BulletholeClient.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local BulletholeEvent = RemoteEvents:WaitForChild("BulletholeEvent")

-- Fungsi untuk membuat bullethole yang realistis
-- === Bullet hole manual realistis, tanpa rbxasset ===
local function createBullethole(position, normal)
	-- parameter dasar
	local THICKNESS = 0.035   -- ketebalan “stiker” 3D
	local R_INNER   = 0.045   -- radius inti hitam (lubang)
	local R_OUTER   = 0.08    -- radius ring retakan/lekukan
	local TTL       = 6       -- detik, auto-bersih semua efek

	-- kecilkan penetrasi ke permukaan agar tidak z-fighting
	local pos = position + normal * (THICKNESS * 0.5)

	-- helper: sejajarkan sumbu Y part ke arah normal
	local function alignYToNormal(p, n)
		n = n.Unit
		local y = Vector3.new(0,1,0)
		local dot = y:Dot(n)
		if dot > 0.999 then
			return CFrame.new(p)
		elseif dot < -0.999 then
			return CFrame.new(p) * CFrame.Angles(math.rad(180),0,0)
		else
			local axis = y:Cross(n).Unit
			local ang  = math.acos(math.clamp(dot, -1, 1))
			return CFrame.new(p) * CFrame.fromAxisAngle(axis, ang)
		end
	end

	-- folder pengelompokan agar rapi + mudah dibersihkan
	local folder = Instance.new("Folder")
	folder.Name = "BulletImpact"
	folder.Parent = workspace

	-- bagian inti: silinder tipis kecil (hitam pekat)
	local core = Instance.new("Part")
	core.Name = "HoleCore"
	core.Shape = Enum.PartType.Cylinder
	core.Size = Vector3.new(R_INNER * 2, THICKNESS, R_INNER * 2)
	core.Anchored = true
	core.CanCollide = false
	core.Material = Enum.Material.SmoothPlastic
	core.Color = Color3.fromRGB(0, 0, 0)
	core.TopSurface = Enum.SurfaceType.Smooth
	core.BottomSurface = Enum.SurfaceType.Smooth
	core.CFrame = alignYToNormal(pos, normal) * CFrame.Angles(0, math.rad(math.random(0,359)), 0)
	core.Parent = folder

	-- ring luar: silinder lebih besar, abu-abu gelap agak transparan → efek bekas retak
	local ring = Instance.new("Part")
	ring.Name = "HoleRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(R_OUTER * 2, math.max(THICKNESS * 0.6, 0.02), R_OUTER * 2)
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.SmoothPlastic
	ring.Color = Color3.fromRGB(30, 30, 30)
	ring.Transparency = 0.2
	ring.TopSurface = Enum.SurfaceType.Smooth
	ring.BottomSurface = Enum.SurfaceType.Smooth
	ring.CFrame = core.CFrame * CFrame.new(0, -THICKNESS*0.15, 0) -- sedikit menjorok
	ring.Parent = folder

	-- kilatan singkat saat tumbukan
	local flash = Instance.new("PointLight")
	flash.Brightness = 2.5
	flash.Range = 6
	flash.Color = Color3.fromRGB(255, 200, 120)
	flash.Parent = core
	task.spawn(function()
		flash.Brightness = 2.5
		task.wait(0.04)
		flash.Brightness = 0
		flash.Enabled = false
	end)

	-- attachment untuk partikel
	local att = Instance.new("Attachment")
	att.Name = "ImpactAttachment"
	att.Parent = core

	-- debu (abu-abu) — tanpa texture khusus (default bawaan emitter)
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "Dust"
	dust.Speed = NumberRange.new(2, 6)
	dust.SpreadAngle = Vector2.new(15, 15)
	dust.Lifetime = NumberRange.new(0.18, 0.35)
	dust.Rate = 0
	dust.Rotation = NumberRange.new(0, 360)
	dust.RotSpeed = NumberRange.new(-90, 90)
	dust.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0.0, 0.15),
		NumberSequenceKeypoint.new(0.5, 0.08),
		NumberSequenceKeypoint.new(1.0, 0.0)
	}
	dust.Color = ColorSequence.new(Color3.fromRGB(130,130,130), Color3.fromRGB(70,70,70))
	dust.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0.0, 0.1),
		NumberSequenceKeypoint.new(1.0, 1.0)
	}
	dust.EmissionDirection = Enum.NormalId.Top
	dust.Parent = att
	dust:Emit(10)

	-- spark kecil (logam) — jumlah sedikit supaya hemat
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparks"
	sparks.Speed = NumberRange.new(10, 18)
	sparks.SpreadAngle = Vector2.new(8, 8)
	sparks.Lifetime = NumberRange.new(0.05, 0.12)
	sparks.Rate = 0
	sparks.LightEmission = 0.7
	sparks.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0.0, 0.06),
		NumberSequenceKeypoint.new(1.0, 0.0)
	}
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 200, 120), Color3.fromRGB(255, 120, 50))
	sparks.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0.0, 0.0),
		NumberSequenceKeypoint.new(1.0, 1.0)
	}
	sparks.EmissionDirection = Enum.NormalId.Top
	sparks.Parent = att
	sparks:Emit(4)

	-- pecahan kecil: 3 cube mungil terpental (tanpa asset), auto-hilang
	for i = 1, 3 do
		local chip = Instance.new("Part")
		chip.Name = "Chip"
		chip.Size = Vector3.new(0.02, 0.02, 0.02)
		chip.Color = Color3.fromRGB(50, 50, 50)
		chip.Material = Enum.Material.SmoothPlastic
		chip.Anchored = false
		chip.CanCollide = false
		chip.CFrame = core.CFrame * CFrame.new(0, THICKNESS*0.6, 0)
		chip.Parent = folder

		local v = Instance.new("BodyVelocity")
		v.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		-- dorong sedikit menjauh sepanjang normal plus variasi
		local rand = Vector3.new(
			math.random(-60,60)/600,
			math.random(0,80)/400,
			math.random(-60,60)/600
		)
		v.Velocity = normal.Unit * math.random(4,7) + rand
		v.Parent = chip

		-- sedikit putaran
		local ang = Instance.new("BodyAngularVelocity")
		ang.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
		ang.AngularVelocity = Vector3.new(
			math.random(-10,10),
			math.random(-10,10),
			math.random(-10,10)
		)
		ang.Parent = chip

		game:GetService("Debris"):AddItem(v, 0.1)
		game:GetService("Debris"):AddItem(ang, 0.15)
		game:GetService("Debris"):AddItem(chip, 0.6)
	end

	-- bersihkan semuanya
	Debris:AddItem(folder, TTL)
end

BulletholeEvent.OnClientEvent:Connect(function(position, normal)
	createBullethole(position, normal)
end)
