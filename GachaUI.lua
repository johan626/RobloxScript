-- GachaUI.lua (LocalScript)
-- Path: StarterGui/GachaUI.lua
-- Script Place: Lobby
-- Last Updated: Refactored for per-weapon gacha system.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Module & Event References
local AudioManager = require(ReplicatedStorage.ModuleScript:WaitForChild("AudioManager"))
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ReplicatedStorage.ModuleScript:WaitForChild("ModelPreviewModule"))
local GachaRollEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GachaRollEvent")
local GachaMultiRollEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GachaMultiRollEvent")
local GachaFreeRollEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GachaFreeRollEvent")
local GetGachaConfig = ReplicatedStorage.RemoteFunctions:WaitForChild("GetGachaConfig")
local GetGachaStatus = ReplicatedStorage.RemoteFunctions:WaitForChild("GetGachaStatus")

-- ================== UI CREATION ==================
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "GachaSkinGUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false

-- [NEW] Weapon Selection Container
local weaponSelectionContainer = Instance.new("Frame", screenGui)
weaponSelectionContainer.Name = "WeaponSelectionContainer"
weaponSelectionContainer.AnchorPoint = Vector2.new(0.5, 0.5)
weaponSelectionContainer.Size = UDim2.new(0.8, 0, 0.8, 0)
weaponSelectionContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
weaponSelectionContainer.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
weaponSelectionContainer.BackgroundTransparency = 0.1
weaponSelectionContainer.BorderSizePixel = 2
weaponSelectionContainer.BorderColor3 = Color3.fromRGB(0, 170, 255)
weaponSelectionContainer.Visible = false
local wsCorner = Instance.new("UICorner", weaponSelectionContainer); wsCorner.CornerRadius = UDim.new(0, 12)
local wsAspectRatio = Instance.new("UIAspectRatioConstraint", weaponSelectionContainer)
wsAspectRatio.AspectRatio = 1.5

local wsTitle = Instance.new("TextLabel", weaponSelectionContainer)
wsTitle.Name = "Title"
wsTitle.Size = UDim2.new(1, -20, 0.1, 0)
wsTitle.Position = UDim2.new(0.5, 0, 0.05, 0)
wsTitle.AnchorPoint = Vector2.new(0.5, 0)
wsTitle.Text = "PILIH SENJATA UNTUK GACHA"
wsTitle.Font = Enum.Font.Sarpanch
wsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
wsTitle.TextScaled = true
wsTitle.BackgroundTransparency = 1

local weaponList = Instance.new("ScrollingFrame", weaponSelectionContainer)
weaponList.Name = "WeaponList"
weaponList.Size = UDim2.new(0.9, 0, 0.75, 0)
weaponList.Position = UDim2.new(0.5, 0, 0.5, 0)
weaponList.AnchorPoint = Vector2.new(0.5, 0.5)
weaponList.BackgroundTransparency = 1
weaponList.BorderSizePixel = 0
local weaponListLayout = Instance.new("UIGridLayout", weaponList)
weaponListLayout.CellPadding = UDim2.new(0.02, 0, 0.03, 0)
weaponListLayout.CellSize = UDim2.new(0.3, 0, 0.4, 0)
weaponListLayout.SortOrder = Enum.SortOrder.Name

local wsCloseButton = Instance.new("TextButton", weaponSelectionContainer)
wsCloseButton.Name = "CloseButton"
wsCloseButton.Size = UDim2.new(0, 30, 0, 30)
wsCloseButton.Position = UDim2.new(1, -20, 0, 20)
wsCloseButton.AnchorPoint = Vector2.new(1, 0)
wsCloseButton.Text = "X"
wsCloseButton.Font = Enum.Font.SourceSansBold
wsCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
wsCloseButton.TextSize = 22
wsCloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
local wscbCorner = Instance.new("UICorner", wsCloseButton); wscbCorner.CornerRadius = UDim.new(1, 0)

-- Main Container (for specific weapon gacha)
local mainContainer = Instance.new("Frame", screenGui)
mainContainer.Name = "MainContainer"
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.Size = UDim2.new(0.8, 0, 0.8, 0)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
mainContainer.BackgroundTransparency = 0.1
mainContainer.BorderSizePixel = 0
mainContainer.Visible = false

local aspectRatioConstraint = Instance.new("UIAspectRatioConstraint", mainContainer)
aspectRatioConstraint.AspectRatio = 1.5
aspectRatioConstraint.DominantAxis = Enum.DominantAxis.Width
aspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

