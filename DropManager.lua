-- DropManager.lua (Script)
-- Path: ServerScriptService/Script/DropManager.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local WeaponUpgradeModule = require(ModuleScriptServerScriptService:WaitForChild("WeaponUpgradeConfigModule"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))
local ShieldModule = require(ModuleScriptServerScriptService:WaitForChild("ShieldModule"))

local dropFolder = ServerStorage.Drop

-- Config
local DROP_CHANCE = 0.05 -- probabilitas drop saat zombie mati (0..1)
local PICKUP_RADIUS = 6 -- jika kamu pakai ProximityPrompt nanti bisa disesuaikan
local POINTS_AMOUNT = 1000 -- poin untuk "Points Instant"
local MINIGUN_DURATION = 30 -- detik
local SHIELD_AMOUNT = 30 -- HP perisai
local SHIELD_DURATION = 30 -- detik

-- Sistem Drop Berbobot (Weighted Drop System)
-- 'name' harus sesuai dengan nama asset di ReplicatedStorage.Drop
-- 'weight' menentukan kelangkaan. Semakin tinggi, semakin umum.
local WEIGHTED_DROPS = {
	{ name = "Points",      weight = 30 },
	{ name = "Health",      weight = 25 },
	{ name = "Shield",      weight = 20 },
	{ name = "Ammo",        weight = 15 },
	{ name = "AutoUpgrade", weight = 10 },
	{ name = "Minigun",     weight = 5  },
}


-- Helper: apply skin based on Use_Skin property (server-side)
local function applySkin(tool, weaponName)
	if not tool or not tool.Parent then return end
	local def = WeaponModule.Weapons[weaponName]
	if not def or not def.Skins or not def.Use_Skin then return end
	local skin = def.Skins[def.Use_Skin]
	if not skin then return end
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end
	local mesh = handle:FindFirstChildOfClass("SpecialMesh")
	if not mesh then
		mesh = Instance.new("SpecialMesh")
		mesh.Name = "Mesh"
		mesh.Parent = handle
	end
	if skin.MeshId and skin.MeshId ~= "" then
		mesh.MeshId = skin.MeshId
	end
	if skin.TextureId and skin.TextureId ~= "" then
		mesh.TextureId = skin.TextureId
	end
end

-- Helper: cari player dari bagian yang menyentuh drop
local function getPlayerFromHit(hit)
	local character = hit and hit.Parent
	if not character then return nil end
	return Players:GetPlayerFromCharacter(character)
end

