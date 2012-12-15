if CLIENT and not file.Exists ("gcompute/gcompute.lua", "LCL") then return end
if CLIENT and not GetConVar ("sv_allowcslua"):GetBool () then return end
include ("gcompute/gcompute.lua")