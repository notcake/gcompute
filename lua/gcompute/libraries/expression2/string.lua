local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local String = Expression2:AddClass ("string")
String:SetNullable (false)
String:SetPrimitive (true)
String:SetDefaultValueCreator (
	function ()
		return ""
	end
)
	
Expression2:AddMethod ("format", "string formatString, object ...")
	:SetReturnType ("string")
	:SetNativeFunction (string.format)
	
Expression2:AddMethod ("print", "object ...")
	:SetNativeFunction (
		function (...)
			local t = {...}
			for k, v in ipairs (t) do
				t [k] = v:ToString ()
			end
			executionContext:GetProcess ():GetStdOut ():WriteLine (table.concat (t, "\t"))
		end
	)

Expression2:AddMethod ("toByte", "string char")
	:SetReturnType ("number")
	:SetNativeFunction (string.byte)

Expression2:AddMethod ("toByte", "string char, number offset")
	:SetReturnType ("number")
	:SetNativeFunction (string.byte)

Expression2:AddMethod ("toChar", "number value")
	:SetReturnType ("string")
	:SetNativeFunction (string.char)

String:AddMethod ("ToString")
	:SetNativeFunction (tostring)
	
String:AddMethod ("toString")
	:SetNativeFunction (tostring)

String:AddMethod ("find", "string substring")
	:SetReturnType ("number")
	:SetNativeString ("string.find (%self%, %arg:substring%, 1, true)")
	:SetNativeFunction (
		function (self, substring)
			return string.find (self, substring, 1, true)
		end
	)

String:AddMethod ("length")
	:SetReturnType ("number")
	:SetNativeString ("#%self%")
	:SetNativeFunction (string.len)

String:AddMethod ("sub", "number start")
	:SetReturnType ("string")
	:SetNativeString ("string.sub (%self%, %arg:start%)")
	:SetNativeFunction (string.sub)

String:AddMethod ("sub", "number start, number end")
	:SetReturnType ("string")
	:SetNativeString ("string.sub (%self%, %arg:end%)")
	:SetNativeFunction (string.sub)

String:AddMethod ("upper")
	:SetReturnType ("string")
	:SetNativeString ("string.upper (%self%)")
	:SetNativeFunction (string.upper)

String:AddMethod ("lower")
	:SetReturnType ("string")
	:SetNativeString ("string.lower (%self%)")
	:SetNativeFunction (string.lower)
	
String:AddMethod ("operator+", "string str")
	:SetReturnType ("string")
	:SetNativeString ("(%self% .. %str%)")
	:SetNativeFunction (
		function (self, str)
			return self .. str
		end
	)
	
String:AddMethod ("operator+", "number n")
	:SetReturnType ("string")
	:SetNativeString ("(%self% .. %n%")
	:SetNativeFunction (
		function (self, n)
			return self .. n
		end
	)
	
String:AddExplicitCast ("number", function (s) return tonumber (s) or 0 end)