-- Aksi per tipe drop
local function applyDropEffect(dropType, picker)
	if not picker or not picker.Parent then return end
	local char = picker.Character or picker
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if dropType == "Health" then
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
		end

	elseif dropType == "Ammo" then
		-- satu orang ambil -> semua pemain diberi full ammo
		for _, p in pairs(Players:GetPlayers()) do
			-- update semua tools di Character dan Backpack
			local containers = {}
			if p.Character then table.insert(containers, p.Character) end
			local backpack = p:FindFirstChild("Backpack")
			if backpack then table.insert(containers, backpack) end

			for _, cont in ipairs(containers) do
				for _, tool in pairs(cont:GetChildren()) do
					if tool and tool:IsA("Tool") then
						local wdef = WeaponModule.Weapons[tool.Name]
						if wdef then
							-- set attribute; WeaponHandler di project kamu akan mendengarkan AttributeChanged
							-- Refill tanpa menghapus efek upgrade:
							-- Ambil kapasitas AKTUAL: pakai Custom* kalau ada, kalau tidak pakai default wdef
							local baseMax = wdef.MaxAmmo or 0
							local baseReserve = wdef.ReserveAmmo or 0
							local capMax = tool:GetAttribute("CustomMaxAmmo") or baseMax
							local capReserve = tool:GetAttribute("CustomReserveAmmo") or baseReserve

							-- Paksa AttributeChanged supaya WeaponHandler mengisi ulang server-side,
							-- tapi JANGAN turunkan ke default. Kalau nilainya sudah sama, "colek" sebentar
							-- agar event tetap terpanggil.
							local function forceSetAttribute(name, target)
								-- jika sudah sama, set ke target-1 lalu set lagi ke target agar berubah
								local current = tool:GetAttribute(name)
								if current == target then
									tool:SetAttribute(name, math.max(target - 1, 0))
								end
								tool:SetAttribute(name, target)
							end

							forceSetAttribute("CustomMaxAmmo", capMax)
							forceSetAttribute("CustomReserveAmmo", capReserve)
						end
					end
				end
			end
		end

	elseif dropType == "Points" then
		-- beri poin instant kepada picker
		PointsSystem.AddPoints(picker, POINTS_AMOUNT)

	elseif dropType == "Shield" then
		-- tambahkan perisai sementara ke pemain
		ShieldModule.Add(picker, SHIELD_AMOUNT)
		-- jadwalkan penghapusan perisai setelah durasi berakhir
		task.delay(SHIELD_DURATION, function()
			-- pastikan pemain masih valid sebelum mencoba menghapus perisai
			if picker and picker.Parent then
				-- kurangi perisai sejumlah yang diberikan, jangan set ke 0
				-- ini mencegah bug jika pemain mengambil perisai lain
				ShieldModule.Damage(picker, SHIELD_AMOUNT)
			end
		end)

	elseif dropType == "AutoUpgrade" then
		-- upgrade 1 level untuk senjata ter-equip (jika ada)
		local chosenTool = nil
		if picker.Character then
			chosenTool = picker.Character:FindFirstChildOfClass("Tool")
		end
		if not chosenTool then
			-- coba backpack
			local bp = picker:FindFirstChild("Backpack")
			if bp then chosenTool = bp:FindFirstChildOfClass("Tool") end
		end
		if chosenTool and chosenTool:IsA("Tool") then
			-- abaikan upgrade jika senjata adalah minigun atau sudah mencapai level maksimum
			if chosenTool.Name ~= "Minigun" then
				local weaponId = chosenTool:GetAttribute("WeaponId")
				if weaponId then
					local cur = WeaponUpgradeModule.GetLevel(picker, weaponId) or 0
					-- tentukan level maksimum dari konfigurasi senjata (default 10)
					local wname = chosenTool.Name
					local cfgMax = 10
					if WeaponModule.Weapons[wname] and WeaponModule.Weapons[wname].UpgradeConfig and WeaponModule.Weapons[wname].UpgradeConfig.MaxLevel then
						cfgMax = WeaponModule.Weapons[wname].UpgradeConfig.MaxLevel
					end
					-- hanya upgrade jika belum mencapai max level
					if cur < cfgMax then
						local newLevel = math.min(cur + 1, cfgMax)
						WeaponUpgradeModule.SetLevel(picker, weaponId, newLevel)
						chosenTool:SetAttribute("UpgradeLevel", newLevel)
						-- apply skin so drop upgrade matches shop behavior
						applySkin(chosenTool, wname)
						local reFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
						local upgradeEvent = reFolder and reFolder:FindFirstChild("UpgradeUIOpen")
						if upgradeEvent then upgradeEvent:FireClient(picker, wname, newLevel) end
						-- jika upgrade dari level 0 ke 1, tambahkan bonus ammo
						if cur == 0 and newLevel == 1 then
							local wdef = WeaponModule.Weapons[wname]
							if wdef then
								local mult = 1.5
								local newMax = math.floor((wdef.MaxAmmo or 0) * mult + 0.5)
								local newReserve = math.floor((wdef.ReserveAmmo or 0) * mult + 0.5)
								chosenTool:SetAttribute("CustomMaxAmmo", newMax)
								chosenTool:SetAttribute("CustomReserveAmmo", newReserve)
							end
						end
					end
				end
			end
		end

	elseif dropType == "Minigun" then
		-- beri pemain minigun sementara (minigun harus tersedia di ServerStorage atau ReplicatedStorage)
		local template = ServerStorage.Weapons:FindFirstChild("Minigun")
		if template and template:IsA("Tool") then
			local clone = template:Clone()
			clone:SetAttribute("TemporaryDrop", true)
			-- pastikan handle tidak menyebabkan objek mengapung saat dihapus
			local handle = clone:FindFirstChild("Handle") or clone:FindFirstChildWhichIsA("BasePart")
			if handle then
				handle.CanCollide = false
			end
			-- berikan minigun ke pemain (Backpack atau langsung jika tidak ada Backpack)
			clone.Parent = picker:FindFirstChild("Backpack") or picker
			-- hapus secara manual setelah durasi berakhir untuk menghindari tool tertinggal melayang
			task.delay(MINIGUN_DURATION, function()
				if clone and clone.Parent then
					-- Pastikan tidak masih dipegang: paksa unequip sebelum destroy
					local hum = picker.Character and picker.Character:FindFirstChildOfClass("Humanoid")
					if hum and clone:IsDescendantOf(picker.Character) then
						hum:UnequipTools()
						task.wait() -- beri 1 frame untuk memicu Unequipped di klien
					end

					clone:Destroy()
					-- Setelah minigun dihancurkan, jika player tidak memegang tool apa pun,
					-- auto-equip senjata pertama di Backpack
					local hum = picker.Character and picker.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						local hasToolEquipped = picker.Character:FindFirstChildOfClass("Tool")
						if not hasToolEquipped then
							local bp = picker:FindFirstChild("Backpack")
							if bp then
								-- "Senjata no 1" = tool pertama yang ditemukan di Backpack
								local firstTool
								for _, item in ipairs(bp:GetChildren()) do
									if item:IsA("Tool") then
										firstTool = item
										break
									end
								end
								if firstTool then
									hum:EquipTool(firstTool)
								end
							end
						end
					end
				end
			end)
		else
			warn("Minigun template tidak ditemukan di ServerStorage atau ReplicatedStorage. Buat Tool bernama 'Minigun'.")
		end
	end
