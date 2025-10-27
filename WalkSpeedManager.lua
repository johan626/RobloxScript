-- WalkSpeedManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/WalkSpeedManager.lua
-- Script Place: ACT 1: Village

local WalkSpeedManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))

-- Ensure the RemoteEvent for walkspeed updates exists
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local updateEventName = "UpdateWalkSpeedModifierEvent"
local updateEvent = RemoteEvents:FindFirstChild(updateEventName)
if not updateEvent then
	updateEvent = Instance.new("RemoteEvent")
	updateEvent.Name = updateEventName
	updateEvent.Parent = RemoteEvents
end

local BASE_WALK_SPEED = 16
local RELOAD_MODIFIER = 8 - BASE_WALK_SPEED -- Pre-calculate the modifier for reloading.
local playerModifiers = {} -- { [player.UserId] = { modifierName = value, ... } }

--[[
    Updates the player's walkspeed based on the sum of all active modifiers.
]]
function WalkSpeedManager.update_speed(player)
	local char = player.Character
	if not char or not char:FindFirstChild("Humanoid") then return end

	local humanoid = char.Humanoid
	local modifiers = playerModifiers[player.UserId]
	if not modifiers then
		humanoid.WalkSpeed = BASE_WALK_SPEED
		return
	end

	local totalSpeed = BASE_WALK_SPEED
	for _, value in pairs(modifiers) do
		totalSpeed = totalSpeed + value
	end

	-- Ensure speed doesn't drop below a minimum threshold (e.g., 1) unless set to 0 by a specific state.
	if totalSpeed < 0 then
		totalSpeed = 1
	end

	-- If a "knock" modifier exists, speed is forced to 0.
	if modifiers.knock then
		totalSpeed = 0
	end

	humanoid.WalkSpeed = totalSpeed
end

--[[
    Adds or updates a speed modifier for a player.
    Example: WalkSpeedManager.add_modifier(player, "sprint", 8)
]]
function WalkSpeedManager.add_modifier(player, modifierName, value)
	local userId = player.UserId
	if not playerModifiers[userId] then
		playerModifiers[userId] = {}
	end

	playerModifiers[userId][modifierName] = value
	WalkSpeedManager.update_speed(player)
end

--[[
    Removes a speed modifier from a player.
    Example: WalkSpeedManager.remove_modifier(player, "sprint")
]]
function WalkSpeedManager.remove_modifier(player, modifierName)
	local userId = player.UserId
	if not playerModifiers[userId] or not playerModifiers[userId][modifierName] then
		return
	end

	playerModifiers[userId][modifierName] = nil
	WalkSpeedManager.update_speed(player)
end

--[[
    Initializes a player's speed management when they join or their character spawns.
]]
local function setupPlayer(player)
	playerModifiers[player.UserId] = {}
	player.CharacterAdded:Connect(function(character)
		-- Wait for humanoid to exist
		local humanoid = character:WaitForChild("Humanoid")
		playerModifiers[player.UserId] = {}
		humanoid.WalkSpeed = BASE_WALK_SPEED

		-- Handle player death
		humanoid.Died:Connect(function()
			playerModifiers[player.UserId] = {}
		end)
	end)
end

--[[
    Cleans up when a player leaves.
]]
local function onPlayerRemoving(player)
	if playerModifiers[player.UserId] then
		playerModifiers[player.UserId] = nil
	end
end

-- Connect events for players already in game and for new players
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

-- Listen for client requests to update speed modifiers
updateEvent.OnServerEvent:Connect(function(player, modifierName, value)
	if not player or not modifierName or type(modifierName) ~= "string" then return end

	-- Allowlist of client-updatable modifiers
	local allowedModifiers = { sprint = true, aim = true, reload = true }
	if not allowedModifiers[modifierName] then
		warn("WalkSpeedManager: Disallowed modifier '" .. modifierName .. "' from " .. player.Name)
		return
	end

	-- Handle AIM and RELOAD (boolean logic)
	if modifierName == "aim" or modifierName == "reload" then
		if value == true then
			local modifierValue = 0
			if modifierName == "reload" then
				modifierValue = RELOAD_MODIFIER
			elseif modifierName == "aim" then
				local char = player.Character
				local tool = char and char:FindFirstChildOfClass("Tool")
				if tool and WeaponModule.Weapons[tool.Name] then
					local weaponStats = WeaponModule.Weapons[tool.Name]
					local adsSpeed = weaponStats.ADS_WalkSpeed or BASE_WALK_SPEED
					modifierValue = adsSpeed - BASE_WALK_SPEED
				end
			end
			WalkSpeedManager.add_modifier(player, modifierName, modifierValue)
		else -- value is false or nil, so remove the modifier
			WalkSpeedManager.remove_modifier(player, modifierName)
		end
	-- Handle SPRINT (numeric logic, which may be sent from other scripts)
	elseif modifierName == "sprint" then
		if value and type(value) == "number" then
			WalkSpeedManager.add_modifier(player, modifierName, value)
		else -- value is nil or not a number, so remove the modifier
			WalkSpeedManager.remove_modifier(player, "sprint")
		end
	end
end)

return WalkSpeedManager
