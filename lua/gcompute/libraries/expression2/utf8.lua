local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

Expression2:AddMethod ("toUnicodeByte", "string char")
	:SetReturnType ("number")
	:SetNativeFunction (GLib.UTF8.Byte)

Expression2:AddMethod ("toUnicodeChar", "number codePoint")
	:SetReturnType ("string")
	:SetNativeFunction (GLib.UTF8.Char)