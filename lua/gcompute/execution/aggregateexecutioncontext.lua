local self = {}
GCompute.Execution.AggregateExecutionContext = GCompute.MakeConstructor (self, GCompute.Execution.ExecutionContext)

--[[
	Events:
		CanCreateExecutionInstance (code, sourceId, instanceOptions)
			Fired when an execution instance is about to be created.
		ExecutionInstanceCreated (IExecutionInstance executionInstance)
			Fired when an execution instance has been created.
			
]]

local function DebugPrint (message)
	message = os.date ("%H:%M:%S") .. " " .. message
	
	if CLIENT then message = "[CL] " .. message end
	if SERVER then message = "[SV] " .. message end
	
	-- print (message)
end

function self:ctor (authId, hostId, languageName, contextOptions)
	self.HostId  = hostId
	self.OwnerId = authId
	
	self.LanguageName = languageName
	
	self.ContextOptions = contextOptions
	
	self.NormalizedHostIds   = {}
	self.NormalizedHostIdSet = {}
	
	-- Execution contexts
	self.HostIdExecutionContexts                     = {}
	self.HostIdExecutionContextCreationReturnCodes   = {}
	self.ExecutionContexts                           = {}
	self.ExecutionContextCreationCallbacks           = {}
	
	self.PendingExecutionContextCreationCount        = 0
	self.PendingExecutionContextCreationSet          = {}
	self.ExecutionContextCreationCompletionCallbacks = {}
	
	-- Execution instances
	self.ExecutionInstanceSet = GLib.WeakKeyTable ()
	
	-- Normalize the host ID
	self:AddToNormalizedHostId (self.HostId)
	
	DebugPrint ("AggregateExecutionContext:ctor")
	
	-- Create our execution contexts
	self:CreateExecutionContextsAsync ()
end

function self:dtor ()
	for _, executionContext in ipairs (self.ExecutionContexts) do
		executionContext:dtor ()
	end
	
	self.ExecutionContexts = {}
end

