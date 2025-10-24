-- ProfileModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/ProfileModule.lua
-- Script Place: Lobby

local ServerScriptService = game:GetService("ServerScriptService")
local LevelModule = require(ServerScriptService.ModuleScript:WaitForChild("LevelModule"))
local StatsModule = require(ServerScriptService.ModuleScript:WaitForChild("StatsModule"))
local MissionPointsModule = require(ServerScriptService.ModuleScript:WaitForChild("MissionPointsModule")) -- Tambahkan modul Mission Points

local ProfileModule = {}

function ProfileModule.GetProfileData(player)
	if not player then return nil end

	-- Get data from modules
	local levelData = LevelModule.GetData(player)
	local statsData = StatsModule.GetData(player)
	local missionPoints = MissionPointsModule:GetMissionPoints(player) -- Ambil data Mission Points

	-- Prepare the data to be sent to the client
	local profileData = {
		Name = player.Name,
		Level = levelData.Level,
		XP = levelData.XP,
		TotalCoins = statsData.TotalCoins,
		LifetimeAP = statsData.AchievementPoints or 0, -- Tambahkan Lifetime AP
		LifetimeMP = missionPoints or 0, -- Tambahkan Lifetime MP
		TotalKills = statsData.TotalKills,
		TotalDamageDealt = statsData.TotalDamageDealt or 0,
		TotalRevives = statsData.TotalRevives,
		TotalKnocks = statsData.TotalKnocks
	}

	return profileData
end

return ProfileModule
