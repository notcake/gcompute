local self = {}
GCompute.Execution.ExecutionServiceExecutionFilterable = GCompute.MakeConstructor (self, GCompute.Execution.IExecutionFilterable)

--[[
	Events:
		CanCreateExecutionContext (authId, hostId, languageName)
			Fired when an execution context is about to be created.
		CanCreateExecutionInstance (IExecutionContext executionContext, code, sourceId, instanceOptions)
			Fired when an execution instance is about to be created.
		CanStartExecution (IExecutionInstance executionInstance)
			Fired when an execution instance is about to start execution. 
		ExecutionContextCreated (IExecutionContext executionContext)
			Fired when an execution context has been created.
		ExecutionInstanceCreated (IExecutionContext executionContext, IExecutionInstance executionInstance)
			Fired when an execution instance has been created.
]]

function self:ctor (executionService)
	self.ExecutionService = nil
	self.ExecutionContexts  = GLib.WeakKeyTable ()
	self.ExecutionInstances = GLib.WeakKeyTable ()
	
	GCompute.EventProvider (self)
	
	self:SetExecutionService (executionService)
end

function self:SetExecutionService (executionService)
	if self.ExecutionService == executionService then return self end
	
	self:UnhookExecutionService (self.ExecutionService)
	self:UnhookExecutionContexts ()
	self:UnhookExecutionInstances ()
	self.ExecutionService = executionService
	self:HookExecutionService (self.ExecutionService)
	
	return self
end

-- Internal, do not call
function self:HookExecutionService (executionService)
	if not executionService then return end
	
	executionService:AddEventListener ("CanCreateExecutionContext", "GCompute.ExecutionServiceExecutionFilterable." .. self:GetHashCode (),
		function (_, authId, hostId, languageName)
			return self:DispatchEvent ("CanCreateExecutionContext", authId, hostId, languageName)
		end
	)
	
	executionService:AddEventListener ("ExecutionContextCreated", "GCompute.ExecutionServiceExecutionFilterable." .. self:GetHashCode (),
		function (_, executionContext)
			self:HookExecutionContext (executionContext)
			self.ExecutionContexts [executionContext] = true
			
			return self:DispatchEvent ("ExecutionContextCreated", executionContext)
		end
	)
end

function self:UnhookExecutionService (executionService)
	if not executionService then return end
	
	executionService:RemoveEventListener ("CanCreateExecutionContext", "GCompute.ExecutionServiceExecutionFilterable." .. self:GetHashCode ())
	executionService:RemoveEventListener ("ExecutionContextCreated",   "GCompute.ExecutionServiceExecutionFilterable." .. self:GetHashCode ())
end

function self:UnhookExecutionContexts ()
	for executionContext, _ in pairs (self.ExecutionContexts) do
		self:UnhookExecutionContext (executionContext)
	end
	
	self.ExecutionContexts = GLib.WeakKeyTable ()
end

function self:HookExecutionContext (executionContext)
	if not executionContext then return end
	
	executionContext:AddEventListener ("CanCreateExecutionInstance", "GCompute.ExecutionServiceExecutionFilterable." .. self:GetHashCode (),
		function (_, code, sourceId, instanceOptions)
			return self:DispatchEvent ("CanCreateExecutionInstance", executionContext, code, sourceId, instanceOptions)
		end
	)
	
	executionContext:AddEventListener ("ExecutionInstanceCreated", "GCompute.ExecutionServiceExecutionFilterable." .. self:GetHashCode (),
		function (_, executionInstance)
			self:HookExecutionInstance (executionInstance)
			self.ExecutionInstances [executionInstance] = true
			
			return self:DispatchEvent ("ExecutionInstanceCreated", executionContext, executionInstance)
		end
	)
end

function self:UnhookExecutionContext (executionContext)
	if not executionContext then return end
	
	executionContext:RemoveEventListener ("CanCreateExecutionInstance", "GCompute.ExecutionServiceExecutionFilterable." .. self:GetHashCode ())
	executionContext:RemoveEventListener ("ExecutionInstanceCreated",   "GCompute.ExecutionServiceExecutionFilterable." .. self:GetHashCode ())
end

function self:UnhookExecutionInstances ()
	for executionInstance, _ in pairs (self.ExecutionInstances) do
		self:UnhookExecutionInstance (executionInstance)
	end
	
	self.ExecutionInstances = GLib.WeakKeyTable ()
end

function self:HookExecutionInstance (executionInstance)
	if not executionInstance then return end
	
	executionInstance:AddEventListener ("CanStartExecution", "GCompute.ExecutionServiceExecutionFilterable." .. self:GetHashCode (),
		function (_)
			return self:DispatchEvent ("CanStartExecution", executionInstance)
		end
	)
end

function self:UnhookExecutionInstance (executionInstance)
	if not executionInstance then return end
	
	executionInstance:RemoveEventListener ("CanStartExecution", "GCompute.ExecutionServiceExecutionFilterable." .. self:GetHashCode ())
end