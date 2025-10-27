-- LobbyRoomUI.lua (LocalScript)
-- Path: StarterGui/RoomUI.lua
-- Script Place: Lobby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Wait for the ProximityPrompt to exist in the workspace
local lobbyRoomPart = workspace:WaitForChild("LobbyRoom")
local proximityPrompt = lobbyRoomPart:WaitForChild("ProximityPrompt")
local preGameLobbyPlayerList, preGameLobbyCountdownLabel, preGameLobbyRoomCodeLabel
-- Remote Event Handling
local lobbyRemote = ReplicatedStorage:WaitForChild("LobbyRemote")
local kickPlayerEvent = ReplicatedStorage:WaitForChild("KickPlayerFromLobby")
local onKickedEvent = ReplicatedStorage:WaitForChild("OnKickedFromLobby")
local updatePlayerBoosterStatusEvent = ReplicatedStorage:WaitForChild("UpdatePlayerBoosterStatusEvent")
local getBoosterConfigFunc = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetBoosterConfig")

local BoosterConfig = getBoosterConfigFunc:InvokeServer()
local joinRoomScrollingFrame -- Will be assigned in populateJoinRoomFrame

-- State
local isCountdownActive = false
local playerBoosterLabels = {}
local playerBoosterIcons = {}

-- Main UI container
local lobbyScreenGui = Instance.new("ScreenGui")
lobbyScreenGui.Name = "LobbyScreenGui"
lobbyScreenGui.Parent = player:WaitForChild("PlayerGui")
lobbyScreenGui.Enabled = false -- Initially hidden

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = lobbyScreenGui
mainFrame.Size = UDim2.new(0, 400, 0, 300)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Parent = mainFrame
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titleLabel.Text = "Lobby"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 24

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleLabel

-- Buttons
local buttonLayout = Instance.new("UIListLayout")
buttonLayout.Parent = mainFrame
buttonLayout.FillDirection = Enum.FillDirection.Vertical
buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.Padding = UDim.new(0, 10)
buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

local function createButton(text, order)
	local button = Instance.new("TextButton")
	button.Name = text .. "Button"
	button.Parent = mainFrame
	button.LayoutOrder = order
	button.Size = UDim2.new(0, 200, 0, 50)
	button.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
	button.Text = text
	button.Font = Enum.Font.SourceSansBold
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 20

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = button

	return button
end

local createRoomButton = createButton("Create Room", 1)
local joinRoomButton = createButton("Join Room", 2)
local matchmakingButton = createButton("Matchmaking", 3)
local soloButton = createButton("Solo", 4)

-- Sub-Frames for different actions
local createRoomFrame = Instance.new("Frame")
createRoomFrame.Name = "CreateRoomFrame"
createRoomFrame.Parent = mainFrame
createRoomFrame.Size = UDim2.new(1, 0, 1, 0)
createRoomFrame.Position = UDim2.new(0, 0, 0, 0)
createRoomFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
createRoomFrame.BorderSizePixel = 0
createRoomFrame.Visible = false -- Hidden by default

local joinRoomFrame = createRoomFrame:Clone()
joinRoomFrame.Name = "JoinRoomFrame"
joinRoomFrame.Parent = mainFrame
joinRoomFrame.Visible = false

local matchmakingFrame = createRoomFrame:Clone()
matchmakingFrame.Name = "MatchmakingFrame"
matchmakingFrame.Parent = mainFrame
matchmakingFrame.Visible = false

local preGameLobbyFrame = createRoomFrame:Clone()
preGameLobbyFrame.Name = "PreGameLobbyFrame"
preGameLobbyFrame.Parent = mainFrame
preGameLobbyFrame.Visible = false

local soloFrame = createRoomFrame:Clone()
soloFrame.Name = "SoloFrame"
soloFrame.Parent = mainFrame
soloFrame.Visible = false

-- Function to switch between frames
local function switchFrame(frameToShow)
	-- Make buttons visible/invisible
	createRoomButton.Visible = (frameToShow == nil)
	joinRoomButton.Visible = (frameToShow == nil)
	matchmakingButton.Visible = (frameToShow == nil)
	soloButton.Visible = (frameToShow == nil)

	for _, child in ipairs(mainFrame:GetChildren()) do
		if child:IsA("Frame") then
			child.Visible = false
		end
	end
	if frameToShow then
		frameToShow.Visible = true
	end
end

