-- GameSettingsUI.lua (LocalScript)
-- StarterGui/GameSettingsUI.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvents
local UpdateSettingsEvent = ReplicatedStorage.RemoteEvents:WaitForChild("UpdateSettingsEvent")
local LoadSettingsEvent = ReplicatedStorage.RemoteEvents:WaitForChild("LoadSettingsEvent")
local BindableEvents = ReplicatedStorage.BindableEvents

-- #region Initial Setup and Variables

local currentSettings = {
	sound = { enabled = true, sfxVolume = 0.8 },
	controls = { fireControlType = "FireButton" },
	gameplay = { shadows = true },
	hud = {}
}
local temporarySettings = {}
local defaultHudSettings = {} -- To store original, factory-default positions
local layoutEditorOriginalVisibility = {} -- To store visibility before entering layout mode

-- Custom deep copy function to handle Roblox data types like UDim2
local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		elseif typeof(v) == "UDim2" then
			copy[k] = UDim2.new(v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
		else
			copy[k] = v
		end
	end
	return copy
end

local AudioManager = {}
AudioManager.SFX = {}
function AudioManager:SetSFXVolume(volume) for _,s in ipairs(self.SFX) do if s and s:IsA("Sound") then s.Volume=volume end end end
task.spawn(function()
	task.wait(5)
	for _, sound in ipairs(game:GetService("SoundService"):GetDescendants()) do
		if sound:IsA("Sound") and sound.Name ~= "Music" then -- Exclude music
			table.insert(AudioManager.SFX, sound)
		end
	end
end)

local screenGui = Instance.new("ScreenGui", playerGui); screenGui.Name = "GameSettingsUI"; screenGui.ResetOnSpawn = false; screenGui.IgnoreGuiInset = true
local screenGui2 = Instance.new("ScreenGui", playerGui); screenGui2.Name = "GameSettingsUI2"; screenGui2.ResetOnSpawn = false; screenGui2.IgnoreGuiInset = false

local TARGET_BUTTON_NAMES = {
	"MobileReloadButton", "MobileAimButton", "MobileSprintButton", "HPContainer", "StaminaContainer",
	"AmmoContainer", "ElementActivatePrompt", "PerkDisplayContainer", "WaveContainer", "BloodContainer", "BossTimerContainer"
}
local hudElements = {}

local gearBtn = Instance.new("ImageButton", screenGui2); gearBtn.Name = "GameSettingsButton"; gearBtn.Size = UDim2.new(0.055, 0, 0.0, 0); gearBtn.Position = UDim2.new(0.01, 0, 0.01, 0); gearBtn.BackgroundTransparency = 1; gearBtn.Image = "rbxassetid://128019335135588"; gearBtn.ZIndex = 100
Instance.new("UIAspectRatioConstraint", gearBtn).AspectType = Enum.AspectType.ScaleWithParentSize
Instance.new("UICorner", gearBtn).CornerRadius = UDim.new(1, 0)

local overlay = Instance.new("Frame", screenGui); overlay.Name = "GameSettingsOverlay"; overlay.Visible = false; overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0); overlay.BackgroundTransparency = 0.35; overlay.Size = UDim2.new(1, 0, 1, 0); overlay.ZIndex = 99
-- #endregion

