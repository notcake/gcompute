local self = {}
GCompute.Profiling.SamplingFunctionEntry = GCompute.MakeConstructor (self, GCompute.Profiling.FunctionEntry)

function self:ctor (profilingResultSet, func)
	self.TotalSampleCount = 0
	self.ExclusiveSampleCount = 0
	self.InclusiveSampleCount = 0
	
	self.LineCounts = {}
	
	self.TotalCallerCount = 0
	self.CallerCounts = GLib.WeakKeyTable ()
	self.TotalCalleeCount = 0
	self.CalleeCounts = GLib.WeakKeyTable ()
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
	return self.ExclusiveSampleCount / self.ProfilingResultSet:GetSampleCount ()
end

function self:GetInclusiveSampleCount ()
	return self.InclusiveSampleCount
end

function self:GetInclusiveSampleFraction ()
	return self.InclusiveSampleCount / self.ProfilingResultSet:GetSampleCount ()
end

function self:GetLineCount (line)
	return self.LineCounts [line] or 0
end

function self:GetLineCountEnumerator ()
	return GLib.KeyValueEnumerator (self.LineCounts)
end

function self:GetLineFraction (line)
	return (self.LineCounts [line] or 0) / self.TotalSampleCount
end

function self:GetCallerCount (func)
	return self.CallerCounts [func] or 0
end

function self:GetCallerEnumerator ()
	return GLib.KeyValueEnumerator (self.CallerCounts)
end

function self:GetCallerFraction (func)
	return (self.CallerCounts [func] or 0) / self.TotalCallerCount
end

function self:GetCalleeCount (func)
	return self.CalleeCounts [func] or 0
end

function self:GetCalleeEnumerator ()
	return GLib.KeyValueEnumerator (self.CalleeCounts)
end

function self:GetCalleeFraction (func)
	return (self.CalleeCounts [func] or 0) / self.TotalCalleeCount
end