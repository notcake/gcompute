local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

Expression2:AddFunction ("toUnicodeChar")
	:SetReturnType ("Expression2.string")
	:SetNativeFunction (GLib.UTF8.Char)