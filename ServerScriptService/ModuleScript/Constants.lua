-- Constants.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/Constants.lua
-- Deskripsi: Modul ini menyimpan semua konstanta, string, dan path penting dalam game.

local Constants = {}

-- Nama Event
Constants.Events = {
	-- Remote Events
	MISSION_COMPLETE = "MissionCompleteEvent",
	GAME_SETTINGS_UPDATE = "GameSettingsUpdateEvent",
	SPECIAL_WAVE_ALERT = "SpecialWaveAlertEvent",
	WAVE_COUNTDOWN = "WaveCountdownEvent",
	PLAYER_COUNT = "PlayerCountEvent",
	OPEN_START_UI = "OpenStartUIEvent",
	READY_COUNT = "ReadyCountEvent",
	RESTART_GAME = "RestartGameEvent",
	START_GAME = "StartGameEvent",
	EXIT_GAME = "ExitGameEvent",
	WAVE_UPDATE = "WaveUpdateEvent",
	START_VOTE_COUNTDOWN = "StartVoteCountdownEvent",
	START_VOTE_CANCELED = "StartVoteCanceledEvent",
	CANCEL_START_VOTE = "CancelStartVoteEvent",
	GAME_OVER = "GameOverEvent",
	KNOCK = "KnockEvent",
	REVIVE = "ReviveEvent",
	REVIVE_PROGRESS = "ReviveProgressEvent",
	CANCEL_REVIVE = "CancelReviveEvent",
	GLOBAL_KNOCK_NOTIFICATION = "GlobalKnockNotificationEvent",
	PING_KNOCKED_PLAYER = "PingKnockedPlayerEvent",
	SHOOT = "ShootEvent",
	RELOAD = "ReloadEvent",
	AMMO_UPDATE = "AmmoUpdateEvent",
	HITMARKER = "HitmarkerEvent",
	BULLETHOLE = "BulletholeEvent",
	DAMAGE_DISPLAY = "DamageDisplayEvent",
	BOSS_TIMER = "BossTimerEvent",
	BOSS_INCOMING = "BossIncoming",
	SPRINT = "SprintEvent",
	STAMINA_UPDATE = "StaminaUpdate",
	JUMP = "JumpEvent",
	GACHA_SKIN_WON = "GachaSkinWonEvent",

	-- Bindable Events
	ZOMBIE_DIED = "ZombieDiedEvent",
	REPORT_DAMAGE = "ReportDamageEvent",
}

-- Nama Atribut
Constants.Attributes = {
	IMMUNE = "Immune",
	MECHANIC_FREEZE = "MechanicFreeze",
	ATTACK_RANGE = "AttackRange",
	ATTACK_DAMAGE = "AttackDamage",
	IS_ZOMBIE = "IsZombie",
	IS_BOSS = "IsBoss",
	STUNNED = "Stunned",
	ATTACKING = "Attacking",
	DAMAGE_REDUCTION_PCT = "DamageReductionPct",
	KNOCKED = "Knocked",
	IS_SHOOTING = "IsShooting",
	IS_RELOADING = "IsReloading",
	IS_USING_BOOSTER = "IsUsingBooster",
	RATE_BOOST = "RateBoost",
	WEAPON_ID = "WeaponId",
	UPGRADE_LEVEL = "UpgradeLevel",
	CUSTOM_MAX_AMMO = "CustomMaxAmmo",
	CUSTOM_RESERVE_AMMO = "CustomReserveAmmo",
	AMMO_LISTENER_ATTACHED = "_AmmoListenerAttached",
	EXPLOSIVE_ROUNDS_BOOST = "ExplosiveRoundsBoost",
	IS_SPRINTING = "IsSprinting",
	STAMINA_BOOST = "StaminaBoost",
	REVIVE_BOOST = "ReviveBoost",
	MEDIC_BOOST = "MedicBoost",
	KNOCK_COUNT = "KnockCount",
	TEMPORARY_DROP = "TemporaryDrop",
	IS_DROP = "IsDrop",
}

-- String dan Nilai Lainnya
Constants.Strings = {
	GAME_MODE_STORY = "Story",
	DIFFICULTY_EASY = "Easy",
	CHAMS_HIGHLIGHT = "ChamsHighlight",
	COIN_BOOSTER_1GAME = "COIN_BOOSTER_1GAME",
	XP_BOOSTER_30MIN = "XP_BOOSTER_30MIN",
	STARTER_POINTS_BOOSTER = "StarterPoints",
	STARTING_SHIELD_BOOSTER = "StartingShield",
	SELF_REVIVE_BOOSTER = "SelfRevive",
	DIFFICULTY_CRAZY = "Crazy",
	LOBBY_PLACE = "Lobby",
}

return Constants
