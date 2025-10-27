-- LobbyRoomManager.lua (Script)
-- Path: ServerScriptService/Script/LobbyRoomManager.lua
-- Script Place: Lobby

--==============================================================================
--// SERVICES & MODULES
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ServerScriptService = game:GetService("ServerScriptService")

local PlaceData = require(script.Parent.Parent.ModuleScript.PlaceDataConfig)
local BoosterModule = require(ServerScriptService.ModuleScript:WaitForChild("BoosterModule"))
local LevelModule = require(ServerScriptService.ModuleScript:WaitForChild("LevelModule"))

--==============================================================================
--// NETWORKING
--==============================================================================

-- Helper function to ensure a RemoteEvent exists, creating it if it doesn't.
-- This prevents race conditions in live environments where client might fire an event before the server creates it.
local function getOrCreateEvent(name)
	local event = ReplicatedStorage:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = ReplicatedStorage
	end
	return event
end

local lobbyRemote = getOrCreateEvent("LobbyRemote")
local kickPlayerEvent = getOrCreateEvent("KickPlayerFromLobby")
local onKickedEvent = getOrCreateEvent("OnKickedFromLobby")
local updatePlayerBoosterStatusEvent = getOrCreateEvent("UpdatePlayerBoosterStatusEvent")

--==============================================================================
--// STATE
--==============================================================================

--[[
    RoomData = {
        [roomId] = {
            Host = Player,
            Players = {Player},
            MaxPlayers = number,
            IsPrivate = boolean,
            RoomCode = string or nil,
            RoomId = string
        }
    }
]]
local rooms = {}

-- matchmakingQueues[playerCount] = {player1, player2, ...}
-- matchmakingQueues[playerCount][gameMode][difficulty] = {player1, player2, ...}
local matchmakingQueues = {}
local activeCountdowns = {}


--==============================================================================
--// UTILITY FUNCTIONS
--==============================================================================

-- Function to generate a unique room ID/code
local function generateRoomCode()
	-- Simple 5-digit code for now. In a real scenario, you'd want to ensure it's unique.
	return string.format("%05d", math.random(1, 99999))
end

-- Finds and returns the room data a specific player is in
local function getPlayerRoom(player)
	for roomId, roomData in pairs(rooms) do
		for _, p in ipairs(roomData.Players) do
			if p == player then
				return roomData
			end
		end
	end
	return nil
end

--==============================================================================
--// CORE LOGIC: ROOM & PLAYER MANAGEMENT
--==============================================================================

-- Sends updated room information to all players within that room
local function updateRoomInfo(roomData)
	local playersData = {}
	for _, p in ipairs(roomData.Players) do
		local boosterData = BoosterModule.GetData(p)
		local levelData = LevelModule.GetData(p)
		table.insert(playersData, {
			Name = p.Name,
			UserId = p.UserId,
			ActiveBooster = boosterData and boosterData.Active or nil,
			Level = levelData and levelData.Level or 1
		})
	end

	local payload = {
		roomName = roomData.Name,
		roomId = roomData.RoomId,
		hostName = roomData.Host.Name,
		players = playersData,
		maxPlayers = roomData.MaxPlayers,
		roomCode = roomData.RoomCode,
		gameMode = roomData.GameMode, -- Pass game mode to clients
		difficulty = roomData.Difficulty
	}

	for _, p in ipairs(roomData.Players) do
		lobbyRemote:FireClient(p, "roomUpdate", payload)
	end
end

-- Sends an updated list of public rooms to all clients
local function broadcastPublicRoomsUpdate()
	local publicRooms = {}
	for id, data in pairs(rooms) do
		if not data.IsPrivate then
			publicRooms[id] = {
				roomName = data.Name,
				playerCount = #data.Players,
				maxPlayers = data.MaxPlayers,
				hostName = data.Host.Name,
				roomId = data.RoomId,
				gameMode = data.GameMode -- Pass game mode to clients
			}
		end
	end
	lobbyRemote:FireAllClients("publicRoomsUpdate", publicRooms)
end

