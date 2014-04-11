local self = {}
GCompute.Execution.LuadevExecutionContext = GCompute.MakeConstructor (self, GCompute.Execution.ExecutionContext)

function self:ctor (ownerId, hostId, languageName, contextOptions)
	self.HostId  = hostId
	self.OwnerId = ownerId
	
	self.ContextOptions = contextOptions
end

-- Internal, do not call
function self:CanCreateExecutionInstance ()
	local hostId = self:GetHostId ()
	
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