local self = {}
GCompute.Execution.LuadevExecutionService = GCompute.MakeConstructor (self, GCompute.Execution.IExecutionService)

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
	if languageName and languageName ~= "GLua" then return false, GCompute.ReturnCode.NotSupported end
	if not self:IsAvailable ()                 then return false, GCompute.ReturnCode.NoCarrier    end
	
	-- Check luadev permissions
	local owner = GCompute.PlayerMonitor:GetUserEntity (authId)
	if owner and owner:IsValid () and not luadev.IsPlayerAllowed (owner, "") then
		return false, GCompute.ReturnCode.AccessDenied
	end
	
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
	
	-- Create the execution context
	local executionContext = GCompute.Execution.LuadevExecutionContext (authId, hostId, languageName, contextOptions)
	
	-- ExecutionContextCreated event
	self:DispatchEvent ("ExecutionContextCreated", executionContext)
	
	return executionContext
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