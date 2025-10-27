-- LeaderboardManager.lua (Script)
-- Path: ServerScriptService/Script/LeaderboardManager.lua
-- Script Place: Lobby
-- This script manages all leaderboards in a centralized way.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Load necessary modules and data
local PlaceData = require(ServerScriptService.ModuleScript:WaitForChild("PlaceDataConfig"))
local LeaderboardConfig = require(ReplicatedStorage:WaitForChild("LeaderboardConfig"))
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))

-- Ensure this script only runs in the lobby
if game.PlaceId ~= PlaceData["Lobby"] then
	return
end

-- --- Remote Objects Setup ---
-- --- Remote Functions Setup ---
local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "RemoteFunctions"
	remoteFolder.Parent = ReplicatedStorage
end

-- Create a single, global countdown value
local countdownValue = remoteFolder:FindFirstChild("LeaderboardCountdown")
if not countdownValue then
	countdownValue = Instance.new("NumberValue")
	countdownValue.Name = "LeaderboardCountdown"
	countdownValue.Parent = remoteFolder
end
countdownValue.Value = 60 -- Set initial value

-- --- Leaderboard Initialization Loop ---
for key, config in pairs(LeaderboardConfig) do
	local functionName = "GetLeaderboard_" .. key
	local leaderboardName = config.DataStoreName

	local getLeaderboardFunction = remoteFolder:FindFirstChild(functionName)
	if not getLeaderboardFunction then
		getLeaderboardFunction = Instance.new("RemoteFunction")
		getLeaderboardFunction.Name = functionName
		getLeaderboardFunction.Parent = remoteFolder
	end

	-- Set the callback function using the new DataStoreManager
	getLeaderboardFunction.OnServerInvoke = function(player)
		-- 1. Fetch top 50 players from DataStoreManager
		local topPlayersRaw = DataStoreManager:GetLeaderboardData(leaderboardName, false, 50)
		if not topPlayersRaw then
			warn("LeaderboardManager: Failed to fetch top players for " .. key)
			return nil
		end

		local topPlayersData = {}
		for rank, data in ipairs(topPlayersRaw) do
			local userId = tonumber(data.key)
			local value = data.value
			local username = "Player"

			-- Safely get username
			local nameSuccess, nameResult = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
			if nameSuccess then username = nameResult end

			local playerData = {
				Rank = rank,
				Username = username,
				UserId = userId
			}
			playerData[config.ValueKey] = value
			table.insert(topPlayersData, playerData)
		end

		-- 2. Fetch the current player's score and rank from DataStoreManager
		local playerScore, playerRank = DataStoreManager:GetPlayerRankInLeaderboard(leaderboardName, player.UserId)

		local playerInfo = {
			Rank = playerRank,
			Score = playerScore
		}

		-- 3. Return both lists
		return {
			TopPlayers = topPlayersData,
			PlayerInfo = playerInfo
		}
	end

	print("LeaderboardService: Initialized leaderboard for " .. key)
end

-- --- Global Countdown Loop ---
task.spawn(function()
	local UPDATE_INTERVAL = 60
	while true do
		for i = UPDATE_INTERVAL, 1, -1 do
			countdownValue.Value = i
			task.wait(1)
		end
	end
end)

print("LeaderboardService.lua: Loaded successfully with a global countdown.")
