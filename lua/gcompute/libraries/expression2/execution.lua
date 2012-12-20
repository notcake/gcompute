local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

Expression2:AddMethod ("first")
	:SetReturnType ("number")
	:SetNativeFunction (
		function ()
			local tls = executionContext:GetThreadLocalStorage ()
			return tls.Expression2.First == true and 1 or 0
		end
	)

Expression2:AddMethod ("interval", "number milliseconds")
	:SetNativeFunction (
		function (executionInterval)
			local tls = executionContext:GetThreadLocalStorage ()
			tls.Expression2.ExecutionInterval = executionInterval
		end
	)

Expression2:AddMethod ("perf")
	:SetReturnType ("number")
	:SetNativeFunction (
		function ()
			return 1
		end
	)
	
Expression2:AddMethod ("runOnTick", "number runOnTick")
	:SetNativeFunction (GCompute.NullCallback)