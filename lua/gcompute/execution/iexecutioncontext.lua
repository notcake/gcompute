local self = {}
GCompute.Execution.IExecutionContext = GCompute.MakeConstructor (self, GLib.IDisposable)

--[[
	Events:
		CanCreateExecutionInstance (code, sourceId, instanceOptions)
			Fired when an execution instance is about to be created.
		ExecutionInstanceCreated (IExecutionInstance executionInstance)
			Fired when an execution instance has been created.
			
]]

function self:ctor ()
end

function self:CanCreateExecutionInstance (code, sourceId, instanceOptions)
	GCompute.Error ("IExecutionContext:CanCreateExecutionInstance : Not implemented.")
end

function self:CreateExecutionInstance (code, sourceId, instanceOptions, callback)
	GCompute.Error ("IExecutionContext:CreateExecutionInstance : Not implemented.")
end

function self:GetHostId ()
	GCompute.Error ("IExecutionContext:GetHostId : Not implemented.")
end

function self:GetOwnerId ()
	GCompute.Error ("IExecutionContext:GetOwnerId : Not implemented.")
end

function self:GetLanguageName ()
	GCompute.Error ("IExecutionContext:GetLanguageName : Not implemented.")
end

function self:GetContextOptions ()
	GCompute.Error ("IExecutionContext:GetContextOptions : Not implemented.")
end

function self:HasContextOption (contextOption)
	return bit.band (self:GetContextOptions (), contextOption) == contextOption
end

function self:IsEasyContext ()
	return bit.band (self:GetContextOptions (), GCompute.Execution.ExecutionContextOptions.EasyContext) ~= 0
end

function self:IsReplContext ()
	return bit.band (self:GetContextOptions (), GCompute.Execution.ExecutionContextOptions.Repl) ~= 0
end