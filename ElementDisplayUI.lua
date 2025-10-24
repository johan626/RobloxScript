-- ElementDisplayUI.lua (LocalScript)
-- Path: StarterGui/ElementDisplayUI.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local ElementActivated      = RemoteEvents:WaitForChild("ElementActivated")
local ElementDeactivated    = RemoteEvents:WaitForChild("ElementDeactivated")
local ActivateElementEvent  = RemoteEvents:WaitForChild("ActivateElementEvent")
local ElementPurchased      = RemoteEvents:WaitForChild("ElementPurchased")
local WaveUpdateEvent       = RemoteEvents:WaitForChild("WaveUpdateEvent")

-- Warna dan ikon untuk setiap elemen
local elementData = {
	Fire = {
		icon = "🔥",
		color = Color3.fromRGB(255, 100, 50),
		gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 50))
		}
	},
	Ice = {
		icon = "❄️",
		color = Color3.fromRGB(100, 200, 255),
		gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 150, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 230, 255))
		}
	},
	Poison = {
		icon = "☠️",
		color = Color3.fromRGB(150, 255, 100),
		gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 50)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 255, 100))
		}
	},
	Shock = {
		icon = "⚡",
		color = Color3.fromRGB(255, 255, 100),
		gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 50)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 150))
		}
	},
	Wind = {
		icon = "🌪️",
		color = Color3.fromRGB(200, 230, 255),
		gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 210, 240)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 240, 255))
		}
	},
	Earth = {
		icon = "🌍",
		color = Color3.fromRGB(150, 120, 80),
		gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 90, 60)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 150, 100))
		}
	},
	Light = {
		icon = "✨",
		color = Color3.fromRGB(255, 255, 200),
		gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 150)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 230))
		}
	},
	Dark = {
		icon = "🌑",
		color = Color3.fromRGB(80, 60, 120),
		gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 30, 80)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 70, 150))
		}
	}
}

-- ====== Wadah minimal tanpa header/“Elements” container ======
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "ElementDisplayUI"
hudGui.IgnoreGuiInset = true
hudGui.ResetOnSpawn = false
hudGui.Parent = playerGui

-- ====== State ======
local elementFrames = {}        -- [name] = {frame=Frame, type="active"/"purchased", ...}
local purchasedElementName = nil

-- ====== Helper Functions ======
local function getElementData(name)
	return elementData[name] or {
		icon = "❓",
		color = Color3.fromRGB(180, 180, 180),
		gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 100, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180))
		}
	}
end

-- Terapkan posisi/ukuran tersimpan ke sebuah GuiObject jika ada di MobileButtonsSettings
local function applyIfSavedPosition(guiObj)
	local folder = playerGui:FindFirstChild("MobileButtonsSettings")
	if not folder then return false end
	local node = folder:FindFirstChild(guiObj.Name)
	if not node or not node:IsA("StringValue") then return false end

	local ok, data = pcall(function() return HttpService:JSONDecode(node.Value) end)
	if not ok or not data or not data.position or not data.size then return false end

	guiObj.Position = UDim2.new(data.position.X, data.position.OffsetX, data.position.Y, data.position.OffsetY)
	guiObj.Size     = UDim2.new(data.size.X,     data.size.OffsetX,     data.size.Y,     data.size.OffsetY)
	return true
end

local function rearrangeFrames()
	local activeFrames = {}
	local purchasedFrames = {}

	-- Pisahkan frame berdasarkan tipe
	for name, data in pairs(elementFrames) do
		if data.type == "active" then
			table.insert(activeFrames, {name = name, data = data})
		elseif data.type == "purchased" then
			table.insert(purchasedFrames, {name = name, data = data})
		end
	end

	-- Atur ulang posisi frame
	local totalHeight = 12
	local spacing = 10

	-- Tampilkan purchased frames di atas
	for i, item in ipairs(purchasedFrames) do
		local frame = item.data.frame
		frame.Position = UDim2.new(1, -12, 0, totalHeight)
		-- Jika user punya posisi tersimpan untuk frame ini, jangan timpa posisinya dan jangan ikut stacking
		if not applyIfSavedPosition(frame) then
			frame.Position = UDim2.new(1, -12, 0, totalHeight)
			totalHeight = totalHeight + frame.AbsoluteSize.Y + spacing
		end

		totalHeight = totalHeight + frame.AbsoluteSize.Y + spacing
	end

	-- Tampilkan active frames di bawah purchased frames
	for i, item in ipairs(activeFrames) do
		local frame = item.data.frame
		frame.Position = UDim2.new(1, -12, 0, totalHeight)
		if not applyIfSavedPosition(frame) then
			frame.Position = UDim2.new(1, -12, 0, totalHeight)
			totalHeight = totalHeight + frame.AbsoluteSize.Y + spacing
		end
		totalHeight = totalHeight + frame.AbsoluteSize.Y + spacing
	end
