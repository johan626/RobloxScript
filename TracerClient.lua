-- TracerClient.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/TracerClient.lua (LocalScript)
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local TracerBroadcast = RemoteEvents:WaitForChild("TracerBroadcast")

-- Setting tracer (ambil dari versi server sebelumnya)
local TRACER_COLOR = Color3.fromRGB(255, 200, 50)
local TRACER_WIDTH = 0.1

local function spawnTracer(startPos: Vector3, endPos: Vector3)
	-- Buat part “dummy” untuk menampung attachment & beam
	local tracerPart = Instance.new("Part")
	tracerPart.Size = Vector3.new(0.1, 0.1, 0.1)
	tracerPart.CFrame = CFrame.new(startPos)
	tracerPart.Anchored = true
	tracerPart.CanCollide = false
	tracerPart.Transparency = 1
	tracerPart.Name = "TracerPart"
	tracerPart.Parent = workspace

	-- Attachment
	local a0 = Instance.new("Attachment"); a0.Parent = tracerPart
	local a1 = Instance.new("Attachment"); a1.Parent = tracerPart
	a0.WorldPosition = startPos
	a1.WorldPosition = endPos

	-- Beam
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Color = ColorSequence.new(TRACER_COLOR)
	beam.Width0 = TRACER_WIDTH
	beam.Width1 = TRACER_WIDTH
	beam.Brightness = 5
	beam.LightEmission = 0.8
	beam.LightInfluence = 0
	beam.Texture = "rbxassetid://446111271"
	beam.TextureSpeed = 10

	local distance = (startPos - endPos).Magnitude
	beam.TextureLength = distance / 2
	beam.Parent = tracerPart

	-- Fade cepat
	local tween = TweenService:Create(beam, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Width0 = 0,
		Width1 = 0,
		Brightness = 0
	})
	tween:Play()

	-- Bersihkan
	Debris:AddItem(tracerPart, 0.3)
end

-- Terima siaran dari server
TracerBroadcast.OnClientEvent:Connect(function(shooter: Player, startPos: Vector3, endPos: Vector3, weaponName: string)
	-- Render untuk semua client, termasuk penembak (polanya sama seperti muzzle flash broadcast)
	spawnTracer(startPos, endPos)
end)