-- #region Settings Panel UI
local settingsPanel = Instance.new("Frame", overlay); settingsPanel.Name = "SettingsPanel"; settingsPanel.Size = UDim2.new(0, 500, 0, 400); settingsPanel.Position = UDim2.new(0.5, 0, 0.5, 0); settingsPanel.AnchorPoint = Vector2.new(0.5, 0.5); settingsPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 50); Instance.new("UICorner", settingsPanel).CornerRadius = UDim.new(0, 12)
local titleLabel = Instance.new("TextLabel", settingsPanel); titleLabel.Name = "Title"; titleLabel.Size = UDim2.new(1, 0, 0, 50); titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40); titleLabel.Text = "Game Settings"; titleLabel.Font = Enum.Font.GothamBold; titleLabel.TextColor3 = Color3.new(1, 1, 1); titleLabel.TextSize = 24; Instance.new("UICorner", titleLabel).CornerRadius = UDim.new(0, 12)
local contentContainer = Instance.new("Frame", settingsPanel); contentContainer.Name = "Content"; contentContainer.Size = UDim2.new(1, -40, 1, -110); contentContainer.Position = UDim2.new(0, 20, 0, 60); contentContainer.BackgroundTransparency = 1; local listLayout = Instance.new("UIListLayout", contentContainer); listLayout.Padding = UDim.new(0, 15); listLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Sound Section
local soundSection = Instance.new("Frame", contentContainer); soundSection.Name = "SoundSection"; soundSection.Size = UDim2.new(1, 0, 0, 70); soundSection.BackgroundTransparency = 1; soundSection.LayoutOrder = 1
local soundTitle = Instance.new("TextLabel", soundSection); soundTitle.Name = "SoundTitle"; soundTitle.Size = UDim2.new(1, 0, 0, 20); soundTitle.Text = "Sound Settings"; soundTitle.Font = Enum.Font.GothamBold; soundTitle.TextColor3 = Color3.fromRGB(200, 200, 200); soundTitle.TextXAlignment = Enum.TextXAlignment.Left; soundTitle.BackgroundTransparency = 1
local enableSoundCheckbox = Instance.new("TextButton", soundSection); enableSoundCheckbox.Name = "EnableSoundCheckbox"; enableSoundCheckbox.Size = UDim2.new(1, 0, 0, 25); enableSoundCheckbox.BackgroundColor3 = Color3.fromRGB(50, 50, 60); enableSoundCheckbox.Font = Enum.Font.Gotham; enableSoundCheckbox.TextColor3 = Color3.new(1, 1, 1); enableSoundCheckbox.TextXAlignment = Enum.TextXAlignment.Left
local soundSlidersContainer = Instance.new("Frame", soundSection); soundSlidersContainer.Name = "SoundSliders"; soundSlidersContainer.Size = UDim2.new(1, 0, 1, -30); soundSlidersContainer.Position = UDim2.new(0, 0, 0, 30); soundSlidersContainer.BackgroundTransparency = 1; Instance.new("UIListLayout", soundSlidersContainer).Padding = UDim.new(0, 5)

-- Controls Section
local controlsSection = Instance.new("Frame", contentContainer)
controlsSection.Name = "ControlsSection"
controlsSection.Size = UDim2.new(1, 0, 0, 60)
controlsSection.BackgroundTransparency = 1
controlsSection.LayoutOrder = 2

local controlsTitle = Instance.new("TextLabel", controlsSection)
controlsTitle.Name = "ControlsTitle"
controlsTitle.Size = UDim2.new(1, 0, 0, 20)
controlsTitle.Text = "Mobile Controls"
controlsTitle.Font = Enum.Font.GothamBold
controlsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
controlsTitle.TextXAlignment = Enum.TextXAlignment.Left
controlsTitle.BackgroundTransparency = 1

local fireControlButtons = Instance.new("Frame", controlsSection)
fireControlButtons.Name = "FireControlButtons"
fireControlButtons.Size = UDim2.new(1, 0, 0, 30)
fireControlButtons.Position = UDim2.new(0, 0, 0, 25)
fireControlButtons.BackgroundTransparency = 1
local fireControlLayout = Instance.new("UIListLayout", fireControlButtons)
fireControlLayout.FillDirection = Enum.FillDirection.Horizontal
fireControlLayout.Padding = UDim.new(0, 10)

local fireButtonOption = Instance.new("TextButton", fireControlButtons)
fireButtonOption.Name = "FireButtonOption"
fireButtonOption.Size = UDim2.new(0, 120, 1, 0)
fireButtonOption.BackgroundColor3 = Color3.fromRGB(80, 80, 95)
fireButtonOption.Text = "Fire Button"
fireButtonOption.Font = Enum.Font.Gotham
fireButtonOption.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", fireButtonOption).CornerRadius = UDim.new(0, 6)

