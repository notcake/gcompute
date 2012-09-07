local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Number = Expression2:AddType ("array")

Number:AddFunction ("count")
	:SetReturnType ("number")
	:SetNativeFunction (
		function (self)
			return #self
		end
	)

Number:AddFunction ("pushNumber", { { "number", "val" } })
	:SetNativeFunction (
		function (self, val)
			self [#self + 1] = val
		end
	)