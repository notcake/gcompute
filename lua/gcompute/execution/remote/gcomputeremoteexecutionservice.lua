local self = {}
GCompute.Execution.GComputeRemoteExecutionService = GCompute.MakeConstructor (self, GCompute.Execution.IExecutionService)

function self:ctor ()
end

function self:CanCreateExecutionContext (authId, hostId, languageName)
	if not self:IsAvailable () then return false, GCompute.ReturnCode.NoCarrier end
	
	return true
end

function self:CreateExecutionContext (authId, hostId, languageName, contextOptions, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	local allowed, denialReason = self:CanCreateExecutionContext (authId, hostId, languageName)
	if not allowed then return nil, denialReason end
	
	if CLIENT then
		local executionService, returnCode = GCompute.Services.RemoteServiceManagerManager:GetRemoteService (GLib.GetServerId (), "ExecutionService")
		if not executionService then
			return nil, returnCode
		end
		
		return executionService:CreateExecutionContext (authId, hostId, languageName, contextOptions, callback)
	elseif SERVER then
		if istable (hostId) then
			GCompute.Error ("GComputeRemoteExecutionService:CreateExecutionContext : Aggregate execution contexts are not supported!")
			return nil, GCompute.ReturnCode.NotSupported
		end
		
		local executionService, returnCode = GCompute.Services.RemoteServiceManagerManager:GetRemoteService (hostId, "ExecutionService")
		if not executionService then
			return nil, returnCode
		end
		
		return executionService:CreateExecutionContext (authId, hostId, languageName, contextOptions, callback)
	end
	
	return nil, GCompute.ReturnCode.NotSupported
end

local clientTargets =
{
	"Server",
	"Clients",
	"Shared"
}

local serverTargets =
{
	"Clients",
	"Shared"
}

function self:GetHostEnumerator ()
	return GLib.Enumerator.Join (
		GLib.Enumerator.ArrayEnumerator (SERVER and serverTargets or clientTargets),
		GCompute.PlayerMonitor:GetUserEnumerator ()
	)
end

function self:GetLanguageEnumerator ()
	return GCompute.Execution.LocalExecutionService:GetLanguageEnumerator ()
end

function self:IsAvailable ()
	return GCompute.Services.RemoteServiceManagerManager:IsAvailable ()
end

GCompute.Execution.GComputeRemoteExecutionService = GCompute.Execution.GComputeRemoteExecutionService ()