local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Angle = Expression2:AddClass ("angle")
Expression2:AddAlias ("ang", "angle")
Angle:SetNullable (false)
Angle:SetNativelyAllocated (true)

Angle:AddConstructor ()
	:SetNativeString ("Angle (0, 0, 0)")
	:SetNativeFunction (
		function ()
			return Angle (0, 0, 0)
		end
	)

Angle:AddConstructor ("number p, number y, number r")
	:SetNativeString ("Angle (%arg:p%, %arg:y%, %arg:r%)")
	:SetNativeFunction (
		function (p, y, r)
			return Angle (p, y, r)
		end
	)
