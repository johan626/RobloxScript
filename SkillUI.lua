-- SkillUI.lua (LocalScript)
-- Path: StarterGui/SkillUI.lua
-- Script Place: Lobby
-- UI yang Didesain Ulang untuk menjadi Dinamis dan Informatif

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then
	return -- Jangan jalankan skrip jika LocalPlayer tidak ada (misalnya, di sisi server)
end
local playerGui = player:WaitForChild("PlayerGui")

-- Ganti nama skrip ini agar unik dan bisa di-require dengan andal
-- Memuat modul dan remote
local SkillConfig = require(ReplicatedStorage.ModuleScript:WaitForChild("SkillConfig"))
local remoteFolder = ReplicatedStorage:WaitForChild("SkillRemotes")
local upgradeSkillRequestEvent = remoteFolder:WaitForChild("UpgradeSkillRequestEvent")
local upgradeSkillResultEvent = remoteFolder:WaitForChild("UpgradeSkillResultEvent")
local getSkillDataFunc = remoteFolder:WaitForChild("GetSkillDataFunc")
local getResetCostFunc = remoteFolder:WaitForChild("GetResetCostFunc")
local resetSkillsRequestEvent = remoteFolder:WaitForChild("ResetSkillsRequestEvent")
local resetSkillsResultEvent = remoteFolder:WaitForChild("ResetSkillsResultEvent")

-- Remotes untuk Reset Single Skill
local getSingleResetCostFunc = remoteFolder:WaitForChild("GetSingleResetCostFunc")
local resetSingleSkillRequestEvent = remoteFolder:WaitForChild("ResetSingleSkillRequestEvent")
local resetSingleSkillResultEvent = remoteFolder:WaitForChild("ResetSingleSkillResultEvent")

-- UI Elements
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkillUI"
screenGui.Parent = playerGui
screenGui.Enabled = true
screenGui.ResetOnSpawn = false

-- Tombol utama untuk membuka UI
local skillButton = Instance.new("TextButton")
skillButton.Name = "SkillButton"
skillButton.Parent = screenGui
skillButton.Size = UDim2.new(0, 120, 0, 50)
skillButton.Position = UDim2.new(1, -260, 0, 10)
skillButton.Text = "Skills"
skillButton.Font = Enum.Font.SourceSansBold
skillButton.TextSize = 20
skillButton.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
skillButton.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", skillButton).CornerRadius = UDim.new(0, 8)

-- Panel Utama
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 500, 0, 400)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.BorderSizePixel = 2
mainFrame.Visible = false

local titleLabel = Instance.new("TextLabel", mainFrame)
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.Text = "Skills"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 24
titleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

local skillPointsLabel = Instance.new("TextLabel", mainFrame)
skillPointsLabel.Name = "SkillPointsLabel"
skillPointsLabel.Size = UDim2.new(1, -20, 0, 30)
skillPointsLabel.Position = UDim2.new(0, 10, 0, 55)
skillPointsLabel.Font = Enum.Font.SourceSans
skillPointsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
skillPointsLabel.TextSize = 18
skillPointsLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Notifikasi
local notificationLabel = Instance.new("TextLabel", mainFrame)
notificationLabel.Name = "NotificationLabel"
notificationLabel.Size = UDim2.new(1, -20, 0, 30)
notificationLabel.Position = UDim2.new(0, 10, 1, -80)
notificationLabel.Font = Enum.Font.SourceSansItalic
notificationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notificationLabel.TextSize = 16
notificationLabel.TextXAlignment = Enum.TextXAlignment.Center
notificationLabel.Text = ""
notificationLabel.BackgroundTransparency = 1
notificationLabel.Visible = false

local backButton = Instance.new("TextButton", titleLabel)
backButton.Name = "BackButton"
backButton.Size = UDim2.new(0, 80, 0, 30)
backButton.Position = UDim2.new(0, 10, 0.5, -15)
backButton.Text = "‹ Back"
backButton.Font = Enum.Font.SourceSansBold
backButton.TextSize = 18
backButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
backButton.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", backButton).CornerRadius = UDim.new(0, 6)

