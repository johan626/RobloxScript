-- AchievementUI.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/AchievementUI.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then
	return -- Jangan jalankan skrip jika LocalPlayer tidak ada
end

-- Deklarasikan fungsi terlebih dahulu agar bisa direferensikan sebelum definisi penuh
local initialize

-- UI instances for easier access
local screenGui = Instance.new("ScreenGui")
local mainFrame = Instance.new("Frame")
local categoriesFrame = Instance.new("Frame")
local achievementsFrame = Instance.new("ScrollingFrame")
local openButton = Instance.new("TextButton")
local searchBox -- upvalue for search box

-- Buat fungsi toggle terpusat
local function toggleUI(visible)
	if visible then
		initialize() -- Muat data terbaru saat dibuka
	end
	mainFrame.Visible = visible
end

local function createModernUI()
	screenGui.Name = "AchievementGui"
	screenGui.Parent = player.PlayerGui
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Open Button
	openButton.Name = "OpenAchievements"
	openButton.Size = UDim2.new(0, 150, 0, 50)
	openButton.Position = UDim2.new(0, 10, 0.5, -25)
	openButton.Text = "Achievements"
	openButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	openButton.Font = Enum.Font.SourceSansBold
	openButton.TextSize = 18
	openButton.Parent = screenGui
	local openBtnCorner = Instance.new("UICorner")
	openBtnCorner.CornerRadius = UDim.new(0, 8)
	openBtnCorner.Parent = openButton

	-- Main Frame (Hidden by default)
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 700, 0, 500)
	mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
	mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui
	local mainFrameCorner = Instance.new("UICorner")
	mainFrameCorner.CornerRadius = UDim.new(0, 12)
	mainFrameCorner.Parent = mainFrame

	-- Title Label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 40)
	titleLabel.Text = "ACHIEVEMENTS"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 20
	titleLabel.Parent = mainFrame
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = titleLabel

	-- Back Button
	local backButton = Instance.new("TextButton")
	backButton.Name = "BackButton"
	backButton.Size = UDim2.new(0, 80, 0, 30)
	backButton.Position = UDim2.new(0, 10, 0, 5)
	backButton.Text = "‹ Back"
	backButton.Font = Enum.Font.SourceSansBold
	backButton.TextSize = 18
	backButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	backButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	backButton.Parent = titleLabel
	local backBtnCorner = Instance.new("UICorner", backButton)
	backBtnCorner.CornerRadius = UDim.new(0, 6)

	-- Close Button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -40, 0, 5)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.TextSize = 16
	closeButton.BackgroundTransparency = 0.2
	closeButton.Parent = titleLabel
	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(1, 0) -- Make it a circle
	closeBtnCorner.Parent = closeButton

	-- Categories Frame (Left Panel)
	categoriesFrame.Name = "CategoriesFrame"
	categoriesFrame.Size = UDim2.new(0, 180, 1, -50)
	categoriesFrame.Position = UDim2.new(0, 5, 0, 45)
	categoriesFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	categoriesFrame.BorderSizePixel = 0
	categoriesFrame.Parent = mainFrame
	local catFrameCorner = Instance.new("UICorner")
	catFrameCorner.CornerRadius = UDim.new(0, 8)
	catFrameCorner.Parent = categoriesFrame

	local categoriesLayout = Instance.new("UIListLayout")
	categoriesLayout.Padding = UDim.new(0, 5)
	categoriesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	categoriesLayout.Parent = categoriesFrame

	-- Search Box
	searchBox = Instance.new("TextBox")
	searchBox.Name = "SearchBox"
	searchBox.Size = UDim2.new(1, -10, 0, 30)
	searchBox.Position = UDim2.new(0, 5, 0, 5)
	searchBox.Font = Enum.Font.SourceSans
	searchBox.Text = ""
	searchBox.TextSize = 14
	searchBox.PlaceholderText = "Cari achievement..."
	searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	searchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	searchBox.ClearTextOnFocus = false
	searchBox.LayoutOrder = -1 -- Ensure it's at the top
	searchBox.Parent = categoriesFrame
	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 6)
	searchCorner.Parent = searchBox

	-- Achievements Frame (Right Panel)
	achievementsFrame.Name = "AchievementsFrame"
	achievementsFrame.Size = UDim2.new(1, -195, 1, -50)
	achievementsFrame.Position = UDim2.new(0, 190, 0, 45)
	achievementsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	achievementsFrame.BorderSizePixel = 0
	achievementsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	achievementsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	achievementsFrame.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150)
	achievementsFrame.ScrollBarThickness = 6
	achievementsFrame.Parent = mainFrame
	local achFrameCorner = Instance.new("UICorner")
	achFrameCorner.CornerRadius = UDim.new(0, 8)
	achFrameCorner.Parent = achievementsFrame

	local achievementsLayout = Instance.new("UIListLayout")
	achievementsLayout.Padding = UDim.new(0, 10)
	achievementsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	achievementsLayout.Parent = achievementsFrame

	-- Sembunyikan tombol utama
	-- Sembunyikan tombol utama
	openButton.Visible = false

	-- Hubungkan tombol tutup
	local backButton = titleLabel:WaitForChild("BackButton")
	backButton.MouseButton1Click:Connect(function()
		toggleUI(false)
		ReplicatedStorage.BindableEvents.ToggleProfileUIEvent:Fire(true)
	end)

	closeButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
	end)
