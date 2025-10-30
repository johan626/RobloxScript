-- WeaponManager.lua (Script)
-- Path: ServerScriptService/Script/WeaponManager.lua
-- Script Place: ACT 1: Village

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local GameConfig = require(ModuleScriptServerScriptService:WaitForChild("GameConfig"))
local GameStatus = require(ModuleScriptServerScriptService:WaitForChild("GameStatus"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))
local ElementModule = require(ModuleScriptServerScriptService:WaitForChild("ElementConfigModule"))
local CoinsManager = require(ModuleScriptServerScriptService:WaitForChild("CoinsModule"))
local SkillModule = require(ModuleScriptServerScriptService:WaitForChild("SkillModule"))
local SkillConfig = require(ModuleScriptReplicatedStorage:WaitForChild("SkillConfig"))
local StatsModule = require(ModuleScriptServerScriptService:WaitForChild("StatsModule"))
local MissionManager = require(ModuleScriptServerScriptService:WaitForChild("MissionManager"))

local ShootEvent = RemoteEvents:WaitForChild("ShootEvent")
local ReloadEvent = RemoteEvents:WaitForChild("ReloadEvent")
local AmmoUpdateEvent = RemoteEvents:WaitForChild("AmmoUpdateEvent")
local HitmarkerEvent = RemoteEvents:WaitForChild("HitmarkerEvent")
local BulletholeEvent = RemoteEvents:WaitForChild("BulletholeEvent")
local DamageDisplayEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("DamageDisplayEvent") or Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
DamageDisplayEvent.Name = "DamageDisplayEvent"

-- Anti-spam tembak: catat waktu tembak terakhir per-player per-senjata
local lastFireTime = {}

local playerAmmo = {}
local playerReserveAmmo = {}

local function applyDamageAndStats(player, targetHumanoid, hitModel, damage, isHeadshot, weaponName)
	if damage <= 0 then return end

	local isZombie = hitModel:FindFirstChild("IsZombie")
	local targetPlayer = game.Players:GetPlayerFromCharacter(hitModel)

	-- Jika bukan zombie atau pemain, abaikan
	if not isZombie and not targetPlayer then return end

	-- Cek kondisi friendly fire
	if targetPlayer and targetPlayer ~= player then
		local currentDifficulty = GameStatus:GetDifficulty()
		local difficultyRules = GameConfig.Difficulty[currentDifficulty] and GameConfig.Difficulty[currentDifficulty].Rules
		if not (difficultyRules and difficultyRules.FriendlyFire) then
			return -- Friendly fire tidak aktif, jangan beri damage
		end
	end

	local finalDamage = damage
	-- Terapkan efek elemental dan reduksi damage hanya pada zombie
	if isZombie then
		finalDamage = ElementModule.OnPlayerHit(player, hitModel, damage) or damage
		if hitModel:GetAttribute("Immune") then
			finalDamage = 0
		else
			local dr = hitModel:GetAttribute("DamageReductionPct") or 0
			finalDamage = finalDamage * (1 - math.clamp(dr, 0, 0.95))
		end
	end

	if finalDamage <= 0 then return end

	targetHumanoid:TakeDamage(finalDamage)

	-- Update statistik, poin, dan creator tag hanya untuk zombie
	if isZombie then
		StatsModule.AddTotalDamage(player, finalDamage)
		StatsModule.AddWeaponDamage(player, weaponName, finalDamage)
		PointsSystem.AddDamage(player, finalDamage)
		CoinsManager.AddCoins(player, math.floor(finalDamage))
		DamageDisplayEvent:FireAllClients(finalDamage, hitModel, isHeadshot)

		-- Handle creator tag for kill credit
		local creatorTag = hitModel:FindFirstChild("creator")
		if not creatorTag then
			creatorTag = Instance.new("StringValue")
			creatorTag.Name = "creator"
			creatorTag.Parent = hitModel
		end

		local existingData = {}
		if creatorTag.Value and creatorTag.Value ~= "" then
			local success, result = pcall(HttpService.JSONDecode, HttpService, creatorTag.Value)
			if success and typeof(result) == "table" then
				existingData = result
			end
		end

		if not existingData.IsHeadshot or isHeadshot then
			local weaponDisplayName = (WeaponModule.Weapons[weaponName] and WeaponModule.Weapons[weaponName].DisplayName) or weaponName
			local creatorData = {
				Player = player.UserId,
				WeaponType = weaponDisplayName,
				IsHeadshot = existingData.IsHeadshot or isHeadshot
			}
			creatorTag.Value = HttpService:JSONEncode(creatorData)
		end
	end

	return finalDamage
