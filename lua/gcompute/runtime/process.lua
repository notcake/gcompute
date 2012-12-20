local self = {}
GCompute.Process = GCompute.MakeConstructor (self)

--[[
	Events:
		NameChanged (string name)
			Fired when the name of this process has changed.
		Resumed ()
			Fired when this process is resumed.
		Suspended ()
			Fired when this process is suspended.
		Started ()
			Fired when this process is started.
		Terminated ()
			Fired when this process is terminated.
]]

function self:ctor (processList, processId)
	if not processList then
		GCompute.Error ("Processes should be created with GCompute.LocalProcessList:CreateProcess ()")
	end

	self.ProcessList = processList
	self.ProcessId = processId
	
	self.Name = "Process " .. string.format ("%08x", self.ProcessId)
	self.CreationTimestamp = os.time ()
	
	self.Started = false
	self.Suspended = false
	self.Terminating = false
	self.Terminated = false

	self.Modules = {}
	self.Threads = {}
	
	self.NamespaceDefinition = {}
	self.RuntimeNamespace = {}
	
	self.ProcessLocalStorage = {}
	
	self.StdIn  = nil
	self.StdOut = GCompute.Pipe ()
	self.StdErr = GCompute.Pipe ()
	
	GCompute.EventProvider (self)
end

function self:CreateThread ()
	local thread = GCompute.Thread (self)
	self.Threads [thread:GetThreadID ()] = thread
	
	GCompute:DispatchEvent ("ThreadCreated", self, thread)
	
	return thread
end

function self:GetCreationTimestamp ()
	return self.CreationTimestamp
end

function self:GetCpuTime ()
	local cpuTime = 0
	for _, thread in pairs (self.Threads) do
		cpuTime = cpuTime + thread:GetCpuTime ()
	end
	return cpuTime
end

function self:GetName ()
	return self.Name
end

function self:GetNamespace ()
	return self.NamespaceDefinition
end

function self:GetProcessId ()
	return self.ProcessId
end

function self:GetProcessLocalStorage ()
	return self.ProcessLocalStorage
end

function self:GetRuntimeNamespace ()
	return self.RuntimeNamespace
end

function self:GetStdErr ()
	return self.StdErr
end

function self:GetStdIn ()
	return self.StdIn
end

function self:GetStdOut ()
	return self.StdOut
end

function self:GetThreadEnumerator ()
	return pairs (self.Threads)
end

function self:Resume ()
	if not self.Suspended then return end
	
	self.Suspended = false
	self:DispatchEvent ("Resumed")
end

function self:SetNamespace (namespaceDefinition)
	self.NamespaceDefinition = namespaceDefinition
end

function self:SetName (name)
	name = name or string.format ("Process %08x", self:GetProcessId ())
	if self.Name == name then return end
	
	self.Name = name
	self:DispatchEvent ("NameChanged", name)
end

function self:Start ()
	if self.Started then return end

	self.Started = true
	self.RuntimeNamespace = self.NamespaceDefinition:CreateRuntimeObject ()
	
	local mainThread = self:CreateThread ()
	mainThread:SetName ("Main Thread")
	mainThread:SetFunction (self:GetNamespace ():GetConstructor ())
	mainThread:Start ()
	
	mainThread:AddEventListener ("Terminated",
		function ()
			self:Terminate ()
		end
	)
	
	self:DispatchEvent ("Started")
end

function self:Suspend ()
	if self.Suspended then return end
	
	self.Suspended = true
	self:DispatchEvent ("Suspended")
end

function self:Terminate ()
	if self.Terminating or self.Terminated then return end
	
	self.Terminating = true
	self.Terminated = true
	self:DispatchEvent ("Terminated")
end