local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

Expression2:AddFunction ("first")
	:SetReturnType ("number")
	:SetNativeFunction (
		function (executionContext)
			return true
		end
	)

Expression2:AddFunction ("perf")
	:SetReturnType ("number")
	:SetNativeFunction (
		function (executionContext)
			return true
		end
	)
	
Expression2:AddFunction ("runOnTick", { { "number", "runOnTick" } })
	:SetNativeFunction (GCompute.NullCallback)