-- ZombieConfig.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/ZombieConfig.lua
-- Script Place: ACT 1: Village

local ZombieConfig = {}

ZombieConfig.BaseZombie = {
	MaxHealth = 100,
	WalkSpeed = 10,
	AttackDamage = 10,
	AttackCooldown = 1.5,
	IsZombie = true,
	AttackRange = 4  -- Ditambahkan
}

-- Per-type overrides
ZombieConfig.Types = {
	Runner = {
		MaxHealth = 60,
		WalkSpeed = 18,
		AttackDamage = 6,
		AttackCooldown = 1.0,
		Chance = 0.30,
		AttackRange = 4  -- Ditambahkan
	},
	Shooter = {
		MaxHealth = 120,
		WalkSpeed = 8,
		AttackDamage = 8,
		AttackCooldown = 1.5,
		ProjectileSpeed = 80,
		Acid = {
			PoolDuration = 8,
			DoT_Duration = 5,
			DoT_Tick = 1,
			DoT_DamagePerTick = 5
		},
		Chance = 0.25,
		AttackRange = 4  -- Ditambahkan
	},
	Tank = {
		MaxHealth = 10000,
		WalkSpeed = 6,
		AttackDamage = 25,
		AttackCooldown = 2.5,
		Chance = 0.10,
		AttackRange = 5  -- Ditambahkan
	},
	Boss = {
		MaxHealth = 75000,  -- Diperbesar untuk Boss
		WalkSpeed = 8,  -- Dipercepat sedikit
		AttackDamage = 50,
		AttackCooldown = 2.0,
		AttackRange = 25,  -- Ditambahkan (jarak besar untuk Boss raksasa)
		-- boss poison skill config
		Poison = {
			InitialCount = 4,
			Interval = 60,
			SinglePoisonPct = 0.40,
			Duration = 4,
			SpecialTimeout = 30,
			SpecialDuration = 10
		},
		-- radiasi (kolom sempit, vertikal tinggi)
		Radiation = {
			HorizontalRadius = 12,      -- radius kecil secara horizontal (XZ)
			VerticalHalfHeight = 200,   -- jangkauan ke atas & bawah (Y)
			DamagePerSecondPct = 0.01,  -- % dari MaxHealth per detik
			Tick = 0.5                  -- interval cek & tick damage
		},
		ChanceWaveMin = 10,
		ChanceWaveMax = 15,
		ChanceToSpawn = 1
	},
	Boss2 = {
		MaxHealth = 100000,  -- Diperbesar untuk Boss
		WalkSpeed = 8,  -- Dipercepat sedikit
		AttackDamage = 50,
		AttackCooldown = 2.0,
		AttackRange = 25,  -- Ditambahkan (jarak besar untuk Boss raksasa)

		-- Timer wajib (wipe out bila habis)
		SpecialTimeout = 300, -- detik

		-- Radiasi (radius kecil, vertikal tinggi; jangan dihilangkan)
		Radiation = {
			Tick = 0.5,
			HorizontalRadius = 6,       -- kecil
			VerticalHalfHeight = 1000,  -- kolom tinggi
			DamagePerSecondPct = 0.01
		},

		-- FOLLOW CLOUD: ubah jadi Gravity Well (BUKAN POISON)
		Gravity = {
			Interval = 150,        -- tiap 15 detik spawn well di atas target
			Duration = 6,
			Radius = 10,          -- area efek
			PullForce = 500        -- tarikan ke pusat well (opsional)
		},

		-- Mekanik KOOPERASI 4 PEMAIN @50% HP
		Coop = {
			TriggerHPPercent = 0.5,
			RequiredPlayers = 4,       -- akan dipakai min(#Players, 4)
			Duration = 20,             -- detik
			FailDR = 0.50,             -- Damage Reduction 50% kalau gagal
			FailDRDuration = 30        -- detik
		},
		-- GRAVITY SLAM (telegraph -> implode -> explode)
		GravitySlam = {
			Cooldown = 10,           -- jeda antar slam (detik)
			TelegraphTime = 3,       -- durasi cincin warning sebelum meledak
			Radius = 50,             -- jari-jari area slam (XZ)
			ImplodeDuration = 0.3,   -- durasi hisap singkat
			ImplodeForce = 500,     -- kekuatan tarikan (implosion)
			ExplodeForce = 300,     -- kekuatan dorong (explosion)
			DamagePct = 0.15,        -- persentase MaxHealth pemain sebagai damage
		},
		-- Spawn window & chance
		ChanceWaveMin = 30,
		ChanceWaveMax = 35,
		ChanceToSpawn = 0.3,
	},
	Boss3 = {
		-- “Maestro Nekrosis”
		MaxHealth = 125000,
		WalkSpeed = 8,
		AttackDamage = 55,
		AttackCooldown = 2.0,
		AttackRange = 25,
		SpecialTimeout = 300, -- wajib: waktu habis -> wipe out

		-- Radiasi kecil (dipertahankan)
		Radiation = {
			Tick = 0.5,
			HorizontalRadius = 6,       -- kecil
			VerticalHalfHeight = 1000,  -- kolom tinggi
			DamagePerSecondPct = 0.01
		},
		-- Tidak pakai ChanceWaveMin/Max karena dipaksa spawn di wave 50

		-- MEKANIK BARU: MIRROR QUARTET
		MirrorQuartet = {
			TriggerHPPercent = 0.5,
			RequiredPlayers = 4,
			Duration = 30,
			SuccessLockTime = 3,
			FailDR = 0.5,
			FailDRDuration = 30
		},

		-- MEKANIK BARU: CHROMATIC REQUIEM
		ChromaticRequiem = {
			TriggerHPPercent = 0.25,
			Duration = 30,
			FailDR = 0.5,
			FailDRDuration = 30,
			SuccessStunDuration = 5
		},

		-- SERANGAN BIASA BARU: Corrupting Blast
		CorruptingBlast = {
			Cooldown = 10,              -- Jeda antar serangan dalam detik
			TelegraphDuration = 1.5,    -- Durasi tanda di tanah sebelum meledak
			BlastRadius = 15,           -- Radius ledakan awal
			BlastDamage = 15,           -- Damage ledakan awal (flat)
			PuddleDuration = 3,         -- Durasi genangan korup di tanah
			PuddleDamagePerTick = 5,    -- Damage setiap tick dari genangan
			PuddleTickInterval = 0.5    -- Seberapa sering genangan memberikan damage
		},

		-- SERANGAN BIASA BARU: Grasping Souls
		GraspingSouls = {
			Cooldown = 15,              -- Jeda antar serangan
			TelegraphDuration = 1.5,    -- Waktu peringatan sebelum bola ditembakkan
			SoulCount = {2, 3},         -- Jumlah bola arwah yang akan ditembakkan (min, max)
			SoulHP = 30,                -- HP setiap bola arwah
			SoulSpeed = 12,             -- Kecepatan bola arwah mengejar pemain
			BlastRadius = 8,            -- Radius ledakan saat mengenai pemain
			BlastDamage = 25,           -- Damage ledakan
			DebuffDuration = 6,         -- Durasi debuff "Soul Taint"
			DebuffSlowPct = 0.5         -- Pengurangan kecepatan gerak (50%)
		}
	},
}

return ZombieConfig
