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
		ThreadCreated (thread)
			Fired when this process creates a thread.
		ThreadTerminated (thread)
			Fired when a thread belonging to this process has terminated.
]]

function self:ctor (processList, processId)
	if not processList then
		GCompute.Error ("Processes should be created with GCompute.LocalProcessList:CreateProcess ()")
	end

	self.ProcessList = processList
	
	-- Identity
	self.ProcessId = processId
	self.Name = "Process " .. string.format ("%08x", self.ProcessId)
	self.OwnerId = GLib.GetSystemId ()
	
	-- Modules
	self.Modules   = {}
	self.ModuleSet = {}
	
	-- Process
	self.CreationTimestamp = os.time ()
	
	self.Started     = false
	self.Suspended   = false
	self.Terminating = false
	self.Terminated  = false
	
	-- Threads
	self.MainThread  = nil
	self.Threads     = {}
	
	-- Environment
	self.RootNamespace = GCompute.MirrorNamespaceDefinition ()
	self.Environment   = {}
	
	self.ProcessLocalStorage = {}
	
	-- Holds
	self.Holds = {}
	
	-- IO
	self.StdIn  = nil
	self.StdOut = GCompute.Pipe ()
	self.StdErr = GCompute.Pipe ()
	
	GCompute.EventProvider (self)
	
	self:AddEventListener ("ThreadTerminated",
		function (_, thread)
			if self.MainThread == thread then
				self.MainThread = nil
			end
			self:CheckShouldTerminate ()
		end
	)
end

-- Identity
function self:GetName ()
	return self.Name
end

function self:GetOwnerId ()
	return self.OwnerId
end

function self:GetProcessId ()
	return self.ProcessId
end

function self:SetName (name)
	name = name or string.format ("Process %08x", self:GetProcessId ())
	if self.Name == name then return end
	
	self.Name = name
	self:DispatchEvent ("NameChanged", name)
end

function self:SetOwnerId (ownerId)
	self.OwnerId = ownerId
end

-- Modules
function self:AddModule (module)
	if self.ModuleSet [module] then return end
	self.ModuleSet [module] = true
	
	for referencedModule in module:GetReferencedModuleEnumerator () do
		self:AddModule (referencedModule)
	end
	
	self.Modules [#self.Modules + 1] = module
	
	self.RootNamespace:AddSourceNamespace (module:GetRootNamespace ())
end

function self:GetModule (index)
	return self.Modules [index]
end

function self:GetModuleCount ()
	return #self.Modules
end

function self:GetModuleEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Modules [i]
	end
end

-- Process
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

function self:Resume ()
	if not self.Suspended then return end
	
	self.Suspended = false
	self:DispatchEvent ("Resumed")
	GCompute:DispatchEvent ("ProcessResumed", self)
end

function self:Start ()
	if self.Started then return end

	self.Started = true
	self.Environment = self.RootNamespace:CreateRuntimeObject ()
	
	local mainThread = self:CreateThread ()
	self.MainThread = mainThread
	mainThread:SetName ("Main Thread")
	mainThread:SetFunction (
		function ()
			self:GetStdOut ():WriteLine ("Starting process...")
			self:GetStdOut ():WriteLine (self:ToString ())
			for module in self:GetModuleEnumerator () do
				self:GetStdOut ():WriteLine ("\t" .. module:ToString ():gsub ("\n", "\n\t"))
			end
			self:GetRootNamespace ():GetConstructor () ()
		end
	)
	mainThread:Start ()
	
	self:DispatchEvent ("Started")
	GCompute:DispatchEvent ("ProcessStarted", self)
end

function self:Suspend ()
	if self.Suspended then return end
	
	self.Suspended = true
	self:DispatchEvent ("Suspended")
	GCompute:DispatchEvent ("ProcessSuspended", self)
end

function self:Terminate ()
	if self.Terminating or self.Terminated then return end
	
	self.Terminating = true
	self.Terminated = true
	self:DispatchEvent ("Terminated")
	GCompute:DispatchEvent ("ProcessTerminated", self)
end

-- Threads
function self:CreateThread ()
	local thread = GCompute.Thread (self)
	self.Threads [thread:GetThreadID ()] = thread
	
	thread:AddEventListener ("Terminated",
		function ()
			self.Threads [thread:GetThreadID ()] = nil
			self:DispatchEvent ("ThreadTerminated", thread)
			GCompute:DispatchEvent ("ThreadTerminated", self, thread)
		end
	)
	
	self:DispatchEvent ("ThreadCreated", thread)
	GCompute:DispatchEvent ("ThreadCreated", self, thread)
	
	return thread
end

function self:GetMainThread ()
	return self.MainThread
end

function self:GetThreadCount ()
	local count = 0
	for _, _ in pairs (self.Threads) do
		count = count + 1
	end
	return count
end

function self:GetThreadEnumerator ()
	return pairs (self.Threads)
end

-- Environment
function self:GetEnvironment ()
	return self.Environment
end

function self:GetRootNamespace ()
	return self.RootNamespace
end

function self:GetProcessLocalStorage ()
	return self.ProcessLocalStorage
end

-- Holds
function self:AddHold (holdName)
	self.Holds [holdName] = true
end

function self:GetHoldCount ()
	local count = 0
	for _, _ in pairs (self.Holds) do
		count = count + 1
	end
	return count
end

function self:GetHoldEnumerator ()
	local next, tbl, key = pairs (self.Holds)
	return function ()
		key = next (tbl, key)
		return key
	end
end

function self:RemoveHold (holdName)
	if not self.Holds [holdName] then return end
	
	self.Holds [holdName] = nil
	
	self:CheckShouldTerminate ()
end

-- IO
function self:GetStdErr ()
	return self.StdErr
end

function self:GetStdIn ()
	return self.StdIn
end

function self:GetStdOut ()
	return self.StdOut
end

function self:ToString ()
	return "[Process 0x" .. string.format ("%08x", self:GetProcessId ()) .. " (" .. self:GetName () .. ", " .. self:GetOwnerId () .. ")]"
end

-- Internal, do not call
function self:CheckShouldTerminate ()
	if self:GetThreadCount () == 0 and self:GetHoldCount () == 0 then
		self:Terminate ()
	end
end