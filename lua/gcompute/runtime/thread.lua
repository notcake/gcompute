local self = {}
GCompute.Thread = GCompute.MakeConstructor (self)

local nextThreadId = 0

--[[
	Events:
		Terminated ()
			Fired when this thread has terminated.
]]

function self:ctor (process)
	self.ThreadID = nextThreadId
	nextThreadId = nextThreadId + 1

	self.Process = process
	self.ExecutionContext = GCompute.ExecutionContext (process, self)
	self.Name = "Thread " .. string.format ("%08x", self.ThreadID)
	
	self.Started = false
	self.Terminated = false
	
	self.Function = GCompute.NullCallback
	self.Parameters = {}
	
	-- Statistics
	self.CpuTime = 0
	self.LastExecutionTime = 0
	
	GCompute.EventProvider (self)
end

function self:GetCpuTime ()
	if SysTime () - self.LastExecutionTime > 0.5 then return 0 end
	return self.CpuTime
end

function self:GetExecutionContext ()
	return self.ExecutionContext
end

function self:GetProcess ()
	return self.Process
end

function self:GetThreadID ()
	return self.ThreadID
end

function self:GetName ()
	return self.Name
end

function self:IsRunning ()
	return self.Started and not self.Terminated
end

function self:RunSome ()
	if not self.Started then return end
	if self.Terminated then return end
	
	local _executionContext = _G.executionContext
	_G.executionContext = self:GetExecutionContext ()
	
	local startTime = SysTime ()
	repeat
		executionContext:PopResumeFunction () ()
	until not self:IsRunning () or SysTime () - startTime >= 0.001
	
	self.CpuTime = SysTime () - startTime
	self.LastExecutionTime = SysTime ()
	
	_G.executionContext = _executionContext
end

function self:SetFunction (threadFunction)
	self.Function = threadFunction
end

function self:SetName (name)
	self.Name = name
end

function self:Start (...)
	if self.Started then return false end
	
	self.Started = true
	self.Parameters = { ... }
	
	self.ExecutionContext:PushResumeFunction (
		function ()
			self:Terminate ()
		end
	)
	self.ExecutionContext:PushResumeFunction (
		function ()
			self.Function (unpack (self.Parameters))
		end
	)
end

function self:Terminate ()
	if self.Terminated then return end
	
	self.Terminated = true
	self:DispatchEvent ("Terminated")
end

function self:Yield (...)
	coroutine.yield (...)
end