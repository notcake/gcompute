local Global = GCompute.GlobalNamespace
local String = Global:AddType ("String")
String:SetNullable (false)
String:SetPrimitive (true)
String:SetDefaultValueCreator (
	function ()
		return ""
	end
)

String:AddFunction ("ToUpper")
	:SetNativeFunction (string.upper)
String:AddFunction ("ToLower")
	:SetNativeFunction (string.lower)
String:AddFunction ("ToString")
	:SetNativeFunction (tostring)