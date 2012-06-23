-- GCompute bindings
local String = GCompute.GlobalNamespace:AddType ("String")
String:AddFunction ("ToUpper")
	:SetNativeFunction (string.upper)
String:AddFunction ("ToLower")
	:SetNativeFunction (string.lower)

-- Expression 2
local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local String = Expression2:AddType ("string")

String:AddFunction ("upper")
	:SetNativeFunction (string.upper)

String:AddFunction ("lower")
	:SetNativeFunction (string.upper)