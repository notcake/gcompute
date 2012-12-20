local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Number = Expression2:AddClass ("number")
Number:SetNullable (false)
Number:SetPrimitive (true)
Number:SetDefaultValueCreator (
	function ()
		return 0
	end
)

Number:AddConstructor ({ { "int", "n" } })
	:SetNativeFunction (
		function (n)
			return n
		end
	)

Number:AddMethod ("ToString")
	:SetNativeFunction (tostring)
	
Number:AddMethod ("toString")
	:SetNativeFunction (tostring)

Number:AddMethod ("toHex")
	:SetReturnType ("string")
	:SetNativeFunction (
		function (n)
			return string.format ("%x", n)
		end
	)

local function addOperator (symbol, f)
	Number:AddMethod ("operator" .. symbol, "number b")
		:SetReturnType ("number")
		:SetNativeString ("(%self% " .. symbol .. "%arg:b%)")
		:SetNativeFunction (f)
end

local function addComparisonOperator (symbol, f)
	Number:AddMethod ("operator" .. symbol, "number b")
		:SetReturnType ("bool")
		:SetNativeString ("(%self% " .. symbol .. "%arg:b%)")
		:SetNativeFunction (f)
end

addOperator ("+", function (a, b) return a + b end)
addOperator ("-", function (a, b) return a - b end)
addOperator ("*", function (a, b) return a * b end)
addOperator ("/", function (a, b) return a / b end)
addOperator ("%", function (a, b) return a % b end)
addOperator ("^", function (a, b) return a ^ b end)
addOperator ("&", function (a, b) return bit.band (a, b) end)
addOperator ("|", function (a, b) return bit.bor  (a, b) end)

addComparisonOperator ("<", function (a, b) return a < b end)
addComparisonOperator ("<=", function (a, b) return a <= b end)
addComparisonOperator (">", function (a, b) return a > b end)
addComparisonOperator (">=", function (a, b) return a >= b end)
	
Number:AddExplicitCast ("bool", function (n) return n ~= 0 end)
Number:AddExplicitCast ("string", function (n) return tostring (n) end)