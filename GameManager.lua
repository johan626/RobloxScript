-- GameManager.lua (Script)
-- Path: ServerScriptService/Script/GameManager.lua
-- Script Place: ACT 1: Village

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

-- Game Mode Initialization
-- Game Initialization
local gameMode = "Story" -- Default to Story
local difficulty = "Easy" -- Default difficulty
local gameInitialized = false

local function initializeGameSettings(player)
	if gameInitialized then return end

	local joinData = player:GetJoinData()
	local teleportData = joinData and joinData.TeleportData

	if teleportData then
		gameMode = teleportData.gameMode or "Story"
		difficulty = teleportData.difficulty or "Easy"
		gameInitialized = true
		print(string.format("Game settings initialized from JoinData. Mode: %s, Difficulty: %s", gameMode, difficulty))
	else
		-- Fallback for players joining directly or if data is missing
		gameInitialized = true
		print("No JoinData found for game settings. Defaulting to Story and Easy.")
	end
end

-- Connect to PlayerAdded to get the game mode from the first player
local playerAddedConnection
playerAddedConnection = Players.PlayerAdded:Connect(function(player)
	initializeGameSettings(player)
	-- Disconnect after the first player joins to avoid re-initializing
	if gameInitialized and playerAddedConnection then
		playerAddedConnection:Disconnect()
		playerAddedConnection = nil
	end
end)

-- Handle players who might already be in the game when the script runs
if #Players:GetPlayers() > 0 then
	initializeGameSettings(Players:GetPlayers()[1])
	if gameInitialized and playerAddedConnection then
		playerAddedConnection:Disconnect()
		playerAddedConnection = nil
	end
end

print("GameManager loaded. Waiting for player to initialize game mode...")


local BindableEvents = game.ReplicatedStorage.BindableEvents
local RemoteEvents = game.ReplicatedStorage.RemoteEvents

-- Pastikan MissionCompleteEvent ada
if not RemoteEvents:FindFirstChild("MissionCompleteEvent") then
	local event = Instance.new("RemoteEvent")
	event.Name = "MissionCompleteEvent"
	event.Parent = RemoteEvents
end

-- Pastikan GameModeUpdateEvent ada
-- Pastikan GameSettingsUpdateEvent ada
if not RemoteEvents:FindFirstChild("GameSettingsUpdateEvent") then
	local event = Instance.new("RemoteEvent")
	event.Name = "GameSettingsUpdateEvent"
	event.Parent = RemoteEvents
end

-- Pastikan SpecialWaveAlertEvent ada
if not RemoteEvents:FindFirstChild("SpecialWaveAlertEvent") then
	local event = Instance.new("RemoteEvent")
	event.Name = "SpecialWaveAlertEvent"
	event.Parent = RemoteEvents
end

local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local GameConfig = require(game.ServerScriptService.ModuleScript.GameConfig)
local GameStatus = require(ModuleScriptServerScriptService:WaitForChild("GameStatus"))
local SessionDataManager = require(ModuleScriptServerScriptService:WaitForChild("SessionDataManager"))
local PlaceData = require(ModuleScriptServerScriptService:WaitForChild("PlaceDataConfig"))
local SpawnerModule = require(ModuleScriptServerScriptService:WaitForChild("SpawnerModule"))
local BuildingManager = require(ModuleScriptServerScriptService:WaitForChild("BuildingModule"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))
local CoinsModule = require(ModuleScriptServerScriptService:WaitForChild("CoinsModule"))
local ElementModule = require(ModuleScriptServerScriptService:WaitForChild("ElementConfigModule"))
local PerkHandler = require(ModuleScriptServerScriptService:WaitForChild("PerkModule"))
local WalkSpeedManager = require(ModuleScriptServerScriptService:WaitForChild("WalkSpeedManager"))
local StatsModule = require(ModuleScriptServerScriptService:WaitForChild("StatsModule"))
local BoosterModule = require(ModuleScriptServerScriptService:WaitForChild("BoosterModule"))
local ShieldModule = require(ModuleScriptServerScriptService:WaitForChild("ShieldModule"))
local MissionManager = require(ModuleScriptServerScriptService:WaitForChild("MissionManager"))
local AchievementManager = require(ModuleScriptServerScriptService:WaitForChild("AchievementManager"))
local DataStoreManager = require(ModuleScriptServerScriptService:WaitForChild("DataStoreManager"))
DataStoreManager:Init()

