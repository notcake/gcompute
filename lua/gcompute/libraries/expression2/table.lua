local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Table = Expression2:AddClass ("table")
Table:SetNullable (false)
Table:SetNativelyAllocated (true)

Table:AddConstructor ()
	:SetNativeFunction (GCompute.Expression2.CreateContainer)

GCompute.Expression2.AddContainerIndexer (Table, "number")
GCompute.Expression2.AddContainerIndexer (Table, "string")

Table:AddMethod ("ToString")
	:SetReturnType ("String")
	:SetNativeFunction (
		function (self)
			local inToString = threadLocalStorage.Expression2.InToString
			
			if inToString [self] then
				return "{table}"
			end
			inToString [self] = true
			
			local str = "{table}"
			
			inToString [self] = false
			
			return str
		end
	)