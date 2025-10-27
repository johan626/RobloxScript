-- SkillConfig.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/SkillConfig.lua
-- Script Place: Lobby & ACT 1: Village

local SkillConfig = {
	HeadshotDamage = {
		Name = "Headshot Damage",
		Description = "Meningkatkan damage dari headshot.",
		MaxLevel = 5,
		-- Properti kustom bisa ditambahkan di sini sesuai kebutuhan skill
		DamagePerLevel = 1
	},
	DamageBoss = {
		Name = "Damage Boss",
		Description = "Meningkatkan damage terhadap boss.",
		MaxLevel = 10,
		DamagePerLevel = 1
	},
	MaxHealth = {
		Name = "Max Health",
		Description = "Meningkatkan HP maksimal pemain.",
		MaxLevel = 20,
		HPPerLevel = 1
	},
	MaxStamina = {
		Name = "Max Stamina",
		Description = "Meningkatkan stamina maksimal pemain.",
		MaxLevel = 20,
		StaminaPerLevel = 1
	},
	WeaponSpecialist = {
		Name = "Weapon Specialist",
		Description = "Meningkatkan damage untuk tipe senjata tertentu.",
		MaxLevel = 5, -- Max level per kategori
		DamagePerLevel = 1,
		IsCategorized = true,
		Categories = {
			Pistol = "Pistol",
			AssaultRifle = "Assault Rifle",
			SMG = "SMG",
			Shotgun = "Shotgun",
			Sniper = "Sniper",
			LMG = "LMG"
		}
	},
	GreedGash = {
		Name = "Greed Gash",
		Description = "Memberikan peluang untuk mendapatkan bonus BP setiap kali berhasil membunuh zombie.",
		MaxLevel = 5,
		ChancePerLevel = 3, -- Peluang dalam persen (3% per level)
		BonusAmount = 50
	}
}

return SkillConfig
