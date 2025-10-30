-- BoosterShopManager.lua (Script)
-- Path: ServerScriptService/Script/BoosterShopManager.lua
-- Script Place: Lobby

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Memuat modul yang diperlukan
local BoosterModule = require(ServerScriptService.ModuleScript:WaitForChild("BoosterModule"))
local CoinsModule = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))
local BoosterConfig = require(ServerScriptService.ModuleScript:WaitForChild("BoosterConfig"))

-- Konfigurasi Toko
local BOOSTER_SHOP_PART_NAME = "BoosterShop"

-- Pastikan RemoteEvents & RemoteFunctions ada
local function getOrCreate(parent, className, name)
	local instance = parent:FindFirstChild(name)
	if not instance then
		instance = Instance.new(className)
		instance.Name = name
		instance.Parent = parent
	end
	return instance
end

local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or getOrCreate(ReplicatedStorage, "Folder", "RemoteEvents")
local RemoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions") or getOrCreate(ReplicatedStorage, "Folder", "RemoteFunctions")

-- Events for the Shop
local ToggleBoosterShopEvent = getOrCreate(RemoteEvents, "RemoteEvent", "ToggleBoosterShopEvent")
local PurchaseBoosterFunction = getOrCreate(RemoteFunctions, "RemoteFunction", "PurchaseBoosterFunction") -- Changed to RemoteFunction
local GetBoosterConfig = getOrCreate(RemoteFunctions, "RemoteFunction", "GetBoosterConfig")

-- Events for the Inventory UI (to ensure they are created reliably)
getOrCreate(RemoteEvents, "RemoteEvent", "BoosterUpdateEvent")
getOrCreate(RemoteEvents, "RemoteEvent", "ActivateBoosterEvent")

-- Cari part toko dan proximity prompt
local boosterShopPart = Workspace.Shop:WaitForChild(BOOSTER_SHOP_PART_NAME)
local proximityPrompt = boosterShopPart:FindFirstChildOfClass("ProximityPrompt")

if not proximityPrompt then
	warn("BoosterShopManager: ProximityPrompt tidak ditemukan di dalam " .. BOOSTER_SHOP_PART_NAME)
else
	proximityPrompt.ObjectText = "Shop"
	proximityPrompt.ActionText = "Open Booster Shop"

	-- Fungsi yang akan dieksekusi saat prompt dipicu
	local function onPromptTriggered(player)
		-- Kumpulkan data yang relevan untuk dikirim ke klien
		local boosterData = BoosterModule.GetData(player)
		local coinsData = CoinsModule.GetData(player)

		local clientData = {
			coins = coinsData.Coins,
			inventory = boosterData.Inventory,
			activeBooster = boosterData.Active
		}

		-- Kirim data bersamaan dengan event toggle
		ToggleBoosterShopEvent:FireClient(player, clientData)
	end

	-- Hubungkan fungsi ke event Triggered dari prompt
	proximityPrompt.Triggered:Connect(onPromptTriggered)
	print("BoosterShopManager: ProximityPrompt terhubung untuk membuka UI.")
end

-- Fungsi untuk menangani aktivasi booster
local function onActivateRequest(player, boosterId)
	if not player or not boosterId then return end
	BoosterModule.SetActiveBooster(player, boosterId)
end

-- Hubungkan fungsi aktivasi ke RemoteEvent
local ActivateBoosterEvent = RemoteEvents:WaitForChild("ActivateBoosterEvent")
ActivateBoosterEvent.OnServerEvent:Connect(onActivateRequest)

-- Fungsi untuk menangani permintaan pembelian dari klien
local function onPurchaseRequest(player, boosterId)
	if not player or not boosterId then return { success = false, message = "Invalid arguments." } end

	local boosterInfo = BoosterConfig[boosterId]
	if not boosterInfo then
		warn(player.Name .. " tried to buy a non-existent item: " .. tostring(boosterId))
		return { success = false, message = "Item not found." }
	end

	local playerData = CoinsModule.GetData(player)
	if playerData.Coins < boosterInfo.Price then
		return { success = false, message = "Not enough coins." }
	end

	if not CoinsModule.SubtractCoins(player, boosterInfo.Price) then
		return { success = false, message = "Purchase failed." }
	end

	if not BoosterModule.AddBooster(player, boosterId, 1) then
		CoinsModule.AddCoins(player, boosterInfo.Price) -- Refund
		return { success = false, message = "Failed to add item." }
	end

	return { success = true, message = "Purchase successful!" }
end

-- Hubungkan fungsi pembelian ke RemoteFunction
PurchaseBoosterFunction.OnServerInvoke = onPurchaseRequest

-- Fungsi untuk menyediakan data konfigurasi ke klien
local function onConfigRequest()
	return BoosterConfig
end

-- Hubungkan fungsi konfigurasi ke RemoteFunction
GetBoosterConfig.OnServerInvoke = onConfigRequest

print("BoosterShopManager berhasil diinisialisasi dengan UI.")
