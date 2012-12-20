local Global = GCompute.GlobalNamespace
local String = Global:AddClass ("String")
String:SetNullable (false)
String:SetPrimitive (true)
String:SetDefaultValueCreator (
	function ()
		return ""
	end
)

String:AddProperty ("Length")
	:SetType ("number")
	:AddGetter ()
		:SetNativeString ("#%self%")
		:SetNativeFunction (string.len)

String:AddMethod ("ToUpper")
	:SetNativeFunction (string.upper)
String:AddMethod ("ToLower")
	:SetNativeFunction (string.lower)
String:AddMethod ("ToString")
	:SetNativeFunction (tostring)