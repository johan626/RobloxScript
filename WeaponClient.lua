-- WeaponClient.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/WeaponClient.lua
-- Script Place: ACT 1: Village

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BindableEvents = ReplicatedStorage:WaitForChild("BindableEvents")
local ModuleScriptReplicatedStorage = ReplicatedStorage:WaitForChild("ModuleScript")

-- Modules
local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local ViewmodelModule = require(ModuleScriptReplicatedStorage:WaitForChild("ViewmodelModule"))
local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))

-- Remote Events
local UpdateWalkSpeedModifierEvent = RemoteEvents:WaitForChild("UpdateWalkSpeedModifierEvent")
local ShootEvent = RemoteEvents:WaitForChild("ShootEvent")
local ReloadEvent = RemoteEvents:WaitForChild("ReloadEvent")
local TracerEvent = RemoteEvents:WaitForChild("TracerEvent")
local MuzzleFlashEvent = RemoteEvents:WaitForChild("MuzzleFlashEvent")
local AmmoUpdateEvent = RemoteEvents:WaitForChild("AmmoUpdateEvent")
local KnockEvent = RemoteEvents:WaitForChild("KnockEvent")
local GameOverEvent = RemoteEvents:WaitForChild("GameOverEvent")

-- Bindable Events for Mobile Controls
local startAutoFireEvent = BindableEvents:FindFirstChild("StartAutoFireEvent") or Instance.new("BindableEvent", BindableEvents)
startAutoFireEvent.Name = "StartAutoFireEvent"
local stopAutoFireEvent = BindableEvents:FindFirstChild("StopAutoFireEvent") or Instance.new("BindableEvent", BindableEvents)
stopAutoFireEvent.Name = "StopAutoFireEvent"

-- Bindable Event for Mobile Aim Toggle
local toggleAimEvent = BindableEvents:FindFirstChild("ToggleAimEvent") or Instance.new("BindableEvent", BindableEvents)
toggleAimEvent.Name = "ToggleAimEvent"
local aimStatusChangedEvent = BindableEvents:FindFirstChild("AimStatusChangedEvent") or Instance.new("BindableEvent", BindableEvents)
aimStatusChangedEvent.Name = "AimStatusChangedEvent"

-- Bindable Event for Reload Request
local requestReloadEvent = BindableEvents:FindFirstChild("RequestReloadEvent") or Instance.new("BindableEvent", BindableEvents)
requestReloadEvent.Name = "RequestReloadEvent"


-- State variables
local currentWeapon = nil
local weaponName = nil
local weaponStats = nil
local viewmodel = nil

local canShoot = true
local reloading = false
local isMouseDown = false
local currentAmmo = 0
local isAiming = false
local isGameOver = false
local isKnocked = false

local originalFoV = camera.FieldOfView
local nextFireTime = 0

local adsHeldByFire = false
local adsTransitionTime = 0.2
local currentRecoil = 0
local recoilDecayRate = 1

local defaultGrip = nil
local adsTween = nil
local fovTween = nil
local lastTargetFoV = originalFoV
local currentReloadSound = nil

local connections = {}

-- SNIPER_SET for mobile controls
local SNIPER_SET = { ["L115A1"]=true, ["DSR"]=true, ["Barrett-M82"]=true }

-- Functions
local function cleanupWeapon()
	if not currentWeapon then return end

	if isAiming then
		isAiming = false
		aimStatusChangedEvent:Fire(false) -- Fire status update
		currentWeapon:SetAttribute("IsAiming", false)
		if player.Character then
			player.Character:SetAttribute("IsAiming", false)
			player.Character:SetAttribute("CameraLock", false) -- Pastikan kunci dilepas
		end
	end
	if reloading then
		reloading = false
		if player.Character then player.Character:SetAttribute("IsReloading", false) end
	end

	if adsTween then adsTween:Cancel() adsTween = nil end
	if fovTween then fovTween:Cancel() fovTween = nil end

	camera.FieldOfView = originalFoV
	lastTargetFoV = originalFoV

	if currentReloadSound then
		currentReloadSound:Stop()
		currentReloadSound = nil
	end

	-- Remove any weapon-related modifiers
	UpdateWalkSpeedModifierEvent:FireServer("aim", false)
	UpdateWalkSpeedModifierEvent:FireServer("reload", false)

	if viewmodel then
		viewmodel:destroyViewmodel()
		viewmodel = nil
	end

	for _, conn in pairs(connections) do
		conn:Disconnect()
	end
	table.clear(connections)

	currentWeapon = nil
	weaponName = nil
	weaponStats = nil
	isMouseDown = false