local doubleTapOption = Instance.new("TextButton", fireControlButtons)
doubleTapOption.Name = "DoubleTapOption"
doubleTapOption.Size = UDim2.new(0, 120, 1, 0)
doubleTapOption.BackgroundColor3 = Color3.fromRGB(80, 80, 95)
doubleTapOption.Text = "Double Tap"
doubleTapOption.Font = Enum.Font.Gotham
doubleTapOption.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", doubleTapOption).CornerRadius = UDim.new(0, 6)

-- HUD Section
local hudSection = Instance.new("Frame", contentContainer); hudSection.Name = "HUDSection"; hudSection.Size = UDim2.new(1, 0, 0, 60); hudSection.BackgroundTransparency = 1; hudSection.LayoutOrder = 3
local hudTitle = Instance.new("TextLabel", hudSection); hudTitle.Name = "HUDTitle"; hudTitle.Size = UDim2.new(1, 0, 0, 20); hudTitle.Text = "HUD Customization"; hudTitle.Font = Enum.Font.GothamBold; hudTitle.TextColor3 = Color3.fromRGB(200, 200, 200); hudTitle.TextXAlignment = Enum.TextXAlignment.Left; hudTitle.BackgroundTransparency = 1
local customizeHudButton = Instance.new("TextButton", hudSection); customizeHudButton.Name = "CustomizeHudButton"; customizeHudButton.Size = UDim2.new(1, 0, 0, 30); customizeHudButton.Position = UDim2.new(0,0,0,25); customizeHudButton.BackgroundColor3 = Color3.fromRGB(80, 80, 95); customizeHudButton.Text = "Customize Layout"; customizeHudButton.Font = Enum.Font.Gotham; customizeHudButton.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", customizeHudButton).CornerRadius = UDim.new(0, 6)

-- Gameplay Section
local gameplaySection = Instance.new("Frame", contentContainer); gameplaySection.Name = "GameplaySection"; gameplaySection.Size = UDim2.new(1, 0, 0, 60); gameplaySection.BackgroundTransparency = 1; gameplaySection.LayoutOrder = 4
local gameplayTitle = Instance.new("TextLabel", gameplaySection); gameplayTitle.Name = "GameplayTitle"; gameplayTitle.Size = UDim2.new(1, 0, 0, 20); gameplayTitle.Text = "Gameplay Settings"; gameplayTitle.Font = Enum.Font.GothamBold; gameplayTitle.TextColor3 = Color3.fromRGB(200, 200, 200); gameplayTitle.TextXAlignment = Enum.TextXAlignment.Left; gameplayTitle.BackgroundTransparency = 1
local enableShadowsCheckbox = Instance.new("TextButton", gameplaySection); enableShadowsCheckbox.Name = "EnableShadowsCheckbox"; enableShadowsCheckbox.Size = UDim2.new(1, 0, 0, 25); enableShadowsCheckbox.Position = UDim2.new(0,0,0,25); enableShadowsCheckbox.BackgroundColor3 = Color3.fromRGB(50, 50, 60); enableShadowsCheckbox.Font = Enum.Font.Gotham; enableShadowsCheckbox.TextColor3 = Color3.new(1, 1, 1); enableShadowsCheckbox.TextXAlignment = Enum.TextXAlignment.Left

-- Main Action Buttons
local actionButtonContainer = Instance.new("Frame", settingsPanel); actionButtonContainer.Name = "ActionButtonContainer"; actionButtonContainer.Size = UDim2.new(1, 0, 0, 50); actionButtonContainer.AnchorPoint = Vector2.new(0.5, 1); actionButtonContainer.Position = UDim2.new(0.5, 0, 1, 0); actionButtonContainer.BackgroundTransparency = 1; actionButtonContainer.ZIndex = 101; local actionListLayout = Instance.new("UIListLayout", actionButtonContainer); actionListLayout.FillDirection = Enum.FillDirection.Horizontal; actionListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; actionListLayout.Padding = UDim.new(0, 20)
local btnSimpan = Instance.new("TextButton", actionButtonContainer); btnSimpan.Name = "SaveBtn"; btnSimpan.Size = UDim2.new(0, 120, 0, 40); btnSimpan.Text = "Simpan"; btnSimpan.Font = Enum.Font.GothamBold; btnSimpan.BackgroundColor3 = Color3.fromRGB(0, 170, 90); btnSimpan.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", btnSimpan).CornerRadius = UDim.new(0, 8)
local btnBatal = Instance.new("TextButton", actionButtonContainer); btnBatal.Name = "CancelBtn"; btnBatal.Size = UDim2.new(0, 120, 0, 40); btnBatal.Text = "Batal"; btnBatal.Font = Enum.Font.GothamBold; btnBatal.BackgroundColor3 = Color3.fromRGB(170, 60, 60); btnBatal.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", btnBatal).CornerRadius = UDim.new(0, 8)
-- #endregion

