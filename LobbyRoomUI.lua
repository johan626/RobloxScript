-- LobbyRoomUI.lua (LocalScript)
-- Path: StarterGui/RoomUI.lua
-- Script Place: Lobby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

--[[
	STYLE GUIDE
	This table centralizes the UI's appearance for consistency.
]]
local Style = {
	Colors = {
		Background = Color3.fromRGB(28, 29, 34),          -- Dark grey, almost black
		Primary = Color3.fromRGB(39, 41, 48),            -- Slightly lighter grey for frames
		Secondary = Color3.fromRGB(58, 61, 70),          -- Grey for buttons, inputs
		Accent = Color3.fromRGB(0, 170, 255),            -- Bright blue for highlights
		Success = Color3.fromRGB(88, 255, 120),          -- Green for "start", "confirm"
		Danger = Color3.fromRGB(255, 80, 80),            -- Red for "kick", "leave"
		Text = Color3.fromRGB(230, 230, 230),            -- Off-white for body text
		TextHeader = Color3.fromRGB(255, 255, 255),      -- Pure white for titles
		TextMuted = Color3.fromRGB(150, 150, 150),      -- Grey for subtitles, placeholders
		Gold = Color3.fromRGB(255, 196, 0)               -- For special highlights like boosters
	},
	Fonts = {
		Header = Enum.Font.SourceSansBold,
		Body = Enum.Font.SourceSans,
		Light = Enum.Font.SourceSansLight
	},
	Sizes = {
		Header = 28,
		Subheader = 22,
		Body = 18,
		Small = 14
	},
	Radius = UDim.new(0, 8)
}


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

-- Main Frame (Redesigned: larger and more modern)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = lobbyScreenGui
mainFrame.Size = UDim2.new(0, 850, 0, 500) -- Larger size
mainFrame.Position = UDim2.new(0.5, -425, 0.5, -250)
mainFrame.BackgroundColor3 = Style.Colors.Background
mainFrame.BorderSizePixel = 0
mainFrame.Active = true

local corner = Instance.new("UICorner")
corner.CornerRadius = Style.Radius
corner.Parent = mainFrame

-- Add a subtle border/stroke to the main frame
local stroke = Instance.new("UIStroke")
stroke.Color = Style.Colors.Accent
stroke.Thickness = 1
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Parent = mainFrame
titleLabel.Size = UDim2.new(1, 0, 0, 60) -- Taller header
titleLabel.BackgroundColor3 = Style.Colors.Primary
titleLabel.Text = "LOBBY"
titleLabel.Font = Style.Fonts.Header
titleLabel.TextColor3 = Style.Colors.TextHeader
titleLabel.TextSize = Style.Sizes.Header

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = Style.Radius
titleCorner.Parent = titleLabel

-- Buttons
-- Redesigned Navigation/Button area
local navFrame = Instance.new("Frame")
navFrame.Name = "NavigationFrame"
navFrame.Parent = mainFrame
navFrame.Size = UDim2.new(0, 200, 1, -60) -- Left sidebar
navFrame.Position = UDim2.new(0, 0, 0, 60)
navFrame.BackgroundColor3 = Style.Colors.Primary
navFrame.BorderSizePixel = 0

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.Parent = navFrame
buttonLayout.FillDirection = Enum.FillDirection.Vertical
buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.Padding = UDim.new(0, 10)
buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Top

-- Content area for the sub-frames
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Parent = mainFrame
contentFrame.Size = UDim2.new(1, -200, 1, -60)
contentFrame.Position = UDim2.new(0, 200, 0, 60)
contentFrame.BackgroundColor3 = Style.Colors.Background
contentFrame.BorderSizePixel = 0


local function createButton(text, order)
	local button = Instance.new("TextButton")
	button.Name = text .. "Button"
	button.Parent = navFrame -- Buttons are now in the nav frame
	button.LayoutOrder = order
	button.Size = UDim2.new(1, -20, 0, 45) -- Responsive width
	button.BackgroundColor3 = Style.Colors.Secondary
	button.Text = text
	button.Font = Style.Fonts.Body
	button.TextColor3 = Style.Colors.Text
	button.TextSize = Style.Sizes.Body

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = Style.Radius
	btnCorner.Parent = button

	return button
end

local createRoomButton = createButton("Create Room", 1)
local joinRoomButton = createButton("Join Room", 2)
local matchmakingButton = createButton("Matchmaking", 3)
local soloButton = createButton("Solo", 4)

-- Sub-Frames for different actions (now parented to contentFrame)
local function createSubFrame(name)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Parent = contentFrame -- Parented to the new content area
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.Position = UDim2.new(0, 0, 0, 0)
	frame.BackgroundColor3 = Style.Colors.Background -- Use style color
	frame.BorderSizePixel = 0
	frame.Visible = false -- Hidden by default
	return frame
end

