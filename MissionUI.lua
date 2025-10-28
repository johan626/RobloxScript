-- MissionUI.lua (LocalScript)
-- Path: StarterGui/MissionUI.client.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hapus UI lama jika ada
if playerGui:FindFirstChild("MissionUI") then
	playerGui.MissionUI:Destroy()
end
if playerGui:FindFirstChild("MissionButton") then
	playerGui.MissionButton:Destroy()
end

-- ======================================================
-- PEMBUATAN UI
-- ======================================================

-- ScreenGui Utama
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MissionUI"
screenGui.Enabled = false
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Tombol untuk membuka UI
local buttonGui = Instance.new("ScreenGui")
buttonGui.Name = "MissionButton"
buttonGui.ResetOnSpawn = false
buttonGui.Parent = playerGui

local openButton = Instance.new("TextButton")
openButton.Name = "OpenMission"
openButton.Text = "📜 Misi"
openButton.Size = UDim2.new(0, 120, 0, 40)
openButton.AnchorPoint = Vector2.new(0, 1)
openButton.Position = UDim2.new(0.13, 0, 0.98, 0) -- Di sebelah tombol reward
openButton.Font = Enum.Font.SourceSansBold
openButton.TextSize = 18
openButton.BackgroundColor3 = Color3.fromRGB(243, 156, 18) -- Oranye
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.Parent = buttonGui
local openCorner = Instance.new("UICorner", openButton)
openCorner.CornerRadius = UDim.new(0, 8)

-- Frame Utama
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.5, 0, 0.6, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 48, 59)
mainFrame.Visible = false
mainFrame.Parent = screenGui
local frameCorner = Instance.new("UICorner", mainFrame)
frameCorner.CornerRadius = UDim.new(0, 12)

-- Header
local titleText = Instance.new("TextLabel")
titleText.Name = "Title"
titleText.Size = UDim2.new(1, 0, 0.1, 0)
titleText.Text = "Misi"
titleText.Font = Enum.Font.SourceSansBold
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 24
titleText.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
titleText.Parent = mainFrame
local titleCorner = Instance.new("UICorner", titleText)
titleCorner.CornerRadius = UDim.new(0, 12)

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -10, 0.5, 0)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 20
closeButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Parent = titleText
local closeCorner = Instance.new("UICorner", closeButton)
closeCorner.CornerRadius = UDim.new(0, 8)

-- Tab Buttons
local tabFrame = Instance.new("Frame")
tabFrame.Name = "TabFrame"
tabFrame.Size = UDim2.new(1, 0, 0.1, 0)
tabFrame.Position = UDim2.new(0, 0, 0.1, 0)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = mainFrame

local dailyTab = Instance.new("TextButton")
dailyTab.Name = "DailyTab"
dailyTab.Size = UDim2.new(0.5, 0, 1, 0)
dailyTab.Text = "Harian"
dailyTab.Font = Enum.Font.SourceSansBold
dailyTab.TextSize = 18
dailyTab.BackgroundColor3 = Color3.fromRGB(60, 64, 78)
dailyTab.TextColor3 = Color3.fromRGB(255, 255, 255)
dailyTab.Parent = tabFrame

local weeklyTab = Instance.new("TextButton")
weeklyTab.Name = "WeeklyTab"
weeklyTab.Size = UDim2.new(0.5, 0, 1, 0)
weeklyTab.Position = UDim2.new(0.5, 0, 0, 0)
weeklyTab.Text = "Mingguan"
weeklyTab.Font = Enum.Font.SourceSansBold
weeklyTab.TextSize = 18
weeklyTab.BackgroundColor3 = Color3.fromRGB(45, 48, 59)
weeklyTab.TextColor3 = Color3.fromRGB(200, 200, 200)
weeklyTab.Parent = tabFrame

-- Kontainer Misi
local missionContainer = Instance.new("ScrollingFrame")
missionContainer.Name = "MissionContainer"
missionContainer.Size = UDim2.new(0.95, 0, 0.75, 0)
missionContainer.Position = UDim2.new(0.5, 0, 0.6, 0)
missionContainer.AnchorPoint = Vector2.new(0.5, 0.5)
missionContainer.BackgroundTransparency = 1
missionContainer.BorderSizePixel = 0
missionContainer.Parent = mainFrame
local missionListLayout = Instance.new("UIListLayout", missionContainer)
missionListLayout.Padding = UDim.new(0, 10)
missionListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Template Misi
local missionTemplate = Instance.new("Frame")
missionTemplate.Name = "MissionTemplate"
missionTemplate.Visible = false
missionTemplate.Size = UDim2.new(1, 0, 0, 80)
missionTemplate.BackgroundColor3 = Color3.fromRGB(60, 64, 78)
--Jangan di-parent dulu

local templateCorner = Instance.new("UICorner", missionTemplate)
templateCorner.CornerRadius = UDim.new(0, 8)

