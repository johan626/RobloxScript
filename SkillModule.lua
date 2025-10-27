-- SkillModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/SkillModule.lua
-- Script Place: Lobby & ACT 1: Village

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local StatsModule = require(ServerScriptService.ModuleScript:WaitForChild("StatsModule"))
local CoinsModule = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))
-- Memuat konfigurasi skill dari modul terpusat
local SkillConfig = require(ReplicatedStorage.ModuleScript:WaitForChild("SkillConfig"))

local SkillModule = {}

-- Tabel untuk melacak waktu permintaan terakhir dari setiap pemain (untuk debounce)
local lastUpgradeRequest = {}
local DEBOUNCE_TIME = 0.5 -- Detik

-- Remote Events and Functions
local remoteFolder = ReplicatedStorage:FindFirstChild("SkillRemotes") or Instance.new("Folder", ReplicatedStorage)
remoteFolder.Name = "SkillRemotes"

-- Mengganti RemoteEvent dengan RemoteFunction untuk mendapatkan feedback langsung
-- Menggunakan RemoteEvent untuk komunikasi asinkron
if remoteFolder:FindFirstChild("UpgradeSkillFunc") then
	remoteFolder:FindFirstChild("UpgradeSkillFunc"):Destroy() -- Hapus RemoteFunction lama jika ada
end
local upgradeSkillRequestEvent = remoteFolder:FindFirstChild("UpgradeSkillRequestEvent") or Instance.new("RemoteEvent", remoteFolder)
upgradeSkillRequestEvent.Name = "UpgradeSkillRequestEvent"

local upgradeSkillResultEvent = remoteFolder:FindFirstChild("UpgradeSkillResultEvent") or Instance.new("RemoteEvent", remoteFolder)
upgradeSkillResultEvent.Name = "UpgradeSkillResultEvent"

local getSkillDataFunc = remoteFolder:FindFirstChild("GetSkillDataFunc") or Instance.new("RemoteFunction", remoteFolder)
getSkillDataFunc.Name = "GetSkillDataFunc"

local getResetCostFunc = remoteFolder:FindFirstChild("GetResetCostFunc") or Instance.new("RemoteFunction", remoteFolder)
getResetCostFunc.Name = "GetResetCostFunc"

local resetSkillsRequestEvent = remoteFolder:FindFirstChild("ResetSkillsRequestEvent") or Instance.new("RemoteEvent", remoteFolder)
resetSkillsRequestEvent.Name = "ResetSkillsRequestEvent"

local resetSkillsResultEvent = remoteFolder:FindFirstChild("ResetSkillsResultEvent") or Instance.new("RemoteEvent", remoteFolder)
resetSkillsResultEvent.Name = "ResetSkillsResultEvent"

--[[ Remotes untuk Reset Single Skill ]]
local getSingleResetCostFunc = remoteFolder:FindFirstChild("GetSingleResetCostFunc") or Instance.new("RemoteFunction", remoteFolder)
getSingleResetCostFunc.Name = "GetSingleResetCostFunc"

local resetSingleSkillRequestEvent = remoteFolder:FindFirstChild("ResetSingleSkillRequestEvent") or Instance.new("RemoteEvent", remoteFolder)
resetSingleSkillRequestEvent.Name = "ResetSingleSkillRequestEvent"

local resetSingleSkillResultEvent = remoteFolder:FindFirstChild("ResetSingleSkillResultEvent") or Instance.new("RemoteEvent", remoteFolder)
resetSingleSkillResultEvent.Name = "ResetSingleSkillResultEvent"


function SkillModule.GetSkillData(player)
	local data = StatsModule.GetData(player)
	-- Pastikan semua skill dari config ada di data pemain
	if not data.Skills then
		data.Skills = {}
	end
	for skillName, config in pairs(SkillConfig) do
		if config.IsCategorized then
			if not data.Skills[skillName] then
				data.Skills[skillName] = {}
			end
			for categoryKey, _ in pairs(config.Categories) do
				if data.Skills[skillName][categoryKey] == nil then
					data.Skills[skillName][categoryKey] = 0
				end
			end
		else
			if data.Skills[skillName] == nil then
				data.Skills[skillName] = 0
			end
		end
	end

	return {
		SkillPoints = data.SkillPoints or 0,
		Skills = data.Skills
	}
end

function SkillModule.AddSkillPoint(player)
	local data = StatsModule.GetData(player)
	data.SkillPoints = (data.SkillPoints or 0) + 1
	StatsModule.SaveData(player, data)
end

