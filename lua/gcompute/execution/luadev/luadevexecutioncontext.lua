local self = {}
GCompute.Execution.LuadevExecutionContext = GCompute.MakeConstructor (self, GCompute.Execution.ExecutionContext)

--[[
	Events:
		CanCreateExecutionInstance (code, sourceId, instanceOptions)
			Fired when an execution instance is about to be created.
		ExecutionInstanceCreated (IExecutionInstance executionInstance)
			Fired when an execution instance has been created.
			
]]

function self:ctor (ownerId, hostId, languageName, contextOptions)
	self.HostId         = hostId
	self.OwnerId        = ownerId
	
	self.LanguageName   = languageName
	
	self.ContextOptions = contextOptions
end

-- Internal, do not call
function self:CanCreateExecutionInstance (code, sourceId, instanceOptions)
	local hostId = self:GetHostId ()
	
	-- CanCreateExecutionInstance event
	local allowed, denialReason = self:DispatchEvent ("CanCreateExecutionInstance", code, sourceId, instanceOptions)
	if allowed == false then return false, denialReason end
	
	if istable (hostId)    then return true end
	if hostId == "Server"  then return true end
	if hostId == "Clients" then return true end
	if hostId == "Shared"  then return true end
	
	local host = GCompute.PlayerMonitor:GetUserEntity (hostId)
	if host and host:IsValid () then return true end
	
	return false, GCompute.ReturnCode.NoCarrier
end

function self:GetExecutionInstanceConstructor  ()
	return GCompute.Execution.LuadevExecutionInstance
end