local self = {}
GCompute.Process = GCompute.MakeConstructor (self)

local nextProcessId = 0

function self:ctor ()
	self.ProcessId = nextProcessId
	nextProcessId = nextProcessId + 1

	self.Modules = {}
	self.Threads = {}
	
	self.NamespaceDefinition = {}
	self.RuntimeNamespace = {}
	self.StdIn = nil
	self.StdOut = nil
end

function self:CreateThread ()
	local thread = GCompute.Thread (self)
	self.Threads [thread:GetThreadID ()] = thread
	
	return thread
end

function self:GetNamespace ()
	return self.NamespaceDefinition
end

function self:GetRuntimeNamespace ()
	return self.RuntimeNamespace
end

function self:SetNamespace (namespaceDefinition)
	self.NamespaceDefinition = namespaceDefinition
end

function self:Start ()
	self.RuntimeNamespace = self.NamespaceDefinition:CreateRuntimeNamespace ()
	A = self.RuntimeNamespace
	
	local mainThread = self:CreateThread ()
	mainThread:SetName ("Main Thread")
	mainThread:SetFunction (function (self)
		self:GetProcess ():GetNamespace ():GetConstructor () (self:GetExecutionContext ())
	end)
	mainThread:Start ()
end