local closeButton = Instance.new("TextButton", titleLabel)
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0.5, -15)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 16
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(1, 0)

local resetButton = Instance.new("TextButton", mainFrame)
resetButton.Name = "ResetButton"
resetButton.Size = UDim2.new(0, 120, 0, 40)
resetButton.Position = UDim2.new(0.5, -60, 1, -50) -- Centered
resetButton.Text = "Reset Skills"
resetButton.Font = Enum.Font.SourceSansBold
resetButton.TextSize = 20
resetButton.BackgroundColor3 = Color3.fromRGB(220, 120, 0)
resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Confirmation Dialog
local confirmationFrame = Instance.new("Frame", mainFrame)
confirmationFrame.Name = "ConfirmationFrame"
confirmationFrame.Size = UDim2.new(0, 300, 0, 150)
confirmationFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
confirmationFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
confirmationFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
confirmationFrame.BorderSizePixel = 1
confirmationFrame.Visible = false
confirmationFrame.ZIndex = 2

local confirmationLabel = Instance.new("TextLabel", confirmationFrame)
confirmationLabel.Size = UDim2.new(1, -20, 0, 80)
confirmationLabel.Position = UDim2.new(0, 10, 0, 5)
confirmationLabel.Font = Enum.Font.SourceSans
confirmationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmationLabel.TextSize = 18
confirmationLabel.TextWrapped = true
confirmationLabel.ZIndex = 3

local confirmButton = Instance.new("TextButton", confirmationFrame)
confirmButton.Name = "ConfirmButton"
confirmButton.Size = UDim2.new(0, 100, 0, 40)
confirmButton.Position = UDim2.new(0.5, -110, 1, -50)
confirmButton.Text = "Confirm"
confirmButton.Font = Enum.Font.SourceSansBold
confirmButton.TextSize = 18
confirmButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmButton.ZIndex = 3

local cancelButton = Instance.new("TextButton", confirmationFrame)
cancelButton.Name = "CancelButton"
cancelButton.Size = UDim2.new(0, 100, 0, 40)
cancelButton.Position = UDim2.new(0.5, 10, 1, -50)
cancelButton.Text = "Cancel"
cancelButton.Font = Enum.Font.SourceSansBold
cancelButton.TextSize = 18
cancelButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
cancelButton.ZIndex = 3

-- Container untuk skill-skill dinamis
local skillContainer = Instance.new("ScrollingFrame", mainFrame)
skillContainer.Size = UDim2.new(1, -20, 0, mainFrame.AbsoluteSize.Y - 140)
skillContainer.Position = UDim2.new(0, 10, 0, 90)
skillContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
skillContainer.BorderSizePixel = 0
skillContainer.CanvasSize = UDim2.new(0, 0, 0, 0)

local uiListLayout = Instance.new("UIListLayout", skillContainer)
uiListLayout.Padding = UDim.new(0, 10)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Tabel untuk menyimpan referensi ke UI element setiap skill
local skillUIElements = {}
local currentConfirmConnection = nil -- Variabel untuk menyimpan koneksi event konfirmasi

-- Fungsi untuk menampilkan notifikasi
local function showNotification(message, isSuccess)
	notificationLabel.Text = message
	notificationLabel.TextColor3 = isSuccess and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
	notificationLabel.Visible = true

	task.wait(2)

	notificationLabel.Visible = false
end