-- Creates a new room
local function handleCreateRoom(hostPlayer, settings, initialPlayers)
	local roomName = settings.roomName and settings.roomName:gsub("^%s*(.-)%s*$", "%1") or ""
	if roomName == "" then
		roomName = hostPlayer.DisplayName .. "'s Room"
	end

	local maxPlayers = math.clamp(tonumber(settings.maxPlayers) or 4, 2, 8)
	local isPrivate = settings.isPrivate or false
	local gameMode = settings.gameMode or "Story"
	local difficulty = settings.difficulty or "Easy"

	local roomId = generateRoomCode()
	while rooms[roomId] do
		roomId = generateRoomCode()
	end

	local playersInRoom = initialPlayers or {hostPlayer}

	local newRoom = {
		Name = roomName,
		Host = hostPlayer,
		Players = playersInRoom,
		MaxPlayers = maxPlayers,
		IsPrivate = isPrivate,
		RoomCode = isPrivate and roomId or nil,
		RoomId = roomId,
		GameMode = gameMode,
		Difficulty = difficulty
	}

	rooms[roomId] = newRoom
	print(string.format("Room '%s' created. ID: %s, Host: %s, Private: %s, Max Players: %d, Mode: %s", roomName, roomId, hostPlayer.Name, tostring(isPrivate), maxPlayers, gameMode))

	-- Fire back to the original host client if they created it manually
	if not initialPlayers then
		lobbyRemote:FireClient(hostPlayer, "roomCreated", {
			success = true,
			roomCode = newRoom.RoomCode,
			roomId = newRoom.RoomId
		})
	end

	if not newRoom.IsPrivate then
		broadcastPublicRoomsUpdate()
	end

	updateRoomInfo(newRoom)
	return roomId -- Return the ID for matchmaking
end

-- Handles a player joining an existing room
local function handleJoinRoom(player, joinData)
	if getPlayerRoom(player) then
		lobbyRemote:FireClient(player, "joinFailed", { reason = "You are already in a room." })
		return
	end

	local roomIdToJoin = joinData.roomId or joinData.roomCode
	local room = rooms[roomIdToJoin]

	if not room then
		lobbyRemote:FireClient(player, "joinFailed", { reason = "Room not found." })
		return
	end

	if joinData.roomCode and room.IsPrivate and room.RoomCode ~= joinData.roomCode then
		lobbyRemote:FireClient(player, "joinFailed", { reason = "Invalid room code." })
		return
	end

	if #room.Players >= room.MaxPlayers then
		lobbyRemote:FireClient(player, "joinFailed", { reason = "Room is full." })
		return
	end

	table.insert(room.Players, player)
	print(string.format("Player %s joined room %s", player.Name, room.RoomId))

	lobbyRemote:FireClient(player, "joinSuccess", { roomId = room.RoomId })

	if not room.IsPrivate then
		broadcastPublicRoomsUpdate()
	end

	updateRoomInfo(room)
end

-- Removes a player from any matchmaking queue they are in
local function handleCancelMatchmaking(player)
	for playerCount, modes in pairs(matchmakingQueues) do
		for mode, difficulties in pairs(modes) do
			for difficulty, queue in pairs(difficulties) do
				for i, p in ipairs(queue) do
					if p == player then
						table.remove(queue, i)
						print(string.format("Player %s cancelled matchmaking for %d players in %s mode on %s difficulty.", player.Name, playerCount, mode, difficulty))
						lobbyRemote:FireClient(player, "matchmakingCancelled")
						return
					end
				end
			end
		end
	end
end

-- Handles all logic when a player leaves the game
local function handlePlayerRemoving(player)
	-- Also remove from matchmaking queue if they are in one
	handleCancelMatchmaking(player)

	local roomData = getPlayerRoom(player)
	if roomData then
		local wasPrivate = roomData.IsPrivate
		local roomId = roomData.RoomId

		-- Find and remove the player
		for i, p in ipairs(roomData.Players) do
			if p == player then
				table.remove(roomData.Players, i)
				print(string.format("Player %s removed from room %s", player.Name, roomId))
				break
			end
		end

		-- Check if the room is now empty
		if #roomData.Players == 0 then
			print("Room " .. roomId .. " is empty, dissolving.")
			rooms[roomId] = nil
			if not wasPrivate then
				broadcastPublicRoomsUpdate()
			end
			return
		end

		-- Handle host migration
		if roomData.Host == player then
			roomData.Host = roomData.Players[1]
			print(string.format("Host migrated in room %s. New host is %s", roomId, roomData.Host.Name))
		end

		updateRoomInfo(roomData)
		if not wasPrivate then
			broadcastPublicRoomsUpdate()
		end
	end
