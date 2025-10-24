-- JumpManager.lua (Script) 
-- Path: ServerScriptService/Script/JumpManager.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")

-- Atur nilai default di sini:
local DEFAULT_JUMP_POWER = 30
local USE_JUMP_POWER = true

local function setupHumanoid(humanoid)
	if not humanoid or not humanoid:IsA("Humanoid") then return end
	-- Pastikan properti ada (safety)
	pcall(function()
		humanoid.UseJumpPower = USE_JUMP_POWER
		humanoid.JumpPower = DEFAULT_JUMP_POWER
	end)
end

local function onCharacterAdded(character)
	-- Character kadang belum punya Humanoid segera, tunggu sebentar
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
	setupHumanoid(humanoid)
end

local function onPlayerAdded(player)
	-- Jika player sudah punya character (mis. ketika script reload), pasang juga
	if player.Character then
		onCharacterAdded(player.Character)
	end
	-- Pasang handler untuk respawn/character baru
	player.CharacterAdded:Connect(onCharacterAdded)
end

-- Pasang handler untuk pemain yang join setelah server start
Players.PlayerAdded:Connect(onPlayerAdded)

-- Tangani pemain yang sudah ada (jika script dimuat ulang saat ada pemain online)
for _, player in ipairs(Players:GetPlayers()) do
	spawn(function() -- ajak asynchronous kecil supaya tidak blocking
		onPlayerAdded(player)
	end)
end
