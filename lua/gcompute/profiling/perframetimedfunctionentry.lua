local self = {}
GCompute.Profiling.PerFrameTimedFunctionEntry = GCompute.MakeConstructor (self, GCompute.Profiling.PerFrameTimedFunctionEntry)

function self:ctor (profilingResultSet, func)
	self.FrameCount = 0
	
	self.CallerFrameCounts = GLib.WeakKeyTable ()
	self.CalleeFrameCounts = GLib.WeakKeyTable ()
end

function self:Clear ()
	self.FrameCount         = 0
	self.CallCount          = 0
	self.TotalExclusiveTime = 0
	self.TotalInclusiveTime = 0
	
	self.CallerFrameCounts = GLib.WeakKeyTable ()
	self.CallerCallCounts  = GLib.WeakKeyTable ()
	self.CallerCallTimes   = GLib.WeakKeyTable ()
	self.CalleeFrameCounts = GLib.WeakKeyTable ()
	self.CalleeCallCounts  = GLib.WeakKeyTable ()
	self.CalleeCallTimes   = GLib.WeakKeyTable ()
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