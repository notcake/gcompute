local self = {}
GCompute.Profiling.FunctionEntry = GCompute.MakeConstructor (self, GCompute.Profiling.FunctionEntry)

function self:ctor (profilingResultSet, func)
	self.ProfilingResultSet = profilingResultSet
	self.Function = GLib.Lua.Function (func)
end

function self:GetFunction ()
	return self.Function
end

function self:GetFunctionName ()
	local name = GLib.Lua.GetFunctionName (self:GetRawFunction ())
	if name then return name end
	
	local func = self:GetFunction ()
	return self:GetFunction ():GetPrototype () .. " [" .. func:GetFilePath () .. ": " .. func:GetStartLine () .. "-" .. func:GetEndLine () .. "]"
end

function self:GetFunctionPrototype ()
	local name = GLib.Lua.GetFunctionName (self:GetRawFunction ())
	if name then return name .. " " .. self:GetFunction ():GetParameterList ():ToString () end
	
	local func = self:GetFunction ()
	return self:GetFunction ():GetPrototype () .. " [" .. func:GetFilePath () .. ": " .. func:GetStartLine () .. "-" .. func:GetEndLine () .. "]"
end

function self:GetRawFunction ()
	return self.Function:GetRawFunction ()
end