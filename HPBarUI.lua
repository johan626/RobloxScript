-- HPBarUI.lua (LocalScript)
-- Path: StarterGui/HPBarUI.lua
-- Script Place: ACT 1: Village

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local StarterGui 		 = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local KnockEvent = RemoteEvents:WaitForChild("KnockEvent")
local ShieldUpdateEvent = RemoteEvents:WaitForChild("ShieldUpdateEvent")

-- Sembunyikan health bar default di topbar
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

-- ====== KONFIG ======
local CONFIG = {
	-- Ukuran untuk desktop dan mobile
	DesktopSize = UDim2.new(0, 260, 0, 36),
	MobileSize = UDim2.new(0, 180, 0, 28),

	-- Posisi untuk desktop (kiri bawah) dan mobile (kanan atas)
	DesktopPosition = UDim2.new(0, 24, 1, -120),
	MobilePosition = UDim2.new(1, -24, 0, 24),

	-- Style kartu/bar
	CornerRadius = UDim.new(0, 10),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.2,
	StrokeThickness = 2,

	BaseFillColor = Color3.fromRGB(60, 200, 120),
	CardColor = Color3.fromRGB(28, 28, 32),
	CardTransparency = 0.05,
	ShadowTransparency = 0.9,

	-- Tween & threshold
	TweenTime = 0.18,
	LowHpThreshold = 0.35,
	LowHpPulseSpeed = 2.2,

	-- VFX damage
	DamageFlashDuration = 0.12,   -- seberapa cepat flash merah
	ShakeDuration       = 0.18,   -- durasi shake
	ShakeOffset         = 6,      -- px
	SparkBurstCount     = 8,      -- jumlah percikan UI
	SparkLifetime       = 0.35,   -- detik
	VignetteMaxAlpha    = 0.35,   -- intensitas vignette
	VignetteFadeTime    = 0.25,   -- fade out vignette
}

-- ====== DETEKSI PERANGKAT ======
local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- ====== UTIL WARNA ======
local function lerp(a, b, t) return a + (b - a) * t end

local function hsvLerp(c1, c2, t)
	local h1, s1, v1 = c1:ToHSV()
	local h2, s2, v2 = c2:ToHSV()
	return Color3.fromHSV(lerp(h1, h2, t), lerp(s1, s2, t), lerp(v1, v2, t))
end

-- hijau → kuning → merah
local function healthColor(healthPct)
	healthPct = math.clamp(healthPct, 0, 1)
	if healthPct >= 0.5 then
		local t = (healthPct - 0.5) / 0.5
		return hsvLerp(Color3.fromRGB(255, 196, 0), Color3.fromRGB(60, 200, 120), t)
	else
		local t = (healthPct / 0.5)
		return hsvLerp(Color3.fromRGB(204, 40, 40), Color3.fromRGB(255, 196, 0), t)
	end
end
-- ====== BANGUN UI ======
local function ensureHUDScreen()
	local hud = Instance.new("ScreenGui")
	hud.Name = "HPBarUI"
	hud.ResetOnSpawn = false
	hud.IgnoreGuiInset = true
	hud.Parent = playerGui
	return hud
end

