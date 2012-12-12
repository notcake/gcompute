local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Array = Expression2:AddType ("array")
Array:SetNativelyAllocated (true)

Array:AddConstructor ({ { "object", "..." } })
	:SetNativeFunction (
		function (...)
			local array =
			{
				Values = {},
				Types  = {}
			}
			for _, object in ipairs ({...}) do
				array.Values [#array.Values + 1] = object:Unbox ()
				array.Types  [#array.Types  + 1] = object:GetType ()
			end
			return array
		end
	)

Array:AddFunction ("count")
	:SetReturnType ("number")
	:SetNativeFunction (
		function (self)
			return #self.Values
		end
	)

Array:AddFunction ("pushNumber", { { "number", "val" } })
	:SetNativeFunction (
		function (self, val)
			self.Values [#self.Values + 1] = val
			self.Types  [#self.Types  + 1] = executionContext:GetRuntimeNamespace ().Expression2.number
		end
	)

Array:AddFunction ("operator[]", { { "number", "index" } }, { "T" })
	:SetReturnType ("T")
	:SetNativeString ("%self% [%arg:index%]")
	:SetNativeFunction (
		function (self, index)
			return self.Values [index]
		end
	)

Array:AddFunction ("operator[]", { { "number", "index" }, { "T", "val" } }, { "T" })
	:SetReturnType ("T")
	:SetNativeString ("%self% [%arg:index%] = %arg:val%")
	:SetNativeFunction (
		function (self, index, value)
			self.Values [index] = value
		end
	)