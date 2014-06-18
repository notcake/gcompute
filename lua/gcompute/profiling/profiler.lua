local self = {}
GCompute.Profiling.Profiler = GCompute.MakeConstructor (self)

--[[
	Events:
		Cleared ()
			Fired when the profiling results have been cleared.
		ProfilingResultSetChanged ()
			Fired when the profiling result set has changed.
		Started ()
			Fired when the profiler has started.
		Stopped ()
			Fired when the profiler has stopped.
]]

function self:ctor ()
	self.Running = false
	self.ProfilingResultSet = nil
	
	GCompute:AddEventListener ("Unloaded",
		function ()
			self:dtor ()
		end
	)
	
	GCompute.EventProvider (self)
end

function self:dtor ()
	self:Stop ()
end

function self:Clear ()
	if self.ProfilingResultSet then
		self.ProfilingResultSet:Clear ()
	end
	
	self:DispatchEvent ("Cleared")
end

function self:GetProfilingResultSet ()
	return self.ProfilingResultSet
end

function self:IsRunning ()
	return self.Running
end

function self:SetProfilingResultSet (profilingResultSet)
	if self.ProfilingResultSet == profilingResultSet then return self end
	
	local oldProfilingResultSet = self.ProfilingResultSet
	self.ProfilingResultSet = profilingResultSet
	
	self:DispatchEvent ("ProfilingResultSetChanged", oldProfilingResultSet, self.ProfilingResultSet)
	
	return self
end

function self:Start ()
	GCompute.Error ("Profiler:Start : Not implemented.")
end

function self:Stop ()
	GCompute.Error ("Profiler:Stop : Not implemented.")
end

-- Internal, do not call
function self:SetRunning (running)
	if self.Running == running then return self end
	
	self.Running = running
	
	if self.Running then
		self:DispatchEvent ("Started")
	else
		self:DispatchEvent ("Stopped")
	end
	
	return self
end

function self:__call (...)
	return self.__ictor (...)
end