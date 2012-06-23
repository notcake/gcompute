local self = {}
GCompute.ExecutionContext = GCompute.MakeConstructor (self)

function self:ctor (process, thread)
	if not thread then ErrorNoHalt ("ExecutionContexts should only be created by Threads.\n") GCompute.PrintStackTrace () end
	self.Process = process
	self.Thread = thread

	self.ScopeLookup = GCompute.ScopeLookup ()
	
	self.InterruptFlag = false
	
	self.BreakFlag = false
	self.ContinueFlag = false
	self.ReturnFlag = false
	self.ReturnValue = nil
	self.ReturnValueReference = nil
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
	local returnValueReference = self.ReturnValueReference
	
	self.ReturnValue = nil
	self.ReturnValueReference = nil
	
	return returnValue, returnValueReference
end

function self:Error (message)
	ErrorNoHalt (message .. "\n")
end

function self:GetProcess ()
	return self.Process
end

function self:GetReturnValue ()
	return self.ReturnValue, self.ReturnValueReference
end

function self:GetThread ()
	return self.Thread
end

function self:PopScope ()
	self.ScopeLookup:PopScope ()
end

function self:PushScope (scope)
	local ScopeInstance = scope:CreateInstance ()
	ScopeInstance:SetParentScope (scope:GetParentScope ())
	self.ScopeLookup:PushScope (ScopeInstance)
	
	return ScopeInstance
end

--[[
	ExecutionContext:PushBlockScope (Scope scopeDefinition)
		Returns: Scope scopeInstance
		
		Pushes an instance of scopeDefinition onto the scope stack, setting
		its parent to the scope that was at the top of the stack.
]]
function self:PushBlockScope (scope)
	local ScopeInstance = scope:CreateInstance ()
	ScopeInstance:SetParentScope (self.ScopeLookup.TopScope)
	self.ScopeLookup:PushScope (ScopeInstance)
	
	return ScopeInstance
end

function self:Return (value, reference)
	self.ReturnValue = value
	self.ReturnValueReference = reference
	
	self.ReturnFlag = true
	self.InterruptFlag = true
end

function self:TopScope ()
	return self.ScopeLookup.TopScope
end