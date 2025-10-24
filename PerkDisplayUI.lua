-- PerkDisplayUI.lua (LocalScript)
-- Path: StarterGui/PerkDisplayUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local perkUpdateEv = RemoteEvents:WaitForChild("PerkUpdate")

-- Buat ScreenGui khusus display perk
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PerkDisplayUI"
screenGui.IgnoreGuiInset = false
screenGui.ResetOnSpawn = true
screenGui.Parent = gui

-- Main container with stylish design
local mainContainer = Instance.new("Frame")
mainContainer.Name = "PerkDisplayContainer"
mainContainer.Size = UDim2.new(0, 60, 0, 40)
mainContainer.Position = UDim2.new(0.01, 0, 0.01, 0)
mainContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainContainer.BackgroundTransparency = 0.2
mainContainer.Transparency = 1
mainContainer.BorderSizePixel = 0
mainContainer.ClipsDescendants = true
mainContainer.Parent = screenGui

-- Add gradient background
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
})
gradient.Rotation = 90
gradient.Parent = mainContainer

-- Rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainContainer

-- Perks container
local perksContainer = Instance.new("Frame")
perksContainer.Name = "PerksContainer"
perksContainer.Size = UDim2.new(1, -10, 1, -10)
perksContainer.Position = UDim2.new(0, 5, 0, 5)
perksContainer.BackgroundTransparency = 1
perksContainer.Parent = mainContainer

local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Vertical
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.VerticalAlignment = Enum.VerticalAlignment.Top
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 8)
list.Parent = perksContainer

-- Ikon untuk setiap perk dengan emoji yang lebih representatif
local perkIcons = {
	HPPlus = "❤️",
	StaminaPlus = "⚡",
	ReloadPlus = "🔧", 
	RevivePlus = "🔄",
	RateBoost = "🚀",
}

-- Cache frame per perk
local perkFrames = {}
local activeTweens = {}

-- Function to create a glowing effect
local function createGlowEffect(parent)
	local glow = Instance.new("Frame")
	glow.Name = "GlowEffect"
	glow.Size = UDim2.new(1, 10, 1, 10)
	glow.Position = UDim2.new(0, -5, 0, -5)
	glow.BackgroundTransparency = 1
	glow.BorderSizePixel = 0
	glow.Parent = parent
	glow.ZIndex = -1

	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0, 12)
	glowCorner.Parent = glow

	local glowStroke = Instance.new("UIStroke")
	glowStroke.Color = Color3.fromRGB(100, 150, 255)
	glowStroke.Thickness = 3
	glowStroke.Transparency = 0.7
	glowStroke.Parent = glow

	return glow
end

-- Function to animate the glow effect
local function animateGlow(glow)
	local pulseIn = TweenService:Create(
		glow.UIStroke,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
		{Thickness = 6, Transparency = 0.3}
	)
	pulseIn:Play()
	return pulseIn
end

-- Function to create a particle effect (simulated with frames and tweens)
local function createParticleEffect(parent, color)
	local particles = {}

	for i = 1, 4 do
		local particle = Instance.new("Frame")
		particle.Size = UDim2.new(0, 4, 0, 4)
		particle.BackgroundColor3 = color
		particle.BorderSizePixel = 0
		particle.Position = UDim2.new(0.5, 0, 0.5, 0)
		particle.AnchorPoint = Vector2.new(0.5, 0.5)
		particle.Parent = parent
		particle.ZIndex = -1

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = particle

		local angle = math.rad((i-1) * 90)
		local goalPos = UDim2.new(
			0.5, 30 * math.cos(angle),
			0.5, 30 * math.sin(angle)
		)

		local tween = TweenService:Create(
			particle,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = goalPos,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 0, 0, 0)
			}
		)

		table.insert(particles, {particle = particle, tween = tween})
	end

	return particles
end

