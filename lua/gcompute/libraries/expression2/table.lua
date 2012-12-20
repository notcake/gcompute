local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Table = Expression2:AddClass ("table")
Table:SetNullable (false)
Table:SetNativelyAllocated (true)

Table:AddConstructor ()
	:SetNativeFunction (
		function ()
			return
			{
				Values = {},
				Types  = {}
			}
		end
	)

Table:AddMethod ("ToString")
	:SetReturnType ("string")
	:SetNativeFunction (
		function (self)
			local inToString = thread:GetThreadLocalStorage ().Expression2.InToString
			
			if inToString [self] then
				return "{table}"
			end
			
			inToString [self] = true
			
			local str = "{table}"
			
			inToString [self] = false
			
			return str
		end
	)