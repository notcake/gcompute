local G = GCompute.GlobalScope
local Debug = G:AddNamespace ("debug")

local Function = nil

Function = Debug:AddFunction ("scopetrace", "void")
Function.Native = function (executionContext)
	return executionContext.ScopeLookup.TopScope:ToString ()
end

Function.NativeString = "scopetrace(%args%)"