-- #region Layout Editor UI
local layoutEditorOverlay = Instance.new("Frame", overlay); layoutEditorOverlay.Name = "LayoutEditorOverlay"; layoutEditorOverlay.Visible = false; layoutEditorOverlay.Size = UDim2.new(1,0,1,0); layoutEditorOverlay.BackgroundTransparency = 1; layoutEditorOverlay.ZIndex = 100
local layoutActionButtonContainer = Instance.new("Frame", layoutEditorOverlay); layoutActionButtonContainer.Name = "LayoutActionButtonContainer"; layoutActionButtonContainer.Size = UDim2.new(1, 0, 0, 50); layoutActionButtonContainer.AnchorPoint = Vector2.new(0.5, 1); layoutActionButtonContainer.Position = UDim2.new(0.5, 0, 1, -20); layoutActionButtonContainer.BackgroundTransparency = 1; local layoutActionListLayout = Instance.new("UIListLayout", layoutActionButtonContainer); layoutActionListLayout.FillDirection = Enum.FillDirection.Horizontal; layoutActionListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; layoutActionListLayout.Padding = UDim.new(0, 20)
local btnSimpanLayout = Instance.new("TextButton", layoutActionButtonContainer); btnSimpanLayout.Name = "SaveLayoutBtn"; btnSimpanLayout.Size = UDim2.new(0, 120, 0, 40); btnSimpanLayout.Text = "Simpan Layout"; btnSimpanLayout.Font = Enum.Font.GothamBold; btnSimpanLayout.BackgroundColor3 = Color3.fromRGB(0, 170, 90); btnSimpanLayout.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", btnSimpanLayout).CornerRadius = UDim.new(0, 8)
local btnDefaultLayout = Instance.new("TextButton", layoutActionButtonContainer); btnDefaultLayout.Name = "DefaultLayoutBtn"; btnDefaultLayout.Size = UDim2.new(0, 120, 0, 40); btnDefaultLayout.Text = "Default"; btnDefaultLayout.Font = Enum.Font.GothamBold; btnDefaultLayout.BackgroundColor3 = Color3.fromRGB(100, 100, 115); btnDefaultLayout.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", btnDefaultLayout).CornerRadius = UDim.new(0, 8)
local btnBatalLayout = Instance.new("TextButton", layoutActionButtonContainer); btnBatalLayout.Name = "CancelLayoutBtn"; btnBatalLayout.Size = UDim2.new(0, 120, 0, 40); btnBatalLayout.Text = "Batal"; btnBatalLayout.Font = Enum.Font.GothamBold; btnBatalLayout.BackgroundColor3 = Color3.fromRGB(170, 60, 60); btnBatalLayout.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", btnBatalLayout).CornerRadius = UDim.new(0, 8)
-- #endregion

