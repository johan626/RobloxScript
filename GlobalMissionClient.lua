-- GlobalMissionClient.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/GlobalMissionClient.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- Tunggu Part bernama "GlobalMission"
local boardPart = Workspace.Leaderboard:WaitForChild("GlobalMission")

-- ==================================================
-- FUNGSI PEMBUATAN UI
-- ==================================================
local function createMissionUI(parentPart)
	-- Hapus UI lama jika ada untuk mencegah duplikasi
	if parentPart:FindFirstChild("MissionDisplay") then
		parentPart.MissionDisplay:Destroy()
	end

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "MissionDisplay"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = parentPart

	local mainFrame = Instance.new("Frame", surfaceGui)
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
	mainFrame.BorderSizePixel = 0

	local titleLabel = Instance.new("TextLabel", mainFrame)
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
	titleLabel.Text = "MISI KOMUNITAS MINGGUAN"
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 30
	titleLabel.TextColor3 = Color3.fromRGB(255, 193, 7)
	titleLabel.BackgroundColor3 = Color3.fromRGB(25, 28, 38)

	local descriptionLabel = Instance.new("TextLabel", mainFrame)
	descriptionLabel.Name = "Description"
	descriptionLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
	descriptionLabel.Position = UDim2.new(0.05, 0, 0.2, 0)
	descriptionLabel.Text = "Memuat misi..."
	descriptionLabel.Font = Enum.Font.SourceSans
	descriptionLabel.TextSize = 24
	descriptionLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	descriptionLabel.TextWrapped = true

	local progressBg = Instance.new("Frame", mainFrame)
	progressBg.Name = "GlobalProgressBackground"
	progressBg.Size = UDim2.new(0.9, 0, 0.1, 0)
	progressBg.Position = UDim2.new(0.05, 0, 0.35, 0)
	progressBg.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	Instance.new("UICorner", progressBg).CornerRadius = UDim.new(0, 8)

	local progressFill = Instance.new("Frame", progressBg)
	progressFill.Name = "GlobalProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	Instance.new("UICorner", progressFill).CornerRadius = UDim.new(0, 8)

	local progressText = Instance.new("TextLabel", progressBg)
	progressText.Name = "GlobalProgressText"
	progressText.Size = UDim2.new(1, 0, 1, 0)
	progressText.Text = "0 / 1,000,000"
	progressText.Font = Enum.Font.SourceSansBold
	progressText.TextSize = 22
	progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
	progressText.BackgroundTransparency = 1

	local playerContributionLabel = Instance.new("TextLabel", mainFrame)
	playerContributionLabel.Name = "PlayerContribution"
	playerContributionLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
	playerContributionLabel.Position = UDim2.new(0.05, 0, 0.5, 0)
	playerContributionLabel.Text = "Kontribusi Anda: 0"
	playerContributionLabel.Font = Enum.Font.SourceSansBold
	playerContributionLabel.TextSize = 20
	playerContributionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	playerContributionLabel.TextXAlignment = Enum.TextXAlignment.Left

	local countdownLabel = Instance.new("TextLabel", mainFrame)
	countdownLabel.Name = "Countdown"
	countdownLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
	countdownLabel.Position = UDim2.new(0.05, 0, 0.6, 0)
	countdownLabel.Text = "Sisa Waktu: 7h 0m 0d"
	countdownLabel.Font = Enum.Font.SourceSansBold
	countdownLabel.TextSize = 20
	countdownLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
	countdownLabel.TextXAlignment = Enum.TextXAlignment.Left

	local claimButton = Instance.new("TextButton", mainFrame)
	claimButton.Name = "ClaimButton"
	claimButton.Size = UDim2.new(0.4, 0, 0.15, 0)
	claimButton.Position = UDim2.new(0.3, 0, 0.8, 0)
	claimButton.Text = "Klaim Hadiah Minggu Lalu"
	claimButton.Font = Enum.Font.SourceSansBold
	claimButton.TextSize = 24
	claimButton.BackgroundColor3 = Color3.fromRGB(243, 156, 18)
	claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	Instance.new("UICorner", claimButton).CornerRadius = UDim.new(0, 8)

	return {
		descriptionLabel = descriptionLabel,
		progressFill = progressFill,
		progressText = progressText,
		playerContributionLabel = playerContributionLabel,
		countdownLabel = countdownLabel,
		claimButton = claimButton
	}
end

