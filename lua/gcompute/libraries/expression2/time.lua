local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

Expression2:AddFunction ("systime")
	:SetReturnType ("number")
	:SetNativeFunction (SysTime)
