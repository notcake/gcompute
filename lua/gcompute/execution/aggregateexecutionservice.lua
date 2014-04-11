local self = {}
GCompute.Execution.AggregateExecutionService = GCompute.MakeConstructor (self, GCompute.Execution.IExecutionService)

function self:ctor ()
end

function self:CanCreateExecutionContext (authId, hostId, languageName)
	-- Aggregate execution
	if type (hostId) == "table" then
		for _, hostId in ipairs (hostId) do
			local allowed, denialReason = self:CanCreateExecutionContext (authId, hostId, languageName)
			if not allowed then return false, denialReason end
		end
		return true
	end
	
	-- Shared
	if hostId == "Shared" then
		local allowed, denialReason = self:CanCreateExecutionContext (authId, GLib.GetServerId (), languageName)
		if not allowed then return false, denialReason end
		hostId = "Clients"
	end
	
	-- Clients
	if hostId == "Clients" then
		for hostId in GCompute.PlayerMonitor:GetUserEnumerator () do
			local allowed, denialReason = self:CanCreateExecutionContext (authId, hostId, languageName)
			if not allowed then return false, denialReason end
		end
		return true
	end
	
	-- Local host
	if hostId == "Self" then hostId = GLib.GetLocalId () end
	if hostId == GLib.GetLocalId () then
		return GCompute.Execution.LocalExecutionService:CanCreateExecutionContext (authId, hostId, languageName)
	end
	
	-- Remote host
	return GCompute.Execution.RemoteExecutionService:CanCreateExecutionContext (authId, hostId, languageName)
end

function self:CreateExecutionContext (authId, hostId, languageName, contextOptions, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	local allowed, denialReason = self:CanCreateExecutionContext (authId, hostId, languageName)
	if not allowed then return nil, denialReason end
	
	-- Aggregate execution
	if type (hostId) == "table" or
	   hostId == "Clients" or
	   hostId == "Shared" then
		return GCompute.Execution.AggregateExecutionContext (authId, hostId, languageName, contextOptions)
	end
	
	-- Local host
	if hostId == "Self" then hostId = GLib.GetLocalId () end
	if hostId == GLib.GetLocalId () then
		return GCompute.Execution.LocalExecutionService:CreateExecutionContext (authId, hostId, languageName, contextOptions)
	end
	
	-- Remote host
	return GCompute.Execution.RemoteExecutionService:CreateExecutionContext (authId, hostId, languageName, contextOptions)
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