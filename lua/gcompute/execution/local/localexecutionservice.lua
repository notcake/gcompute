local self = {}
GCompute.Execution.LocalExecutionService = GCompute.MakeConstructor (self, GCompute.Execution.IExecutionService)

--[[
	Events:
		CanCreateExecutionContext (authId, hostId, languageName)
			Fired when an execution context is about to be created.
		ExecutionContextCreated (IExecutionContext executionContext)
			Fired when an execution context has been created.
			
]]

local sv_allowcslua = GetConVar ("sv_allowcslua")

function self:ctor ()
	GCompute.EventProvider (self)
end

function self:CanCreateExecutionContext (authId, hostId, languageName)
	-- CanCreateExecutionContext event
	local allowed, denialReason = self:DispatchEvent ("CanCreateExecutionContext", authId, hostId, languageName)
	if allowed == false then return false, denialReason end
	
	-- Check permissions
	if authId ~= GLib.GetLocalId () and
	   authId ~= GLib.GetServerId () and
	   authId ~= GLib.GetSystemId () and
	   (not GCompute.PlayerMonitor:GetUserEntity (authId) or not GCompute.PlayerMonitor:GetUserEntity (authId):IsSuperAdmin ()) then
		return false, GCompute.ReturnCode.AccessDenied
	end
	
	-- Check host
	if hostId ~= GLib.GetLocalId () then
		return false, GCompute.ReturnCode.NotSupported
	end

	-- Check for server side only language
	if CLIENT and languageName and languageName == "SQLite" then
		return false, GCompute.ReturnCode.NotSupported
	end
	
	-- Check languages
	if languageName and
	   languageName ~= "Console" and
	   languageName ~= "Terminal Emulator" and
	   not GCompute.Languages.Get (languageName) then
		return false, GCompute.ReturnCode.NotSupported
	end
	
	-- sv_allowcslua
	if CLIENT and
	   authId == GLib.GetLocalId () and
	   not LocalPlayer ():IsSuperAdmin () and
	   not sv_allowcslua:GetBool () then
		return false, GCompute.ReturnCode.AccessDenied
	end
	
	return true
end

function self:CreateExecutionContext (authId, hostId, languageName, contextOptions, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	-- Check if creation is allowed
	local allowed, returnCode = self:CanCreateExecutionContext (authId, hostId, languageName)
	if not allowed then return nil, returnCode end
	
	-- Create the execution context
	local executionContext
	
	if languageName == "Console" then
		executionContext, returnCode = GCompute.Execution.ConsoleExecutionContext (authId, languageName, contextOptions), GCompute.ReturnCode.Success
	-- elseif languageName == "Terminal Emulator" then
	-- 	executionContext, returnCode = GCompute.Execution.TerminalEmulatorExecutionContext (authId, languageName, contextOptions), GCompute.ReturnCode.Success
	elseif languageName == "GLua" then
		executionContext, returnCode = GCompute.Execution.GLuaExecutionContext (authId, languageName, contextOptions), GCompute.ReturnCode.Success
	elseif languageName == "SQLite" then
		executionContext, returnCode = GCompute.Execution.SQLiteExecutionContext (authId, languageName, contextOptions), GCompute.ReturnCode.Success
	else
		returnCode = GCompute.ReturnCode.NotSupported
	end
	
	-- ExecutionContextCreated event
	if executionContext then
		self:DispatchEvent ("ExecutionContextCreated", executionContext)
	end
	
	return executionContext, returnCode
end

function self:GetHostEnumerator ()
	return GLib.SingleValueEnumerator (GLib.GetLocalId ())
end

local pseudoLanguages =
{
	"Console",
	"Terminal Emulator"
}
function self:GetLanguageEnumerator ()
	local languages = {}
	for language in GCompute.Languages:GetEnumerator () do
		languages [#languages + 1] = language:GetName ()
	end
	table.sort (languages)
	
	return GLib.Enumerator.Join (
		GLib.Enumerator.ArrayEnumerator (pseudoLanguages),
		GLib.Enumerator.ArrayEnumerator (languages)
	)
end

GCompute.Execution.LocalExecutionService = GCompute.Execution.LocalExecutionService ()