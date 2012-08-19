local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local String = Expression2:AddType ("string")
	
Expression2:AddFunction ("format", { { "string", "formatString" }, { "object", "..." } })
	:SetReturnType ("string")
	:SetNativeFunction (string.format)
	
Expression2:AddFunction ("print", { { "object", "..." } })
	:SetNativeFunction (print)

String:AddFunction ("upper")
	:SetReturnType ("string")
	:SetNativeFunction (string.upper)

String:AddFunction ("lower")
	:SetReturnType ("string")
	:SetNativeFunction (string.upper)
	
String:AddFunction ("operator+", { { "string", "str" } })
	:SetReturnType ("string")
	:SetNativeString ("(%self% .. %str%")
	:SetNativeFunction (
		function (self, str)
			return self .. str
		end
	)
	
String:AddFunction ("operator+", { { "number", "n" } })
	:SetReturnType ("string")
	:SetNativeString ("(%self% .. %n%")
	:SetNativeFunction (
		function (self, n)
			return self .. n
		end
	)
	
String:AddExplicitCast ("number", function (s) return tonumber (s) or 0 end)