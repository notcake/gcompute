local self = {}
GCompute.Execution.GComputeRemoteExecutionService = GCompute.MakeConstructor (self, GCompute.Execution.IExecutionService)

--[[
	Events:
		CanCreateExecutionContext (authId, hostId, languageName)
			Fired when an execution context is about to be created.
		ExecutionContextCreated (IExecutionContext executionContext)
			Fired when an execution context has been created.
			
]]

function self:ctor ()
	GCompute.EventProvider (self)
end

function self:CanCreateExecutionContext (authId, hostId, languageName)
	if not self:IsAvailable () then return false, GCompute.ReturnCode.NoCarrier end
	
	-- CanCreateExecutionContext event
	local allowed, denialReason = self:DispatchEvent ("CanCreateExecutionContext", authId, hostId, languageName)
	if allowed == false then return false, denialReason end
	
	return true
end

function self:CreateExecutionContext (authId, hostId, languageName, contextOptions, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	-- Check if creation is allowed
	local allowed, denialReason = self:CanCreateExecutionContext (authId, hostId, languageName)
	if not allowed then return nil, denialReason end
	
	-- Get the execution service
	local executionService, returnCode
	
	if CLIENT then
		executionService, returnCode = GCompute.Services.RemoteServiceManagerManager:GetRemoteService (GLib.GetServerId (), "ExecutionService")
	elseif SERVER then
		-- We shouldn't ever get an aggregate host ID at this layer on the server.
		if istable (hostId) then
			GCompute.Error ("GComputeRemoteExecutionService:CreateExecutionContext : Aggregate execution contexts are not supported!")
			return nil, GCompute.ReturnCode.NotSupported
		end
		
		executionService, returnCode = GCompute.Services.RemoteServiceManagerManager:GetRemoteService (hostId, "ExecutionService")
	else
		return nil, GCompute.ReturnCode.NotSupported
	end
	
	-- Create the execution context
	if not executionService then return nil, returnCode end
	local executionContext, denialReason = executionService:CreateExecutionContext (authId, hostId, languageName, contextOptions, callback)
	
	-- ExecutionContextCreated event
	if executionContext then
		self:DispatchEvent ("ExecutionContextCreated", executionContext)
	end
	
	return executionContext, denialReason
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