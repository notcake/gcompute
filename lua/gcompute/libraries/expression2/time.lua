local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

Expression2:AddMethod ("curtime")
	:SetReturnType ("number")
	:SetNativeFunction (CurTime)

Expression2:AddMethod ("systime")
	:SetReturnType ("number")
	:SetNativeFunction (SysTime)
