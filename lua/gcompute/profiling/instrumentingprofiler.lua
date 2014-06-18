local self = {}
GCompute.Profiling.InstrumentingProfiler = GCompute.MakeConstructor (self, GCompute.Profiling.Profiler)

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
	self.Stack = {}
	self.StackCount = 0
	
	self.NativeReturnDebugHook = function (reason, ...)
		self:ApplyDebugHook ()
	end
	self.DebugHook = function (reason, ...)
		local profilingResultSet = self.ProfilingResultSet
		
		if not profilingResultSet then
			self:Stop ()
			return
		end
		
		local info = debug.getinfo (2, "fS")
		
		local functionEntry = profilingResultSet:GetFunctionEntry (info.func)
		
		if reason == "call" then
			-- About to enter function given by info.func
			self.StackCount = self.StackCount + 1
			local stackEntry = self.Stack [self.StackCount] or GCompute.Profiler.InstrumentingProfilerStackEntry ()
			self.Stack [self.StackCount] = stackEntry
			stackEntry:SetFunctionEntry (functionEntry)
			stackEntry:Enter ()
			
			if self.StackCount > 1 then
				self.Stack [self.StackCount - 1]:Pause (stackEntry)
			end
			
			if info.what == "C" then
				debug.sethook (self.NativeReturnDebugHook, "")
			end
		elseif reason == "return" then
			-- About to leave function given by info.func
			while self.StackCount > 0 do
				if self.Stack [self.StackCount].FunctionEntry == functionEntry then
					self.Stack [self.StackCount]:Exit ()
					self.StackCount = self.StackCount - 1
					break
				end
				self.Stack [self.StackCount]:Exit ()
				self.StackCount = self.StackCount - 1
			end
			
			if self.StackCount > 0 then
				self.Stack [self.StackCount]:Resume ()
			end
		end
	end
end

function self:dtor ()
	self:Stop ()
end

function self:Start ()
	if self.Running then return end
	
	if not self.ProfilingResultSet then
		self:SetProfilingResultSet (GCompute.Profiling.ProfilingResultSet ())
	end
	
	hook.Add ("HUDPaint", "GCompute.Profiler.InstrumentingProfiler." .. self:GetHashCode (),
		function ()
			if debug.gethook () ~= self.DebugHook then
				self:ApplyDebugHook () -- FITE ME IRL
			end
		end
	)
	
	self:ApplyDebugHook ()
	
	self:SetRunning (true)
end

function self:Stop ()
	if not self.Running then return end
	
	debug.sethook ()
	
	hook.Remove ("HUDPaint", "GCompute.Profiler.InstrumentingProfiler." .. self:GetHashCode ())
	
	self:SetRunning (false)
end

function self:ApplyDebugHook ()
	debug.sethook (self.DebugHook, "cr")
end

GCompute.Profiling.InstrumentingProfiler = GCompute.Profiling.InstrumentingProfiler ()