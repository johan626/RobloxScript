-- LeaderboardClient.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/LeaderboardClient.lua
-- Script Place: Lobby
-- This single script manages the UI for all leaderboards.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local avatarCache = {} -- Cache for player avatars

-- Wait for necessary modules and remote objects
local LeaderboardConfig = require(ReplicatedStorage:WaitForChild("LeaderboardConfig"))
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local globalCountdownValue = remoteFolder:WaitForChild("LeaderboardCountdown")

local leaderboardUpdaters = {} -- Stores the update function for each leaderboard
local countdownLabels = {} -- Stores the countdown label for each UI

-- --- UI Template Function ---
-- Creates the basic structure for a leaderboard UI.
local function createLeaderboardUI(part, title, face)
	-- Clear existing GUI
	if part:FindFirstChild("LeaderboardGui") then
		part.LeaderboardGui:Destroy()
	end

	local gui = Instance.new("SurfaceGui")
	gui.Name = "LeaderboardGui"
	gui.AlwaysOnTop = false
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.Parent = part

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	mainFrame.BackgroundTransparency = 0.5
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	titleLabel.Text = title
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Parent = mainFrame

	local listFrame = Instance.new("Frame")
	listFrame.Size = UDim2.new(0.9, 0, 0.55, 0) -- Reduced height for 5 players
	listFrame.Position = UDim2.new(0.05, 0, 0.18, 0)
	listFrame.BackgroundTransparency = 1
	listFrame.Parent = mainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listFrame

	-- --- Pagination Controls ---
	local paginationFrame = Instance.new("Frame")
	paginationFrame.Name = "PaginationFrame"
	paginationFrame.Size = UDim2.new(0.9, 0, 0.08, 0)
	paginationFrame.Position = UDim2.new(0.05, 0, 0.74, 0) -- Below the list frame
	paginationFrame.BackgroundTransparency = 1
	paginationFrame.Parent = mainFrame

	local prevButton = Instance.new("TextButton")
	prevButton.Name = "PrevButton"
	prevButton.Size = UDim2.new(0.2, 0, 1, 0)
	prevButton.Position = UDim2.new(0, 0, 0, 0)
	prevButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	prevButton.Font = Enum.Font.SourceSansBold
	prevButton.Text = "<"
	prevButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	prevButton.Parent = paginationFrame

	local nextButton = Instance.new("TextButton")
	nextButton.Name = "NextButton"
	nextButton.Size = UDim2.new(0.2, 0, 1, 0)
	nextButton.Position = UDim2.new(0.8, 0, 0, 0)
	nextButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	nextButton.Font = Enum.Font.SourceSansBold
	nextButton.Text = ">"
	nextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	nextButton.Parent = paginationFrame

	local pageLabel = Instance.new("TextLabel")
	pageLabel.Name = "PageLabel"
	pageLabel.Size = UDim2.new(0.5, 0, 1, 0)
	pageLabel.Position = UDim2.new(0.25, 0, 0, 0)
	pageLabel.BackgroundTransparency = 1
	pageLabel.Font = Enum.Font.SourceSans
	pageLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	pageLabel.TextScaled = true
	pageLabel.Text = "Page 1 / 10"
	pageLabel.Parent = paginationFrame

	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "CountdownLabel"
	countdownLabel.Size = UDim2.new(0.9, 0, 0.05, 0)
	countdownLabel.Position = UDim2.new(0.05, 0, 0.88, 0) -- Position is fine
	countdownLabel.Font = Enum.Font.SourceSans
	countdownLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	countdownLabel.TextScaled = true
	countdownLabel.Text = "Waiting for server..."
	countdownLabel.TextXAlignment = Enum.TextXAlignment.Center
	countdownLabel.Parent = mainFrame
	table.insert(countdownLabels, countdownLabel)

	local playerRankLabel = Instance.new("TextLabel")
	playerRankLabel.Name = "PlayerRankLabel"
	playerRankLabel.Size = UDim2.new(0.9, 0, 0.05, 0)
	playerRankLabel.Position = UDim2.new(0.05, 0, 0.94, 0) -- Position is fine
	playerRankLabel.Font = Enum.Font.SourceSansBold
	playerRankLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
	playerRankLabel.TextScaled = true
	playerRankLabel.Text = ""
	playerRankLabel.TextXAlignment = Enum.TextXAlignment.Center
	playerRankLabel.Parent = mainFrame

	-- --- Row Template ---
	-- --- Row Template --- (Adjusted for 5 rows)
	local rowTemplate = Instance.new("Frame")
	rowTemplate.Name = "RowTemplate"
	rowTemplate.Size = UDim2.new(1, 0, 0.18, 0) -- Adjusted size for 5 items
	rowTemplate.BackgroundTransparency = 1
	rowTemplate.Visible = false
	rowTemplate.Parent = listFrame

	local rankChangeIndicator = Instance.new("TextLabel")
	rankChangeIndicator.Name = "RankChange"
	rankChangeIndicator.Position = UDim2.new(0, 0, 0, 0) -- Moved to the left
	rankChangeIndicator.Size = UDim2.new(0.05, 0, 1, 0)
	rankChangeIndicator.Font = Enum.Font.SourceSansBold
	rankChangeIndicator.TextColor3 = Color3.fromRGB(200, 200, 200)
	rankChangeIndicator.Text = "-"
	rankChangeIndicator.TextScaled = true
	rankChangeIndicator.TextXAlignment = Enum.TextXAlignment.Center
	rankChangeIndicator.BackgroundTransparency = 1
	rankChangeIndicator.Parent = rowTemplate

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Name = "Rank"
	rankLabel.Position = UDim2.new(0.05, 0, 0, 0) -- Moved to the right of the indicator
	rankLabel.Size = UDim2.new(0.1, 0, 1, 0)
	rankLabel.Font = Enum.Font.SourceSans
	rankLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	rankLabel.TextScaled = true
	rankLabel.TextXAlignment = Enum.TextXAlignment.Left
	rankLabel.Parent = rowTemplate

	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "Avatar"
	avatarImage.Position = UDim2.new(0.16, 0, 0.1, 0)
	avatarImage.Size = UDim2.new(0.12, 0, 0.8, 0)
	avatarImage.BackgroundTransparency = 1
	avatarImage.ScaleType = Enum.ScaleType.Crop
	avatarImage.Parent = rowTemplate

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Username"
	nameLabel.Position = UDim2.new(0.29, 0, 0, 0)
	nameLabel.Size = UDim2.new(0.41, 0, 1, 0)
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = rowTemplate

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
	valueLabel.Size = UDim2.new(0.3, 0, 1, 0)
	valueLabel.Font = Enum.Font.SourceSans
	valueLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	valueLabel.TextScaled = true
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = rowTemplate

	local errorLabel = Instance.new("TextLabel")
	errorLabel.Name = "ErrorLabel"
	errorLabel.Size = UDim2.new(0.9, 0, 0.75, 0)
	errorLabel.Position = UDim2.new(0.05, 0, 0.18, 0)
	errorLabel.BackgroundTransparency = 1
	errorLabel.Font = Enum.Font.SourceSansItalic
	errorLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
	errorLabel.Text = "Could not load leaderboard data."
	errorLabel.TextScaled = true
	errorLabel.TextWrapped = true
	errorLabel.Visible = false
	errorLabel.Parent = mainFrame

	return listFrame, rowTemplate, errorLabel, playerRankLabel, prevButton, nextButton, pageLabel