local createRoomFrame = createSubFrame("CreateRoomFrame")
local joinRoomFrame = createSubFrame("JoinRoomFrame")
local matchmakingFrame = createSubFrame("MatchmakingFrame")
local preGameLobbyFrame = createSubFrame("PreGameLobbyFrame")
local soloFrame = createSubFrame("SoloFrame")

-- Function to switch between frames
local currentFrame = nil
local function switchFrame(frameToShow)
	-- Hide all sub-frames in the content area
	for _, child in ipairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") then
			child.Visible = false
		end
	end

	-- Update navigation button appearances
	for _, button in ipairs(navFrame:GetChildren()) do
		if button:IsA("TextButton") then
			local isSelected = (frameToShow and frameToShow.Name == button.Name:gsub("Button", "Frame"))
			button.BackgroundColor3 = isSelected and Style.Colors.Accent or Style.Colors.Secondary
		end
	end

	if frameToShow then
		frameToShow.Visible = true
	end
	currentFrame = frameToShow
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
	label.Font = Style.Fonts.Body
	label.TextSize = Style.Sizes.Body
	label.TextColor3 = Style.Colors.Text
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left

	local buttonsFrame = Instance.new("Frame", difficultyFrame)
	buttonsFrame.Name = "DifficultyButtons"
	buttonsFrame.Size = UDim2.new(1, 0, 1, -25)
	buttonsFrame.Position = UDim2.new(0, 0, 0, 25)
	buttonsFrame.BackgroundTransparency = 1
	local gridLayout = Instance.new("UIGridLayout", buttonsFrame)
	gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
	gridLayout.CellSize = UDim2.new(0, 80, 0, 35) -- Larger buttons

	local difficulties = {"Easy", "Normal", "Hard", "Expert", "Hell", "Crazy"}
	local selectedDifficulty = "Easy" -- Default
	local buttons = {}

	for _, diffName in ipairs(difficulties) do
		local button = Instance.new("TextButton", buttonsFrame)
		button.Name = diffName
		button.Text = diffName
		button.Font = Style.Fonts.Body
		button.TextSize = Style.Sizes.Small
		button.BackgroundColor3 = Style.Colors.Secondary
		button.TextColor3 = Style.Colors.Text
		local corner = Instance.new("UICorner", button)
		corner.CornerRadius = UDim.new(0, 6)
		buttons[diffName] = button

		button.MouseButton1Click:Connect(function()
			selectedDifficulty = diffName
			for name, btn in pairs(buttons) do
				btn.BackgroundColor3 = (name == diffName) and Style.Colors.Accent or Style.Colors.Secondary
			end
			if onSelectionChanged then
				onSelectionChanged(selectedDifficulty)
			end
		end)
	end

	-- Set default selection
	buttons["Easy"].BackgroundColor3 = Style.Colors.Accent

	return difficultyFrame
end

