-- PointsModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/PointsModule.lua
-- Script Place: ACT 1: Village

local PointsSystem = {}

local playerPoints = {}

-- Tambahkan ini di atas
local ServerScriptService = game:GetService("ServerScriptService")
local LevelManager = require(ServerScriptService.ModuleScript:WaitForChild("LevelModule"))

function PointsSystem.SetupPlayer(player)
	-- simpan poin internal
	playerPoints[player] = 10000

	-- buat folder leaderstats (sementara) dan tiga IntValue
	if player and player:IsA("Player") then
		-- jika sudah ada leaderstats, reset nilainya
		if player:FindFirstChild("leaderstats") then
			player.leaderstats:Destroy()
		end

		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		local bp = Instance.new("IntValue")
		bp.Name = "BP"
		bp.Value = 0
		bp.Parent = leaderstats

		local totalDamage = Instance.new("IntValue")
		totalDamage.Name = "TotalDamage"
		totalDamage.Value = 0
		totalDamage.Parent = leaderstats

		local kills = Instance.new("IntValue")
		kills.Name = "Kills"
		kills.Value = 0
		kills.Parent = leaderstats	

		local knocks = Instance.new("IntValue")
		knocks.Name = "Knock"
		knocks.Value = 0
		knocks.Parent = leaderstats
	end
end

function PointsSystem.RemovePlayer(player)
	playerPoints[player] = nil
	-- bersihkan leaderstats bila ada
	if player and player:FindFirstChild("leaderstats") then
		player.leaderstats:Destroy()
	end
end

function PointsSystem.AddPoints(player, amount)
	if not playerPoints[player] then return end
	playerPoints[player] += amount

	-- update leaderstats BP bila ada
	if player and player:FindFirstChild("leaderstats") then
		local bpVal = player.leaderstats:FindFirstChild("BP")
		if bpVal then
			bpVal.Value = playerPoints[player] or 0
		end
	end

	-- update ke client (UI)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local PointsUpdate = ReplicatedStorage.RemoteEvents:FindFirstChild("PointsUpdate")
	if PointsUpdate then
		PointsUpdate:FireClient(player, playerPoints[player])
	end
end

function PointsSystem.GetPoints(player)
	return playerPoints[player] or 0
end

-- increment kills leaderstat (dipanggil dari ZombieModule saat ada killer)
function PointsSystem.AddKill(player)
	if not player or not player:IsA("Player") then return end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local v = ls:FindFirstChild("Kills")
		if v then v.Value = v.Value + 1 end
	end
end

-- increment knock leaderstat (dipanggil saat player knock)
function PointsSystem.AddKnock(player)
	if not player or not player:IsA("Player") then return end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local v = ls:FindFirstChild("Knock")
		if v then v.Value = v.Value + 1 end
	end
end

function PointsSystem.AddDamage(player, damageAmount)
	if not player or not player:IsA("Player") then return end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local v = ls:FindFirstChild("TotalDamage")
		if v then
			v.Value = v.Value + damageAmount
		end
	end

	-- Integrasi dengan LevelManager: 1 damage = 1 XP
	if LevelManager then
		LevelManager.AddXP(player, damageAmount)
	end
end

return PointsSystem
