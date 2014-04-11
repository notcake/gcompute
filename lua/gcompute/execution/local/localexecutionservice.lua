local self = {}
GCompute.Execution.LocalExecutionService = GCompute.MakeConstructor (self, GCompute.Execution.IExecutionService)

function self:ctor ()
end

function self:CanCreateExecutionContext (authId, hostId, languageName)
	-- Check permissions
	if authId ~= GLib.GetLocalId () and
	   (not GCompute.PlayerMonitor:GetUserEntity (authId) or not GCompute.PlayerMonitor:GetUserEntity (authId):IsSuperAdmin ()) then
		return false, GCompute.ReturnCode.AccessDenied
	end
	
	-- Check host
	if hostId ~= GLib.GetLocalId () then
		return false, GCompute.ReturnCode.NotSupported
	end
	
	-- Check languages
	if languageName and
	   languageName ~= "Console" and
	   languageName ~= "Terminal Emulator" and
	   not GCompute.Languages.Get (languageName) then
		return false, GCompute.ReturnCode.NotSupported
	end
	
	return true
end

function self:CreateExecutionContext (authId, hostId, languageName, contextOptions, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	local allowed, denialReason = self:CanCreateExecutionContext (authId, hostId, languageName)
	if not allowed then return nil, denialReason end
	
	if languageName == "Console" then
		return GCompute.Execution.ConsoleExecutionContext (authId, contextOptions), GCompute.ReturnCode.Success
	-- elseif languageName == "Terminal Emulator" then
	-- 	return GCompute.Execution.TerminalEmulatorExecutionContext (authId, contextOptions), GCompute.ReturnCode.Success
	elseif languageName == "GLua" then
		return GCompute.Execution.GLuaExecutionContext (authId, contextOptions), GCompute.ReturnCode.Success
	end
	
	return nil, GCompute.ReturnCode.NotSupported
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