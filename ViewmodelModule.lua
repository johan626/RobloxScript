-- ViewmodelModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/ViewmodelModule.lua
-- Script Place: ACT 1: Village

local ViewmodelModule = {}
ViewmodelModule.__index = ViewmodelModule

-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

function ViewmodelModule.new(tool, player, weaponName, weaponModule)
	local self = setmetatable({}, ViewmodelModule)

	self.tool = tool
	self.player = player
	self.weaponName = weaponName
	self.WeaponModule = weaponModule
	self.camera = workspace.CurrentCamera

	-- Viewmodel state
	self.viewmodel = nil
	self.viewmodelHandle = nil
	self.adsBlend = 0
	self.currentSway = Vector3.new()
	self.targetSway = Vector3.new()
	self.currentBob = Vector3.new()
	self.targetBob = Vector3.new()
	self.lastCameraCFrame = self.camera.CFrame
	self.bobTime = 0
	self.breathTime = 0
	self.currentVisualRecoil = 0
	self.targetVisualRecoil = 0

	-- Weapon stats
	local weaponStats = self.WeaponModule.Weapons[self.weaponName]
	self.swayIntensity = weaponStats.SwayIntensity or 0.5
	self.swaySmoothing = weaponStats.SwaySmoothing or 10
	self.bobIntensity = weaponStats.BobIntensity or 0.5
	self.bobSmoothing = weaponStats.BobSmoothing or 10
	self.bobFrequency = weaponStats.BobFrequency or 10
	self.breathIntensity = weaponStats.BreathIntensity or 0.1
	self.breathSpeed = weaponStats.BreathSpeed or 2
	self.visualRecoilIntensity = weaponStats.VisualRecoilIntensity or 0.5
	self.visualRecoilKick = weaponStats.VisualRecoilKick or 0.3
	self.visualRecoilRecovery = weaponStats.VisualRecoilRecovery or 5

	return self
end

function ViewmodelModule:cleanupOldViewmodels()
	for _, inst in ipairs(self.camera:GetChildren()) do
		if (inst:IsA("Model") and inst:GetAttribute("IsViewmodel")) or inst.Name == "FirstPersonViewmodel" then
			inst:Destroy()
		elseif inst:IsA("BasePart") and inst.Name == "ViewmodelHandle" then
			inst:Destroy()
		end
	end
end

function ViewmodelModule:calculateSway(delta)
	local weaponStats = self.WeaponModule.Weapons[self.weaponName]
	if not weaponStats then return Vector3.new() end

	local intensity = weaponStats.SwayIntensity or 0.5
	local smoothing = weaponStats.SwaySmoothing or 10

	if self.isAiming then
		intensity = intensity * 0.3
	end

	local swayFactor = intensity / smoothing
	return Vector3.new(
		-delta.Y * swayFactor * 0.5,
		-delta.X * swayFactor,
		delta.X * swayFactor * 0.2
	)
end

function ViewmodelModule:calculateBob(dt)
	local weaponStats = self.WeaponModule.Weapons[self.weaponName]
	if not weaponStats then return Vector3.new() end

	local intensity = weaponStats.BobIntensity or 0.5
	local frequency = weaponStats.BobFrequency or 10

	if self.isAiming then
		intensity = intensity * 0.3
	end

	local char = self.player.Character
	if not char then return Vector3.new() end

	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return Vector3.new() end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return Vector3.new() end

	local velocity = hrp.Velocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local maxSpeed = humanoid.WalkSpeed

	if speed < 0.1 then
		self.bobTime = 0
		return Vector3.new()
	end

	self.bobTime = self.bobTime + dt * (speed / maxSpeed) * frequency

	local bobX = math.sin(self.bobTime * 0.5) * intensity * 0.1
	local bobY = math.sin(self.bobTime) * intensity * 0.2
	local bobZ = math.cos(self.bobTime * 0.5) * intensity * 0.05

	return Vector3.new(bobX, bobY, bobZ)
end

function ViewmodelModule:calculateBreath(dt)
	self.breathTime = self.breathTime + dt * self.breathSpeed
	local breathOffset = math.sin(self.breathTime) * self.breathIntensity * 0.1

	if self.isAiming then
		breathOffset = breathOffset * 0.3
	end

	return Vector3.new(0, breathOffset, 0)
end

function ViewmodelModule:applyVisualRecoil()
	self.targetVisualRecoil = self.targetVisualRecoil + self.visualRecoilKick
end

