-- PlayerData.lua (Script)
-- Path: ServerScriptService/Script/PlayerData.lua
-- Script Place: Lobby & ACT 1: Village

-- Memuat modul DataStoreManager agar sistemnya aktif
-- Memuat modul-modul penting agar sistemnya aktif
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))
local TitleManager = require(ServerScriptService.ModuleScript:WaitForChild("TitleManager"))
local GlobalMissionManager = require(ServerScriptService.ModuleScript:WaitForChild("GlobeMissionManager"))

-- Tidak ada logika lain yang diperlukan di sini, karena modul-modul
-- sudah menangani event mereka secara internal.
