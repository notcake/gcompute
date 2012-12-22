local self = {}
GCompute.ExecutionContext = GCompute.MakeConstructor (self)

function self:ctor (process, thread)
	if not thread then ErrorNoHalt ("ExecutionContexts should only be created by Threads.\n") GCompute.PrintStackTrace () end
	self.Process = process
	self.Thread = thread
	
	-- Execution
	self.ASTRunner = GCompute.ASTRunner ()
	self.ResumeStack = GCompute.Containers.Stack ()
	
	-- Flow control
	self.InterruptFlag = false
	
	self.BreakFlag = false
	self.ContinueFlag = false
	self.ReturnFlag = false
	self.ReturnValue = nil
	
	-- Stack
	self.TopStackFrame = nil
	self.Stack = GCompute.Containers.Stack ()
end

-- Process
function self:GetProcess ()
	return self.Process
end

function self:GetProcessLocalStorage ()
	return self.Process:GetProcessLocalStorage ()
end

-- Thread
function self:GetThread ()
	return self.Thread
end

function self:GetThreadLocalStorage ()
	return self.Thread:GetThreadLocalStorage ()
end

-- IO
function self:GetStdErr ()
	return self:GetProcess ():GetStdErr ()
end

function self:GetStdIn ()
	return self:GetProcess ():GetStdIn ()
end

function self:GetStdOut ()
	return self:GetProcess ():GetStdOut ()
end

-- Execution
function self:Error (message)
	ErrorNoHalt (message .. "\n")
end

function self:GetASTRunner ()
	return self.ASTRunner
end

function self:GetEnvironment ()
	return self.Process:GetEnvironment ()
end

function self:GetReturnValue ()
	return self.ReturnValue
end

-- Execution
function self:PopResumeFunction ()
	return self.ResumeStack:Pop ()
end

function self:PushResumeFunction (func)
	self.ResumeStack:Push (func)
end

function self:PushResumeAST (astNode)
	self.ASTRunner:PushNode (nil) -- Push guard
	self.ASTRunner:PushNode (astNode)
	self.ASTRunner:PushState (0)
	
	self:PushResumeFunction (
		function ()
			self.ASTRunner:Resume ()
		end
	)
end

-- Flow control
function self:Break ()
	self.BreakFlag = true
	self.InterruptFlag = true
end

function self:ClearBreak ()
	if not self.BreakFlag then return end
	
	self.BreakFlag = false
	self.InterruptFlag = false
end

function self:Continue ()
	self.ContinueFlag = true
	self.InterruptFlag = true
end

function self:ClearContinue ()
	if not self.ContinueFlag then return end

	self.ContinueFlag = false
	self.InterruptFlag = false
end

function self:Return (value)
	self.ReturnValue = value
	
	self.ReturnFlag = true
	self.InterruptFlag = true
end

function self:ClearReturn ()
	if not self.ReturnFlag then return end

	self.ReturnFlag = false
	self.InterruptFlag = false
	
	local returnValue = self.ReturnValue
	
	self.ReturnValue = nil
	
	return returnValue
end

function self:ClearInterrupt ()
	self.InterruptFlag = false
	
	self.BreakFlag = false
	self.ContinueFlag = false
	self.ReturnFlag = false
end

-- Stack
function self:PopStackFrame ()
	self.Stack:Pop ()
	self.TopStackFrame = self.Stack.Top
	return self.TopStackFrame
end

function self:PushStackFrame (stackFrame)
	self.Stack:Push (stackFrame)
	self.TopStackFrame = self.Stack.Top
end