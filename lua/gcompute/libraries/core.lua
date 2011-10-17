local G = GCompute.GlobalScope

local Type = nil
local Function = nil
Type = G:AddType ("String")
Type.NativeString = "\"%arg%\""

Function = G:AddFunction ("print", "void")
Function:AddArgument ("String", "Message")
Function.Native = function (ExecutionContext, Message)
	print (Message)
end

Function.NativeString = "print(%args%)"