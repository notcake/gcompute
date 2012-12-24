local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

Expression2:AddMethod ("owner")
	:SetReturnType ("player")
	:SetNativeFunction (
		function ()
			return GCompute.PlayerMonitor:GetUserEntity (executionContext:GetProcess ():GetOwnerId ())
		end
	)

Expression2:AddMethod ("toString", "object obj")
	:SetReturnType ("string")
	:SetNativeFunction (
		function (obj)
			return obj:ToString ()
		end
	)