local Global = GCompute.GlobalNamespace
local Number = Global:AddClass ("Number")
Number:SetNullable (false)
Number:SetPrimitive (true)
Number:SetDefaultValueCreator (
	function ()
		return 0
	end
)

Number:AddMethod ("ToString")
	:SetNativeFunction (tostring)

Number:AddMethod ("ToHex")
	:SetNativeFunction (
		function (n)
			return string.format ("%x", n)
		end
	)