local self = {}
GCompute.Execution.ExecutionContext = GCompute.MakeConstructor (self, GCompute.Execution.IExecutionContext)

--[[
	Events:
		CanCreateExecutionInstance (code, sourceId, instanceOptions)
			Fired when an execution instance is about to be created.
		ExecutionInstanceCreated (IExecutionInstance executionInstance)
			Fired when an execution instance has been created.
			
]]

function self:ctor ()
	self.HostId         = nil
	self.OwnerId        = nil
	
	self.LanguageName   = nil
	
	self.ContextOptions = GCompute.Execution.ExecutionContextOptions.None
	
	self.NextInstanceId = 0
	
	GCompute.EventProvider (self)
end

function self:CanCreateExecutionInstance (code, sourceId, instanceOptions)
	-- CanCreateExecutionInstance event
	local allowed, denialReason = self:DispatchEvent ("CanCreateExecutionInstance", code, sourceId, instanceOptions)
	if allowed == false then return false, denialReason end
	
	return true
end

function self:CreateExecutionInstance (code, sourceId, instanceOptions, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	-- Check if creation is allowed
	local allowed, denialReason = self:CanCreateExecutionInstance (code, sourceId, instanceOptions)
	if not allowed then return false, denialReason end
	
	-- Create execution instance
	local executionInstance = self:GetExecutionInstanceConstructor () (self, instanceOptions)
	
	-- Add source file
	if not sourceId and self:IsReplContext () then
		sourceId = "@repl_" .. self:AllocateInstanceId ()
	end
	
	executionInstance:AddSourceFile (code, sourceId)
	
	-- ExecutionInstanceCreated event
	self:DispatchEvent ("ExecutionInstanceCreated", executionInstance)
	
	-- Execute
	if bit.band (instanceOptions, GCompute.Execution.ExecutionInstanceOptions.ExecuteImmediately) ~= 0 then
		executionInstance:Start ()
	end
	
	return executionInstance
end

function self:GetHostId ()
	return self.HostId
end

function self:GetOwnerId ()
	return self.OwnerId
end

function self:GetLanguageName ()
	return self.LanguageName
end

function self:GetContextOptions ()
	return self.ContextOptions
end

function self:SetHostId (hostId)
	self.HostId = hostId
end

function self:SetOwnerId (ownerId)
	self.OwnerId = ownerId
end

-- Internal, do not call
function self:AllocateInstanceId ()
	local instanceId = self.NextInstanceId
	self.NextInstanceId = self.NextInstanceId + 1
	return instanceId
end

function self:GetExecutionInstanceConstructor ()
	GCompute.Error ("ExecutionContext:GetExecutionInstanceConstructor : Not implemented.")
end

function self:SetExecutionInstanceConstructor (constructor)
	self.GetExecutionInstanceConstructor = function (self)
		return constructor
	end
end