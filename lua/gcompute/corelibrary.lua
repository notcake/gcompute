local G = GCompute.GlobalScope

local T = nil
local F = nil
G:AddType ("Type")
	:SetInheritable (false)
	:SetScopeType (false)

G:AddType ("Namespace")
	:SetInheritable (false)
	
G:AddType ("Function")
	:SetInheritable (false)
	:SetScopeType (false)

G:AddType ("UnresolvedType")
	:SetInheritable (false)
	:SetScopeType (false)
	:ClearBaseTypes ()

G:AddType ("Void")
	:SetInheritable (false)
	:SetScopeType (false)
	:ClearBaseTypes ()
	
G:AddType ("Auto")
	:SetInheritable (false)
	:SetScopeType (false)
	:ClearBaseTypes ()
	
G:AddType ("Boolean")
	:SetInheritable (false)
	:SetPrimitiveType (true)
	:SetScopeType (false)
	
G:AddType ("String")
	:SetInheritable (false)
	:SetPrimitiveType (true)
	:SetScopeType (false)

G:AddTypeReference ("void", "Void")
G:AddTypeReference ("auto", "Auto")
G:AddTypeReference ("var", "Auto")
G:AddTypeReference ("bool", "Boolean")
G:AddTypeReference ("string", "String")

F = G:AddFunction ("print", "void")
F:AddArgument ("String", "message")
F.Native = function (executionContext, message)
	print (tostring (message))
	GCompute.E2Pipe.Print (tostring (message))
end

F.NativeString = "print(%args%)"

F = G:AddFunction ("systime", "float")
F.Native = function (executionContext)
	return SysTime ()
end

F.NativeString = "SysTime()"