-- Fungsi untuk mengupdate seluruh UI berdasarkan data terbaru
local function updateUI(skillData)
	skillPointsLabel.Text = "Skill Points: " .. (skillData.SkillPoints or 0)

	for skillName, ui in pairs(skillUIElements) do
		local config = SkillConfig[skillName]
		if config.IsCategorized then
			-- Update UI untuk skill dengan kategori
			for categoryKey, catUI in pairs(ui.Categories) do
				local level = (skillData.Skills[skillName] and skillData.Skills[skillName][categoryKey]) or 0
				catUI.LevelLabel.Text = string.format("%s [Lv %d/%d]", config.Categories[categoryKey], level, config.MaxLevel)
				local canUpgrade = (skillData.SkillPoints > 0) and (level < config.MaxLevel)
				catUI.UpgradeButton.Text = (level >= config.MaxLevel) and "Max" or "Upgrade"
				catUI.UpgradeButton.BackgroundColor3 = canUpgrade and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 100, 100)
				catUI.UpgradeButton.Active = canUpgrade
				catUI.ResetButton.Visible = level > 0
			end
		else
			-- Update UI untuk skill biasa
			local level = (skillData.Skills and skillData.Skills[skillName]) or 0
			ui.LevelLabel.Text = string.format("%s [Lv %d/%d]", config.Name, level, config.MaxLevel)
			local canUpgrade = (skillData.SkillPoints > 0) and (level < config.MaxLevel)
			ui.UpgradeButton.Text = (level >= config.MaxLevel) and "Max" or "Upgrade"
			ui.UpgradeButton.BackgroundColor3 = canUpgrade and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 100, 100)
			ui.UpgradeButton.Active = canUpgrade
			ui.ResetButton.Visible = level > 0
		end
	end
end