-- #region Core Logic
local function createSlider(name, parent)
	local container = Instance.new("Frame", parent); container.Name = name .. "Container"; container.Size = UDim2.new(1, 0, 0, 25); container.BackgroundTransparency = 1
	local label = Instance.new("TextLabel", container); label.Name = "Label"; label.Size = UDim2.new(0.3, 0, 1, 0); label.Text = name; label.Font = Enum.Font.Gotham; label.TextColor3 = Color3.fromRGB(220, 220, 220); label.TextXAlignment = Enum.TextXAlignment.Left; label.BackgroundTransparency = 1
	local sliderFrame = Instance.new("Frame", container); sliderFrame.Name = "SliderFrame"; sliderFrame.Size = UDim2.new(0.7, 0, 1, 0); sliderFrame.Position = UDim2.new(0.3, 0, 0, 0); sliderFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	local sliderBar = Instance.new("Frame", sliderFrame); sliderBar.Name = "SliderBar"; sliderBar.Size = UDim2.new(0.5, 0, 1, 0); sliderBar.BackgroundColor3 = Color3.fromRGB(100, 120, 255)
	return container, sliderBar, sliderFrame
end
local sfxSlider, sfxSliderBar, sfxSliderFrame = createSlider("SFX", soundSlidersContainer)

local activeEditors = {}
function makeDraggable(frame)
	local dragging, dragStart, startPos, conn
	frame.InputBegan:Connect(function(input)
		if frame:GetAttribute("IsResizing") then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = Vector2.new(input.Position.X, input.Position.Y); startPos = frame.Position
			conn = UserInputService.InputChanged:Connect(function(cInput)
				if dragging and (cInput.UserInputType == Enum.UserInputType.MouseMovement or cInput.UserInputType == Enum.UserInputType.Touch) then
					local delta = Vector2.new(cInput.Position.X, cInput.Position.Y) - dragStart
					frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
				end
			end)
		end
	end)
	frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false; if conn then conn:Disconnect() end
		end
	end)
end

function makeResizable(frame)
	local handle = Instance.new("Frame", frame); handle.Name = "ResizeHandle"; handle.AnchorPoint = Vector2.new(1, 1); handle.Size = UDim2.new(0, 20, 0, 20); handle.Position = UDim2.new(1, 0, 1, 0); handle.BackgroundColor3 = Color3.new(1, 1, 1); handle.BackgroundTransparency = 0.2; handle.ZIndex = frame.ZIndex + 2; Instance.new("UICorner", handle).CornerRadius = UDim.new(0, 6)
	local resizing, startSize, startInputPos, conn
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true; frame:SetAttribute("IsResizing", true); startInputPos = Vector2.new(input.Position.X, input.Position.Y); startSize = frame.Size
			conn = UserInputService.InputChanged:Connect(function(cInput)
				if resizing and (cInput.UserInputType == Enum.UserInputType.MouseMovement or cInput.UserInputType == Enum.UserInputType.Touch) then
					local delta = Vector2.new(cInput.Position.X, cInput.Position.Y) - startInputPos
					frame.Size = UDim2.new(startSize.X.Scale, startSize.X.Offset + delta.X, startSize.Y.Scale, startSize.Y.Offset + delta.Y)
				end
			end)
		end
	end)
	handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = false; frame:SetAttribute("IsResizing", false); if conn then conn:Disconnect() end
		end
	end)
	return handle
end

function setLayoutEditorMode(enabled)
	settingsPanel.Visible = not enabled
	layoutEditorOverlay.Visible = enabled
	if enabled then
		layoutEditorOriginalVisibility = {}
	end
	for name, element in pairs(hudElements) do
		if enabled then
			layoutEditorOriginalVisibility[name] = element.Visible
			element.Visible = true
			local ghost = Instance.new("Frame", element); ghost.Name = "EditGhost"; ghost.BackgroundTransparency = 1; ghost.Size = UDim2.new(1,0,1,0); ghost.ZIndex = element.ZIndex + 1; local stroke = Instance.new("UIStroke", ghost); stroke.Thickness = 2; stroke.Color = Color3.fromRGB(80, 200, 255)
			makeDraggable(element)
			local handle = makeResizable(element)
			activeEditors[name] = { ghost = ghost, handle = handle }
		else
			if activeEditors[name] then
				activeEditors[name].ghost:Destroy()
				activeEditors[name].handle:Destroy()
				activeEditors[name] = nil
			end
			if layoutEditorOriginalVisibility[name] ~= nil then
				element.Visible = layoutEditorOriginalVisibility[name]
			end
		end
	end
