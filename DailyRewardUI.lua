-- DailyRewardUI.lua (LocalScript)
-- Path: StarterGui/DailyRewardUI.client.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hapus UI lama jika ada untuk pembaruan
if playerGui:FindFirstChild("DailyRewardUI") then
	playerGui.DailyRewardUI:Destroy()
end
if playerGui:FindFirstChild("DailyRewardButton") then
	playerGui.DailyRewardButton:Destroy()
end


-- ======================================================
-- BAGIAN 1: PEMBUATAN UI SECARA TERPROGRAM
-- ======================================================

-- Frame Hadiah Utama (Awalnya Tidak Terlihat)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DailyRewardUI"
screenGui.Enabled = false
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainCanvas = Instance.new("CanvasGroup")
mainCanvas.Name = "MainCanvas"
mainCanvas.Size = UDim2.new(0.6, 0, 0.7, 0)
mainCanvas.AnchorPoint = Vector2.new(0.5, 0.5)
mainCanvas.Position = UDim2.new(0.5, 0, 0.5, 0)
mainCanvas.BackgroundTransparency = 1
mainCanvas.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(1, 0, 1, 0) -- Isi penuh canvas
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 48, 59)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = mainCanvas
local mainFrameCorner = Instance.new("UICorner")
mainFrameCorner.CornerRadius = UDim.new(0, 12)
mainFrameCorner.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(1, 0, 0.1, 0)
titleText.Text = "Daily Rewards"
titleText.Font = Enum.Font.SourceSansBold
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 24
titleText.BackgroundColor3 = Color3.fromRGB(35, 38, 48) -- Warna header
titleText.Parent = mainFrame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleText

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -10, 0.5, 0)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 20
closeButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Merah modern
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.BorderSizePixel = 0
closeButton.Parent = titleText
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local gridContainer = Instance.new("Frame")
gridContainer.Name = "GridContainer"
gridContainer.Size = UDim2.new(0.95, 0, 0.75, 0)
gridContainer.Position = UDim2.new(0.5, 0, 0.52, 0)
gridContainer.AnchorPoint = Vector2.new(0.5, 0.5)
gridContainer.BackgroundTransparency = 1
gridContainer.Parent = mainFrame

local rewardsGrid = Instance.new("UIGridLayout")
rewardsGrid.Name = "RewardsGrid"
rewardsGrid.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
rewardsGrid.CellSize = UDim2.new(0.12, 0, 0.2, 0)
rewardsGrid.StartCorner = Enum.StartCorner.TopLeft
rewardsGrid.SortOrder = Enum.SortOrder.LayoutOrder
rewardsGrid.Parent = gridContainer

local dayTemplate = Instance.new("Frame")
dayTemplate.Name = "DayTemplate"
dayTemplate.Visible = false
dayTemplate.BackgroundColor3 = Color3.fromRGB(60, 64, 78) -- Warna baru
dayTemplate.BorderSizePixel = 0
dayTemplate.Parent = gridContainer -- Store template here, it's invisible
local dayCorner = Instance.new("UICorner")
dayCorner.CornerRadius = UDim.new(0, 8)
dayCorner.Parent = dayTemplate

local dayNumber = Instance.new("TextLabel")
dayNumber.Name = "DayNumber"
dayNumber.Size = UDim2.new(1, 0, 0.3, 0)
dayNumber.Text = "1"
dayNumber.Font = Enum.Font.SourceSansBold
dayNumber.TextColor3 = Color3.fromRGB(220, 220, 220)
dayNumber.BackgroundColor3 = Color3.fromRGB(75, 79, 94) -- Warna baru
dayNumber.TextSize = 18
dayNumber.Parent = dayTemplate
local dayNumberCorner = Instance.new("UICorner")
dayNumberCorner.Parent = dayNumber

local icon = Instance.new("ImageLabel")
icon.Name = "Icon"
icon.Size = UDim2.new(0.6, 0, 0.6, 0)
icon.AnchorPoint = Vector2.new(0.5, 0.5)
icon.Position = UDim2.new(0.5, 0, 0.5, 0) -- Posisikan di tengah
icon.BackgroundTransparency = 1
icon.Parent = dayTemplate

