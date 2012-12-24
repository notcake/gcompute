local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Vector2 = Expression2:AddClass ("vector2")
Expression2:AddAlias ("vec2", "vector2")
Vector2:SetNullable (false)
Vector2:SetNativelyAllocated (true)

Vector2:AddConstructor ()
	:SetNativeString ("{ 0, 0 }")
	:SetNativeFunction (
		function ()
			return { 0, 0 }
		end
	)

Vector2:AddConstructor ("number x, number y")
	:SetNativeString ("{ %arg:x%, %arg:y% }")
	:SetNativeFunction (
		function (x, y)
			return { x, y }
		end
	)