end

-- ====== Kartu elemen aktif ======
local function createActiveBuffFrame(name, duration)
	-- Reuse kalau sudah ada
	if elementFrames[name] and elementFrames[name].type == "active" then
		elementFrames[name].expires = tick() + duration
		return elementFrames[name].frame
	end

	local elementInfo = getElementData(name)

	local frame = Instance.new("Frame")
	frame.Name = "ElementActivatePrompt"
	-- Terapkan posisi/ukuran tersimpan jika ada
	applyIfSavedPosition(frame)
	frame.Size = UDim2.new(0, 200, 0, 70)
	frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	frame.BorderSizePixel = 0
	frame.ZIndex = 6
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.ClipsDescendants = true

	-- Gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = elementInfo.gradient
	gradient.Transparency = NumberSequence.new(0.7)
	gradient.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	-- Glow effect
	local glow = Instance.new("UIStroke")
	glow.Color = elementInfo.color
	glow.Thickness = 2
	glow.Transparency = 0.5
	glow.Parent = frame

	-- Icon container dengan latar belakang bulat
	local iconContainer = Instance.new("Frame")
	iconContainer.Size = UDim2.new(0, 40, 0, 40)
	iconContainer.Position = UDim2.new(0, 10, 0, 15)
	iconContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	iconContainer.BackgroundTransparency = 0.9
	iconContainer.ZIndex = 7

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0)
	iconCorner.Parent = iconContainer

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = elementInfo.icon
	icon.TextColor3 = elementInfo.color
	icon.TextScaled = true
	icon.ZIndex = 8
	icon.Parent = iconContainer

	iconContainer.Parent = frame

	-- Nama elemen
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 120, 0, 20)
	nameLabel.Position = UDim2.new(0, 60, 0, 12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.ZIndex = 7
	nameLabel.Parent = frame

	-- Timer
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.new(0, 120, 0, 20)
	timeLabel.Position = UDim2.new(0, 60, 0, 32)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = tostring(duration) .. "s"
	timeLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	timeLabel.TextScaled = true
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.ZIndex = 7
	timeLabel.Parent = frame

	-- Progress bar container
	local barBG = Instance.new("Frame")
	barBG.Size = UDim2.new(0, 180, 0, 6)
	barBG.Position = UDim2.new(0, 10, 0, 58)
	barBG.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	barBG.BorderSizePixel = 0
	barBG.ZIndex = 7
	barBG.Parent = frame

	local barCornerBG = Instance.new("UICorner")
	barCornerBG.CornerRadius = UDim.new(1, 0)
	barCornerBG.Parent = barBG

	-- Progress bar
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 1, 0)
	bar.Position = UDim2.new(0, 0, 0, 0)
	bar.BackgroundColor3 = elementInfo.color
	bar.BorderSizePixel = 0
	bar.ZIndex = 8
	bar.Parent = barBG

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	-- Pulse effect untuk bar
	local pulseGlow = Instance.new("UIStroke")
	pulseGlow.Color = elementInfo.color
	pulseGlow.Thickness = 2
	pulseGlow.Transparency = 0.8
	pulseGlow.Parent = bar
	pulseGlow.Enabled = false

	-- Simpan referensi
	elementFrames[name] = {
		frame = frame,
		type = "active",
		expires = tick() + duration,
		initialDuration = duration,
		timeLabel = timeLabel,
		bar = bar,
		pulseGlow = pulseGlow,
		elementInfo = elementInfo
	}

	-- Animasi masuk
	frame.Size = UDim2.new(0, 0, 0, 70)
	local tween = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
		{Size = UDim2.new(0, 200, 0, 70)})
	tween:Play()

	-- Atur ulang posisi semua frame
	rearrangeFrames()

	return frame
end

