local self = {}
GCompute.Profiling.TimedFunctionEntry = GCompute.MakeConstructor (self, GCompute.Profiling.FunctionEntry)

function self:ctor (profilingResultSet, func)
	self.ProfilingResultSet = profilingResultSet
	self.Function = GLib.Lua.Function (func)
	
	self.CallCount = 0
	self.ExclusiveTime = 0
	self.InclusiveTime = 0
	
	self.CallerCallCounts = GLib.WeakKeyTable ()
	self.CallerCallTimes  = GLib.WeakKeyTable ()
	self.CalleeCallCounts = GLib.WeakKeyTable ()
	self.CalleeCallTimes  = GLib.WeakKeyTable ()
end

function self:Clear ()
	self.CallCount          = 0
	self.TotalExclusiveTime = 0
	self.TotalInclusiveTime = 0
	
	self.CallerCallCounts = GLib.WeakKeyTable ()
	self.CallerCallTimes  = GLib.WeakKeyTable ()
	self.CalleeCallCounts = GLib.WeakKeyTable ()
	self.CalleeCallTimes  = GLib.WeakKeyTable ()
end

-- Crediting
function self:CreditExclusiveTime (exclusiveTime)
	self.ExclusiveTime = self.ExclusiveTime + exclusiveTime
end

function self:CreditInclusiveTime (inclusiveTime)
	self.InclusiveTime = self.InclusiveTime + inclusiveTime
end

-- Querying
function self:GetCallCount ()
	return self.CallCount
end

function self:GetTotalInclusiveTime ()
	return self.TotalInclusiveTime
end

function self:GetTotalExclusiveTime ()
	return self.TotalExclusiveTime
end

function self:GetAverageInclusiveTimePerCall ()
	return self.TotalInclusiveTime / self.CallCount
end

function self:GetAverageExclusiveTimePerCall ()
	return self.TotalExclusiveTime / self.CallCount
end

-- Returns the number of calls by the specified caller
function self:GetCallCountFromCaller (callerId)
	return self.CallerCallCount [callerId] or 0
end

-- Returns the total time spent within calls from the specified caller
function self:GetTotalTimeWithinCaller (callerId)
	return self.CallerCallTimes [callerId] or 0
end

-- Returns the number of calls made to the given callee
function self:GetCallCountToCallee (calleeId)
	return self.CalleeCallCount [calleeId] or 0
end

-- Returns the total time spent within the specified callee
function self:GetTotalTimeInCallee (calleeId)
	return self.CalleeCallTimes [calleeId] or 0
end