local function buildHPUI()
	local hud = ensureHUDScreen()

	-- Container kartu
	local card = hud:FindFirstChild("HPContainer") or Instance.new("Frame")
	card.Name = "HPContainer"
	card.AnchorPoint = Vector2.new(0, 1)

	-- Atur ukuran berdasarkan perangkat
	if isMobile() then
		card.Size = CONFIG.MobileSize
	else
		card.Size = CONFIG.DesktopSize
	end

	card.BackgroundColor3 = CONFIG.CardColor
	card.BackgroundTransparency = CONFIG.CardTransparency
	card.BorderSizePixel = 0
	card.Parent = hud

	-- Corner & stroke
	if not card:FindFirstChildOfClass("UICorner") then
		local c = Instance.new("UICorner")
		c.CornerRadius = CONFIG.CornerRadius
		c.Parent = card
	end
	local stroke = card:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Thickness = CONFIG.StrokeThickness
	stroke.Color = CONFIG.StrokeColor
	stroke.Transparency = CONFIG.StrokeTransparency
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = card

	-- Bar background
	local barBG = card:FindFirstChild("BarBG") or Instance.new("Frame")
	barBG.Name = "BarBG"
	barBG.AnchorPoint = Vector2.new(0.5, 0.5)
	barBG.Position = UDim2.new(0.5, 0, 0.5, 0)
	barBG.Size = UDim2.new(1, -12, 1, -12)
	barBG.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
	barBG.BackgroundTransparency = 0.1
	barBG.BorderSizePixel = 0
	barBG.ZIndex = 1
	barBG.Parent = card
	if not barBG:FindFirstChildOfClass("UICorner") then
		local c = Instance.new("UICorner")
		c.CornerRadius = CONFIG.CornerRadius
		c.Parent = barBG
	end

	local icon = card:FindFirstChild("Icon") or Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.new(0.12, 0, 1, 0)      -- lebar ikon sama dengan StaminaBar
	icon.Position = UDim2.new(0.02, 0, 0, 0)  -- padding kiri sama
	icon.Text = "❤️"                           -- ganti petir -> hati
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = Color3.fromRGB(255, 255, 255)
	icon.TextTransparency = 0.05
	icon.ZIndex = 5
	icon.Parent = card

	-- === Geser track/bar agar tidak tertutup ikon (meniru Track StaminaBar) ===
	barBG.AnchorPoint = Vector2.new(0, 0.5)
	barBG.Position = UDim2.new(0.16, 0, 0.5, 0)  -- 0.16 = mulai setelah area ikon
	barBG.Size = UDim2.new(0.82, 0, 1, -12)

	-- Bentuk pil + stroke halus seperti StaminaBar
	local trackCorner = barBG:FindFirstChildOfClass("UICorner")
	if trackCorner then
		trackCorner.CornerRadius = UDim.new(1, 0)
	end

	local trackStroke = barBG:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	trackStroke.Thickness = 1
	trackStroke.Color = Color3.fromRGB(70, 70, 90)
	trackStroke.Transparency = 0.35
	trackStroke.Parent = barBG


	-- Fill
	local fill = barBG:FindFirstChild("Fill") or Instance.new("Frame")
	fill.Name = "Fill"
	fill.AnchorPoint = Vector2.new(0, 0.5)
	fill.Position = UDim2.new(0, 0, 0.5, 0)
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = CONFIG.BaseFillColor
	fill.BorderSizePixel = 0
	fill.ZIndex = 3
	fill.Parent = barBG
	if not fill:FindFirstChildOfClass("UICorner") then
		local c = Instance.new("UICorner")
		c.CornerRadius = CONFIG.CornerRadius
		c.Parent = fill
	end
	local grad = fill:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	grad.Rotation = 0
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	grad.Parent = fill

	-- Label
	local label = card:FindFirstChild("HPLabel") or Instance.new("TextLabel")
	label.Name = "HPLabel"
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.new(0.5, 0, 0.5, 0)

	-- Sesuaikan ukuran teks untuk mobile
	if isMobile() then
		label.Size = UDim2.new(1.2, -24, 1.2, -12)
		label.TextScaled = false
		label.TextSize = 14
	else
		label.Size = UDim2.new(1.5, -24, 1.5, -12)
		label.TextScaled = true
	end

	label.ZIndex = 5 -- Di atas perisai
	label.Text = "100/100"
	label.TextColor3 = Color3.fromRGB(245, 245, 245)
	label.Font = Enum.Font.GothamBold
	label.Parent = barBG
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center

	-- Vignette overlay (full-screen) untuk damage flash
	local vignette = hud:FindFirstChild("DamageVignette") or Instance.new("Frame")
	vignette.Name = "DamageVignette"
	vignette.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	vignette.BackgroundTransparency = 1
	vignette.BorderSizePixel = 0
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.ZIndex = 999
	vignette.Visible = true
	vignette.Parent = hud

	-- ImageGradient untuk vignette (dengan ImageLabel grad radial)
	local vignetteImg = vignette:FindFirstChild("Img") or Instance.new("ImageLabel")
	vignetteImg.Name = "Img"
	vignetteImg.BackgroundTransparency = 1
	vignetteImg.Image = "rbxassetid://146197114" -- radial gradient default Roblox (alternatif)
	vignetteImg.ImageColor3 = Color3.fromRGB(255, 0, 0)
	vignetteImg.ImageTransparency = 1
	vignetteImg.ScaleType = Enum.ScaleType.Slice
	vignetteImg.SliceScale = 1
	vignetteImg.Size = UDim2.fromScale(1, 1)
	vignetteImg.Parent = vignette

	-- Layer untuk sparks (UI percikan)
	local sparkLayer = card:FindFirstChild("SparkLayer") or Instance.new("Frame")
	sparkLayer.Name = "SparkLayer"
	sparkLayer.BackgroundTransparency = 1
	sparkLayer.Size = UDim2.fromScale(1, 1)
	sparkLayer.ZIndex = 5
	sparkLayer.ClipsDescendants = true
	sparkLayer.Parent = card

	-- Shield Fill
	local shieldFill = barBG:FindFirstChild("ShieldFill") or Instance.new("Frame")
	shieldFill.Name = "ShieldFill"
	shieldFill.AnchorPoint = Vector2.new(0, 0.5)
	shieldFill.Position = UDim2.new(0, 0, 0.5, 0)
	shieldFill.Size = UDim2.new(0, 0, 1, 0) -- Start with 0 width
	shieldFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- Blue color for shield
	shieldFill.BorderSizePixel = 0
	shieldFill.ZIndex = 4 -- Above health, below label
	shieldFill.Parent = barBG
	if not shieldFill:FindFirstChildOfClass("UICorner") then
		local c = Instance.new("UICorner")
		c.CornerRadius = CONFIG.CornerRadius
		c.Parent = shieldFill
	end

	return card, barBG, fill, grad, label, vignetteImg, sparkLayer, shieldFill
