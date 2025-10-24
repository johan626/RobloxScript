-- LeaderboardConfig.lua
-- Path: ReplicatedStorage/LeaderboardConfig.lua
-- Script Place: Lobby

local LeaderboardConfig = {
	AP = {
		PartName = "APLeaderboard",
		DataStoreName = "APLeaderboard_v1",
		Title = "TOP 10 ACHIEVEMENT POINTS",
		ValueKey = "AP",
		ValuePrefix = "",
		Face = Enum.NormalId.Front
	},
	Kills = {
		PartName = "KillLeaderboard",
		DataStoreName = "KillsLeaderboard_v1",
		Title = "TOP 10 KILLERS",
		ValueKey = "Kills",
		ValuePrefix = "",
		Face = Enum.NormalId.Front
	},
	Level = {
		PartName = "LVLeaderboard",
		DataStoreName = "LevelLeaderboard_v1",
		Title = "TOP 10 LEVEL",
		ValueKey = "Level",
		ValuePrefix = "Lv. ",
		Face = Enum.NormalId.Front
	},
	MP = {
		PartName = "MPLeaderboard",
		DataStoreName = "MPLeaderboard_v1",
		Title = "TOP 10 MISSION POINTS",
		ValueKey = "MP",
		ValuePrefix = "",
		Face = Enum.NormalId.Front
	},
	TD = {
		PartName = "TDLeaderboard",
		DataStoreName = "TDLeaderboard_v1",
		Title = "TOP 10 TOTAL DAMAGE",
		ValueKey = "TD",
		ValuePrefix = "",
		Face = Enum.NormalId.Front
	}
}

return LeaderboardConfig