-- ====== Kartu elemen baru dibeli ======
local function createPurchasedBuffFrame(elementName)
	local elementInfo = getElementData(elementName)

	local frame = Instance.new("Frame")
	frame.Name = "ElementPurchasedPrompt"
	-- Terapkan posisi/ukuran tersimpan jika ada
	applyIfSavedPosition(frame)
	frame.Size = UDim2.new(0, 200, 0, 70)
	frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	frame.BorderSizePixel = 0
	frame.ZIndex = 6
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.ClipsDescendants = true

	-- Gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = elementInfo.gradient
	gradient.Transparency = NumberSequence.new(0.7)
	gradient.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	-- Glow effect (berdenyut)
	local glow = Instance.new("UIStroke")
	glow.Color = elementInfo.color
	glow.Thickness = 2
	glow.Transparency = 0.5
	glow.Parent = frame

	-- Animasi glow berdenyut
	local pulseIn = TweenService:Create(glow, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
		{Thickness = 4, Transparency = 0.2})
	local pulseOut = TweenService:Create(glow, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
		{Thickness = 2, Transparency = 0.5})

	pulseOut:Play()
	local pulseConnection
	pulseConnection = pulseOut.Completed:Connect(function()
		pulseIn:Play()
		pulseIn.Completed:Connect(function()
			pulseOut:Play()
		end)
	end)

	-- Icon container
	local iconContainer = Instance.new("Frame")
	iconContainer.Size = UDim2.new(0, 40, 0, 40)
	iconContainer.Position = UDim2.new(0, 10, 0, 15)
	iconContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	iconContainer.BackgroundTransparency = 0.9
	iconContainer.ZIndex = 7

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0)
	iconCorner.Parent = iconContainer

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = elementInfo.icon
	icon.TextColor3 = elementInfo.color
	icon.TextScaled = true
	icon.ZIndex = 8
	icon.Parent = iconContainer

	iconContainer.Parent = frame

	-- Nama elemen
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 120, 0, 20)
	nameLabel.Position = UDim2.new(0, 60, 0, 12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = elementName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.ZIndex = 7
	nameLabel.Parent = frame

	-- Prompt aktivasi
	if UserInputService.TouchEnabled then
		local activateButton = Instance.new("TextButton")
		activateButton.Size = UDim2.new(0, 120, 0, 25)
		activateButton.Position = UDim2.new(0, 60, 0, 35)
		activateButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
		activateButton.AutoButtonColor = true
		activateButton.Text = "ACTIVATE"
		activateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		activateButton.TextScaled = true
		activateButton.Font = Enum.Font.GothamBold
		activateButton.ZIndex = 7
		activateButton.Parent = frame

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = activateButton

		-- Hover effect untuk tombol
		activateButton.MouseEnter:Connect(function()
			TweenService:Create(activateButton, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(0, 220, 0),
				Size = UDim2.new(0, 125, 0, 27)
			}):Play()
		end)

		activateButton.MouseLeave:Connect(function()
			TweenService:Create(activateButton, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(0, 180, 0),
				Size = UDim2.new(0, 120, 0, 25)
			}):Play()
		end)

		activateButton.MouseButton1Click:Connect(function()
			TweenService:Create(activateButton, TweenInfo.new(0.1), {
				BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			}):Play()
			task.wait(0.1)
			TweenService:Create(activateButton, TweenInfo.new(0.1), {
				BackgroundColor3 = Color3.fromRGB(0, 180, 0)
			}):Play()
			ActivateElementEvent:FireServer(elementName)
		end)
	else
		local promptLabel = Instance.new("TextLabel")
		promptLabel.Size = UDim2.new(0, 120, 0, 20)
		promptLabel.Position = UDim2.new(0, 60, 0, 35)
		promptLabel.BackgroundTransparency = 1
		promptLabel.Text = "Press F to activate"
		promptLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		promptLabel.TextScaled = true
		promptLabel.Font = Enum.Font.GothamBold
		promptLabel.ZIndex = 7
		promptLabel.Parent = frame

		-- Animasi teks berkedip
		local fadeOut = TweenService:Create(promptLabel, TweenInfo.new(0.5), {TextTransparency = 0.3})
		local fadeIn = TweenService:Create(promptLabel, TweenInfo.new(0.5), {TextTransparency = 0})

		fadeIn:Play()
		fadeIn.Completed:Connect(function()
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				fadeIn:Play()
			end)
		end)
	end

	-- Simpan
	elementFrames[elementName] = {
		frame = frame,
		type = "purchased",
		glow = glow,
		pulseIn = pulseIn,
		pulseOut = pulseOut,
		pulseConnection = pulseConnection
	}

	-- Animasi masuk
	frame.Size = UDim2.new(0, 0, 0, 70)
	local tween = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
		{Size = UDim2.new(0, 200, 0, 70)})
	tween:Play()

	-- Atur ulang posisi semua frame
	rearrangeFrames()

	return frame
end

