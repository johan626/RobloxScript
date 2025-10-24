-- SprintBarUI.lua (LocalScript)
-- Path: StarterGui/SprintBarUI.lua
-- Script Place: ACT 1: Village

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local Lighting           = game:GetService("Lighting")

local player = Players.LocalPlayer

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local DebuffInfo 		 = require(ModuleScriptReplicatedStorage:WaitForChild("DebuffInfo"))

local UpdateWalkSpeedModifierEvent = RemoteEvents:WaitForChild("UpdateWalkSpeedModifierEvent")
local staminaUpdate  = RemoteEvents:WaitForChild("StaminaUpdate")
local jumpEvent      = RemoteEvents:WaitForChild("JumpEvent")
local debuffStatusEvent = RemoteEvents:WaitForChild("DebuffStatusEvent")
local sprintEvent = RemoteEvents:WaitForChild("SprintEvent")

debuffStatusEvent.OnClientEvent:Connect(function(isSlowed)
	DebuffInfo.isSlowed = isSlowed
end)

-- === Konstanta sprint / stamina (selaras dengan server) ===
local MAX_STAMINA          = 100
local CLIENT_DRAIN_PER_SEC = 20     -- untuk feedback UI; server tetap otoritatif
local CLIENT_REGEN_PER_SEC = 3
local MIN_TO_SPRINT        = 10
local JUMP_STAMINA_COST    = 5
local MIN_TO_JUMP          = 5
local REGEN_DELAY          = 1.0
local SPRINT_SPEED         = 22

-- State
local stamina        = MAX_STAMINA
local isSprinting    = false
local lastSprintStop = 0
local baseWalkSpeed  = nil
local humanoid       = nil
local isShiftHeld = false

-- === Helper: status aiming & reloading (aman) ===
local function isToolAiming()
	local character = player.Character
	if not character then return false end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool or not tool.GetAttribute then return false end
	local ok, val = pcall(function() return tool:GetAttribute("IsAiming") end)
	return ok and (val == true)
end

local function isReloading()
	local character = player.Character
	if not character then return false end
	local isReloading = character:GetAttribute("IsReloading")
	return isReloading == true
end

-- === Deteksi Perangkat ===
local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- === UI: Enhanced Stamina Bar ===
local gui = Instance.new("ScreenGui")
gui.Name = "SprintBarUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Container responsif (mengikuti ukuran dan posisi HP bar)
local container = Instance.new("Frame")
container.Name = "StaminaContainer"
container.AnchorPoint = Vector2.new(0, 1)
container.Position = UDim2.new(0,01, 0, 0.99, 0)
container.Size = UDim2.new(0.25, 0, 0.07, 0)
container.BackgroundTransparency = 1
container.Parent = gui

-- Atur ukuran dan posisi berdasarkan perangkat (sama dengan HP bar)
if isMobile() then
	container.Size = UDim2.new(0, 180, 0, 28)
	container.Position = UDim2.new(1, -24, 0, 62) -- Di bawah HP bar mobile dengan margin 10 pixel
	container.AnchorPoint = Vector2.new(1, 0) -- Kanan atas
else
	container.Size = UDim2.new(0, 260, 0, 36)
	container.Position = UDim2.new(0, 24, 1, -75) -- Di bawah HP bar desktop dengan margin 10 pixel
	container.AnchorPoint = Vector2.new(0, 1) -- Kiri bawah
end

-- Background panel with improved design
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(1, 0, 1, 0)
panel.Position = UDim2.new(0, 0, 0, 0)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
panel.BackgroundTransparency = 0
panel.Parent = container

-- Sudut membulat + outline + shadow lembut
local panelCorner = Instance.new("UICorner", panel)
panelCorner.CornerRadius = UDim.new(0, 10)

local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Thickness = 2
panelStroke.Color = Color3.fromRGB(60, 60, 80)
panelStroke.Transparency = 0.25

-- Glow effect
local panelGlow = Instance.new("ImageLabel")
panelGlow.Name = "Glow"
panelGlow.BackgroundTransparency = 1
panelGlow.Size = UDim2.new(1.1, 0, 1.2, 0)
panelGlow.Position = UDim2.new(-0.05, 0, -0.1, 0)
panelGlow.Image = "rbxassetid://8992231221"
panelGlow.ImageColor3 = Color3.fromRGB(0, 200, 100)
panelGlow.ImageTransparency = 0.9
panelGlow.ScaleType = Enum.ScaleType.Slice
panelGlow.SliceCenter = Rect.new(100, 100, 100, 100)
panelGlow.Parent = panel
panelGlow.ZIndex = -1