-- Populate CreateRoomFrame
local function populateCreateRoomFrame()
	local title = Instance.new("TextLabel", createRoomFrame)
	title.Size = UDim2.new(1, -40, 0, 50)
	title.Position = UDim2.new(0, 20, 0, 10)
	title.Text = "Create a New Room"
	title.Font = Style.Fonts.Header
	title.TextSize = Style.Sizes.Subheader
	title.TextColor3 = Style.Colors.TextHeader
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left

	local backButton = Instance.new("TextButton", createRoomFrame)
	backButton.Size = UDim2.new(0, 80, 0, 35)
	backButton.Position = UDim2.new(1, -100, 0, 20)
	backButton.Text = "Back"
	backButton.Font = Style.Fonts.Body
	backButton.TextSize = Style.Sizes.Body
	backButton.BackgroundColor3 = Style.Colors.Secondary
	backButton.TextColor3 = Style.Colors.Text
	local backCorner = Instance.new("UICorner", backButton)
	backCorner.CornerRadius = Style.Radius

	backButton.MouseButton1Click:Connect(function()
		switchFrame(nil) -- Go back to main menu
	end)

	--[[ Re-layout the options ]]
	local optionsFrame = Instance.new("Frame", createRoomFrame)
	optionsFrame.Size = UDim2.new(1, -40, 1, -140)
	optionsFrame.Position = UDim2.new(0, 20, 0, 70)
	optionsFrame.BackgroundTransparency = 1
	local listLayout = Instance.new("UIListLayout", optionsFrame)
	listLayout.Padding = UDim.new(0, 15)

	-- Room Name
	local roomNameLabel = Instance.new("TextLabel", optionsFrame)
	roomNameLabel.Size = UDim2.new(1, 0, 0, 20)
	roomNameLabel.Text = "Room Name (Optional)"
	roomNameLabel.Font = Style.Fonts.Body
	roomNameLabel.TextSize = Style.Sizes.Body
	roomNameLabel.TextColor3 = Style.Colors.Text
	roomNameLabel.BackgroundTransparency = 1
	roomNameLabel.TextXAlignment = Enum.TextXAlignment.Left

	local roomNameInput = Instance.new("TextBox", optionsFrame)
	roomNameInput.Size = UDim2.new(1, 0, 0, 40)
	roomNameInput.Font = Style.Fonts.Body
	roomNameInput.Text = ""
	roomNameInput.PlaceholderText = "Enter a name..."
	roomNameInput.PlaceholderColor3 = Style.Colors.TextMuted
	roomNameInput.TextColor3 = Style.Colors.Text
	roomNameInput.BackgroundColor3 = Style.Colors.Secondary
	local roomNameCorner = Instance.new("UICorner", roomNameInput)
	roomNameCorner.CornerRadius = Style.Radius

	-- Max Players
	local playerCountLabel = Instance.new("TextLabel", optionsFrame)
	playerCountLabel.Size = UDim2.new(1, 0, 0, 20)
	playerCountLabel.Text = "Max Players (2-8)"
	playerCountLabel.Font = Style.Fonts.Body
	playerCountLabel.TextSize = Style.Sizes.Body
	playerCountLabel.TextColor3 = Style.Colors.Text
	playerCountLabel.BackgroundTransparency = 1
	playerCountLabel.TextXAlignment = Enum.TextXAlignment.Left

	local playerCountInput = Instance.new("TextBox", optionsFrame)
	playerCountInput.Size = UDim2.new(0, 100, 0, 40)
	playerCountInput.Font = Style.Fonts.Body
	playerCountInput.Text = "4"
	playerCountInput.TextColor3 = Style.Colors.Text
	playerCountInput.BackgroundColor3 = Style.Colors.Secondary
	local inputCorner = Instance.new("UICorner", playerCountInput)
	inputCorner.CornerRadius = Style.Radius

	-- Toggles (Private & Mode) in a horizontal frame
	local togglesFrame = Instance.new("Frame", optionsFrame)
	togglesFrame.Size = UDim2.new(1, 0, 0, 40)
	togglesFrame.BackgroundTransparency = 1
	local gridLayout = Instance.new("UIGridLayout", togglesFrame)
	gridLayout.CellSize = UDim2.new(0.5, -5, 1, 0)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 0)

	local isPrivate = false
	local privateToggle = Instance.new("TextButton", togglesFrame)
	privateToggle.Size = UDim2.new(1, 0, 1, 0)
	privateToggle.Text = "Room: Public"
	privateToggle.Font = Style.Fonts.Body
	privateToggle.TextSize = Style.Sizes.Body
	privateToggle.BackgroundColor3 = Style.Colors.Secondary
	privateToggle.TextColor3 = Style.Colors.Text
	local privateCorner = Instance.new("UICorner", privateToggle)
	privateCorner.CornerRadius = Style.Radius

	privateToggle.MouseButton1Click:Connect(function()
		isPrivate = not isPrivate
		privateToggle.Text = isPrivate and "Room: Private" or "Room: Public"
	end)

	local gameMode = "Story" -- Default mode
	local modeButton = Instance.new("TextButton", togglesFrame)
	modeButton.Size = UDim2.new(1, 0, 1, 0)
	modeButton.Text = "Mode: Story"
	modeButton.Font = Style.Fonts.Body
	modeButton.TextSize = Style.Sizes.Body
	modeButton.BackgroundColor3 = Style.Colors.Secondary
	modeButton.TextColor3 = Style.Colors.Text
	local modeCorner = Instance.new("UICorner", modeButton)
	modeCorner.CornerRadius = Style.Radius

	modeButton.MouseButton1Click:Connect(function()
		if gameMode == "Story" then
			gameMode = "Endless"
		else
			gameMode = "Story"
		end
		modeButton.Text = "Mode: " .. gameMode
	end)

	-- Difficulty Selector
	local selectedDifficulty = "Easy"
	local difficultySelector = createDifficultySelector(optionsFrame, function(difficulty)
		selectedDifficulty = difficulty
	end)
	difficultySelector.LayoutOrder = 5

	-- Confirm Button
	local confirmButton = Instance.new("TextButton", createRoomFrame)
	confirmButton.Size = UDim2.new(1, -40, 0, 50)
	confirmButton.Position = UDim2.new(0, 20, 1, -70)
	confirmButton.Text = "Confirm & Create"
	confirmButton.Font = Style.Fonts.Header
	confirmButton.TextSize = Style.Sizes.Subheader
	confirmButton.BackgroundColor3 = Style.Colors.Success
	confirmButton.TextColor3 = Style.Colors.Background
	local confirmCorner = Instance.new("UICorner", confirmButton)
	confirmCorner.CornerRadius = Style.Radius

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
	title.Size = UDim2.new(1, -40, 0, 50)
	title.Position = UDim2.new(0, 20, 0, 10)
	title.Text = "Join a Room"
	title.Font = Style.Fonts.Header
	title.TextSize = Style.Sizes.Subheader
	title.TextColor3 = Style.Colors.TextHeader
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left

	local backButton = Instance.new("TextButton", joinRoomFrame)
	backButton.Size = UDim2.new(0, 80, 0, 35)
	backButton.Position = UDim2.new(1, -100, 0, 20)
	backButton.Text = "Back"
	backButton.Font = Style.Fonts.Body
	backButton.TextSize = Style.Sizes.Body
	backButton.BackgroundColor3 = Style.Colors.Secondary
	backButton.TextColor3 = Style.Colors.Text
	local backCorner = Instance.new("UICorner", backButton)
	backCorner.CornerRadius = Style.Radius
	backButton.MouseButton1Click:Connect(function()
		switchFrame(nil)
	end)

	local publicRoomsLabel = Instance.new("TextLabel", joinRoomFrame)
	publicRoomsLabel.Size = UDim2.new(1, -40, 0, 20)
	publicRoomsLabel.Position = UDim2.new(0, 20, 0, 70)
	publicRoomsLabel.Text = "Public Rooms"
	publicRoomsLabel.Font = Style.Fonts.Body
	publicRoomsLabel.TextSize = Style.Sizes.Body
	publicRoomsLabel.TextColor3 = Style.Colors.Text
	publicRoomsLabel.BackgroundTransparency = 1
	publicRoomsLabel.TextXAlignment = Enum.TextXAlignment.Left

	local scrollingFrame = Instance.new("ScrollingFrame", joinRoomFrame)
	scrollingFrame.Size = UDim2.new(1, -40, 1, -200)
	scrollingFrame.Position = UDim2.new(0, 20, 0, 100)
	scrollingFrame.BackgroundColor3 = Style.Colors.Primary
	scrollingFrame.BorderSizePixel = 0
	local listLayout = Instance.new("UIListLayout", scrollingFrame)
	listLayout.Padding = UDim.new(0, 5)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local scrollingCorner = Instance.new("UICorner", scrollingFrame)
	scrollingCorner.CornerRadius = Style.Radius

	joinRoomScrollingFrame = scrollingFrame

	-- Join with Code Section
	local joinCodeFrame = Instance.new("Frame", joinRoomFrame)
	joinCodeFrame.Size = UDim2.new(1, -40, 0, 50)
	joinCodeFrame.Position = UDim2.new(0, 20, 1, -70)
	joinCodeFrame.BackgroundTransparency = 1
	local grid = Instance.new("UIGridLayout", joinCodeFrame)
	grid.CellSize = UDim2.new(0.7, -5, 1, 0)
	grid.CellPadding = UDim2.new(0, 10, 0, 0)

	local roomCodeInput = Instance.new("TextBox", joinCodeFrame)
	roomCodeInput.Name = "roomCodeInput"
	roomCodeInput.Size = UDim2.new(1, 0, 1, 0)
	roomCodeInput.PlaceholderText = "Enter Room Code..."
	roomCodeInput.PlaceholderColor3 = Style.Colors.TextMuted
	roomCodeInput.Font = Style.Fonts.Body
	roomCodeInput.TextSize = Style.Sizes.Body
	roomCodeInput.TextColor3 = Style.Colors.Text
	roomCodeInput.BackgroundColor3 = Style.Colors.Secondary
	local codeCorner = Instance.new("UICorner", roomCodeInput)
	codeCorner.CornerRadius = Style.Radius

	local joinWithCodeButton = Instance.new("TextButton", joinCodeFrame)
	joinWithCodeButton.Name = "joinWithCodeButton"
	joinWithCodeButton.Size = UDim2.new(1, 0, 1, 0)
	joinWithCodeButton.Text = "Join"
	joinWithCodeButton.Font = Style.Fonts.Body
	joinWithCodeButton.TextSize = Style.Sizes.Body
	joinWithCodeButton.BackgroundColor3 = Style.Colors.Accent
	joinWithCodeButton.TextColor3 = Style.Colors.TextHeader
	local joinCorner = Instance.new("UICorner", joinWithCodeButton)
	joinCorner.CornerRadius = Style.Radius

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
	local titleLabel = preGameLobbyFrame:FindFirstChild("TitleLabel")
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
	if gameModeLabel then
		gameModeLabel.Text = "Mode: " .. (roomData.gameMode or "Story")
	end

	-- Update Difficulty display
	local difficultyLabel = preGameLobbyFrame:FindFirstChild("DifficultyLabel")
	if difficultyLabel then
		difficultyLabel.Text = "Difficulty: " .. (roomData.difficulty or "Easy")
	end


	-- Clear old player list
	for _, child in ipairs(preGameLobbyPlayerList:GetChildren()) do
		if not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end
	playerBoosterLabels = {} -- Clear old labels
	playerBoosterIcons = {} -- Clear old icons

	-- Add new player labels
	for _, playerData in ipairs(roomData.players) do
		local playerFrame = Instance.new("Frame")
		playerFrame.Size = UDim2.new(1, 0, 0, 70)
		playerFrame.BackgroundColor3 = Style.Colors.Primary
		local corner = Instance.new("UICorner", playerFrame)
		corner.CornerRadius = Style.Radius
		playerFrame.Parent = preGameLobbyPlayerList

		local playerLabel = Instance.new("TextLabel")
		playerLabel.Size = UDim2.new(1, -80, 0.6, 0)
		playerLabel.Position = UDim2.new(0, 15, 0, 0)
		playerLabel.Parent = playerFrame

		local displayText = string.format("[Lv. %d] %s", playerData.Level or 1, playerData.Name)
		if playerData.Name == roomData.hostName then
			displayText = displayText .. " (Host)"
		end
		playerLabel.Text = displayText
		playerLabel.Font = Style.Fonts.Body
		playerLabel.TextSize = Style.Sizes.Body
		playerLabel.TextColor3 = Style.Colors.TextHeader
		playerLabel.TextXAlignment = Enum.TextXAlignment.Left
		playerLabel.BackgroundTransparency = 1

		local boosterLabel = Instance.new("TextLabel")
		boosterLabel.Name = "BoosterLabel"
		boosterLabel.Size = UDim2.new(1, -20, 0.4, 0)
		boosterLabel.Position = UDim2.new(0, 15, 0.6, 0)
		boosterLabel.Font = Style.Fonts.Light
		boosterLabel.TextSize = Style.Sizes.Small
		boosterLabel.TextColor3 = Style.Colors.Gold
		boosterLabel.BackgroundTransparency = 1
		boosterLabel.TextXAlignment = Enum.TextXAlignment.Left
		boosterLabel.Parent = playerFrame

		local boosterIcon = Instance.new("ImageLabel")
		boosterIcon.Name = "BoosterIcon"
		boosterIcon.Size = UDim2.new(0, 16, 0, 16)
		boosterIcon.Position = UDim2.new(0, 0, 0.5, -8)
		boosterIcon.BackgroundTransparency = 1
		boosterIcon.Parent = boosterLabel

		if playerData.ActiveBooster and BoosterConfig[playerData.ActiveBooster] then
			boosterLabel.Text = "   " .. BoosterConfig[playerData.ActiveBooster].Name
			boosterIcon.Visible = true
		else
			boosterLabel.Text = "No booster active"
			boosterIcon.Visible = false
		end
		playerBoosterLabels[playerData.UserId] = boosterLabel
		playerBoosterIcons[playerData.UserId] = boosterIcon


		-- Add Kick Button
		local isHost = (player.Name == roomData.hostName)
		if isHost and playerData.Name ~= player.Name then
			local kickButton = Instance.new("TextButton")
			kickButton.Name = "KickButton"
			kickButton.Size = UDim2.new(0, 60, 1, -20)
			kickButton.Position = UDim2.new(1, -70, 0, 10)
			kickButton.Text = "Kick"
			kickButton.Font = Style.Fonts.Body
			kickButton.TextSize = Style.Sizes.Small
			kickButton.BackgroundColor3 = Style.Colors.Danger
			kickButton.TextColor3 = Style.Colors.TextHeader
			local kickCorner = Instance.new("UICorner", kickButton)
			kickCorner.CornerRadius = UDim.new(0, 6)
			kickButton.Parent = playerFrame

			kickButton.MouseButton1Click:Connect(function()
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
			startGameButton.AutoButtonColor = isFull
			if isFull then
				startGameButton.BackgroundColor3 = Style.Colors.Success
				startGameButton.Text = "Start Game"
			else
				startGameButton.BackgroundColor3 = Style.Colors.Secondary
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
			preGameLobbyCountdownLabel.Text = "Waiting for more players..."
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
	local title = Instance.new("TextLabel", matchmakingFrame)
	title.Size = UDim2.new(1, -40, 0, 50)
	title.Position = UDim2.new(0, 20, 0, 10)
	title.Text = "Matchmaking"
	title.Font = Style.Fonts.Header
	title.TextSize = Style.Sizes.Subheader
	title.TextColor3 = Style.Colors.TextHeader
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left

	local optionsFrame = Instance.new("Frame", matchmakingFrame)
	optionsFrame.Size = UDim2.new(1, -40, 1, -140)
	optionsFrame.Position = UDim2.new(0, 20, 0, 70)
	optionsFrame.BackgroundTransparency = 1
	local listLayout = Instance.new("UIListLayout", optionsFrame)
	listLayout.Padding = UDim.new(0, 15)

	-- Elements for starting a search
	local startElements = {}

	local playerCountLabel = Instance.new("TextLabel", optionsFrame)
	playerCountLabel.Size = UDim2.new(1, 0, 0, 20)
	playerCountLabel.Text = "Players (2-8)"
	playerCountLabel.Font = Style.Fonts.Body
	playerCountLabel.TextSize = Style.Sizes.Body
	playerCountLabel.TextColor3 = Style.Colors.Text
	playerCountLabel.BackgroundTransparency = 1
	playerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
	table.insert(startElements, playerCountLabel)

	local playerCountInput = Instance.new("TextBox", optionsFrame)
	playerCountInput.Size = UDim2.new(0, 100, 0, 40)
	playerCountInput.Font = Style.Fonts.Body
	playerCountInput.Text = "4"
	playerCountInput.TextColor3 = Style.Colors.Text
	playerCountInput.BackgroundColor3 = Style.Colors.Secondary
	local inputCorner = Instance.new("UICorner", playerCountInput)
	inputCorner.CornerRadius = Style.Radius
	table.insert(startElements, playerCountInput)

	local matchmakingMode = "Story" -- Default mode
	local modeButton = Instance.new("TextButton", optionsFrame)
	modeButton.Size = UDim2.new(1, 0, 0, 40)
	modeButton.Text = "Mode: Story"
	modeButton.Font = Style.Fonts.Body
	modeButton.TextSize = Style.Sizes.Body
	modeButton.BackgroundColor3 = Style.Colors.Secondary
	modeButton.TextColor3 = Style.Colors.Text
	local modeCorner = Instance.new("UICorner", modeButton)
	modeCorner.CornerRadius = Style.Radius
	table.insert(startElements, modeButton)

	modeButton.MouseButton1Click:Connect(function()
		if matchmakingMode == "Story" then
			matchmakingMode = "Endless"
		else
			matchmakingMode = "Story"
		end
		modeButton.Text = "Mode: " .. matchmakingMode
	end)

	local selectedDifficulty = "Easy"
	local difficultySelector = createDifficultySelector(optionsFrame, function(difficulty)
		selectedDifficulty = difficulty
	end)
	table.insert(startElements, difficultySelector)

	local startButton = Instance.new("TextButton", matchmakingFrame)
	startButton.Size = UDim2.new(1, -40, 0, 50)
	startButton.Position = UDim2.new(0, 20, 1, -70)
	startButton.Text = "Start Search"
	startButton.Font = Style.Fonts.Header
	startButton.TextSize = Style.Sizes.Subheader
	startButton.BackgroundColor3 = Style.Colors.Accent
	startButton.TextColor3 = Style.Colors.TextHeader
	local startCorner = Instance.new("UICorner", startButton)
	startCorner.CornerRadius = Style.Radius
	table.insert(startElements, startButton)

	-- Elements for when searching is in progress
	local searchingElements = {}
	local searchingLabel = Instance.new("TextLabel", matchmakingFrame)
	searchingLabel.Size = UDim2.new(1, 0, 0.5, 0)
	searchingLabel.Position = UDim2.new(0, 0, 0.2, 0)
	searchingLabel.Text = "Searching for players..."
	searchingLabel.Font = Style.Fonts.Header
	searchingLabel.TextSize = Style.Sizes.Subheader
	searchingLabel.TextColor3 = Style.Colors.Text
	searchingLabel.BackgroundTransparency = 1
	searchingLabel.Visible = false
	table.insert(searchingElements, searchingLabel)

	local cancelButton = Instance.new("TextButton", matchmakingFrame)
	cancelButton.Size = UDim2.new(1, -40, 0, 50)
	cancelButton.Position = UDim2.new(0, 20, 1, -70)
	cancelButton.Text = "Cancel Search"
	cancelButton.Font = Style.Fonts.Header
	cancelButton.TextSize = Style.Sizes.Subheader
	cancelButton.BackgroundColor3 = Style.Colors.Danger
	cancelButton.TextColor3 = Style.Colors.TextHeader
	local cancelCorner = Instance.new("UICorner", cancelButton)
	cancelCorner.CornerRadius = Style.Radius
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
	end)
