-- StartUI.lua (LocalScript)
-- Path: StarterGui/StartUI.lua
-- Script Place: ACT 1: Village

local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

local SELECT_ACTION = "StartConfirm_Arrows"

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local StartGameEvent = RemoteEvents:WaitForChild("StartGameEvent")
local PlayerCountEvent = RemoteEvents:WaitForChild("PlayerCountEvent")
local OpenStartUIEvent = RemoteEvents:WaitForChild("OpenStartUIEvent")
local ReadyCountEvent = RemoteEvents:WaitForChild("ReadyCountEvent")
local StartVoteCountdownEvent = RemoteEvents:WaitForChild("StartVoteCountdownEvent")
local StartVoteCanceledEvent  = RemoteEvents:WaitForChild("StartVoteCanceledEvent")
local CancelStartVoteEvent = RemoteEvents:WaitForChild("CancelStartVoteEvent")
local GameSettingsUpdateEvent = RemoteEvents:WaitForChild("GameSettingsUpdateEvent")

-- GUI utama popup start
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StartUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = true
screenGui.Parent = playerGui

-- Background blur effect
local blurEffect = Instance.new("BlurEffect")
blurEffect.Size = 0
blurEffect.Parent = game:GetService("Lighting")

local tweenBlurIn = TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size = 10})
local tweenBlurOut = TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size = 0})

-- Tentukan ukuran frame berdasarkan platform
local frameSize = UIS.TouchEnabled and UDim2.new(0.6, 0, 0.45, 0) or UDim2.new(0.4, 0, 0.35, 0)
local framePosition = UIS.TouchEnabled and UDim2.new(0.2, 0, 0.275, 0) or UDim2.new(0.3, 0, 0.325, 0)

local frame = Instance.new("Frame")
frame.Size = frameSize
frame.Position = framePosition
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = screenGui

-- Gradient background
local gradient = Instance.new("UIGradient")
gradient.Rotation = 90
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 30)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 60))
}
gradient.Parent = frame

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 16)
UICorner.Parent = frame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(100, 100, 180)
UIStroke.Thickness = 3
UIStroke.Parent = frame

-- Glow effect
local glow = Instance.new("ImageLabel")
glow.Name = "GlowEffect"
glow.Image = "rbxassetid://4996891970"
glow.ImageColor3 = Color3.fromRGB(40, 60, 180)
glow.ScaleType = Enum.ScaleType.Slice
glow.SliceCenter = Rect.new(49, 49, 450, 450)
glow.BackgroundTransparency = 1
glow.Size = UDim2.new(1, 40, 1, 40)
glow.Position = UDim2.new(0, -20, 0, -20)
glow.ZIndex = -1
glow.Parent = frame

local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(1, 0, 0.2, 0)
label.BackgroundTransparency = 1
label.TextScaled = true
label.TextColor3 = Color3.new(1, 1, 1)
label.Text = "START GAME"
label.Font = Enum.Font.GothamBlack
label.Parent = frame

-- NEW: Label untuk menampilkan jumlah pemain
local playerCountLabel = Instance.new("TextLabel")
playerCountLabel.Size = UDim2.new(1, 0, 0.1, 0)
playerCountLabel.Position = UDim2.new(0, 0, 0.2, 0)
playerCountLabel.BackgroundTransparency = 1
playerCountLabel.TextScaled = true
playerCountLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
playerCountLabel.Text = "Players: 1"
playerCountLabel.Font = Enum.Font.GothamBold
playerCountLabel.Parent = frame

-- NEW: Label untuk mode permainan
local gameModeLabel = Instance.new("TextLabel")
gameModeLabel.Size = UDim2.new(1, 0, 0.1, 0)
gameModeLabel.Position = UDim2.new(0, 0, 0.3, 0)
gameModeLabel.BackgroundTransparency = 1
gameModeLabel.TextScaled = true
gameModeLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
gameModeLabel.Text = "Mode: Loading..."
gameModeLabel.Font = Enum.Font.GothamBold
gameModeLabel.Parent = frame

-- NEW: Label untuk kesulitan
local difficultyLabel = Instance.new("TextLabel")
difficultyLabel.Size = UDim2.new(1, 0, 0.1, 0)
difficultyLabel.Position = UDim2.new(0, 0, 0.35, 0)
difficultyLabel.BackgroundTransparency = 1
difficultyLabel.TextScaled = true
difficultyLabel.TextColor3 = Color3.fromRGB(255, 220, 180)
difficultyLabel.Text = "Difficulty: Loading..."
difficultyLabel.Font = Enum.Font.GothamBold
difficultyLabel.Parent = frame