local WaveCountdownEvent = RemoteEvents:WaitForChild("WaveCountdownEvent")
local PlayerCountEvent   = RemoteEvents:WaitForChild("PlayerCountEvent")
local OpenStartUIEvent   = RemoteEvents:WaitForChild("OpenStartUIEvent")
local ReadyCountEvent    = RemoteEvents:WaitForChild("ReadyCountEvent")
local RestartGameEvent = RemoteEvents:WaitForChild("RestartGameEvent")
local StartGameEvent = RemoteEvents:WaitForChild("StartGameEvent")
local ExitGameEvent = RemoteEvents:WaitForChild("ExitGameEvent")
local WaveUpdateEvent = RemoteEvents:WaitForChild("WaveUpdateEvent")
local StartVoteCountdownEvent = RemoteEvents:WaitForChild("StartVoteCountdownEvent")
local StartVoteCanceledEvent  = RemoteEvents:WaitForChild("StartVoteCanceledEvent")
local CancelStartVoteEvent = RemoteEvents:WaitForChild("CancelStartVoteEvent")

local ZombieDiedEvent = BindableEvents:WaitForChild("ZombieDiedEvent")
local ReportDamageEvent = BindableEvents:FindFirstChild("ReportDamageEvent") or Instance.new("BindableEvent", BindableEvents)
ReportDamageEvent.Name = "ReportDamageEvent"

ReportDamageEvent.Event:Connect(function(player, damageAmount)
	if not gameStarted or not player or not damageAmount then return end

	local userId = player.UserId
	if not waveDamageTracker[userId] then
		waveDamageTracker[userId] = 0
	end
	waveDamageTracker[userId] += damageAmount
end)

-- Penanda sesi voting agar timer lama tidak 'menimpa' sesi baru
local currentVoteSession = 0
local zombiesToSpawn = 0
local zombiesKilled = 0
local chamsApplied = false
local wave = 1
local gameStarted = false
-- Token sesi untuk membatalkan loop lama
local runToken = 0
local activePlayers = 0
local initialPlayerCount = 0
-- Kumpulan pemain yang sudah menekan YES
local readyPlayers = {}
local waveDamageTracker = {}

local Lighting = game:GetService("Lighting")
-- Simpan nilai default lighting untuk dipulihkan nanti
local defaultLightingSettings = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient
}

-- >>> TRANSISI LIGHTING ANTAR-WAVE <<<
local TweenService = game:GetService("TweenService")

local function tweenLightingTo(targetSettings, duration)
	duration = duration or GameConfig.Lighting.TransitionDuration
	-- Siapkan goal dari settings table
	local goal = {
		Brightness = targetSettings.Brightness,
		ClockTime = targetSettings.ClockTime,
		Ambient = targetSettings.Ambient,
		OutdoorAmbient = targetSettings.OutdoorAmbient
	}

	-- Cek apakah ClockTime perlu "memutar" ke depan
	if goal.ClockTime < Lighting.ClockTime then
		goal.ClockTime = goal.ClockTime + 24 -- Tambah 24 jam agar tween berjalan maju
	end

	-- Tween halus (Sine InOut)
	local info = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	TweenService:Create(Lighting, info, goal):Play()
end
-- <<< END TRANSISI LIGHTING >>>

-- Fungsi untuk memulihkan lighting ke kondisi awal
local function restoreLighting()
	Lighting.Brightness = defaultLightingSettings.Brightness
	Lighting.ClockTime = defaultLightingSettings.ClockTime
	Lighting.Ambient = defaultLightingSettings.Ambient
	Lighting.OutdoorAmbient = defaultLightingSettings.OutdoorAmbient
end

local function ApplyChamsToZombies()
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:FindFirstChild("IsZombie") and not m:FindFirstChild("IsBoss") then
			local hum = m:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				-- Hanya zombie yang masih hidup yang diberi highlight
				if not m:FindFirstChild("ChamsHighlight") then
					local h = Instance.new("Highlight")
					h.Name = "ChamsHighlight"
					h.FillTransparency = 1 -- hanya outline
					h.OutlineTransparency = 0
					h.OutlineColor = Color3.fromRGB(0, 255, 0) -- hijau
					h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- tembus tembok
					h.Parent = m
				end
			else
				-- Jika mayat masih tersisa dan sempat punya highlight, cabut supaya tidak ikut ter-highlight
				local h = m:FindFirstChild("ChamsHighlight")
				if h then h:Destroy() end
			end
		end
	end