end

-- Populate PreGameLobbyFrame
local function populatePreGameLobbyFrame()
	-- Main container for player cards
	local playerList = Instance.new("ScrollingFrame", preGameLobbyFrame)
	playerList.Size = UDim2.new(0.7, -15, 1, -80)
	playerList.Position = UDim2.new(0, 10, 0, 10)
	playerList.BackgroundColor3 = Style.Colors.Background
	playerList.BorderSizePixel = 0
	local gridLayout = Instance.new("UIGridLayout", playerList)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.CellSize = UDim2.new(0.5, -5, 0, 70)
	preGameLobbyPlayerList = playerList

	-- Sidebar for room info and actions
	local sidebar = Instance.new("Frame", preGameLobbyFrame)
	sidebar.Size = UDim2.new(0.3, -15, 1, -80)
	sidebar.Position = UDim2.new(0.7, 0, 0, 10)
	sidebar.BackgroundTransparency = 1

	local title = Instance.new("TextLabel", sidebar)
	title.Name = "TitleLabel"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Text = "LOBBY"
	title.Font = Style.Fonts.Header
	title.TextSize = Style.Sizes.Header
	title.TextColor3 = Style.Colors.TextHeader
	title.BackgroundTransparency = 1

	local roomCodeLabel = Instance.new("TextLabel", sidebar)
	roomCodeLabel.Name = "RoomCodeLabel"
	roomCodeLabel.Size = UDim2.new(1, 0, 0, 20)
	roomCodeLabel.Position = UDim2.new(0, 0, 0, 35)
	roomCodeLabel.Font = Style.Fonts.Light
	roomCodeLabel.Text = "Room Code: ..."
	roomCodeLabel.TextSize = Style.Sizes.Small
	roomCodeLabel.TextColor3 = Style.Colors.TextMuted
	roomCodeLabel.BackgroundTransparency = 1
	roomCodeLabel.Visible = false
	preGameLobbyRoomCodeLabel = roomCodeLabel

	local gameModeLabel = Instance.new("TextLabel", sidebar)
	gameModeLabel.Name = "GameModeLabel"
	gameModeLabel.Size = UDim2.new(1, 0, 0, 20)
	gameModeLabel.Position = UDim2.new(0, 0, 0, 60)
	gameModeLabel.Font = Style.Fonts.Body
	gameModeLabel.Text = "Mode: ..."
	gameModeLabel.TextSize = Style.Sizes.Body
	gameModeLabel.TextColor3 = Style.Colors.Text
	gameModeLabel.BackgroundTransparency = 1

	local difficultyLabel = Instance.new("TextLabel", sidebar)
	difficultyLabel.Name = "DifficultyLabel"
	difficultyLabel.Size = UDim2.new(1, 0, 0, 20)
	difficultyLabel.Position = UDim2.new(0, 0, 0, 85)
	difficultyLabel.Font = Style.Fonts.Body
	difficultyLabel.Text = "Difficulty: ..."
	difficultyLabel.TextSize = Style.Sizes.Body
	difficultyLabel.TextColor3 = Style.Colors.Text
	difficultyLabel.BackgroundTransparency = 1

	local leaveButton = Instance.new("TextButton", sidebar)
	leaveButton.Name = "LeaveButton"
	leaveButton.Size = UDim2.new(1, 0, 0, 40)
	leaveButton.Position = UDim2.new(0, 0, 1, -50)
	leaveButton.Text = "Leave"
	leaveButton.Font = Style.Fonts.Body
	leaveButton.TextSize = Style.Sizes.Body
	leaveButton.BackgroundColor3 = Style.Colors.Danger
	leaveButton.TextColor3 = Style.Colors.TextHeader
	local leaveCorner = Instance.new("UICorner", leaveButton)
	leaveCorner.CornerRadius = Style.Radius
	leaveButton.MouseButton1Click:Connect(function()
		if leaveButton.AutoButtonColor then lobbyRemote:FireServer("leaveRoom") end
	end)

	-- Bottom bar for status and start button
	local bottomBar = Instance.new("Frame", preGameLobbyFrame)
	bottomBar.Size = UDim2.new(1, 0, 0, 60)
	bottomBar.Position = UDim2.new(0, 0, 1, -60)
	bottomBar.BackgroundColor3 = Style.Colors.Primary
	local bottomCorner = Instance.new("UICorner", bottomBar)
	bottomCorner.CornerRadius = Style.Radius

	local countdownLabel = Instance.new("TextLabel", bottomBar)
	countdownLabel.Size = UDim2.new(0.5, 0, 1, 0)
	countdownLabel.Position = UDim2.new(0, 15, 0, 0)
	countdownLabel.Text = "Waiting for players..."
	countdownLabel.Font = Style.Fonts.Body
	countdownLabel.TextSize = Style.Sizes.Body
	countdownLabel.TextColor3 = Style.Colors.Text
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.TextXAlignment = Enum.TextXAlignment.Left
	preGameLobbyCountdownLabel = countdownLabel

	local startGameButton = Instance.new("TextButton", bottomBar)
	startGameButton.Name = "StartGameButton"
	startGameButton.Size = UDim2.new(0.4, 0, 1, -20)
	startGameButton.Position = UDim2.new(0.6, -10, 0, 10)
	startGameButton.Text = "Start Game"
	startGameButton.Font = Style.Fonts.Body
	startGameButton.TextSize = Style.Sizes.Body
	startGameButton.BackgroundColor3 = Style.Colors.Success
	startGameButton.TextColor3 = Style.Colors.Background
	local startCorner = Instance.new("UICorner", startGameButton)
	startCorner.CornerRadius = Style.Radius
	startGameButton.Visible = false
	startGameButton.MouseButton1Click:Connect(function()
		if not startGameButton.AutoButtonColor then return end
		if isCountdownActive then
			lobbyRemote:FireServer("cancelCountdown")
		else
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
	title.Size = UDim2.new(1, -40, 0, 50)
	title.Position = UDim2.new(0, 20, 0, 10)
	title.Text = "Play Solo"
	title.Font = Style.Fonts.Header
	title.TextSize = Style.Sizes.Subheader
	title.TextColor3 = Style.Colors.TextHeader
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left

	local optionsFrame = Instance.new("Frame", soloFrame)
	optionsFrame.Size = UDim2.new(1, -40, 1, -140)
	optionsFrame.Position = UDim2.new(0, 20, 0, 70)
	optionsFrame.BackgroundTransparency = 1
	local listLayout = Instance.new("UIListLayout", optionsFrame)
	listLayout.Padding = UDim.new(0, 15)

	local selectedMode = "Story"
	local selectedDifficulty = "Easy"

	local modeLabel = Instance.new("TextLabel", optionsFrame)
	modeLabel.Size = UDim2.new(1, 0, 0, 20)
	modeLabel.Text = "Game Mode"
	modeLabel.Font = Style.Fonts.Body
	modeLabel.TextSize = Style.Sizes.Body
	modeLabel.TextColor3 = Style.Colors.Text
	modeLabel.BackgroundTransparency = 1
	modeLabel.TextXAlignment = Enum.TextXAlignment.Left

	local modeButtonsFrame = Instance.new("Frame", optionsFrame)
	modeButtonsFrame.Size = UDim2.new(1, 0, 0, 40)
	modeButtonsFrame.BackgroundTransparency = 1
	local grid = Instance.new("UIGridLayout", modeButtonsFrame)
	grid.CellSize = UDim2.new(0.5, -5, 1, 0)
	grid.CellPadding = UDim2.new(0, 10, 0, 0)

	local storyButton = Instance.new("TextButton", modeButtonsFrame)
	storyButton.Text = "Story"
	local endlessButton = Instance.new("TextButton", modeButtonsFrame)
	endlessButton.Text = "Endless"

	for _, button in ipairs({storyButton, endlessButton}) do
		button.Size = UDim2.new(1,0,1,0)
		button.Font = Style.Fonts.Body
		button.TextSize = Style.Sizes.Body
		button.TextColor3 = Style.Colors.Text
		button.BackgroundColor3 = Style.Colors.Secondary
		local corner = Instance.new("UICorner", button)
		corner.CornerRadius = Style.Radius
	end

	storyButton.MouseButton1Click:Connect(function()
		selectedMode = "Story"
		storyButton.BackgroundColor3 = Style.Colors.Accent
		endlessButton.BackgroundColor3 = Style.Colors.Secondary
	end)

	endlessButton.MouseButton1Click:Connect(function()
		selectedMode = "Endless"
		endlessButton.BackgroundColor3 = Style.Colors.Accent
		storyButton.BackgroundColor3 = Style.Colors.Secondary
	end)
	storyButton.BackgroundColor3 = Style.Colors.Accent -- Default selection

	local difficultySelector = createDifficultySelector(optionsFrame, function(difficulty)
		selectedDifficulty = difficulty
	end)

	local startSoloButton = Instance.new("TextButton", soloFrame)
	startSoloButton.Size = UDim2.new(1, -40, 0, 50)
	startSoloButton.Position = UDim2.new(0, 20, 1, -70)
	startSoloButton.Text = "Start Solo Game"
	startSoloButton.Font = Style.Fonts.Header
	startSoloButton.TextSize = Style.Sizes.Subheader
	startSoloButton.BackgroundColor3 = Style.Colors.Success
	startSoloButton.TextColor3 = Style.Colors.Background
	local startCorner = Instance.new("UICorner", startSoloButton)
	startCorner.CornerRadius = Style.Radius

	startSoloButton.MouseButton1Click:Connect(function()
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
	entry.Size = UDim2.new(1, -10, 0, 50)
	entry.BackgroundColor3 = Style.Colors.Secondary
	local corner = Instance.new("UICorner", entry)
	corner.CornerRadius = Style.Radius

	local title = Instance.new("TextLabel", entry)
	title.Size = UDim2.new(0.7, 0, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.Text = string.format("%s - Host: %s", roomName, hostName)
	title.Font = Style.Fonts.Body
	title.TextSize = Style.Sizes.Body
	title.TextColor3 = Style.Colors.TextHeader
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left

	local details = Instance.new("TextLabel", entry)
	details.Size = UDim2.new(0.3, 0, 1, 0)
	details.Position = UDim2.new(0.7, -15, 0, 0)
	details.Text = string.format("%s | %s", gameMode or "Story", playerCount)
	details.Font = Style.Fonts.Light
	details.TextSize = Style.Sizes.Small
	details.TextColor3 = Style.Colors.TextMuted
	details.BackgroundTransparency = 1
	details.TextXAlignment = Enum.TextXAlignment.Right

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