end

local function stopAdsTween()
	if adsTween then
		adsTween:Cancel()
		adsTween = nil
	end
end

local function stopFovTween()
	if fovTween then
		fovTween:Cancel()
		fovTween = nil
	end
end

local function transitionToHip()
	stopAdsTween()
	if not defaultGrip or not currentWeapon then return end
	local tweenInfo = TweenInfo.new(adsTransitionTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	adsTween = TweenService:Create(currentWeapon, tweenInfo, {Grip = defaultGrip})
	adsTween:Play()
end

local function transitionToADS()
	if not weaponStats or not currentWeapon then return end
	stopAdsTween()

	local adsPosition, adsRotation

	-- Dapatkan nama skin dari atribut tool, dengan fallback ke Use_Skin lalu ke Default Skin.
	local equippedSkinName = currentWeapon:GetAttribute("EquippedSkin") or weaponStats.Use_Skin or "Default Skin"
	local skin = weaponStats.Skins[equippedSkinName] or weaponStats.Skins["Default Skin"]

	if skin then
		if UserInputService.TouchEnabled and skin.ADS_Position_Mobile then
			adsPosition = skin.ADS_Position_Mobile
			adsRotation = skin.ADS_Rotation_Mobile or skin.ADS_Rotation
		else
			adsPosition = skin.ADS_Position
			adsRotation = skin.ADS_Rotation
		end
	end

	if not adsPosition then return end

	local targetCFrame = CFrame.new(adsPosition)
	if adsRotation then
		targetCFrame = targetCFrame * CFrame.Angles(math.rad(adsRotation.X), math.rad(adsRotation.Y), math.rad(adsRotation.Z))
	end

	local tweenInfo = TweenInfo.new(adsTransitionTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	adsTween = TweenService:Create(currentWeapon, tweenInfo, {Grip = targetCFrame})
	adsTween:Play()
end

local function _computeFireRate()
	if not weaponStats then return 0 end
	local rate = weaponStats.FireRate
	if player.Character and player.Character:GetAttribute("RateBoost") then
		rate = rate * 0.7
	end
	return rate
end

local function isFireCooldownReady()
	return tick() >= (nextFireTime or 0)
end

local function markJustFired()
	nextFireTime = tick() + _computeFireRate()
end

local function setupWeapon(tool)
	cleanupWeapon() -- Clean up previous weapon first

	currentWeapon = tool
	weaponName = tool.Name
	weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return end

	tool.CanBeDropped = false
	defaultGrip = tool.Grip
	originalFoV = camera.FieldOfView
	lastTargetFoV = originalFoV
	adsTransitionTime = weaponStats.TransitionTime or 0.2
	reloading = false
	isAiming = false
	tool:SetAttribute("IsAiming", false)
	currentAmmo = tool:GetAttribute("Ammo") or weaponStats.MaxAmmo

	viewmodel = ViewmodelModule.new(tool, player, weaponName, WeaponModule)
	viewmodel:createViewmodel()

	local function applySkinClient()
		if not weaponStats or not weaponStats.Skins then return end

		-- Dapatkan nama skin dari atribut tool, dengan fallback ke Use_Skin lalu ke Default Skin.
		local equippedSkinName = tool:GetAttribute("EquippedSkin") or weaponStats.Use_Skin or "Default Skin"
		local skin = weaponStats.Skins[equippedSkinName] or weaponStats.Skins["Default Skin"]

		if not skin then return end

		local function setMesh(part)
			if not part or not part:IsA("BasePart") then return end
			local mesh = part:FindFirstChildOfClass("SpecialMesh")
			if not mesh then
				mesh = Instance.new("SpecialMesh")
				mesh.Name = "Mesh"
				mesh.Parent = part
			end
			if skin.MeshId and skin.MeshId ~= "" then mesh.MeshId = skin.MeshId end
			if skin.TextureId and skin.TextureId ~= "" then mesh.TextureId = skin.TextureId end
		end

		setMesh(tool:FindFirstChild("Handle"))
		if viewmodel.viewmodelHandle then
			setMesh(viewmodel.viewmodelHandle)
		end
	end
	applySkinClient()

	-- Connect specific tool events
	table.insert(connections, tool.Destroying:Connect(cleanupWeapon))
	table.insert(connections, tool.AncestryChanged:Connect(function(_, parent)
		if parent ~= player.Character then
			cleanupWeapon()
		end
	end))

	-- NEW: Listen for late attribute changes to fix skin race condition
	table.insert(connections, tool.AttributeChanged:Connect(function(attribute)
		if attribute == "EquippedSkin" then
			applySkinClient()
		end
	end))
end

-- Input Handling
local function handleReloadRequest()
	if not currentWeapon or not weaponStats or reloading or isKnocked then return end

	local isSprinting = player.Character and player.Character:GetAttribute("IsSprinting")
	if isSprinting then
		player.Character:SetAttribute("RequestStopSprint", true)
	end

	reloading = true
	if player.Character then player.Character:SetAttribute("IsReloading", true) end

	-- Jika sedang ADS, batalkan ADS & modifier speednya dulu (THE FIX)
	if isAiming then
		isAiming = false
		aimStatusChangedEvent:Fire(false) -- Fire status update
		UpdateWalkSpeedModifierEvent:FireServer("aim", false)
	end

	currentWeapon:SetAttribute("IsAiming", false)
	if player.Character then
		player.Character:SetAttribute("IsAiming", false)
	end
	transitionToHip()

	UpdateWalkSpeedModifierEvent:FireServer("reload", true)
	ReloadEvent:FireServer(currentWeapon)
end

local function onInputBegan(input, gpe)
	if gpe then return end
	if not currentWeapon or not weaponStats then return end

	-- ADS (Right-click)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if not reloading and not isKnocked then
			isAiming = true
			currentWeapon:SetAttribute("IsAiming", true)
			if player.Character then
				player.Character:SetAttribute("IsAiming", true)
				player.Character:SetAttribute("CameraLock", true) -- Kunci kamera
			end
			transitionToADS()
			UpdateWalkSpeedModifierEvent:FireServer("aim", true)

			-- Mulai transisi FOV
			stopFovTween()
			fovTween = TweenService:Create(camera, TweenInfo.new(adsTransitionTime), {FieldOfView = weaponStats.ADSFoV})
			fovTween:Play()
		end
	-- Reload (R key)
	elseif input.KeyCode == Enum.KeyCode.R then
		handleReloadRequest()
	end
end

local function onInputEnded(input, gpe)
	if not currentWeapon or not weaponStats then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if isAiming then -- Hanya jika state benar-benar berubah
			isAiming = false
			aimStatusChangedEvent:Fire(false) -- Fire status update
			currentWeapon:SetAttribute("IsAiming", false)
			if player.Character then
				player.Character:SetAttribute("IsAiming", false)
			end
			transitionToHip()
			UpdateWalkSpeedModifierEvent:FireServer("aim", false)

			-- Langsung lepas kunci kamera, jangan tween FOV lagi
			if player.Character then
				player.Character:SetAttribute("CameraLock", false)
			end
		end
	end
end

local function onButton1Down()
	if currentWeapon and not reloading and not isKnocked then
		isMouseDown = true
		if currentAmmo <= 0 then
			AudioManager.playSound(weaponStats.Sounds.Empty, currentWeapon)
		end
	end
end

local function onButton1Up()
	isMouseDown = false
end

-- Touch Controls
local lastTapTime = 0
local lastTapPosition = nil
local sniperHoldTouch = nil
local sniperHoldActive = false
local autoFireTouch = nil
local isAutoFiring = false

local function getDoubleTapUsesADS()
	local v = player:GetAttribute("DoubleTapUsesADS")
	return v == nil and true or v
end

local function isSniperWeapon()
	return SNIPER_SET[weaponName] == true
end

local function canMobileShoot()
	return currentWeapon and not reloading and not isKnocked and currentAmmo > 0
end

local function fireFromCenterOnce()
	if not isFireCooldownReady() then return end
	markJustFired()

	local viewportSize = camera.ViewportSize
	local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
	local ray = camera:ViewportPointToRay(screenCenter.X, screenCenter.Y)
	local cameraDirection = camera.CFrame.LookVector

	ShootEvent:FireServer(currentWeapon, cameraDirection, isAiming)
	currentAmmo = currentAmmo - 1
	if viewmodel then viewmodel:applyVisualRecoil() end

	local handle = viewmodel and viewmodel.viewmodelHandle or currentWeapon:FindFirstChild("Handle")
	if handle then
		local startPos = handle.CFrame:PointToWorldSpace(weaponStats.TracerOffset or Vector3.new(0, 0, 0))
		-- For visual effect, we still need a target position for the tracer
		local hitPosition = ray.Origin + ray.Direction * 1000
		TracerEvent:FireServer(startPos, hitPosition, weaponName)
		MuzzleFlashEvent:FireServer(handle, weaponName)
	end

	AudioManager.playSound(weaponStats.Sounds.Fire, currentWeapon)
	local recoilFactor = isAiming and 0.5 or 1
	currentRecoil = math.min(10, currentRecoil + (weaponStats.Recoil * recoilFactor))
end

local function handleStartAutoFire(touchObj)
	if isAutoFiring then return end
	isAutoFiring = true
	autoFireTouch = touchObj

	task.spawn(function()
		while isAutoFiring do
			if not canMobileShoot() then break end
			while isAutoFiring and not isFireCooldownReady() do task.wait(0.01) end
			if not isAutoFiring or not canMobileShoot() then break end

			fireFromCenterOnce()
			task.wait(_computeFireRate())

			if currentAmmo <= 0 then
				if adsHeldByFire or isAiming then
					adsHeldByFire = false
					isAiming = false
					currentWeapon:SetAttribute("IsAiming", false)
					transitionToHip()
					UpdateWalkSpeedModifierEvent:FireServer("aim", false)
				end
				break
			end
			if reloading or isKnocked or not currentWeapon then break end
		end
		isAutoFiring = false
		autoFireTouch = nil
	end)
end

local function handleStopAutoFire()
	isAutoFiring = false
end

startAutoFireEvent.Event:Connect(handleStartAutoFire)
stopAutoFireEvent.Event:Connect(handleStopAutoFire)


local function onTouchStarted(touch, gpe)
	if gpe or not UserInputService.TouchEnabled or reloading or isKnocked or not currentWeapon or not weaponStats then return end

	-- Double Tap Logic
	if player:GetAttribute("FireControlType") == "DoubleTap" then
		local currentTime = tick()
		local tapPosition = touch.Position
		if tapPosition.X > camera.ViewportSize.X / 2 then
			if currentTime - lastTapTime < 0.3 and lastTapPosition then
				if player.Character and player.Character:GetAttribute("IsSprinting") == true then
					player.Character:SetAttribute("RequestStopSprint", true)
				end

				if currentAmmo <= 0 then
					AudioManager.playSound(weaponStats.Sounds.Empty, currentWeapon)
					return
				end

				if getDoubleTapUsesADS() then
					if not isAiming then
						isAiming = true
						currentWeapon:SetAttribute("IsAiming", true)
						if player.Character then
							player.Character:SetAttribute("IsAiming", true)
						end
						transitionToADS()
						UpdateWalkSpeedModifierEvent:FireServer("aim", true) -- FIX: Add walkspeed modifier
					end
					adsHeldByFire = true
				else
					if isAiming then
						isAiming = false
						currentWeapon:SetAttribute("IsAiming", false)
						if player.Character then
							player.Character:SetAttribute("IsAiming", false)
						end
						transitionToHip()
					end
					adsHeldByFire = false
				end

				if isSniperWeapon() then
					if not isAiming then
						isAiming = true
						currentWeapon:SetAttribute("IsAiming", true)
						if player.Character then
							player.Character:SetAttribute("IsAiming", true)
						end
						transitionToADS()
					end
					adsHeldByFire = true
					sniperHoldActive = true
					sniperHoldTouch = touch
				else
					handleStartAutoFire(touch)
				end
			end
			lastTapTime = currentTime
			lastTapPosition = tapPosition
		end
	end
end

local function onTouchEnded(touch, gpe)
	if not currentWeapon then return end
	if autoFireTouch and touch == autoFireTouch then
		isAutoFiring = false
		if adsHeldByFire then
			adsHeldByFire = false
			isAiming = false
			currentWeapon:SetAttribute("IsAiming", false)
			if player.Character then
				player.Character:SetAttribute("IsAiming", false)
			end
			transitionToHip()
			UpdateWalkSpeedModifierEvent:FireServer("aim", false) -- FIX: Reset walkspeed modifier
		end
	end
	if sniperHoldTouch and touch == sniperHoldTouch then
		if canMobileShoot() and isFireCooldownReady() then
			fireFromCenterOnce()
		end
		sniperHoldActive = false
		sniperHoldTouch = nil
		if adsHeldByFire then
			adsHeldByFire = false
			isAiming = false
			currentWeapon:SetAttribute("IsAiming", false)
			if player.Character then
				player.Character:SetAttribute("IsAiming", false)
			end
			transitionToHip()
		end
	end
end

-- Game Loop
local function onRenderStepped(dt)
	if viewmodel then
		viewmodel:updateViewmodel(dt, isAiming)
	end
end

local function onStepped(dt)
	if not currentWeapon or not weaponStats then
		if currentRecoil > 0 then
			currentRecoil = math.max(0, currentRecoil - recoilDecayRate)
			local currentCFrame = camera.CFrame
			local recoilCFrame = CFrame.Angles(math.rad(currentRecoil), 0, 0)
			camera.CFrame = currentCFrame * recoilCFrame
		end
		return
	end

	if currentAmmo <= 0 then isMouseDown = false end

	if not UserInputService.TouchEnabled and isMouseDown and canShoot and not reloading and not isKnocked then
		if player.Character and player.Character:GetAttribute("IsSprinting") == true then return end
		if not isFireCooldownReady() then return end

		markJustFired()
		canShoot = false

		local cameraDirection = camera.CFrame.LookVector
		ShootEvent:FireServer(currentWeapon, cameraDirection, isAiming)
		currentAmmo = currentAmmo - 1
		if viewmodel then viewmodel:applyVisualRecoil() end

		local handle = viewmodel and viewmodel.viewmodelHandle or currentWeapon:FindFirstChild("Handle")
		if handle then
			local startPos = handle.CFrame:PointToWorldSpace(weaponStats.TracerOffset or Vector3.new(0,0,0))
			-- For visual effect, we still need a target position for the tracer
			local hitPosition = mouse.Hit.Position
			TracerEvent:FireServer(startPos, hitPosition, weaponName)
			MuzzleFlashEvent:FireServer(handle, weaponName)
		end

		AudioManager.playSound(weaponStats.Sounds.Fire, currentWeapon)

		local recoilFactor = isAiming and 0.5 or 1
		currentRecoil = math.min(10, currentRecoil + (weaponStats.Recoil * recoilFactor))

		task.wait(_computeFireRate())
		canShoot = true
	end

	local currentCFrame = camera.CFrame
	local recoilCFrame = CFrame.Angles(math.rad(currentRecoil), 0, 0)
	camera.CFrame = currentCFrame * recoilCFrame
	currentRecoil = math.max(0, currentRecoil - recoilDecayRate)
end

-- Remote Event Handlers
AmmoUpdateEvent.OnClientEvent:Connect(function(updatedWeaponName, ammo, reserveAmmo, isVisible, isReloadingFromServer)
	if not currentWeapon or updatedWeaponName ~= weaponName then return end

	currentAmmo = ammo
	if currentAmmo <= 0 and (adsHeldByFire or isAiming) then
		adsHeldByFire = false
		isAiming = false
		currentWeapon:SetAttribute("IsAiming", false)
		if player.Character then
			player.Character:SetAttribute("IsAiming", false)
			player.Character:SetAttribute("CameraLock", false) -- Lepas kunci
		end
		transitionToHip()
		UpdateWalkSpeedModifierEvent:FireServer("aim", false)
	end

	if isReloadingFromServer then
		if not currentReloadSound then
			currentReloadSound = AudioManager.createSound(weaponStats.Sounds.Reload, currentWeapon)
			if currentReloadSound then
				currentReloadSound:Play()
				reloading = true
			end
		end
	else
		if currentReloadSound then
			currentReloadSound:Stop()
			currentReloadSound = nil
		end
		reloading = false
		if player.Character then player.Character:SetAttribute("IsReloading", false) end

		UpdateWalkSpeedModifierEvent:FireServer("reload", false)
		if isAiming then
			UpdateWalkSpeedModifierEvent:FireServer("aim", true)
		end
	end
end)

KnockEvent.OnClientEvent:Connect(function(knockStatus)
	isKnocked = knockStatus
	if isKnocked and currentWeapon then
		if isAiming then
			isAiming = false
			aimStatusChangedEvent:Fire(false)
		end
		isMouseDown = false
		currentWeapon:SetAttribute("IsAiming", false)
		if player.Character then
			player.Character:SetAttribute("IsAiming", false)
		end
		transitionToHip()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:UnequipTools() end
		cleanupWeapon()
	end
end)

GameOverEvent.OnClientEvent:Connect(function()
	isGameOver = true
	if isAiming then
		isAiming = false
		aimStatusChangedEvent:Fire(false)
	end
	isMouseDown = false
	if currentWeapon then
		currentWeapon:SetAttribute("IsAiming", false)
		if player.Character then
			player.Character:SetAttribute("IsAiming", false)
			player.Character:SetAttribute("CameraLock", false) -- Lepas kunci
		end
		transitionToHip()
	end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum:UnequipTools() end
	cleanupWeapon()
end)

local function onCharacterAdded(character)
	cleanupWeapon()

	local humanoid = character:WaitForChild("Humanoid")

	-- Ketika ada objek baru di dalam karakter (bisa berupa Tool)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and WeaponModule.Weapons[child.Name] then
			if isGameOver or isKnocked then
				humanoid:UnequipTools()
				return
			end
			setupWeapon(child)
		end
	end)

	-- Ketika Tool dilepas dari karakter
	character.ChildRemoved:Connect(function(child)
		if child == currentWeapon then
			cleanupWeapon()
		end
	end)

	character.Destroying:Connect(cleanupWeapon)
end

-- Mobile Aim Button Handler
local function handleToggleAim()
	if not currentWeapon or not weaponStats or reloading or isKnocked then return end

	-- Toggle the aiming state
	isAiming = not isAiming
	currentWeapon:SetAttribute("IsAiming", isAiming)
	if player.Character then
		player.Character:SetAttribute("IsAiming", isAiming)
	end

	if isAiming then
		if player.Character then player.Character:SetAttribute("CameraLock", true) end
		transitionToADS()
		UpdateWalkSpeedModifierEvent:FireServer("aim", true)

		-- Mulai transisi FOV
		stopFovTween()
		fovTween = TweenService:Create(camera, TweenInfo.new(adsTransitionTime), {FieldOfView = weaponStats.ADSFoV})
		fovTween:Play()
	else
		transitionToHip()
		UpdateWalkSpeedModifierEvent:FireServer("aim", false)

		-- Langsung lepas kunci kamera, jangan tween FOV lagi
		if player.Character then
			player.Character:SetAttribute("CameraLock", false)
		end
	end
	-- Fire status update to UI
	aimStatusChangedEvent:Fire(isAiming)
end

-- BARU: Logika untuk mereplikasi skin pada pemain lain
local function applySkinToCharacterTool(tool)
	if not tool or not tool:IsA("Tool") or not tool:FindFirstChild("Handle") then
		return
	end

	local weaponName = tool.Name
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats or not weaponStats.Skins then
		return
	end

	-- Beri jeda singkat untuk memastikan atribut sudah direplikasi
	task.wait()

	local equippedSkinName = tool:GetAttribute("EquippedSkin") or "Default Skin"
	local skinData = weaponStats.Skins[equippedSkinName] or weaponStats.Skins["Default Skin"]

	if not skinData then return end

	local handle = tool.Handle
	local mesh = handle:FindFirstChildOfClass("SpecialMesh")
	if not mesh then
		mesh = Instance.new("SpecialMesh")
		mesh.Name = "Mesh"
		mesh.Parent = handle
	end

	if skinData.MeshId and skinData.MeshId ~= "" then
		mesh.MeshId = skinData.MeshId
	end
	if skinData.TextureId and skinData.TextureId ~= "" then
		mesh.TextureId = skinData.TextureId
	end
end

local function watchCharacter(character)
    local connections = {} -- Tabel untuk koneksi spesifik karakter ini

	-- Terapkan skin pada senjata yang sudah ada saat karakter muncul
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			applySkinToCharacterTool(child)
		end
	end

	-- Amati senjata baru yang ditambahkan ke karakter
	table.insert(connections, character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			applySkinToCharacterTool(child)
			-- Amati jika atribut skin berubah (untuk mengatasi race condition replikasi)
			table.insert(connections, child.AttributeChanged:Connect(function(attribute)
				if attribute == "EquippedSkin" then
					applySkinToCharacterTool(child)
				end
			end))
		end
	end))

    -- Fungsi pembersihan untuk karakter ini
    character.Destroying:Connect(function()
        for _, conn in ipairs(connections) do
            conn:Disconnect()
        end
        table.clear(connections)
    end)