-- Label progres ready
local readyCountLabel = Instance.new("TextLabel")
readyCountLabel.Size = UDim2.new(1, 0, 0.1, 0)
readyCountLabel.Position = UDim2.new(0, 0, 0.4, 0)
readyCountLabel.BackgroundTransparency = 1
readyCountLabel.TextScaled = true
readyCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
readyCountLabel.Text = "Ready: 0/0"
readyCountLabel.Font = Enum.Font.GothamBold
readyCountLabel.Parent = frame

-- Label countdown waktu voting
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Size = UDim2.new(1, 0, 0.1, 0)
countdownLabel.Position = UDim2.new(0, 0, 0.5, 0)
countdownLabel.BackgroundTransparency = 1
countdownLabel.TextScaled = true
countdownLabel.TextColor3 = Color3.fromRGB(255, 200, 150)
countdownLabel.Font = Enum.Font.GothamBold
countdownLabel.Text = "Time left: 30s"
countdownLabel.Parent = frame

-- Button container
local buttonContainer = Instance.new("Frame")
buttonContainer.Size = UDim2.new(0.9, 0, 0.3, 0)
buttonContainer.Position = UDim2.new(0.05, 0, 0.65, 0)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = frame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.FillDirection = Enum.FillDirection.Horizontal
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
uiListLayout.Padding = UDim.new(0.05, 0)
uiListLayout.Parent = buttonContainer

local yesBtn = Instance.new("TextButton")
yesBtn.Size = UDim2.new(0.45, 0, 1, 0)
yesBtn.Text = "YES"
yesBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
yesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
yesBtn.TextScaled = true
yesBtn.Font = Enum.Font.GothamBlack
yesBtn.AutoButtonColor = false
yesBtn.Parent = buttonContainer

local yesCorner = Instance.new("UICorner")
yesCorner.CornerRadius = UDim.new(0, 12)
yesCorner.Parent = yesBtn

local yesStroke = Instance.new("UIStroke")
yesStroke.Color = Color3.fromRGB(100, 255, 100)
yesStroke.Thickness = 2
yesStroke.Parent = yesBtn

local noBtn = Instance.new("TextButton")
noBtn.Size = UDim2.new(0.45, 0, 1, 0)
noBtn.Text = "NO"
noBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
noBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
noBtn.TextScaled = true
noBtn.Font = Enum.Font.GothamBlack
noBtn.AutoButtonColor = false
noBtn.Parent = buttonContainer

local noCorner = Instance.new("UICorner")
noCorner.CornerRadius = UDim.new(0, 12)
noCorner.Parent = noBtn

local noStroke = Instance.new("UIStroke")
noStroke.Color = Color3.fromRGB(255, 100, 100)
noStroke.Thickness = 2
noStroke.Parent = noBtn
-- === Keyboard selection (desktop) ===
local selectedIdx = 1 -- 1 = YES, 2 = NO

local function setSelected(i)
	selectedIdx = math.clamp(i, 1, 2)
	-- Tebalkan stroke + sedikit scale untuk highlight
	if selectedIdx == 1 then
		yesStroke.Thickness = 4
		noStroke.Thickness = 2
		TweenService:Create(yesBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.48, 0, 1.05, 0)}):Play()
		TweenService:Create(noBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.45, 0, 1, 0)}):Play()
	else
		yesStroke.Thickness = 2
		noStroke.Thickness = 4
		TweenService:Create(yesBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.45, 0, 1, 0)}):Play()
		TweenService:Create(noBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.48, 0, 1.05, 0)}):Play()
	end
end

-- Hover effects for buttons
local function createButtonHoverEffect(button, hoverColor)
	local originalColor = button.BackgroundColor3
	local originalStroke = button.UIStroke.Color

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
		TweenService:Create(button.UIStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 255, 255)}):Play()
		TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.new(0.48, 0, 1.05, 0)}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
		TweenService:Create(button.UIStroke, TweenInfo.new(0.2), {Color = originalStroke}):Play()
		TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.new(0.45, 0, 1, 0)}):Play()
	end)

	button.MouseButton1Down:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.new(0.43, 0, 0.95, 0)}):Play()
	end)

	button.MouseButton1Up:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.new(0.45, 0, 1, 0)}):Play()
	end)
end

createButtonHoverEffect(yesBtn, Color3.fromRGB(60, 220, 60))
createButtonHoverEffect(noBtn, Color3.fromRGB(220, 60, 60))

-- Desktop: Prompt untuk tekan E
local desktopPrompt = Instance.new("TextLabel")
desktopPrompt.Size = UDim2.new(0.4, 0, 0.08, 0)
desktopPrompt.Position = UDim2.new(0.3, 0, 0.5, 0)
desktopPrompt.BackgroundTransparency = 1
desktopPrompt.Text = "PRESS [E] TO START"
desktopPrompt.TextColor3 = Color3.fromRGB(255, 255, 255)
desktopPrompt.TextScaled = true
desktopPrompt.Font = Enum.Font.GothamBlack
desktopPrompt.Visible = not UIS.TouchEnabled
desktopPrompt.Parent = screenGui