-- Ikon ? dengan animasi
local icon = Instance.new("TextLabel")
icon.Name = "Icon"
icon.BackgroundTransparency = 1
icon.Size = UDim2.new(0.12, 0, 1, 0)
icon.Position = UDim2.new(0.02, 0, 0, 0)
icon.Text = "⚡"
icon.TextScaled = true
icon.Font = Enum.Font.GothamBold
icon.TextColor3 = Color3.fromRGB(255, 255, 255)
icon.TextTransparency = 0.05
icon.Parent = panel

-- Track bar (background)
local track = Instance.new("Frame")
track.Name = "Track"
track.AnchorPoint = Vector2.new(0, 0.5)
track.Position = UDim2.new(0.16, 0, 0.5, 0)
track.Size = UDim2.new(0.82, 0, 0.38, 0)
track.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
track.BackgroundTransparency = 0.15
track.BorderSizePixel = 0
track.Parent = panel

local trackCorner = Instance.new("UICorner", track)
trackCorner.CornerRadius = UDim.new(1, 0)

local trackStroke = Instance.new("UIStroke", track)
trackStroke.Thickness = 1
trackStroke.Color = Color3.fromRGB(80, 80, 110)
trackStroke.Transparency = 0.35

-- Fill bar (foreground)
local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.AnchorPoint = Vector2.new(0, 0.5)
fill.Position = UDim2.new(0, 0, 0.5, 0)
fill.Size = UDim2.new(1, 0, 1, 0) -- nanti di-scale via Size.X.Scale
fill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
fill.BorderSizePixel = 0
fill.Parent = track
fill.ZIndex = 2

local fillCorner = Instance.new("UICorner", fill)
fillCorner.CornerRadius = UDim.new(1, 0)

-- Gradient pada fill
local fillGradient = Instance.new("UIGradient", fill)
fillGradient.Rotation = 0
fillGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(30, 255, 180)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0, 180, 90))
}

-- Spark highlight tipis di atas bar
local highlight = Instance.new("Frame")
highlight.Name = "Highlight"
highlight.AnchorPoint = Vector2.new(0, 0)
highlight.Position = UDim2.new(0, 0, 0, 0)
highlight.Size = UDim2.new(1, 0, 0, 2)
highlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
highlight.BackgroundTransparency = 0.7
highlight.BorderSizePixel = 0
highlight.Parent = fill

-- Ticks (penanda 25/50/75%)
local tickContainer = Instance.new("Frame")
tickContainer.Name = "Ticks"
tickContainer.BackgroundTransparency = 1
tickContainer.AnchorPoint = Vector2.new(0, 0.5)
tickContainer.Position = UDim2.new(0, 0, 0.5, 0)
tickContainer.Size = UDim2.new(1, 0, 1, 0)
tickContainer.ZIndex = track.ZIndex + 1
tickContainer.Parent = track

local function makeTick(xScale)
	local t = Instance.new("Frame")
	t.BackgroundColor3 = Color3.fromRGB(120, 120, 150)
	t.BackgroundTransparency = 0.45
	t.BorderSizePixel = 0
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.new(xScale, 0, 0.5, 0)
	t.Size = UDim2.new(0, 2, 0.8, 0)
	t.Parent = tickContainer
end
makeTick(0.25); makeTick(0.50); makeTick(0.75)

-- Label persentase
local percentLabel = Instance.new("TextLabel")
percentLabel.Name = "Percent"
percentLabel.BackgroundTransparency = 1
percentLabel.AnchorPoint = Vector2.new(0.5, 0.5)
percentLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
percentLabel.Size = UDim2.new(1.5, 0, 1.5, 0)  -- biar skala penuh mengikuti tinggi track
percentLabel.ZIndex = track.ZIndex + 2
percentLabel.Text = "100%"
percentLabel.TextScaled = true
percentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  -- putih kontras
percentLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)  -- outline hitam tipis
percentLabel.TextStrokeTransparency = 0.3                -- 0 (tebal) ... 1 (tak terlihat)
percentLabel.Font = Enum.Font.GothamBold
percentLabel.Parent = track

-- Anim helpers
local activeTween; local colorTween; local shakeConn; local particleConn
local LOW_THRESHOLD = 0.2   -- 20%
local LAST_WARN = 0