local rewardText = Instance.new("TextLabel")
rewardText.Name = "RewardText"
rewardText.Size = UDim2.new(1, 0, 0.4, 0)
rewardText.AnchorPoint = Vector2.new(0.5, 1)
rewardText.Position = UDim2.new(0.5, 0, 1, -5)
rewardText.Font = Enum.Font.SourceSans
rewardText.Text = "250 Coins"
rewardText.TextColor3 = Color3.fromRGB(200, 200, 200)
rewardText.TextSize = 14
rewardText.BackgroundTransparency = 1
rewardText.Parent = dayTemplate

local claimableHighlight = Instance.new("UIStroke")
claimableHighlight.Name = "ClaimableHighlight"
claimableHighlight.Color = Color3.fromRGB(255, 215, 0) -- Warna emas
claimableHighlight.Thickness = 2
claimableHighlight.Enabled = false
claimableHighlight.Parent = dayTemplate

local statusOverlay = Instance.new("ImageLabel")
statusOverlay.Name = "StatusOverlay"
statusOverlay.Visible = false
statusOverlay.Size = UDim2.new(1, 0, 1, 0)
statusOverlay.BackgroundTransparency = 0.5
statusOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusOverlay.Image = "rbxassetid://3926307971" -- Ikon centang Roblox
statusOverlay.ImageColor3 = Color3.fromRGB(46, 204, 113) -- Hijau modern
statusOverlay.Parent = dayTemplate
local statusCorner = Instance.new("UICorner")
statusCorner.Parent = statusOverlay

local claimButton = Instance.new("TextButton")
claimButton.Name = "ClaimButton"
claimButton.Size = UDim2.new(0.8, 0, 0.12, 0)
claimButton.AnchorPoint = Vector2.new(0.5, 1)
claimButton.Position = UDim2.new(0.5, 0, 1, -10)
claimButton.Text = "CLAIM"
claimButton.Font = Enum.Font.SourceSansBold
claimButton.TextSize = 22
claimButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Hijau modern
claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
claimButton.BorderSizePixel = 0
claimButton.Parent = mainFrame
local claimCorner = Instance.new("UICorner")
claimCorner.CornerRadius = UDim.new(0, 8)
claimCorner.Parent = claimButton

-- Tombol Mandiri untuk Membuka UI
local rewardButtonGui = Instance.new("ScreenGui")
rewardButtonGui.Name = "DailyRewardButton"
rewardButtonGui.ResetOnSpawn = false
rewardButtonGui.Parent = playerGui

local openButton = Instance.new("TextButton")
openButton.Name = "OpenDailyReward"
openButton.Text = "🎁 Reward"
openButton.AnchorPoint = Vector2.new(0, 0.5)
openButton.Size = UDim2.new(0.15, 0, 0.1, 0)
openButton.Position = UDim2.new(0.01, 0, 0.625, 0)
openButton.Font = Enum.Font.SourceSansBold
openButton.TextSize = 18
openButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219) -- Biru modern
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.BorderSizePixel = 0
openButton.TextScaled = true
openButton.Parent = rewardButtonGui
local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 8)
openCorner.Parent = openButton

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0.15, 0)
padding.PaddingLeft = UDim.new(0.15, 0)
padding.PaddingBottom = UDim.new(0.15, 0)
padding.PaddingRight = UDim.new(0.15, 0)
padding.Parent = openButton

-- ======================================================
-- BAGIAN 2: LOGIKA UI
-- ======================================================

local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local getRewardInfo = RemoteEventsFolder:WaitForChild("GetDailyRewardInfo")
local claimRewardEvent = RemoteEventsFolder:WaitForChild("ClaimDailyReward")
local showRewardUIEvent = RemoteEventsFolder:WaitForChild("ShowDailyRewardUI")

local rewardConfig = require(ReplicatedStorage.ModuleScript:WaitForChild("DailyRewardConfig"))

local currentDay = 1
local canClaimToday = false

local function getRewardNotificationText(reward)
	if reward.Type == "Coins" then
		return string.format("You received: %d Coins!", reward.Value)
	elseif reward.Type == "Booster" then
		return string.format("You received the %s Booster!", reward.Value)
	elseif reward.Type == "Skin" then
		return "You received a Random Skin!"
	else
		return string.format("You received: %s!", reward.Type)
	end
end