end

-- Buat drop instance di posisi tertentu dan pasang listener pickup
local function spawnDrop(dropName, position)
	local template = dropFolder:FindFirstChild(dropName)
	if not template then
		warn("Drop template '"..dropName.."' tidak ditemukan di ReplicatedStorage.Drop")
		return
	end

	local drop = template:Clone()
	-- letakkan drop sedikit di atas tanah/zombie
	if drop:IsA("BasePart") then
		-- turunkan sedikit posisi spawn supaya drop melayang lebih rendah (1.2 -> 0.6)
		drop.CFrame = CFrame.new(position + Vector3.new(0, 0.6, 0))
		drop.Anchored = true
		drop.CanCollide = false
		drop.CanQuery = false -- agar raycast/peluru mengabaikan drop
		drop:SetAttribute("IsDrop", true) -- penanda (opsional)
	else
		-- jika template berupa Model
		if drop.PrimaryPart then
			drop:SetPrimaryPartCFrame(CFrame.new(position + Vector3.new(0, 1.2, 0)))
		else
			-- coba set posisi tiap part
			for _, v in pairs(drop:GetDescendants()) do
				if v:IsA("BasePart") then
					v.Anchored = true
					v.CanCollide = false
					v.CanQuery = false -- kunci: raycast mengabaikan part drop
					v:SetAttribute("IsDrop", true) -- penanda (opsional)
				end
			end
		end
	end
	drop.Name = "Drop_"..dropName
	drop.Parent = workspace

	-- tambahkan animasi putar-putar, naik turun dan cahaya ke drop
	-- fungsi lokal untuk melakukan animasi saat drop berada di dunia
	local function animateDrop(instance)
		-- pastikan ada bagian utama untuk dianimasikan
		local part
		if instance:IsA("BasePart") then
			part = instance
		elseif instance.PrimaryPart then
			part = instance.PrimaryPart
		end
		if not part then return end
		-- tambahkan cahaya lembut pada drop agar terlihat bercahaya
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 0, 0) -- warna merah darah
		light.Range = 8
		light.Brightness = 2
		light.Parent = part
		-- gunakan loop berkelanjutan untuk memutar dan mengayunkan drop
		local RunService = game:GetService("RunService")
		spawn(function()
			-- simpan posisi awal agar bobbing mempertahankan posisi horizontal
			local basePos = part.Position
			local elapsed = 0
			-- terus animasikan selama drop masih berada di dunia
			while instance and instance.Parent do
				-- tunggu hingga frame berikutnya
				local dt = RunService.Heartbeat:Wait()
				elapsed = elapsed + dt
				-- hitung offset naik turun menggunakan fungsi sinus (turunkan amplitudo menjadi 0.2 stud)
				local bobOffset = math.sin(elapsed * 2) * 0.2
				-- hitung rotasi mengelilingi sumbu Y (tetap linear)
				local rotation = CFrame.Angles(0, elapsed * 2, 0)
				-- hasilkan CFrame baru
				local newCFrame = CFrame.new(basePos + Vector3.new(0, bobOffset, 0)) * rotation
				if instance:IsA("BasePart") then
					part.CFrame = newCFrame
				else
					-- animasikan keseluruhan model melalui PrimaryPart
					instance:SetPrimaryPartCFrame(newCFrame)
				end
			end
		end)
	end
	-- jalankan animasi pada drop yang baru dibuat
	animateDrop(drop)

	local picked = false
	-- gunakan Touched untuk pickup (sederhana). Gunakan debounce supaya hanya 1 orang yang ambil.
	local conn
	conn = drop.Touched:Connect(function(hit)
		if picked then return end
		local player = getPlayerFromHit(hit)
		if not player then return end
		picked = true
		-- apply effect
		applyDropEffect(dropName, player)
		-- bersihkan
		if conn then conn:Disconnect() end
		if drop and drop.Parent then drop:Destroy() end
	end)

	Debris:AddItem(drop, 25) -- hilangkan jika tidak diambil

	-- Efek berkedip 5 detik terakhir sebelum hilang
	task.spawn(function()
		-- Tunggu hingga sisa waktu 5 detik
		task.wait(20)

		-- Berhenti jika drop sudah diambil atau hancur
		if picked or not drop or not drop.Parent then
			return
		end

		-- Kumpulkan semua part dan lampu untuk dianimasikan
		local partsToBlink = {}
		local light = nil
		if drop:IsA("BasePart") then
			table.insert(partsToBlink, drop)
			light = drop:FindFirstChildOfClass("PointLight")
		else
			if drop.PrimaryPart then
				light = drop.PrimaryPart:FindFirstChildOfClass("PointLight")
			end
			for _, v in pairs(drop:GetDescendants()) do
				if v:IsA("BasePart") then
					table.insert(partsToBlink, v)
				end
			end
		end

		-- Simpan transparansi asli dari setiap part
		local originalTransparencies = {}
		for _, part in pairs(partsToBlink) do
			originalTransparencies[part] = part.Transparency
		end

		-- Lakukan animasi berkedip selama 5 detik
		local blinkEndTime = tick() + 5
		local isVisible = true
		while tick() < blinkEndTime do
			-- Berhenti jika drop diambil atau hancur di tengah animasi
			if picked or not drop or not drop.Parent then break end

			isVisible = not isVisible

			-- Ubah transparansi semua part
			for _, part in pairs(partsToBlink) do
				if isVisible then
					part.Transparency = originalTransparencies[part]
				else
					part.Transparency = 0.8 -- Buat sedikit terlihat agar tidak hilang total
				end
			end

			-- Nyalakan/matikan lampu
			if light then
				light.Enabled = isVisible
			end

			task.wait(0.2) -- Interval kedipan
		end

		-- Kembalikan ke kondisi semula jika masih ada (jarang terjadi karena Debris akan menghancurkannya)
		if not picked and drop and drop.Parent then
			for _, part in pairs(partsToBlink) do
				part.Transparency = originalTransparencies[part]
			end
			if light then
				light.Enabled = true
			end
		end
	end)