-- IExecutionContext
function self:CreateExecutionInstance (code, sourceId, instanceOptions, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	DebugPrint ("AggregateExecutionContext:CreateExecutionInstance")
	
	-- Check if creation is allowed
	local allowed, denialReason = self:CanCreateExecutionInstance (code, sourceId, instanceOptions)
	if not allowed then return false, denialReason end
	
	-- Create / update our execution contexts
	self:CreateExecutionContextsAsync ()
	
	-- Create execution instance
	local executionInstance = GCompute.Execution.AggregateExecutionInstance (self, instanceOptions)
	self.ExecutionInstanceSet [executionInstance] = true
	
	-- ExecutionInstanceCreated event
	self:DispatchEvent ("ExecutionInstanceCreated", executionInstance)
	
	executionInstance:CreateExecutionInstances (code, sourceId)
	
	return executionInstance
end

-- AggregateExecutionContext
function self:GetExecutionContextEnumerator ()
	return GLib.ArrayEnumerator (self.ExecutionContexts)
end

-- Internal, do not call
function self:AddToNormalizedHostId (hostId)
	if istable (hostId) then
		for _, hostId in ipairs (hostId) do
			self:AddToNormalizedHostId (hostId)
		end
		
		return
	end
	
	if SERVER and hostId == "Shared" then
		self:AddToNormalizedHostId (GLib.GetServerId ())
		self:AddToNormalizedHostId ("Clients")
		return
	end
	
	if self.NormalizedHostIdSet [hostId] then return end
	
	self.NormalizedHostIdSet [hostId] = true
	self.NormalizedHostIds [#self.NormalizedHostIds + 1] = hostId
end

-- Creates execution contexts and blocks
-- until they are all created or the timeout period has elapsed
function self:CreateExecutionContexts (timeout, callback)
	if not callback then return I (GLib.CallSelfAsAsync ()) end
	
	DebugPrint ("AggregateExecutionContext:CreateExecutionContexts")
	DebugPrint (GLib.StackTrace ())
	timeout = timeout or 5
	
	local waitAborted   = false
	local waitSucceeded = false
	timer.Simple (timeout,
		function ()
			if waitSucceeded then return end
			
			DebugPrint ("AggregateExecutionContext:CreateExecutionContexts timeout")
			
			waitAborted = true
			callback ()
		end
	)
	
	self:CreateExecutionContextsAsync ()
	
	self:AddExecutionContextCreationCompletionCallback (
		function ()
			if waitAborted then return end
			
			DebugPrint ("AggregateExecutionContext:CreateExecutionContexts success!?!?")
			
			waitSucceeded = true
			callback ()
		end
	)
end

function self:CreateExecutionContextsAsync ()
	-- Split off the local host ID from the hosts list
	local routedHostIds = {}
	for _, hostId in ipairs (self.NormalizedHostIds) do
		if hostId == GLib.GetLocalId () then
			-- Split off local host ID
			self:CreateLocalExecutionContext (hostId, hostId)
		else
			routedHostIds [#routedHostIds + 1] = hostId
		end
	end
	
	-- Handle routed hosts
	if #routedHostIds > 0 then
		if CLIENT then
			-- Create one big remote execution context for everything.
			self:CreateRemoteExecutionContext ("Remote", routedHostIds)
		elseif SERVER then
			-- Create an execution context for each entry needing routing.
			for _, hostId in ipairs (routedHostIds) do
				if hostId == "Clients" then
					-- Create an execution context for each client.
					for userId in GCompute.PlayerMonitor:GetUserEnumerator () do
						self:CreateRemoteExecutionContext (userId, userId)
					end
				else
					-- Create a remote execution context
					self:CreateRemoteExecutionContext (hostId, hostId)
				end
			end
		else
			-- What is this I don't even.
		end
	end
end

function self:CreateExecutionContext (creationId, executionService, hostId, callback)
	-- Check if the execution context already exists
	if self.HostIdExecutionContexts [creationId] then
		-- Nothing to do here.
		if callback then
			callback (self.HostIdExecutionContexts [creationId], self.HostIdExecutionContextCreationReturnCodes [creationId])
		end
		
		return
	end
	
	-- Register the callback
	self.ExecutionContextCreationCallbacks [creationId] = self.ExecutionContextCreationCallbacks [creationId] or {}
	self.ExecutionContextCreationCallbacks [creationId] [#self.ExecutionContextCreationCallbacks [creationId] + 1] = callback
	
	-- Check if a creation request is already in progress
	if self.PendingExecutionContextCreationSet [creationId] then return end
	
	-- Make the creation request
	self.PendingExecutionContextCreationCount = self.PendingExecutionContextCreationCount + 1
	self.PendingExecutionContextCreationSet [creationId] = true
	
	GLib.CallAsync (
		function ()
			local executionContext, returnCode = executionService:CreateExecutionContext (self:GetOwnerId (), hostId, self:GetLanguageName (), self:GetContextOptions ())
			
			-- Register the execution context
			self:RegisterExecutionContext (creationId, executionContext, returncode)
			
			-- Call creation callbacks
			for _, callback in ipairs (self.ExecutionContextCreationCallbacks [creationId]) do
				callback (executionContext, returnCode)
			end
			
			self.ExecutionContextCreationCallbacks [creationId] = nil
			
			-- No longer pending
			self.PendingExecutionContextCreationCount = self.PendingExecutionContextCreationCount - 1
			self.PendingExecutionContextCreationSet [creationId] = nil
			
			if self.PendingExecutionContextCreationCount == 0 then
				self:CallExecutionContextCreationCompletionCallbacks ()
			end
			
			-- Delayed creation of execution instances
			if executionContext then
				for executionInstance in pairs (self.ExecutionInstanceSet) do
					executionInstance:CreateExecutionInstance (executionContext)
				end
			end
		end
	)
end

function self:CreateLocalExecutionContext (creationId, hostId, callback)
	self:CreateExecutionContext (creationId, GCompute.Execution.LocalExecutionService, hostId, callback)
end

function self:CreateRemoteExecutionContext (creationId, hostId, callback)
	self:CreateExecutionContext (creationId, GCompute.Execution.RemoteExecutionService, hostId, callback)
end

function self:RegisterExecutionContext (creationId, executionContext, returnCode)
	DebugPrint ("AggregateExecutionContext:RegisterExecutionContext " .. tostring (creationId))
	
	self.HostIdExecutionContexts                   [creationId] = executionContext
	self.HostIdExecutionContextCreationReturnCodes [creationId] = returnCode
	
	if executionContext then
		self.ExecutionContexts [#self.ExecutionContexts + 1] = executionContext
	end
end

function self:AddExecutionContextCreationCompletionCallback (callback)
	if self.PendingExecutionContextCreationCount == 0 then
		callback ()
		return
	end
	
	self.ExecutionContextCreationCompletionCallbacks [#self.ExecutionContextCreationCompletionCallbacks + 1] = callback
end

function self:CallExecutionContextCreationCompletionCallbacks ()
	for _, callback in ipairs (self.ExecutionContextCreationCompletionCallbacks) do
		callback ()
	end
	
	self.ExecutionContextCreationCompletionCallbacks = {}
end