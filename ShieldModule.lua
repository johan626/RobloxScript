-- ShieldModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/ShieldModule.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Pastikan RemoteEvent untuk pembaruan UI ada
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder", ReplicatedStorage)
RemoteEvents.Name = "RemoteEvents"

local ShieldUpdateEvent = RemoteEvents:FindFirstChild("ShieldUpdateEvent") or Instance.new("RemoteEvent", RemoteEvents)
ShieldUpdateEvent.Name = "ShieldUpdateEvent"

local ShieldModule = {}
-- Menyimpan data perisai untuk setiap pemain: { [UserId] = { Current = 0, Max = 0 } }
local playerShields = {}

-- Fungsi untuk mendapatkan atau menginisialisasi data perisai pemain
local function getShieldData(player)
	if not playerShields[player.UserId] then
		playerShields[player.UserId] = {
			Current = 0,
			Max = 0
		}
	end
	return playerShields[player.UserId]
end

-- Fungsi untuk mengirim pembaruan ke client
local function updateClient(player)
	local data = getShieldData(player)
	-- Kirim data perisai saat ini dan maksimal untuk digunakan oleh UI bar
	ShieldUpdateEvent:FireClient(player, data.Current, data.Max)
end

-- Mengatur perisai pemain ke jumlah tertentu
function ShieldModule.Set(player, amount)
	if not player then return end
	local data = getShieldData(player)
	local newAmount = math.max(0, amount)
	data.Max = newAmount
	data.Current = newAmount
	print(string.format("Shield set for %s: %d/%d", player.Name, data.Current, data.Max))
	updateClient(player)
end

-- Menambah perisai pemain
function ShieldModule.Add(player, amount)
	if not player or not amount or amount <= 0 then return end
	local data = getShieldData(player)
	-- Jika pemain tidak memiliki perisai maks, penambahan ini akan menetapkannya
	if data.Max == 0 then
		data.Max = amount
	end
	data.Current = math.min(data.Max, data.Current + amount)
	print(string.format("Added %d shield to %s. New shield: %d/%d", amount, player.Name, data.Current, data.Max))
	updateClient(player)
end


-- Mengurangi perisai akibat kerusakan dan mengembalikan sisa kerusakan
function ShieldModule.Damage(player, damageAmount)
	if not player or not damageAmount or damageAmount <= 0 then
		return damageAmount -- Kembalikan kerusakan asli jika argumen tidak valid
	end

	local data = getShieldData(player)
	if data.Current <= 0 then
		return damageAmount -- Tidak ada perisai untuk menyerap kerusakan
	end

	local absorbedDamage = math.min(data.Current, damageAmount)
	local leftoverDamage = damageAmount - absorbedDamage

	data.Current = data.Current - absorbedDamage
	print(string.format("Shield for %s took %d damage. Remaining shield: %d. Leftover damage: %d", player.Name, absorbedDamage, data.Current, leftoverDamage))

	updateClient(player)

	return leftoverDamage
end

-- Mendapatkan nilai perisai pemain saat ini
function ShieldModule.Get(player)
	if not player then return 0 end
	return getShieldData(player).Current
end

-- Mengatur ulang perisai saat karakter spawn
local function onCharacterAdded(character)
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		-- Mengatur ulang perisai menjadi 0 saat respawn.
		-- Booster akan menerapkannya kembali di awal permainan/ronde.
		ShieldModule.Set(player, 0)
	end
end

-- Inisialisasi dan pembersihan data pemain
local function onPlayerAdded(player)
	getShieldData(player) -- Inisialisasi saat bergabung
	player.CharacterAdded:Connect(onCharacterAdded)
end

local function onPlayerRemoving(player)
	if playerShields[player.UserId] then
		playerShields[player.UserId] = nil -- Bersihkan data untuk mencegah kebocoran memori
	end
end

-- Hubungkan ke event pemain
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Untuk pemain yang sudah ada di dalam game saat skrip dijalankan
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

return ShieldModule
