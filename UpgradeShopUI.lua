-- UpgradeShopUI.lua (LocalScript)
-- Path: StarterGui/UpgradeShopUI.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))

local upgradeEvent = RemoteEvents:WaitForChild("UpgradeUIOpen")
local confirmUpgradeEvent = RemoteEvents:WaitForChild("ConfirmUpgrade")

local upgradeRF = RemoteFunctions:WaitForChild("UpgradeWeaponRF")
local getLevelRF = RemoteFunctions:WaitForChild("GetWeaponLevelRF")

local upgradePart = workspace:WaitForChild("Upgrade")

-- Create modern UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UpgradeShopUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.IgnoreGuiInset = true

-- Background overlay with blur effect
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.7
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.ZIndex = 1
overlay.Parent = screenGui

-- Main upgrade container with modern design - Responsive size for mobile
local isMobile = UserInputService.TouchEnabled
local mainContainerWidth = isMobile and 280 or 300
local mainContainerHeight = isMobile and 300 or 380

local mainContainer = Instance.new("Frame")
mainContainer.Size = UDim2.new(0, mainContainerWidth, 0, mainContainerHeight)
mainContainer.Position = UDim2.new(0.5, -mainContainerWidth/2, 0.5, -mainContainerHeight/2)
mainContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainContainer.BorderSizePixel = 0
mainContainer.Visible = false
mainContainer.ZIndex = 2
mainContainer.Parent = screenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 15)
UICorner.Parent = mainContainer

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(80, 80, 120)
UIStroke.Thickness = 3
UIStroke.Parent = mainContainer

-- Header with gradient effect
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, isMobile and 35 or 50)
header.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
header.BorderSizePixel = 0
header.ZIndex = 3
header.Parent = mainContainer

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 15)
headerCorner.Parent = header

local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 80)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 60))
}
headerGradient.Rotation = 90
headerGradient.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0.15, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "WEAPON UPGRADE"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextStrokeTransparency = 0.8
titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
titleLabel.ZIndex = 4
titleLabel.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, isMobile and 25 or 30, 0, isMobile and 25 or 30)
closeBtn.Position = UDim2.new(0.92, 0, 0.1, 0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 4
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

-- Upgrade info area with modern layout
local upgradeInfo = Instance.new("Frame")
upgradeInfo.Size = UDim2.new(0.9, 0, 0, isMobile and 170 or 240)
upgradeInfo.Position = UDim2.new(0.05, 0, 0.15, 0)
upgradeInfo.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
upgradeInfo.BorderSizePixel = 0
upgradeInfo.ZIndex = 3
upgradeInfo.Parent = mainContainer

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 10)
infoCorner.Parent = upgradeInfo

local infoStroke = Instance.new("UIStroke")
infoStroke.Color = Color3.fromRGB(90, 90, 130)
infoStroke.Thickness = 2
infoStroke.Parent = upgradeInfo

local weaponNameLabel = Instance.new("TextLabel")
weaponNameLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
weaponNameLabel.Position = UDim2.new(0.1, 0, 0.05, 0)
weaponNameLabel.BackgroundTransparency = 1
weaponNameLabel.Text = "WEAPON"
weaponNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
weaponNameLabel.TextScaled = true
weaponNameLabel.Font = Enum.Font.GothamBold
weaponNameLabel.ZIndex = 4
weaponNameLabel.Parent = upgradeInfo

