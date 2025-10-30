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
    playerPoints[player] = 0

    if player and player:IsA("Player") then
        local leaderstats = player:FindFirstChild("leaderstats")

        -- Jika folder leaderstats belum ada, buat.
        if not leaderstats then
            leaderstats = Instance.new("Folder")
            leaderstats.Name = "leaderstats"
            leaderstats.Parent = player
        end

        -- Fungsi helper untuk membuat atau me-reset stat
        local function createOrResetStat(name, value)
            local stat = leaderstats:FindFirstChild(name)
            if not stat then
                stat = Instance.new("IntValue")
                stat.Name = name
                stat.Parent = leaderstats
            end
            stat.Value = value
        end

        -- Buat atau reset semua stats yang diperlukan
        createOrResetStat("BP", 0)
        createOrResetStat("TotalDamage", 0)
        createOrResetStat("Kills", 0)
        createOrResetStat("Knock", 0)
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
	if not playerPoints[player] then return false end

	-- Jika ini adalah pengurangan (pembelian), periksa apakah poin cukup
	if amount < 0 then
		if playerPoints[player] < math.abs(amount) then
			return false -- Poin tidak cukup
		end
	end

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

	return true
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

end

return PointsSystem
