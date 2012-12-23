local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

local function addMathFunction (name, argumentName)
	Expression2:AddMethod (name, "number " .. (argumentName or "n"))
		:SetReturnType ("number")
		:SetNativeString ("math." .. name .. " (%arg:n%)")
		:SetNativeFunction (math [name])
end

addMathFunction ("abs")
addMathFunction ("ceil")
addMathFunction ("floor")

addMathFunction ("sqrt")

addMathFunction ("sin", "angleInRadians")
addMathFunction ("cos", "angleInRadians")
addMathFunction ("tan", "angleInRadians")
addMathFunction ("asin", "sin")
addMathFunction ("acos", "cos")
addMathFunction ("atan", "tan")

Expression2:AddMethod ("max", "number a, number ...")
	:SetReturnType ("number")
	:SetNativeString ("math.max (%arg:a%, %args%)")
	:SetNativeFunction (math.max)

Expression2:AddMethod ("min", "number a, number ...")
	:SetReturnType ("number")
	:SetNativeString ("math.min (%arg:a%, %args%)")
	:SetNativeFunction (math.min)