local self = {}
GCompute.Execution.IExecutionFilterable = GCompute.MakeConstructor (self)

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