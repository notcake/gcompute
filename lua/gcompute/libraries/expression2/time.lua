local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

Expression2:AddFunction ("curtime")
	:SetReturnType ("number")
	:SetNativeFunction (CurTime)

Expression2:AddFunction ("systime")
	:SetReturnType ("number")
	:SetNativeFunction (SysTime)