local function createLeaderboardUI(parentPart)
	if parentPart:FindFirstChild("LeaderboardDisplay") then
		parentPart.LeaderboardDisplay:Destroy()
	end

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "LeaderboardDisplay"
	surfaceGui.Face = Enum.NormalId.Back
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = parentPart

	local mainFrame = Instance.new("Frame", surfaceGui)
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
	mainFrame.BorderSizePixel = 0

	local titleLabel = Instance.new("TextLabel", mainFrame)
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
	titleLabel.Text = "KONTRIBUTOR TERATAS"
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 30
	titleLabel.TextColor3 = Color3.fromRGB(255, 193, 7)
	titleLabel.BackgroundColor3 = Color3.fromRGB(25, 28, 38)

	local listLayout = Instance.new("UIListLayout", mainFrame)
	listLayout.Padding = UDim.new(0, 5)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local entryLabels = {}
	for i = 1, 10 do
		local entryFrame = Instance.new("Frame", mainFrame)
		entryFrame.Name = "Entry" .. i
		entryFrame.Size = UDim2.new(0.9, 0, 0.07, 0)
		entryFrame.BackgroundColor3 = Color3.fromRGB(45, 48, 58)
		entryFrame.LayoutOrder = i
		entryFrame.Parent = mainFrame

		local rankLabel = Instance.new("TextLabel", entryFrame)
		rankLabel.Name = "Rank"
		rankLabel.Size = UDim2.new(0.15, 0, 1, 0)
		rankLabel.Text = "#" .. i
		rankLabel.Font = Enum.Font.SourceSansBold
		rankLabel.TextSize = 20
		rankLabel.TextColor3 = Color3.fromRGB(255, 193, 7)

		local nameLabel = Instance.new("TextLabel", entryFrame)
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
		nameLabel.Position = UDim2.new(0.15, 0, 0, 0)
		nameLabel.Text = "Memuat..."
		nameLabel.Font = Enum.Font.SourceSans
		nameLabel.TextSize = 18
		nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left

		local contributionLabel = Instance.new("TextLabel", entryFrame)
		contributionLabel.Name = "Contribution"
		contributionLabel.Size = UDim2.new(0.3, 0, 1, 0)
		contributionLabel.Position = UDim2.new(0.7, 0, 0, 0)
		contributionLabel.Text = "0"
		contributionLabel.Font = Enum.Font.SourceSansBold
		contributionLabel.TextSize = 18
		contributionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		contributionLabel.TextXAlignment = Enum.TextXAlignment.Right

		table.insert(entryLabels, {
			Frame = entryFrame,
			Rank = rankLabel,
			Name = nameLabel,
			Contribution = contributionLabel
		})
	end

	local playerRankLabel = Instance.new("TextLabel", mainFrame)
	playerRankLabel.Name = "PlayerRankLabel"
	playerRankLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
	playerRankLabel.Position = UDim2.new(0.05, 0, 0.88, 0)
	playerRankLabel.Text = "Peringkat Anda: Memuat..."
	playerRankLabel.Font = Enum.Font.SourceSansBold
	playerRankLabel.TextSize = 22
	playerRankLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
	playerRankLabel.TextXAlignment = Enum.TextXAlignment.Center
	playerRankLabel.BackgroundTransparency = 1

	return { entryLabels = entryLabels, playerRankLabel = playerRankLabel }
end

-- ==================================================
-- LOGIKA UTAMA
-- ==================================================
local uiElements = createMissionUI(boardPart)
local leaderboardUIElements = createLeaderboardUI(boardPart)

-- Referensi ke RemoteFunctions
local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local getGlobalMissionState = remoteFunctions:WaitForChild("GetGlobalMissionState")
local claimGlobalMissionReward = remoteFunctions:WaitForChild("ClaimGlobalMissionReward")
local getGlobalMissionLeaderboard = remoteFunctions:WaitForChild("GetGlobalMissionLeaderboard")
local getPlayerGlobalMissionRank = remoteFunctions:WaitForChild("GetPlayerGlobalMissionRank")

local MISSION_UPDATE_INTERVAL = 60 -- Setiap 1 menit
local LEADERBOARD_UPDATE_INTERVAL = 300 -- Setiap 5 menit

local function formatTime(seconds)
	if seconds < 0 then seconds = 0 end
	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	return string.format("Sisa Waktu: %d hari, %d jam, %d menit", days, hours, minutes)
end

local function formatNumber(num)
	local formatted = tostring(math.floor(num))
	while true do local k; formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2'); if k == 0 then break end end
	return formatted
end

