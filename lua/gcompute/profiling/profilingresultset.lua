local self = {}
GCompute.Profiling.ProfilingResultSet = GCompute.MakeConstructor (self)

--[[
	Events:
		Cleared ()
			Fired when the profiling results have been cleared.
]]

function self:ctor ()
	self.SampleCount = 0
	
	self.FunctionEntries = GLib.WeakKeyTable ()
	self.FunctionEntriesByPath = GLib.WeakTable ()
	
	GCompute.EventProvider (self)
end

function self:Clear ()
	self.SampleCount = 0
	self.FunctionEntries = GLib.WeakKeyTable ()
	self.FunctionEntriesByPath = GLib.WeakTable ()
	
	self:DispatchEvent ("Cleared")
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