local self = {}
GCompute.Profiling.FunctionEntry = GCompute.MakeConstructor (self)

function self:ctor (profiler, func)
	self.Profiler = profiler
	self.Function = GLib.Lua.Function (func)
	
	self.TotalSampleCount = 0
	self.ExclusiveSampleCount = 0
	self.InclusiveSampleCount = 0
	
	self.LineCounts = {}
	
	self.TotalCallerCount = 0
	self.CallerCounts = GLib.WeakKeyTable ()
	self.TotalCalleeCount = 0
	self.CalleeCounts = GLib.WeakKeyTable ()
end

function self:GetFunction ()
	return self.Function
end

function self:GetFunctionName ()
	local name = GLib.Lua.NameCache:GetFunctionName (self:GetRawFunction ())
	if name then return name end
	
	local func = self:GetFunction ()
	return self:GetFunction ():GetPrototype () .. " [" .. func:GetFilePath () .. ": " .. func:GetStartLine () .. "-" .. func:GetEndLine () .. "]"
end

function self:GetFunctionPrototype ()
	local name = GLib.Lua.NameCache:GetFunctionName (self:GetRawFunction ())
	if name then return name .. " " .. self:GetFunction ():GetParameterList ():ToString () end
	
	local func = self:GetFunction ()
	return self:GetFunction ():GetPrototype () .. " [" .. func:GetFilePath () .. ": " .. func:GetStartLine () .. "-" .. func:GetEndLine () .. "]"
end

function self:GetRawFunction ()
	return self.Function:GetRawFunction ()
end

function self:Clear ()
	self.TotalSampleCount = 0
	self.ExclusiveSampleCount = 0
	self.InclusiveSampleCount = 0
	
	self.LineCounts = {}
	
	self.TotalCallerCount = 0
	self.CallerCounts = GLib.WeakKeyTable ()
	self.TotalCalleeCount = 0
	self.CalleeCounts = GLib.WeakKeyTable ()
end

function self:GetTotalSampleCount ()
	return self.TotalSampleCount
end

function self:GetExclusiveSampleCount ()
	return self.ExclusiveSampleCount
end

function self:GetExclusiveSampleFraction ()
	return self.ExclusiveSampleCount / self.Profiler:GetSampleCount ()
end

function self:GetInclusiveSampleCount ()
	return self.InclusiveSampleCount
end

function self:GetInclusiveSampleFraction ()
	return self.InclusiveSampleCount / self.Profiler:GetSampleCount ()
end

function self:GetLineCount (line)
	return self.LineCounts [line] or 0
end

function self:GetLineCountEnumerator ()
	local next, tbl, key = pairs (self.LineCounts)
	
	return function ()
		key = next (tbl, key)
		return key, tbl [key]
	end
end

function self:GetLineFraction (line)
	return (self.LineCounts [line] or 0) / self.TotalSampleCount
end

function self:GetCallerCount (func)
	return self.CallerCounts [func] or 0
end

function self:GetCallerFraction (func)
	return (self.CallerCounts [func] or 0) / self.TotalCallerCount
end

function self:GetCalleeCount (func)
	return self.CalleeCounts [func] or 0
end

function self:GetCalleeFraction (func)
	return (self.CalleeCounts [func] or 0) / self.TotalCalleeCount
end