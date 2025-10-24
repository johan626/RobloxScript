-- SprintManager.lua (Script)
-- Path: ServerScriptService/Script/SprintManager.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local DebuffManager = require(ModuleScriptServerScriptService:WaitForChild("DebuffModule"))
local SkillModule = require(ModuleScriptServerScriptService:WaitForChild("SkillModule"))
local SkillConfig = require(ModuleScriptReplicatedStorage:WaitForChild("SkillConfig"))

local sprintEvent = RemoteEvents:WaitForChild("SprintEvent")
local staminaUpdate = RemoteEvents:WaitForChild("StaminaUpdate")
local jumpEvent = RemoteEvents:WaitForChild("JumpEvent")

local MAX = 100
local DRAIN_PER_SEC = 20
local REGEN_PER_SEC = 3
local MIN_TO_SPRINT = 10

local playerData = {}

local function calculateMaxStamina(player)
	local char = player.Character
	local currentMax = MAX

	-- Cek bonus stamina dari perk
	if char and char:GetAttribute("StaminaBoost") then
		currentMax = currentMax * 1.3
	end

	-- Cek bonus dari skill
	local skillData = SkillModule.GetSkillData(player)
	if skillData and skillData.Skills then
		local staminaLevel = skillData.Skills.MaxStamina or 0
		if staminaLevel > 0 then
			local staminaBonus = staminaLevel * (SkillConfig.MaxStamina.StaminaPerLevel or 1)
			currentMax = currentMax + staminaBonus
		end
	end

	return currentMax
end

Players.PlayerAdded:Connect(function(player)
	playerData[player] = {
		stamina = MAX,
		isSprinting = false,
		lastSprintRequest = 0
	}

	player.CharacterAdded:Connect(function(char)
		char:SetAttribute("IsSprinting", false)
		-- Inisialisasi stamina dengan memperhitungkan semua bonus
		playerData[player].stamina = calculateMaxStamina(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerData[player] = nil
end)

-- Server loop
spawn(function()
	while true do
		for player, data in pairs(playerData) do
			local char = player.Character
			local currentMaxStamina = calculateMaxStamina(player)

			if data.isSprinting then
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local moving = hum and (hum.MoveDirection.Magnitude > 0.1)
				if moving then
					-- drain saat bergerak
					data.stamina = math.max(0, data.stamina - DRAIN_PER_SEC * (1/10))
					if data.stamina <= 0 then
						data.isSprinting = false
						if char then char:SetAttribute("IsSprinting", false) end
					end
				else
					-- REGEN saat diam walau masih menahan Shift (status sprint)
					data.stamina = math.min(currentMaxStamina, data.stamina + REGEN_PER_SEC * (1/10))
				end
			else
				data.stamina = math.min(currentMaxStamina, data.stamina + REGEN_PER_SEC * (1/10))
			end

			if player and player.Parent then
				staminaUpdate:FireClient(player, math.floor(data.stamina))
			end
		end
		task.wait(0.1)
	end
end)

sprintEvent.OnServerEvent:Connect(function(player, action)
	local data = playerData[player]
	if not data then return end
	local char = player.Character
	local currentMaxStamina = calculateMaxStamina(player)

	if action == "Start" then
		-- Tambahan: Cek apakah pemain terkena debuff slow
		local speedMultiplier = DebuffManager.GetSpeedMultiplier(player)
		if speedMultiplier < 1 then
			return -- Jangan izinkan sprint jika sedang diperlambat
		end

		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (hum and hum.MoveDirection.Magnitude > 0.1) then
			return -- jangan set isSprinting kalau belum ada gerakan
		end
		if data.stamina > (MIN_TO_SPRINT * (char:GetAttribute("StaminaBoost") and 1.3 or 1)) and not data.isSprinting then
			data.isSprinting = true
			if char then char:SetAttribute("IsSprinting", true) end
		end
	elseif action == "Stop" then
		if data.isSprinting then
			data.isSprinting = false
			if char then char:SetAttribute("IsSprinting", false) end
		end
	end
end)

jumpEvent.OnServerEvent:Connect(function(player)
	local data = playerData[player]
	if not data then return end

	-- Cek apakah stamina cukup untuk melompat
	if data.stamina >= 5 then
		data.stamina = data.stamina - 5
	end
end)