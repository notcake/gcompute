local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Vector4 = Expression2:AddClass ("vector4")
Expression2:AddAlias ("vec4", "vector4")
Vector4:SetNullable (false)
Vector4:SetNativelyAllocated (true)

Vector4:AddConstructor ()
	:SetNativeString ("{ 0, 0, 0, 0 }")
	:SetNativeFunction (
		function ()
			return { 0, 0, 0, 0 }
		end
	)

Vector4:AddConstructor ("number x, number y, number z")
	:SetNativeString ("{ %arg:x%, %arg:y%, %arg:z%, 0 }")
	:SetNativeFunction (
		function (x, y, z)
			return { x, y, z, 0 }
		end
	)

Vector4:AddConstructor ("number x, number y, number z, number w")
	:SetNativeString ("{ %arg:x%, %arg:y%, %arg:z%, %arg:w% }")
	:SetNativeFunction (
		function (x, y, z, w)
			return { x, y, z, w }
		end
	)
