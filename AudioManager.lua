-- AudioManager.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/AudioManager.lua
-- Script Place: ACT 1: Village

local AudioManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Kamus terpusat untuk semua ID aset suara
AudioManager.Sounds = {
	Boss = {
		Alert = "rbxassetid://9119663003", -- Digunakan untuk lock, ambient, warning, whisper
		Complete = "rbxassetid://9119663691", -- Digunakan untuk completion, explosion
		Bass = "rbxassetid://130863833",
	},
	VFX = {
		Poison = "rbxassetid://9117168972",
		Acid = "rbxassetid://138081500",
	},
	Elements = {
		Fire = "rbxassetid://7106659874",
		Ice = "rbxassetid://9118068272",
		Earth = "rbxassetid://9066038215",
		Wind = "rbxassetid://9046003215",
		Placeholder = "rbxassetid://9118068272",
	},
	Weapons = {
		Pistol = { Fire = "rbxassetid://4502821590", Reload = "rbxassetid://8302576808" },
		Rifle = { Fire = "rbxassetid://116169266166053", Reload = "rbxassetid://110520432216161" },
		SMG = { Fire = "rbxassetid://87534588983395", Reload = "rbxassetid://801171060" },
		Shotgun = { Fire = "rbxassetid://7282759187", Reload = "rbxassetid://145081845" },
		Sniper = { Fire = "rbxassetid://5679835770", Reload = "rbxassetid://7641927705" },
		LMG = { Fire = "rbxassetid://5679835770", Reload = "rbxassetid://7641927705" },
		Empty = "rbxassetid://9113104337",
	}
}

--[[
    Membuat dan mengkonfigurasi instance suara, tetapi tidak memutarnya.
    Mengembalikan instance suara untuk kontrol manual.
]]
function AudioManager.createSound(soundPath, parent, properties)
	local path = string.split(soundPath, ".")
	local soundId

	local currentTable = AudioManager.Sounds
	for i, key in ipairs(path) do
		if type(currentTable) == "table" and currentTable[key] then
			if i == #path then
				soundId = currentTable[key]
			else
				currentTable = currentTable[key]
			end
		else
			warn("AudioManager: Tidak dapat menemukan suara di jalur:", soundPath)
			return
		end
	end

	if soundId then
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Parent = parent or workspace

		if properties and type(properties) == "table" then
			for prop, value in pairs(properties) do
				sound[prop] = value
			end
		end

		return sound
	else
		warn("AudioManager: Jalur suara tidak valid:", soundPath)
	end
end

--[[
    Membuat, mengkonfigurasi, dan memutar suara. Wrapper di sekitar createSound.
    PENTING: Penelepon bertanggung jawab untuk membersihkan.
]]
function AudioManager.playSound(soundPath, parent, properties)
	local sound = AudioManager.createSound(soundPath, parent, properties)
	if sound then
		sound:Play()
	end
	return sound
end

return AudioManager