end

local function handleExplosion(player, position, hitModel)
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastRadius = 8
	explosion.BlastPressure = 0
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = workspace

	local zombiesInRadius = workspace:GetPartBoundsInRadius(explosion.Position, explosion.BlastRadius)
	for _, part in ipairs(zombiesInRadius) do
		local nearbyModel = part:FindFirstAncestorOfClass("Model")
		if nearbyModel and nearbyModel:FindFirstChild("IsZombie") and nearbyModel ~= hitModel then
			local nearbyHumanoid = nearbyModel:FindFirstChild("Humanoid")
			if nearbyHumanoid and nearbyHumanoid.Health > 0 then
				nearbyHumanoid:TakeDamage(25)
				PointsSystem.AddDamage(player, 25)
				CoinsManager.AddCoins(player, 25)
				DamageDisplayEvent:FireAllClients(25, nearbyModel, false)
			end
		end
	end
end

local function ensureToolHasId(tool)
	if not tool then return nil end
	if not tool:GetAttribute("WeaponId") then
		tool:SetAttribute("WeaponId", HttpService:GenerateGUID(false))
	end
	return tool:GetAttribute("WeaponId")
end

local function setupToolAmmoForPlayer(player, tool)
	if not tool or not tool:IsA("Tool") then return end
	local weaponName = tool.Name
	if not WeaponModule.Weapons[weaponName] then return end
	local id = ensureToolHasId(tool)
	if not id then return end
	playerAmmo[player] = playerAmmo[player] or {}
	playerReserveAmmo[player] = playerReserveAmmo[player] or {}

	local weaponStats = WeaponModule.Weapons[weaponName]
	local defaultMax = weaponStats and weaponStats.MaxAmmo or 0
	local defaultReserve = weaponStats and weaponStats.ReserveAmmo or 0

	local customMax = tool:GetAttribute("CustomMaxAmmo")
	local customReserve = tool:GetAttribute("CustomReserveAmmo")

	local initMax = customMax or defaultMax
	local initReserve = customReserve or defaultReserve

	if playerAmmo[player][id] == nil then
		playerAmmo[player][id] = initMax
		playerReserveAmmo[player][id] = initReserve
	end

	AmmoUpdateEvent:FireClient(player, weaponName, playerAmmo[player][id], playerReserveAmmo[player][id], true)

	if not tool:GetAttribute("_AmmoListenerAttached") then
		tool:SetAttribute("_AmmoListenerAttached", true)
		tool.AttributeChanged:Connect(function(attr)
			if attr == "CustomMaxAmmo" or attr == "CustomReserveAmmo" then
				local newMax = tool:GetAttribute("CustomMaxAmmo") or (weaponStats and weaponStats.MaxAmmo) or 0
				local newReserve = tool:GetAttribute("CustomReserveAmmo") or (weaponStats and weaponStats.ReserveAmmo) or 0

				playerAmmo[player] = playerAmmo[player] or {}
				playerReserveAmmo[player] = playerReserveAmmo[player] or {}

				playerAmmo[player][id] = newMax
				playerReserveAmmo[player][id] = newReserve

				AmmoUpdateEvent:FireClient(player, weaponName, playerAmmo[player][id], playerReserveAmmo[player][id], true)
			end
		end)
	end
end