end

local function ClearChams()
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:FindFirstChild("IsZombie") then
			local h = m:FindFirstChild("ChamsHighlight")
			if h then h:Destroy() end
		end
	end
end

local GameOverEvent = RemoteEvents:WaitForChild("GameOverEvent")

local function HandleGameOver()
	if not gameStarted then return end
	print("Semua pemain telah kalah. Game Over.")

	runToken += 1 -- Hentikan semua loop game yang sedang berjalan
	gameStarted = false

	-- Kirim event ke semua client untuk menampilkan layar Game Over
	GameOverEvent:FireAllClients()

	-- Di sini kita tidak langsung teleport. Client akan memiliki tombol untuk kembali ke lobi.
end

-- Fungsi untuk menghitung pemain aktif
local function countActivePlayers()
	-- Di lobby/awal, Character bisa belum spawn → hitung taotal pemain saja
	if not gameStarted then
		return #game.Players:GetPlayers()
	end

	-- Saat game berjalan, hitung pemain yang benar-benar aktif (punya Character dan tidak Knocked)
	local count = 0
	for _, player in ipairs(game.Players:GetPlayers()) do
		if player.Character and not player.Character:FindFirstChild("Knocked") then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				count += 1
			end
		end
	end
	return count
end


-- Fungsi update jumlah pemain ke semua client
local function updatePlayerCount()
	activePlayers = countActivePlayers()
	PlayerCountEvent:FireAllClients(activePlayers)

	-- Cek kondisi game over jika permainan sudah dimulai
	if gameStarted and activePlayers == 0 then
		HandleGameOver()
	end

	return activePlayers
end

-- Fungsi reset game
local function ResetGame()
	gameStarted = false
	wave = 1
	zombiesKilled = 0
	-- Naikkan token agar loop lama segera berhenti
	runToken += 1

	-- Bersihkan semua zombie sisa sesi sebelumnya
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:FindFirstChild("IsZombie") then
			m:Destroy()
		end
	end

	restoreLighting() -- pastikan lighting balik normal saat reset
	ClearChams()
	-- Reset purchased elements
	ElementModule.ClearPurchasedElements()

	-- Reset perks, points & leaderstats untuk semua player
	for _, player in ipairs(game.Players:GetPlayers()) do
		PerkHandler.clearPlayerPerks(player)
		PointsSystem.SetupPlayer(player)
	end
end

-- Event zombie mati
ZombieDiedEvent.Event:Connect(function()
	-- Abaikan kill jika game tidak berjalan (hindari wave skip)
	if not gameStarted then return end
	zombiesKilled += 1
end)

