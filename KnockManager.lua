-- KnockManager.lua (Script)
-- Path: ServerScriptService/Script/KnockManager.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local Constants = require(ModuleScriptServerScriptService:WaitForChild("Constants"))
local GameConfig = require(ModuleScriptServerScriptService:WaitForChild("GameConfig"))
local GameStatus = require(ModuleScriptServerScriptService:WaitForChild("GameStatus"))
local WalkSpeedManager = require(ModuleScriptServerScriptService:WaitForChild("WalkSpeedManager"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))
local StatsModule = require(ModuleScriptServerScriptService:WaitForChild("StatsModule"))
local BoosterModule = require(ModuleScriptServerScriptService:WaitForChild("BoosterModule"))
local AchievementManager = require(ModuleScriptServerScriptService:WaitForChild("AchievementManager"))

local KnockEvent = RemoteEvents:WaitForChild(Constants.Events.KNOCK)
local ReviveEvent = RemoteEvents:WaitForChild(Constants.Events.REVIVE)
local GameOverEvent = RemoteEvents:WaitForChild(Constants.Events.GAME_OVER)
local ReviveProgressEvent = RemoteEvents:WaitForChild(Constants.Events.REVIVE_PROGRESS)
local CancelReviveEvent = RemoteEvents:WaitForChild(Constants.Events.CANCEL_REVIVE)
local GlobalKnockNotificationEvent = RemoteEvents:WaitForChild(Constants.Events.GLOBAL_KNOCK_NOTIFICATION)
local PingKnockedPlayerEvent = RemoteEvents:WaitForChild(Constants.Events.PING_KNOCKED_PLAYER)

local activeRevivers = {} -- [reviver] = {target, startTime, connection}
local pingCooldowns = {} -- [player] = lastPingTime

local KnockConfig = GameConfig.KnockSystem

local function cancelRevive(reviver)
	if activeRevivers[reviver] then
		if activeRevivers[reviver].connection then
			activeRevivers[reviver].connection:Disconnect()
		end
		ReviveProgressEvent:FireClient(reviver, 0, true, 0) -- Cancel progress
		activeRevivers[reviver] = nil
	end
end

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid")
		humanoid.BreakJointsOnDeath = false
		-- [Spawn Grace] Abaikan health spike awal saat baru respawn
		local justSpawned = true
		task.delay(2, function()  -- 2 detik cukup untuk inisialisasi
			justSpawned = false
		end)


		humanoid.HealthChanged:Connect(function(health)
			if (not justSpawned) and health <= 0 and not char:FindFirstChild(Constants.Attributes.KNOCKED) then
				-- Cek untuk Self-Revive Booster
				local usedBooster = BoosterModule.UseActiveBooster(player)
				if usedBooster == Constants.Strings.SELF_REVIVE_BOOSTER then
					-- Booster digunakan, hidupkan kembali pemain
					humanoid.Health = humanoid.MaxHealth * 0.5 -- Pulihkan 50% HP
					-- Tambahkan efek visual/suara di sini jika diinginkan
					print(player.Name .. " menggunakan Self-Revive!")
					return -- Hentikan proses knock
				end

				local activePlayers = 0
				for _, p in pairs(game.Players:GetPlayers()) do
					if p.Character and not p.Character:FindFirstChild(Constants.Attributes.KNOCKED) then
						activePlayers = activePlayers + 1
					end
				end

				if activePlayers <= 1 then
					GameOverEvent:FireAllClients()
					-- Bersihkan status knock & UI terkait pada semua pemain saat Game Over
					local Players = game:GetService("Players")

					-- Batalkan semua proses revive yang sedang berjalan
					for reviver, _ in pairs(activeRevivers) do
						cancelRevive(reviver)
					end

					-- Hapus tag "Knocked" & kirim KnockEvent(false) agar UI Knock ditutup
					for _, plr in ipairs(Players:GetPlayers()) do
						if plr.Character then
							local tag = plr.Character:FindFirstChild(Constants.Attributes.KNOCKED)
							if tag then tag:Destroy() end
							KnockEvent:FireClient(plr, false)
							-- Pastikan progress bar revive (jika ada) juga direset & disembunyikan
							ReviveProgressEvent:FireClient(plr, 0, true, 0)
						end
					end
					-- MATIKAN AUTORESPAWN & BEKUKAN KARAKTER SAAT GAME OVER
					local Players = game:GetService("Players")
					Players.CharacterAutoLoads = false
					for _, plr in ipairs(Players:GetPlayers()) do
						local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
						if hum then
							if hum.Health <= 0 then
								-- biarkan ragdoll, JANGAN respawn (karena CharacterAutoLoads = false)
							else
								hum.Health = math.max(1, hum.Health)
								WalkSpeedManager.add_modifier(plr, "gameOver", -100) -- Effectively sets speed to 0 or less
								hum.JumpPower = 0
								hum.PlatformStand = true
							end
						end
					end

					for _, zombie in pairs(workspace:GetChildren()) do
						if zombie:FindFirstChild(Constants.Attributes.IS_ZOMBIE) then
							zombie:Destroy()
						end
					end
				else
					local tag = Instance.new("BoolValue")
					tag.Name = Constants.Attributes.KNOCKED
					tag.Parent = char

					-- NEW: Lacak jumlah knock pada player
					local currentKnocks = player:GetAttribute(Constants.Attributes.KNOCK_COUNT) or 0
					player:SetAttribute(Constants.Attributes.KNOCK_COUNT, currentKnocks + 1)

					WalkSpeedManager.add_modifier(player, "knock", -16)
					humanoid.JumpPower = 0
					humanoid.PlatformStand = true
					humanoid.Health = 1
					KnockEvent:FireClient(player, true)
					-- update leaderstat knock
					if PointsSystem and PointsSystem.AddKnock then
						PointsSystem.AddKnock(player)
					end
					-- update lifetime stats knock
					if StatsModule and StatsModule.AddKnock then
						StatsModule.AddKnock(player)
					end

					-- Reset wave survival streak for achievements
					if AchievementManager and AchievementManager.ResetWaveSurvivedProgress then
						AchievementManager:ResetWaveSurvivedProgress(player)
					end

					-- NEW: Kirim notifikasi ke semua pemain
					GlobalKnockNotificationEvent:FireAllClients(player.Name, true, char.HumanoidRootPart.Position)
				end
			elseif char:FindFirstChild(Constants.Attributes.KNOCKED) and humanoid.Health < 1 then
				humanoid.Health = 1
			end
		end)
	end)
