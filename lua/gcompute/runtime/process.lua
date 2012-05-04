local Process = {}
GCompute.Process = GCompute.MakeConstructor (Process)

local nextProcessId = 0

function Process:ctor ()
	self.ProcessId = nextProcessId
	nextProcessId = nextProcessId + 1

	self.Modules = {}
	self.Threads = {}
	
	self.ProcessScope = nil
	self.StdIn = nil
	self.StdOut = nil
end

function Process:CreateThread ()
	local thread = GCompute.Thread (self)
	self.Threads [thread:GetThreadID ()] = thread
	
	return thread
end

function Process:GetScope ()
	return self.ProcessScope
end

function Process:SetScope (scope)
	self.ProcessScope = scope
end

function Process:Start ()
	local Main = self:CreateThread ()
	Main:SetName ("Main Thread")
	Main:SetFunction (function (self)
		self:GetProcess ():GetScope ().OptimizedBlock:Evaluate (self:GetExecutionContext ())
	end)
	Main:Start ()
end