local function colorForPct(p)
	-- lerp: merah (<=20%) -> kuning (50%) -> hijau (>=80%)
	if p <= 0.5 then
		-- merah ke kuning
		local t = math.clamp((p - 0.0) / 0.5, 0, 1)
		local r = 255
		local g = 50 + (205 * t)
		return Color3.fromRGB(r, g, 40)
	else
		-- kuning ke hijau
		local t = math.clamp((p - 0.5) / 0.5, 0, 1)
		local r = 255 - math.floor(255 * t * 0.9)
		local g = 255
		return Color3.fromRGB(r, g, 60 + math.floor(150 * t))
	end
end

local function setFillInstant(pct)
	fill.Size = UDim2.new(pct, 0, 1, 0)
	local c = colorForPct(pct)
	fill.BackgroundColor3 = c
	fillGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0.0, c:lerp(Color3.fromRGB(255,255,255), 0.10)),
		ColorSequenceKeypoint.new(1.0, c:lerp(Color3.fromRGB(0,0,0), 0.15))
	}
end

local function shakeWarning(enable)
	if enable then
		if shakeConn then return end
		shakeConn = RunService.RenderStepped:Connect(function()
			-- jitter ringan pada panel saat stamina rendah
			local t = os.clock()
			local dx = math.sin(t * 22) * 1.2
			local dy = math.cos(t * 18) * 0.8
			panel.Position = UDim2.new(0, dx, 0, dy)
		end)
	else
		if shakeConn then shakeConn:Disconnect(); shakeConn = nil end
		panel.Position = UDim2.new(0, 0, 0, 0)
	end
end

local function tweenToPct(pct)
	if activeTween then activeTween:Cancel() end
	if colorTween then colorTween:Cancel() end

	local sizeGoal = { Size = UDim2.new(pct, 0, 1, 0) }
	activeTween = TweenService:Create(fill, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), sizeGoal)
	activeTween:Play()

	-- tween warna ke target
	local target = colorForPct(pct)
	colorTween = TweenService:Create(fill, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = target})
	colorTween:Play()
	colorTween.Completed:Connect(function()
		fillGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0.0, target:lerp(Color3.fromRGB(255,255,255), 0.10)),
			ColorSequenceKeypoint.new(1.0, target:lerp(Color3.fromRGB(0,0,0), 0.15))
		}
	end)

	-- update label
	percentLabel.Text = string.format("%d%%", math.floor(pct * 100 + 0.5))

	-- Animate icon when stamina changes
	TweenService:Create(icon, TweenInfo.new(0.1), {TextColor3 = target}):Play()

	-- Update glow color
	TweenService:Create(panelGlow, TweenInfo.new(0.2), {ImageColor3 = target}):Play()

	-- warning behavior
	if pct <= LOW_THRESHOLD then
		if tick() - LAST_WARN > 0.5 then
			LAST_WARN = tick()
			-- pulse panel stroke
			panelStroke.Color = Color3.fromRGB(255, 90, 90)
			TweenService:Create(panelStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(60, 60, 80)}):Play()
		end
		shakeWarning(true)
	else
		shakeWarning(false)
		if particleConn then
			particleConn:Disconnect()
			particleConn = nil
		end
	end

	-- Add glow effect when full
	if pct >= 0.95 then
		TweenService:Create(panelGlow, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
			ImageTransparency = 0.7
		}):Play()
	else
		TweenService:Create(panelGlow, TweenInfo.new(0.3), {
			ImageTransparency = 0.9
		}):Play()
	end
end

local function updateBar()
	local pct = math.clamp(stamina / MAX_STAMINA, 0, 1)
	tweenToPct(pct)
	if player.Character then
		player.Character:SetAttribute("ClientStamina", stamina)
	end
end

-- === Terima update stamina dari server
staminaUpdate.OnClientEvent:Connect(function(s)
	stamina = tonumber(s) or stamina
	updateBar()

	-- Kontrol kemampuan melompat berdasarkan stamina
	if humanoid and humanoid.Parent then
		local originalJumpPower = player.Character:GetAttribute("OriginalJumpPower") or 30
		if stamina < MIN_TO_JUMP then
			if humanoid.JumpPower > 0 then
				player.Character:SetAttribute("OriginalJumpPower", humanoid.JumpPower)
				humanoid.JumpPower = 0
			end
		else
			if humanoid.JumpPower == 0 then
				humanoid.JumpPower = originalJumpPower
			end
		end
	end
end)

-- === Tombol Sprint Mobile (statik, non-draggable, non-resizable) ===
-- Gaya ON/OFF (warna frame BG & stroke)
local function styleFancy(btn, selected)
	if not btn then return end
	local stroke = btn:FindFirstChild("Stroke")
	if selected then
		if stroke then 
			TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(80, 200, 120)}):Play()
		end
	else
		if stroke then 
			TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 255, 255)}):Play()
		end
	end