ShootEvent.OnServerEvent:Connect(function(player, tool, cameraDirection, isAiming)
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end
	if not tool or not tool:IsA("Tool") then return end
	if not player.Character or not tool:IsDescendantOf(player.Character) then
		return
	end

	-- NEW: Cek jika player sedang knock
	if char:FindFirstChild("Knocked") then
		return
	end

	-- Atur atribut IsShooting untuk membatalkan revive jika sedang berlangsung
	char:SetAttribute("IsShooting", true)
	task.delay(0.1, function()
		if char then
			char:SetAttribute("IsShooting", false)
		end
	end)

	local weaponName = tool.Name
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return end

	local id = ensureToolHasId(tool)
	playerAmmo[player] = playerAmmo[player] or {}
	playerReserveAmmo[player] = playerReserveAmmo[player] or {}
	if playerAmmo[player][id] == nil then
		playerAmmo[player][id] = weaponStats.MaxAmmo
		playerReserveAmmo[player][id] = weaponStats.ReserveAmmo
	end

	-- ===== Server-side fire-rate gate =====
	-- Jangan izinkan menembak kalau masih dalam jeda fire rate atau sedang reload
	if player.Character and player.Character:GetAttribute("IsReloading") then
		return
	end

	lastFireTime[player] = lastFireTime[player] or {}

	local now = tick()
	local cooldown = weaponStats.FireRate
	-- Hormati buff RateBoost jika ada (sesuai logika client)
	if player.Character and player.Character:GetAttribute("RateBoost") then
		cooldown = cooldown * 0.7
	end

	local last = lastFireTime[player][id] or 0
	if (now - last) < cooldown then
		-- Belum waktunya nembak lagi → tolak
		return
	end

	-- Lewat gate: set timestamp tembakan
	lastFireTime[player][id] = now
	-- ===== End gate =====

	if playerAmmo[player][id] <= 0 then
		return
	end

	playerAmmo[player][id] = playerAmmo[player][id] - 1
	AmmoUpdateEvent:FireClient(player, weaponName, playerAmmo[player][id], playerReserveAmmo[player][id], true)

	local origin = char.Head.Position
	-- The direction is now the LookVector sent from the client, multiplied by a max distance.
	local direction = cameraDirection * 300
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {char}
	-- Abaikan semua instance drop di workspace (nama diawali "Drop_")
	for _, child in ipairs(workspace:GetChildren()) do
		if typeof(child.Name) == "string" and string.sub(child.Name, 1, 5) == "Drop_" then
			table.insert(raycastParams.FilterDescendantsInstances, child)
		end
	end
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local hasHeadshot = false
	local hasBodyshot = false
	local explosionTriggered = false -- Flag untuk memastikan hanya satu ledakan per tembakan

	-- Cek peluang ledakan SEKALI per tembakan
	local shouldExplode = false
	if player.Character and player.Character:GetAttribute("ExplosiveRoundsBoost") then
		if math.random() <= 0.1 then -- 10% chance
			shouldExplode = true
		end
	end

	if weaponStats.Pellets then
		local spread = isAiming and weaponStats.ADS_Spread or weaponStats.Spread
		for i = 1, weaponStats.Pellets do
			local pelletSpread = Vector3.new(
				(math.random() - 0.5) * spread,
				(math.random() - 0.5) * spread,
				(math.random() - 0.5) * spread
			)
			local pelletDir = (cameraDirection + pelletSpread).Unit * 300
			local res = workspace:Raycast(origin, pelletDir, raycastParams)

			if res and res.Instance then
				local hitPart = res.Instance
				local hitModel = hitPart:FindFirstAncestorOfClass("Model")
				-- hanya buat bullethole kalau yang kena bukan zombie
				local isZombie = hitModel and hitModel:FindFirstChild("IsZombie")
				if not isZombie then
					BulletholeEvent:FireClient(player, res.Position, res.Normal)
				end

				if hitModel and hitModel:FindFirstChild("Humanoid") then
					local targetHumanoid = hitModel:FindFirstChild("Humanoid")
					local immune = (hitModel:GetAttribute("Immune") == true)
					local instanceLevel = tool:GetAttribute("UpgradeLevel") or 0
					local base = weaponStats.Damage or 0
					local cfg = weaponStats.UpgradeConfig
					local damage = base
					if cfg then
						damage = base + (cfg.DamagePerLevel * instanceLevel)
					end
					local isHeadshotPellet = false

					if hitModel:FindFirstChild("IsZombie") and targetHumanoid.Health > 0 then
						local skillData = SkillModule.GetSkillData(player)
						if hitPart.Name == "Head" or hitPart.Parent and hitPart.Parent.Name == "Head" then
							local headshotLevel = skillData.Skills.HeadshotDamage or 0
							local headshotBonus = headshotLevel * (SkillConfig.HeadshotDamage.DamagePerLevel or 1)
							damage = (damage * weaponStats.HeadshotMultiplier) + headshotBonus
							isHeadshotPellet = true
							if not immune then hasHeadshot = true end
						else
							if not immune then hasBodyshot = true end
						end
						if hitModel:FindFirstChild("IsBoss") then
							local bossDamageLevel = skillData.Skills.DamageBoss or 0
							local bossDamageBonus = bossDamageLevel * (SkillConfig.DamageBoss.DamagePerLevel or 0)
							damage = damage + bossDamageBonus
						end

						-- Apply weapon specialist damage
						if weaponName ~= "Minigun" then
							local category = weaponStats.Category
							if category then
								local categoryKey = string.gsub(category, " ", "")
								if SkillConfig.WeaponSpecialist.Categories[categoryKey] and skillData.Skills.WeaponSpecialist then
									local specialistLevel = skillData.Skills.WeaponSpecialist[categoryKey] or 0
									if specialistLevel > 0 then
										local specialistBonus = specialistLevel * (SkillConfig.WeaponSpecialist.DamagePerLevel or 1)
										damage = damage + specialistBonus
									end
								end
							end
						end
					end

					local finalDamage = applyDamageAndStats(player, targetHumanoid, hitModel, damage, isHeadshotPellet, weaponName)
					if finalDamage and finalDamage > 0 then
						-- Logika Poin & Misi per Pellet
						if not immune then
							local bpMultiplier = GameConfig.Economy and GameConfig.Economy.BP_Per_Damage_Multiplier or 0
							PointsSystem.AddPoints(player, math.floor(finalDamage * bpMultiplier))
						end

						if isHeadshotPellet then
							HitmarkerEvent:FireClient(player, true)
							-- Update misi headshot
							if MissionManager then
								MissionManager:UpdateMissionProgress(player, {
									eventType = "HEADSHOT",
									amount = 1,
									weaponType = weaponStats.Category
								})
							end
						else
							HitmarkerEvent:FireClient(player, false)
							-- Update misi 'hit' jika ada di masa depan
							if MissionManager then
								MissionManager:UpdateMissionProgress(player, {
									eventType = "HIT",
									amount = 1,
									weaponType = weaponStats.Category
								})
							end
						end

						if shouldExplode and not explosionTriggered then
							explosionTriggered = true
							handleExplosion(player, res.Position, hitModel)
						end
					end
				end
			end
		end
	else
		local spread = isAiming and weaponStats.ADS_Spread or weaponStats.Spread
		local spreadOffset = Vector3.new(
			(math.random() - 0.5) * spread,
			(math.random() - 0.5) * spread,
			(math.random() - 0.5) * spread
		)
		direction = (cameraDirection + spreadOffset).Unit * 300

		local result = workspace:Raycast(origin, direction, raycastParams)

		if result and result.Instance then
			local hitPart = result.Instance
			local hitModel = hitPart:FindFirstAncestorOfClass("Model")
			-- hanya buat bullethole kalau yang kena bukan zombie
			local isZombie = hitModel and hitModel:FindFirstChild("IsZombie")
			if not isZombie then
				BulletholeEvent:FireClient(player, result.Position, result.Normal)
			end

			if hitModel and hitModel:FindFirstChild("Humanoid") then
				local targetHumanoid = hitModel:FindFirstChild("Humanoid")
				local instanceLevel = tool:GetAttribute("UpgradeLevel") or 0
				local base = weaponStats.Damage or 0
				local cfg = weaponStats.UpgradeConfig
				local damage = base
				if cfg then
					damage = base + (cfg.DamagePerLevel * instanceLevel)
				end
				local isHeadshot = false

				if hitModel:FindFirstChild("IsZombie") and targetHumanoid.Health > 0 then
					local skillData = SkillModule.GetSkillData(player)
					if hitPart.Name == "Head" or hitPart.Parent and hitPart.Parent.Name == "Head" then
						local headshotLevel = skillData.Skills.HeadshotDamage or 0
						local headshotBonus = headshotLevel * (SkillConfig.HeadshotDamage.DamagePerLevel or 1)
						damage = (damage * weaponStats.HeadshotMultiplier) + headshotBonus
						isHeadshot = true
					end
					if hitModel:FindFirstChild("IsBoss") then
						local bossDamageLevel = skillData.Skills.DamageBoss or 0
						local bossDamageBonus = bossDamageLevel * (SkillConfig.DamageBoss.DamagePerLevel or 0)
						damage = damage + bossDamageBonus
					end

					-- Apply weapon specialist damage
					if weaponName ~= "Minigun" then
						local category = weaponStats.Category
						if category then
							local categoryKey = string.gsub(category, " ", "")
							if SkillConfig.WeaponSpecialist.Categories[categoryKey] and skillData.Skills.WeaponSpecialist then
								local specialistLevel = skillData.Skills.WeaponSpecialist[categoryKey] or 0
								if specialistLevel > 0 then
									local specialistBonus = specialistLevel * (SkillConfig.WeaponSpecialist.DamagePerLevel or 1)
									damage = damage + specialistBonus
								end
							end
						end
					end
				end

				HitmarkerEvent:FireClient(player, isHeadshot)
				local finalDamage = applyDamageAndStats(player, targetHumanoid, hitModel, damage, isHeadshot, weaponName)

				-- Berikan poin berdasarkan damage jika target bukan immune
				if finalDamage and finalDamage > 0 and not hitModel:GetAttribute("Immune") then
					local bpMultiplier = GameConfig.Economy and GameConfig.Economy.BP_Per_Damage_Multiplier or 0
					PointsSystem.AddPoints(player, math.floor(finalDamage * bpMultiplier))
				end

				-- Update Misi untuk non-shotgun
				if MissionManager and finalDamage and finalDamage > 0 then
					local eventType = isHeadshot and "HEADSHOT" or "HIT"
					MissionManager:UpdateMissionProgress(player, {
						eventType = eventType,
						amount = 1,
						weaponType = weaponStats.Category
					})
				end

				if finalDamage and finalDamage > 0 and shouldExplode then
					handleExplosion(player, result.Position, hitModel)
				end
			end
		end
	end
end)

