-- BuildingModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BuildingModule.lua
-- Script Place: ACT 1: Village

local BuildingManager = {}

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local buildingsFolder = Workspace:FindFirstChild("Buildings")
local backupFolder = ServerStorage:FindFirstChild("BuildingsBackup")

function BuildingManager.hideBuildings()
	if not buildingsFolder then
		warn("BuildingManager: 'Buildings' folder not found in Workspace.")
		return
	end

	print("BuildingManager: Hiding buildings.")
	for _, building in ipairs(buildingsFolder:GetChildren()) do
		building.Parent = backupFolder
	end
end

function BuildingManager.restoreBuildings()
	if not buildingsFolder then
		warn("BuildingManager: 'Buildings' folder not found in Workspace.")
		return
	end

	print("BuildingManager: Restoring buildings.")
	for _, building in ipairs(backupFolder:GetChildren()) do
		building.Parent = buildingsFolder
	end
end

return BuildingManager
