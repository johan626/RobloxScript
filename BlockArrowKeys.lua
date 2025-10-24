-- BlockArrowKeys.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/BlockArrowKeys.lua
-- Script Place: ACT 1: Village

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

-- Nama aksi unik agar mudah di-unbind kalau perlu
local ACTION_NAME = "BlockArrowKeysForMovementAndCamera"

-- Callback yang "menyerap" input arrow keys
local function blockArrowKeys(actionName, inputState, inputObject)
	-- Kalau sedang ngetik di TextBox, jangan blokir (biar bisa navigasi teks)
	if UserInputService:GetFocusedTextBox() then
		return Enum.ContextActionResult.Pass
	end

	-- Serap semua state (Begin/Change/End) supaya tidak diteruskan ke kontrol default
	return Enum.ContextActionResult.Sink
end

-- Bind dengan prioritas tinggi agar menimpa kontrol movement/camera bawaan
ContextActionService:BindActionAtPriority(
	ACTION_NAME,
	blockArrowKeys,
	false, -- tidak perlu tombol touch
	Enum.ContextActionPriority.High.Value,
	Enum.KeyCode.Left,
	Enum.KeyCode.Right,
	Enum.KeyCode.Up,
	Enum.KeyCode.Down
)