end



-- Initialize the UI
createModernUI()

local function createAchievementCard(achievementData)
	local card = Instance.new("Frame")
	card.Name = "AchievementCard"
	card.Size = UDim2.new(1, -10, 0, 90)
	card.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	card.BorderSizePixel = 0
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	-- Status Icon (Left side)
	local statusIcon = Instance.new("ImageLabel")
	statusIcon.Name = "StatusIcon"
	statusIcon.Size = UDim2.new(0, 40, 0, 40)
	statusIcon.Position = UDim2.new(0, 15, 0.5, -20)
	statusIcon.BackgroundTransparency = 1
	statusIcon.Image = achievementData.Completed and "rbxassetid://10748332233" or "rbxassetid://10748331644" -- Placeholder IDs for checkmark/lock
	statusIcon.ImageColor3 = achievementData.Completed and Color3.fromRGB(0, 255, 127) or Color3.fromRGB(150, 150, 150)
	statusIcon.Parent = card

	-- Text Info (Name, Desc, Reward)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -70, 0, 22)
	nameLabel.Position = UDim2.new(0, 65, 0, 5)
	nameLabel.Text = achievementData.Name
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextSize = 18
	nameLabel.BackgroundTransparency = 1
	nameLabel.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(1, -70, 0, 18)
	descLabel.Position = UDim2.new(0, 65, 0, 28)
	descLabel.Text = achievementData.Desc
	descLabel.Font = Enum.Font.SourceSans
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextSize = 14
	descLabel.BackgroundTransparency = 1
	descLabel.Parent = card

	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Name = "Reward"
	rewardLabel.Size = UDim2.new(0, 100, 0, 20)
	rewardLabel.Position = UDim2.new(1, -110, 0, 5)
	rewardLabel.Text = "AP: " .. tostring(achievementData.APReward)
	rewardLabel.Font = Enum.Font.SourceSansBold
	rewardLabel.TextColor3 = Color3.fromRGB(255, 190, 0)
	rewardLabel.TextXAlignment = Enum.TextXAlignment.Right
	rewardLabel.TextSize = 16
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Parent = card

	-- Progress Bar
	local progressBarBg = Instance.new("Frame")
	progressBarBg.Name = "ProgressBar"
	progressBarBg.Size = UDim2.new(1, -70, 0, 15)
	progressBarBg.Position = UDim2.new(0, 65, 1, -25)
	progressBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	progressBarBg.BorderSizePixel = 0
	local barBgCorner = Instance.new("UICorner")
	barBgCorner.CornerRadius = UDim.new(1, 0)
	barBgCorner.Parent = progressBarBg
	progressBarBg.Parent = card

	local progress = achievementData.Target > 0 and math.min(achievementData.Progress / achievementData.Target, 1) or 1
	local progressBarFill = Instance.new("Frame")
	progressBarFill.Size = UDim2.new(progress, 0, 1, 0)
	progressBarFill.BackgroundColor3 = achievementData.Completed and Color3.fromRGB(0, 255, 127) or Color3.fromRGB(0, 170, 255)
	progressBarFill.BorderSizePixel = 0
	local barFillCorner = Instance.new("UICorner")
	barFillCorner.CornerRadius = UDim.new(1, 0)
	barFillCorner.Parent = progressBarFill
	progressBarFill.Parent = progressBarBg

	local progressText = Instance.new("TextLabel")
	progressText.Size = UDim2.new(1, 0, 1, 0)
	progressText.Text = string.format("%d / %d", achievementData.Progress, achievementData.Target)
	progressText.Font = Enum.Font.SourceSansSemibold
	progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
	progressText.TextSize = 12
	progressText.BackgroundTransparency = 1
	progressText.Parent = progressBarBg

	return card
end

-- LOGIC IMPLEMENTATION
local getAchievements = ReplicatedStorage:WaitForChild("GetAchievementsFunc")
local achievementEvent = ReplicatedStorage:WaitForChild("AchievementUnlocked")
local allAchievementsData = {}
local categorizedAchievements = {}
local currentCategoryButton = nil
local currentCategoryName = "Semua"