ReloadEvent.OnServerEvent:Connect(function(player, tool)
	-- HARD GUARD: cegah spam reload (double-tap/berkali-kali)
	if player.Character then
		-- kalau sudah sedang reload ATAU ada lock aktif, tolak segera
		if player.Character:GetAttribute("IsReloading") or player.Character:GetAttribute("_ReloadLock") then
			return
		end
		-- pasang lock sedini mungkin untuk menutup race condition
		player.Character:SetAttribute("_ReloadLock", true)
	end
	if not tool or not tool:IsA("Tool") then return end
	if not player.Character or not tool:IsDescendantOf(player.Character) then return end

	-- NEW: Cek jika player sedang knock
	if player.Character:FindFirstChild("Knocked") then
		return
	end

	local weaponName = tool.Name
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return end

	local id = ensureToolHasId(tool)
	local currentAmmo = (playerAmmo[player] and playerAmmo[player][id]) or weaponStats.MaxAmmo
	local reserveAmmo = (playerReserveAmmo[player] and playerReserveAmmo[player][id]) or weaponStats.ReserveAmmo
	local maxAmmo = tool:GetAttribute("CustomMaxAmmo") or weaponStats.MaxAmmo

	local ammoNeeded = maxAmmo - currentAmmo
	local ammoToReload = math.min(ammoNeeded, reserveAmmo)

	if ammoToReload > 0 then
		-- Tandai RELOADING seawal mungkin (lock sudah terpasang di atas)
		if player.Character then
			player.Character:SetAttribute("IsReloading", true)
		end
		-- Cek perk ReloadPlus
		-- Tandai karakter sedang reload (atribut global & konsisten untuk semua senjata)
		if player.Character then
			player.Character:SetAttribute("IsReloading", true)
		end

		local reloadTime = weaponStats.ReloadTime
		if player.Character and player.Character:GetAttribute("ReloadBoost") then
			reloadTime = reloadTime * 0.7 -- 30% faster
		end

		for i = 1, 20 do
			if not tool.Parent or not player.Character or not tool:IsDescendantOf(player.Character) then
				break
			end
			local progress = i / 20
			local reloadPercentage = math.floor(progress * 100)
			AmmoUpdateEvent:FireClient(player, weaponName, reloadPercentage, 0, true, true)
			task.wait(reloadTime / 20)
		end

		if tool.Parent and player.Character and tool:IsDescendantOf(player.Character) then
			playerAmmo[player][id] = currentAmmo + ammoToReload
			playerReserveAmmo[player][id] = reserveAmmo - ammoToReload
		else
			-- Tidak ada peluru untuk di-reload → bebaskan lock bila ada
			if player.Character then
				player.Character:SetAttribute("_ReloadLock", false)
			end
		end
	end
	-- Selesai reload → hapus tanda reload
	if player.Character then
		player.Character:SetAttribute("IsReloading", false)
		-- Bersihkan lock setelah reload beres
		player.Character:SetAttribute("_ReloadLock", false)
	end
	AmmoUpdateEvent:FireClient(player, weaponName, playerAmmo[player][id], playerReserveAmmo[player][id], true, false)
end)

game.Players.PlayerAdded:Connect(function(player)
	playerAmmo[player] = {}
	playerReserveAmmo[player] = {}
	player.CharacterAdded:Connect(function(char)
		for _, v in pairs(char:GetChildren()) do
			if v:IsA("Tool") then
				setupToolAmmoForPlayer(player, v)
			end
		end
		char.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				setupToolAmmoForPlayer(player, child)
			end
		end)
	end)

	local backpack = player:WaitForChild("Backpack")
	for _, v in pairs(backpack:GetChildren()) do
		if v:IsA("Tool") then
			setupToolAmmoForPlayer(player, v)
		end
	end
	backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			task.wait(0.02)
			setupToolAmmoForPlayer(player, child)
		end
	end)
end)

-- Bersihkan state saat player keluar
game.Players.PlayerRemoving:Connect(function(plr)
	playerAmmo[plr] = nil
	playerReserveAmmo[plr] = nil
	lastFireTime[plr] = nil
end)