local function updateUI()
	local success, missionState = pcall(function() return getGlobalMissionState:InvokeServer() end)
	if not success or not missionState then
		warn("[GlobalMissionClient] Gagal mendapatkan state misi.")
		uiElements.descriptionLabel.Text = "Gagal memuat data misi. Mencoba lagi..."
		return
	end

	uiElements.descriptionLabel.Text = missionState.Description

	local playerContribution = missionState.PlayerContribution
	local rewardTiers = missionState.RewardTiers
	local currentRewardText = "Tidak ada hadiah"
	local nextRewardText = "Tidak ada target berikutnya"

	-- Cari hadiah saat ini dan berikutnya (dengan asumsi rewardTiers diurutkan dari kecil ke besar)
	if rewardTiers and #rewardTiers > 0 then
		local currentTier = nil
		local nextTier = rewardTiers[1] -- Asumsikan target berikutnya adalah tier pertama

		for i = 1, #rewardTiers do
			if playerContribution >= rewardTiers[i].Contribution then
				currentTier = rewardTiers[i]
				-- Cek apakah ada tier berikutnya
				if i < #rewardTiers then
					nextTier = rewardTiers[i+1]
				else
					nextTier = nil -- Sudah mencapai tier maksimum
				end
			else
				-- Karena sudah diurutkan, tier pertama yang tidak tercapai adalah target berikutnya
				nextTier = rewardTiers[i]
				break
			end
		end

		if currentTier then
			currentRewardText = string.format("%s %s", formatNumber(currentTier.Reward.Value), currentTier.Reward.Type)
		end
		if nextTier then
			nextRewardText = string.format("Capai %s untuk %s %s", formatNumber(nextTier.Contribution), formatNumber(nextTier.Reward.Value), nextTier.Reward.Type)
		end
	end

	uiElements.playerContributionLabel.Text = string.format("Kontribusi Anda: %s\nHadiah Saat Ini: %s\nTarget Berikutnya: %s", formatNumber(playerContribution), currentRewardText, nextRewardText)
	uiElements.playerContributionLabel.TextYAlignment = Enum.TextYAlignment.Top
	uiElements.playerContributionLabel.Size = UDim2.new(0.9, 0, 0.25, 0) -- Perbesar ukuran untuk 3 baris

	local progressPercent = math.clamp(missionState.GlobalProgress / missionState.GlobalTarget, 0, 1)
	uiElements.progressFill.Size = UDim2.new(progressPercent, 0, 1, 0)
	uiElements.progressText.Text = string.format("%s / %s", formatNumber(missionState.GlobalProgress), formatNumber(missionState.GlobalTarget))

	local remainingTime = missionState.EndTime - os.time()
	uiElements.countdownLabel.Text = formatTime(remainingTime)
end

uiElements.claimButton.MouseButton1Click:Connect(function()
	uiElements.claimButton.Text = "Memproses..."
	uiElements.claimButton.Interactable = false
	local success, result = pcall(function() return claimGlobalMissionReward:InvokeServer() end)

	if not success then
		StarterGui:SetCore("SendNotification", { Title = "Error", Text = "Terjadi kesalahan. Coba lagi." })
	elseif result.Success then
		StarterGui:SetCore("SendNotification", { Title = "Hadiah Diklaim!", Text = string.format("Anda menerima %d %s!", result.Reward.Value, result.Reward.Type) })
		uiElements.claimButton.Text = "Sudah Diklaim"
	else
		StarterGui:SetCore("SendNotification", { Title = "Gagal Klaim", Text = result.Reason or "Tidak ada hadiah." })
		uiElements.claimButton.Text = "Klaim Hadiah Minggu Lalu"
		uiElements.claimButton.Interactable = true
	end
end)

local function updateLeaderboardUI()
	local success, leaderboardData = pcall(function() return getGlobalMissionLeaderboard:InvokeServer() end)
	if not success or not leaderboardData then
		warn("[GlobalMissionClient] Gagal mendapatkan data leaderboard.")
		return
	end

	for i = 1, 10 do
		local entryUI = leaderboardUIElements.entryLabels[i]
		local data = leaderboardData[i]

		if data then
			entryUI.Name.Text = data.Name
			entryUI.Contribution.Text = formatNumber(data.Contribution)
			entryUI.Frame.Visible = true
		else
			entryUI.Frame.Visible = false
		end
	end

	-- Update peringkat pemain
	local successRank, rank = pcall(function() return getPlayerGlobalMissionRank:InvokeServer() end)
	if successRank and rank then
		leaderboardUIElements.playerRankLabel.Text = string.format("Peringkat Anda: #%s", tostring(rank))
	else
		leaderboardUIElements.playerRankLabel.Text = "Peringkat Anda: Error"
	end
end

-- Inisialisasi awal
task.wait(2)
updateUI()
updateLeaderboardUI()

-- Loop pembaruan terpisah
coroutine.wrap(function()
	while true do
		task.wait(MISSION_UPDATE_INTERVAL)
		updateUI()
	end
end)()

coroutine.wrap(function()
	while true do
		task.wait(LEADERBOARD_UPDATE_INTERVAL)
		updateLeaderboardUI()
	end
end)()
