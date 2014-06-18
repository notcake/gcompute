local self = {}
GCompute.Profiling.SamplingProfiler = GCompute.MakeConstructor (self, GCompute.Profiling.Profiler)

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
	self.SamplesLastFrame = 0
	self.SamplesThisFrame = 0
	self.DebugHook = function (reason)
		local profilingResultSet = self.ProfilingResultSet
		
		if not profilingResultSet then
			self:Stop ()
			return
		end
		
		self.SamplesThisFrame = self.SamplesThisFrame + 1
		profilingResultSet.SampleCount = profilingResultSet.SampleCount + 1
		
		if self.SamplesThisFrame >= 512 then
			-- Our sampling rate is too high, lower it
			self.InstructionInterval = self.InstructionInterval * 2
			self:ApplyDebugHook ()
		end
		
		-- Get stack trace
		local stackTrace = GLib.Lua.StackTrace (nil, 1)
		
		local previousStackFrame = stackTrace:GetFrame (1)
		local previousRawFunction = previousStackFrame:GetRawFunction ()
		local previousFunctionEntry = profilingResultSet:GetFunctionEntry (previousRawFunction)
		previousRawFunction = previousFunctionEntry:GetRawFunction () -- Closures will be mapped to a single raw function
		
		-- First frame
		previousFunctionEntry.TotalSampleCount = previousFunctionEntry.TotalSampleCount + 1
		previousFunctionEntry.ExclusiveSampleCount = previousFunctionEntry.ExclusiveSampleCount + 1
		previousFunctionEntry.InclusiveSampleCount = previousFunctionEntry.InclusiveSampleCount + 1
		
		previousFunctionEntry.LineCounts [previousStackFrame:GetCurrentLine ()] = (previousFunctionEntry.LineCounts [previousStackFrame:GetCurrentLine ()] or 0) + 1
		
		for i = 2, stackTrace:GetFrameCount () do
			local stackFrame = stackTrace:GetFrame (i)
			local rawFunction = stackFrame:GetRawFunction ()
			local functionEntry = profilingResultSet:GetFunctionEntry (rawFunction)
			rawFunction = functionEntry:GetRawFunction () -- Closures will be mapped to a single raw function
			
			functionEntry.TotalSampleCount = functionEntry.TotalSampleCount + 1
			functionEntry.InclusiveSampleCount = functionEntry.InclusiveSampleCount + 1
			
			functionEntry.LineCounts [stackFrame:GetCurrentLine ()] = (functionEntry.LineCounts [stackFrame:GetCurrentLine ()] or 0) + 1
			
			functionEntry.TotalCalleeCount = functionEntry.TotalCalleeCount + 1
			functionEntry.CalleeCounts [previousRawFunction] = (functionEntry.CalleeCounts [previousRawFunction] or 0) + 1
			
			previousFunctionEntry.TotalCallerCount = previousFunctionEntry.TotalCallerCount + 1
			previousFunctionEntry.CallerCounts [rawFunction] = (previousFunctionEntry.CallerCounts [rawFunction] or 0) + 1
			
			-- Advance
			previousStackFrame = stackFrame
			previousRawFunction = rawFunction
			previousFunctionEntry = functionEntry
		end
	end
	self.InstructionInterval = nil
end

function self:dtor ()
	self:Stop ()
end

function self:GetSampleRate ()
	return self.SamplesLastFrame
end

function self:Start ()
	if self.Running then return end
	
	if not self.ProfilingResultSet then
		self:SetProfilingResultSet (GCompute.Profiling.ProfilingResultSet ())
	end
	
	hook.Add ("HUDPaint", "GCompute.Profiler.SamplingProfiler." .. self:GetHashCode (),
		function ()
			if debug.gethook () ~= self.DebugHook then
				self:ApplyDebugHook () -- FITE ME IRL
			end
			
			if self.SamplesThisFrame < 256 then
				-- Our sampling rate is too low, raise it
				self.InstructionInterval = self.InstructionInterval / 2
				self:ApplyDebugHook ()
			end
			
			self.SamplesLastFrame = self.SamplesThisFrame
			self.SamplesThisFrame = 0
		end
	)
	
	self.InstructionInterval = self.InstructionInterval or 1024
	self:ApplyDebugHook ()
	
	self:SetRunning (true)
end

function self:Stop ()
	if not self.Running then return end
	
	debug.sethook ()
	
	hook.Remove ("HUDPaint", "GCompute.Profiler.SamplingProfiler." .. self:GetHashCode ())
	
	self:SetRunning (false)
end

function self:ApplyDebugHook ()
	debug.sethook (self.DebugHook, "", self.InstructionInterval)
end

GCompute.Profiling.SamplingProfiler = GCompute.Profiling.SamplingProfiler ()