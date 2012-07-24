local Global = GCompute.GlobalNamespace
local String = Global:AddType ("String")
String:AddFunction ("ToUpper")
	:SetNativeFunction (string.upper)
String:AddFunction ("ToLower")
	:SetNativeFunction (string.lower)