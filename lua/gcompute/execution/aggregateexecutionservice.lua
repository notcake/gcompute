local self = {}
GCompute.Execution.AggregateExecutionService = GCompute.MakeConstructor (self, GCompute.Execution.IExecutionService)

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
	if hostId == "Self" then hostId = GLib.GetLocalId () end
	
	local allowed, denialReason
	if type (hostId) == "table" then
		-- Aggregate execution
		for _, hostId in ipairs (hostId) do
			allowed, denialReason = self:CanCreateExecutionContext (authId, hostId, languageName)
			if not allowed then return false, denialReason end
		end
	elseif hostId == "Shared" then
		-- Shared
		allowed, denialReason = self:CanCreateExecutionContext (authId, GLib.GetServerId (), languageName)
		if not allowed then return false, denialReason end
		
		allowed, denialReason = self:CanCreateExecutionContext (authId, "Clients", languageName)
		if not allowed then return false, denialReason end
	elseif hostId == "Clients" then
		-- Clients
		for hostId in GCompute.PlayerMonitor:GetUserEnumerator () do
			allowed, denialReason = self:CanCreateExecutionContext (authId, hostId, languageName)
			if not allowed then return false, denialReason end
		end
	elseif hostId == GLib.GetLocalId () then
		-- Local host
		allowed, denialReason = GCompute.Execution.LocalExecutionService:CanCreateExecutionContext (authId, hostId, languageName)
		if not allowed then return false, denialReason end
	else
		-- Remote host
		allowed, denialReason = GCompute.Execution.RemoteExecutionService:CanCreateExecutionContext (authId, hostId, languageName)
		if not allowed then return false, denialReason end
	end
	
	-- CanCreateExecutionContext event
	allowed, denialReason = self:DispatchEvent ("CanCreateExecutionContext", authId, hostId, languageName)
	if allowed == false then return false, denialReason end
	
	return true
end

function self:CreateExecutionContext (authId, hostId, languageName, contextOptions, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	-- Check if creation is allowed
	local allowed, denialReason = self:CanCreateExecutionContext (authId, hostId, languageName)
	if not allowed then return nil, denialReason end
	
	-- Create the execution context
	local executionContext
	
	if hostId == "Self" then hostId = GLib.GetLocalId () end
	
	if type (hostId) == "table" or
	   hostId == "Clients" or
	   hostId == "Shared" then
		-- Aggregate execution
		executionContext = GCompute.Execution.AggregateExecutionContext (authId, hostId, languageName, contextOptions)
	elseif hostId == GLib.GetLocalId () then
		-- Local host
		executionContext, denialReason = GCompute.Execution.LocalExecutionService:CreateExecutionContext (authId, hostId, languageName, contextOptions)
	else
		-- Remote host
		executionContext, denialReason = GCompute.Execution.RemoteExecutionService:CreateExecutionContext (authId, hostId, languageName, contextOptions)
	end
	
	-- ExecutionContextCreated event
	if executionContext then
		self:DispatchEvent ("ExecutionContextCreated", executionContext)
	end
	
	return executionContext, denialReason
end

local targets =
{
	"Self",
	"Server",
	"Clients",
	"Shared"
}
function self:GetHostEnumerator ()
	return GLib.Enumerator.Join (
		GLib.Enumerator.ArrayEnumerator (targets),
		GCompute.PlayerMonitor:GetUserEnumerator ()
	)
end

function self:GetLanguageEnumerator ()
	return GCompute.Execution.LocalExecutionService:GetLanguageEnumerator ()
end

GCompute.Execution.AggregateExecutionService = GCompute.Execution.AggregateExecutionService ()