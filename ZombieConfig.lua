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
		Name = "Plague Titan",
		MaxHealth = 75000,
		WalkSpeed = 8,
		AttackDamage = 50, -- Serangan melee standar jika pemain terlalu dekat
		AttackRange = 8,
		SpecialTimeout = 300, -- Timer pemusnahan tetap ada

		-- FASE 1 & 2
		Radiation = {
			Phase1Radius = 15,
			Phase2Radius = 25, -- Aura mengembang di Fase 2
			VerticalHalfHeight = 200,
			DamagePerSecondPct = 0.01,
			Tick = 0.5
		},

		-- FASE 1
		CorrosiveSlam = {
			Cooldown = 12,
			Damage = 30,
			Radius = 40,
			TelegraphDuration = 1.5,
			WaveSpeed = 80,
		},
		ToxicLob = {
			Cooldown = 8,
			PuddleDuration = 15,
			PuddleDamagePerTick = 5,
			PuddleTickInterval = 0.5,
			PuddleRadius = 12,
			TelegraphDuration = 1,
		},

		-- TRANSISI
		PhaseTransition = {
			TriggerHPPercent = 0.5,
			RoarDuration = 3,
		},

		-- FASE 2
		VolatileMinions = {
			Cooldown = 25,
			SpawnCount = {2, 3}, -- min, max
			MinionType = "Runner", -- Akan menggunakan stats Runner tapi mungkin dengan HP lebih rendah
			ExplosionRadius = 15,
			ExplosionDamage = 25,
		},
		FissionBarrage = {
			Cooldown = 40,
			ProjectileCount = 4,
			IntervalBetweenShots = 0.5,
		},

		ChanceWaveMin = 10,
		ChanceWaveMax = 15,
		ChanceToSpawn = 1
	},
	Boss2 = {
		Name = "Void Ascendant",
		MaxHealth = 100000,
		WalkSpeed = 8,
		AttackDamage = 50,
		AttackRange = 25,
		SpecialTimeout = 300,

		-- FASE 1
		OrbOfAnnihilation = {
			Cooldown = 15,
			OrbSpeed = 20,
			Lifetime = 20,
			ExplosionRadius = 15,
			ExplosionDamage = 40,
		},

		-- TRANSISI
		Upheaval = {
			TriggerHPPercent = 0.5,
			Duration = 5, -- Durasi animasi platform naik
			PlatformCount = 5,
			PlatformSize = Vector3.new(30, 100, 30),
			ArenaRadius = 80,
		},

		-- FASE 2
		PlatformShatter = {
			Cooldown = 20,
			TelegraphDuration = 2,
			Damage = 30,
		},
		DualOrbSummon = {
			Cooldown = 25,
		},
		CelestialRain = {
			Cooldown = 45,
			ProjectileCount = 10,
			Interval = 0.5,
			BlastRadius = 10,
			BlastDamage = 25,
			TelegraphDuration = 1,
		},

		ChanceWaveMin = 30,
		ChanceWaveMax = 35,
		ChanceToSpawn = 0.3,
	},
	Boss3 = {
		Name = "Maestro of Necrosis",
		MaxHealth = 125000,
		WalkSpeed = 8,
		AttackDamage = 55,
		AttackRange = 25,
		SpecialTimeout = 300,

		-- Gerakan Orkestra
		Movements = {
			Duration = {min = 20, max = 30}, -- Berapa lama setiap gerakan berlangsung
			-- Gerakan 1: Allegro of Souls
			Allegro = {
				SoulStream = {
					Cooldown = 8,
					ProjectileSpeed = 60,
					ProjectileCount = 15,
					Interval = 0.2,
					Damage = 10,
				},
				NecroticEruption = {
					Cooldown = 12,
					PillarCount = 5,
					Radius = 8,
					Damage = 25,
					TelegraphDuration = 1.5,
				},
			},
			-- Gerakan 2: Adagio of Corruption
			Adagio = {
				CorruptingBlast = {
					Cooldown = 10,
					BlastRadius = 15,
					BlastDamage = 15,
					PuddleDuration = 10,
					PuddleDamagePerTick = 5,
					PuddleTickInterval = 0.5,
					TelegraphDuration = 1.5,
				},
				ChainsOfTorment = {
					Cooldown = 18,
					Duration = 12,
					MaxDistance = 40,
					DamagePerSecond = 10,
				},
			},
			-- Gerakan 3: Fortissimo of the Damned
			Fortissimo = {
				EchoesOfTheMaestro = {
					Cooldown = 25,
					EchoHealth = 5000,
					MaxEchoes = 3, -- 1 gema per 2 pemain, maks 3
				},
				CrescendoOfSouls = {
					Cooldown = 40,
					ChargeDuration = 5,
					Damage = 100,
				},
			},
		},
	},
}

return ZombieConfig
