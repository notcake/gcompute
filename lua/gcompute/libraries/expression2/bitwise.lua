local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Number = Expression2:AddClass ("number")

Number:AddMethod ("operator&", "number b")
	:SetReturnType ("number")
	:SetNativeString ("bit.band (%self%, %arg:b%)")
	:SetNativeFunction (bit.band)
	
Number:AddMethod ("operator|", "number b")
	:SetReturnType ("number")
	:SetNativeString ("bit.bor (%self%, %arg:b%)")
	:SetNativeFunction (bit.bor)

Number:AddMethod ("operator>>", "number bits")
	:SetReturnType ("number")
	:SetNativeString ("bit.rshift (%self%, %arg:bits%)")
	:SetNativeFunction (bit.rshift)

Number:AddMethod ("operator<<", "number bits")
	:SetReturnType ("number")
	:SetNativeString ("bit.lshift (%self%, %arg:bits%)")
	:SetNativeFunction (bit.lshift)

Expression2:AddMethod ("bXor", "number a, number b")
	:SetReturnType ("number")
	:SetNativeString ("bit.bxor (%arg:a%, %arg:b%)")
	:SetNativeFunction (bit.bxor)