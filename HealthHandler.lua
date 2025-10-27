-- HealthHandler.lua (Script)
-- Path: ServerScriptService/Script/HealthHandler.lua
-- Script Place: ACT 1: Village

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		-- Cari script bawaan Health dan hapus
		local healthScript = char:FindFirstChild("Health")
		if healthScript then
			healthScript:Destroy()
		end
	end)
end)
