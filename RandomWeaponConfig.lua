-- RandomWeaponConfig.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/RandomWeaponConfig.lua
-- Script Place: ACT 1: Village

local RandomWeaponConfig = {}

RandomWeaponConfig.Cost = 100            -- biaya beli random weapon (ubah sesuai keinginan)
RandomWeaponConfig.MaxWeapons = 2       -- maksimal senjata yg boleh dibawa
RandomWeaponConfig.StarterWeapon = "M1911" -- starter di awal
-- Daftar nama senjata yang boleh keluar (harus ada di ServerStorage, nama exact)
RandomWeaponConfig.AvailableWeapons = {
	"AK-47",
	"P90",
	"M590A1",
	"L115A1",
	"M1911",
	"Desert-Eagle",
	"Glock-19",
	"MP5",
	"UZI",
	"SCAR",
	"M4A1",
	"AA-12",
	"SPAS-12",
	"DSR",
	"Barrett-M82",
	"RPD",
	"PKP",
	"M249"
}

return RandomWeaponConfig