-- Fungsi start loop game
local function startGameLoop()
	if gameStarted then return end

	-- Atur tingkat kesulitan di GameStatus
	GameStatus:SetDifficulty(difficulty)

	-- Reset data sesi permainan
	SessionDataManager:ResetAllSessionData()

	gameStarted = true
	-- Buat sesi baru dan ikat loop ke sesi ini
	runToken += 1
	local myToken = runToken

	-- Update jumlah pemain
	activePlayers = updatePlayerCount()
	initialPlayerCount = activePlayers
	print("Game started with " .. initialPlayerCount .. " players.")

	-- Tambahkan ini untuk menginisialisasi UI pada semua pemain saat game dimulai
	for _, plr in pairs(game.Players:GetPlayers()) do
		PointsSystem.AddPoints(plr, 0) -- Menginisialisasi poin dan menampilkan UI

		-- Cek dan gunakan booster
		local boosterData = BoosterModule.GetData(plr)
		if boosterData and boosterData.Active then
			local activeBooster = boosterData.Active -- Simpan nama booster aktif
			local usedBooster = BoosterModule.UseActiveBooster(plr) -- Gunakan dan konsumsi

			if usedBooster then -- Pastikan booster berhasil digunakan
				if usedBooster == "StarterPoints" then
					PointsSystem.AddPoints(plr, 1500)
					print(plr.Name .. " used StarterPoints booster and received 1500 points.")
				elseif usedBooster == "StartingShield" then
					if plr.Character then
						local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							local shieldAmount = humanoid.MaxHealth * 0.5
							ShieldModule.Set(plr, shieldAmount)
							print(plr.Name .. " used StartingShield booster and received a 50% shield.")
						end
					end
				end
			end
		end
	end

	-- Start playtime tracking loop
	task.spawn(function()
		while myToken == runToken and gameStarted do
			task.wait(60) -- Wait for 60 seconds
			if not gameStarted then break end -- Double check if game has ended

			for _, player in ipairs(game.Players:GetPlayers()) do
				-- Add playtime only to active (not knocked) players
				if player.Character and not player.Character:FindFirstChild("Knocked") then
					if StatsModule and StatsModule.AddPlaytime then
						StatsModule.AddPlaytime(player, 60)
					end
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			-- Stop cepat jika sesi diganti/di-reset
			if (myToken ~= runToken) or (not gameStarted) then break end

			print("Wave " .. wave .. " dimulai! Jumlah Pemain: " .. activePlayers)
			WaveUpdateEvent:FireAllClients(wave, activePlayers)
			local isDarkWave = false
			local isBloodMoonWave = false
			local waveModifiers = {} -- Tabel untuk menyimpan flag gelombang spesial

			local isSpecialEventTriggered = false
			if GameConfig.DarkWave.Interval > 0 and (wave % GameConfig.DarkWave.Interval == 0) then
				isDarkWave = true
				if math.random() < GameConfig.BloodMoon.Chance then
					isBloodMoonWave = true
					isSpecialEventTriggered = true
					RemoteEvents.SpecialWaveAlertEvent:FireAllClients("Blood Moon")
					print("Blood Moon wave! Memulai transisi ke dark lalu ke blood.")
					task.spawn(function()
						tweenLightingTo(GameConfig.Lighting.DarkSettings, GameConfig.Lighting.TransitionDuration / 2)
						task.wait(GameConfig.Lighting.TransitionDuration / 2)
						tweenLightingTo(GameConfig.Lighting.BloodSettings, GameConfig.Lighting.TransitionDuration / 2)
					end)
				else
					print("Wave gelap! Memulai transisi ke dark.")
					tweenLightingTo(GameConfig.Lighting.DarkSettings, GameConfig.Lighting.TransitionDuration)
				end
			end

			-- Jika tidak ada acara berbasis interval (seperti Blood Moon), cek acara berbasis peluang
			if not isSpecialEventTriggered then
				local rand = math.random()
				if rand < GameConfig.FastWave.Chance then
					waveModifiers.isFast = true
					RemoteEvents.SpecialWaveAlertEvent:FireAllClients("Fast Wave")
					print("Gelombang Cepat!")
				elseif rand < (GameConfig.FastWave.Chance + GameConfig.SpecialWave.Chance) then
					waveModifiers.isSpecial = true
					RemoteEvents.SpecialWaveAlertEvent:FireAllClients("Special Wave")
					print("Gelombang Spesial!")
				end
			end

			-- Sesuaikan jumlah zombie berdasarkan jumlah pemain awal
			zombiesToSpawn = wave * GameConfig.Wave.ZombiesPerWavePerPlayer * initialPlayerCount
			-- Pastikan jumlah pemain aktif (untuk game over check) selalu up-to-date tiap awal wave
			updatePlayerCount()

			-- Modifikasi jumlah zombie saat Blood Moon: spawn lebih banyak
			if isBloodMoonWave then
				zombiesToSpawn = math.floor(zombiesToSpawn * GameConfig.BloodMoon.SpawnMultiplier)
			end
			zombiesKilled = 0
			chamsApplied = false
			ClearChams()
			waveDamageTracker = {}
			local isBossWave = SpawnerModule.SpawnWave(zombiesToSpawn, wave, activePlayers, gameMode, difficulty, waveModifiers)
			print("Menunggu " .. zombiesToSpawn .. " zombie dikalahkan.")
			while zombiesKilled < zombiesToSpawn do
				local remaining = math.max(0, zombiesToSpawn - zombiesKilled)
				if (not chamsApplied) and remaining == 3 then
					chamsApplied = true
					ApplyChamsToZombies()
				end
				-- Jika sesi berubah saat menunggu, hentikan segera
				if (myToken ~= runToken) or (not gameStarted) then
					-- keluar dari coroutine agar loop lama benar-benar selesai
					return
				end

				task.wait(1)
			end
			print("Wave " .. wave .. " selesai!")
			-- Cek lagi sebelum memberi reward/lanjut wave
			if (myToken ~= runToken) or (not gameStarted) then break end

			-- <<< KONDISI KEMENANGAN (HANYA UNTUK MODE STORY) >>>
			if gameMode == "Story" then
				-- Kondisi kemenangan yang lebih kuat: hanya bergantung pada nomor wave.
				-- Ini mencegah bug di masa depan jika logika SpawnerModule diubah.
				if wave == 50 then
					print("Wave 50 selesai! Misi selesai.")

					-- Kirim event kemenangan ke semua client
					local missionCompleteEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("MissionCompleteEvent")
					if missionCompleteEvent then
						missionCompleteEvent:FireAllClients()
					end

					-- Hentikan semua proses game yang sedang berjalan
					runToken += 1
					gameStarted = false

					-- Tunggu 10 detik sebelum teleport
					task.wait(10)

					-- Teleport semua pemain ke lobi
					local lobbyId = PlaceData["Lobby"]
					if lobbyId then
						local playersToTeleport = game.Players:GetPlayers()
						if #playersToTeleport > 0 then
							-- Simpan data semua pemain secara sinkron sebelum teleport
							for _, p in ipairs(playersToTeleport) do
								DataStoreManager:SavePlayerDataYielding(p)
							end
							-- Gunakan pcall untuk keamanan
							local success, result = pcall(function()
								return TeleportService:TeleportAsync(lobbyId, playersToTeleport)
							end)
							if not success then
								warn("Gagal teleport pemain setelah kemenangan: " .. tostring(result))
							end
						end
					else
						warn("ID Lobi tidak ditemukan untuk teleport kemenangan.")
					end

					-- Keluar dari loop game utama
					break
				end
			end
			-- <<< AKHIR KONDISI KEMENANGAN >>>

			if isBossWave then
				BuildingManager.restoreBuildings()
			end

			-- Jika ini Blood Moon atau wave gelap, kembalikan pencahayaan ke semula sebelum memberikan reward
			if isBloodMoonWave or isDarkWave then
				print("Wave khusus selesai. Memulihkan pencahayaan.")
			end

			-- Berikan bonus kepada setiap pemain yang masih hidup (tidak knocked)
			for _, player in ipairs(game.Players:GetPlayers()) do
				if player.Character and not player.Character:FindFirstChild("Knocked") then
					-- Kalkulasi dan berikan Koin (Mata Uang Permanen)
					local userId = player.UserId
					local totalDamage = waveDamageTracker[userId] or 0

					local coinConfig = GameConfig.Economy.Coins
					local difficultyConfig = GameConfig.Difficulty[difficulty]

					if coinConfig and difficultyConfig then
						local healthMultiplier = difficultyConfig.HealthMultiplier
						local adjustedRatio = coinConfig.DamageToCoinConversionRatio * healthMultiplier

						local coinsFromDamage = 0
						if adjustedRatio > 0 then
							coinsFromDamage = math.floor(totalDamage / adjustedRatio)
						end

						local baseReward = coinConfig.WaveCompleteBonus + coinsFromDamage

						local difficultyMultiplier = coinConfig.DifficultyCoinMultipliers[difficulty] or 1
						local finalCoinReward = math.floor(baseReward * difficultyMultiplier)

						if finalCoinReward > 0 then
							CoinsModule.AddCoins(player, finalCoinReward)
							print(string.format("%s mendapatkan %d Koin (Bonus: %d, Dari Kerusakan: %d, Pengganda: x%.2f)",
								player.Name, finalCoinReward, coinConfig.WaveCompleteBonus, coinsFromDamage, difficultyMultiplier))
						end
					end

					-- Berikan Poin
					PointsSystem.AddPoints(player, GameConfig.Wave.BonusPoints)
					print(player.Name .. " mendapatkan " .. GameConfig.Wave.BonusPoints .. " BP (Wave Bonus)!")

					-- Berikan Heal
					local humanoid = player.Character:FindFirstChild("Humanoid")
					if humanoid then
						local healAmount = humanoid.MaxHealth * GameConfig.Wave.HealPercentage
						humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healAmount)
						print(player.Name .. " mendapatkan heal " .. (GameConfig.Wave.HealPercentage * 100) .. "% (Wave Heal)!")
					end

					-- Update Misi Selesaikan Gelombang
					if MissionManager then
						MissionManager:UpdateMissionProgress(player, { eventType = "WAVE_COMPLETE", amount = 1 })
					end

					-- Update Achievement Progress for Surviving a Wave
					if AchievementManager and AchievementManager.UpdateWaveSurvivedProgress then
						AchievementManager:UpdateWaveSurvivedProgress(player)
					end

					-- Update Total Waves Completed for Wave Conqueror Achievement
					if AchievementManager and AchievementManager.UpdateStatProgress then
						AchievementManager:UpdateStatProgress(player, "TotalWavesCompleted")
					end
				end
			end

			-- Auto-revive untuk mode Crazy SEBELUM countdown dimulai
			if difficulty == "Crazy" then
				for _, player in ipairs(game.Players:GetPlayers()) do
					if player.Character and player.Character:FindFirstChild("Knocked") then
						local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							print("Auto-reviving " .. player.Name .. " for Crazy mode.")
							-- Logika dari KnockManager direplikasi di sini
							humanoid.Health = humanoid.MaxHealth * 0.1 -- 10% HP
							WalkSpeedManager.remove_modifier(player, "knock")
							humanoid.JumpPower = 50
							humanoid.PlatformStand = false

							local knockedTag = player.Character:FindFirstChild("Knocked")
							if knockedTag then knockedTag:Destroy() end

							-- Kirim event ke klien untuk menutup UI knock
							RemoteEvents.KnockEvent:FireClient(player, false)
						end
					end
				end
			end

			-- Kirim countdown dan mulai transisi lighting ke wave berikutnya
			local nextWave = wave + 1
			local nextIsDark = GameConfig.DarkWave.Interval > 0 and (nextWave % GameConfig.DarkWave.Interval == 0)

			local targetSettings
			if nextIsDark then
				targetSettings = GameConfig.Lighting.DarkSettings
			else
				targetSettings = defaultLightingSettings
			end

			tweenLightingTo(targetSettings, GameConfig.Lighting.TransitionDuration)

			for count = 10, 1, -1 do
				WaveCountdownEvent:FireAllClients(count)
				task.wait(1)
			end
			WaveCountdownEvent:FireAllClients(0)
			task.wait(0.1)

			-- Hapus purchased elements yang belum diaktifkan untuk semua player
			ElementModule.ClearPurchasedElements()

			-- Cek kondisi game over untuk wave berikutnya
			updatePlayerCount()

			wave += 1
		end
	end)
