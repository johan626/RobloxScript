-- ProfileUI.lua (LocalScript)
-- Path: StarterGui/ProfileUI.lua
-- Script Place: Lobby
-- Last Revision: [Current Date] - Modern UI/UX Overhaul for Profile

--[[ SERVICES ]]--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--[[ LOCAL PLAYER ]]--
local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")

--[[ CONSTANTS ]]--
-- Only run this script in the Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then
	script:Destroy()
	return
end

--[[ ASSETS & REMOTE EVENTS ]]--
local profileRemoteFunction = ReplicatedStorage:WaitForChild("GetProfileData")
local getTitleDataFunc = ReplicatedStorage:WaitForChild("GetTitleData")
local setEquippedTitleEvent = ReplicatedStorage:WaitForChild("SetEquippedTitle")
local getWeaponStatsFunc = ReplicatedStorage:WaitForChild("GetWeaponStats")
local LevelUpdateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("LevelUpdateEvent")
local BindableEvents = ReplicatedStorage:WaitForChild("BindableEvents")

--[[ TWEEN & ANIMATION SETTINGS ]]--
local TWEEN_INFO_FAST = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TWEEN_INFO_SMOOTH = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

--================================================================================--
--[[ HELPER FUNCTIONS ]]--
--================================================================================--

-- Creates a UI instance with specified properties
local function create(instanceType, properties)
	local obj = Instance.new(instanceType)
	for prop, value in pairs(properties or {}) do
		obj[prop] = value
	end
	return obj
end

-- Formats large numbers into a more readable format (K, M)
local function formatNumber(n)
    n = tonumber(n) or 0
	if n >= 1000000 then return string.format("%.1fM", n / 1000000) end
	if n >= 1000 then return string.format("%.1fK", n / 1000) end
	return tostring(n)
end

-- Creates a UI element with an icon
local function createIconLabel(parent, iconId, text)
    local frame = create("Frame", {
        Name = text .. "IconLabel",
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
    })
    local icon = create("ImageLabel", {
        Name = "Icon",
        Parent = frame,
        Size = UDim2.new(0, 24, 0, 24),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://" .. iconId,
        ImageColor3 = Color3.fromRGB(180, 180, 180)
    })
    local label = create("TextLabel", {
        Name = "Label",
        Parent = frame,
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 30, 0, 0),
        Font = Enum.Font.SourceSans,
        Text = text .. ": 0",
        TextSize = 18,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    return frame, label
end

-- Smoothly animates the UI in or out
local function animateUI(container, visible)
    if visible then
        container.Visible = true
        container.AnchorPoint = Vector2.new(0.5, 0.5)
        container.Position = UDim2.new(0.5, 0, 0.5, 20)
        container.Size = UDim2.new(0.9, 0, 0.9, 0)
        container.BackgroundTransparency = 1

        local sizeTween = TweenService:Create(container, TWEEN_INFO_SMOOTH, {Size = UDim2.new(1, 0, 1, 0)})
        local posTween = TweenService:Create(container, TWEEN_INFO_SMOOTH, {Position = UDim2.new(0.5, 0, 0.5, 0)})
        local transparencyTween = TweenService:Create(container, TWEEN_INFO_FAST, {BackgroundTransparency = 0})

        sizeTween:Play()
        posTween:Play()
        transparencyTween:Play()
    else
        local sizeTween = TweenService:Create(container, TWEEN_INFO_SMOOTH, {Size = UDim2.new(0.9, 0, 0.9, 0)})
        local posTween = TweenService:Create(container, TWEEN_INFO_SMOOTH, {Position = UDim2.new(0.5, 0, 0.5, 20)})
        local transparencyTween = TweenService:Create(container, TWEEN_INFO_FAST, {BackgroundTransparency = 1})

        sizeTween:Play()
        posTween:Play()
        transparencyTween:Play()

        sizeTween.Completed:Wait()
        container.Visible = false
    end
end


--================================================================================--
--[[ CORE UI STRUCTURE (NEW DESIGN) ]]--
--================================================================================--

-- Main ScreenGui
local profileScreenGui = create("ScreenGui", {
    Name = "ProfileUI_V2",
    Parent = playerGui,
    Enabled = true,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
})

-- Background Blur
local blur = create("BlurEffect", {
    Name = "BackgroundBlur",
    Parent = game.Lighting,
    Size = 0,
    Enabled = false,
})

-- Main container Frame (for animation)
local mainContainer = create("Frame", {
    Name = "MainContainer",
    Parent = profileScreenGui,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 750, 0, 500),
    BackgroundColor3 = Color3.fromRGB(30, 32, 40),
    BorderColor3 = Color3.fromRGB(80, 80, 80),
    BorderSizePixel = 1,
    Visible = false,
})
create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = mainContainer })

