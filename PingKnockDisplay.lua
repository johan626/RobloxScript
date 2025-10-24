-- PingKnockDisplay.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/PingKnockDisplay.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PingKnockedPlayerEvent = ReplicatedStorage.RemoteEvents:WaitForChild("PingKnockedPlayerEvent")

local PING_SOUND_ID = "rbxassetid://152222467" -- Example sound, will replace with a better one
local PING_DURATION = 3

local function createPingEffect(player)
	local character = player.Character
	if not character or not character:FindFirstChild("Head") then
		return
	end

	-- Create BillboardGui for the exclamation mark
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "PingGui"
	billboardGui.Adornee = character.Head
	billboardGui.Size = UDim2.new(0, 50, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 2, 0)
	billboardGui.AlwaysOnTop = true

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "!"
	textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextScaled = true
	textLabel.TextStrokeTransparency = 0
	textLabel.Parent = billboardGui

	billboardGui.Parent = character.Head

	-- Create and play sound
	local sound = Instance.new("Sound")
	sound.SoundId = PING_SOUND_ID
	sound.Parent = character.Head
	sound:Play()

	-- Clean up after duration
	game:GetService("Debris"):AddItem(billboardGui, PING_DURATION)
	game:GetService("Debris"):AddItem(sound, PING_DURATION + 1) -- Play sound a bit longer
end

PingKnockedPlayerEvent.OnClientEvent:Connect(function(player)
	createPingEffect(player)
end)