local decoFrame = Instance.new("Frame", mainContainer)
decoFrame.Name = "DecoFrame"
decoFrame.Size = UDim2.new(1, 0, 1, 0)
decoFrame.BackgroundTransparency = 1
decoFrame.BorderSizePixel = 2
decoFrame.BorderColor3 = Color3.fromRGB(0, 170, 255)
local decoCorner = Instance.new("UICorner", decoFrame)
decoCorner.CornerRadius = UDim.new(0, 12)

-- [NEW] Back button to return to weapon selection
local backButton = Instance.new("TextButton", mainContainer)
backButton.Name = "BackButton"
backButton.Size = UDim2.new(0, 30, 0, 30)
backButton.Position = UDim2.new(0, 20, 0, 20)
backButton.AnchorPoint = Vector2.new(0, 0)
backButton.Text = "<"
backButton.Font = Enum.Font.SourceSansBold
backButton.TextColor3 = Color3.fromRGB(255, 255, 255)
backButton.TextSize = 22
backButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
local backCorner = Instance.new("UICorner", backButton); backCorner.CornerRadius = UDim.new(1, 0)

local leftPanel = Instance.new("Frame", mainContainer)
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0.6, 0, 0.95, 0)
leftPanel.Position = UDim2.new(0.025, 0, 0.5, 0)
leftPanel.AnchorPoint = Vector2.new(0, 0.5)
leftPanel.BackgroundTransparency = 1

local titleLabel = Instance.new("TextLabel", leftPanel)
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Text = "WEAPON CRATE" -- Will be updated dynamically
titleLabel.Font = Enum.Font.Sarpanch
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.BackgroundTransparency = 1

local mainViewport = Instance.new("ViewportFrame", leftPanel)
mainViewport.Name = "MainViewport"
mainViewport.Size = UDim2.new(1, 0, 0.45, 0)
mainViewport.Position = UDim2.new(0, 0, 0.12, 0)
mainViewport.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
mainViewport.BorderSizePixel = 1
mainViewport.BorderColor3 = Color3.fromRGB(0, 170, 255)
local vpCorner = Instance.new("UICorner", mainViewport); vpCorner.CornerRadius = UDim.new(0, 8)

local legendaryChanceLabel = Instance.new("TextLabel", leftPanel)
legendaryChanceLabel.Name = "LegendaryChanceLabel"
legendaryChanceLabel.Size = UDim2.new(1, 0, 0.05, 0)
legendaryChanceLabel.Position = UDim2.new(0, 0, 0.58, 0)
legendaryChanceLabel.Font = Enum.Font.SourceSans
legendaryChanceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
legendaryChanceLabel.TextScaled = true
legendaryChanceLabel.TextXAlignment = Enum.TextXAlignment.Left
legendaryChanceLabel.BackgroundTransparency = 1

local commonChanceLabel = Instance.new("TextLabel", leftPanel)
commonChanceLabel.Name = "CommonChanceLabel"
commonChanceLabel.Size = UDim2.new(1, 0, 0.05, 0)
commonChanceLabel.Position = UDim2.new(0, 0, 0.63, 0)
commonChanceLabel.Font = Enum.Font.SourceSans
commonChanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
commonChanceLabel.TextScaled = true
commonChanceLabel.TextXAlignment = Enum.TextXAlignment.Left
commonChanceLabel.BackgroundTransparency = 1

local armoryLabel = Instance.new("TextLabel", leftPanel)
armoryLabel.Name = "ArmoryLabel"
armoryLabel.Size = UDim2.new(1, 0, 0.05, 0)
armoryLabel.Position = UDim2.new(0, 0, 0.7, 0)
armoryLabel.Font = Enum.Font.Sarpanch
armoryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
armoryLabel.TextScaled = true
armoryLabel.Text = "LEGENDARY ARMORY"
armoryLabel.TextXAlignment = Enum.TextXAlignment.Left
armoryLabel.BackgroundTransparency = 1

local armoryContainer = Instance.new("ScrollingFrame", leftPanel)
armoryContainer.Name = "ArmoryContainer"
armoryContainer.Size = UDim2.new(1, 0, 0.15, 0)
armoryContainer.Position = UDim2.new(0, 0, 0.75, 0)
armoryContainer.BackgroundTransparency = 1
armoryContainer.CanvasSize = UDim2.new(2, 0, 1, 0)
armoryContainer.ScrollBarThickness = 6
local armoryLayout = Instance.new("UIListLayout", armoryContainer)
armoryLayout.FillDirection = Enum.FillDirection.Horizontal
armoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
armoryLayout.Padding = UDim.new(0.02, 0)