end

-- Handles a player actively choosing to leave a room
local function handleLeaveRoom(player)
	local roomData = getPlayerRoom(player)
	if roomData then
		-- NEW: Block leaving if a countdown is active in the room
		if activeCountdowns[roomData.RoomId] then
			warn(string.format("Player %s attempted to leave room %s during countdown. Denied.", player.Name, roomData.RoomId))
			return
		end

		local wasPrivate = roomData.IsPrivate
		local roomId = roomData.RoomId

		-- Find and remove the player
		for i, p in ipairs(roomData.Players) do
			if p == player then
				table.remove(roomData.Players, i)
				print(string.format("Player %s left room %s", player.Name, roomId))
				break
			end
		end

		-- Fire an event back to the leaving player to confirm they've left, so UI can reset
		lobbyRemote:FireClient(player, "leftRoomSuccess")

		-- Check if the room is now empty
		if #roomData.Players == 0 then
			print("Room " .. roomId .. " is empty, dissolving.")
			rooms[roomId] = nil
			if not wasPrivate then
				broadcastPublicRoomsUpdate()
			end
			return
		end

		-- Handle host migration
		if roomData.Host == player then
			roomData.Host = roomData.Players[1] -- The next player in the list becomes host
			print(string.format("Host migrated in room %s. New host is %s", roomId, roomData.Host.Name))
		end

		-- Update everyone else in the room
		updateRoomInfo(roomData)

		-- Update public room list if it was a public room
		if not wasPrivate then
			broadcastPublicRoomsUpdate()
		end
	end
end

-- Cancels an active countdown for a room
local function handleCancelCountdown(player)
	local room = getPlayerRoom(player)
	-- Ensure the player is a host and a countdown is actually running for their room
	if room and room.Host == player and activeCountdowns[room.RoomId] then
		print(string.format("Host %s is cancelling the countdown for room %s.", player.Name, room.RoomId))

		-- Setting this to nil will cause the countdown loop to terminate
		activeCountdowns[room.RoomId] = nil

		-- Notify all clients in the room to reset their UI
		for _, p in ipairs(room.Players) do
			lobbyRemote:FireClient(p, "countdownCancelled")
		end
	else
		warn(string.format("Player %s sent an invalid cancelCountdown request.", player.Name))
	end
end

-- Handles kicking a player from the room (Host only)
local function handleKickPlayer(hostPlayer, targetUserId)
	local room = getPlayerRoom(hostPlayer)

	-- Validation: Must be in a room and must be the host
	if not room or room.Host ~= hostPlayer then
		warn(string.format("Player %s sent an invalid kick request (not a host).", hostPlayer.Name))
		return
	end

	-- Validation: Can't kick yourself
	if hostPlayer.UserId == targetUserId then
		warn(string.format("Host %s attempted to kick themselves.", hostPlayer.Name))
		return
	end

	local targetPlayer
	local targetPlayerIndex
	-- Find the target player in the room's player list
	for i, p in ipairs(room.Players) do
		if p.UserId == targetUserId then
			targetPlayer = p
			targetPlayerIndex = i
			break
		end
	end

	-- Validation: Target player must be in the room
	if not targetPlayer then
		warn(string.format("Host %s tried to kick player with ID %d, but they were not in the room.", hostPlayer.Name, targetUserId))
		return
	end

	-- All checks passed, proceed with kicking
	print(string.format("Host %s is kicking player %s from room %s.", hostPlayer.Name, targetPlayer.Name, room.RoomId))

	-- 1. Remove the player from the room's list
	table.remove(room.Players, targetPlayerIndex)

	-- 2. Notify the kicked player
	onKickedEvent:FireClient(targetPlayer)

	-- 3. Update the room for everyone else
	updateRoomInfo(room)

	-- 4. Update public room list if it was a public room
	if not room.IsPrivate then
		broadcastPublicRoomsUpdate()
	end
