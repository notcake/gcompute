local self = {}
GCompute.IDE.Profiler.ProfilerSubView = GCompute.MakeConstructor (self, GCompute.IDE.SubView)

function self:ctor (view, container)
	self.UpdateNeeded = false
	
	self.Profiler = nil
	self.ProfilingResultSet = nil
end

function self:dtor ()
	self:SetProfiler (nil)
	self:SetProfilingResultSet (nil)
end

function self:Clear ()
end

function self:IsUpdateNeeded ()
	return self.UpdateNeeded
end

function self:CreateHistoryItem (historyItem)
	historyItem = historyItem or GCompute.IDE.Profiler.HistoryItem ()
	historyItem:SetSubViewId (self:GetId ())
	
	return historyItem
end

function self:RestoreHistoryItem (historyItem)
end

function self:GetId ()
	return self.Id or self.Name or tostring (self:GetHashCode ())
end

function self:GetName ()
	return self.Name or tostring (self:GetHashCode ())
end

-- Profiler
function self:GetProfiler ()
	return self.Profiler
end

function self:GetProfilingResultSet ()
	return self.ProfilingResultSet
end

function self:SetProfiler (profiler)
	if self.Profiler == profiler then return self end
	
	self:UnhookProfiler (self.Profiler)
	self.Profiler = profiler
	self:HookProfiler (profiler)
	
	return self
end

function self:SetProfilingResultSet (profilingResultSet)
	if self.ProfilingResultSet == profilingResultSet then return self end
	
	self:UnhookProfilingResultSet (self.ProfilingResultSet)
	self.ProfilingResultSet = profilingResultSet
	self:HookProfilingResultSet (self.ProfilingResultSet)
	
	self:Clear ()
	self.UpdateNeeded = true
	
	return self
end

-- Internal, do not call
function self:HookProfiler (profiler)
	if not profiler then return end
	
	profiler:AddEventListener ("Started", self:GetHashCode (),
		function ()
			self.UpdateNeeded = true
		end
	)
	
	profiler:AddEventListener ("Stopped", self:GetHashCode (),
		function ()
			self.UpdateNeeded = true
		end
	)
end

function self:UnhookProfiler (profiler)
	if not profiler then return end
	
	profiler:RemoveEventListener ("Started", self:GetHashCode ())
	profiler:RemoveEventListener ("Stopped", self:GetHashCode ())
end

function self:HookProfilingResultSet (profilingResultSet)
	if not profilingResultSet then return end
	
	profilingResultSet:AddEventListener ("Cleared", self:GetHashCode (),
		function ()
			self:Clear ()
		end
	)
end

function self:UnhookProfilingResultSet (profilingResultSet)
	if not profilingResultSet then return end
	
	profilingResultSet:RemoveEventListener ("Cleared", self:GetHashCode ())
end