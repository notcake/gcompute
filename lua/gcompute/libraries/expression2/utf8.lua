local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

Expression2:AddFunction ("toUnicodeChar", { { "number", "codePoint" } })
	:SetReturnType ("string")
	:SetNativeFunction (GLib.UTF8.Char)