local function createInfoRow(yPosition, icon, text, value, color)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(0.9, 0, 0, isMobile and 18 or 20)
	row.Position = UDim2.new(0.05, 0, yPosition, 0)
	row.BackgroundTransparency = 1
	row.ZIndex = 4
	row.Parent = upgradeInfo

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, isMobile and 18 or 20, 0, isMobile and 18 or 20)
	iconLabel.Position = UDim2.new(0, 0, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
	iconLabel.TextScaled = true
	iconLabel.ZIndex = 4
	iconLabel.Parent = row

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(0.5, 0, 1, 0)
	textLabel.Position = UDim2.new(0.2, 0, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	textLabel.TextScaled = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Font = Enum.Font.Gotham
	textLabel.ZIndex = 4
	textLabel.Parent = row

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.4, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = value
	valueLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	valueLabel.TextScaled = true
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.ZIndex = 4
	valueLabel.Parent = row

	return valueLabel
end

local rowHeight = isMobile and 0.14 or 0.15
local currentLevelValue = createInfoRow(rowHeight * 1, "📊", "Current Level", "Lv.0", Color3.fromRGB(200, 200, 255))
local nextLevelValue = createInfoRow(rowHeight * 2, "⬆️", "Next Level", "Lv.1", Color3.fromRGB(100, 255, 100))
local damageValue = createInfoRow(rowHeight * 3, "💥", "Damage", "0 → 0", Color3.fromRGB(255, 150, 100))
local ammoValue = createInfoRow(rowHeight * 4, "🔋", "Ammo", "+0%", Color3.fromRGB(100, 200, 255))
local costValue = createInfoRow(rowHeight * 5, "💰", "Cost", "0 BP", Color3.fromRGB(255, 215, 0))

local buttonContainer = Instance.new("Frame")
buttonContainer.Size = UDim2.new(0.9, 0, 0, isMobile and 45 or 60)
buttonContainer.Position = UDim2.new(0.05, 0, isMobile and 0.72 or 0.8, 0)
buttonContainer.BackgroundTransparency = 1
buttonContainer.ZIndex = 3
buttonContainer.Parent = mainContainer

local confirmButton = Instance.new("TextButton")
confirmButton.Size = UDim2.new(0.45, 0, 0.8, 0)
confirmButton.Position = UDim2.new(0, 0, 0.1, 0)
confirmButton.Text = "UPGRADE"
confirmButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmButton.Font = Enum.Font.GothamBold
confirmButton.TextScaled = true
confirmButton.ZIndex = 4
confirmButton.Parent = buttonContainer

local cancelButton = Instance.new("TextButton")
cancelButton.Size = UDim2.new(0.45, 0, 0.8, 0)
cancelButton.Position = UDim2.new(0.55, 0, 0.1, 0)
cancelButton.Text = "CANCEL"
cancelButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
cancelButton.Font = Enum.Font.GothamBold
cancelButton.TextScaled = true
cancelButton.ZIndex = 4
cancelButton.Parent = buttonContainer

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 10)
buttonCorner.Parent = confirmButton
buttonCorner:Clone().Parent = cancelButton

local function addButtonHoverEffect(button, hoverColor)
	if UserInputService.TouchEnabled then return end
	local originalColor = button.BackgroundColor3
	button.MouseEnter:Connect(function()
		game:GetService("TweenService"):Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
	end)
	button.MouseLeave:Connect(function()
		game:GetService("TweenService"):Create(button, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
	end)
end

addButtonHoverEffect(confirmButton, Color3.fromRGB(0, 220, 0))
addButtonHoverEffect(cancelButton, Color3.fromRGB(220, 0, 0))
addButtonHoverEffect(closeBtn, Color3.fromRGB(220, 80, 80))

local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local UPG_ARROW_ACTION = "UpgradeUI_Arrows"
local UPG_ENTER_ACTION = "UpgradeUI_Enter"
local upgSelected = "confirm"

local function styleUpgButton(btn, active)
	if not btn then return end
	local stroke = btn:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Parent = btn
	end
	stroke.Thickness = active and 3 or 0
	stroke.Color = Color3.fromRGB(255, 215, 0)
end

local function setUpgSelected(which)
	if which ~= "confirm" and which ~= "cancel" then return end
	upgSelected = which
	styleUpgButton(confirmButton, upgSelected == "confirm")
	styleUpgButton(cancelButton,  upgSelected == "cancel")
end

local function handleUpgArrows(_, state, input)
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
	if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Up then
		setUpgSelected("confirm")
	elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.Down then
		setUpgSelected("cancel")
	else
		return Enum.ContextActionResult.Pass
	end
	return Enum.ContextActionResult.Sink
end

local notificationFrame = Instance.new("Frame")
notificationFrame.Size = UDim2.new(0, isMobile and 250 or 300, 0, isMobile and 50 or 60)
notificationFrame.AnchorPoint = Vector2.new(0.5, 0.5)
notificationFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
notificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
notificationFrame.BorderSizePixel = 0
notificationFrame.Visible = false
notificationFrame.ZIndex = 10
notificationFrame.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 12)
notifCorner.Parent = notificationFrame

local notifStroke = Instance.new("UIStroke")
notifStroke.Color = Color3.fromRGB(80, 80, 120)
notifStroke.Thickness = 2
notifStroke.Parent = notificationFrame

local notifLabel = Instance.new("TextLabel")
notifLabel.Size = UDim2.new(1, 0, 1, 0)
notifLabel.BackgroundTransparency = 1
notifLabel.Text = ""
notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notifLabel.TextScaled = true
notifLabel.Font = Enum.Font.GothamBold
notifLabel.ZIndex = 11
notifLabel.Parent = notificationFrame

local progressContainer = Instance.new("Frame")
progressContainer.Size = UDim2.new(0.9, 0, 0, isMobile and 12 or 15)
progressContainer.Position = isMobile and UDim2.new(0.05, 0, 0.9, 0) or UDim2.new(0.05, 0, 0.95, 0)
progressContainer.BackgroundTransparency = 1
progressContainer.Visible = false
progressContainer.ZIndex = 5
progressContainer.Parent = mainContainer

local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(1, 0, 0.5, 0)
progressBg.Position = UDim2.new(0, 0, 0.25, 0)
progressBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
progressBg.BorderSizePixel = 0
progressBg.ZIndex = 4
progressBg.Parent = progressContainer

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
progressBar.BorderSizePixel = 0
progressBar.ZIndex = 5
progressBar.Parent = progressBg

local progressLabel = Instance.new("TextLabel")
progressLabel.Size = UDim2.new(1, 0, 1, 0)
progressLabel.BackgroundTransparency = 1
progressLabel.Text = "UPGRADING..."
progressLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
progressLabel.TextScaled = true
progressLabel.Font = Enum.Font.Gotham
progressLabel.ZIndex = 6
progressLabel.Parent = progressContainer

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(1, 0)
progressCorner.Parent = progressBg
progressCorner:Clone().Parent = progressBar

local currentTool = nil
local upgradeData = nil
local isUIOpen = false

local function setBackpackVisible(visible)
	if isMobile then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, visible)
	end