end

-- Fungsi untuk membuat tombol mobile yang transparan seperti ADS
local function createMobileButton(buttonName, defaultPosition, defaultSize, backgroundColor, text)
	local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild("ScreenGui") or Instance.new("ScreenGui")
	screenGui.Name = "ScreenGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- Buat tombol dengan desain bulat dan transparan
	local button = Instance.new("ImageButton")
	button.Name = buttonName
	button.Size = defaultSize
	button.Position = defaultPosition
	button.BackgroundTransparency = 1  -- Latar belakang tombol transparan
	button.ImageTransparency = 1
	button.AutoButtonColor = false
	button.Visible = false
	button.ZIndex = 10
	button.Parent = screenGui

	-- Buat latar belakang bulat dengan transparansi
	local bg = Instance.new("Frame")
	bg.Name = "BG"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = backgroundColor or Color3.fromRGB(45, 45, 45)
	bg.BackgroundTransparency = 0.7  -- 70% transparan
	bg.BorderSizePixel = 0
	bg.ZIndex = 10
	bg.Parent = button

	-- Buat sudut bulat
	local corner = Instance.new("UICorner", bg)
	corner.CornerRadius = UDim.new(1, 0)  -- Bentuk bulat sempurna

	-- Tambahkan stroke/garis tepi yang transparan
	local stroke = Instance.new("UIStroke", bg)
	stroke.Name = "Stroke"
	stroke.Thickness = 2
	stroke.Transparency = 0.7  -- 70% transparan
	stroke.Color = Color3.fromRGB(255, 255, 255)

	-- Buat label teks
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -10, 1, -10)
	label.Position = UDim2.new(0, 5, 0, 5)
	label.BackgroundTransparency = 1
	label.Text = text or buttonName
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.ZIndex = 11
	label.TextWrapped = true
	label.Parent = bg

	-- Tambahkan efek hover dan press
	button.MouseEnter:Connect(function()
		bg.BackgroundTransparency = 0.6
		stroke.Transparency = 0.6
	end)

	button.MouseLeave:Connect(function()
		bg.BackgroundTransparency = 0.7
		stroke.Transparency = 0.7
	end)

	button.MouseButton1Down:Connect(function()
		bg.BackgroundTransparency = 0.5
		stroke.Transparency = 0.5
	end)

	button.MouseButton1Up:Connect(function()
		bg.BackgroundTransparency = 0.6
		stroke.Transparency = 0.6
	end)

	return button
end

-- Buat tombol Sprint dengan desain baru yang transparan
local mobileSprintButton = nil
if UserInputService.TouchEnabled then
	mobileSprintButton = createMobileButton(
		"MobileSprintButton",
		UDim2.new(0.86, 0, 0.52, 0),
		UDim2.new(0, 72, 0, 72),
		Color3.fromRGB(45, 45, 45),
		"SPRINT"
	)
end

local function refreshSprintButtonStyle()
	if not mobileSprintButton then return end

	local bg = mobileSprintButton:FindFirstChild("BG")
	if not bg then return end

	local stroke = bg:FindFirstChild("Stroke")
	if not stroke then return end

	if isSprinting then
		stroke.Color = Color3.fromRGB(80, 200, 120) -- Hijau saat aktif
	else
		stroke.Color = Color3.fromRGB(255, 255, 255) -- Putih saat non-aktif
	end
end

-- === Logika Sprint ===
local function onCharacterAdded(char)
	-- ambil humanoid baru
	humanoid = char:WaitForChild("Humanoid")
	-- reset state sprint lokal (biar tidak nyangkut)
	isSprinting = false
	baseWalkSpeed = nil
	-- pastikan atribut di karakter ikut konsisten
	char:SetAttribute("IsSprinting", false)
	-- segarkan tampilan tombol sprint (kalau ada)
	if mobileSprintButton then
		mobileSprintButton.Visible = UserInputService.TouchEnabled
		refreshSprintButtonStyle() -- akan set tampilan non-sprinting
	end

	-- Deteksi lompatan untuk mengurangi stamina
	humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Jumping then
			if stamina >= MIN_TO_JUMP then
				-- HANYA kirim event, jangan kurangi stamina di client
				pcall(function() jumpEvent:FireServer() end)
			end
		end
	end)
end

-- Rebind saat karakter respawn supaya referensi Humanoid dan state reset aman
player.CharacterAdded:Connect(onCharacterAdded)