end

-- Helper: pilih drop berdasarkan bobot
local totalDropWeight = 0
for _, dropData in ipairs(WEIGHTED_DROPS) do
	totalDropWeight = totalDropWeight + dropData.weight
end

local function getWeightedRandomDrop()
	local randomNum = math.random(1, totalDropWeight)
	local currentWeight = 0
	for _, dropData in ipairs(WEIGHTED_DROPS) do
		currentWeight = currentWeight + dropData.weight
		if randomNum <= currentWeight then
			return dropData.name
		end
	end
	return nil -- fallback, seharusnya tidak terjadi
end

-- Monitor zombie spawn & attach Died listener
local function watchZombie(zombie)
	if not zombie or not zombie.Parent then return end
	if not zombie:FindFirstChild("IsZombie") then return end
	-- cari humanoid
	local humanoid = zombie:FindFirstChildOfClass("Humanoid") or zombie:FindFirstChild("Humanoid")
	local primaryPos
	if zombie.PrimaryPart then
		primaryPos = function() return zombie.PrimaryPart.Position end
	else
		primaryPos = function()
			local hrp = zombie:FindFirstChild("HumanoidRootPart")
			if hrp then return hrp.Position end
			return (zombie:GetModelCFrame().p)
		end
	end

	if humanoid then
		humanoid.Died:Connect(function()
			-- jangan drop dari boss; boss punya drop khusus (BP)
			if zombie:FindFirstChild("IsBoss") then return end

			-- coba drop berdasarkan chance
			if math.random() <= DROP_CHANCE then
				local dropName = getWeightedRandomDrop()
				if dropName then
					local pos = primaryPos() or Vector3.new(0, 5, 0)
					spawnDrop(dropName, pos)
				end
			end
		end)
	end
end

-- Attach watcher ke zombie yang sudah ada
for _, child in pairs(workspace:GetChildren()) do
	pcall(function() watchZombie(child) end)
end

-- listen for zombies baru (spawn dari module)
workspace.ChildAdded:Connect(function(child)
	-- delay kecil untuk memastikan model sudah lengkap
	task.wait(0.03)
	pcall(function() watchZombie(child) end)
end)

print("[DropManager] aktif - drop chance:", DROP_CHANCE)