local function populateAchievements(searchQuery)
	searchQuery = searchQuery and searchQuery:lower() or ""
	-- Clear previous achievements
	for _, child in ipairs(achievementsFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local achievementsToShow = {}
	if currentCategoryName == "Semua" then
		achievementsToShow = allAchievementsData
	else
		achievementsToShow = categorizedAchievements[currentCategoryName] or {}
	end

	-- Filter based on search query
	local filteredAchievements = {}
	if searchQuery ~= "" then
		for _, ach in ipairs(achievementsToShow) do
			if ach.Name:lower():find(searchQuery) then
				table.insert(filteredAchievements, ach)
			end
		end
	else
		filteredAchievements = achievementsToShow
	end

	-- Sort: Uncompleted first, then by progress percentage (desc), then by name
	table.sort(filteredAchievements, function(a, b)
		if a.Completed ~= b.Completed then
			return not a.Completed -- false (uncompleted) comes before true (completed)
		end
		if not a.Completed then -- Both are uncompleted, sort by progress
			local progressA = a.Target > 0 and a.Progress / a.Target or 0
			local progressB = b.Target > 0 and b.Progress / b.Target or 0
			if progressA ~= progressB then
				return progressA > progressB -- Higher progress first
			end
		end
		-- If progress is the same or both are completed, sort by name
		return a.Name < b.Name
	end)

	for _, achievementData in ipairs(filteredAchievements) do
		local card = createAchievementCard(achievementData)
		card.Parent = achievementsFrame
	end
end

local function createCategoryButton(categoryName)
	local button = Instance.new("TextButton")
	button.Name = categoryName
	button.Size = UDim2.new(1, -10, 0, 40)
	button.Position = UDim2.new(0, 5, 0, 0)
	button.Text = categoryName
	button.Font = Enum.Font.SourceSansBold
	button.TextSize = 18
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.LayoutOrder = categoryName == "Semua" and 0 or 1 -- "Semua" always first
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = button
	button.Parent = categoriesFrame

	button.MouseButton1Click:Connect(function()
		if currentCategoryButton then
			currentCategoryButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- Deselect old
		end
		button.BackgroundColor3 = Color3.fromRGB(0, 170, 255) -- Select new
		currentCategoryButton = button
		currentCategoryName = categoryName
		populateAchievements(searchBox.Text)
	end)

	return button
end

initialize = function()
	allAchievementsData = getAchievements:InvokeServer()

	-- Clear old buttons
	for _, child in ipairs(categoriesFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	-- Group achievements by category
	categorizedAchievements = {}
	for _, data in ipairs(allAchievementsData) do
		local category = data.Category or "Lainnya"
		if not categorizedAchievements[category] then
			categorizedAchievements[category] = {}
		end
		table.insert(categorizedAchievements[category], data)
	end

	-- Create "All" button first
	local allButton = createCategoryButton("Semua")

	-- Create other category buttons
	local categoryNames = {}
	for name, _ in pairs(categorizedAchievements) do
		table.insert(categoryNames, name)
	end
	table.sort(categoryNames)

	for _, categoryName in ipairs(categoryNames) do
		createCategoryButton(categoryName)
	end

	-- Auto-select the "All" button
	allButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	currentCategoryButton = allButton
	currentCategoryName = "Semua"
	populateAchievements(searchBox.Text)
end

local function showNotification(message)
	local notificationFrame = Instance.new("Frame")
	notificationFrame.Name = "AchievementNotification"
	notificationFrame.Size = UDim2.new(0, 350, 0, 60)
	notificationFrame.Position = UDim2.new(0.5, -175, -0.1, 0)
	notificationFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	notificationFrame.BorderSizePixel = 0
	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 8)
	notifCorner.Parent = notificationFrame
	notificationFrame.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 20)
	title.Text = "ACHIEVEMENT UNLOCKED"
	title.Font = Enum.Font.SourceSansBold
	title.TextColor3 = Color3.fromRGB(0, 255, 127)
	title.TextSize = 16
	title.BackgroundTransparency = 1
	title.Parent = notificationFrame

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, -10, 1, -25)
	messageLabel.Position = UDim2.new(0, 5, 0, 25)
	messageLabel.Text = message
	messageLabel.Font = Enum.Font.SourceSans
	messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	messageLabel.TextSize = 14
	messageLabel.BackgroundTransparency = 1
	messageLabel.TextWrapped = true
	messageLabel.Parent = notificationFrame

	-- Animate In
	notificationFrame:TweenPosition(UDim2.new(0.5, -175, 0.05, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.5, true)
	task.wait(4)
	-- Animate Out
	notificationFrame:TweenPosition(UDim2.new(0.5, -175, -0.1, 0), Enum.EasingDirection.In, Enum.EasingStyle.Back, 0.5, true, function()
		notificationFrame:Destroy()
	end)
end

local function onAchievementUnlocked(achievement)
	local message = string.format("'%s' (+%d AP)", achievement.Name, achievement.APReward)
	showNotification(message)

	-- Refresh data and UI if the window is open
	if mainFrame.Visible then
		initialize()
	end
end

-- Connect open/close logic
-- Dengarkan event dari ProfileUI
local bindableEvents = ReplicatedStorage:WaitForChild("BindableEvents")
local toggleAchievementUIEvent = bindableEvents:WaitForChild("ToggleAchievementUIEvent")

toggleAchievementUIEvent.Event:Connect(function(visible)
	toggleUI(visible)
end)

searchBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		populateAchievements(searchBox.Text)
	end
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	populateAchievements(searchBox.Text)
end)

achievementEvent.OnClientEvent:Connect(onAchievementUnlocked)
