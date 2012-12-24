local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

Expression2:AddMethod ("operator>>", "number val, number bits")
	:SetReturnType ("number")
	:SetNativeString ("bit.rshift (%arg:val%, %arg:bits%)")
	:SetNativeFunction (bit.rshift)

Expression2:AddMethod ("operator<<", "number val, number bits")
	:SetReturnType ("number")
	:SetNativeString ("bit.lshift (%arg:val%, %arg:bits%)")
	:SetNativeFunction (bit.lshift)

Expression2:AddMethod ("bXor", "number a, number b")
	:SetReturnType ("number")
	:SetNativeString ("bit.bxor (%arg:a%, %arg:b%)")
	:SetNativeFunction (bit.bxor)