-- Animate the prompt
if not UIS.TouchEnabled then
	spawn(function()
		while true do
			TweenService:Create(desktopPrompt, TweenInfo.new(0.8), {TextTransparency = 0.3}):Play()
			wait(0.9)
			TweenService:Create(desktopPrompt, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
			wait(0.9)
		end
	end)
end

-- Mobile: Tombol Start di tengah layar
local mobileStartBtn = Instance.new("TextButton")
mobileStartBtn.Size = UDim2.new(0.3, 0, 0.12, 0) -- Diperbesar untuk mobile
mobileStartBtn.Position = UDim2.new(0.35, 0, 0.5, 0)
mobileStartBtn.Text = "START"
mobileStartBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 220)
mobileStartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mobileStartBtn.TextScaled = true
mobileStartBtn.Visible = UIS.TouchEnabled
mobileStartBtn.AutoButtonColor = false
mobileStartBtn.Parent = screenGui

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 16)
startCorner.Parent = mobileStartBtn

local startStroke = Instance.new("UIStroke")
startStroke.Color = Color3.fromRGB(150, 180, 255)
startStroke.Thickness = 3
startStroke.Parent = mobileStartBtn

-- Hover effect for mobile button
mobileStartBtn.MouseEnter:Connect(function()
	TweenService:Create(mobileStartBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 120, 240)}):Play()
	TweenService:Create(mobileStartBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.32, 0, 0.13, 0)}):Play()
end)

mobileStartBtn.MouseLeave:Connect(function()
	TweenService:Create(mobileStartBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 100, 220)}):Play()
	TweenService:Create(mobileStartBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.3, 0, 0.12, 0)}):Play()
end)

-- Part
local startPart = workspace:WaitForChild("StartPart")

-- NEW: Track if game has started
local gameStarted = false

local function hideFrame()
	local tweenOut = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.1, 0, 0.1, 0),
		Position = UDim2.new(0.45, 0, 0.45, 0)
	})

	tweenOut:Play()
	-- Lepas binding supaya kontrol player normal kembali
	ContextActionService:UnbindAction(SELECT_ACTION)
	tweenBlurOut:Play()

	tweenOut.Completed:Connect(function()
		frame.Visible = false
	end)
end

-- Update Game Settings from server
GameSettingsUpdateEvent.OnClientEvent:Connect(function(settings)
	if gameModeLabel and settings.gameMode then
		gameModeLabel.Text = string.format("Mode: %s", settings.gameMode)
	end
	if difficultyLabel and settings.difficulty then
		difficultyLabel.Text = string.format("Difficulty: %s", settings.difficulty)
	end
end)

-- Progres ready dari server
ReadyCountEvent.OnClientEvent:Connect(function(ready, total)
	readyCountLabel.Text = string.format("Ready: %d/%d", ready, total)
	-- animasi kecil
	TweenService:Create(readyCountLabel, TweenInfo.new(0.2), {TextTransparency = 0.5}):Play()
	task.wait(0.1)
	TweenService:Create(readyCountLabel, TweenInfo.new(0.2), {TextTransparency = 0}):Play()

	-- Jika semua sudah siap, tutup UI dan kunci prompt
	if ready >= total and total > 0 then
		gameStarted = true
		hideFrame()
		desktopPrompt.Visible = false
		mobileStartBtn.Visible = false
	end
end)

-- Update countdown dari server
StartVoteCountdownEvent.OnClientEvent:Connect(function(timeLeft)
	if countdownLabel and frame.Visible then
		countdownLabel.Text = string.format("Time left: %ds", timeLeft)
	end
end)

-- NEW: terima nama pembatal & tampilkan notifikasi
StartVoteCanceledEvent.OnClientEvent:Connect(function(cancelerName)
	hideFrame()

	-- Notifikasi ke player lokal
	if cancelerName and cancelerName ~= "" then
		local msg = ("Voting canceled by %s"):format(cancelerName)
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "Start cancelled",
				Text = msg,
				Duration = 3
			})
		end)
		pcall(function()
			game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
				Text = "[SYSTEM] " .. msg,
				Color = Color3.fromRGB(255, 80, 80)
			})
		end)
	end

	-- tampilkan kembali prompt sesuai platform
	if not gameStarted then
		if UIS.TouchEnabled then
			mobileStartBtn.Visible = true
		else
			desktopPrompt.Visible = true
		end
	end
end)