end

function updateUiFromSettings(settings)
	local sound = settings.sound
	local controls = settings.controls
	local gameplay = settings.gameplay

	enableShadowsCheckbox.Text = gameplay and gameplay.shadows and "  ✓  Enable Shadows" or "     Enable Shadows"

	enableSoundCheckbox.Text = sound.enabled and "  ✓  Enable Sound" or "     Enable Sound"
	soundSlidersContainer.Visible = sound.enabled
	sfxSliderBar.Size = UDim2.new(sound.sfxVolume, 0, 1, 0)

	-- Update controls UI
	if controls then
		local isFireButton = controls.fireControlType == "FireButton"
		fireButtonOption.BackgroundColor3 = isFireButton and Color3.fromRGB(100, 120, 255) or Color3.fromRGB(80, 80, 95)
		doubleTapOption.BackgroundColor3 = not isFireButton and Color3.fromRGB(100, 120, 255) or Color3.fromRGB(80, 80, 95)
	end

	controlsSection.Visible = UserInputService.TouchEnabled
end

function applySettings(settings)
	local sound = settings.sound
	local controls = settings.controls
	local gameplay = settings.gameplay

	-- Terapkan pengaturan bayangan
	if gameplay and gameplay.shadows ~= nil then
		game.Lighting.GlobalShadows = gameplay.shadows
	end

	local globalVolume = sound.enabled and 1 or 0
	AudioManager:SetSFXVolume(sound.sfxVolume * globalVolume)

	if controls then
		player:SetAttribute("FireControlType", controls.fireControlType)
	end

	for name, hudSetting in pairs(settings.hud) do
		local element = hudElements[name]
		if element and hudSetting and hudSetting.pos and hudSetting.size then
			element.Position = hudSetting.pos
			element.Size = hudSetting.size
		end
	end

	-- Refresh mobile buttons visibility after applying settings
	local refreshMobileButtonsEvent = BindableEvents:FindFirstChild("RefreshMobileButtons")
	if refreshMobileButtonsEvent then
		refreshMobileButtonsEvent:Fire()
	end
end

local function initializeHudDefaults()
	for _, name in ipairs(TARGET_BUTTON_NAMES) do
		local element = playerGui:FindFirstChild(name, true)
		if element then
			hudElements[name] = element
			if not defaultHudSettings[name] then
				defaultHudSettings[name] = {
					pos = element.Position,
					size = element.Size
				}
			end
			if not currentSettings.hud[name] then
				currentSettings.hud[name] = {
					pos = element.Position,
					size = element.Size
				}
			end
		end
	end
end

function setSettingsMode(enabled)
	overlay.Visible = enabled
	gearBtn.Visible = not enabled
	settingsPanel.Visible = enabled
	layoutEditorOverlay.Visible = false
	if enabled then
		temporarySettings = deepCopy(currentSettings)
		updateUiFromSettings(temporarySettings)
		-- applySettings(temporarySettings) -- Don't apply on open, only on change or save
	end
end

local function handleSliderInput(sliderFrame, bar, updateFunc)
	local function updateValue(input)
		local size = sliderFrame.AbsoluteSize
		local inputPos = Vector2.new(input.Position.X, input.Position.Y)
		local pos = inputPos - sliderFrame.AbsolutePosition
		local p = math.clamp(pos.X / size.X, 0, 1)
		bar.Size = UDim2.new(p, 0, 1, 0)
		updateFunc(p)
		applySettings(temporarySettings)
	end
	sliderFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			updateValue(input)
			local conn, e_conn
			conn = UserInputService.InputChanged:Connect(function(ci)
				if ci.UserInputType == Enum.UserInputType.MouseMovement or ci.UserInputType == Enum.UserInputType.Touch then
					updateValue(ci)
				end
			end)
			e_conn = UserInputService.InputEnded:Connect(function(ei)
				if ei.UserInputType == input.UserInputType then
					conn:Disconnect()
					e_conn:Disconnect()
				end
			end)
		end
	end)
