local self = {}
GCompute.Execution.IExecutionService = GCompute.MakeConstructor (self, GLib.IDisposable)

--[[
	Events:
		CanCreateExecutionContext (authId, hostId, languageName)
			Fired when an execution context is about to be created.
		ExecutionContextCreated (IExecutionContext executionContext)
			Fired when an execution context has been created.
			
]]

function self:ctor ()
end

function self:CanCreateExecutionContext (authId, hostId, languageName)
	GCompute.Error ("IExecutionService:CanCreateExecutionContext : Not implemented.")
end

function self:CreateExecutionContext (authId, hostId, languageName, contextOptions, callback)
	GCompute.Error ("IExecutionService:CreateExecutionContext : Not implemented.")
end

function self:GetHostEnumerator ()
	GCompute.Error ("IExecutionService:GetHostEnumerator : Not implemented.")
end

function self:GetLanguageEnumerator ()
	GCompute.Error ("IExecutionService:GetLanguageEnumerator : Not implemented.")
end

function self:IsAvailable ()
	return true
end