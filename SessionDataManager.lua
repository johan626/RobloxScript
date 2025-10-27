-- SessionDataManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/SessionDataManager.lua
-- Script Place: ACT 1: Village

local SessionDataManager = {}

-- Contoh: { [player.UserId] = { RandomWeaponPurchases = 2 } }
local sessionData = {}

-- Fungsi untuk mendapatkan data sesi pemain
function SessionDataManager:GetData(player)
	if not sessionData[player.UserId] then
		sessionData[player.UserId] = {}
	end
	return sessionData[player.UserId]
end

-- Fungsi untuk menambah jumlah pembelian senjata acak
function SessionDataManager:IncrementRandomWeaponPurchases(player)
	local data = self:GetData(player)
	data.RandomWeaponPurchases = (data.RandomWeaponPurchases or 0) + 1
	print(("[SessionDataManager] %s now has %d random weapon purchases."):format(player.Name, data.RandomWeaponPurchases))
end

-- Fungsi untuk mendapatkan jumlah pembelian senjata acak
function SessionDataManager:GetRandomWeaponPurchases(player)
	local data = self:GetData(player)
	return data.RandomWeaponPurchases or 0
end

-- Fungsi untuk me-reset semua data sesi
function SessionDataManager:ResetAllSessionData()
	sessionData = {}
	print("[SessionDataManager] Semua data sesi telah di-reset.")
end

-- Membersihkan data pemain saat mereka keluar
game.Players.PlayerRemoving:Connect(function(player)
	if sessionData[player.UserId] then
		sessionData[player.UserId] = nil
	end
end)

return SessionDataManager