local function handleStartArrows(_, inputState, input)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if not frame.Visible then
		return Enum.ContextActionResult.Pass
	end

	local kc = input.KeyCode
	if kc == Enum.KeyCode.Left or kc == Enum.KeyCode.Up then
		setSelected(1)
		return Enum.ContextActionResult.Sink
	elseif kc == Enum.KeyCode.Right or kc == Enum.KeyCode.Down then
		setSelected(2)
		return Enum.ContextActionResult.Sink
	elseif kc == Enum.KeyCode.Return or kc == Enum.KeyCode.KeypadEnter then
		if selectedIdx == 1 then
			-- aksi YES
			TweenService:Create(yesBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 255, 100)}):Play()
			StartGameEvent:FireServer()
		else
			-- aksi NO
			TweenService:Create(noBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}):Play()
			hideFrame()
			delay(0.3, function()
				if not gameStarted then
					if UIS.TouchEnabled then
						mobileStartBtn.Visible = true
					else
						desktopPrompt.Visible = true
					end
				end
			end)
		end
		return Enum.ContextActionResult.Sink
	end

	return Enum.ContextActionResult.Pass
end

-- Function to show frame with animation
local function showFrame()
	frame.Visible = true
	frame.Size = UDim2.new(0.1, 0, 0.1, 0)
	frame.Position = UDim2.new(0.45, 0, 0.45, 0)

	tweenBlurIn:Play()

	-- Tentukan ukuran dan posisi target berdasarkan platform
	local targetSize = UIS.TouchEnabled and UDim2.new(0.6, 0, 0.45, 0) or UDim2.new(0.4, 0, 0.35, 0)
	local targetPosition = UIS.TouchEnabled and UDim2.new(0.2, 0, 0.275, 0) or UDim2.new(0.3, 0, 0.325, 0)

	local tweenIn = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = targetSize,
		Position = targetPosition
	})
	tweenIn:Play()
	-- Aktifkan navigasi keyboard hanya di desktop
	if not UIS.TouchEnabled then
		setSelected(1) -- default fokus ke YES
		ContextActionService:BindActionAtPriority(
			SELECT_ACTION,
			handleStartArrows,
			false,
			Enum.ContextActionPriority.High.Value,
			Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.Up, Enum.KeyCode.Down,
			Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter
		)
	end
end

-- Jika server minta tampilkan UI ke semua pemain
OpenStartUIEvent.OnClientEvent:Connect(function()
	-- Reset label countdown saat sesi baru dibuka
	if countdownLabel then
		countdownLabel.Text = "Time left: 30s"
	end
	-- Jangan buka lagi kalau UI sudah terlihat
	if frame.Visible then return end
	if not gameStarted then
		showFrame()
	end
end)

-- Dari server saat waktu habis / voting dibatalkan
StartVoteCanceledEvent.OnClientEvent:Connect(function()
	hideFrame()
	-- tampilkan kembali prompt sesuai platform
	if not gameStarted then
		if UIS.TouchEnabled then
			mobileStartBtn.Visible = true
		else
			desktopPrompt.Visible = true
		end
	end
end)

-- Function to hide frame with animation

-- PC (Keyboard E)
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.E and not gameStarted and not frame.Visible then
		local char = player.Character or player.CharacterAdded:Wait()
		local hrp = char:WaitForChild("HumanoidRootPart")
		local dist = (hrp.Position - startPart.Position).Magnitude
		if dist < 10 then
			OpenStartUIEvent:FireServer()
			desktopPrompt.Visible = false -- Sembunyikan prompt E
		end
	end
end)

-- Mobile (tombol layar)
mobileStartBtn.MouseButton1Click:Connect(function()
	if not gameStarted then
		if frame.Visible then return end
		local char = player.Character or player.CharacterAdded:Wait()
		local hrp = char:WaitForChild("HumanoidRootPart")
		local dist = (hrp.Position - startPart.Position).Magnitude
		if dist < 10 then
			OpenStartUIEvent:FireServer()
			mobileStartBtn.Visible = false -- Sembunyikan tombol Start
		end
	end
end)

-- Ya / Tidak
yesBtn.MouseButton1Click:Connect(function()
	TweenService:Create(yesBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 255, 100)}):Play()
	StartGameEvent:FireServer()
end)

noBtn.MouseButton1Click:Connect(function()
	-- NEW: kirim pembatalan ke server, server yg broadcast tutup UI semua
	TweenService:Create(noBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}):Play()
	CancelStartVoteEvent:FireServer()

	-- (Opsional) feel responsif: langsung tutup juga di sisi lokal
	hideFrame()
end)

-- Cek jarak untuk menampilkan UI
game:GetService("RunService").RenderStepped:Connect(function()
	if not gameStarted then
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local dist = (char.HumanoidRootPart.Position - startPart.Position).Magnitude

			-- Tampilkan UI sesuai platform hanya jika dekat dengan startPart
			if UIS.TouchEnabled then
				mobileStartBtn.Visible = dist < 10 and not frame.Visible
			else
				desktopPrompt.Visible = dist < 10 and not frame.Visible
			end
		end
	end
end)