-- Fungsi untuk membuat UI dinamis saat pertama kali dibuka
local function createDynamicSkills()
	local layoutOrder = 0
	for skillName, config in pairs(SkillConfig) do
		if config.IsCategorized then
			-- Membuat UI untuk skill dengan kategori
			local categoryCount = 0
			for _ in pairs(config.Categories) do categoryCount = categoryCount + 1 end
			local mainSkillFrame = Instance.new("Frame", skillContainer)
			mainSkillFrame.Name = skillName
			mainSkillFrame.Size = UDim2.new(1, 0, 0, 30 + (categoryCount * 65))
			mainSkillFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			mainSkillFrame.LayoutOrder = layoutOrder
			Instance.new("UIListLayout", mainSkillFrame).Padding = UDim.new(0, 5)

			local mainLabel = Instance.new("TextLabel", mainSkillFrame)
			mainLabel.Size = UDim2.new(1, 0, 0, 25)
			mainLabel.Text = config.Name
			mainLabel.Font = Enum.Font.SourceSansBold
			mainLabel.TextSize = 20
			mainLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

			skillUIElements[skillName] = { Frame = mainSkillFrame, Categories = {} }

			for categoryKey, categoryDisplayName in pairs(config.Categories) do
				local catFrame = Instance.new("Frame", mainSkillFrame)
				catFrame.Name = categoryKey
				catFrame.Size = UDim2.new(1, -10, 0, 60)
				catFrame.Position = UDim2.new(0, 5, 0, 0)
				catFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

				local levelLabel = Instance.new("TextLabel", catFrame)
				levelLabel.Size = UDim2.new(0.65, 0, 1, 0)
				levelLabel.Font = Enum.Font.SourceSans
				levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				levelLabel.TextSize = 18
				levelLabel.TextXAlignment = Enum.TextXAlignment.Left
				levelLabel.Position = UDim2.new(0, 10, 0, 0)

				local upgradeButton = Instance.new("TextButton", catFrame)
				upgradeButton.Size = UDim2.new(0.14, 0, 0.8, 0)
				upgradeButton.Position = UDim2.new(0.68, 0, 0.1, 0)
				upgradeButton.Font = Enum.Font.SourceSansBold
				upgradeButton.TextSize = 16
				upgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)

				local resetButton = Instance.new("TextButton", catFrame)
				resetButton.Size = UDim2.new(0.14, 0, 0.8, 0)
				resetButton.Position = UDim2.new(0.83, 0, 0.1, 0)
				resetButton.Font = Enum.Font.SourceSansBold
				resetButton.TextSize = 16
				resetButton.Text = "Reset"
				resetButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
				resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
				resetButton.Visible = false

				skillUIElements[skillName].Categories[categoryKey] = {
					Frame = catFrame,
					LevelLabel = levelLabel,
					UpgradeButton = upgradeButton,
					ResetButton = resetButton
				}

				local function handleUpgradeClick()
					if not upgradeButton.Active then return end
					upgradeButton.Text = "..."
					upgradeButton.Active = false
					upgradeSkillRequestEvent:FireServer(skillName, categoryKey)
				end

				local function handleResetClick()
					local success, result = pcall(getSingleResetCostFunc.InvokeServer, getSingleResetCostFunc, skillName, categoryKey)
					if success then
						local cost = result or 0
						local level = (getSkillDataFunc:InvokeServer().Skills[skillName][categoryKey] or 0)
						confirmationLabel.Text = string.format("Yakin ingin reset '%s'?\nBiaya: %d Koin\nPoin Skill kembali: %d", categoryDisplayName, cost, level)

						if currentConfirmConnection then
							currentConfirmConnection:Disconnect()
						end

						currentConfirmConnection = confirmButton.MouseButton1Click:Connect(function()
							if not confirmButton.Active then return end
							showNotification("Mereset skill...", true)
							confirmationFrame.Visible = false
							resetSingleSkillRequestEvent:FireServer(skillName, categoryKey)
						end)

						confirmButton.Active = true
						confirmButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
						confirmationFrame.Visible = true
					else
						showNotification("Gagal mendapatkan biaya reset.", false)
					end
				end

				upgradeButton.MouseButton1Click:Connect(handleUpgradeClick)
				resetButton.MouseButton1Click:Connect(handleResetClick)
			end
		else
			-- Membuat UI untuk skill biasa
			local skillFrame = Instance.new("Frame", skillContainer)
			skillFrame.Name = skillName
			skillFrame.Size = UDim2.new(1, 0, 0, 60)
			skillFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			skillFrame.LayoutOrder = layoutOrder

			local levelLabel = Instance.new("TextLabel", skillFrame)
			levelLabel.Size = UDim2.new(0.65, 0, 1, 0)
			levelLabel.Font = Enum.Font.SourceSans
			levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			levelLabel.TextSize = 18
			levelLabel.TextXAlignment = Enum.TextXAlignment.Left
			levelLabel.Position = UDim2.new(0, 10, 0, 0)

			local upgradeButton = Instance.new("TextButton", skillFrame)
			upgradeButton.Size = UDim2.new(0.14, 0, 0.8, 0)
			upgradeButton.Position = UDim2.new(0.68, 0, 0.1, 0)
			upgradeButton.Font = Enum.Font.SourceSansBold
			upgradeButton.TextSize = 16
			upgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)

			local resetButton = Instance.new("TextButton", skillFrame)
			resetButton.Size = UDim2.new(0.14, 0, 0.8, 0)
			resetButton.Position = UDim2.new(0.83, 0, 0.1, 0)
			resetButton.Font = Enum.Font.SourceSansBold
			resetButton.TextSize = 16
			resetButton.Text = "Reset"
			resetButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
			resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			resetButton.Visible = false -- Sembunyikan secara default

			skillUIElements[skillName] = {
				Frame = skillFrame,
				LevelLabel = levelLabel,
				UpgradeButton = upgradeButton,
				ResetButton = resetButton
			}

			local function handleUpgradeClick()
				if not upgradeButton.Active then return end
				upgradeButton.Text = "..."
				upgradeButton.Active = false
				upgradeSkillRequestEvent:FireServer(skillName)
			end

			local function handleResetClick()
				local success, result = pcall(getSingleResetCostFunc.InvokeServer, getSingleResetCostFunc, skillName, nil)
				if success then
					local cost = result or 0
					local level = (getSkillDataFunc:InvokeServer().Skills[skillName] or 0)
					confirmationLabel.Text = string.format("Yakin ingin reset '%s'?\nBiaya: %d Koin\nPoin Skill kembali: %d", config.Name, cost, level)

					-- Hapus koneksi lama sebelum membuat yang baru
					if currentConfirmConnection then
						currentConfirmConnection:Disconnect()
					end

					currentConfirmConnection = confirmButton.MouseButton1Click:Connect(function()
						if not confirmButton.Active then return end
						showNotification("Mereset skill...", true)
						confirmationFrame.Visible = false
						resetSingleSkillRequestEvent:FireServer(skillName, nil)
					end)

					confirmButton.Active = true
					confirmButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
					confirmationFrame.Visible = true
				else
					showNotification("Gagal mendapatkan biaya reset.", false)
				end
			end

			upgradeButton.MouseButton1Click:Connect(handleUpgradeClick)
			resetButton.MouseButton1Click:Connect(handleResetClick)
		end
		layoutOrder = layoutOrder + 1
	end

	-- Menghitung ulang CanvasSize setelah semua elemen ditambahkan
	local totalHeight = 0
	for _, child in ipairs(skillContainer:GetChildren()) do
		if child:IsA("UIListLayout") then continue end
		totalHeight = totalHeight + child.AbsoluteSize.Y + uiListLayout.Padding.Offset
	end
	skillContainer.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