local function createPerkCard(perkName)
	if perkFrames[perkName] and perkFrames[perkName].Parent then
		return perkFrames[perkName]
	end

	local card = Instance.new("Frame")
	card.Name = "Perk_" .. perkName
	card.Size = UDim2.new(0, 50, 0, 50)
	card.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	card.BorderSizePixel = 0
	card.BackgroundTransparency = 0.2
	card.ClipsDescendants = true

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 120, 200)
	stroke.Thickness = 1
	stroke.Transparency = 0.3
	stroke.Parent = card

	-- Add gradient to card
	local cardGradient = Instance.new("UIGradient")
	cardGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 55)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 40))
	})
	cardGradient.Rotation = 90
	cardGradient.Parent = card

	-- Icon background
	local iconBg = Instance.new("Frame")
	iconBg.Name = "IconBg"
	iconBg.Size = UDim2.new(0, 36, 0, 36)
	iconBg.Position = UDim2.new(0, 7, 0, 7)
	iconBg.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	iconBg.BorderSizePixel = 0

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 6)
	iconCorner.Parent = iconBg

	local iconGlow = createGlowEffect(iconBg)
	iconBg.Parent = card

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = perkIcons[perkName] or "?"
	icon.TextColor3 = Color3.fromRGB(255, 215, 0)
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.Parent = iconBg

	-- Animation for appearance
	card.Size = UDim2.new(0, 50, 0, 0)
	card.BackgroundTransparency = 1
	iconBg.BackgroundTransparency = 1
	icon.TextTransparency = 1

	-- Store the card in cache
	perkFrames[perkName] = card

	-- Animate the card in
	local cardTween = TweenService:Create(
		card,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 50, 0, 50), BackgroundTransparency = 0.2}
	)

	local iconBgTween = TweenService:Create(
		iconBg,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0}
	)

	local textTween = TweenService:Create(
		icon,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	)

	-- Start animations with slight delays for a cascading effect
	cardTween:Play()
	cardTween.Completed:Connect(function()
		iconBgTween:Play()
		textTween:Play()

		-- Start glow animation after card is fully visible
		textTween.Completed:Connect(function()
			activeTweens[perkName] = animateGlow(iconGlow)

			-- Create particle effect
			local particles = createParticleEffect(iconBg, Color3.fromRGB(100, 150, 255))
			for _, p in ipairs(particles) do
				p.tween:Play()
			end
		end)
	end)

	return card
end

local function removePerkCard(perkName)
	local card = perkFrames[perkName]
	if not card then return end

	-- Stop any active glow animation
	if activeTweens[perkName] then
		activeTweens[perkName]:Cancel()
		activeTweens[perkName] = nil
	end

	if card.Parent then
		-- Animate out
		local cardTween = TweenService:Create(
			card,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Size = UDim2.new(0, 50, 0, 0), BackgroundTransparency = 1}
		)

		local icon = card:FindFirstChild("IconBg") and card.IconBg:FindFirstChild("Icon")

		if icon then
			TweenService:Create(icon, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
		end

		cardTween:Play()
		cardTween.Completed:Wait()
		card:Destroy()
	end

	perkFrames[perkName] = nil
end

local function updatePerksDisplay(perks)
	-- Hapus kartu yang tidak lagi dimiliki
	for name, _ in pairs(perkFrames) do
		if not table.find(perks, name) then
			removePerkCard(name)
		end
	end

	-- Tambahkan kartu baru
	for _, name in ipairs(perks) do
		if not perkFrames[name] or not perkFrames[name].Parent then
			local card = createPerkCard(name)
			card.Parent = perksContainer
			card.LayoutOrder = #perksContainer:GetChildren()
		end
	end

	-- Animate container size change
	local newHeight = math.max(40, #perks * (50 + list.Padding.Offset) + 10)
	TweenService:Create(
		mainContainer,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 60, 0, newHeight)}
	):Play()
end

-- Dengarkan update dari server; dipanggil saat membeli/kehilangan perk
perkUpdateEv.OnClientEvent:Connect(function(perks)
	updatePerksDisplay(perks or {})
end)

-- Inisialisasi
updatePerksDisplay({})
