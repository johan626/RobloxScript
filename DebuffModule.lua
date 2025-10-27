-- DebuffModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/DebuffModule.lua
-- Script Place: ACT 1: Village

local DebuffManager = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local debuffStatusEvent = RemoteEvents:WaitForChild("DebuffStatusEvent")

-- Tabel untuk melacak semua debuff kecepatan aktif per pemain
local activeSpeedDebuffs = {}

-- Fungsi untuk menerapkan atau menyegarkan debuff kecepatan
function DebuffManager.ApplySpeedDebuff(player, debuffName, multiplier, duration)
	if not player or not player.Character then return end

	local userId = player.UserId
	if not activeSpeedDebuffs[userId] then
		activeSpeedDebuffs[userId] = {}
	end

	local wasSlowed = DebuffManager.GetSpeedMultiplier(player) < 1

	activeSpeedDebuffs[userId][debuffName] = {
		multiplier = multiplier,
		endTime = tick() + duration
	}

	-- Beri tahu klien bahwa mereka sekarang diperlambat
	if not wasSlowed then
		debuffStatusEvent:FireClient(player, true)
	end
end

-- Fungsi internal untuk membersihkan debuff yang sudah kedaluwarsa
function DebuffManager._updateDebuffs()
	local now = tick()
	for userId, debuffs in pairs(activeSpeedDebuffs) do
		local player = game:GetService("Players"):GetPlayerByUserId(userId)
		if player then
			local wasSlowed = DebuffManager.GetSpeedMultiplier(player) < 1

			for name, data in pairs(debuffs) do
				if now > data.endTime then
					activeSpeedDebuffs[userId][name] = nil
				end
			end

			local isNowSlowed = DebuffManager.GetSpeedMultiplier(player) < 1

			-- Jika status perlambatan berubah, beri tahu klien
			if wasSlowed and not isNowSlowed then
				debuffStatusEvent:FireClient(player, false)
			end
		end
	end
end

-- Fungsi untuk mendapatkan pengganda kecepatan terendah (prioritas tertinggi) untuk seorang pemain
function DebuffManager.GetSpeedMultiplier(player)
	if not player or not player.Character then return 1 end

	local userId = player.UserId
	local debuffs = activeSpeedDebuffs[userId]
	if not debuffs then return 1 end

	local lowestMultiplier = 1
	for _, data in pairs(debuffs) do
		if data.multiplier < lowestMultiplier then
			lowestMultiplier = data.multiplier
		end
	end

	return lowestMultiplier
end

-- Jalankan pembaruan pada setiap detak jantung server
RunService.Heartbeat:Connect(function()
	DebuffManager._updateDebuffs()
end)

return DebuffManager
