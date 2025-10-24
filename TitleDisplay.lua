-- TitleDisplay.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/TitleDisplay.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local titleChangedEvent = ReplicatedStorage:WaitForChild("TitleChanged")
local getTitleDataFunc = ReplicatedStorage:WaitForChild("GetTitleData")

local function createOrUpdateTitleDisplay(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local head = character:WaitForChild("Head")

	-- Hide default Roblox name and health bar
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local playerInfoGui = head:FindFirstChild("PlayerInfoGui")
	if not playerInfoGui then
		playerInfoGui = Instance.new("BillboardGui")
		playerInfoGui.Name = "PlayerInfoGui"
		playerInfoGui.Parent = head
		playerInfoGui.Adornee = head
		playerInfoGui.Size = UDim2.new(8, 0, 3, 0) -- Use Scale for size in studs
		playerInfoGui.StudsOffset = Vector3.new(0, 2.5, 0) -- Adjusted position
		playerInfoGui.AlwaysOnTop = true
		playerInfoGui.MaxDistance = 100

		local listLayout = Instance.new("UIListLayout")
		listLayout.Parent = playerInfoGui
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Parent = playerInfoGui
		nameLabel.Size = UDim2.new(0.75, 0, 0.375, 0) -- Use scale for size
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.SourceSans
		nameLabel.TextScaled = true -- Scale text to fit
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White
		nameLabel.Text = player.DisplayName
		nameLabel.LayoutOrder = 1 -- Displayed first

		local rankLabel = Instance.new("TextLabel")
		rankLabel.Name = "RankLabel"
		rankLabel.Parent = playerInfoGui
		rankLabel.Size = UDim2.new(0.75, 0, 0.375, 0) -- Use scale for size
		rankLabel.BackgroundTransparency = 1
		rankLabel.Font = Enum.Font.SourceSans
		rankLabel.TextScaled = true -- Scale text to fit
		rankLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow
		rankLabel.Text = ""
		rankLabel.LayoutOrder = 2 -- Displayed second
	end

	-- Get initial title
	local success, titleData = pcall(function()
		return getTitleDataFunc:InvokeServer(player)
	end)

	local rankLabel = playerInfoGui:WaitForChild("RankLabel")
	if success and titleData and titleData.EquippedTitle then
		rankLabel.Text = titleData.EquippedTitle
	else
		rankLabel.Text = "" -- Default to empty string on failure or if nil
	end
end

local function updateTitle(player, newTitle)
	if player and player.Character then
		local head = player.Character:FindFirstChild("Head")
		if head then
			local playerInfoGui = head:FindFirstChild("PlayerInfoGui")
			if playerInfoGui and playerInfoGui:FindFirstChild("RankLabel") then
				-- Ensure newTitle is a string
				playerInfoGui.RankLabel.Text = newTitle or ""
			end
		end
	end
end

-- Handle when a player's title changes
titleChangedEvent.OnClientEvent:Connect(function(player, newTitle)
	updateTitle(player, newTitle)
end)

-- Handle new players joining
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		createOrUpdateTitleDisplay(player)
	end)
end)

-- Handle existing players in the game
for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		createOrUpdateTitleDisplay(player)
	else
		-- If character hasn't loaded yet, connect to the event.
		-- This connection is not redundant because it's in an else block.
		player.CharacterAdded:Connect(function()
			createOrUpdateTitleDisplay(player)
		end)
	end
end