end


--==============================================================================
--// CORE LOGIC: MATCHMAKING
--==============================================================================

-- Checks if a queue is full and, if so, creates a room for the players
local function checkForFullQueue(playerCount, gameMode, difficulty)
	local queue = matchmakingQueues[playerCount] and matchmakingQueues[playerCount][gameMode] and matchmakingQueues[playerCount][gameMode][difficulty]
	if not queue then return end

	if #queue >= playerCount then
		print(string.format("Full queue found for %d players in %s mode on %s difficulty. Creating room.", playerCount, gameMode, difficulty))

		local playersForGame = {}
		for i = 1, playerCount do
			table.insert(playersForGame, table.remove(queue, 1))
		end

		local settings = { maxPlayers = playerCount, isPrivate = true, gameMode = gameMode, difficulty = difficulty }
		local newRoomId = handleCreateRoom(playersForGame[1], settings, playersForGame)

		for _, p in ipairs(playersForGame) do
			if p then
				lobbyRemote:FireClient(p, "matchFound", { roomId = newRoomId })
			end
		end
	end
end

-- Adds a player to a matchmaking queue
local function handleStartMatchmaking(player, data)
	local playerCount = math.clamp(tonumber(data.playerCount) or 4, 2, 8)
	local gameMode = data.gameMode or "Story"
	local difficulty = data.difficulty or "Easy"

	-- Ensure the queue structure exists
	if not matchmakingQueues[playerCount] then matchmakingQueues[playerCount] = {} end
	if not matchmakingQueues[playerCount][gameMode] then matchmakingQueues[playerCount][gameMode] = {} end
	if not matchmakingQueues[playerCount][gameMode][difficulty] then matchmakingQueues[playerCount][gameMode][difficulty] = {} end

	table.insert(matchmakingQueues[playerCount][gameMode][difficulty], player)
	print(string.format("Player %s entered matchmaking for %d players in %s mode on %s difficulty.", player.Name, playerCount, gameMode, difficulty))

	lobbyRemote:FireClient(player, "matchmakingStarted")
	checkForFullQueue(playerCount, gameMode, difficulty)
end

--==============================================================================
--// CORE LOGIC: GAME START & TELEPORTATION
--==============================================================================

