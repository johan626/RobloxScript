-- AdminUI.lua (LocalScript)
-- Path: StarterGui/AdminUI.lua
-- Script Place: Lobby

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Player and Admin Check
local player = Players.LocalPlayer
local isAdmin = false

-- Fungsi untuk membuat UI
local function CreateAdminUI()
	-- Definisi struktur kategori untuk UI
	local categoryStructure = {
		Stats = {
			["Informasi Pemain"] = {"Level", "XP", "SkillPoints"},
			["Catatan Pertarungan"] = {"TotalKills", "TotalKnocks", "TotalRevives"},
			["Ekonomi"] = {"TotalCoins"},
		},
		Inventory = {
			["Ekonomi & Gacha"] = {"Coins", "PityCount"},
			["Boosters"] = {"Owned", "Active"},
			["Kosmetik"] = {"Skins"},
		}
	}

	-- Hapus UI lama jika ada
	local oldGui = player.PlayerGui:FindFirstChild("AdminPanelGui")
	if oldGui then oldGui:Destroy() end

	-- Remote Events/Functions
	local adminEventsFolder = ReplicatedStorage:WaitForChild("AdminEvents")
	local requestDataFunc = adminEventsFolder:WaitForChild("AdminRequestData")
	local updateDataEvent = adminEventsFolder:WaitForChild("AdminUpdateData")
	local deleteDataEvent = adminEventsFolder:WaitForChild("AdminDeleteData")

	-- State untuk data dan konfirmasi
	local currentData = nil
	local pendingAction, pendingTargetId, pendingData = nil, nil, nil

	-- UI Creation
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdminPanelGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- Main Frame
	local mainFrame = Instance.new("Frame") -- Mengubah dari ScrollingFrame ke Frame biasa
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 450, 0, 560) -- Ukuran diperbesar sedikit
	mainFrame.Position = UDim2.new(0.5, -225, 0.5, -280)
	mainFrame.BackgroundColor3 = Color3.fromRGB(35, 37, 40)
	mainFrame.BorderColor3 = Color3.fromRGB(20, 20, 20)
	mainFrame.ClipsDescendants = true
	mainFrame.BorderSizePixel = 2
	mainFrame.Visible = false
	mainFrame.Draggable = true
	mainFrame.Active = true
	mainFrame.ZIndex = 1
	mainFrame.Parent = screenGui
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

	local mainLayout = Instance.new("UIListLayout")
	mainLayout.Padding = UDim.new(0, 10)
	mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	mainLayout.Parent = mainFrame

	local mainPadding = Instance.new("UIPadding")
	mainPadding.PaddingTop = UDim.new(0, 10)
	mainPadding.PaddingBottom = UDim.new(0, 10)
	mainPadding.PaddingLeft = UDim.new(0, 10)
	mainPadding.PaddingRight = UDim.new(0, 10)
	mainPadding.Parent = mainFrame

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Text = "Admin Panel"
	titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 20
	titleLabel.LayoutOrder = 1
	titleLabel.Parent = mainFrame

	-- User Input Section
	local userInputFrame = Instance.new("Frame")
	userInputFrame.Name = "UserInputFrame"
	userInputFrame.Size = UDim2.new(1, 0, 0, 35)
	userInputFrame.BackgroundTransparency = 1
	userInputFrame.LayoutOrder = 2
	userInputFrame.Parent = mainFrame
	local userInputLayout = Instance.new("UIListLayout")
	userInputLayout.FillDirection = Enum.FillDirection.Horizontal
	userInputLayout.Padding = UDim.new(0, 10)
	userInputLayout.Parent = userInputFrame

	local userIdBox = Instance.new("TextBox")
	userIdBox.Name = "UserIdBox"
	userIdBox.Size = UDim2.new(1, -110, 1, 0)
	userIdBox.PlaceholderText = "Masukkan UserID Target..."
	userIdBox.BackgroundColor3 = Color3.fromRGB(25, 27, 30)
	userIdBox.TextColor3 = Color3.new(1, 1, 1)
	userIdBox.Parent = userInputFrame
	Instance.new("UICorner", userIdBox).CornerRadius = UDim.new(0, 6)

	local getDataButton = Instance.new("TextButton")
	getDataButton.Name = "GetDataButton"
	getDataButton.Text = "Get Data"
	getDataButton.Size = UDim2.new(0, 100, 1, 0)
	getDataButton.BackgroundColor3 = Color3.fromRGB(60, 80, 140) -- Warna diubah
	getDataButton.TextColor3 = Color3.new(1, 1, 1)
	getDataButton.Font = Enum.Font.SourceSansBold
	getDataButton.Parent = userInputFrame
	Instance.new("UICorner", getDataButton).CornerRadius = UDim.new(0, 6)

	-- Tab Navigation
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(1, 0, 0, 30)
	tabContainer.BackgroundTransparency = 1
	tabContainer.LayoutOrder = 3
	tabContainer.Parent = mainFrame
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.Parent = tabContainer

	-- Content Container
	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(1, 0, 1, -235) -- Adjust size to fit in mainFrame
	contentContainer.BackgroundTransparency = 1
	contentContainer.LayoutOrder = 4
	contentContainer.Parent = mainFrame
	local pageLayout = Instance.new("UIPageLayout")
	pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pageLayout.Parent = contentContainer

	-- Tab Content Pages
	local statsPage = Instance.new("ScrollingFrame")
	statsPage.Name = "StatsPage"
	statsPage.Size = UDim2.new(1, 0, 1, 0)
	statsPage.BackgroundTransparency = 1
	statsPage.LayoutOrder = 1
	statsPage.Parent = contentContainer
	local statsLayout = Instance.new("UIListLayout")
	statsLayout.Padding = UDim.new(0, 5)
	statsLayout.Parent = statsPage
	local statsPadding = Instance.new("UIPadding", statsPage)
	statsPadding.PaddingLeft = UDim.new(0, 10)
	statsPadding.PaddingRight = UDim.new(0, 10)


	local inventoryPage = Instance.new("ScrollingFrame")
	inventoryPage.Name = "InventoryPage"
	inventoryPage.Size = UDim2.new(1, 0, 1, 0)
	inventoryPage.BackgroundTransparency = 1
	inventoryPage.LayoutOrder = 2
	inventoryPage.Parent = contentContainer
	local inventoryLayout = Instance.new("UIListLayout")
	inventoryLayout.Padding = UDim.new(0, 5)
	inventoryLayout.Parent = inventoryPage
	local inventoryPadding = Instance.new("UIPadding", inventoryPage)
	inventoryPadding.PaddingLeft = UDim.new(0, 10)
	inventoryPadding.PaddingRight = UDim.new(0, 10)

	-- Tab Button Creation and Logic
	local tabs = {}
	local pages = {
		Stats = statsPage,
		Inventory = inventoryPage,
	}
	local activeTab = nil
	local activeColor = Color3.fromRGB(70, 90, 150)
	local inactiveColor = Color3.fromRGB(55, 55, 55)

	local function switchTab(tabName)
		for name, button in pairs(tabs) do
			button.BackgroundColor3 = (name == tabName) and activeColor or inactiveColor
		end
		pageLayout:JumpTo(pages[tabName])
		activeTab = tabName
	end

	local function createTabButton(name)
		local button = Instance.new("TextButton")
		button.Name = name .. "Tab"
		button.Text = name
		button.Size = UDim2.new(0.5, -2.5, 1, 0)
		button.BackgroundColor3 = inactiveColor
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.SourceSansBold
		button.Parent = tabContainer
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
		button.MouseButton1Click:Connect(function()
			switchTab(name)
		end)
		tabs[name] = button
		return button
	end

	createTabButton("Stats")
	createTabButton("Inventory")
	-- Set initial tab
	switchTab("Stats")

	-- Dynamic Data Container (akan diisi oleh buildDynamicUI)
	-- Ini sekarang menjadi alias untuk halaman konten yang relevan
	local dataContainer = statsPage -- Default

	-- Helper function to create UI for a single field (can be a value, or a nested table)
	local function createFieldUI(parent, key, value, path)
		local currentPath = path .. "/" .. tostring(key)

		-- Fields that should be read-only
		local readOnlyKeys = {"TotalKills", "TotalCoins", "TotalRevives", "TotalKnocks", "Skins"}
		local isReadOnly = table.find(readOnlyKeys, tostring(key)) or false

		if type(value) == "table" then
			-- Logic for non-collapsible, nested tables
			local tableFrame = Instance.new("Frame")
			tableFrame.Name = tostring(key)
			tableFrame.AutomaticSize = Enum.AutomaticSize.Y
			tableFrame.Size = UDim2.new(1, 0, 0, 0)
			tableFrame.BackgroundTransparency = 1
			tableFrame.Parent = parent
			local tableLayout = Instance.new("UIListLayout")
			tableLayout.Padding = UDim.new(0, 5)
			tableLayout.SortOrder = Enum.SortOrder.Name
			tableLayout.Parent = tableFrame
			Instance.new("UIPadding", tableFrame).PaddingLeft = UDim.new(0, 10)

			local title = Instance.new("TextLabel")
			title.Name = "Title"
			title.Size = UDim2.new(1, 0, 0, 20)
			title.Text = tostring(key) .. ":"
			title.Font = Enum.Font.SourceSansBold
			title.TextColor3 = Color3.fromRGB(220, 220, 220)
			title.BackgroundTransparency = 1
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Parent = tableFrame

			local sortedKeys = {}
			for k, _ in pairs(value) do table.insert(sortedKeys, k) end
			table.sort(sortedKeys)

			for _, k in ipairs(sortedKeys) do
				local v = value[k]
				createFieldUI(tableFrame, k, v, currentPath) -- Recursive call for nested items
			end
		else
			-- Create a frame for a single key-value pair
			local itemFrame = Instance.new("Frame")
			itemFrame.Name = tostring(key)
			itemFrame.Size = UDim2.new(1, 0, 0, 30)
			itemFrame.BackgroundTransparency = 1
			itemFrame.Parent = parent

			local layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.VerticalAlignment = Enum.VerticalAlignment.Center
			layout.Padding = UDim.new(0, 10)
			layout.Parent = itemFrame

			-- Label for the key
			local keyLabel = Instance.new("TextLabel")
			keyLabel.Size = UDim2.new(0.4, -5, 1, 0)
			keyLabel.Text = tostring(key)
			keyLabel.Font = Enum.Font.SourceSans
			keyLabel.TextColor3 = Color3.new(1, 1, 1)
			keyLabel.BackgroundTransparency = 1
			keyLabel.TextXAlignment = Enum.TextXAlignment.Left
			keyLabel.Parent = itemFrame

			-- TextBox for the value
			local valueBox = Instance.new("TextBox")
			valueBox.Name = "ValueBox"
			valueBox.Size = UDim2.new(0.6, -5, 1, 0)
			valueBox.Text = tostring(value)
			valueBox.BackgroundColor3 = isReadOnly and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(30, 30, 30)
			valueBox.TextColor3 = isReadOnly and Color3.fromRGB(180, 180, 180) or Color3.new(1, 1, 1)
			valueBox.TextEditable = not isReadOnly
			valueBox.Parent = itemFrame
			Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 6)

			-- Store the path to the data in an attribute for easy reconstruction later
			itemFrame:SetAttribute("DataPath", currentPath)
			itemFrame:SetAttribute("DataType", type(value)) -- Store original type
		end
	end

	-- Dynamic UI Builder Function
	local function buildDynamicUI(parent, dataKey, dataBlock, path)
		local categories = categoryStructure[dataKey]
		if not categories or not dataBlock then return end

		-- Get a consistent order for categories
		local orderedCategoryNames = {}
		for name, _ in pairs(categories) do table.insert(orderedCategoryNames, name) end
		table.sort(orderedCategoryNames) -- Sorting to ensure consistent UI layout

		for _, categoryName in ipairs(orderedCategoryNames) do
			local fields = categories[categoryName]

			-- Create a header for the category
			local categoryHeader = Instance.new("TextLabel")
			categoryHeader.Name = categoryName .. "Header"
			categoryHeader.Size = UDim2.new(1, 0, 0, 25)
			categoryHeader.Text = "  " .. categoryName
			categoryHeader.Font = Enum.Font.SourceSansBold
			categoryHeader.TextSize = 18
			categoryHeader.TextColor3 = Color3.fromRGB(240, 240, 240)
			categoryHeader.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			categoryHeader.TextXAlignment = Enum.TextXAlignment.Left
			categoryHeader.Parent = parent
			Instance.new("UICorner", categoryHeader).CornerRadius = UDim.new(0, 4)

			-- Create a frame to hold the items in this category
			local categoryContent = Instance.new("Frame")
			categoryContent.Name = categoryName .. "Content"
			categoryContent.AutomaticSize = Enum.AutomaticSize.Y
			categoryContent.Size = UDim2.new(1, 0, 0, 0)
			categoryContent.BackgroundTransparency = 1
			categoryContent.Parent = parent
			local contentLayout = Instance.new("UIListLayout")
			contentLayout.Padding = UDim.new(0, 5)
			contentLayout.Parent = categoryContent
			local contentPadding = Instance.new("UIPadding", categoryContent)
			contentPadding.PaddingTop = UDim.new(0, 5)
			contentPadding.PaddingBottom = UDim.new(0, 10) -- More padding at the bottom of a category

			-- Find which fields from the data actually exist for this category
			local foundFields = {}
			for dataFieldName, dataFieldValue in pairs(dataBlock) do
				if table.find(fields, dataFieldName) then
					table.insert(foundFields, {name = dataFieldName, value = dataFieldValue})
				end
			end

			-- Sort fields alphabetically for consistent order
			table.sort(foundFields, function(a, b) return a.name < b.name end)

			-- Create UI for each field found
			for _, fieldData in ipairs(foundFields) do
				local fieldName = fieldData.name
				local fieldValue = fieldData.value
				-- Gunakan dataKey versi lowercase untuk path agar konsisten dengan server
				local fieldPath = path .. "/" .. string.lower(dataKey)
				createFieldUI(categoryContent, fieldName, fieldValue, fieldPath)
			end
		end
	end

	-- Buttons Frame
	local buttonsFrame = Instance.new("Frame")
	buttonsFrame.Size = UDim2.new(1, 0, 0, 35)
	buttonsFrame.BackgroundTransparency = 1
	buttonsFrame.LayoutOrder = 5 -- Diubah ke 5 untuk berada di bawah contentContainer
	buttonsFrame.Parent = mainFrame

	local buttonsLayout = Instance.new("UIListLayout")
	buttonsLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonsLayout.Padding = UDim.new(0, 10)
	buttonsLayout.Parent = buttonsFrame

	local function createButton(name, text, parent, size)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Text = text
		button.Size = size or UDim2.new(0.5, -5, 1, 0) -- Ukuran untuk 2 tombol
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.SourceSansBold
		button.Parent = parent
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
		return button
	end

	local setDataButton = createButton("SetDataButton", "Set Data", buttonsFrame)
	setDataButton.BackgroundColor3 = Color3.fromRGB(70, 90, 150)

	local deleteDataButton = createButton("DeleteDataButton", "Delete Data", buttonsFrame)
	deleteDataButton.BackgroundColor3 = Color3.fromRGB(180, 70, 70)

	-- Player List Button
	local playerListButton = createButton("PlayerListButton", "Daftar Pemain", mainFrame, UDim2.new(1, 0, 0, 35))
	playerListButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	playerListButton.LayoutOrder = 6

	-- Status Label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0, 40)
	statusLabel.Text = "Status: Idle | Tekan 'P' untuk Buka/Tutup"
	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextWrapped = true
	statusLabel.LayoutOrder = 7
	statusLabel.Parent = mainFrame

	-- Pop-up Frames
	local function createPopupFrame(name, size, zIndex)
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.Size = size
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		frame.BorderColor3 = Color3.fromRGB(120, 120, 120)
		frame.Visible = false
		frame.ZIndex = zIndex
		frame.Parent = screenGui
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 10)
		padding.PaddingBottom = UDim.new(0, 10)
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.Parent = frame

		return frame
	end

	-- Player List UI
	local playerListFrame = createPopupFrame("PlayerListFrame", UDim2.new(0, 300, 0, 400), 4)
	local playerListLayout = Instance.new("UIListLayout")
	playerListLayout.Padding = UDim.new(0, 5)
	playerListLayout.Parent = playerListFrame

	local playerListTitle = Instance.new("TextLabel")
	playerListTitle.Size = UDim2.new(1, 0, 0, 25)
	playerListTitle.Text = "Pemain Online"
	playerListTitle.Font = Enum.Font.SourceSansBold
	playerListTitle.TextColor3 = Color3.new(1, 1, 1)
	playerListTitle.BackgroundTransparency = 1
	playerListTitle.Parent = playerListFrame

	local playerListScroll = Instance.new("ScrollingFrame")
	playerListScroll.Size = UDim2.new(1, 0, 1, -65)
	playerListScroll.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	playerListScroll.Parent = playerListFrame
	Instance.new("UICorner", playerListScroll).CornerRadius = UDim.new(0, 6)

	local playerListScrollLayout = Instance.new("UIListLayout")
	playerListScrollLayout.Padding = UDim.new(0, 5)
	playerListScrollLayout.Parent = playerListScroll

	local closePlayerListButton = createButton("ClosePlayerListButton", "Tutup", playerListFrame, UDim2.new(1, 0, 0, 30))
	closePlayerListButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

	-- Data Display UI (Now obsolete, but kept for pop-up structure)
	local dataDisplayFrame = createPopupFrame("DataDisplayFrame", UDim2.new(0, 300, 0, 330), 2)
	dataDisplayFrame.Visible = false -- Hide by default

	-- Confirmation Dialog UI
	local confirmationFrame = createPopupFrame("ConfirmationFrame", UDim2.new(0, 350, 0, 130), 3)
	local confirmationLayout = Instance.new("UIListLayout")
	confirmationLayout.Padding = UDim.new(0, 10)
	confirmationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	confirmationLayout.Parent = confirmationFrame

	local confirmationLabel = Instance.new("TextLabel")
	confirmationLabel.Size = UDim2.new(1, 0, 0, 50)
	confirmationLabel.TextColor3 = Color3.new(1, 1, 1)
	confirmationLabel.BackgroundTransparency = 1
	confirmationLabel.TextWrapped = true
	confirmationLabel.Parent = confirmationFrame

	local confirmButtonsFrame = Instance.new("Frame")
	confirmButtonsFrame.Size = UDim2.new(1, 0, 0, 30)
	confirmButtonsFrame.BackgroundTransparency = 1
	confirmButtonsFrame.Parent = confirmationFrame

	local confirmButtonsLayout = Instance.new("UIListLayout")
	confirmButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
	confirmButtonsLayout.Padding = UDim.new(0, 10)
	confirmButtonsLayout.Parent = confirmButtonsFrame

	local confirmYesButton = createButton("ConfirmYesButton", "Ya", confirmButtonsFrame, UDim2.new(0.5, -5, 1, 0))
	confirmYesButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)

	local confirmNoButton = createButton("ConfirmNoButton", "Tidak", confirmButtonsFrame, UDim2.new(0.5, -5, 1, 0))
	confirmNoButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)

	-- UI Logic
	local function togglePanel()
		mainFrame.Visible = not mainFrame.Visible
		if not mainFrame.Visible then -- Sembunyikan semua popup
			confirmationFrame.Visible, playerListFrame.Visible = false, false
		end
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		local activeTextBox = UserInputService:GetFocusedTextBox()
		if activeTextBox and activeTextBox:IsDescendantOf(screenGui) then return end
		if input.KeyCode == Enum.KeyCode.P then togglePanel() end
	end)

	-- Player List Logic
	local function updatePlayerList()
		for _, v in ipairs(playerListScroll:GetChildren()) do
			if v:IsA("TextButton") then v:Destroy() end
		end
		for _, p in ipairs(Players:GetPlayers()) do
			local playerButton = createButton(p.Name, p.Name, playerListScroll, UDim2.new(1, 0, 0, 30))
			playerButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			playerButton.MouseButton1Click:Connect(function()
				userIdBox.Text = tostring(p.UserId)
				playerListFrame.Visible = false
				statusLabel.Text = "Status: UserID " .. p.UserId .. " dipilih."
			end)
		end
	end

	playerListButton.MouseButton1Click:Connect(function()
		updatePlayerList()
		playerListFrame.Visible = true
	end)
	closePlayerListButton.MouseButton1Click:Connect(function() playerListFrame.Visible = false end)
	Players.PlayerAdded:Connect(updatePlayerList)
	Players.PlayerRemoving:Connect(updatePlayerList)

	-- Main Buttons Logic
	getDataButton.MouseButton1Click:Connect(function()
		local targetUserId = tonumber(userIdBox.Text)
		if not targetUserId then statusLabel.Text = "Status: UserID tidak valid."; return end

		statusLabel.Text = "Status: Meminta data..."
		-- Clear old dynamic UI from both pages
		for _, page in pairs({statsPage, inventoryPage}) do
			for _, child in ipairs(page:GetChildren()) do
				if not child:IsA("UIListLayout") then
					child:Destroy()
				end
			end
		end

		local data, message = requestDataFunc:InvokeServer(targetUserId)

		if data then
			currentData = data

			-- Build the dynamic UI into the respective tabs
			if data.stats then
				buildDynamicUI(statsPage, "Stats", data.stats, "")
			end
			if data.inventory then
				buildDynamicUI(inventoryPage, "Inventory", data.inventory, "")
			end

			statusLabel.Text = "Status: Data berhasil dimuat untuk UserID " .. targetUserId
		else
			currentData = nil
			statusLabel.Text = "Status: Gagal memuat data. Pesan: " .. (message or "Tidak ada data.")
		end
	end)

	local function triggerConfirmation(action, id, data)
		pendingAction, pendingTargetId, pendingData = action, id, data
		if action == "set" then
			confirmationLabel.Text = "Apakah Anda yakin ingin mengubah data untuk UserID " .. id .. "?"
		elseif action == "delete" then
			confirmationLabel.Text = "PERINGATAN: Aksi ini akan menghapus data secara permanen. Apakah Anda yakin ingin menghapus data untuk UserID " .. id .. "?"
		end
		confirmationFrame.Visible = true
	end

	-- Dynamic Data Reconstructor Function
	local function reconstructData()
		local newData = {}
		-- Iterate over both pages to reconstruct data from all visible fields
		for _, page in pairs({statsPage, inventoryPage}) do
			for _, itemFrame in ipairs(page:GetDescendants()) do
				if itemFrame:IsA("Frame") and itemFrame:GetAttribute("DataPath") then
					local path = itemFrame:GetAttribute("DataPath")
					local dataType = itemFrame:GetAttribute("DataType")
					local valueBox = itemFrame:FindFirstChild("ValueBox")
					if valueBox and valueBox.TextEditable then -- Hanya proses field yang bisa diedit
						local textValue = valueBox.Text
						local value
						-- Konversi nilai kembali ke tipe data aslinya
						if dataType == "number" then
							value = tonumber(textValue)
							if value == nil then
								statusLabel.Text = "Status: Input tidak valid untuk path " .. path .. ". Harap masukkan angka."
								return nil -- Batalkan jika ada input yang tidak valid
							end
						elseif dataType == "boolean" then
							value = (textValue:lower() == "true")
						else
							value = textValue -- Tetap sebagai string
						end

						-- Rekonstruksi path di tabel newData
						local pathSegments = string.split(path, "/")
						local currentTable = newData
						-- Mulai dari indeks 2 untuk melewati string kosong pertama dari split
						for i = 2, #pathSegments - 1 do
							local segment = pathSegments[i]
							if not currentTable[segment] then
								currentTable[segment] = {}
							end
							currentTable = currentTable[segment]
						end
						currentTable[pathSegments[#pathSegments]] = value
					end
				end
			end
		end
		-- Gabungkan data yang tidak dapat diedit dari data asli
		-- Ini penting untuk menjaga integritas data seperti 'TotalKills', 'Skins', dll.
		local function deepMerge(t1, t2)
			for k, v in pairs(t2) do
				if type(v) == "table" and type(t1[k]) == "table" then
					deepMerge(t1[k], v)
				elseif t1[k] == nil then
					t1[k] = v
				end
			end
			return t1
		end

		return deepMerge(newData, currentData)
	end

	setDataButton.MouseButton1Click:Connect(function()
		if not currentData then
			statusLabel.Text = "Status: Dapatkan data pemain terlebih dahulu."
			return
		end

		local targetUserId = tonumber(userIdBox.Text)
		if not targetUserId then
			statusLabel.Text = "Status: UserID tidak valid."
			return
		end

		-- Rekonstruksi data dari UI dinamis
		local newData = reconstructData()

		if newData then
			triggerConfirmation("set", targetUserId, newData)
		else
			-- Pesan error sudah diatur oleh reconstructData
		end
	end)

	deleteDataButton.MouseButton1Click:Connect(function()
		local targetUserId = tonumber(userIdBox.Text)
		if not targetUserId then statusLabel.Text = "Status: UserID tidak valid."; return end
		triggerConfirmation("delete", targetUserId)
	end)

	local function resetConfirmationState()
		pendingAction, pendingTargetId, pendingData = nil, nil, nil
		confirmationFrame.Visible = false
	end

	confirmYesButton.MouseButton1Click:Connect(function()
		if pendingAction == "set" then
			updateDataEvent:FireServer(pendingTargetId, pendingData)
			statusLabel.Text = "Status: Permintaan perubahan data dikirim."
		elseif pendingAction == "delete" then
			deleteDataEvent:FireServer(pendingTargetId)
			statusLabel.Text = "Status: Permintaan hapus data dikirim."
			-- Clear UI after deletion from both pages
			for _, page in pairs({statsPage, inventoryPage}) do
				for _, child in ipairs(page:GetChildren()) do
					if not child:IsA("UIListLayout") then
						child:Destroy()
					end
				end
			end
			currentData = nil
		end
		resetConfirmationState()
	end)

	confirmNoButton.MouseButton1Click:Connect(function()
		resetConfirmationState()
		statusLabel.Text = "Status: Aksi dibatalkan."
	end)
end

-- Main Logic
player:GetAttributeChangedSignal("IsAdmin"):Connect(function()
	isAdmin = player:GetAttribute("IsAdmin")
	if isAdmin then CreateAdminUI()
	else
		local adminGui = player.PlayerGui:FindFirstChild("AdminPanelGui")
		if adminGui then adminGui:Destroy() end
	end
end)

isAdmin = player:GetAttribute("IsAdmin")
if isAdmin then CreateAdminUI() end