end

-- Saat 1 pemain menekan YES -> tandai siap, broadcast progres, dan mulai jika semua siap
StartGameEvent.OnServerEvent:Connect(function(player)
	if gameStarted then return end

	readyPlayers[player.UserId] = true

	-- hitung progres
	local total = #game.Players:GetPlayers()
	local ready = 0
	for _, plr in ipairs(game.Players:GetPlayers()) do
		if readyPlayers[plr.UserId] then
			ready += 1
		end
	end

	-- broadcast "x/total" ke semua client
	ReadyCountEvent:FireAllClients(ready, total)

	-- kalau semua sudah siap -> mulai game & reset penanda
	if ready >= total then
		readyPlayers = {}
		print("Semua pemain siap. Memulai game...")
		-- Akhiri sesi voting agar timer berhenti
		currentVoteSession += 1
		startGameLoop()
	end
end)

-- NEW: jika satu pemain batalkan, hentikan sesi & reset untuk semua
CancelStartVoteEvent.OnServerEvent:Connect(function(player)
	if gameStarted then return end

	-- hentikan countdown sesi ini
	currentVoteSession += 1

	-- reset daftar siap
	readyPlayers = {}

	local total = #game.Players:GetPlayers()

	-- broadcast ke semua client: tutup UI + tampilkan nama pembatal
	local who = (player.DisplayName or player.Name)
	StartVoteCanceledEvent:FireAllClients(who)

	-- reset progres ready di UI
	ReadyCountEvent:FireAllClients(0, total)
end)