-- Tangani kasus di mana karakter sudah ada saat skrip berjalan (penting untuk Studio)
if player.Character then
	onCharacterAdded(player.Character)
end

local function ensureHumanoid()
	if not player.Character then return end
	if not humanoid or humanoid.Parent == nil then
		humanoid = player.Character:FindFirstChildOfClass("Humanoid") or player.Character:WaitForChild("Humanoid")
	end
end

local function stopSprint()
	if not isSprinting then return end
	isSprinting = false
	if player.Character then player.Character:SetAttribute("IsSprinting", false) end

	UpdateWalkSpeedModifierEvent:FireServer("sprint", nil) -- Send nil to remove modifier
	sprintEvent:FireServer("Stop")

	lastSprintStop = tick()
	refreshSprintButtonStyle()
end

local function startSprint()
	-- tidak boleh sprint saat aiming / reloading / diperlambat
	if isToolAiming() or isReloading() or DebuffInfo.isSlowed then return end
	if stamina <= MIN_TO_SPRINT then return end
	ensureHumanoid()
	if not humanoid or humanoid.MoveDirection.Magnitude <= 0.1 then
		-- Tahan start sprint kalau belum ada input gerak
		return
	end

	isSprinting = true
	lastSprintStop = 0
	if player.Character then player.Character:SetAttribute("IsSprinting", true) end

	local sprintBonus = SPRINT_SPEED - 16 -- Calculate the bonus speed
	UpdateWalkSpeedModifierEvent:FireServer("sprint", sprintBonus)
	sprintEvent:FireServer("Start")

	refreshSprintButtonStyle()
end

local function toggleSprint()
	if isSprinting then stopSprint() else startSprint() end
end

-- Input keyboard: Shift untuk sprint (hold-to-sprint)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.LeftShift then
		isShiftHeld = true
		startSprint()
	end
end)
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.LeftShift then
		isShiftHeld = false
		stopSprint()
	end
end)

-- Klik tombol mobile Sprint (toggle)
if mobileSprintButton then
	mobileSprintButton.Visible = UserInputService.TouchEnabled
	mobileSprintButton.MouseButton1Click:Connect(toggleSprint)
	refreshSprintButtonStyle()
end

-- === Loop utama untuk responsif & sinkron UI ===
RunService.RenderStepped:Connect(function(dt)
	if not player.Character then return end

	-- [BARU] Periksa permintaan pembatalan sprint dari skrip lain (misalnya, WeaponClient)
	if player.Character:GetAttribute("RequestStopSprint") == true then
		stopSprint()
		player.Character:SetAttribute("RequestStopSprint", nil) -- Hapus atribut setelah diproses
	end

	ensureHumanoid()
	-- Auto-start saat mulai bergerak sambil masih menahan Shift
	if isShiftHeld and not isSprinting then
		local canStart = (not isToolAiming()) and (not isReloading()) and stamina > MIN_TO_SPRINT
		if canStart then
			ensureHumanoid()
			if humanoid and humanoid.Parent and (humanoid.MoveDirection.Magnitude > 0.1) then
				startSprint()
			end
		end
	end

	-- Auto-cancel jika reloading mulai
	if isSprinting and isReloading() then
		stopSprint()
	end

	-- Drain / regen klien agar UI terasa responsif (server tetap otoritatif)
	if isSprinting and stamina > 0 then
		-- Cancel sprint jika mulai aiming
		if isToolAiming() then
			stopSprint()
		else
			-- Hanya kuras stamina jika benar-benar bergerak
			local moving = humanoid and humanoid.Parent and (humanoid.MoveDirection.Magnitude > 0.1)
			if not moving then
				-- IZINKAN REGEN walau status masih sprint asal diam
				stamina = math.min(MAX_STAMINA, stamina + CLIENT_REGEN_PER_SEC * dt)
			else
				-- (drain dipindah masuk sini)
				stamina = math.max(0, stamina - CLIENT_DRAIN_PER_SEC * dt)
				if stamina <= 0 then
					stopSprint()
				end
			end
		end
	else
		-- Regen setelah jeda
		if tick() - lastSprintStop > REGEN_DELAY then
			stamina = math.min(MAX_STAMINA, stamina + CLIENT_REGEN_PER_SEC * dt)
			-- Auto-lanjut sprint saat Shift masih ditekan & mulai bergerak lagi
			local moving = humanoid and humanoid.Parent and (humanoid.MoveDirection.Magnitude > 0.1)
			if isShiftHeld and moving and stamina >= MIN_TO_SPRINT then
				startSprint()
			end
		end
	end

	updateBar()
end)
