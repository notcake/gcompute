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
	self.Threads   = {}
	
	-- Environment
	self.RootNamespace = GCompute.MirrorNamespaceDefinition ()
	self.Environment   = {}
	
	self.ProcessLocalStorage = {}
	
	-- IO
	self.StdIn  = nil
	self.StdOut = GCompute.Pipe ()
	self.StdErr = GCompute.Pipe ()
	
	GCompute.EventProvider (self)
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
end

function self:Start ()
	if self.Started then return end

	self.Started = true
	self.Environment = self.RootNamespace:CreateRuntimeObject ()
	
	local mainThread = self:CreateThread ()
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

-- Threads
function self:CreateThread ()
	local thread = GCompute.Thread (self)
	self.Threads [thread:GetThreadID ()] = thread
	
	GCompute:DispatchEvent ("ThreadCreated", self, thread)
	
	return thread
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