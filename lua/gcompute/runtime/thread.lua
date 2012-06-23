local self = {}
GCompute.Thread = GCompute.MakeConstructor (self)

local nextThreadId = 0

function self:ctor (process)
	self.ThreadID = nextThreadId
	nextThreadId = nextThreadId + 1

	self.Process = process
	self.ExecutionContext = GCompute.ExecutionContext (process, self)
	self.Name = "Thread " .. tostring (self.ThreadID)
	
	self.Function = GCompute.NullCallback
	self.Running = false
	
	-- Non-coroutine execution model
	self.ResumeFunction = nil
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
	return self.Running
end

function self:SetFunction (threadFunction)
	self.Function = threadFunction
end

function self:SetName (name)
	self.Name = name
end

function self:Start (...)
	if self.Running then return false end
	
	self.Running = true
	self:Function (...)
end

function self:Yield (resumeFunction)
	self.ResumeFunction = resumeFunction or self.ResumeFunction
end