local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Number = Expression2:AddClass ("number")

Number:AddMethod ("operator!")
	:SetReturnType ("bool")
	:SetNativeString ("%arg:n% == 0")
	:SetNativeFunction (
		function (n)
			return n == 0
		end
	)

Number:AddMethod ("operator&&", "bool b")
	:SetReturnType ("bool")
	:SetNativeString ("%self% ~= 0 and %arg:b%")
	:SetNativeFunction (
		function (self, b)
			return self ~= 0 and b
		end
	)

Number:AddMethod ("operator||", "bool b")
	:SetReturnType ("bool")
	:SetNativeString ("%self% ~= 0 or %arg:b%")
	:SetNativeFunction (
		function (self, b)
			return self ~= 0 or b
		end
	)