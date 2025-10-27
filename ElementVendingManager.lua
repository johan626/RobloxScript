-- ElementVendingManager.lua (Script)
-- Path: ServerScriptService/Script/ElementVendingManager.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))
local ElementModule = require(ModuleScriptServerScriptService:WaitForChild("ElementConfigModule"))
local BoosterModule = require(ModuleScriptServerScriptService:WaitForChild("BoosterModule"))

local OpenElementShopEvent = RemoteEvents:WaitForChild("OpenElementShop")
local CloseElementShopEvent = RemoteEvents:WaitForChild("CloseElementShop")

local purchaseRF = RemoteFunctions:WaitForChild("PurchaseElement")

-- Hapus proximity prompt lama
local vending = workspace:FindFirstChild("Elements")
if vending and vending:IsA("BasePart") then
	local prompt = vending:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt:Destroy()
	end
end

-- Fungsi untuk mengecek jarak player dengan vending machine
local function isPlayerNearVending(player)
	local vendingPart = workspace:FindFirstChild("Elements")
	if not vendingPart or not vendingPart:IsA("BasePart") then return false end

	local character = player.Character
	if not character then return false end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end

	local distance = (humanoidRootPart.Position - vendingPart.Position).Magnitude
	return distance <= 10
end

-- Remote function untuk membuka UI shop
local function requestOpenShop(player)
	if not isPlayerNearVending(player) then
		return false
	end

	local hasDiscount = false
	local boosterData = BoosterModule.GetData(player)
	if boosterData and boosterData.Active == "CouponDiscount" then
		hasDiscount = true
	end

	OpenElementShopEvent:FireClient(player, ElementModule.GetConfig(), hasDiscount)
	return true
end

-- Handler untuk request buka shop
local RequestOpenElementShop = ReplicatedStorage.RemoteEvents:FindFirstChild("RequestOpenElementShop")
if not RequestOpenElementShop then
	RequestOpenElementShop = Instance.new("RemoteEvent")
	RequestOpenElementShop.Name = "RequestOpenElementShop"
	RequestOpenElementShop.Parent = ReplicatedStorage.RemoteEvents
end

RequestOpenElementShop.OnServerEvent:Connect(function(player)
	requestOpenShop(player)
end)

-- Purchase RemoteFunction implementation
purchaseRF.OnServerInvoke = function(player, elementName)
	-- safety: ensure PointsSystem setup for player
	if not PointsSystem.GetPoints(player) then
		PointsSystem.SetupPlayer(player)
	end

	local cfg = ElementModule.GetConfig()[elementName]
	if not cfg then return false, "Element not found" end

	-- security: check proximity to vending part
	if not isPlayerNearVending(player) then
		return false, "Not near vending"
	end

	-- Cek apakah player sudah memiliki purchased element atau active element di wave ini?
	local purchased = ElementModule.GetPurchasedElement(player)
	local activeElements = ElementModule.GetActiveElements(player)
	if purchased or next(activeElements) ~= nil then
		return false, "Already have an element this wave"
	end

	local cost = cfg.Cost
	local hasDiscount = false
	local boosterData = BoosterModule.GetData(player)
	if boosterData and boosterData.Active == "CouponDiscount" then
		hasDiscount = true
		cost = math.floor(cost / 2)
	end

	local currentPoints = PointsSystem.GetPoints(player) or 0
	if currentPoints < cost then
		return false, "Not enough points"
	end

	-- PERBAIKAN: Cek ulang kondisi sebelum mengurangi poin
	-- Pastikan tidak ada purchased element atau active element
	local purchasedCheck = ElementModule.GetPurchasedElement(player)
	local activeElementsCheck = ElementModule.GetActiveElements(player)
	if purchasedCheck or next(activeElementsCheck) ~= nil then
		return false, "Already have an element this wave"
	end

	-- Grant element terlebih dahulu sebelum mengurangi poin
	local success, message = ElementModule.GrantElement(player, elementName)
	if not success then
		return false, message
	end

	-- Baru kemudian kurangi poin
	PointsSystem.AddPoints(player, -cost)

	-- Jika ada diskon, gunakan booster
	if hasDiscount then
		BoosterModule.UseActiveBooster(player)
	end

	-- Kirim event ke client bahwa element berhasil dibeli
	local ElementPurchased = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("ElementPurchased")
	if ElementPurchased then
		ElementPurchased:FireClient(player, elementName)
	end

	return true, "Purchased "..elementName
end

-- Cleanup ketika player meninggalkan game
Players.PlayerRemoving:Connect(function(player)
	-- Tutup UI shop jika terbuka
	CloseElementShopEvent:FireClient(player)
end)