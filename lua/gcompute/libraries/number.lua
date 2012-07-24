local Global = GCompute.GlobalNamespace
local Number = Global:AddType ("Number")
Number:AddFunction ("ToHex")
	:SetNativeFunction (
		function (n)
			return string.format ("%x", n)
		end
	)