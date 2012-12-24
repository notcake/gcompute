local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Vector = Expression2:AddClass ("vector")
Expression2:AddAlias ("vec", "vector")
Vector:SetNullable (false)
Vector:SetNativelyAllocated (true)

Vector:AddConstructor ()
	:SetNativeString ("Vector (0, 0, 0)")
	:SetNativeFunction (
		function ()
			return Vector (0, 0, 0)
		end
	)

Vector:AddConstructor ("number x, number y, number z")
	:SetNativeString ("Vector (%arg:x%, %arg:y%, %arg:z%)")
	:SetNativeFunction (
		function (x, y, z)
			return Vector (x, y, z)
		end
	)

Vector:AddMethod ("length")
	:SetReturnType ("number")
	:SetNativeString ("%self%:Length ()")
	:SetNativeFunction (
		function (self)
			return self:Length ()
		end
	)

Vector:AddMethod ("operator+", "vector v")
	:SetReturnType ("vector")
	:SetNativeString ("%self% + %arg:v%")
	:SetNativeFunction (
		function (self, v)
			return self + v
		end
	)

Vector:AddMethod ("operator-", "vector v")
	:SetReturnType ("vector")
	:SetNativeString ("%self% - %arg:v%")
	:SetNativeFunction (
		function (self, v)
			return self - v
		end
	)

Vector:AddMethod ("operator*", "number n")
	:SetReturnType ("vector")
	:SetNativeString ("%self% * %arg:n%")
	:SetNativeFunction (
		function (self, n)
			return self * v
		end
	)

Vector:AddMethod ("operator/", "number n")
	:SetReturnType ("vector")
	:SetNativeString ("%self% / %arg:n%")
	:SetNativeFunction (
		function (self, n)
			return self / v
		end
	)