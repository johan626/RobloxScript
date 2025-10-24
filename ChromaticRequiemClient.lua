-- ChromaticRequiemClient.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/ChromaticRequiemClient.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local uiEvent = RemoteEvents:WaitForChild("ChromaticRequiemUIEvent")

local mainGui = nil
local mainFrame = nil
local currentBoss = nil

local colorMap = {
	North = Color3.fromRGB(255, 0, 0),
	East = Color3.fromRGB(0, 255, 0),
	South = Color3.fromRGB(0, 0, 255),
	West = Color3.fromRGB(255, 255, 0)
}

local function updateUI(order, boss)
	-- Jika GUI sudah ada, bersihkan label lama
	if mainFrame then
		for _, child in ipairs(mainFrame:GetChildren()) do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
	else -- Jika GUI belum ada, buat yang baru
		mainGui = Instance.new("BillboardGui")
		mainGui.Name = "ChromaticRequiemUI"
		mainGui.AlwaysOnTop = true
		mainGui.Size = UDim2.new(0, 400, 0, 100) -- Ukuran dalam piksel
		mainGui.StudsOffset = Vector3.new(0, 5, 0) -- Posisikan di atas kepala boss

		mainFrame = Instance.new("Frame", mainGui)
		mainFrame.Name = "MainFrame"
		mainFrame.Size = UDim2.new(1, 0, 1, 0) -- Penuhi BillboardGui
		mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		mainFrame.BackgroundTransparency = 0.3
		mainFrame.BorderSizePixel = 1

		local layout = Instance.new("UIListLayout", mainFrame)
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0.05, 0)

		-- Atur Adornee dan Parent
		if boss and boss:FindFirstChild("HumanoidRootPart") then
			mainGui.Adornee = boss:FindFirstChild("HumanoidRootPart")
			mainGui.Parent = boss:FindFirstChild("HumanoidRootPart")
			currentBoss = boss
		else
			-- Fallback jika boss tidak valid, hancurkan diri sendiri
			mainGui:Destroy()
			mainGui = nil
			mainFrame = nil
			return
		end
	end

	-- Buat label baru berdasarkan urutan
	for i, colorName in ipairs(order) do
		local colorLabel = Instance.new("TextLabel", mainFrame)
		colorLabel.Size = UDim2.new(0.2, 0, 0.8, 0)
		colorLabel.Text = colorName
		colorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		colorLabel.BackgroundColor3 = colorMap[colorName] or Color3.fromRGB(200, 200, 200)
		colorLabel.Font = Enum.Font.SourceSansBold
		colorLabel.TextScaled = true
	end
end

local function onEvent(command, data, boss)
	if command == "show" then
		-- Hancurkan UI lama jika ada
		if mainGui then
			mainGui:Destroy()
			mainGui = nil
			mainFrame = nil
		end
		updateUI(data, boss)
	elseif command == "update" then
		-- Pastikan kita memperbarui UI pada boss yang benar
		if boss and boss == currentBoss and mainGui then
			updateUI(data, boss)
		end
	elseif command == "hide" then
		if mainGui then
			mainGui:Destroy()
			mainGui = nil
			mainFrame = nil
			currentBoss = nil
		end
	end
end

uiEvent.OnClientEvent:Connect(onEvent)