function SkillModule.UpgradeSkill(player, skillName, categoryName)
	-- 1. Validasi dasar
	if not player then return { success = false, message = "Invalid player." } end

	local config = SkillConfig[skillName]
	if not config then
		return { success = false, message = "Skill tidak ditemukan." }
	end

	-- Validasi kategori jika ada
	if config.IsCategorized and (not categoryName or not config.Categories[categoryName]) then
		return { success = false, message = "Kategori skill tidak valid." }
	end

	-- 2. Debounce untuk mencegah race condition/spam
	local now = tick()
	if lastUpgradeRequest[player.UserId] and (now - lastUpgradeRequest[player.UserId]) < DEBOUNCE_TIME then
		return { success = false, message = "Harap tunggu sebentar." }
	end
	lastUpgradeRequest[player.UserId] = now

	-- 3. Logika upgrade
	local data = StatsModule.GetData(player)
	local skillPoints = data.SkillPoints or 0
	if skillPoints <= 0 then
		return { success = false, message = "Skill point tidak cukup." }
	end

	if not data.Skills then
		data.Skills = {}
	end

	if config.IsCategorized then
		-- Logika untuk skill dengan kategori
		if not data.Skills[skillName] then
			data.Skills[skillName] = {}
		end
		local currentLevel = data.Skills[skillName][categoryName] or 0
		if currentLevel >= config.MaxLevel then
			return { success = false, message = "Skill sudah mencapai level maksimal." }
		end
		data.Skills[skillName][categoryName] = currentLevel + 1
	else
		-- Logika untuk skill biasa
		local currentLevel = data.Skills[skillName] or 0
		if currentLevel >= config.MaxLevel then
			return { success = false, message = "Skill sudah mencapai level maksimal." }
		end
		data.Skills[skillName] = currentLevel + 1
	end

	data.SkillPoints = skillPoints - 1
	StatsModule.SaveData(player, data)

	-- Hapus timestamp setelah berhasil agar tidak mengganggu request berikutnya
	lastUpgradeRequest[player.UserId] = nil

	-- 4. Kembalikan data terbaru
	return { success = true, message = "Skill berhasil diupgrade!", newData = SkillModule.GetSkillData(player) }
end

function SkillModule.GetResetCost(player)
	local data = StatsModule.GetData(player)
	local resetCount = data.SkillResetCount or 0
	return 5000 * (2 ^ resetCount)
end

function SkillModule.ResetSkills(player)
	-- 1. Validasi
	if not player then return { success = false, message = "Invalid player." } end

	-- 2. Dapatkan data dan hitung biaya
	local statsData = StatsModule.GetData(player)
	local cost = SkillModule.GetResetCost(player)

	-- 3. Cek koin
	local coinData = CoinsModule.GetData(player)
	if coinData.Coins < cost then
		return { success = false, message = "Koin tidak cukup untuk reset." }
	end

	-- 4. Hitung total poin skill yang dihabiskan
	local spentSkillPoints = 0
	if statsData.Skills then
		for skillName, levels in pairs(statsData.Skills) do
			local config = SkillConfig[skillName]
			if config then
				if config.IsCategorized then
					for _, level in pairs(levels) do
						spentSkillPoints = spentSkillPoints + level
					end
				else
					spentSkillPoints = spentSkillPoints + levels
				end
			end
		end
	end

	-- 5. Lakukan transaksi dan update data
	local success = CoinsModule.SubtractCoins(player, cost)
	if not success then
		return { success = false, message = "Gagal mengurangi koin." }
	end

	-- Kembalikan poin skill
	statsData.SkillPoints = (statsData.SkillPoints or 0) + spentSkillPoints

	-- Reset semua skill ke level 0
	statsData.Skills = {}
	for skillName, config in pairs(SkillConfig) do
		if config.IsCategorized then
			statsData.Skills[skillName] = {}
			for categoryKey, _ in pairs(config.Categories) do
				statsData.Skills[skillName][categoryKey] = 0
			end
		else
			statsData.Skills[skillName] = 0
		end
	end

	-- Tingkatkan biaya reset untuk selanjutnya
	statsData.SkillResetCount = (statsData.SkillResetCount or 0) + 1

	-- Simpan perubahan
	StatsModule.SaveData(player, statsData)

	-- 6. Kembalikan hasil
	return { success = true, message = "Skill berhasil direset!", newData = SkillModule.GetSkillData(player) }
end

