local Global = GCompute.GlobalNamespace
local Color = Global:AddClass ("Color")
Color:SetNullable (false)
Color:SetPrimitive (true)
Color:SetDefaultValueCreator (
	function ()
		return _G.Color (255, 255, 255, 255)
	end
)

Color:AddConstructor ("number r, number g, number b")
	:SetNativeString ("Color (%arg:r%, %arg:g%, %arg:b%)")
	:SetNativeFunction (_G.Color)

Color:AddConstructor ("number r, number g, number b, number a")
	:SetNativeString ("Color (%arg:r%, %arg:g%, %arg:b%, %arg:a%)")
	:SetNativeFunction (_G.Color)

local properties =
{
	["R"] = "r",
	["G"] = "g",
	["B"] = "b",
	["A"] = "a"
}

for propertyName, memberName in pairs (properties) do
	local property = Color:AddProperty (propertyName, "number")
	property:AddGetter ()
		:SetNativeString ("%self%." .. memberName)
		:SetNativeFunction (
			function (self)
				return self [memberName]
			end
		)
end

for colorName, color in pairs (GLib.Colors) do
	local property = Color:AddProperty (colorName, "Color")
		:SetMemberStatic (true)
		:AddGetter ()
			:SetNativeString ("GLib.Colors." .. colorName)
			:SetNativeFunction (
				function ()
					return GLib.Colors [colorName]
				end
			)
end

Color:AddMethod ("operator==", "Color color")
	:SetReturnType ("bool")
	:SetNativeFunction (
		function (self, color)
			return self.r == color.r and
			       self.g == color.g and
			       self.b == color.b and
			       self.a == color.a
		end
	)

Color:AddMethod ("ToString")
	:SetReturnType ("string")
	:SetNativeFunction (
		function (self)
			return string.format ("Color (%3d, %3d, %3d, %3d)", self.r, self.g, self.b, self.a)
		end
	)