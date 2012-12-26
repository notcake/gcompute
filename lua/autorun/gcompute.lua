if SERVER or
   file.Exists ("gcompute/gcompute.lua", "LUA") or
   file.Exists ("gcompute/gcompute.lua", "LCL") and GetConVar ("sv_allowcslua"):GetBool () then
	include ("gcompute/gcompute.lua")
end