function SkillModule.GetSingleSkillResetCost(player, skillName, categoryName)
	local data = StatsModule.GetData(player)
	if not data.Skills or not data.Skills[skillName] then
		return 0
	end

	local config = SkillConfig[skillName]
	if not config then return 0 end

	local currentLevel
	if config.IsCategorized then
		if not categoryName or not data.Skills[skillName][categoryName] then
			return 0
		end
		currentLevel = data.Skills[skillName][categoryName]
	else
		currentLevel = data.Skills[skillName]
	end

	-- Biaya = Level saat ini * 500 koin
	return (currentLevel or 0) * 500
end

function SkillModule.ResetSingleSkill(player, skillName, categoryName)
	-- NOTE: Investigasi pada SkillConfig.lua menunjukkan tidak ada sistem dependensi
	-- antar skill (misalnya, Skill A menjadi prasyarat untuk Skill B).
	-- Oleh karena itu, logika tambahan untuk menangani dependensi tidak diperlukan.
	-- Mereset satu skill tidak akan memengaruhi validitas skill lain.

	-- 1. Validasi
	if not player then return { success = false, message = "Invalid player." } end

	local config = SkillConfig[skillName]
	if not config then
		return { success = false, message = "Skill tidak ditemukan." }
	end
	if config.IsCategorized and (not categoryName or not config.Categories[categoryName]) then
		return { success = false, message = "Kategori skill tidak valid." }
	end

	-- 2. Dapatkan data dan hitung biaya
	local statsData = StatsModule.GetData(player)
	local cost = SkillModule.GetSingleSkillResetCost(player, skillName, categoryName)
	local currentLevel = 0
	if statsData.Skills and statsData.Skills[skillName] then
		if config.IsCategorized then
			currentLevel = statsData.Skills[skillName][categoryName] or 0
		else
			currentLevel = statsData.Skills[skillName] or 0
		end
	end

	if currentLevel <= 0 then
		return { success = false, message = "Skill ini belum diupgrade." }
	end

	-- 3. Cek koin
	local coinData = CoinsModule.GetData(player)
	if coinData.Coins < cost then
		return { success = false, message = "Koin tidak cukup untuk reset." }
	end

	-- 4. Lakukan transaksi dan update data
	local success = CoinsModule.SubtractCoins(player, cost)
	if not success then
		return { success = false, message = "Gagal mengurangi koin." }
	end

	-- Kembalikan poin skill sebanyak level yang direset
	statsData.SkillPoints = (statsData.SkillPoints or 0) + currentLevel

	-- Reset skill spesifik ke level 0
	if config.IsCategorized then
		statsData.Skills[skillName][categoryName] = 0
	else
		statsData.Skills[skillName] = 0
	end

	-- Simpan perubahan
	StatsModule.SaveData(player, statsData)

	-- 5. Kembalikan hasil
	return { success = true, message = "Skill berhasil direset!", newData = SkillModule.GetSkillData(player) }
end


-- Remote function handler
-- Event handler untuk permintaan upgrade
local function onUpgradeRequested(player, skillName, categoryName)
	local result = SkillModule.UpgradeSkill(player, skillName, categoryName)
	-- Tambahkan identifier ke hasil agar klien tahu skill mana yang diupdate
	result.skillName = skillName
	result.categoryName = categoryName
	upgradeSkillResultEvent:FireClient(player, result)
end

upgradeSkillRequestEvent.OnServerEvent:Connect(onUpgradeRequested)

getSkillDataFunc.OnServerInvoke = function(player)
	return SkillModule.GetSkillData(player)
end

getResetCostFunc.OnServerInvoke = function(player)
	return SkillModule.GetResetCost(player)
end

local function onResetSkillsRequested(player)
	local result = SkillModule.ResetSkills(player)
	resetSkillsResultEvent:FireClient(player, result)
end

resetSkillsRequestEvent.OnServerEvent:Connect(onResetSkillsRequested)

getSingleResetCostFunc.OnServerInvoke = function(player, skillName, categoryName)
	return SkillModule.GetSingleSkillResetCost(player, skillName, categoryName)
end

local function onResetSingleSkillRequested(player, skillName, categoryName)
	local result = SkillModule.ResetSingleSkill(player, skillName, categoryName)
	resetSingleSkillResultEvent:FireClient(player, result)
end

resetSingleSkillRequestEvent.OnServerEvent:Connect(onResetSingleSkillRequested)


-- Membersihkan data pemain dari tabel debounce saat mereka keluar
Players.PlayerRemoving:Connect(function(player)
	if lastUpgradeRequest[player.UserId] then
		lastUpgradeRequest[player.UserId] = nil
	end
end)


return SkillModule
