local self = {}
GCompute.Execution.LuadevExecutionService = GCompute.MakeConstructor (self, GCompute.Execution.IExecutionService)

function self:ctor ()
end

function self:CanCreateExecutionContext (authId, hostId, languageName)
	if languageName and languageName ~= "GLua"  then return false, GCompute.ReturnCode.NotSupported end
	if not self:IsAvailable () then return false, GCompute.ReturnCode.NoCarrier end
	
	local owner = GCompute.PlayerMonitor:GetUserEntity (authId)
	if owner and owner:IsValid () and not luadev.IsPlayerAllowed (owner, "") then return false, GCompute.ReturnCode.AccessDenied end
	
	return true
end

function self:CreateExecutionContext (authId, hostId, languageName, contextOptions, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	local allowed, denialReason = self:CanCreateExecutionContext (authId, hostId, languageName)
	if not allowed then return nil, denialReason end
	
	return GCompute.Execution.LuadevExecutionContext (authId, hostId, languageName, contextOptions)
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
	return luadev ~= nil
end

GCompute.Execution.LuadevExecutionService = GCompute.Execution.LuadevExecutionService ()