function ViewmodelModule:createViewmodel()
	self:cleanupOldViewmodels()
	if self.viewmodel then
		self.viewmodel:Destroy()
		self.viewmodel = nil
	end

	self.viewmodel = self.tool:Clone()
	self.viewmodel.Name = "FirstPersonViewmodel"
	self.viewmodel:SetAttribute("IsViewmodel", true)
	self.viewmodel.Parent = self.camera
	self.viewmodel:ClearAllChildren()

	local originalHandle = self.tool:FindFirstChild("Handle")
	if originalHandle then
		self.viewmodelHandle = originalHandle:Clone()
		self.viewmodelHandle.Name = "ViewmodelHandle"
		self.viewmodelHandle.Parent = self.viewmodel

		for _, child in ipairs(self.viewmodelHandle:GetChildren()) do
			if child:IsA("Weld") or child:IsA("WeldConstraint") then
				child:Destroy()
			end
		end

		local weaponStats = self.WeaponModule.Weapons[self.weaponName]
		local viewmodelPosition = weaponStats.ViewmodelPosition or Vector3.new(1.5, -1, -2.5)
		local viewmodelRotation = weaponStats.ViewmodelRotation or Vector3.new(0, 0, 0)

		self.viewmodelHandle.CFrame = self.camera.CFrame * CFrame.new(viewmodelPosition) * CFrame.Angles(
			math.rad(viewmodelRotation.X),
			math.rad(viewmodelRotation.Y),
			math.rad(viewmodelRotation.Z)
		)
		self.viewmodelHandle.Anchored = true
	end

	if self.tool.Parent == self.player.Character then
		self.tool.Handle.Transparency = 1
		for _, child in ipairs(self.tool:GetChildren()) do
			if child:IsA("BasePart") and child.Name ~= "Handle" then
				child.Transparency = 1
			elseif child:IsA("Decal") then
				child.Transparency = 1
			end
		end
	end
end

function ViewmodelModule:destroyViewmodel()
	if self.viewmodel then
		self.viewmodel:Destroy()
		self.viewmodel = nil
		self.viewmodelHandle = nil
		self:cleanupOldViewmodels()
	end

	if not self.tool or not self.tool.Parent or not self.tool:FindFirstChild("Handle") then
		return
	end

	self.tool.Handle.Transparency = 0
	for _, child in ipairs(self.tool:GetChildren()) do
		if child:IsA("BasePart") and child.Name ~= "Handle" then
			child.Transparency = 0
		elseif child:IsA("Decal") then
			child.Transparency = 0
		end
	end
end

function ViewmodelModule:updateViewmodel(dt, isAiming)
	self.isAiming = isAiming
	local weaponStats = self.WeaponModule.Weapons[self.weaponName]
	local vmBlendTime = weaponStats.ADS_BlendTimeVM or weaponStats.TransitionTime or 0.2
	local step = math.clamp(dt / vmBlendTime, 0, 1)

	if isAiming then
		self.adsBlend = math.clamp(self.adsBlend + step, 0, 1)
	else
		self.adsBlend = math.clamp(self.adsBlend - step, 0, 1)
	end

	if not self.viewmodelHandle or not self.viewmodel then return end

	local cameraDelta = self.camera.CFrame:ToObjectSpace(self.lastCameraCFrame)
	self.lastCameraCFrame = self.camera.CFrame

	self.targetSway = self:calculateSway(Vector2.new(cameraDelta.Y, cameraDelta.X))
	self.targetBob = self:calculateBob(dt)
	local breathOffset = self:calculateBreath(dt)

	self.currentVisualRecoil = self.currentVisualRecoil + (self.targetVisualRecoil - self.currentVisualRecoil) * dt * self.visualRecoilRecovery
	self.targetVisualRecoil = self.targetVisualRecoil * (1 - dt * self.visualRecoilRecovery)

	self.currentSway = self.currentSway:Lerp(self.targetSway, dt * self.swaySmoothing)
	self.currentBob = self.currentBob:Lerp(self.targetBob, dt * self.bobSmoothing)

	local weaponStats = self.WeaponModule.Weapons[self.weaponName]
	local viewmodelPosition = weaponStats.ViewmodelPosition or Vector3.new(1.5, -1, -2.5)
	local viewmodelRotation = weaponStats.ViewmodelRotation or Vector3.new(0, 0, 0)
	local hipBaseCF = self.camera.CFrame
		* CFrame.new(viewmodelPosition)
		* CFrame.Angles(math.rad(viewmodelRotation.X), math.rad(viewmodelRotation.Y), math.rad(viewmodelRotation.Z))

	local adsPosition
	local adsRotation

	if weaponStats.Skins and weaponStats.Use_Skin and weaponStats.Skins[weaponStats.Use_Skin] then
		local skin = weaponStats.Skins[weaponStats.Use_Skin]
		if UserInputService.TouchEnabled and skin.ADS_Position_Mobile then
			adsPosition = skin.ADS_Position_Mobile
			adsRotation = skin.ADS_Rotation_Mobile or skin.ADS_Rotation
		else
			adsPosition = skin.ADS_Position
			adsRotation = skin.ADS_Rotation
		end
	end

	local adsBaseCF
	if adsPosition then
		adsBaseCF = self.camera.CFrame * CFrame.new(adsPosition)
		if adsRotation then
			adsBaseCF = adsBaseCF * CFrame.Angles(math.rad(adsRotation.X), math.rad(adsRotation.Y), math.rad(adsRotation.Z))
		end
	else
		adsBaseCF = hipBaseCF
	end

	local baseCFrame = hipBaseCF:Lerp(adsBaseCF, self.adsBlend)

	local finalCFrame = baseCFrame * 
		CFrame.Angles(
			math.rad(self.currentSway.X),
			math.rad(self.currentSway.Y),
			math.rad(self.currentSway.Z)
		) *
		CFrame.new(self.currentBob + breathOffset) *
		CFrame.new(0, 0, -self.currentVisualRecoil)

	self.viewmodelHandle.CFrame = finalCFrame
end

return ViewmodelModule
