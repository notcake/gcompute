local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

local function addMathFunction (name)
	Expression2:AddFunction (name, { { "number", "n" } })
		:SetReturnType ("number")
		:SetNativeString ("math." .. name .. " (%arg:n%)")
		:SetNativeFunction (math [name])
end

addMathFunction ("abs")
addMathFunction ("ceil")
addMathFunction ("floor")

addMathFunction ("sin")
addMathFunction ("cos")