end

local function showNotification(message, color, duration)
	notifLabel.Text = message
	notifLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	notificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	notificationFrame.Visible = true
	notificationFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	local tweenIn = TweenService:Create(notificationFrame, TweenInfo.new(0.3), {Position = UDim2.new(0.5, 0, 0.45, 0)})
	tweenIn:Play()
	task.wait(duration or 3)
	local tweenOut = TweenService:Create(notificationFrame, TweenInfo.new(0.3), {Position = UDim2.new(0.5, 0, 0.55, 0)})
	tweenOut:Play()
	task.wait(0.3)
	notificationFrame.Visible = false
end

local function calculateDamage(weaponName, level)
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return 0 end
	local baseDamage = weaponStats.Damage or 0
	local cfg = weaponStats.UpgradeConfig or {}
	local damagePerLevel = cfg.DamagePerLevel or 5
	return baseDamage + (damagePerLevel * level)
end

local function calculateAmmoIncrease(level)
	if level == 0 then return 50 end
	return 0
end

local function unbindUpgradeControls()
	CAS:UnbindAction(UPG_ARROW_ACTION)
	CAS:UnbindAction(UPG_ENTER_ACTION)
end

local function closeUpgradeUI()
	if not isUIOpen then return end
	setBackpackVisible(true)
	local tween = TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -mainContainerWidth/2, 0.7, -mainContainerHeight/2),
		Size = UDim2.new(0, mainContainerWidth, 0, 0)
	})
	tween:Play()
	task.wait(0.3)
	mainContainer.Visible = false
	overlay.Visible = false
	isUIOpen = false
	ContextActionService:UnbindAction("CloseUpgradeUI")
	unbindUpgradeControls()
end

local function performUpgrade()
	if not currentTool or not upgradeData then return end
	progressContainer.Visible = true
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	local tween = TweenService:Create(progressBar, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)})
	tween:Play()
	confirmButton.AutoButtonColor = false
	confirmButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	cancelButton.AutoButtonColor = false
	cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	task.wait(1.5)
	confirmUpgradeEvent:FireServer(currentTool, true)
	progressContainer.Visible = false
	confirmButton.AutoButtonColor = true
	confirmButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
	cancelButton.AutoButtonColor = true
	cancelButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
	closeUpgradeUI()
end

local function handleUpgEnter(_, state, input)
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	if input.KeyCode ~= Enum.KeyCode.Return and input.KeyCode ~= Enum.KeyCode.KeypadEnter then
		return Enum.ContextActionResult.Pass
	end
	if upgSelected == "confirm" then
		performUpgrade()
	else
		closeUpgradeUI()
	end
	return Enum.ContextActionResult.Sink
end

local function bindUpgradeControls()
	if UIS.TouchEnabled then return end
	setUpgSelected("confirm")
	CAS:BindActionAtPriority(
		UPG_ARROW_ACTION, handleUpgArrows, false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.Up, Enum.KeyCode.Down
	)
	CAS:BindActionAtPriority(
		UPG_ENTER_ACTION, handleUpgEnter, false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter
	)
end

