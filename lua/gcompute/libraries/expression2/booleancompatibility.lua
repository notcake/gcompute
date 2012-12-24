local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

Expression2:AddMethod ("operator!", "number n")
	:SetReturnType ("bool")
	:SetNativeString ("%arg:n% == 0")
	:SetNativeFunction (
		function (n)
			return n == 0
		end
	)