local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Array = Expression2:AddType ("array")

Array:AddFunction ("count")
	:SetReturnType ("number")
	:SetNativeFunction (
		function (self)
			return #self
		end
	)

Array:AddFunction ("pushNumber", { { "number", "val" } })
	:SetNativeFunction (
		function (self, val)
			self [#self + 1] = val
		end
	)

Array:AddFunction ("operator[]", { { "number", "index" } }, { "T" })
	:SetReturnType ("T")
	:SetNativeString ("%self% [%arg:index%]")
	:SetNativeFunction (
		function (self, index)
			return self [index]
		end
	)

Array:AddFunction ("operator[]", { { "number", "index" }, { "T", "val" } }, { "T" })
	:SetReturnType ("T")
	:SetNativeString ("%self% [%arg:index%] = %arg:val%")
	:SetNativeFunction (
		function (self, index, value)
			self [index] = value
		end
	)