-- Helper function to create a difficulty selector UI
local function createDifficultySelector(parentFrame, onSelectionChanged)
	local difficultyFrame = Instance.new("Frame", parentFrame)
	difficultyFrame.Name = "DifficultySelector"
	difficultyFrame.Size = UDim2.new(1, 0, 0, 60)
	difficultyFrame.BackgroundTransparency = 1

	local label = Instance.new("TextLabel", difficultyFrame)
	label.Size = UDim2.new(1, 0, 0, 20)
	label.Text = "Difficulty"
	label.Font = Enum.Font.SourceSans
	label.TextSize = 18
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left

	local buttonsFrame = Instance.new("Frame", difficultyFrame)
	buttonsFrame.Name = "DifficultyButtons"
	buttonsFrame.Size = UDim2.new(1, 0, 1, -25)
	buttonsFrame.Position = UDim2.new(0, 0, 0, 25)
	buttonsFrame.BackgroundTransparency = 1
	local gridLayout = Instance.new("UIGridLayout", buttonsFrame)
	gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
	gridLayout.CellSize = UDim2.new(0, 55, 0, 30)

	local difficulties = {"Easy", "Normal", "Hard", "Expert", "Hell", "Crazy"}
	local selectedDifficulty = "Easy" -- Default
	local buttons = {}

	for _, diffName in ipairs(difficulties) do
		local button = Instance.new("TextButton", buttonsFrame)
		button.Name = diffName
		button.Text = diffName
		button.Font = Enum.Font.SourceSans
		button.TextSize = 12
		button.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
		button.TextColor3 = Color3.new(1, 1, 1)
		local corner = Instance.new("UICorner", button)
		corner.CornerRadius = UDim.new(0, 4)
		buttons[diffName] = button

		button.MouseButton1Click:Connect(function()
			selectedDifficulty = diffName
			for name, btn in pairs(buttons) do
				btn.BackgroundColor3 = (name == diffName) and Color3.fromRGB(0, 170, 81) or Color3.fromRGB(85, 85, 85)
			end
			if onSelectionChanged then
				onSelectionChanged(selectedDifficulty)
			end
		end)
	end

	-- Set default selection
	buttons["Easy"].BackgroundColor3 = Color3.fromRGB(0, 170, 81)

	return difficultyFrame
end

-- Populate CreateRoomFrame
local function populateCreateRoomFrame()
	local title = Instance.new("TextLabel", createRoomFrame)
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Text = "Create Room"
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 20
	title.TextColor3 = Color3.new(1, 1, 1)
	title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

	local backButton = Instance.new("TextButton", createRoomFrame)
	backButton.Size = UDim2.new(0, 50, 0, 30)
	backButton.Position = UDim2.new(0, 10, 0, 10)
	backButton.Text = "Back"
	backButton.Font = Enum.Font.SourceSans
	backButton.TextSize = 16
	backButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
	backButton.TextColor3 = Color3.new(1, 1, 1)
	local backCorner = Instance.new("UICorner", backButton)
	backCorner.CornerRadius = UDim.new(0, 6)

	backButton.MouseButton1Click:Connect(function()
		switchFrame(nil) -- Go back to main menu
	end)

	-- Player count slider would be complex to create from scratch.
	-- Let's use a simple TextBox for now for player count.
	local roomNameLabel = Instance.new("TextLabel", createRoomFrame)
	roomNameLabel.Size = UDim2.new(0, 200, 0, 20)
	roomNameLabel.Position = UDim2.new(0.5, -100, 0.2, 0)
	roomNameLabel.Text = "Room Name (Optional):"
	roomNameLabel.Font = Enum.Font.SourceSans
	roomNameLabel.TextSize = 18
	roomNameLabel.TextColor3 = Color3.new(1, 1, 1)
	roomNameLabel.BackgroundTransparency = 1
	roomNameLabel.TextXAlignment = Enum.TextXAlignment.Left

	local roomNameInput = Instance.new("TextBox", createRoomFrame)
	roomNameInput.Size = UDim2.new(0, 200, 0, 30)
	roomNameInput.Position = UDim2.new(0.5, -100, 0.2, 25)
	roomNameInput.Font = Enum.Font.SourceSans
	roomNameInput.Text = ""
	roomNameInput.PlaceholderText = "Enter a name..."
	roomNameInput.TextColor3 = Color3.new(1,1,1)
	roomNameInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	local roomNameCorner = Instance.new("UICorner", roomNameInput)
	roomNameCorner.CornerRadius = UDim.new(0, 6)

	local playerCountLabel = Instance.new("TextLabel", createRoomFrame)
	playerCountLabel.Size = UDim2.new(0, 200, 0, 20)
	playerCountLabel.Position = UDim2.new(0.5, -100, 0.4, 0)
	playerCountLabel.Text = "Max Players (2-8):"
	playerCountLabel.Font = Enum.Font.SourceSans
	playerCountLabel.TextSize = 18
	playerCountLabel.TextColor3 = Color3.new(1, 1, 1)
	playerCountLabel.BackgroundTransparency = 1
	playerCountLabel.TextXAlignment = Enum.TextXAlignment.Left

	local playerCountInput = Instance.new("TextBox", createRoomFrame)
	playerCountInput.Size = UDim2.new(0, 100, 0, 30)
	playerCountInput.Position = UDim2.new(0.5, -100, 0.4, 25)
	playerCountInput.Font = Enum.Font.SourceSans
	playerCountInput.Text = "4"
	playerCountInput.TextColor3 = Color3.new(1,1,1)
	playerCountInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	local inputCorner = Instance.new("UICorner", playerCountInput)
	inputCorner.CornerRadius = UDim.new(0, 6)

	local isPrivate = false
	local privateToggle = Instance.new("TextButton", createRoomFrame)
	privateToggle.Size = UDim2.new(0, 200, 0, 30)
	privateToggle.Position = UDim2.new(0.5, -100, 0.7, 0)
	privateToggle.Text = "Room: Public"
	privateToggle.Font = Enum.Font.SourceSans
	privateToggle.TextSize = 18
	privateToggle.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
	privateToggle.TextColor3 = Color3.new(1, 1, 1)
	local privateCorner = Instance.new("UICorner", privateToggle)
	privateCorner.CornerRadius = UDim.new(0, 6)

	privateToggle.MouseButton1Click:Connect(function()
		isPrivate = not isPrivate
		privateToggle.Text = isPrivate and "Room: Private" or "Room: Public"
	end)

	local gameMode = "Story" -- Default mode
	local modeButton = Instance.new("TextButton", createRoomFrame)
	modeButton.Size = UDim2.new(0, 200, 0, 30)
	modeButton.Position = UDim2.new(0.5, -100, 0.5, 25)
	modeButton.Text = "Mode: Story"
	modeButton.Font = Enum.Font.SourceSans
	modeButton.TextSize = 18
	modeButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
	modeButton.TextColor3 = Color3.new(1, 1, 1)
	local modeCorner = Instance.new("UICorner", modeButton)
	modeCorner.CornerRadius = UDim.new(0, 6)

	modeButton.MouseButton1Click:Connect(function()
		if gameMode == "Story" then
			gameMode = "Endless"
		else
			gameMode = "Story"
		end
		modeButton.Text = "Mode: " .. gameMode
	end)

	local selectedDifficulty = "Easy"
	local difficultySelector = createDifficultySelector(createRoomFrame, function(difficulty)
		selectedDifficulty = difficulty
	end)
	difficultySelector.Position = UDim2.new(0.5, -100, 0.55, 0)

	local confirmButton = Instance.new("TextButton", createRoomFrame)
	confirmButton.Size = UDim2.new(0, 150, 0, 40)
	confirmButton.Position = UDim2.new(0.5, -75, 0.85, 0)
	confirmButton.Text = "Confirm & Create"
	confirmButton.Font = Enum.Font.SourceSansBold
	confirmButton.TextSize = 18
	confirmButton.BackgroundColor3 = Color3.fromRGB(0, 170, 81)
	confirmButton.TextColor3 = Color3.new(1, 1, 1)
	local confirmCorner = Instance.new("UICorner", confirmButton)
	confirmCorner.CornerRadius = UDim.new(0, 8)

	confirmButton.MouseButton1Click:Connect(function()
		local settings = {
			roomName = roomNameInput.Text,
			maxPlayers = playerCountInput.Text,
			isPrivate = isPrivate,
			gameMode = gameMode,
			difficulty = selectedDifficulty
		}
		print("Sending create room request to server with name: " .. settings.roomName .. ", mode: " .. settings.gameMode .. ", difficulty: " .. settings.difficulty)
		ReplicatedStorage.LobbyRemote:FireServer("createRoom", settings)
	end)