end

local playerWatchConnections = {} -- Tabel untuk menyimpan koneksi

local function watchPlayer(playerToWatch)
    -- Jangan amati pemain lokal, karena skin mereka ditangani oleh setupWeapon
	if playerToWatch == player then return end
    -- Hindari duplikasi koneksi
    if playerWatchConnections[playerToWatch] then return end

	if playerToWatch.Character then
		watchCharacter(playerToWatch.Character)
	end
	-- Simpan koneksi agar bisa diputuskan nanti
	playerWatchConnections[playerToWatch] = playerToWatch.CharacterAdded:Connect(watchCharacter)
end

local function unwatchPlayer(playerToRemove)
    if playerWatchConnections[playerToRemove] then
        playerWatchConnections[playerToRemove]:Disconnect()
        playerWatchConnections[playerToRemove] = nil
    end
end


-- Main Setup
if player:GetAttribute("DoubleTapUsesADS") == nil then
	player:SetAttribute("DoubleTapUsesADS", true)
end

-- Connect global input events
UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)
mouse.Button1Down:Connect(onButton1Down)
mouse.Button1Up:Connect(onButton1Up)
UserInputService.TouchStarted:Connect(onTouchStarted)
UserInputService.TouchEnded:Connect(onTouchEnded)
RunService.RenderStepped:Connect(onRenderStepped)
RunService.Stepped:Connect(onStepped)
-- Connect Mobile Aim Event
toggleAimEvent.Event:Connect(handleToggleAim)
-- Connect Reload Request Event
requestReloadEvent.Event:Connect(handleReloadRequest)

-- Handle character already existing or being added
player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end

-- BARU: Mulai amati semua pemain yang ada dan yang akan bergabung
for _, p in ipairs(game.Players:GetPlayers()) do
	watchPlayer(p)
end
game.Players.PlayerAdded:Connect(watchPlayer)
game.Players.PlayerRemoving:Connect(unwatchPlayer) -- PASTIKAN PEMBERSIHAN

-- Boss2 Gravity Fix
do
	if not player:GetAttribute("_GravityPullListener") then
		player:SetAttribute("_GravityPullListener", true)
		local GravityPullEvent = ReplicatedStorage.RemoteEvents:WaitForChild("Boss2GravityLocalPull")
		local lastGravityTick = tick()
		GravityPullEvent.OnClientEvent:Connect(function(sourcePos, pullForce)
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			local now = tick()
			local dt = math.clamp(now - (lastGravityTick or now), 1/120, 0.25)
			lastGravityTick = now
			local dir = (sourcePos - hrp.Position).Unit
			local adsBoost = (isAiming and 1.15 or 1.0)
			hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + dir * (pullForce * 0.5 * dt * adsBoost)
		end)
	end
end
