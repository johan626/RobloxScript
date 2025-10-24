-- LeaderboardManager.lua (Script)
-- Path: ServerScriptService/Script/LeaderboardManager.lua
-- Script Place: Lobby
-- This script manages all leaderboards in a centralized way.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Load necessary modules and data
local PlaceData = require(ServerScriptService.ModuleScript:WaitForChild("PlaceDataConfig"))
local LeaderboardConfig = require(ReplicatedStorage:WaitForChild("LeaderboardConfig"))

-- Ensure this script only runs in the lobby
if game.PlaceId ~= PlaceData["Lobby"] then
	return
end

-- --- Remote Objects Setup ---
local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteObjects")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "RemoteObjects"
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
-- This loop creates a RemoteFunction for each leaderboard defined in the config.
for key, config in pairs(LeaderboardConfig) do
	local functionName = "GetLeaderboard_" .. key

	-- Create a RemoteFunction for fetching the data
	local getLeaderboardFunction = remoteFolder:FindFirstChild(functionName)
	if not getLeaderboardFunction then
		getLeaderboardFunction = Instance.new("RemoteFunction")
		getLeaderboardFunction.Name = functionName
		getLeaderboardFunction.Parent = remoteFolder
	end

	-- Access the specific DataStore for this leaderboard
	local leaderboardStore = DataStoreService:GetOrderedDataStore(config.DataStoreName)

	-- Set the callback function for this specific leaderboard
	getLeaderboardFunction.OnServerInvoke = function(player)
		local topPlayersData = {}
		local playerInfo = {Rank = nil, Score = nil}

		-- 1. Fetch top 50 players
		local success, pages = pcall(function()
			return leaderboardStore:GetSortedAsync(false, 50)
		end)

		if not success then
			warn("LeaderboardService: Failed to fetch top players for " .. key .. ". Error: " .. tostring(pages))
			return nil -- Return nil to indicate failure
		end

		local topPlayersPage = pages:GetCurrentPage()
		for rank, data in ipairs(topPlayersPage) do
			local userId = tonumber(data.key)
			local value = data.value
			local username = "Player"

			local nameSuccess, nameResult = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)

			if nameSuccess then
				username = nameResult
			end

			local playerData = {
				Rank = rank,
				Username = username,
				UserId = userId
			}
			playerData[config.ValueKey] = value
			table.insert(topPlayersData, playerData)
		end

		-- 2. Fetch the current player's score
		local scoreSuccess, score = pcall(function()
			return leaderboardStore:GetAsync(tostring(player.UserId))
		end)

		if scoreSuccess and score then
			playerInfo.Score = score
			-- Check if the player is in the top 50 to find their rank
			for _, topPlayer in ipairs(topPlayersData) do
				if topPlayer.UserId == player.UserId then
					playerInfo.Rank = topPlayer.Rank
					break
				end
			end
		else
			warn("LeaderboardService: Could not get score for player " .. player.UserId)
		end

		-- 3. Return both lists
		return {
			TopPlayers = topPlayersData,
			PlayerInfo = playerInfo
		}
	end

	print("LeaderboardService: Initialized leaderboard for " .. key)
end

-- --- Global Countdown Loop ---
-- This single loop controls the update cycle for all leaderboards.
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
