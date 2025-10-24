-- ModelPreviewModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/ModelPreviewModule.lua
-- Script Place: Lobby

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")

local ModelPreviewModule = {}

-- Store active rotation connections to manage them
local activeRotations = {}

--[[
	Creates a new preview instance within a given ViewportFrame.
	Returns a preview object that contains the model and camera.
	The onComplete callback is fired after assets are preloaded.
]]
function ModelPreviewModule.create(viewport, weaponData, skinData, onComplete)
	-- Clean up any existing model in the viewport
	for _, child in ipairs(viewport:GetChildren()) do
		if child:IsA("WorldModel") or child:IsA("Camera") then
			child:Destroy()
		end
	end

	local worldModel = Instance.new("WorldModel", viewport)
	local camera = Instance.new("Camera")
	camera.Parent = viewport
	camera.FieldOfView = 30
	viewport.CurrentCamera = camera

	local model = Instance.new("Model", worldModel)
	model.Name = "PreviewModel"

	local part = Instance.new("Part", model)
	part.Name = "Handle"
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(1, 1, 1)

	local mesh = Instance.new("SpecialMesh", part)
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = skinData.MeshId
	mesh.TextureId = skinData.TextureId
	mesh.Scale = weaponData.Scale or Vector3.new(1, 1, 1) -- Use scale from config if available

	model.PrimaryPart = part

	local preview = {
		viewport = viewport,
		camera = camera,
		model = model,
		rotationConnection = nil,
		zoomDistance = 5
	}

	-- Preload assets asynchronously
	task.spawn(function()
		local assetsToLoad = {}
		if skinData.MeshId and skinData.MeshId ~= "" then
			table.insert(assetsToLoad, skinData.MeshId)
		end
		if skinData.TextureId and skinData.TextureId ~= "" then
			table.insert(assetsToLoad, skinData.TextureId)
		end

		local success, message = pcall(function()
			if #assetsToLoad > 0 then
				ContentProvider:PreloadAsync(assetsToLoad)
			end
		end)

		if not success then
			warn("ModelPreviewModule: Asset preloading failed: " .. message)
		end

		if onComplete then
			onComplete(preview)
		end
	end)

	-- Return immediately so the UI script isn't blocked
	return preview
end

--[[
	Starts an automatic rotation for a given preview object.
	An optional zoomDistance can be provided.
]]
function ModelPreviewModule.startRotation(preview, zoom)
	ModelPreviewModule.stopRotation(preview) -- Ensure no duplicate connections

	preview.zoomDistance = zoom or preview.zoomDistance

	local cameraAngle = 0
	preview.rotationConnection = RunService.RenderStepped:Connect(function(dt)
		if preview.model and preview.model.PrimaryPart then
			cameraAngle = cameraAngle + (dt * 0.8) -- Constant rotation speed

			local rotation = CFrame.Angles(0, cameraAngle, 0)
			local offset = Vector3.new(0, 0, preview.zoomDistance)
			local cameraPosition = preview.model.PrimaryPart.Position + rotation:VectorToWorldSpace(offset)

			preview.camera.CFrame = CFrame.new(cameraPosition, preview.model.PrimaryPart.Position)
		end
	end)
end

--[[
	Stops the automatic rotation for a given preview object.
]]
function ModelPreviewModule.stopRotation(preview)
	if preview and preview.rotationConnection then
		preview.rotationConnection:Disconnect()
		preview.rotationConnection = nil
	end
end

--[[
	Destroys the preview instance and cleans up its components.
]]
function ModelPreviewModule.destroy(preview)
	if not preview then return end

	ModelPreviewModule.stopRotation(preview)
	if preview.model then
		preview.model:Destroy()
	end
	if preview.camera then
		preview.camera:Destroy()
	end

	-- Clear the table reference
	for k in pairs(preview) do
		preview[k] = nil
	end
end

--[[
    Connects a slider UI to control the zoom of a preview instance.
]]
function ModelPreviewModule.connectZoomSlider(preview, sliderTrack, sliderHandle, sliderFill, minZoom, maxZoom)
	local isDragging = false

	sliderHandle.MouseButton1Down:Connect(function()
		isDragging = true
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local mouseX = input.Position.X
			local trackAbsX = sliderTrack.AbsolutePosition.X
			local trackAbsWidth = sliderTrack.AbsoluteSize.X

			local percent = math.clamp((mouseX - trackAbsX) / trackAbsWidth, 0, 1)

			sliderHandle.Position = UDim2.new(percent, 0, 0.5, 0)
			if sliderFill then
				sliderFill.Size = UDim2.new(percent, 0, 1, 0)
			end

			preview.zoomDistance = minZoom + (percent * (maxZoom - minZoom))
		end
	end)

	-- Set initial state
	local initialPercent = 0.5
	preview.zoomDistance = minZoom + (initialPercent * (maxZoom - minZoom))
	sliderHandle.Position = UDim2.new(initialPercent, 0, 0.5, 0)
	if sliderFill then
		sliderFill.Size = UDim2.new(initialPercent, 0, 1, 0)
	end
end

return ModelPreviewModule