local missionDesc = Instance.new("TextLabel", missionTemplate)
missionDesc.Name = "Description"
missionDesc.Size = UDim2.new(0.7, -10, 0.25, 0)
missionDesc.Position = UDim2.new(0, 10, 0.1, 0)
missionDesc.Font = Enum.Font.SourceSans
missionDesc.TextColor3 = Color3.fromRGB(220, 220, 220)
missionDesc.TextSize = 16
missionDesc.TextXAlignment = Enum.TextXAlignment.Left

local missionReward = Instance.new("TextLabel", missionTemplate)
missionReward.Name = "Reward"
missionReward.Size = UDim2.new(0.7, -10, 0.2, 0)
missionReward.Position = UDim2.new(0, 10, 0.35, 0)
missionReward.Font = Enum.Font.SourceSansBold
missionReward.TextColor3 = Color3.fromRGB(255, 193, 7) -- Gold
missionReward.TextSize = 14
missionReward.TextXAlignment = Enum.TextXAlignment.Left

local missionProgressText = Instance.new("TextLabel", missionTemplate)
missionProgressText.Name = "ProgressText"
missionProgressText.Size = UDim2.new(0.7, -10, 0.2, 0)
missionProgressText.Position = UDim2.new(0, 10, 0.55, 0)
missionProgressText.Font = Enum.Font.SourceSansBold
missionProgressText.TextColor3 = Color3.fromRGB(200, 200, 200)
missionProgressText.TextSize = 14
missionProgressText.TextXAlignment = Enum.TextXAlignment.Left