end
handleSliderInput(sfxSliderFrame, sfxSliderBar, function(p) temporarySettings.sound.sfxVolume = p end)

enableSoundCheckbox.MouseButton1Click:Connect(function() temporarySettings.sound.enabled = not temporarySettings.sound.enabled; updateUiFromSettings(temporarySettings); applySettings(temporarySettings) end)

enableShadowsCheckbox.MouseButton1Click:Connect(function()
	if not temporarySettings.gameplay then temporarySettings.gameplay = { shadows = true } end
	temporarySettings.gameplay.shadows = not temporarySettings.gameplay.shadows
	updateUiFromSettings(temporarySettings)
	applySettings(temporarySettings)
end)

fireButtonOption.MouseButton1Click:Connect(function()
	temporarySettings.controls.fireControlType = "FireButton"
	updateUiFromSettings(temporarySettings)
	applySettings(temporarySettings)
end)

doubleTapOption.MouseButton1Click:Connect(function()
	temporarySettings.controls.fireControlType = "DoubleTap"
	updateUiFromSettings(temporarySettings)
	applySettings(temporarySettings)
end)


-- Function to serialize settings before sending to server
local function serializeSettings(settings)
	local serialized = { sound = settings.sound, controls = settings.controls, hud = {} }
	for name, data in pairs(settings.hud) do
		serialized.hud[name] = {
			pos = { X = { Scale = data.pos.X.Scale, Offset = data.pos.X.Offset }, Y = { Scale = data.pos.Y.Scale, Offset = data.pos.Y.Offset } },
			size = { X = { Scale = data.size.X.Scale, Offset = data.size.X.Offset }, Y = { Scale = data.size.Y.Scale, Offset = data.size.Y.Offset } }
		}
	end
	return serialized
end

-- Button Actions
gearBtn.MouseButton1Click:Connect(function() setSettingsMode(true) end)
btnBatal.MouseButton1Click:Connect(function() applySettings(currentSettings); setSettingsMode(false) end)
btnSimpan.MouseButton1Click:Connect(function()
	currentSettings=deepCopy(temporarySettings)
	UpdateSettingsEvent:FireServer(serializeSettings(currentSettings))
	applySettings(currentSettings)
	setSettingsMode(false)
end)
customizeHudButton.MouseButton1Click:Connect(function() setLayoutEditorMode(true) end)
btnBatalLayout.MouseButton1Click:Connect(function()
	for name, element in pairs(hudElements) do
		if temporarySettings.hud[name] then
			element.Position = temporarySettings.hud[name].pos
			element.Size = temporarySettings.hud[name].size
		end
	end
	setLayoutEditorMode(false)
end)
btnSimpanLayout.MouseButton1Click:Connect(function()
	for name, element in pairs(hudElements) do
		temporarySettings.hud[name].pos = element.Position
		temporarySettings.hud[name].size = element.Size
	end
	setLayoutEditorMode(false)
end)
btnDefaultLayout.MouseButton1Click:Connect(function()
	for name, element in pairs(hudElements) do
		if defaultHudSettings[name] then
			element.Position = defaultHudSettings[name].pos
			element.Size = defaultHudSettings[name].size
		end
	end
end)


LoadSettingsEvent.OnClientEvent:Connect(function(serverSettings)
	initializeHudDefaults()
	if serverSettings and serverSettings.sound then
		for k, v in pairs(serverSettings.sound) do currentSettings.sound[k] = v end
	end
	if serverSettings and serverSettings.controls then
		currentSettings.controls = serverSettings.controls
	end
	if serverSettings and serverSettings.gameplay then
		currentSettings.gameplay = serverSettings.gameplay
	end
	if serverSettings and serverSettings.hud then
		for name, data in pairs(serverSettings.hud) do
			if currentSettings.hud[name] then
				currentSettings.hud[name].pos = data.pos
				currentSettings.hud[name].size = data.size
			end
		end
	end
	applySettings(currentSettings)
	updateUiFromSettings(currentSettings)
end)

task.wait(1)
initializeHudDefaults()
applySettings(currentSettings)
updateUiFromSettings(currentSettings)
-- #endregion
