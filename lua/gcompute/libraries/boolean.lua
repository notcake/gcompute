local Global = GCompute.GlobalNamespace
local Boolean = Global:AddClass ("Boolean")
Boolean:SetNullable (false)
Boolean:SetPrimitive (true)
Boolean:SetDefaultValueCreator (
	function ()
		return false
	end
)

Boolean:AddMethod ("ToString")
	:SetNativeFunction (tostring)

Boolean:AddMethod ("operator||", "bool b")
	:SetNativeFunction (function (a, b) return a or b end)

Boolean:AddMethod ("operator&&", "bool b")
	:SetNativeFunction (function (a, b) return a and b end)