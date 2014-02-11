local self = {}
GCompute.Profiling.Profiler = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Profiling = false
	
	self.FunctionEntries = GLib.WeakKeyTable ()
	self.FunctionEntriesByPath = GLib.WeakTable ()
	
	self.SampleCount = 0
	self.SamplesLastFrame = 0
	self.SamplesThisFrame = 0
	self.DebugHook = function (reason)
		self.SamplesThisFrame = self.SamplesThisFrame + 1
		self.SampleCount = self.SampleCount + 1
		
		if self.SamplesThisFrame >= 512 then
			-- Our sampling rate is too high, lower it
			self.InstructionInterval = self.InstructionInterval * 2
			self:ApplyDebugHook ()
		end
		
		-- Get stack trace
		local stackTrace = GLib.Lua.StackTrace (nil, 1)
		
		local previousStackFrame = stackTrace:GetFrame (1)
		local previousRawFunction = previousStackFrame:GetRawFunction ()
		local previousFunctionEntry = self:GetFunctionEntry (previousRawFunction)
		
		-- First frame
		previousFunctionEntry.TotalSampleCount = previousFunctionEntry.TotalSampleCount + 1
		previousFunctionEntry.ExclusiveSampleCount = previousFunctionEntry.ExclusiveSampleCount + 1
		previousFunctionEntry.InclusiveSampleCount = previousFunctionEntry.InclusiveSampleCount + 1
		
		previousFunctionEntry.LineCounts [previousStackFrame:GetCurrentLine ()] = (previousFunctionEntry.LineCounts [previousStackFrame:GetCurrentLine ()] or 0) + 1
		
		for i = 1, stackTrace:GetFrameCount () do
			local stackFrame = stackTrace:GetFrame (i)
			local rawFunction = stackFrame:GetRawFunction ()
			local functionEntry = self:GetFunctionEntry (rawFunction)
			
			functionEntry.TotalSampleCount = functionEntry.TotalSampleCount + 1
			functionEntry.InclusiveSampleCount = functionEntry.InclusiveSampleCount + 1
			
			functionEntry.LineCounts [stackFrame:GetCurrentLine ()] = (functionEntry.LineCounts [stackFrame:GetCurrentLine ()] or 0) + 1
			
			functionEntry.TotalCalleeCount = functionEntry.TotalCalleeCount + 1
			functionEntry.CalleeCounts [rawFunction] = (functionEntry.CalleeCounts [rawFunction] or 0) + 1
			
			previousFunctionEntry.TotalCallerCount = functionEntry.TotalCallerCount + 1
			previousFunctionEntry.CallerCounts [rawFunction] = (functionEntry.CallerCounts [rawFunction] or 0) + 1
			
			-- Advance
			previousStackFrame = stackFrame
			previousRawFunction = rawFunction
			previousFunctionEntry = functionEntry
		end
	end
	self.InstructionInterval = nil
	
	GCompute:AddEventListener ("Unloaded",
		function ()
			self:dtor ()
		end
	)
end

function self:dtor ()
	self:Stop ()
end

function self:Clear ()
	self.SampleCount = 0
	self.FunctionEntries = GLib.WeakKeyTable ()
	self.FunctionEntriesByPath = GLib.WeakTable ()
end

function self:GetFunctionEntry (func)
	if not self.FunctionEntries [func] then
		local functionInfo = debug.getinfo (func)
		
		-- Check for a function entry by the function's path and span
		-- This is because we only want a single function entry for closures.
		local path = functionInfo.short_src .. ": " .. functionInfo.linedefined .. "-" .. functionInfo.lastlinedefined
		if self.FunctionEntriesByPath [path] then
			return self.FunctionEntriesByPath [path]
		end
		
		-- Otherwise go ahead and create the function entry
		local functionEntry = GCompute.Profiling.FunctionEntry (self, func)
		self.FunctionEntries [func] = functionEntry
		self.FunctionEntriesByPath [path] = functionEntry
	end
	
	return self.FunctionEntries [func]
end

function self:GetFunctionEntryEnumerator ()
	local next, tbl, key = pairs (self.FunctionEntries)
	
	return function ()
		key = next (tbl, key)
		return tbl [key]
	end
end

function self:GetSampleCount ()
	return self.SampleCount
end

function self:GetSampleRate ()
	return self.SamplesLastFrame
end

function self:IsRunning ()
	return self.Profiling
end

function self:Start ()
	if self.Profiling then return end
	
	self.Profiling = true
	
	hook.Add ("HUDPaint", "GCompute.Profiler",
		function ()
			if debug.gethook () ~= self.DebugHook then
				self:ApplyDebugHook ()
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
end

function self:Stop ()
	if not self.Profiling then return end
	
	self.Profiling = false
	
	debug.sethook ()
	
	hook.Remove ("HUDPaint", "GCompute.Profiler")
end

function self:ApplyDebugHook ()
	debug.sethook (self.DebugHook, "", self.InstructionInterval)
end

GCompute.Profiling.Profiler = GCompute.Profiling.Profiler ()