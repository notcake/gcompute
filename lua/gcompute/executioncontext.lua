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
	
	self.TopStackFrame = nil
	self.Stack = GCompute.Containers.Stack ()
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
	if not self.BreakFlag then return end
	
	self.BreakFlag = false
	self.InterruptFlag = false
end

function self:ClearContinue ()
	if not self.ContinueFlag then return end

	self.ContinueFlag = false
	self.InterruptFlag = false
end

function self:ClearReturn ()
	if not self.ReturnFlag then return end

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

function self:PopStackFrame ()
	self.Stack:Pop ()
	self.TopStackFrame = self.Stack.Top
	return self.TopStackFrame
end

function self:PushStackFrame (stackFrame)
	self.Stack:Push (stackFrame)
	self.TopStackFrame = self.Stack.Top
end

function self:Return (value)
	self.ReturnValue = value
	
	self.ReturnFlag = true
	self.InterruptFlag = true
end