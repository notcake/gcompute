local self = {}
GCompute.Profiler.InstrumentingProfilerStackEntry = GCompute.MakeConstructor ()

function self:ctor ()
	self.CallerStackEntry = nil
	self.CalleeStackEntry = nil
	
	self.FunctionEntry = nil
	
	self.ExclusiveTime = 0
	
	self.EntryTime   = nil
	self.UnpauseTime = nil
end

function self:Enter (callerStackEntry)
	self.CallerStackEntry = callerStackEntry
	
	self.EntryTime   = SysTime ()
	self.UnpauseTime = SysTime ()
	
	self.ExclusiveTime = 0
end

function self:Exit ()
	local inclusiveTime = SysTime () - self.EntryTime
	local exclusiveTime = SysTime () - self.UnpauseTime
	
	self.ExclusiveTime = self.ExclusiveTime + exclusiveTime
	
	self.EntryTime   = nil
	self.UnpauseTime = nil
	
	self.CallerStackEntry = nil
	
	return inclusiveTime
end

function self:Pause (calleeStackEntry)
	self.CalleeStackEntry = calleeStackEntry
	
	local exclusiveTime = SysTime () - self.UnpauseTime
	
	self.ExclusiveTime = self.ExclusiveTime + exclusiveTime
	
	self.UnpauseTime = nil
end

function self:Unpause ()
	self.UnpauseTime = SysTime ()
	
	self.CalleeStackEntry = nil
end

function self:GetFunctionEntry ()
	return self.FunctionEntry
end

function self:SetFunctionEntry (functionEntry)
	self.FunctionEntry = functionEntry
end