-- Debounce table untuk teleportasi
local teleportingPlayers = {}

-- Exit Game
ExitGameEvent.OnServerEvent:Connect(function(player)
	-- Cek debounce
	if teleportingPlayers[player.UserId] then
		warn("Player " .. player.Name .. " is already being teleported.")
		return
	end

	print(player.Name .. " memilih Exit")
	local lobbyId = PlaceData["Lobby"]

	if lobbyId then
		-- Simpan data secara sinkron sebelum teleport
		DataStoreManager:SavePlayerDataYielding(player)

		-- Set debounce
		teleportingPlayers[player.UserId] = true

		-- Panggil TeleportAsync dalam pcall
		local success, result = pcall(function()
			return TeleportService:TeleportAsync(lobbyId, {player})
		end)

		if success then
			print("Successfully initiated teleport for " .. player.Name .. " to Lobby (ID: " .. lobbyId .. ")")
		else
			warn("TeleportAsync failed for " .. player.Name .. ": " .. tostring(result))
		end

		-- Hapus debounce setelah beberapa saat, meskipun gagal
		task.delay(5, function()
			teleportingPlayers[player.UserId] = nil
		end)
	else
		warn("Lobby place ID not found in PlaceData.")
	end

	-- Reset game
	ResetGame()
end)

