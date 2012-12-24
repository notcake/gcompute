local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

GCompute:AddEventListener ("ThreadCreated",
	function (_, process, thread)
		local tls = thread:GetThreadLocalStorage ()
		tls.Expression2 = tls.Expression2 or {}
		tls.Expression2.InToString = {}
	end
)

Expression2:AddMethod ("owner")
	:SetReturnType ("player")
	:SetNativeFunction (
		function ()
			return GCompute.Net.PlayerMonitor:GetUserEntity (executionContext:GetProcess ():GetOwnerId ())
		end
	)

Expression2:AddMethod ("toString", "object obj")
	:SetReturnType ("string")
	:SetNativeFunction (
		function (obj)
			return obj:ToString ()
		end
	)