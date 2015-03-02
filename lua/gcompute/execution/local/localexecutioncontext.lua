local self = {}
GCompute.Execution.LocalExecutionContext = GCompute.MakeConstructor (self, GCompute.Execution.ExecutionContext)

local sv_allowcslua = GetConVar ("sv_allowcslua")

function self:ctor (ownerId, languageName, contextOptions)
	self.HostId         = GLib.GetLocalId ()
	self.OwnerId        = ownerId
	
	self.LanguageName   = languageName
	
	self.ContextOptions = contextOptions
end

function self:CanCreateExecutionInstance (code, sourceId, instanceOptions)
	-- CanCreateExecutionInstance event
	local allowed, denialReason = self:DispatchEvent ("CanCreateExecutionInstance", code, sourceId, instanceOptions)
	if allowed == false then return false, denialReason end
	
	-- sv_allowcslua
	if CLIENT and
	   self.OwnerId == GLib.GetLocalId () and
	   not LocalPlayer ():IsSuperAdmin () and
	   not sv_allowcslua:GetBool () then
		return false, GCompute.ReturnCode.AccessDenied
	end
	
	return true
end