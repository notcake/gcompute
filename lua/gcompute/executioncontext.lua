local self = {}
GCompute.ExecutionContext = GCompute.MakeConstructor (self)

function self:ctor (process, thread)
	if not thread then ErrorNoHalt ("ExecutionContexts should only be created by Threads.\n") GCompute.PrintStackTrace () end
	self.Process = process
	self.Thread = thread
	
	self.InterruptFlag = false
	
	self.BreakFlag = false
	self.ContinueFlag = false
	self.ReturnFlag = false
	self.ReturnValue = nil
end

function self:Break ()
	self.BreakFlag = true
	self.InterruptFlag = true
end

function self:Continue ()
	self.ContinueFlag = true
	self.InterruptFlag = true
end

function self:ClearInterrupt ()
	self.InterruptFlag = false
	
	self.BreakFlag = false
	self.ContinueFlag = false
	self.ReturnFlag = false
end

function self:ClearBreak ()
	self.BreakFlag = false
	self.InterruptFlag = false
end

function self:ClearContinue ()
	self.ContinueFlag = false
	self.InterruptFlag = false
end

function self:ClearReturn ()
	self.ReturnFlag = false
	self.InterruptFlag = false
	
	local returnValue = self.ReturnValue
	
	self.ReturnValue = nil
	
	return returnValue
end

function self:Error (message)
	ErrorNoHalt (message .. "\n")
end

function self:GetRuntimeNamespace ()
	return self.Process:GetRuntimeNamespace ()
end

function self:GetProcess ()
	return self.Process
end

function self:GetReturnValue ()
	return self.ReturnValue
end

function self:GetThread ()
	return self.Thread
end

function self:Return (value)
	self.ReturnValue = value
	
	self.ReturnFlag = true
	self.InterruptFlag = true
end