-- Event Listeners
-- Sembunyikan tombol utama karena akan dipindahkan ke ProfileUI
skillButton.Visible = false

-- Fungsi terpusat untuk menampilkan/menyembunyikan UI dan me-refresh data
local function toggleUI(visible)
	mainFrame.Visible = visible
	if mainFrame.Visible then
		-- Selalu panggil data terbaru saat UI dibuka
		local skillData = getSkillDataFunc:InvokeServer()
		if skillData then
			updateUI(skillData)
		end
	end
end

-- Dengarkan event dari ProfileUI untuk menampilkan UI
local bindableEvents = ReplicatedStorage:WaitForChild("BindableEvents")
local toggleSkillUIEvent = bindableEvents:WaitForChild("ToggleSkillUIEvent")
local toggleProfileUIEvent = bindableEvents:WaitForChild("ToggleProfileUIEvent")

toggleSkillUIEvent.Event:Connect(function(visible)
	toggleUI(visible)
end)

-- Event Listeners
backButton.MouseButton1Click:Connect(function()
	toggleUI(false)
	toggleProfileUIEvent:Fire(true)
end)

closeButton.MouseButton1Click:Connect(function()
	toggleUI(false) -- Hanya tutup UI ini, jangan buka profil
end)

resetButton.MouseButton1Click:Connect(function()
	local success, cost = pcall(getResetCostFunc.InvokeServer, getResetCostFunc)
	if success then
		confirmationLabel.Text = string.format("Apakah Anda yakin ingin mereset semua skill? Ini akan membutuhkan biaya %d koin.", cost)
		confirmButton.Active = true
		confirmButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	else
		confirmationLabel.Text = "Gagal mendapatkan biaya reset. Silakan coba lagi nanti."
		confirmButton.Active = false
		confirmButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	end
	confirmationFrame.Visible = true
end)

cancelButton.MouseButton1Click:Connect(function()
	confirmationFrame.Visible = false
end)

confirmButton.MouseButton1Click:Connect(function()
	if not confirmButton.Active then return end
	showNotification("Mereset skills...", true)
	confirmationFrame.Visible = false
	resetSkillsRequestEvent:FireServer()
end)


-- Event handler untuk hasil upgrade dari server
upgradeSkillResultEvent.OnClientEvent:Connect(function(result)
	if not result or not result.skillName then
		local skillData = getSkillDataFunc:InvokeServer()
		if skillData then updateUI(skillData) end
		return
	end
	showNotification(result.message, result.success)
	if result.newData then
		updateUI(result.newData)
	else
		local skillData = getSkillDataFunc:InvokeServer()
		if skillData then updateUI(skillData) end
	end
end)

resetSkillsResultEvent.OnClientEvent:Connect(function(result)
	if not result then return end
	showNotification(result.message, result.success)
	if result.newData then
		updateUI(result.newData)
	else
		local skillData = getSkillDataFunc:InvokeServer()
		if skillData then updateUI(skillData) end
	end
end)


-- Inisialisasi UI
resetSingleSkillResultEvent.OnClientEvent:Connect(function(result)
	if not result then return end
	showNotification(result.message, result.success)
	if result.newData then
		updateUI(result.newData)
	else
		local skillData = getSkillDataFunc:InvokeServer()
		if skillData then updateUI(skillData) end
	end
end)

createDynamicSkills()
