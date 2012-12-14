local Global = GCompute.GlobalNamespace
local Number = Global:AddType ("Number")
Number:SetNullable (false)
Number:SetPrimitive (true)
Number:SetDefaultValueCreator (
	function ()
		return 0
	end
)

Number:AddFunction ("ToString")
	:SetNativeFunction (tostring)

Number:AddFunction ("ToHex")
	:SetNativeFunction (
		function (n)
			return string.format ("%x", n)
		end
	)