local viewRewardsButton = Instance.new("TextButton", leftPanel)
viewRewardsButton.Name = "ViewLegendaryRewards"
viewRewardsButton.Size = UDim2.new(1, 0, 0.08, 0)
viewRewardsButton.Position = UDim2.new(0, 0, 0.92, 0)
viewRewardsButton.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
viewRewardsButton.BorderSizePixel = 1
viewRewardsButton.BorderColor3 = Color3.fromRGB(0, 170, 255)
viewRewardsButton.Font = Enum.Font.Sarpanch
viewRewardsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
viewRewardsButton.TextScaled = true
viewRewardsButton.Text = "LIHAT HADIAH LEGENDARIS"
local vrCorner = Instance.new("UICorner", viewRewardsButton); vrCorner.CornerRadius = UDim.new(0, 4)

local rightPanel = Instance.new("Frame", mainContainer)
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(0.35, 0, 0.95, 0)
rightPanel.Position = UDim2.new(0.975, 0, 0.5, 0)
rightPanel.AnchorPoint = Vector2.new(1, 0.5)
rightPanel.BackgroundTransparency = 1

local rollButton1 = Instance.new("TextButton", rightPanel)
rollButton1.Name = "RollButton1"
rollButton1.Size = UDim2.new(0.9, 0, 0.2, 0)
rollButton1.Position = UDim2.new(0.5, 0, 0.3, 0)
rollButton1.AnchorPoint = Vector2.new(0.5, 0.5)
rollButton1.BackgroundColor3 = Color3.fromRGB(15, 80, 180)
rollButton1.BorderSizePixel = 1
rollButton1.BorderColor3 = Color3.fromRGB(0, 170, 255)
rollButton1.Text = "ROLL x1"
rollButton1.Font = Enum.Font.SourceSansBold
rollButton1.TextColor3 = Color3.fromRGB(255,255,255)
rollButton1.TextScaled = true
local r1Corner = Instance.new("UICorner", rollButton1); r1Corner.CornerRadius = UDim.new(0, 8)

local rollButton10 = Instance.new("TextButton", rightPanel)
rollButton10.Name = "RollButton10"
rollButton10.Size = UDim2.new(0.9, 0, 0.2, 0)
rollButton10.Position = UDim2.new(0.5, 0, 0.6, 0)
rollButton10.AnchorPoint = Vector2.new(0.5, 0.5)
rollButton10.BackgroundColor3 = Color3.fromRGB(15, 80, 180)
rollButton10.BorderSizePixel = 1
rollButton10.BorderColor3 = Color3.fromRGB(0, 170, 255)
rollButton10.Text = "ROLL 10+1"
rollButton10.Font = Enum.Font.SourceSansBold
rollButton10.TextColor3 = Color3.fromRGB(255,255,255)
rollButton10.TextScaled = true
local r10Corner = Instance.new("UICorner", rollButton10); r10Corner.CornerRadius = UDim.new(0, 8)

local freeRollButton = Instance.new("TextButton", rightPanel)
freeRollButton.Name = "FreeRollButton"
freeRollButton.Size = UDim2.new(0.9, 0, 0.15, 0)
freeRollButton.Position = UDim2.new(0.5, 0, 0.8, 0)
freeRollButton.AnchorPoint = Vector2.new(0.5, 0.5)
freeRollButton.BackgroundColor3 = Color3.fromRGB(20, 130, 90)
freeRollButton.BorderSizePixel = 1
freeRollButton.BorderColor3 = Color3.fromRGB(0, 255, 170)
freeRollButton.Font = Enum.Font.SourceSansBold
freeRollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
freeRollButton.Text = "ROLL GRATIS HARIAN"
freeRollButton.TextScaled = true
local frCorner = Instance.new("UICorner", freeRollButton); frCorner.CornerRadius = UDim.new(0, 8)

-- Other frames (Result, Animation, etc.) are mostly unchanged in creation
local animationFrame = Instance.new("Frame", mainContainer)
animationFrame.Name = "AnimationFrame"
animationFrame.Size = UDim2.new(1, 0, 1, 0)
animationFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
animationFrame.BackgroundTransparency = 0.1
animationFrame.Visible = false
local reelText = Instance.new("TextLabel", animationFrame)
reelText.Name = "ReelText"
reelText.Size = UDim2.new(1, 0, 1, 0)
reelText.Font = Enum.Font.Sarpanch
reelText.TextScaled = true
reelText.TextColor3 = Color3.fromRGB(255, 255, 255)
reelText.BackgroundTransparency = 1