local function showUpgradeUI(tool, data)
	if isUIOpen then return end
	isUIOpen = true
	setBackpackVisible(false)
	currentTool = tool
	upgradeData = data
	weaponNameLabel.Text = data.weaponName:upper()
	currentLevelValue.Text = "Lv." .. data.currentLevel
	nextLevelValue.Text = "Lv." .. data.nextLevel
	local currentDamage = calculateDamage(data.weaponName, data.currentLevel)
	local nextDamage = calculateDamage(data.weaponName, data.nextLevel)
	damageValue.Text = currentDamage .. " → " .. nextDamage
	local ammoIncrease = calculateAmmoIncrease(data.currentLevel)
	if ammoIncrease > 0 then
		ammoValue.Text = "+" .. ammoIncrease .. "%"
		ammoValue.Visible = true
	else
		ammoValue.Visible = false
	end

	costValue.Text = data.cost .. " BP"
	if data.hasDiscount then
		costValue.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green for discount
	else
		costValue.TextColor3 = Color3.fromRGB(255, 215, 0) -- Default yellow
	end

	overlay.Visible = true
	mainContainer.Visible = true
	mainContainer.Position = UDim2.new(0.5, -mainContainerWidth/2, 0.7, -mainContainerHeight/2)
	mainContainer.Size = UDim2.new(0, mainContainerWidth, 0, 0)
	local tween = TweenService:Create(mainContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -mainContainerWidth/2, 0.5, -mainContainerHeight/2),
		Size = UDim2.new(0, mainContainerWidth, 0, mainContainerHeight)
	})
	tween:Play()
	ContextActionService:BindAction("CloseUpgradeUI", function(_, inputState, inputObject)
		if inputState == Enum.UserInputState.Begin and inputObject.KeyCode == Enum.KeyCode.Escape then
			closeUpgradeUI()
		end
	end, false, Enum.KeyCode.Escape)
	bindUpgradeControls()
end

local function getEquippedToolName()
	if player.Character then
		local t = player.Character:FindFirstChildOfClass("Tool")
		if t then return t.Name end
	end
	return nil
end

upgradeEvent.OnClientEvent:Connect(function(weaponName, newLevel)
	local current = getEquippedToolName()
	if current == weaponName then
		local tool = player.Character:FindFirstChildOfClass("Tool")
		if tool then
			tool:SetAttribute("UpgradeLevel", newLevel)
		end
		showNotification(weaponName .. " upgraded to Level " .. newLevel, Color3.fromRGB(0, 255, 0), 3)
	end
end)

confirmButton.MouseButton1Click:Connect(performUpgrade)
cancelButton.MouseButton1Click:Connect(closeUpgradeUI)
closeBtn.MouseButton1Click:Connect(closeUpgradeUI)

local function onEquipped(tool)
	if not tool then return end
	local ok, lvl = pcall(function() return getLevelRF:InvokeServer(tool) end)
	if ok and type(lvl) == "number" then
		tool:SetAttribute("UpgradeLevel", lvl)
	end
end

local function onUnequipped()
end

local function watchTools()
	if player.Character then
		player.Character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				child.Equipped:Connect(function() onEquipped(child) end)
				child.Unequipped:Connect(onUnequipped)
			end
		end)
		for _,v in pairs(player.Character:GetChildren()) do
			if v:IsA("Tool") then
				v.Equipped:Connect(function() onEquipped(v) end)
				v.Unequipped:Connect(onUnequipped)
			end
		end
	end
	local backpack = player:WaitForChild("Backpack")
	backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			child.Equipped:Connect(function() onEquipped(child) end)
			child.Unequipped:Connect(onUnequipped)
		end
	end)
	for _,v in pairs(backpack:GetChildren()) do
		if v:IsA("Tool") then
			v.Equipped:Connect(function() onEquipped(v) end)
			v.Unequipped:Connect(onUnequipped)
		end
	end
end

player.CharacterAdded:Connect(function()
	task.wait(0.2)
	watchTools()
end)
if player.Character then watchTools() end

RunService.RenderStepped:Connect(function()
	if isUIOpen then
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and upgradePart then
			local dist = (char.HumanoidRootPart.Position - upgradePart.Position).Magnitude
			if dist > 8 then
				closeUpgradeUI()
			end
		end
	end
end)

local ProximityPromptService = game:GetService("ProximityPromptService")
local upgradePrompt = workspace.Upgrade:WaitForChild("Attachment"):WaitForChild("UpgradePrompt")

ProximityPromptService.PromptTriggered:Connect(function(prompt, plr)
	if prompt ~= upgradePrompt or plr ~= player then return end
	if isUIOpen then return end
	local equippedTool = player.Character and player.Character:FindFirstChildOfClass("Tool")
	if not equippedTool then
		showNotification("Weapon not ready", Color3.fromRGB(255, 100, 100), 2)
		return
	end
	local ok, result = pcall(function()
		return upgradeRF:InvokeServer(equippedTool)
	end)
	if not ok then
		showNotification("Upgrade system error", Color3.fromRGB(255, 100, 100), 2)
		return
	end
	if result.success then
		showUpgradeUI(equippedTool, result)
	else
		showNotification(result.message, Color3.fromRGB(255, 100, 100), 3)
	end
end)