end


-- --- Initialization Loop ---
for key, config in pairs(LeaderboardConfig) do
	local leaderboardPart = Workspace.Leaderboard:WaitForChild(config.PartName)
	if not leaderboardPart then
		warn("LeaderboardClient: Could not find part named " .. config.PartName)
		continue
	end

	local functionName = "GetLeaderboard_" .. key
	local getLeaderboardFunction = remoteFolder:WaitForChild(functionName)

	local listFrame, rowTemplate, errorLabel, playerRankLabel, prevButton, nextButton, pageLabel = createLeaderboardUI(leaderboardPart, config.Title, config.Face)

	-- --- Pagination State ---
	local leaderboardState = {
		allPlayers = {},
		currentPage = 1,
		totalPages = 10,
		playersPerPage = 5
	}

	-- --- Cache for Rank Changes ---
	local rankCache = {} -- Stores UserId -> previous rank

	-- --- Function to Update this Specific UI ---
	local function updateThisLeaderboard()
		local success, result = pcall(function()
			return getLeaderboardFunction:InvokeServer()
		end)

		if not success or not result then
			warn("LeaderboardClient: Failed to invoke " .. functionName .. ". Error: " .. tostring(result))
			listFrame.Visible = false
			playerRankLabel.Visible = false
			errorLabel.Visible = true
			return
		end

		listFrame.Visible = true
		playerRankLabel.Visible = true
		errorLabel.Visible = false

		local newPlayerRanks = result.TopPlayers or {}

		-- 1. Compare ranks and store the change status directly in the player data
		for _, playerData in ipairs(newPlayerRanks) do
			local oldRank = rankCache[playerData.UserId]
			if oldRank then
				if playerData.Rank < oldRank then
					playerData.rankChange = "up"
				elseif playerData.Rank > oldRank then
					playerData.rankChange = "down"
				else
					playerData.rankChange = "same"
				end
			else
				playerData.rankChange = "new"
			end
		end

		-- 2. Now, update the cache for the next cycle
		local newCache = {}
		for _, playerData in ipairs(newPlayerRanks) do
			newCache[playerData.UserId] = playerData.Rank
		end
		rankCache = newCache

		-- 3. Store the processed list of players and reset state
		leaderboardState.allPlayers = newPlayerRanks
		leaderboardState.currentPage = 1
		leaderboardState.totalPages = math.max(1, math.ceil(#leaderboardState.allPlayers / leaderboardState.playersPerPage))

		-- 4. Initial display using the processed data
		displayPage(leaderboardState.currentPage)

		-- Update the player's specific rank info
		local playerInfo = result.PlayerInfo
		if playerInfo and playerInfo.Score then
			if playerInfo.Rank then
				playerRankLabel.Text = string.format("Your Rank: #%d (%s%s)", playerInfo.Rank, config.ValuePrefix, playerInfo.Score)
			else
				-- If rank is not available (player is outside top 10), we need to fetch it separately.
				-- For now, we'll just show the score. A future improvement could be to get the rank directly.
				playerRankLabel.Text = string.format("Your Score: %s%s", config.ValuePrefix, playerInfo.Score)
			end
		else
			playerRankLabel.Text = "You are not ranked."
		end
	end

	-- --- Pagination Logic ---
	function displayPage(page)
		-- Clear existing rows
		for _, child in ipairs(listFrame:GetChildren()) do
			if child:IsA("Frame") and child.Name ~= "RowTemplate" then
				child:Destroy()
			end
		end

		local startIndex = (page - 1) * leaderboardState.playersPerPage + 1
		local endIndex = math.min(startIndex + leaderboardState.playersPerPage - 1, #leaderboardState.allPlayers)

		for i = startIndex, endIndex do
			local playerData = leaderboardState.allPlayers[i]
			if not playerData then break end

			local newRow = rowTemplate:Clone()
			newRow.Name = "PlayerRow"
			newRow.LayoutOrder = i
			newRow.Visible = true

			newRow.Rank.Text = "#" .. playerData.Rank
			newRow.Username.Text = playerData.Username
			newRow.Value.Text = config.ValuePrefix .. tostring(playerData[config.ValueKey])

			-- Update rank change indicator based on pre-calculated status
			local rankChangeIndicator = newRow:FindFirstChild("RankChange")
			if playerData.rankChange == "up" or playerData.rankChange == "new" then
				rankChangeIndicator.Text = "▲"
				rankChangeIndicator.TextColor3 = Color3.fromRGB(0, 255, 127)
			elseif playerData.rankChange == "down" then
				rankChangeIndicator.Text = "▼"
				rankChangeIndicator.TextColor3 = Color3.fromRGB(255, 80, 80)
			else -- "same" or nil
				rankChangeIndicator.Text = "–"
				rankChangeIndicator.TextColor3 = Color3.fromRGB(180, 180, 180)
			end

			if playerData.UserId == localPlayer.UserId then
				newRow.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
				newRow.BackgroundTransparency = 0.5
			end

			if avatarCache[playerData.UserId] then
				newRow.Avatar.Image = avatarCache[playerData.UserId]
			else
				local thumbSuccess, thumbContent, isReady = pcall(function()
					return Players:GetUserThumbnailAsync(playerData.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
				end)
				if thumbSuccess and isReady then
					avatarCache[playerData.UserId] = thumbContent
					newRow.Avatar.Image = thumbContent
				else
					warn("LeaderboardClient: Could not load thumbnail for UserId: " .. tostring(playerData.UserId))
				end
			end
			newRow.Parent = listFrame
		end

		-- Update UI elements
		pageLabel.Text = string.format("Page %d / %d", page, leaderboardState.totalPages)
		prevButton.Visible = page > 1
		nextButton.Visible = page < leaderboardState.totalPages and endIndex < #leaderboardState.allPlayers
	end

	prevButton.MouseButton1Click:Connect(function()
		if leaderboardState.currentPage > 1 then
			leaderboardState.currentPage = leaderboardState.currentPage - 1
			displayPage(leaderboardState.currentPage)
		end
	end)

	nextButton.MouseButton1Click:Connect(function()
		if leaderboardState.currentPage < leaderboardState.totalPages then
			leaderboardState.currentPage = leaderboardState.currentPage + 1
			displayPage(leaderboardState.currentPage)
		end
	end)

	table.insert(leaderboardUpdaters, updateThisLeaderboard)
	pcall(updateThisLeaderboard)
end

-- --- Global Synchronization Logic ---
globalCountdownValue.Changed:Connect(function(newValue)
	local text = string.format("Next update in: %d s", newValue)
	for _, label in ipairs(countdownLabels) do
		label.Text = text
	end

	if newValue == 60 then
		for _, updater in ipairs(leaderboardUpdaters) do
			pcall(updater)
		end
	end
end)

-- Initial display setup for all countdowns
local initialText = string.format("Next update in: %d s", globalCountdownValue.Value)
for _, label in ipairs(countdownLabels) do
	label.Text = initialText
end

print("LeaderboardClient.lua: Initialized successfully with new features.")