local resultFrame = Instance.new("Frame", screenGui)
resultFrame.Name = "ResultFrame"
resultFrame.Size = UDim2.new(0.4, 0, 0.4, 0)
resultFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
resultFrame.AnchorPoint = Vector2.new(0.5, 0.5)
resultFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 25)
resultFrame.Visible = false
local resultText = Instance.new("TextLabel", resultFrame)
resultText.Name = "ResultText"
resultText.Size = UDim2.new(0.9, 0, 0.6, 0)
resultText.Position = UDim2.new(0.5, 0, 0.4, 0)
resultText.AnchorPoint = Vector2.new(0.5, 0.5)
resultText.Font = Enum.Font.SourceSansBold
resultText.TextScaled = true
resultText.BackgroundTransparency = 1
local resultShine = Instance.new("Frame", resultText)
resultShine.Name = "Shine"
resultShine.Size = UDim2.new(0.2,0,2,0)
resultShine.Position=UDim2.new(-0.2,0,-0.5,0)
resultShine.BackgroundColor3=Color3.fromRGB(255,255,255)
resultShine.Rotation=-20
resultShine.Visible=false
local shineGradient = Instance.new("UIGradient", resultShine)
shineGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,1)})
local resultCloseButton = Instance.new("TextButton", resultFrame)
resultCloseButton.Name = "ResultCloseButton"
resultCloseButton.Size = UDim2.new(0.8, 0, 0.2, 0)
resultCloseButton.Position = UDim2.new(0.5, 0, 0.85, 0)
resultCloseButton.AnchorPoint = Vector2.new(0.5, 0.5)
resultCloseButton.Text = "OK"
resultCloseButton.Font = Enum.Font.SourceSansBold
resultCloseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
resultCloseButton.TextScaled = true

local multiResultFrame = Instance.new("Frame", screenGui)
multiResultFrame.Name = "MultiResultFrame"
multiResultFrame.Size = UDim2.new(0.8, 0, 0.7, 0)
multiResultFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
multiResultFrame.AnchorPoint = Vector2.new(0.5, 0.5)
multiResultFrame.BackgroundColor3 = Color3.fromRGB(35, 37, 40)
multiResultFrame.Visible = false
local prizeContainer = Instance.new("ScrollingFrame", multiResultFrame)
prizeContainer.Size = UDim2.new(0.95, 0, 0.7, 0)
prizeContainer.Position = UDim2.new(0.5, 0, 0.45, 0)
prizeContainer.AnchorPoint = Vector2.new(0.5, 0.5)
prizeContainer.BackgroundTransparency = 1
local multiResultGrid = Instance.new("UIGridLayout", prizeContainer)
multiResultGrid.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
multiResultGrid.CellSize = UDim2.new(0.2, 0, 0.4, 0)
local multiResultCloseButton = Instance.new("TextButton", multiResultFrame)
multiResultCloseButton.Name = "MultiResultCloseButton"
multiResultCloseButton.Size = UDim2.new(0.3, 0, 0.1, 0)
multiResultCloseButton.Position = UDim2.new(0.5, 0, 0.9, 0)
multiResultCloseButton.AnchorPoint = Vector2.new(0.5, 0.5)
multiResultCloseButton.Text = "OK"
multiResultCloseButton.Font = Enum.Font.SourceSansBold
multiResultCloseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
multiResultCloseButton.TextScaled = true

local prizePreviewFrame = Instance.new("Frame", screenGui)
prizePreviewFrame.Name = "PrizePreviewFrame"
prizePreviewFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
prizePreviewFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
prizePreviewFrame.AnchorPoint = Vector2.new(0.5, 0.5)
prizePreviewFrame.BackgroundColor3 = Color3.fromRGB(25, 27, 30)
prizePreviewFrame.Visible = false
local ppfTitle = Instance.new("TextLabel", prizePreviewFrame)
ppfTitle.Name = "Title"
ppfTitle.Size = UDim2.new(1, 0, 0.1, 0)
ppfTitle.Text = "DAFTAR HADIAH LEGENDARIS"
ppfTitle.Font = Enum.Font.Sarpanch
ppfTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
ppfTitle.TextScaled = true
ppfTitle.BackgroundTransparency = 1
local ppfBackButton = Instance.new("TextButton", prizePreviewFrame)
ppfBackButton.Name = "BackButton"
ppfBackButton.Size = UDim2.new(0.2, 0, 0.1, 0)
ppfBackButton.Position = UDim2.new(0.1, 0, 0.9, 0)
ppfBackButton.AnchorPoint = Vector2.new(0, 0.5)
ppfBackButton.Text = "Kembali"
ppfBackButton.Font = Enum.Font.SourceSansBold
ppfBackButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
ppfBackButton.TextScaled = true
local prizeListContainer = Instance.new("ScrollingFrame", prizePreviewFrame)
prizeListContainer.Name = "PrizeListContainer"
prizeListContainer.Size = UDim2.new(0.95, 0, 0.75, 0)
prizeListContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
prizeListContainer.AnchorPoint = Vector2.new(0.5, 0.5)
prizeListContainer.BackgroundTransparency = 1
local prizeListLayout = Instance.new("UIGridLayout", prizeListContainer)
prizeListLayout.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
prizeListLayout.CellSize = UDim2.new(0.3, 0, 0.45, 0)

