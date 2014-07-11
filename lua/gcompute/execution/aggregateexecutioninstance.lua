local self = {}
GCompute.Execution.AggregateExecutionInstance = GCompute.MakeConstructor (self, GCompute.Execution.IExecutionInstance)

local function DebugPrint (message)
	message = os.date ("%H:%M:%S") .. " " .. message
	
	if CLIENT then message = "[CL] " .. message end
	if SERVER then message = "[SV] " .. message end
	
	-- print (message)
end

function self:ctor (aggregateExecutionContext, instanceOptions)
	self.ExecutionContext = aggregateExecutionContext
	
	self.InstanceOptions = instanceOptions
	
	-- IO
	self.StdIn  = GCompute.Pipe ()
	self.StdOut = GCompute.Pipe ()
	self.StdErr = GCompute.Pipe ()
	self.CompilerStdOut = GCompute.Pipe ()
	self.CompilerStdErr = GCompute.Pipe ()
	
	-- State
	self.State = GCompute.Execution.ExecutionInstanceState.Uncompiled
	
	-- Aggregate execution instance
	self.ExecutionInstanceFactory = GCompute.NullCallback
	
	-- Execution instances
	self.ExecutionContextExecutionInstances          = GLib.WeakKeyTable ()
	self.ExecutionContextReturnCodes                 = GLib.WeakKeyTable ()
	self.ExecutionInstances                          = {}
	self.ExecutionInstanceCreationCallbacks          = {}
	
	self.PendingExecutionInstanceCreationCount       = 0
	self.PendingExecutionInstanceCreationSet         = {}
	self.ExecutionInstanceCreationCompletionCallbacks = {}
	
	-- I/O
	self.PipeLastSources = {}
	
	GCompute.EventProvider (self)
end

function self:dtor ()
	for _, executionInstance in ipairs (self.ExecutionInstances) do
		self:UnhookExecutionInstance (executionInstance)
		executionInstance:dtor ()
	end
	
	self.ExecutionInstances = {}
end

-- IExecutionInstance
function self:GetExecutionContext ()
	return self.ExecutionContext
end

function self:GetHostId ()
	return self.ExecutionContext:GetHostId()
end

function self:GetOwnerId ()
	return self.ExecutionContext:GetOwnerId()
end

function self:GetInstanceOptions ()
	return self.InstanceOptions
end

-- IO
function self:GetStdIn ()
	return self.StdIn
end

function self:GetStdOut ()
	return self.StdOut
end

function self:GetStdErr ()
	return self.StdErr
end

function self:GetCompilerStdOut ()
	return self.CompilerStdOut
end

function self:GetCompilerStdErr ()
	return self.CompilerStdErr
end

-- Control
function self:Compile ()
	for _, executionInstance in ipairs (self.ExecutionInstances) do
		executionInstance:Compile ()
	end
	
	self:SetState (GCompute.Execution.ExecutionInstanceState.Compiled)
end

function self:Start ()
	if self:IsStarted    () then return end
	if self:IsTerminated () then return end
	
	-- CanStartExecution event
	if not self:DispatchEvent ("CanStartExecution") == false then return end
	
	if GLib.CallSelfInThread () then return end
	
	if not self:IsCompiled () then
		self:Compile ()
	end
	
	self:SetState (GCompute.Execution.ExecutionInstanceState.Running)
	
	for _, executionInstance in ipairs (self.ExecutionInstances) do
		executionInstance:Start ()
	end
end

function self:Terminate ()
	for _, executionInstance in ipairs (self.ExecutionInstances) do
		executionInstance:Terminate ()
	end
	
	self:SetState (GCompute.Execution.ExecutionInstanceState.Terminated)
end

-- State
function self:GetState ()
	return self.State
end

-- AggregateExecutionInstance
function self:CreateExecutionInstances (code, sourceId, timeout, callback)
	if not callback then return I (GLib.CallSelfAsAsync ()) end
	
	DebugPrint ("AggregateExecutionInstance:CreateExecutionInstances")
	timeout = timeout or 5
	
	local waitAborted   = false
	local waitSucceeded = false
	timer.Simple (timeout,
		function ()
			if waitSucceeded then return end
			
			DebugPrint ("AggregateExecutionInstance:CreateExecutionInstances timeout D:<")
			
			waitAborted = true
			callback ()
		end
	)
	
	self:CreateExecutionInstancesAsync (code, sourceId)
	
	self:AddExecutionInstanceCreationCompletionCallback (
		function ()
			if waitAborted then return end
			
			DebugPrint ("AggregateExecutionInstance:CreateExecutionInstances success!?!?")
			
			waitSucceeded = true
			callback ()
		end
	)
end