end)



CancelReviveEvent.OnServerEvent:Connect(function(player)
	cancelRevive(player)
end)

ReviveEvent.OnServerEvent:Connect(function(player, target)
	-- Logika No Revive
	local currentDifficulty = GameStatus:GetDifficulty()
	local difficultyRules = GameConfig.Difficulty[currentDifficulty] and GameConfig.Difficulty[currentDifficulty].Rules
	if difficultyRules and not difficultyRules.AllowRevive then
		return -- Blokir revive jika tidak diizinkan
	end

	-- HARD GUARD: reviver tidak boleh knock / self-target / target harus knock
	if not player.Character or player.Character:FindFirstChild(Constants.Attributes.KNOCKED) or player.Character:GetAttribute(Constants.Attributes.IS_RELOADING) then
		return
	end
	if not target or target == player then
		return
	end
	if not target.Character or not target.Character:FindFirstChild(Constants.Attributes.KNOCKED) then
		return
	end

	if activeRevivers[player] then
		cancelRevive(player)
		return
	end

	if target and target.Character and target.Character:FindFirstChild(Constants.Attributes.KNOCKED) then
		local humanoid = target.Character:FindFirstChild("Humanoid")
		if humanoid then
			local startTime = time()
			activeRevivers[player] = {
				target = target,
				startTime = startTime,
				connection = nil
			}

			local reviveTime = KnockConfig.BaseReviveTime
			if player.Character and player.Character:GetAttribute(Constants.Attributes.REVIVE_BOOST) then
				reviveTime = KnockConfig.BoostedReviveTime
			end

			-- NEW: Tambahkan penalti waktu berdasarkan jumlah knock target
			local knockCount = target:GetAttribute(Constants.Attributes.KNOCK_COUNT) or 1
			if knockCount > 1 then
				reviveTime = reviveTime + (knockCount - 1) * KnockConfig.PenaltyPerKnock
			end

			-- Progress update loop
			task.spawn(function()
				local reviverChar = player.Character
				local targetChar = target.Character

				-- TEMPATKAN DI ATAS: for i = 1, reviveTime * 10 do
				local RunService = game:GetService("RunService")
				local reviverChar = player.Character
				local targetChar = target.Character
				local endTime = time() + reviveTime

				while time() < endTime do
					-- CANCEL GUARD: berhenti kalau sudah dibatalkan dari mana pun
					if not activeRevivers[player] then
						ReviveProgressEvent:FireClient(player, 0, true, 0)
						break
					end
					-- Batal jika status berubah (termasuk jika reviver bergerak)
					if not reviverChar or not targetChar
						or not reviverChar.Parent or not targetChar.Parent
						or reviverChar:FindFirstChild(Constants.Attributes.KNOCKED)
						or reviverChar:GetAttribute(Constants.Attributes.IS_RELOADING)
						or reviverChar:GetAttribute(Constants.Attributes.IS_SHOOTING)
						or reviverChar:GetAttribute(Constants.Attributes.IS_USING_BOOSTER)
						or not targetChar:FindFirstChild(Constants.Attributes.KNOCKED)
						or (reviverChar.HumanoidRootPart.Position - targetChar.HumanoidRootPart.Position).Magnitude > KnockConfig.MaxReviveDistance
						or reviverChar.Humanoid.MoveDirection.Magnitude > 0 then
						cancelRevive(player)
						break
					end

					local remaining = endTime - time()
					local progress = 1 - math.clamp(remaining / reviveTime, 0, 1)
					ReviveProgressEvent:FireClient(player, progress, false, reviveTime)

					RunService.Heartbeat:Wait() -- frame-accurate, tidak molor saat lag
				end

				if activeRevivers[player] then
					-- Successfully revived
					if player.Character and player.Character:GetAttribute(Constants.Attributes.MEDIC_BOOST) then
						humanoid.Health = humanoid.MaxHealth * KnockConfig.BoostedReviveHealth
					else
						humanoid.Health = humanoid.MaxHealth * KnockConfig.DefaultReviveHealth
					end
					WalkSpeedManager.remove_modifier(target, "knock")
					humanoid.JumpPower = KnockConfig.PostReviveJumpPower
					humanoid.PlatformStand = false
					-- FIX: reset fisika & paksa humanoid bangun agar tidak melayang/berputar
					local targetChar = target.Character
					local hrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
					if hrp then
						-- buang momentum sisa
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero

						-- jaga orientasi tegak lurus (tanpa memaksa rotasi yaw)
						local _, yaw, _ = hrp.CFrame:ToEulerAnglesYXZ()
						local pos = hrp.Position
						hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
					end

					-- pastikan humanoid “bangun” normal
					humanoid.AutoRotate = true
					humanoid.Sit = false
					humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

					-- jaga-jaga: setelah satu frame, nolkan lagi kalau masih ada sisa momentum
					task.defer(function()
						if hrp then
							hrp.AssemblyLinearVelocity = Vector3.zero
							hrp.AssemblyAngularVelocity = Vector3.zero
						end
					end)

					target.Character.Knocked:Destroy()
					-- PULIHKAN GERAK SETELAH REVIVE
					humanoid.PlatformStand = false
					-- WalkSpeedManager.remove_modifier(target, "knock") -- Already called above
					-- atur sesuai desainmu
					humanoid.UseJumpPower = true
					humanoid.JumpPower = KnockConfig.PostReviveJumpPower
					KnockEvent:FireClient(target, false)
					-- Pastikan progress bar hilang di client setelah sukses
					ReviveProgressEvent:FireClient(player, 1, false, reviveTime)
					task.defer(function()
						ReviveProgressEvent:FireClient(player, 0, true)
					end)

					-- NEW: Kirim notifikasi revive ke semua pemain
					GlobalKnockNotificationEvent:FireAllClients(target.Name, false, targetChar.HumanoidRootPart.Position)

					-- update lifetime stats revive
					if StatsModule and StatsModule.AddRevive then
						StatsModule.AddRevive(player)
					end

					activeRevivers[player] = nil
				end
			end)
		end
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	cancelRevive(player)
	pingCooldowns[player] = nil
end)

PingKnockedPlayerEvent.OnServerEvent:Connect(function(player)
	-- Security checks: player must be knocked and not in cooldown
	if not player.Character or not player.Character:FindFirstChild(Constants.Attributes.KNOCKED) then
		return
	end

	local now = time()
	if pingCooldowns[player] and now - pingCooldowns[player] < KnockConfig.PingCooldown then
		return
	end

	pingCooldowns[player] = now
	PingKnockedPlayerEvent:FireAllClients(player)
end)