-- Main Layout (Two Columns)
local mainLayout = create("UIListLayout", {
    Parent = mainContainer,
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 10),
})
create("UIPadding", { Parent = mainContainer, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) })

-- Close Button
local closeButton = create("TextButton", {
    Name = "CloseButton",
    Parent = mainContainer,
    Size = UDim2.new(0, 32, 0, 32),
    Position = UDim2.new(1, -10, 0, 10),
    Text = "X",
    Font = Enum.Font.SourceSansBold,
    TextSize = 18,
    BackgroundColor3 = Color3.fromRGB(200, 50, 50),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    ZIndex = 3,
})
create("UICorner", { Parent = closeButton })

--[[ LEFT COLUMN (Player Identity) ]]--
local leftColumn = create("Frame", {
    Name = "LeftColumn",
    Parent = mainContainer,
    Size = UDim2.new(0.35, 0, 1, 0),
    BackgroundTransparency = 1,
})
local leftLayout = create("UIListLayout", { Parent = leftColumn, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

-- ViewportFrame for 3D Character Avatar
-- ImageLabel for 2D Player Avatar
local avatarImage = create("ImageLabel", {
    Name = "AvatarImage",
    Parent = leftColumn,
    Size = UDim2.new(1, 0, 0.6, 0),
    BackgroundColor3 = Color3.fromRGB(40, 42, 54),
    BorderSizePixel = 0,
    ScaleType = Enum.ScaleType.Crop,
    Image = "", -- Placeholder
})
create("UICorner", { Parent = avatarImage })

-- Player Info section below the avatar
local playerInfoFrame = create("Frame", {
    Name = "PlayerInfoFrame",
    Parent = leftColumn,
    Size = UDim2.new(1, 0, 0.4, -10),
    BackgroundTransparency = 1,
})
local infoLayout = create("UIListLayout", { Parent = playerInfoFrame, Padding = UDim.new(0, 5) })

-- Player Name
local nameLabel = create("TextLabel", {
    Name = "NameLabel",
    Parent = playerInfoFrame,
    Size = UDim2.new(1, 0, 0, 35),
    Text = "PLAYER NAME",
    Font = Enum.Font.SourceSansBold,
    TextSize = 28,
    TextColor3 = Color3.fromRGB(255, 255, 255),
})

-- Player Title
local playerTitleLabel = create("TextLabel", {
    Name = "PlayerTitleLabel",
    Parent = playerInfoFrame,
    Size = UDim2.new(1, 0, 0, 20),
    Text = "No Title Equipped",
    Font = Enum.Font.SourceSansItalic,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(180, 180, 180),
})

-- Level and XP Bar
local levelXPFrame = create("Frame", {
    Name = "LevelXPFrame",
    Parent = playerInfoFrame,
    Size = UDim2.new(1, 0, 0, 50),
    BackgroundTransparency = 1,
})

local levelLabel = create("TextLabel", {
    Name = "LevelLabel",
    Parent = levelXPFrame,
    Size = UDim2.new(0, 50, 1, 0),
    Text = "100",
    Font = Enum.Font.SourceSansBold,
    TextSize = 24,
    TextColor3 = Color3.fromRGB(255, 215, 0),
})

local xpBarBg = create("Frame", {
    Name = "XPBarBackground",
    Parent = levelXPFrame,
    Size = UDim2.new(1, -60, 0, 12),
    Position = UDim2.new(0, 60, 0.5, -6),
    BackgroundColor3 = Color3.fromRGB(24, 25, 32),
})
create("UICorner", { Parent = xpBarBg })

local xpBarFill = create("Frame", {
    Name = "XPBarFill",
    Parent = xpBarBg,
    Size = UDim2.new(0, 0, 1, 0), -- Start at 0 width
    BackgroundColor3 = Color3.fromRGB(78, 180, 255),
})
create("UICorner", { Parent = xpBarFill })

local xpValueLabel = create("TextLabel", {
    Name = "XPValueLabel",
    Parent = xpBarBg,
    Size = UDim2.new(1, 0, 1, 0),
    Text = "0 / 0 XP",
    Font = Enum.Font.SourceSansBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1,
})


--[[ RIGHT COLUMN (Details & Navigation) ]]--
local rightColumn = create("Frame", {
    Name = "RightColumn",
    Parent = mainContainer,
    Size = UDim2.new(0.65, -10, 1, 0),
    BackgroundTransparency = 1,
})
local rightLayout = create("UIListLayout", { Parent = rightColumn, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

-- Tab Navigation
local tabFrame = create("Frame", {
    Name = "TabFrame",
    Parent = rightColumn,
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
})
local tabLayout = create("UIListLayout", {
    Parent = tabFrame,
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 5),
})

-- Content Pages
local contentFrame = create("Frame", {
    Name = "ContentFrame",
    Parent = rightColumn,
    Size = UDim2.new(1, 0, 1, -50),
    BackgroundColor3 = Color3.fromRGB(40, 42, 54),
    BorderSizePixel = 0,
})
create("UICorner", { Parent = contentFrame })
local pageLayout = create("UIPageLayout", {
    Parent = contentFrame,
    Animated = true,
    EasingDirection = Enum.EasingDirection.Out,
    EasingStyle = Enum.EasingStyle.Sine,
    TweenTime = 0.3,
})

-- Create individual pages for each tab
local statsPage = create("ScrollingFrame", {
    Name = "StatsPage",
    Parent = contentFrame,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    LayoutOrder = 1,
})
create("UIListLayout", { Parent = statsPage, Padding = UDim.new(0, 8) })
create("UIPadding", { Parent = statsPage, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })

local titlesPage = create("ScrollingFrame", {
    Name = "TitlesPage",
    Parent = contentFrame,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    LayoutOrder = 2,
})
create("UIListLayout", { Parent = titlesPage, Padding = UDim.new(0, 5) })

local weaponStatsPage = create("ScrollingFrame", {
    Name = "WeaponStatsPage",
    Parent = contentFrame,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    LayoutOrder = 3,
})
create("UIListLayout", { Parent = weaponStatsPage, Padding = UDim.new(0, 5) })

-- Tab Button Creation
local activeTabColor = Color3.fromRGB(78, 180, 255)
local inactiveTabColor = Color3.fromRGB(50, 52, 64)
local activeTextColor = Color3.fromRGB(255, 255, 255)
local inactiveTextColor = Color3.fromRGB(180, 180, 180)

local tabButtons = {}

local function createTabButton(text, page)
    local button = create("TextButton", {
        Name = text .. "Tab",
        Parent = tabFrame,
        Size = UDim2.new(0.33, 0, 1, 0),
        Text = text,
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        BackgroundColor3 = inactiveTabColor,
        TextColor3 = inactiveTextColor,
    })
    create("UICorner", { Parent = button })
    table.insert(tabButtons, {button = button, page = page})
    return button
end

local statsTabButton = createTabButton("Statistics", statsPage)
local titlesTabButton = createTabButton("Titles", titlesPage)
local weaponStatsTabButton = createTabButton("Weapon Stats", weaponStatsPage)

-- Function to set the active tab
local function setActiveTab(selectedTab)
    for _, tabInfo in ipairs(tabButtons) do
        local isSelected = (tabInfo.button == selectedTab)
        local bgColor = isSelected and activeTabColor or inactiveTabColor
        local textColor = isSelected and activeTextColor or inactiveTextColor

        TweenService:Create(tabInfo.button, TWEEN_INFO_FAST, {BackgroundColor3 = bgColor, TextColor3 = textColor}):Play()

        if isSelected then
            pageLayout:JumpTo(tabInfo.page)
        end
    end
end

-- Connect tab button clicks
for _, tabInfo in ipairs(tabButtons) do
    tabInfo.button.MouseButton1Click:Connect(function()
        setActiveTab(tabInfo.button)
    end)
end


--================================================================================--
--[[ PROFILE BUTTON (Always Visible) ]]--
--================================================================================--
local profileButton = create("TextButton", {
	Name = "ProfileButton",
	Parent = profileScreenGui,
	AnchorPoint = Vector2.new(0, 0.5),
	Size = UDim2.new(0, 120, 0, 40),
	Position = UDim2.new(0.02, 0, 0.5, 0),
	Text = "View Profile",
	Font = Enum.Font.SourceSansBold,
	TextSize = 16,
	BackgroundColor3 = Color3.fromRGB(50, 52, 64),
	TextColor3 = Color3.fromRGB(255, 255, 255),
})
create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = profileButton })

--================================================================================--
--[[ LOGIC & EVENT CONNECTIONS ]]--
--================================================================================--

-- Main data update function
local function updateProfileData()
	local success, profileData = pcall(function()
		return profileRemoteFunction:InvokeServer()
	end)
	if success and profileData then
		-- Update Left Column Info
		nameLabel.Text = profileData.Name or "N/A"
		levelLabel.Text = tostring(profileData.Level or 0)

		local xp = profileData.XP or 0
		local needed = profileData.XPForNextLevel or 1000
		xpValueLabel.Text = string.format("%s / %s", formatNumber(xp), formatNumber(needed))
		local progress = (needed > 0) and math.clamp(xp / needed, 0, 1) or 1
		TweenService:Create(xpBarFill, TWEEN_INFO_SMOOTH, { Size = UDim2.new(progress, 0, 1, 0) }):Play()

        -- Populate Stats Page
        local stats = {
            {name = "Total Kills", value = profileData.TotalKills, icon = "6031023157"},
            {name = "Total Damage", value = profileData.TotalDamageDealt, icon = "6031022933"},
            {name = "Total Knocks", value = profileData.TotalKnocks, icon = "6031023023"},
            {name = "Total Revives", value = profileData.TotalRevives, icon = "6031022801"},
            {name = "Lifetime Coins", value = profileData.TotalCoins, icon = "6031022681"},
            {name = "Achievement Points", value = profileData.LifetimeAP, icon = "6031022567"},
        }
        for _, child in ipairs(statsPage:GetChildren()) do
            if not child:IsA("UILayout") then child:Destroy() end
        end
        for _, stat in ipairs(stats) do
            local _, label = createIconLabel(statsPage, stat.icon, stat.name)
            label.Text = stat.name .. ": " .. formatNumber(stat.value)
        end
	else
		warn("Failed to get profile data.")
	end
end

-- Functions to populate other tabs
local function populateTitles()
    -- Clear previous entries
    for _, child in ipairs(titlesPage:GetChildren()) do
        if not child:IsA("UILayout") then child:Destroy() end
    end

    local success, titleData = pcall(function() return getTitleDataFunc:InvokeServer() end)
    if not success then warn("Failed to get title data.") return end

    local unlockedTitles = titleData.UnlockedTitles or {}
    local equippedTitle = titleData.EquippedTitle or ""

    -- Update the main title label in the left column
    playerTitleLabel.Text = equippedTitle == "" and "No Title Equipped" or equippedTitle

    -- Unequip button
    local unequipButton = create("TextButton", {
        Name = "UnequipTitle",
        Parent = titlesPage,
        Size = UDim2.new(1, -10, 0, 40),
        Position = UDim2.new(0, 5, 0, 0),
        Text = "Unequip Title",
        Font = Enum.Font.SourceSans,
        TextSize = 18,
        BackgroundColor3 = equippedTitle == "" and activeTabColor or inactiveTabColor,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    create("UICorner", {Parent = unequipButton})

    unequipButton.MouseButton1Click:Connect(function()
        setEquippedTitleEvent:FireServer("")
        -- Refresh the titles list to show the change
        populateTitles()
    end)

    -- Create buttons for each unlocked title
    for _, title in ipairs(unlockedTitles) do
        local titleButton = create("TextButton", {
            Name = title,
            Parent = titlesPage,
            Size = UDim2.new(1, -10, 0, 40),
            Position = UDim2.new(0, 5, 0, 0),
            Text = title,
            Font = Enum.Font.SourceSans,
            TextSize = 18,
            BackgroundColor3 = title == equippedTitle and activeTabColor or inactiveTabColor,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        })
        create("UICorner", {Parent = titleButton})

        titleButton.MouseButton1Click:Connect(function()
            setEquippedTitleEvent:FireServer(title)
            -- Refresh the titles list to show the change
            populateTitles()
        end)
    end
end

local function populateWeaponStats()
    -- Clear previous entries
    for _, child in ipairs(weaponStatsPage:GetChildren()) do
        if not child:IsA("UILayout") then child:Destroy() end
    end

    local success, weaponStats = pcall(function() return getWeaponStatsFunc:InvokeServer() end)
    if not success then warn("Failed to get weapon stats.") return end

    if not weaponStats or #weaponStats == 0 then
        create("TextLabel", {
            Parent = weaponStatsPage,
            Size = UDim2.new(1, 0, 0, 40),
            Text = "No weapon stats recorded yet.",
            Font = Enum.Font.SourceSans,
            TextSize = 18,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            BackgroundTransparency = 1
        })
        return
    end

    for _, stat in ipairs(weaponStats) do
        -- Use a frame for better layout
        local statFrame = create("Frame", {
            Parent = weaponStatsPage,
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundTransparency = 1,
        })
        create("UIListLayout", {Parent = statFrame, FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0,2)})
        create("UIPadding", {Parent = statFrame, PaddingLeft = UDim.new(0,10)})

        create("TextLabel", {
            Parent = statFrame,
            Size = UDim2.new(1, 0, 0, 24),
            Text = stat.Name,
            Font = Enum.Font.SourceSansBold,
            TextSize = 20,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        create("TextLabel", {
            Parent = statFrame,
            Size = UDim2.new(1, 0, 0, 20),
            Text = string.format("Kills: %s  |  Damage: %s", formatNumber(stat.Kills or 0), formatNumber(stat.Damage or 0)),
            Font = Enum.Font.SourceSans,
            TextSize = 16,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextXAlignment = Enum.TextXAlignment.Left,
        })
    end
end


-- Fetches and sets the 2D avatar image
local function updateAvatarImage()
    local userId = player.UserId
    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size420x420

    -- Request the avatar image URL from Roblox services
    local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)

    if isReady then
        avatarImage.Image = content
    else
        warn("ProfileUI: Thumbnail for user " .. userId .. " was not ready.")
        -- Optionally, set a default/loading image here
    end
end

local function toggleProfileUI(visible)
    if visible then
        blur.Enabled = true
        TweenService:Create(blur, TWEEN_INFO_FAST, {Size = 8}):Play()
        updateAvatarImage() -- Replaced updateCharacterViewport
        updateProfileData()
        populateTitles()
        populateWeaponStats()
        setActiveTab(statsTabButton)
        animateUI(mainContainer, true)
    else
        TweenService:Create(blur, TWEEN_INFO_FAST, {Size = 0}):Play()
        animateUI(mainContainer, false)
        task.wait(0.4)
        blur.Enabled = false
    end
end

profileButton.MouseButton1Click:Connect(function()
    toggleProfileUI(not mainContainer.Visible)
end)

closeButton.MouseButton1Click:Connect(function()
    toggleProfileUI(false)
end)

-- Add hover effects to tab buttons
for _, tabInfo in ipairs(tabButtons) do
    tabInfo.button.MouseEnter:Connect(function()
        if pageLayout.CurrentPage ~= tabInfo.page then
            TweenService:Create(tabInfo.button, TWEEN_INFO_FAST, {BackgroundColor3 = Color3.fromRGB(70, 72, 84)}):Play()
        end
    end)
    tabInfo.button.MouseLeave:Connect(function()
        if pageLayout.CurrentPage ~= tabInfo.page then
            TweenService:Create(tabInfo.button, TWEEN_INFO_FAST, {BackgroundColor3 = inactiveTabColor}):Play()
        end
    end)
end

-- Connect to external events if needed
-- e.g., BindableEvents:WaitForChild("OpenProfileFromOtherUI"):Connect(function() toggleProfileUI(true) end)

print("ProfileUI V2 Initialized and Refactored.")