local skinDetailFrame = Instance.new("Frame", screenGui)
skinDetailFrame.Name = "SkinDetailFrame"
skinDetailFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
skinDetailFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
skinDetailFrame.AnchorPoint = Vector2.new(0.5, 0.5)
skinDetailFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 25)
skinDetailFrame.Visible = false
local sdfViewport = Instance.new("ViewportFrame", skinDetailFrame)
sdfViewport.Name = "DetailViewport"
sdfViewport.Size = UDim2.new(0.9, 0, 0.7, 0)
sdfViewport.Position = UDim2.new(0.5, 0, 0.45, 0)
sdfViewport.AnchorPoint = Vector2.new(0.5, 0.5)
sdfViewport.BackgroundColor3 = Color3.fromRGB(25, 27, 30)
local sdfBackButton = Instance.new("TextButton", skinDetailFrame)
sdfBackButton.Name = "DetailBackButton"
sdfBackButton.Size = UDim2.new(0.3, 0, 0.1, 0)
sdfBackButton.Position = UDim2.new(0.1, 0, 0.9, 0)
sdfBackButton.AnchorPoint = Vector2.new(0, 0.5)
sdfBackButton.Text = "Kembali ke Daftar"
sdfBackButton.Font = Enum.Font.SourceSansBold
sdfBackButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
sdfBackButton.TextScaled = true

-- ================== SCRIPT LOGIC ==================

local isRolling = false
local rarityChances = nil
local latestResult, latestMultiResult = nil, nil
local currentWeapon = nil -- [NEW] State to hold the selected weapon
local weaponSkins, potentialPrizes = {}, {}
local activePreviews, armoryPreviews, prizePreviews = {}, {}, {}
local currentDetailPreview = nil

local function playSound(soundName, props) AudioManager.createSound(soundName, screenGui, props):Play() end

local function clearPreviews(previewTable)
	for _, preview in pairs(previewTable) do ModelPreviewModule.destroy(preview) end
	table.clear(previewTable)
end

-- [MODIFIED] Gets all skins for a specific weapon
local function getSkinsForWeapon(weaponName)
	table.clear(weaponSkins); table.clear(potentialPrizes)
	local weaponData = WeaponModule.Weapons[weaponName]
	if not weaponData then return end

	for skinName, skinData in pairs(weaponData.Skins) do
		if skinName ~= "Default Skin" then
			local skinInfo = { WeaponName = weaponName, SkinName = skinName, WeaponData = weaponData, SkinData = skinData, Rarity = "Legendary" }
			table.insert(weaponSkins, skinInfo)
			table.insert(potentialPrizes, skinInfo)
		end
	end
	-- Add common rewards to the potential prize pool for animation
	for i = 1, 10 do table.insert(potentialPrizes, {SkinName = tostring(math.random(10, 50)) .. " BloodCoins", Rarity = "Common"}) end
end