local function updateDayCell(cell, day, status)
	cell.DayNumber.Text = "Day " .. tostring(day)
	local reward = rewardConfig.Rewards[day]
	local rewardLabel = cell.RewardText

	if reward.Type == "Coins" then
		cell.Icon.Image = "rbxassetid://281938327" -- Ikon Koin
		rewardLabel.Text = reward.Value .. " Coins"
	elseif reward.Type == "Booster" then
		cell.Icon.Image = "rbxassetid://512856403" -- Ikon Booster
		rewardLabel.Text = reward.Value
	elseif reward.Type == "Skin" then
		cell.Icon.Image = "rbxassetid://6379326447" -- Ikon Skin
		rewardLabel.Text = "Random Skin"
	elseif reward.Type == "Mystery" then
		cell.Icon.Image = "rbxassetid://497939460" -- Ikon Tanda Tanya
		rewardLabel.Text = "Mystery Reward"
	end

	cell.ClaimableHighlight.Enabled = false
	cell.StatusOverlay.Visible = false

	if status == "Claimed" then
		cell.BackgroundColor3 = Color3.fromRGB(80, 84, 98)
		cell.StatusOverlay.Visible = true
	elseif status == "Claimable" then
		cell.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
		cell.ClaimableHighlight.Enabled = true
	else -- Locked
		cell.BackgroundColor3 = Color3.fromRGB(60, 64, 78)
	end
end

local function populateGrid()
	-- Hapus sel lama dari container
	for _, child in ipairs(gridContainer:GetChildren()) do
		if child:IsA("Frame") and child ~= dayTemplate then
			child:Destroy()
		end
	end

	-- Buat sel baru di dalam container
	for day = 1, #rewardConfig.Rewards do
		local cell = dayTemplate:Clone()
		cell.Name = "Day_" .. day
		cell.Visible = true
		cell.Parent = gridContainer -- Parent ke container, bukan layout
		local status = (day < currentDay and "Claimed") or (day == currentDay and canClaimToday and "Claimable") or "Locked"
		updateDayCell(cell, day, status)
	end
end

local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function animateUI(fadeIn)
	local goal = { GroupTransparency = fadeIn and 0 or 1 }
	local tween = TweenService:Create(mainCanvas, tweenInfo, goal)
	tween:Play()

	if fadeIn then
		screenGui.Enabled = true
	else
		tween.Completed:Wait()
		screenGui.Enabled = false
	end
end

local function openUI()
	local success, result = pcall(function() return getRewardInfo:InvokeServer() end)
	if not success or not result then return end

	currentDay = result.CurrentDay
	canClaimToday = result.CanClaim
	titleText.Text = "Daily Rewards - Day " .. currentDay
	claimButton.Interactable = canClaimToday
	claimButton.Text = canClaimToday and "CLAIM" or "SEE YOU TOMORROW"
	populateGrid()
	animateUI(true)
end

local function playClickAnimation(button)
	local originalSize = button.Size
	local smallerSize = originalSize - UDim2.new(0, 5, 0, 5)
	local sizeTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)

	local shrinkTween = TweenService:Create(button, sizeTweenInfo, {Size = smallerSize})
	local growTween = TweenService:Create(button, sizeTweenInfo, {Size = originalSize})

	shrinkTween:Play()
	shrinkTween.Completed:Wait()
	growTween:Play()
end

claimButton.MouseButton1Click:Connect(function()
	playClickAnimation(claimButton)
	if canClaimToday then
		claimButton.Interactable = false
		local success, result = pcall(function() return claimRewardEvent:InvokeServer() end)
		if success and result and result.Success then
			canClaimToday = false
			currentDay = result.NextDay
			populateGrid()
			local reward = result.ClaimedReward
			local notificationText = getRewardNotificationText(reward)
			StarterGui:SetCore("SendNotification", {Title = "Reward Claimed!", Text = notificationText, Duration = 5})
			task.wait(1)
			animateUI(false)
		else
			claimButton.Interactable = true
		end
	end
end)

closeButton.MouseButton1Click:Connect(function()
	playClickAnimation(closeButton)
	animateUI(false)
end)
openButton.MouseButton1Click:Connect(openUI)
showRewardUIEvent.OnClientEvent:Connect(openUI)

print("Skrip UI Hadiah Harian berhasil dimuat.")
