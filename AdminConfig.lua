-- AdminConfig.lua
-- Path: ServerScriptService/ModuleScript/AdminConfig.lua
-- Script Place: Lobby, ACT 1: Village

local AdminConfig = {}

-- [[
-- 	MOHON DIISI DENGAN ROBLOX USERID ADMIN
-- 	Contoh:
-- 	AdminConfig.Admins = {
-- 		12345678, -- UserID Admin 1
-- 		87654321, -- UserID Admin 2
-- 	}
-- ]]
AdminConfig.Admins = {
	9185027497, -- Ganti dengan UserID admin yang sebenarnya
}

function AdminConfig.IsAdmin(player)
	if not player then return false end
	for _, adminId in ipairs(AdminConfig.Admins) do
		if player.UserId == adminId then
			return true
		end
	end
	return false
end

return AdminConfig