function self:CreateExecutionInstance (executionContext, callback)
	-- Check if the instance already exists
	if self.ExecutionContextExecutionInstances [executionContext] then
		-- Nothing to do here.
		if callback then
			callback (self.ExecutionContextExecutionInstances [executionContext], self.ExecutionContextReturnCodes [executionContext])
		end
		
		return
	end
	
	-- Register the callback
	self.ExecutionInstanceCreationCallbacks [executionContext] = self.ExecutionInstanceCreationCallbacks [executionContext] or {}
	self.ExecutionInstanceCreationCallbacks [executionContext] [#self.ExecutionInstanceCreationCallbacks [executionContext] + 1] = callback
	
	-- Check if a creation request is already in progress
	if self.PendingExecutionInstanceCreationSet [executionContext] then return end
	
	-- Make the creation request
	self.PendingExecutionInstanceCreationCount = self.PendingExecutionInstanceCreationCount + 1
	self.PendingExecutionInstanceCreationSet [executionContext] = true
	
	GLib.CallAsync (
		function ()
			local executionInstance, returnCode = self.ExecutionInstanceFactory (executionContext)
			
			-- Register the execution instance
			self:RegisterExecutionInstance (executionContext, executionInstance, returnCode)
			
			-- Call creation callbacks
			for _, callback in ipairs (self.ExecutionInstanceCreationCallbacks [executionContext]) do
				callback (executionInstance, returnCode)
			end
			
			self.ExecutionInstanceCreationCallbacks [executionContext] = nil
			
			-- No longer pending
			self.PendingExecutionInstanceCreationCount = self.PendingExecutionInstanceCreationCount - 1
			self.PendingExecutionInstanceCreationSet [executionContext] = nil
			
			if self.PendingExecutionInstanceCreationCount == 0 then
				self:CallExecutionInstanceCreationCompletionCallbacks ()
			end
		end
	)
end

function self:GetExecutionInstanceEnumerator ()
	return GLib.ArrayEnumerator (self.ExecutionInstances)
end

-- Internal, do not call
function self:CreateExecutionInstancesAsync (code, sourceId)
	self.ExecutionInstanceFactory = function (executionContext)
		return executionContext:CreateExecutionInstance (code, sourceId, self:GetInstanceOptions ())
	end
	
	for executionContext in self:GetExecutionContext ():GetExecutionContextEnumerator () do
		DebugPrint ("AggregateExecutionInstance:CreateExecutionInstancesAsync : IExecutionContext:CreateExecutionInstance")
		
		self:CreateExecutionInstance (executionContext)
	end
end

function self:RegisterExecutionInstance (executionContext, executionInstance, returnCode)
	DebugPrint ("AggregateExecutionInstance:RegisterExecutionInstance " .. tostring (executionContext:GetHostId ()))
	
	self.ExecutionContextExecutionInstances [executionContext] = executionInstance
	self.ExecutionContextReturnCodes        [executionContext] = returnCode
	
	if executionInstance then
		self.ExecutionInstances [#self.ExecutionInstances + 1] = executionInstance
		self:HookExecutionInstance (executionInstance)
	else
		-- Bugger, what do we do here?
	end
end

function self:AddExecutionInstanceCreationCompletionCallback (callback)
	if self.PendingExecutionInstanceCreationCount == 0 then
		callback ()
		return
	end
	
	self.ExecutionInstanceCreationCompletionCallbacks [#self.ExecutionInstanceCreationCompletionCallbacks + 1] = callback
end

function self:CallExecutionInstanceCreationCompletionCallbacks ()
	for _, callback in ipairs (self.ExecutionInstanceCreationCompletionCallbacks) do
		callback ()
	end
	
	self.ExecutionInstanceCreationCompletionCallbacks = {}
end

local pipes =
{
	"GetCompilerStdOut",
	"GetCompilerStdErr",
	"GetStdOut",
	"GetStdErr"
}

function self:HookExecutionInstance (executionInstance)
	if not executionInstance then return end
	
	for _, pipeMethodName in ipairs (pipes) do
		local hostId              = executionInstance:GetHostId ()
		local executionInstanceId = executionInstance:GetHashCode ()
		local outputPipe = self [pipeMethodName] (self)
		
		executionInstance [pipeMethodName] (executionInstance):AddEventListener ("Text", "GCompute.AggregateExecutionInstance." .. self:GetHashCode (),
			function (_, text, color)
				-- Emit a line break and short header if the pipe's source has changed.
				if self.PipeLastSources [pipeMethodName] ~= executionInstanceId then
					if self.PipeLastSources [pipeMethodName] then
						outputPipe:Write ("\n")
					end
					
					if not self:IsAggregateHostId (hostId) then
						local hostName = GCompute.PlayerMonitor:GetUserName (hostId)
						if hostName == hostId then hostName = nil end
						
						if hostName then
							outputPipe:WriteColor ("[" .. hostId .. " (" .. hostName .. ")] ", GLib.Colors.Orange)
						else
							outputPipe:WriteColor ("[" .. hostId .. "] ", GLib.Colors.Orange)
						end
					end
				end
				self.PipeLastSources [pipeMethodName] = executionInstanceId
				
				if color then
					outputPipe:WriteColor (text, color)
				else
					outputPipe:Write (text)
				end
			end
		)
	end
end

function self:UnhookExecutionInstance (executionInstance)
	if not executionInstance then return end
	
	for _, pipeMethodName in ipairs (pipes) do
		executionInstance [pipeMethodName] (executionInstance):RemoveEventListener ("Text", "GCompute.AggregateExecutionInstance." .. self:GetHashCode ())
	end
end

function self:IsAggregateHostId (hostId)
	if istable (hostId)    then return true end
	if hostId == "Clients" then return true end
	if hostId == "Shared"  then return true end
	return false
end