local progressBar = Instance.new("Frame", missionTemplate)
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(0.7, -10, 0.1, 0)
progressBar.Position = UDim2.new(0, 10, 0.75, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
local barCorner = Instance.new("UICorner", progressBar)
barCorner.CornerRadius = UDim.new(0, 4)

local barFill = Instance.new("Frame", progressBar)
barFill.Name = "BarFill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
local fillCorner = Instance.new("UICorner", barFill)
fillCorner.CornerRadius = UDim.new(0, 4)

local claimButtonTemplate = Instance.new("TextButton", missionTemplate)
claimButtonTemplate.Name = "ClaimButton"
claimButtonTemplate.Size = UDim2.new(0.25, -5, 0.4, 0)
claimButtonTemplate.Position = UDim2.new(0.75, 0, 0.05, 0)
claimButtonTemplate.Font = Enum.Font.SourceSansBold
claimButtonTemplate.TextSize = 16
claimButtonTemplate.TextColor3 = Color3.fromRGB(255, 255, 255)
local claimCorner = Instance.new("UICorner", claimButtonTemplate)
claimCorner.CornerRadius = UDim.new(0, 8)


-- Parent setelah semua anak dibuat
missionTemplate.Parent = missionContainer

-- ======================================================
-- LOGIKA UI
-- ======================================================

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local getMissionData = RemoteEvents:WaitForChild("GetMissionData")
local claimMissionReward = RemoteEvents:WaitForChild("ClaimMissionReward")
local missionProgressUpdated = RemoteEvents:WaitForChild("MissionProgressUpdated")
local missionsReset = RemoteEvents:WaitForChild("MissionsReset")

-- Tidak perlu lagi memuat MissionConfig di klien
-- local missionConfig = require(ReplicatedStorage.ModuleScript:WaitForChild("MissionConfig"))
local currentMissionData = nil
local currentTab = "Daily"
local missionContainerConnection = nil -- Untuk mengelola koneksi event

-- Fungsi findMissionConfig dihapus karena tidak diperlukan lagi.

local function updateMissionFrame(frame, missionID, missionInfo)
	-- Semua info sekarang ada di `missionInfo`
	frame.Description.Text = missionInfo.Description
	frame.Reward.Text = string.format("Hadiah: %d MP", missionInfo.Reward.Value)
	frame.ProgressText.Text = string.format("%d / %d", missionInfo.Progress, missionInfo.Target)

	local progressPercent = math.clamp(missionInfo.Progress / missionInfo.Target, 0, 1)
	frame.ProgressBar.BarFill.Size = UDim2.new(progressPercent, 0, 1, 0)

	local claimBtn = frame.ClaimButton
	claimBtn.Name = missionID -- Set name for easy identification
	if missionInfo.Claimed then
		claimBtn.Text = "Diklaim"
		claimBtn.BackgroundColor3 = Color3.fromRGB(80, 84, 98)
		claimBtn.Interactable = false
	elseif missionInfo.Completed then
		claimBtn.Text = "Klaim"
		claimBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		claimBtn.Interactable = true
	else
		claimBtn.Text = "Proses"
		claimBtn.BackgroundColor3 = Color3.fromRGB(52, 73, 94)
		claimBtn.Interactable = false
	end

end

local function populateMissions()
	if not currentMissionData then return end

	-- Hapus hanya frame misi, dan pastikan template tidak ikut terhapus
	for _, child in ipairs(missionContainer:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "MissionTemplate" then
			child:Destroy()
		end
	end

	local missionData = (currentTab == "Daily") and currentMissionData.Daily or currentMissionData.Weekly
	local missionsToShow = missionData.Missions

	for id, missionInfo in pairs(missionsToShow) do
		local frame = missionTemplate:Clone()
		frame.Name = id
		frame.Visible = true
		updateMissionFrame(frame, id, missionInfo)
		frame.Parent = missionContainer
	end
end

local function switchTab(tabName)
    currentTab = tabName
    if tabName == "Daily" then
        dailyTab.BackgroundColor3 = Color3.fromRGB(60, 64, 78)
        dailyTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        weeklyTab.BackgroundColor3 = Color3.fromRGB(45, 48, 59)
        weeklyTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    else
        weeklyTab.BackgroundColor3 = Color3.fromRGB(60, 64, 78)
        weeklyTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        dailyTab.BackgroundColor3 = Color3.fromRGB(45, 48, 59)
        dailyTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    populateMissions()
end

local function handleClaimResponse(frame, missionID, result)
	if result and result.Success then
		local missionData = (currentTab == "Daily") and currentMissionData.Daily or currentMissionData.Weekly
		missionData.Missions[missionID].Claimed = true

		updateMissionFrame(frame, missionID, missionData.Missions[missionID])

		local reward = result.Reward
		local rewardText = string.format("Anda menerima: %d Mission Points!", reward.Value)
		StarterGui:SetCore("SendNotification", {Title = "Hadiah Diklaim!", Text = rewardText, Duration = 5})
	else
		frame.ClaimButton.Interactable = true
		warn("Gagal mengklaim hadiah: ", result and result.Reason or "Tidak ada respons")
	end
end

local function setupConnections()
	if missionContainerConnection then
		missionContainerConnection:Disconnect()
	end

	missionContainerConnection = missionContainer.ChildAdded:Connect(function(child)
		if not child:IsA("Frame") then return end

		local claimButton = child:FindFirstChild("ClaimButton")
		if claimButton then
			claimButton.MouseButton1Click:Connect(function()
				local missionID = child.Name
				claimButton.Interactable = false
				local success, result = pcall(function() return claimMissionReward:InvokeServer(missionID) end)
				if success then
					handleClaimResponse(child, missionID, result)
				else
					claimButton.Interactable = true
					warn("Error saat memanggil claimMissionReward: ", result)
				end
			end)
		end

	end)
end

local function openUI()
    local success, result = pcall(function() return getMissionData:InvokeServer() end)
    if not success or not result then
        warn("Gagal mendapatkan data misi: ", result)
        return
    end

    currentMissionData = result
    screenGui.Enabled = true
    mainFrame.Visible = true
    setupConnections() -- Atur koneksi event saat UI dibuka
    switchTab("Daily") -- Default ke tab harian
end

local function closeUI()
    mainFrame.Visible = false
    screenGui.Enabled = false
    -- Hentikan koneksi event saat UI ditutup untuk mencegah kebocoran memori
    if missionContainerConnection then
        missionContainerConnection:Disconnect()
        missionContainerConnection = nil
    end
end

openButton.MouseButton1Click:Connect(openUI)
closeButton.MouseButton1Click:Connect(closeUI)
dailyTab.MouseButton1Click:Connect(function() switchTab("Daily") end)
weeklyTab.MouseButton1Click:Connect(function() switchTab("Weekly") end)

-- Listener untuk pembaruan progress real-time
missionProgressUpdated.OnClientEvent:Connect(function(updateData)
	-- Hanya update jika UI sedang terlihat
	if not screenGui.Enabled or not mainFrame.Visible or not currentMissionData then
		return
	end

	local missionID = updateData.missionID

	-- Perbarui data lokal
	local missionSet = currentMissionData.Daily[missionID] and currentMissionData.Daily or currentMissionData.Weekly
	if not missionSet or not missionSet[missionID] then return end

	local missionInfo = missionSet[missionID]
	missionInfo.Progress = updateData.newProgress
	missionInfo.Completed = updateData.completed

	-- Cari frame yang sesuai dan perbarui
	for _, frame in ipairs(missionContainer:GetChildren()) do
		if frame.Name == missionID then
			updateMissionFrame(frame, missionID, missionInfo)

			-- Notifikasi jika misi baru saja selesai
			if updateData.justCompleted then
				StarterGui:SetCore("SendNotification", {
					Title = "Misi Selesai!",
					Text = missionInfo.Description,
					Duration = 3
				})
			end
			break
		end
	end
end)

-- Listener untuk reset misi dari server
missionsReset.OnClientEvent:Connect(function()
	-- Tampilkan notifikasi kepada pemain
	StarterGui:SetCore("SendNotification", {
		Title = "Misi Di-reset!",
		Text = "Misi harian/mingguan Anda telah diperbarui.",
		Duration = 5
	})

	-- Jika UI sedang terbuka, muat ulang datanya untuk menampilkan misi baru
	if screenGui.Enabled and mainFrame.Visible then
		openUI()
	end
end)

print("Skrip UI Misi berhasil dimuat.")