end

-- Connect the "Join with Code" button
local function connectJoinWithCodeButton()
	local roomCodeInput = joinRoomFrame:FindFirstChild("roomCodeInput")
	local joinButton = joinRoomFrame:FindFirstChild("joinWithCodeButton")

	if roomCodeInput and joinButton then
		joinButton.MouseButton1Click:Connect(function()
			local code = roomCodeInput.Text
			if code and code ~= "" then
				print("Client sending request to join with code:", code)
				lobbyRemote:FireServer("joinRoom", { roomCode = code })
			end
		end)
	else
		warn("Could not find 'Join with Code' UI elements.")
	end
end

-- Populate JoinRoomFrame
local function populateJoinRoomFrame()
	local title = Instance.new("TextLabel", joinRoomFrame)
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Text = "Join Room"
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 20
	title.TextColor3 = Color3.new(1, 1, 1)
	title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

	local backButton = Instance.new("TextButton", joinRoomFrame)
	backButton.Size = UDim2.new(0, 50, 0, 30)
	backButton.Position = UDim2.new(0, 10, 0, 10)
	backButton.Text = "Back"
	-- ... (styling)
	backButton.MouseButton1Click:Connect(function()
		switchFrame(nil)
	end)

	local publicRoomsLabel = Instance.new("TextLabel", joinRoomFrame)
	publicRoomsLabel.Size = UDim2.new(1, -20, 0, 20)
	publicRoomsLabel.Position = UDim2.new(0, 10, 0, 55)
	publicRoomsLabel.Text = "Public Rooms"
	publicRoomsLabel.TextXAlignment = Enum.TextXAlignment.Left
	-- ... (styling)

	local scrollingFrame = Instance.new("ScrollingFrame", joinRoomFrame)
	scrollingFrame.Size = UDim2.new(1, -20, 0.5, -60)
	scrollingFrame.Position = UDim2.new(0, 10, 0, 80)
	scrollingFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	local listLayout = Instance.new("UIListLayout", scrollingFrame)
	listLayout.Padding = UDim.new(0, 5)

	-- TAMBAHKAN BARIS INI
	joinRoomScrollingFrame = scrollingFrame

	-- Placeholder for room entry
	local function createRoomEntry(roomName, playerCount)
		local entry = Instance.new("TextButton", scrollingFrame)
		entry.Size = UDim2.new(1, 0, 0, 40)
		entry.Text = string.format("%s (%s)", roomName, playerCount)
		-- ... (styling)
		return entry
	end

	-- Example entries are now removed, will be populated dynamically
	-- createRoomEntry("Cool Room 1", "3/8")
	-- createRoomEntry("Another Room", "1/4")

	local roomCodeInput = Instance.new("TextBox", joinRoomFrame)
	roomCodeInput.Name = "roomCodeInput"
	roomCodeInput.Size = UDim2.new(0.6, -15, 0, 40)
	roomCodeInput.Position = UDim2.new(0, 10, 1, -50)
	roomCodeInput.PlaceholderText = "Enter Room Code"
	-- ... (styling)

	local joinWithCodeButton = Instance.new("TextButton", joinRoomFrame)
	joinWithCodeButton.Name = "joinWithCodeButton"
	joinWithCodeButton.Size = UDim2.new(0.4, -15, 0, 40)
	joinWithCodeButton.Position = UDim2.new(0.6, 0, 1, -50)
	joinWithCodeButton.Text = "Join"
	-- ... (styling)

	connectJoinWithCodeButton()