-- Teleports a group of players to the game place
-- Teleport a group of players to a private game server
local function teleportPlayersToAct1(playersToTeleport, gameMode, difficulty)
	local act1Id = PlaceData["ACT 1: Village"]
	if not act1Id then
		warn("ACT 1 Place ID not found in PlaceData!")
		return
	end

	-- Step 1: Reserve a private server
	local reserveSuccess, privateServerCode = pcall(function()
		return TeleportService:ReserveServer(act1Id)
	end)

	if not reserveSuccess then
		warn("Failed to reserve a private server: ", tostring(privateServerCode))
		-- Optionally, inform players that the teleport failed
		return
	end

	print("Private server reserved with code: " .. privateServerCode)

	-- Step 2: Set teleport options, including the private server code and game mode
	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions.ReservedServerAccessCode = privateServerCode
	teleportOptions:SetTeleportData({
		gameMode = gameMode or "Story",
		difficulty = difficulty or "Easy" -- Default to Easy if not provided
	})

	-- Step 3: Teleport players using TeleportAsync
	local teleportSuccess, teleportResult = pcall(function()
		TeleportService:TeleportAsync(act1Id, playersToTeleport, teleportOptions)
	end)

	if not teleportSuccess then
		warn("Failed to teleport players to private server: ", tostring(teleportResult))
		-- Optionally, handle the failed teleport (e.g., retry, disband room)
	else
		print(string.format("Successfully initiated teleport for %d players to private server with mode: %s and difficulty: %s", #playersToTeleport, gameMode or "Story", difficulty or "Easy"))
	end
end

-- Starts the pre-game countdown for a given room
function startCountdown(room)
	local roomId = room.RoomId
	if activeCountdowns[roomId] then return end -- Already running

	activeCountdowns[roomId] = true
	print("Starting countdown for room:", roomId)

	task.spawn(function()
		for i = 5, 0, -1 do
			-- Check for cancellation at the start of each tick
			if not activeCountdowns[roomId] then
				print("Countdown loop terminated for room:", roomId)
				-- No need to set to nil again, it was done by the cancel function
				return
			end

			local currentRoom = rooms[roomId]
			-- If the room was dissolved mid-countdown, cancel cleanly.
			if not currentRoom then
				print("Countdown cancelled for room:", roomId, "(Room dissolved)")
				activeCountdowns[roomId] = nil
				return
			end

			-- Create a snapshot of players at the start of each tick to prevent errors
			-- if a player leaves while the events are being sent.
			local playersToUpdate = {}
			for _, p in ipairs(currentRoom.Players) do
				table.insert(playersToUpdate, p)
			end

			if #playersToUpdate == 0 then
				print("Countdown cancelled for room:", roomId, "(Empty)")
				rooms[roomId] = nil -- Ensure room is dissolved if it's empty
				activeCountdowns[roomId] = nil
				return
			end

			for _, p in ipairs(playersToUpdate) do
				lobbyRemote:FireClient(p, "countdownUpdate", { value = i })
			end

			if i == 0 then
				print("Countdown finished for room:", roomId, ". Teleporting players...")
				teleportPlayersToAct1(playersToUpdate, currentRoom.GameMode, currentRoom.Difficulty)
			end

			task.wait(1)
		end
		activeCountdowns[roomId] = nil
	end)
end


--==============================================================================
--// EVENT CONNECTIONS
--==============================================================================

-- Main server event handler
lobbyRemote.OnServerEvent:Connect(function(player, action, data)
	if action == "createRoom" then
		handleCreateRoom(player, data)
	elseif action == "getPublicRooms" then
		local publicRoomsData = {}
		for id, roomData in pairs(rooms) do
			if not roomData.IsPrivate then
				publicRoomsData[id] = {
					roomName = roomData.Name,
					playerCount = #roomData.Players,
					maxPlayers = roomData.MaxPlayers,
					hostName = roomData.Host.Name,
					roomId = roomData.RoomId,
					gameMode = roomData.GameMode
				}
			end
		end
		lobbyRemote:FireClient(player, "publicRoomsUpdate", publicRoomsData)
	elseif action == "joinRoom" then
		handleJoinRoom(player, data)
	elseif action == "startMatchmaking" then
		handleStartMatchmaking(player, data)
	elseif action == "cancelMatchmaking" then
		handleCancelMatchmaking(player)
	elseif action == "startSoloGame" then
		local gameMode = data and data.gameMode or "Story"
		local difficulty = data and data.difficulty or "Easy"
		print(string.format("Player %s is starting a solo game in mode: %s on difficulty: %s", player.Name, gameMode, difficulty))
		teleportPlayersToAct1({player}, gameMode, difficulty)
	elseif action == "leaveRoom" then
		handleLeaveRoom(player)
	elseif action == "forceStartGame" then
		local room = getPlayerRoom(player)
		if room and room.Host == player and #room.Players >= room.MaxPlayers then
			print(string.format("Host %s is force starting the game for room %s.", player.Name, room.RoomId))
			-- The 'startCountdown' function already prevents multiple countdowns, so we just call it.
			startCountdown(room)
		else
			warn(string.format("Player %s sent an invalid forceStartGame request.", player.Name))
		end
	elseif action == "cancelCountdown" then
		handleCancelCountdown(player)
	else
		warn("Unknown action received: " .. tostring(action))
	end
end)

-- Connect the function to the PlayerRemoving event
Players.PlayerRemoving:Connect(handlePlayerRemoving)

-- Listen for kick requests from clients
kickPlayerEvent.OnServerEvent:Connect(handleKickPlayer)

--==============================================================================
--// INITIALIZATION
--==============================================================================

print("LobbyRoomManager.lua loaded successfully.")