-- ====== Helper: hapus kartu ======
local function removeElementFrame(name)
	if elementFrames[name] and elementFrames[name].frame then
		local data = elementFrames[name]
		local frame = data.frame

		-- Hentikan animasi yang berjalan
		if data.pulseConnection then
			data.pulseConnection:Disconnect()
		end

		-- Animasi keluar
		TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 70)
		}):Play()

		task.wait(0.3)
		frame:Destroy()
	end
	elementFrames[name] = nil

	-- Atur ulang posisi frame yang tersisa
	rearrangeFrames()
end

-- ====== Event wiring ======
ElementActivated.OnClientEvent:Connect(function(name, duration)
	-- Jika sebelumnya ada purchased frame, hapus
	if elementFrames[name] and elementFrames[name].type == "purchased" then
		removeElementFrame(name)
	end

	-- Tampilkan kartu aktif
	local frame = createActiveBuffFrame(name, duration)
	frame.Parent = hudGui
	purchasedElementName = nil

	-- Efek suara (jika tersedia)
	if SoundService:FindFirstChild("ElementActivated") then
		local sound = SoundService.ElementActivated:Clone()
		sound.Parent = frame
		sound:Play()
		game:GetService("Debris"):AddItem(sound, sound.TimeLength)
	end
end)

ElementDeactivated.OnClientEvent:Connect(function(name)
	removeElementFrame(name)

	-- Efek suara (jika tersedia)
	if SoundService:FindFirstChild("ElementDeactivated") then
		local sound = SoundService.ElementDeactivated:Clone()
		sound.Parent = hudGui
		sound:Play()
		game:GetService("Debris"):AddItem(sound, sound.TimeLength)
	end
end)

ElementPurchased.OnClientEvent:Connect(function(elementName)
	-- Saat beli elemen: tampilkan kontainer kecil "Press F to activate"
	purchasedElementName = elementName

	-- Bersihkan semua kartu purchased sebelumnya biar tidak dobel
	for name, data in pairs(elementFrames) do
		if data.type == "purchased" then
			removeElementFrame(name)
		end
	end

	local frame = createPurchasedBuffFrame(elementName)
	frame.Parent = hudGui

	-- Efek suara (jika tersedia)
	if SoundService:FindFirstChild("ElementPurchased") then
		local sound = SoundService.ElementPurchased:Clone()
		sound.Parent = frame
		sound:Play()
		game:GetService("Debris"):AddItem(sound, sound.TimeLength)
	end
end)

WaveUpdateEvent.OnClientEvent:Connect(function(_wave)
	-- Bersihkan purchased saat wave baru
	for name, data in pairs(elementFrames) do
		if data.type == "purchased" then
			removeElementFrame(name)
		end
	end
	purchasedElementName = nil
end)

-- Input aktivasi (desktop)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F and purchasedElementName then
		-- Visual feedback untuk input
		-- Ambil posisi saat ini, lalu buat efek "press" hanya di Y
		local frame = elementFrames[purchasedElementName].frame
		local basePos = frame.Position

		TweenService:Create(frame, TweenInfo.new(0.1), {
			Position = UDim2.new(basePos.X.Scale, basePos.X.Offset, basePos.Y.Scale, basePos.Y.Offset + 5)
		}):Play()

		task.wait(0.1)

		TweenService:Create(frame, TweenInfo.new(0.1), {
			Position = UDim2.new(basePos.X.Scale, basePos.X.Offset, basePos.Y.Scale, basePos.Y.Offset)
		}):Play()
		ActivateElementEvent:FireServer(purchasedElementName)
	end
end)

-- Update timer & progress untuk elemen aktif
RunService.RenderStepped:Connect(function()
	local now = tick()
	for name, data in pairs(elementFrames) do
		if data.type == "active" and data.expires and data.timeLabel and data.bar then
			local rem = math.max(0, data.expires - now)
			data.timeLabel.Text = string.format("%.1fs", rem)

			if data.initialDuration and data.initialDuration > 0 then
				local percent = rem / data.initialDuration
				data.bar.Size = UDim2.new(percent, 0, 1, 0)

				-- Efek pulsating ketika waktu hampir habis
				if rem < 3 then
					data.pulseGlow.Enabled = true
					local pulse = math.sin(now * 10) * 0.5 + 0.5
					data.pulseGlow.Transparency = 0.5 - (pulse * 0.3)
				else
					data.pulseGlow.Enabled = false
				end
			end

			if rem <= 0 then
				removeElementFrame(name)
			end
		end
	end
end)