-- Update jumlah pemain ketika pemain bergabung atau keluar
game.Players.PlayerAdded:Connect(function(player)
	-- PANGGILAN LANGSUNG: Buat leaderstats segera dan secara sinkron.
	if PointsSystem and type(PointsSystem.SetupPlayer) == "function" then
		PointsSystem.SetupPlayer(player)
	end

	updatePlayerCount()

	-- Memulai pemuatan data non-blocking di latar belakang.
	DataStoreManager:LoadPlayerData(player)

	-- Inisialisasi sistem lain dalam thread terpisah untuk tidak menahan proses join.
	task.spawn(function()
		-- Tunggu hingga data pemain benar-benar dimuat.
		local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
		if not player.Parent then return end -- Pemain mungkin keluar saat data sedang dimuat

		-- Tugas lain yang bergantung pada data dapat tetap di sini.
	end)

	-- Kirim mode permainan saat ini ke pemain yang baru bergabung (ini bisa segera dilakukan).
	local gameSettingsUpdateEvent = RemoteEvents:FindFirstChild("GameSettingsUpdateEvent")
	if gameSettingsUpdateEvent then
		gameSettingsUpdateEvent:FireClient(player, {gameMode = gameMode, difficulty = difficulty})
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	-- Penyimpanan data pemain ditangani secara otomatis oleh DataStoreManager
	-- melalui event PlayerRemoving yang terhubung di dalam modul itu sendiri.
	updatePlayerCount()
end)

-- Update jumlah pemain ketika status knocked berubah
-- Update jumlah pemain ketika status knocked berubah atau pemain mati
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Pemicu untuk saat pemain di-knock
		character.ChildAdded:Connect(function(child)
			if child.Name == "Knocked" then
				updatePlayerCount()
			end
		end)
		character.ChildRemoved:Connect(function(child)
			if child.Name == "Knocked" then
				updatePlayerCount()
			end
		end)

		-- Pemicu baru untuk saat pemain mati
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			-- Tambahkan jeda singkat untuk memastikan status "Knocked" (jika ada) sudah direplikasi
			task.wait(0.1)
			updatePlayerCount()
		end)
	end)
end)

-- Jika satu pemain meminta buka UI start, tampilkan ke semua client
OpenStartUIEvent.OnServerEvent:Connect(function(_player)
	if gameStarted then return end
	-- reset progres ready setiap kali sesi baru pemungutan siap dimulai
	readyPlayers = {}
	-- update total lalu broadcast tampilkan UI
	updatePlayerCount()
	ReadyCountEvent:FireAllClients(0, #game.Players:GetPlayers())
	OpenStartUIEvent:FireAllClients() -- client akan showFrame()
	-- Mulai sesi voting baru + timer 30 detik
	currentVoteSession += 1
	local mySession = currentVoteSession

	task.spawn(function()
		for t = 30, 0, -1 do
			-- Jika game sudah mulai atau sesi tergantikan, hentikan timer
			if gameStarted or currentVoteSession ~= mySession then
				return
			end
			StartVoteCountdownEvent:FireAllClients(t)
			task.wait(1)
		end

		-- Sampai sini: waktu habis. Jika belum mulai dan masih sesi ini, batalkan voting.
		if not gameStarted and currentVoteSession == mySession then
			-- Cek progres siap
			local total = #game.Players:GetPlayers()
			local ready = 0
			for _, plr in ipairs(game.Players:GetPlayers()) do
				if readyPlayers[plr.UserId] then
					ready += 1
				end
			end

			if ready < total then
				readyPlayers = {} -- reset daftar yang sudah siap
				StartVoteCanceledEvent:FireAllClients() -- minta client tutup UI & mulai lagi
				-- (opsional) kirim progres reset
				ReadyCountEvent:FireAllClients(0, total)
			end
		end
	end)
end)
