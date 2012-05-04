local Thread = {}
GCompute.Thread = GCompute.MakeConstructor (Thread)

local LastThreadID = 0

local function DoNothing (self) end

function Thread:ctor (process)
	self.ThreadID = LastThreadID
	LastThreadID = LastThreadID + 1

	self.Process = process
	self.ExecutionContext = GCompute.ExecutionContext (process, self)
	self.Name = "Thread " .. tostring (self.ThreadID)
	
	self.Function = DoNothing
	self.Running = false
end

function Thread:GetExecutionContext ()
	return self.ExecutionContext
end

function Thread:GetProcess ()
	return self.Process
end

function Thread:GetThreadID ()
	return self.ThreadID
end

function Thread:GetName ()
	return self.Name
end

function Thread:IsRunning ()
	return self.Running
end

function Thread:SetFunction (threadFunction)
	self.Function = threadFunction
end

function Thread:SetName (name)
	self.Name = name
end

function Thread:Start (...)
	if self.Running then return false end
	
	self.Running = true
	self:Function (...)
end