end

local function positionHPBar(card)
	if isMobile() then
		-- Untuk mobile: kanan atas
		card.AnchorPoint = Vector2.new(1, 0)
		card.Position = CONFIG.MobilePosition
	else
		-- Untuk desktop: kiri bawah
		card.AnchorPoint = Vector2.new(0, 1)
		card.Position = CONFIG.DesktopPosition
	end
end

-- ====== UI UPDATE SHIELD ======
local function updateShieldUI(shieldFill, currentShield, maxHealth)
	maxHealth = math.max(1, maxHealth)
	currentShield = math.clamp(currentShield, 0, maxHealth) -- Shield can't be larger than max health visually
	-- Persentase perisai dihitung relatif terhadap MaxHealth agar proporsional dengan bar HP
	local pct = currentShield / maxHealth

	-- Tween width
	local goal = { Size = UDim2.new(pct, 0, 1, 0) }
	TweenService:Create(shieldFill, TweenInfo.new(CONFIG.TweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end


-- ====== UI UPDATE HP ======
local function updateHPUI(fill, grad, label, current, max, knocked)
	max = math.max(1, max)
	current = math.clamp(current, 0, max)
	local pct = current / max

	-- Teks
	if knocked then
		label.Text = "KNOCKED"
	else
		label.Text = string.format("%d/%d", math.floor(current + 0.5), math.floor(max + 0.5))
	end

	-- Warna
	local col = healthColor(pct)
	fill.BackgroundColor3 = col
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, col:lerp(Color3.fromRGB(255, 255, 255), 0.0)),
		ColorSequenceKeypoint.new(1, col:lerp(Color3.fromRGB(0, 0, 0), 0.15)),
	})

	-- Tween lebar
	local goal = { Size = UDim2.new(pct, 0, 1, 0) }
	TweenService:Create(fill, TweenInfo.new(CONFIG.TweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()

	-- Low HP pulse flag
	fill:SetAttribute("LowHp", pct <= CONFIG.LowHpThreshold)
end

-- ====== LOW HP PULSE LOOP ======
local function startPulseLoop(fill)
	local pulseT = 0
	RunService.RenderStepped:Connect(function(dt)
		if not fill or not fill.Parent then return end
		local low = fill:GetAttribute("LowHp")
		if low then
			pulseT += dt * CONFIG.LowHpPulseSpeed
			local t = 0.5 + 0.5 * math.sin(pulseT)
			fill.BackgroundTransparency = 0.05 + 0.2 * t
		else
			fill.BackgroundTransparency = 0.05
		end
	end)
end

-- ====== DAMAGE VFX ======

-- Shake kartu (kiri-kanan cepat)
local function doShake(card)
	local orig = card.Position
	local sequence = {
		UDim2.new(orig.X.Scale, orig.X.Offset - CONFIG.ShakeOffset, orig.Y.Scale, orig.Y.Offset),
		UDim2.new(orig.X.Scale, orig.X.Offset + CONFIG.ShakeOffset, orig.Y.Scale, orig.Y.Offset),
		UDim2.new(orig.X.Scale, orig.X.Offset - math.floor(CONFIG.ShakeOffset/2), orig.Y.Scale, orig.Y.Offset),
		orig,
	}
	local ti = TweenInfo.new(CONFIG.ShakeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, pos in ipairs(sequence) do
		TweenService:Create(card, ti, { Position = pos }):Play()
	end
end

-- Flash vignette merah singkat
local function doVignetteFlash(vignetteImg)
	if not vignetteImg then return end
	vignetteImg.ImageTransparency = 1
	local show = TweenService:Create(vignetteImg, TweenInfo.new(CONFIG.DamageFlashDuration), { ImageTransparency = 1 - CONFIG.VignetteMaxAlpha })
	local hide = TweenService:Create(vignetteImg, TweenInfo.new(CONFIG.VignetteFadeTime), { ImageTransparency = 1 })
	show:Play()
	show.Completed:Connect(function()
		hide:Play()
	end)
end

-- Burst spark UI dari sisi kanan bar
local function spawnDamageSparks(layer, whereX)
	if not layer then return end
	local sizeX = layer.AbsoluteSize.X
	local sizeY = layer.AbsoluteSize.Y
	for i = 1, CONFIG.SparkBurstCount do
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Image = "rbxassetid://2151741365" -- kecil putih (spark), bisa diganti aset custom
		img.ImageColor3 = Color3.fromRGB(255, 120, 120)
		img.ImageTransparency = 0
		img.Size = UDim2.new(0, math.random(4, 8), 0, math.random(4, 8))
		img.Position = UDim2.new(0, math.floor(whereX), 0, math.random(2, sizeY - 2))
		img.Rotation = math.random(0, 180)
		img.ZIndex = layer.ZIndex + 1
		img.Parent = layer

		local dx = math.random(-30, -6)
		local dy = math.random(-16, 16)
		local goal = {
			Position = UDim2.new(0, math.floor(whereX + dx), 0, math.random(2, sizeY - 2) + dy),
			ImageTransparency = 1,
		}
		local tw = TweenService:Create(img, TweenInfo.new(CONFIG.SparkLifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
		tw:Play()
		task.delay(CONFIG.SparkLifetime + 0.05, function()
			if img and img.Parent then img:Destroy() end
		end)
	end
end

-- Flash merah singkat di bar fill sendiri
local function doFillFlash(fill)
	local orig = fill.BackgroundColor3
	local flashColor = Color3.fromRGB(230, 40, 40)
	local show = TweenService:Create(fill, TweenInfo.new(CONFIG.DamageFlashDuration), { BackgroundColor3 = flashColor })
	local hide = TweenService:Create(fill, TweenInfo.new(CONFIG.DamageFlashDuration), { BackgroundColor3 = orig })
	show:Play()
	show.Completed:Connect(function()
		hide:Play()
	end)
end

-- Panggil semua damage VFX
local function playDamageVFX(card, fill, vignetteImg, sparkLayer, prevHP, newHP, maxHP)
	if not prevHP or not newHP or not maxHP then return end
	if newHP >= prevHP then return end -- hanya saat turun
	doShake(card)
	doVignetteFlash(vignetteImg)
	doFillFlash(fill)

	-- titik spawn spark: di ujung bar (x = lebar fill)
	local pct = math.max(0, math.min(1, newHP / math.max(1, maxHP)))
	local x = fill.AbsolutePosition.X + fill.AbsoluteSize.X
	-- pastikan relatif ke sparkLayer:
	local relX = x - sparkLayer.AbsolutePosition.X
	spawnDamageSparks(sparkLayer, relX)
end

-- ====== BINDING KE CHARACTER ======
local currentConnections = {}

local function disconnectAll()
	for _, c in ipairs(currentConnections) do
		if typeof(c) == "RBXScriptConnection" then
			c:Disconnect()
		end
	end
	currentConnections = {}
end

local function onCharacterAdded(character)
	disconnectAll()

	local humanoid = character:WaitForChild("Humanoid")
	if not humanoid then return end

	local card, _, fill, grad, label, vignetteImg, sparkLayer, shieldFill = buildHPUI()
	positionHPBar(card) -- Panggil fungsi posisi baru
	startPulseLoop(fill)

	-- nilai awal
	local prevHealth = humanoid.Health
	updateHPUI(fill, grad, label, prevHealth, humanoid.MaxHealth, character:FindFirstChild("Knocked") ~= nil)
	updateShieldUI(shieldFill, 0, humanoid.MaxHealth) -- Start with 0 shield

	-- Health change
	table.insert(currentConnections, humanoid:GetPropertyChangedSignal("Health"):Connect(function()
		local knocked = character:FindFirstChild("Knocked") ~= nil
		local newHP   = humanoid.Health
		updateHPUI(fill, grad, label, newHP, humanoid.MaxHealth, knocked)
		-- VFX ketika turun
		playDamageVFX(card, fill, vignetteImg, sparkLayer, prevHealth, newHP, humanoid.MaxHealth)
		prevHealth = newHP
	end))

	-- MaxHealth change
	table.insert(currentConnections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		local knocked = character:FindFirstChild("Knocked") ~= nil
		updateHPUI(fill, grad, label, humanoid.Health, humanoid.MaxHealth, knocked)
	end))

	-- Optional: KnockEvent dari server
	if KnockEvent then
		table.insert(currentConnections, KnockEvent.OnClientEvent:Connect(function(isKnocked)
			updateHPUI(fill, grad, label, humanoid.Health, humanoid.MaxHealth, isKnocked == true)
		end))
	end

	-- Shield Update Event from server
	if ShieldUpdateEvent then
		table.insert(currentConnections, ShieldUpdateEvent.OnClientEvent:Connect(function(currentShield, maxShield)
			updateShieldUI(shieldFill, currentShield, humanoid.MaxHealth)
		end))
	end
end

-- Player lifecycle
local function init()
	if localPlayer.Character then
		onCharacterAdded(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(onCharacterAdded)
end

init()