-- [MODIFIED] Populates the display for the currently selected weapon
local function populateLegendaryDisplay()
	clearPreviews(activePreviews); clearPreviews(armoryPreviews)
	if not currentWeapon then return end

	getSkinsForWeapon(currentWeapon)
	if #weaponSkins == 0 then return end

	-- Shuffle skins for display
	local shuffled = {}
	for i=1, #weaponSkins do shuffled[i] = weaponSkins[i] end
	for i = #shuffled, 2, -1 do
		local j = math.random(i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end

	-- Main preview
	if shuffled[1] then
		activePreviews.main = ModelPreviewModule.create(mainViewport, shuffled[1].WeaponData, shuffled[1].SkinData)
		ModelPreviewModule.startRotation(activePreviews.main, 5)
	end

	-- Armory preview strip
	for _, child in ipairs(armoryContainer:GetChildren()) do
		if not child:IsA("UILayout") then child:Destroy() end
	end
	for i = 1, #shuffled do
		local itemFrame = Instance.new("Frame", armoryContainer)
		itemFrame.Size = UDim2.new(0.23, 0, 1, 0)
		itemFrame.BackgroundTransparency = 1
		local itemViewport = Instance.new("ViewportFrame", itemFrame)
		itemViewport.Size = UDim2.new(1,0,1,0)
		itemViewport.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
		itemViewport.BorderSizePixel = 1
		itemViewport.BorderColor3 = Color3.fromRGB(0, 100, 150)
		local vpc = Instance.new("UICorner", itemViewport); vpc.CornerRadius = UDim.new(0,8)

		armoryPreviews[i] = ModelPreviewModule.create(itemViewport, shuffled[i].WeaponData, shuffled[i].SkinData)
		ModelPreviewModule.startRotation(armoryPreviews[i], 3)
	end
end

local function fetchGachaConfig()
	if rarityChances then return end
	local s, r = pcall(function() return GetGachaConfig:InvokeServer() end)
	if s and r then
		rarityChances = r
		legendaryChanceLabel.Text = "PELUANG LEGENDARIS: " .. string.format("%.1f", r.Legendary or 0) .. "%"
		commonChanceLabel.Text = "PELUANG BIASA: " .. string.format("%.1f", r.Common or 0) .. "%"
	else
		legendaryChanceLabel.Text = "Gagal memuat peluang."
		commonChanceLabel.Text = ""
	end
end

local function playReelAnimation()
	if #potentialPrizes == 0 then return end

	animationFrame.Visible = true
	local s = AudioManager.createSound("Elements.Wind", screenGui, {Looped=true, Volume=0.3}); s:Play()
	local start = tick()
	while tick() - start < 3 do
		local prize = potentialPrizes[math.random(#potentialPrizes)]
		reelText.Text = prize.SkinName
		reelText.TextColor3 = prize.Rarity == "Legendary" and Color3.fromRGB(255,215,0) or Color3.fromRGB(200,200,200)
		task.wait(0.05)
	end
	s:Stop(); s:Destroy()
	animationFrame.Visible = false
end

local function playShineAnimation()
	resultShine.Visible = true
	local tween = TweenService:Create(resultShine, TweenInfo.new(0.7), {Position = UDim2.new(1,0,-0.5,0)})
	tween:Play()
	tween.Completed:Wait()
	resultShine.Visible = false
	resultShine.Position=UDim2.new(-0.2,0,-0.5,0)
end

local function showResult(resultData)
	animationFrame.Visible=false
	mainContainer.Visible=false
	weaponSelectionContainer.Visible = false
	if resultData.Success then
		local p = resultData.Prize
		if p.Type == "Skin" then
			resultText.Text = string.format("Selamat!\nAnda mendapatkan Skin:\n%s (%s)", p.SkinName, p.WeaponName)
			resultText.TextColor3 = Color3.fromRGB(255,215,0)
			playSound("Boss.Complete", {Volume=0.8})
			task.spawn(playShineAnimation)
		elseif p.Type == "Booster" then
			resultText.Text = string.format("Anda mendapatkan Booster:\n%s", p.Name)
			resultText.TextColor3 = Color3.fromRGB(0, 255, 255)
			playSound("Weapons.Empty", {Volume=0.7})
		else
			resultText.Text = string.format("Anda mendapatkan:\n%d BloodCoins", p.Amount)
			resultText.TextColor3 = Color3.fromRGB(255,255,255)
			playSound("Weapons.Empty", {Volume=0.7})
		end
	else
		resultText.Text = "Gagal!\n"..(resultData.Message or "Terjadi kesalahan.")
		resultText.TextColor3 = Color3.fromRGB(237,66,69)
		playSound("Weapons.Empty", {Volume=0.5})
	end
	resultFrame.Visible = true
end

local function createPrizeLabel(prize)
	local label = Instance.new("TextLabel")
	label.Size=UDim2.new(1,0,1,0)
	label.Font=Enum.Font.SourceSans
	label.TextWrapped=true
	label.BackgroundColor3=Color3.fromRGB(55,58,64)
	label.TextScaled = true
	if prize.Type == "Skin" then
		label.Text = string.format("%s\n(%s)", prize.SkinName, prize.WeaponName)
		label.TextColor3=Color3.fromRGB(255,215,0)
		label.LayoutOrder=1
	elseif prize.Type == "Booster" then
		label.Text = string.format("+1\n%s", prize.Name)
		label.TextColor3=Color3.fromRGB(0, 255, 255)
		label.LayoutOrder=2
	else
		label.Text = string.format("+%d\nBloodCoins", prize.Amount)
		label.TextColor3=Color3.fromRGB(200,200,200)
		label.LayoutOrder=3
	end
	return label
end

local function showMultiResult(resultData)
	animationFrame.Visible=false
	mainContainer.Visible=false
	weaponSelectionContainer.Visible = false
	for _,c in ipairs(prizeContainer:GetChildren()) do
		if c:IsA("UIGridLayout") then continue end
		c:Destroy()
	end
	if resultData.Success then
		for _, prize in ipairs(resultData.Prizes) do
			local prizeLabel = createPrizeLabel(prize)
			prizeLabel.Parent = prizeContainer
		end
		playSound("Boss.Complete", {Volume=0.8})
	end
	multiResultFrame.Visible = true
end

local function showSkinDetail(weaponName, skinName)
	for _, p in pairs(prizePreviews) do ModelPreviewModule.stopRotation(p) end
	prizePreviewFrame.Visible = false
	if currentDetailPreview then ModelPreviewModule.destroy(currentDetailPreview) end
	local weaponData = WeaponModule.Weapons[weaponName]
	local skinData = weaponData.Skins[skinName]
	currentDetailPreview = ModelPreviewModule.create(sdfViewport, weaponData, skinData)
	ModelPreviewModule.startRotation(currentDetailPreview, 5)
	skinDetailFrame.Visible = true
end

-- [MODIFIED] Populates the prize list for the current weapon
local function populatePrizePreview()
	clearPreviews(prizePreviews)
	for _,c in ipairs(prizeListContainer:GetChildren()) do if not c:IsA("UILayout") then c:Destroy() end end

	if #weaponSkins == 0 then getSkinsForWeapon(currentWeapon) end

	for _, skinInfo in ipairs(weaponSkins) do
		local btn = Instance.new("TextButton", prizeListContainer)
		btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""
		btn.MouseButton1Click:Connect(function() showSkinDetail(skinInfo.WeaponName, skinInfo.SkinName) end)
		local vp = Instance.new("ViewportFrame", btn); vp.Size=UDim2.new(1,0,0.7,0); vp.BackgroundColor3=Color3.fromRGB(25,27,30)
		prizePreviews[#prizePreviews+1] = ModelPreviewModule.create(vp, skinInfo.WeaponData, skinInfo.SkinData)
		ModelPreviewModule.startRotation(prizePreviews[#prizePreviews], 5)
		local name = Instance.new("TextLabel", btn); name.Size=UDim2.new(1,0,0.3,0); name.Position=UDim2.new(0,0,0.7,0)
		name.Text=skinInfo.SkinName; name.Font=Enum.Font.SourceSans; name.TextColor3=Color3.fromRGB(255,215,0)
		name.TextScaled=true; name.BackgroundTransparency=1
	end
end

local function updateGachaStatus()
	local status = GetGachaStatus:InvokeServer()
	if not status then return end
	local currentTime = os.time()
	local lastClaim = status.LastFreeGachaClaimUTC or 0
	local currentDayStart = math.floor(currentTime / 86400) * 86400
	local lastClaimDayStart = math.floor(lastClaim / 86400) * 86400
	if currentDayStart > lastClaimDayStart then
		freeRollButton.Text = "ROLL GRATIS TERSEDIA"
		freeRollButton.BackgroundColor3 = Color3.fromRGB(20, 130, 90)
		freeRollButton.AutoButtonColor = true
	else
		freeRollButton.Text = "Telah Diklaim"
		freeRollButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		freeRollButton.AutoButtonColor = false
	end
end

-- [NEW] Functions to control UI visibility
local function hideAllGachaUI()
	screenGui.Enabled = false
	mainContainer.Visible = false
	weaponSelectionContainer.Visible = false
	resultFrame.Visible=false
	multiResultFrame.Visible=false
	prizePreviewFrame.Visible=false
	skinDetailFrame.Visible=false
	clearPreviews(activePreviews); clearPreviews(armoryPreviews); clearPreviews(prizePreviews)
	if currentDetailPreview then ModelPreviewModule.destroy(currentDetailPreview); currentDetailPreview=nil end
	currentWeapon = nil
end

local function showGachaForWeapon(weaponName)
	currentWeapon = weaponName
	weaponSelectionContainer.Visible = false
	mainContainer.Visible = true
	titleLabel.Text = string.upper(weaponName) .. " CRATE"
	fetchGachaConfig()
	updateGachaStatus()
	populateLegendaryDisplay()
end

local function showWeaponSelection()
	currentWeapon = nil
	mainContainer.Visible = false
	weaponSelectionContainer.Visible = true
end

-- [NEW] Populates the weapon selection screen
local function populateWeaponSelection()
	for _, child in ipairs(weaponList:GetChildren()) do
		if not child:IsA("UILayout") then child:Destroy() end
	end

	for weaponName, weaponData in pairs(WeaponModule.Weapons) do
		-- Check if the weapon has any gacha-able skins
		local hasSkins = false
		for skinName, _ in pairs(weaponData.Skins) do
			if skinName ~= "Default Skin" then
				hasSkins = true
				break
			end
		end

		if hasSkins then
			local btn = Instance.new("TextButton", weaponList)
			btn.Name = weaponName
			btn.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
			btn.BorderSizePixel = 1
			btn.BorderColor3 = Color3.fromRGB(0, 170, 255)
			local btnCorner = Instance.new("UICorner", btn); btnCorner.CornerRadius = UDim.new(0, 8)
			local btnTitle = Instance.new("TextLabel", btn)
			btnTitle.Size = UDim2.new(1, 0, 0.3, 0)
			btnTitle.Position = UDim2.new(0, 0, 0.7, 0)
			btnTitle.Text = weaponName
			btnTitle.Font = Enum.Font.Sarpanch
			btnTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
			btnTitle.TextScaled = true
			btnTitle.BackgroundTransparency = 1

			btn.MouseButton1Click:Connect(function()
				showGachaForWeapon(weaponName)
			end)
		end
	end
end

-- [MODIFIED] Main toggle function
local function toggleGachaUI(visible)
	screenGui.Enabled = visible
	if visible then
		populateWeaponSelection()
		showWeaponSelection()
	else
		hideAllGachaUI()
	end
end

-- ================== EVENT CONNECTIONS ==================
GachaRollEvent.OnClientEvent:Connect(function(r) latestResult=r; updateGachaStatus() end)
GachaMultiRollEvent.OnClientEvent:Connect(function(r) latestMultiResult=r; updateGachaStatus() end)

wsCloseButton.MouseButton1Click:Connect(function() toggleGachaUI(false) end)
backButton.MouseButton1Click:Connect(function() showWeaponSelection() end)

resultCloseButton.MouseButton1Click:Connect(function() resultFrame.Visible=false; showGachaForWeapon(currentWeapon) end)
multiResultCloseButton.MouseButton1Click:Connect(function() multiResultFrame.Visible=false; showGachaForWeapon(currentWeapon) end)
viewRewardsButton.MouseButton1Click:Connect(function() mainContainer.Visible=false; populatePrizePreview(); prizePreviewFrame.Visible=true end)
ppfBackButton.MouseButton1Click:Connect(function() prizePreviewFrame.Visible=false; mainContainer.Visible=true; populateLegendaryDisplay() end)
sdfBackButton.MouseButton1Click:Connect(function()
	skinDetailFrame.Visible=false; prizePreviewFrame.Visible=true
	for _,p in pairs(prizePreviews) do ModelPreviewModule.startRotation(p,5) end
end)

rollButton1.MouseButton1Click:Connect(function()
	if isRolling or not currentWeapon then return end
	isRolling=true; latestResult=nil
	playSound("Weapons.Pistol.Reload", {Volume=0.5})
	task.spawn(playReelAnimation)
	GachaRollEvent:FireServer(currentWeapon) -- [MODIFIED] Pass currentWeapon
	local start=tick()
	while not latestResult do
		if tick()-start > 10 then latestResult={Success=false,Message="Server tidak merespons."}; break end
		task.wait(0.1)
	end
	showResult(latestResult)
	isRolling=false
end)

rollButton10.MouseButton1Click:Connect(function()
	if isRolling or not currentWeapon then return end
	isRolling=true; latestMultiResult=nil
	playSound("Weapons.Pistol.Reload", {Volume=0.5})
	task.spawn(playReelAnimation)
	GachaMultiRollEvent:FireServer(currentWeapon) -- [MODIFIED] Pass currentWeapon
	local start=tick()
	while not latestMultiResult do
		if tick()-start > 10 then latestMultiResult={Success=false,Message="Server tidak merespons."}; break end
		task.wait(0.1)
	end
	showMultiResult(latestMultiResult)
	isRolling=false
end)

freeRollButton.MouseButton1Click:Connect(function()
	if isRolling or not freeRollButton.AutoButtonColor or not currentWeapon then return end
	isRolling=true; latestResult=nil
	playSound("Weapons.Pistol.Reload", {Volume=0.5})
	task.spawn(playReelAnimation)
	GachaFreeRollEvent:FireServer(currentWeapon) -- [MODIFIED] Pass currentWeapon
	local start=tick()
	while not latestResult do
		if tick()-start > 10 then latestResult={Success=false,Message="Server tidak merespons."}; break end
		task.wait(0.1)
	end
	showResult(latestResult)
	isRolling=false
end)

local gachaPart = Workspace.Shop:WaitForChild("GachaShopSkin", 10)
if gachaPart then
	local prompt = gachaPart:WaitForChild("ProximityPrompt", 10)
	if prompt then prompt.Triggered:Connect(function() toggleGachaUI(true) end) end
end