end

populateCreateRoomFrame()
populateJoinRoomFrame()

-- Populate MatchmakingFrame
local matchmakingFrameElements = {}
local function resetMatchmakingFrameUI()
	if matchmakingFrameElements.startElements then
		for _, v in ipairs(matchmakingFrameElements.startElements) do v.Visible = true end
		for _, v in ipairs(matchmakingFrameElements.searchingElements) do v.Visible = false end
	end
end

local function updatePreGameLobby(roomData)
	if not preGameLobbyPlayerList or not preGameLobbyRoomCodeLabel then return end

	-- Update Room Name display
	local titleLabel = preGameLobbyFrame:FindFirstChild("TitleLabel") or preGameLobbyFrame:FindFirstChild("TextLabel")
	if titleLabel then
		titleLabel.Text = roomData.roomName or "Lobby"
	end

	-- Update Room Code display
	if roomData.roomCode then
		preGameLobbyRoomCodeLabel.Text = "Room Code: " .. roomData.roomCode
		preGameLobbyRoomCodeLabel.Visible = true
	else
		preGameLobbyRoomCodeLabel.Visible = false
	end

	-- Update Game Mode display
	local gameModeLabel = preGameLobbyFrame:FindFirstChild("GameModeLabel")
	if not gameModeLabel then
		gameModeLabel = Instance.new("TextLabel")
		gameModeLabel.Name = "GameModeLabel"
		gameModeLabel.Size = UDim2.new(1, 0, 0, 20)
		gameModeLabel.Position = UDim2.new(0, 0, 0, 55)
		gameModeLabel.Font = Enum.Font.SourceSans
		gameModeLabel.Text = "Mode: " .. (roomData.gameMode or "Story")
		gameModeLabel.TextSize = 16
		gameModeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		gameModeLabel.BackgroundTransparency = 1
		gameModeLabel.TextXAlignment = Enum.TextXAlignment.Center
		gameModeLabel.Parent = preGameLobbyFrame
	end
	gameModeLabel.Text = "Mode: " .. (roomData.gameMode or "Story")

	-- Update Difficulty display
	local difficultyLabel = preGameLobbyFrame:FindFirstChild("DifficultyLabel")
	if not difficultyLabel then
		difficultyLabel = gameModeLabel:Clone()
		difficultyLabel.Name = "DifficultyLabel"
		difficultyLabel.Parent = preGameLobbyFrame
		difficultyLabel.Position = UDim2.new(0, 0, 0, 75)
	end
	difficultyLabel.Text = "Difficulty: " .. (roomData.difficulty or "Easy")


	-- Clear old player list
	for _, child in ipairs(preGameLobbyPlayerList:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	playerBoosterLabels = {} -- Clear old labels
	playerBoosterIcons = {} -- Clear old icons

	-- Add new player labels
	for _, playerData in ipairs(roomData.players) do
		local playerFrame = Instance.new("Frame")
		playerFrame.Size = UDim2.new(1, -10, 0, 50) -- Increased height to accommodate booster text
		playerFrame.BackgroundTransparency = 1
		playerFrame.Parent = preGameLobbyPlayerList

		local playerLabel = Instance.new("TextLabel")
		playerLabel.Size = UDim2.new(1, 0, 0.6, 0)
		playerLabel.Parent = playerFrame

		local displayText = string.format("[Lv. %d] %s", playerData.Level or 1, playerData.Name)
		if playerData.Name == roomData.hostName then
			displayText = displayText .. " (Host)"
		end
		playerLabel.Text = " " .. displayText

		playerLabel.Font = Enum.Font.SourceSans
		playerLabel.TextSize = 18
		playerLabel.TextColor3 = Color3.new(1,1,1)
		playerLabel.TextXAlignment = Enum.TextXAlignment.Left
		playerLabel.BackgroundColor3 = Color3.fromRGB(55,55,55)
		local corner = Instance.new("UICorner", playerLabel)
		corner.CornerRadius = UDim.new(0, 4)

		local boosterLabel = Instance.new("TextLabel")
		boosterLabel.Name = "BoosterLabel"
		boosterLabel.Size = UDim2.new(1, 0, 0.4, 0)
		boosterLabel.Position = UDim2.new(0, 0, 0.6, 0)
		boosterLabel.Font = Enum.Font.SourceSans
		boosterLabel.TextSize = 14
		boosterLabel.TextColor3 = Color3.fromRGB(200, 200, 0)
		boosterLabel.BackgroundTransparency = 1
		boosterLabel.TextXAlignment = Enum.TextXAlignment.Left
		boosterLabel.Parent = playerFrame

		local boosterIcon = Instance.new("ImageLabel")
		boosterIcon.Name = "BoosterIcon"
		boosterIcon.Size = UDim2.new(0, 18, 0, 18) -- Small square for the icon
		boosterIcon.Position = UDim2.new(0, 5, 0.5, -9)
		boosterIcon.BackgroundTransparency = 1
		boosterIcon.Parent = boosterLabel

		if playerData.ActiveBooster and BoosterConfig[playerData.ActiveBooster] then
			boosterLabel.Text = "   " .. BoosterConfig[playerData.ActiveBooster].Name
			-- NOTE: BoosterConfig does not currently contain image asset IDs.
			-- When available, set the image here, e.g.:
			-- boosterIcon.Image = "rbxassetid://" .. BoosterConfig[playerData.ActiveBooster].IconAssetId
		else
			boosterLabel.Text = ""
			boosterIcon.Visible = false
		end
		playerBoosterLabels[playerData.UserId] = boosterLabel
		playerBoosterIcons[playerData.UserId] = boosterIcon


		-- Add Kick Button if the local player is the host and the current player is not the host
		local isHost = (player.Name == roomData.hostName)
		if isHost and playerData.Name ~= player.Name then
			local kickButton = Instance.new("TextButton")
			kickButton.Name = "KickButton"
			kickButton.Size = UDim2.new(0, 50, 0.8, 0)
			kickButton.Position = UDim2.new(1, -55, 0.1, 0)
			kickButton.Text = "Kick"
			kickButton.Font = Enum.Font.SourceSans
			kickButton.TextSize = 14
			kickButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			kickButton.TextColor3 = Color3.new(1, 1, 1)
			local kickCorner = Instance.new("UICorner", kickButton)
			kickCorner.CornerRadius = UDim.new(0, 4)
			kickButton.Parent = playerLabel

			kickButton.MouseButton1Click:Connect(function()
				print(string.format("Host sending request to kick player with UserId: %d", playerData.UserId))
				kickPlayerEvent:FireServer(playerData.UserId)
			end)
		end
	end

	local isHost = (player.Name == roomData.hostName)
	local isFull = (#roomData.players >= roomData.maxPlayers)

	-- Handle Start Game button visibility and state
	local startGameButton = preGameLobbyFrame:FindFirstChild("StartGameButton")

	if startGameButton then
		startGameButton.Visible = isHost

		if isHost then
			startGameButton.AutoButtonColor = isFull -- Enable click feedback only when full
			if isFull then
				startGameButton.BackgroundColor3 = Color3.fromRGB(0, 170, 81) -- Green (active)
				startGameButton.Text = "Start Game"
			else
				startGameButton.BackgroundColor3 = Color3.fromRGB(130, 130, 130) -- Grey (disabled)
				startGameButton.Text = string.format("%d/%d Players", #roomData.players, roomData.maxPlayers)
			end
		end
	end

	-- Update countdown label text based on room state
	if preGameLobbyCountdownLabel then
		if isFull then
			if isHost then
				preGameLobbyCountdownLabel.Text = "Press Start to Begin"
			else
				preGameLobbyCountdownLabel.Text = "Waiting for Host..."
			end
		else
			preGameLobbyCountdownLabel.Text = "Waiting for players..."
		end
	end
end





local function updateCountdown(value)
	if preGameLobbyCountdownLabel then
		preGameLobbyCountdownLabel.Text = "Starting in: " .. tostring(value)
	end

	-- When the countdown starts, change the button to a cancel button
	if not isCountdownActive then
		isCountdownActive = true
		local startGameButton = preGameLobbyFrame:FindFirstChild("StartGameButton")
		if startGameButton then
			startGameButton.Text = "Cancel"
			startGameButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red color
		end
		-- Also disable the leave button
		local leaveButton = preGameLobbyFrame:FindFirstChild("LeaveButton")
		if leaveButton then
			leaveButton.AutoButtonColor = false
			leaveButton.BackgroundColor3 = Color3.fromRGB(130, 130, 130) -- Greyed out
		end
	end
end

local function resetPreGameLobbyButton()
	isCountdownActive = false
	local startGameButton = preGameLobbyFrame:FindFirstChild("StartGameButton")
	if startGameButton then
		-- The text and color will be reset by the next roomUpdate,
		-- but we can reset the core properties here.
		startGameButton.Text = "Start Game"
		startGameButton.BackgroundColor3 = Color3.fromRGB(0, 170, 81)
	end
	-- Re-enable the leave button
	local leaveButton = preGameLobbyFrame:FindFirstChild("LeaveButton")
	if leaveButton then
		leaveButton.AutoButtonColor = true
		leaveButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Original red color
	end

	if preGameLobbyCountdownLabel then
		-- Reset the label text as well
		preGameLobbyCountdownLabel.Text = "Countdown cancelled."
	end
end

local function populateMatchmakingFrame()
	local backButton = Instance.new("TextButton", matchmakingFrame)
	backButton.Name = "BackButton"
	backButton.Size = UDim2.new(0, 50, 0, 30)
	backButton.Position = UDim2.new(0, 10, 0, 10)
	backButton.Text = "Back"
	-- ... styling

	local title = Instance.new("TextLabel", matchmakingFrame)
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Text = "Matchmaking"
	-- ... styling

	-- Elements for starting a search
	local startElements = {}
	local playerCountLabel = Instance.new("TextLabel", matchmakingFrame)
	playerCountLabel.Size = UDim2.new(0, 200, 0, 30)
	playerCountLabel.Position = UDim2.new(0.5, -100, 0.3, 0)
	playerCountLabel.Text = "Players (2-8):"
	table.insert(startElements, playerCountLabel)

	local playerCountInput = Instance.new("TextBox", matchmakingFrame)
	playerCountInput.Size = UDim2.new(0, 100, 0, 30)
	playerCountInput.Position = UDim2.new(0.5, -50, 0.4, 0)
	playerCountInput.Text = "2"
	table.insert(startElements, playerCountInput)

	local matchmakingMode = "Story" -- Default mode
	local modeButton = Instance.new("TextButton", matchmakingFrame)
	modeButton.Size = UDim2.new(0, 200, 0, 30)
	modeButton.Position = UDim2.new(0.5, -100, 0.6, 0)
	modeButton.Text = "Mode: Story"
	modeButton.Font = Enum.Font.SourceSans
	modeButton.TextSize = 18
	modeButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
	modeButton.TextColor3 = Color3.new(1, 1, 1)
	local modeCorner = Instance.new("UICorner", modeButton)
	modeCorner.CornerRadius = UDim.new(0, 6)
	table.insert(startElements, modeButton)

	modeButton.MouseButton1Click:Connect(function()
		if matchmakingMode == "Story" then
			matchmakingMode = "Endless"
		else
			matchmakingMode = "Story"
		end
		modeButton.Text = "Mode: " .. matchmakingMode
	end)

	local startButton = Instance.new("TextButton", matchmakingFrame)
	startButton.Size = UDim2.new(0, 150, 0, 40)
	startButton.Position = UDim2.new(0.5, -75, 0.8, 0)
	startButton.Text = "Start Search"
	table.insert(startElements, startButton)

	local selectedDifficulty = "Easy"
	local difficultySelector = createDifficultySelector(matchmakingFrame, function(difficulty)
		selectedDifficulty = difficulty
	end)
	difficultySelector.Position = UDim2.new(0.5, -100, 0.55, 0)
	table.insert(startElements, difficultySelector)


	-- Elements for when searching is in progress
	local searchingElements = {}
	local searchingLabel = Instance.new("TextLabel", matchmakingFrame)
	searchingLabel.Size = UDim2.new(1, 0, 0.5, 0)
	searchingLabel.Position = UDim2.new(0, 0, 0.2, 0)
	searchingLabel.Text = "Searching for players..."
	searchingLabel.Visible = false
	table.insert(searchingElements, searchingLabel)

	local cancelButton = Instance.new("TextButton", matchmakingFrame)
	cancelButton.Size = UDim2.new(0, 150, 0, 40)
	cancelButton.Position = UDim2.new(0.5, -75, 0.8, 0)
	cancelButton.Text = "Cancel"
	cancelButton.Visible = false
	table.insert(searchingElements, cancelButton)

	-- Store elements for later access
	matchmakingFrameElements.startElements = startElements
	matchmakingFrameElements.searchingElements = searchingElements

	-- Event handlers
	startButton.MouseButton1Click:Connect(function()
		for _, v in ipairs(startElements) do v.Visible = false end
		for _, v in ipairs(searchingElements) do v.Visible = true end
		lobbyRemote:FireServer("startMatchmaking", {
			playerCount = playerCountInput.Text,
			gameMode = matchmakingMode,
			difficulty = selectedDifficulty
		})
	end)

	cancelButton.MouseButton1Click:Connect(function()
		lobbyRemote:FireServer("cancelMatchmaking")
		-- The server will fire back an event to confirm, which will trigger the UI reset
	end)

	backButton.MouseButton1Click:Connect(function() 
		lobbyRemote:FireServer("cancelMatchmaking") -- Also cancel if they go back
		resetMatchmakingFrameUI()
		switchFrame(nil) 
	end)
end

-- Populate PreGameLobbyFrame
local function populatePreGameLobbyFrame()
	local title = Instance.new("TextLabel", preGameLobbyFrame)
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.Text = "LOBBY"
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 24
	title.TextColor3 = Color3.new(1,1,1)
	title.BackgroundTransparency = 1

	local roomCodeLabel = Instance.new("TextLabel", preGameLobbyFrame)
	roomCodeLabel.Name = "RoomCodeLabel"
	roomCodeLabel.Size = UDim2.new(1, 0, 0, 20)
	roomCodeLabel.Position = UDim2.new(0, 0, 0, 35)
	roomCodeLabel.Font = Enum.Font.SourceSans
	roomCodeLabel.Text = "Room Code: 12345"
	roomCodeLabel.TextSize = 16
	roomCodeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	roomCodeLabel.BackgroundTransparency = 1
	roomCodeLabel.Visible = false -- Initially hidden
	preGameLobbyRoomCodeLabel = roomCodeLabel -- Assign variable

	local playersLabel = Instance.new("TextLabel", preGameLobbyFrame)
	playersLabel.Size = UDim2.new(1, -20, 0, 20)
	playersLabel.Position = UDim2.new(0, 10, 0, 60)
	playersLabel.Text = "Players"
	playersLabel.Font = Enum.Font.SourceSansBold
	playersLabel.TextSize = 18
	playersLabel.TextColor3 = Color3.new(1,1,1)
	playersLabel.TextXAlignment = Enum.TextXAlignment.Left
	playersLabel.BackgroundTransparency = 1

	local playerList = Instance.new("ScrollingFrame", preGameLobbyFrame)
	playerList.Size = UDim2.new(1, -20, 0.6, -20)
	playerList.Position = UDim2.new(0, 10, 0, 85)
	playerList.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	playerList.BorderSizePixel = 0
	local listLayout = Instance.new("UIListLayout", playerList)
	listLayout.Padding = UDim.new(0, 5)
	preGameLobbyPlayerList = playerList -- Assign variable

	local countdownLabel = Instance.new("TextLabel", preGameLobbyFrame)
	countdownLabel.Size = UDim2.new(1, 0, 0, 30)
	countdownLabel.Position = UDim2.new(0, 0, 1, -35)
	countdownLabel.Text = "Waiting for players..."
	countdownLabel.Font = Enum.Font.SourceSansBold
	countdownLabel.TextSize = 20
	countdownLabel.TextColor3 = Color3.new(1,1,1)
	countdownLabel.BackgroundTransparency = 1
	preGameLobbyCountdownLabel = countdownLabel -- Assign variable

	local leaveButton = Instance.new("TextButton", preGameLobbyFrame)
	leaveButton.Name = "LeaveButton"
	leaveButton.Size = UDim2.new(0, 80, 0, 30)
	leaveButton.Position = UDim2.new(1, -90, 0, 5)
	leaveButton.Text = "Leave"
	leaveButton.Font = Enum.Font.SourceSans
	leaveButton.TextSize = 16
	leaveButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	leaveButton.TextColor3 = Color3.new(1, 1, 1)
	local leaveCorner = Instance.new("UICorner", leaveButton)
	leaveCorner.CornerRadius = UDim.new(0, 6)

	leaveButton.MouseButton1Click:Connect(function()
		-- Only allow leaving if the button is active (not greyed out)
		if leaveButton.AutoButtonColor then
			print("Client sending request to leave room.")
			lobbyRemote:FireServer("leaveRoom")
		else
			print("Leave button is disabled during countdown.")
		end
	end)

	local startGameButton = Instance.new("TextButton", preGameLobbyFrame)
	startGameButton.Name = "StartGameButton"
	startGameButton.Size = UDim2.new(0, 150, 0, 40)
	startGameButton.Position = UDim2.new(0.5, -75, 1, -85) -- Position it above the countdown
	startGameButton.Text = "Start Game"
	startGameButton.Font = Enum.Font.SourceSansBold
	startGameButton.TextSize = 18
	startGameButton.BackgroundColor3 = Color3.fromRGB(0, 170, 81)
	startGameButton.TextColor3 = Color3.new(1, 1, 1)
	local startCorner = Instance.new("UICorner", startGameButton)
	startCorner.CornerRadius = UDim.new(0, 8)
	startGameButton.Visible = false -- Hidden by default

	startGameButton.MouseButton1Click:Connect(function()
		if not startGameButton.AutoButtonColor then return end -- Don't do anything if not active

		if isCountdownActive then
			-- If countdown is running, this button acts as a cancel button
			print("Client sending cancel countdown request.")
			lobbyRemote:FireServer("cancelCountdown")
		else
			-- Otherwise, it starts the game
			print("Client sending force start game request.")
			lobbyRemote:FireServer("forceStartGame")
		end
	end)
end

populateMatchmakingFrame()
populatePreGameLobbyFrame()



-- Function to show/hide the UI
local function setUIVisible(visible)
	lobbyScreenGui.Enabled = visible
	if not visible then
		switchFrame(nil) -- Hide all subframes when closing UI
	end
end

-- Event Handling
proximityPrompt.Triggered:Connect(function()
	setUIVisible(true)
end)

createRoomButton.MouseButton1Click:Connect(function()
	switchFrame(createRoomFrame)
end)

joinRoomButton.MouseButton1Click:Connect(function()
	switchFrame(joinRoomFrame)
	ReplicatedStorage.LobbyRemote:FireServer("getPublicRooms")
end)

matchmakingButton.MouseButton1Click:Connect(function()
	switchFrame(matchmakingFrame)
	resetMatchmakingFrameUI()
end)

-- Populate SoloFrame
local function populateSoloFrame()
	local title = Instance.new("TextLabel", soloFrame)
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Text = "Select Solo Mode"
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 20
	title.TextColor3 = Color3.new(1, 1, 1)
	title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

	local backButton = Instance.new("TextButton", soloFrame)
	backButton.Size = UDim2.new(0, 50, 0, 30)
	backButton.Position = UDim2.new(0, 10, 0, 10)
	backButton.Text = "Back"
	backButton.Font = Enum.Font.SourceSans
	backButton.TextSize = 16
	backButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
	backButton.TextColor3 = Color3.new(1, 1, 1)
	local backCorner = Instance.new("UICorner", backButton)
	backCorner.CornerRadius = UDim.new(0, 6)

	backButton.MouseButton1Click:Connect(function()
		switchFrame(nil)
	end)

	local selectedMode = "Story"
	local selectedDifficulty = "Easy"

	local storyButton = createButton("Story", 1)
	storyButton.Parent = soloFrame
	storyButton.Size = UDim2.new(0, 80, 0, 40)
	storyButton.Position = UDim2.new(0.25, -40, 0.3, 0)

	local endlessButton = createButton("Endless", 2)
	endlessButton.Parent = soloFrame
	endlessButton.Size = UDim2.new(0, 80, 0, 40)
	endlessButton.Position = UDim2.new(0.75, -40, 0.3, 0)

	storyButton.MouseButton1Click:Connect(function()
		selectedMode = "Story"
		storyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 81)
		endlessButton.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
	end)

	endlessButton.MouseButton1Click:Connect(function()
		selectedMode = "Endless"
		endlessButton.BackgroundColor3 = Color3.fromRGB(0, 170, 81)
		storyButton.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
	end)
	storyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 81) -- Default selection

	local difficultySelector = createDifficultySelector(soloFrame, function(difficulty)
		selectedDifficulty = difficulty
	end)
	difficultySelector.Position = UDim2.new(0.5, -180, 0.5, 0)
	difficultySelector.Size = UDim2.new(0, 360, 0, 60)
	local grid = difficultySelector:FindFirstChild("DifficultyButtons"):FindFirstChildOfClass("UIGridLayout")
	if grid then
		grid.CellSize = UDim2.new(0, 50, 0, 30)
	end

	local startSoloButton = createButton("Start Solo", 3)
	startSoloButton.Parent = soloFrame
	startSoloButton.Position = UDim2.new(0.5, -100, 0.8, 0)
	startSoloButton.MouseButton1Click:Connect(function()
		print(string.format("Client requesting to start solo game. Mode: %s, Difficulty: %s", selectedMode, selectedDifficulty))
		lobbyRemote:FireServer("startSoloGame", { gameMode = selectedMode, difficulty = selectedDifficulty })
	end)
end

populateSoloFrame()

soloButton.MouseButton1Click:Connect(function()
	switchFrame(soloFrame)
end)



-- Placeholder for room entry creation, so we can use it in the update function
local function createRoomEntry(roomName, hostName, playerCount, gameMode)
	local entry = Instance.new("TextButton")
	entry.Size = UDim2.new(1, -10, 0, 40)
	-- New format: Room Name - Host: HostName (Mode | Players: X/Y)
	entry.Text = string.format(" %s - Host: %s (%s | Pemain: %s)", roomName, hostName, gameMode or "Story", playerCount)
	entry.Font = Enum.Font.SourceSans
	entry.TextSize = 16 -- Slightly smaller to fit more text
	entry.TextColor3 = Color3.new(1, 1, 1)
	entry.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
	entry.TextXAlignment = Enum.TextXAlignment.Left
	local corner = Instance.new("UICorner", entry)
	corner.CornerRadius = UDim.new(0, 4)
	return entry
end

local function updatePublicRoomsList(roomsData)
	if not joinRoomScrollingFrame then return end

	-- Clear old entries, but keep the layout object
	for _, child in ipairs(joinRoomScrollingFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Populate with new entries
	for roomId, roomData in pairs(roomsData) do
		local roomEntry = createRoomEntry(
			roomData.roomName,
			roomData.hostName,
			string.format("%d/%d", roomData.playerCount, roomData.maxPlayers),
			roomData.gameMode -- Meneruskan mode game
		)
		roomEntry.Parent = joinRoomScrollingFrame

		roomEntry.MouseButton1Click:Connect(function()
			print("Client sending request to join room:", roomId)
			lobbyRemote:FireServer("joinRoom", { roomId = roomId })
		end)
	end
end

lobbyRemote.OnClientEvent:Connect(function(action, data)
	if action == "roomCreated" then
		if data.success then
			print("Client received: Room created successfully! Room ID:", data.roomId)
			switchFrame(preGameLobbyFrame)
		else
			warn("Client received: Failed to create room.")
		end
	elseif action == "publicRoomsUpdate" then
		print("Client received public rooms update.")
		updatePublicRoomsList(data)
	elseif action == "joinSuccess" then
		print("Client successfully joined room:", data.roomId)
		switchFrame(preGameLobbyFrame)
	elseif action == "joinFailed" then
		warn("Client failed to join room:", data.reason)
		-- Show a user-facing error message.
		StarterGui:SetCore("SendNotification", {
			Title = "Lobby",
			Text = data.reason or "An unknown error occurred.",
			Duration = 5
		})
	elseif action == "matchmakingCancelled" then
		print("Client has cancelled matchmaking.")
		resetMatchmakingFrameUI()
	elseif action == "matchFound" then
		print("Client has found a match! Joining room:", data.roomId)
		resetMatchmakingFrameUI()
		switchFrame(preGameLobbyFrame)
	elseif action == "roomUpdate" then
		print("Client received room update for room:", data.roomId)
		-- Any room update implies the countdown is no longer valid. Reset the state.
		isCountdownActive = false
		updatePreGameLobby(data)
	elseif action == "countdownUpdate" then
		updateCountdown(data.value)
	elseif action == "countdownCancelled" then
		print("Client received countdown cancellation.")
		resetPreGameLobbyButton()
	elseif action == "leftRoomSuccess" then
		print("Client successfully left room. Returning to main menu.")
		resetPreGameLobbyButton() -- Reset state when leaving
		switchFrame(nil)
	end
end)

onKickedEvent.OnClientEvent:Connect(function()
	print("Client was kicked from the lobby by the host.")
	-- Use StarterGui:SetCore to show a notification
	StarterGui:SetCore("SendNotification", {
		Title = "Lobby",
		Text = "You have been kicked from the room by the host.",
		Duration = 5
	})
	-- Reset UI back to the main lobby menu
	resetPreGameLobbyButton()
	switchFrame(nil)
end)

updatePlayerBoosterStatusEvent.OnClientEvent:Connect(function(userId, activeBoosterName)
	local label = playerBoosterLabels[userId]
	local icon = playerBoosterIcons[userId]
	if label and icon then
		if activeBoosterName and BoosterConfig[activeBoosterName] then
			label.Text = "   " .. BoosterConfig[activeBoosterName].Name
			icon.Visible = true
			-- NOTE: Update icon image here when asset IDs are available
		else
			label.Text = ""
			icon.Visible = false
		end
	end
end)

print("LobbyRoomUI.lua loaded successfully.")
