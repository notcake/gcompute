local self = {}
GCompute.Execution.ExecutionContext = GCompute.MakeConstructor (self, GCompute.Execution.IExecutionContext)

function self:ctor ()
	self.HostId  = nil
	self.OwnerId = nil
	
	self.ContextOptions = GCompute.Execution.ExecutionContextOptions.None
	
	self.NextInstanceId = 0
end

function self:CreateExecutionInstance (code, sourceId, instanceOptions, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	-- Check
	local allowed, denialReason = self:CanCreateExecutionInstance ()
	if not allowed then return false, denialReason end
	
	-- Create execution instance
	local executionInstance = self:GetExecutionInstanceConstructor () (self, instanceOptions)
	
	-- Add source file
	if not sourceId and self:IsReplContext () then
		sourceId = "@repl_" .. self:AllocateInstanceId ()
	end
	
	executionInstance:AddSourceFile (code, sourceId)
	
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

function self:CanCreateExecutionInstance ()
	return true
end

function self:GetExecutionInstanceConstructor ()
	GCompute.Error ("ExecutionContext:GetExecutionInstanceConstructor : Not implemented.")
end

function self:SetExecutionInstanceConstructor (constructor)
	self.GetExecutionInstanceConstructor = function (self)
		return constructor
	end
end