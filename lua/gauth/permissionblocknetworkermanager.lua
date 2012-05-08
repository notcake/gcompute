local self = {}
GAuth.PermissionBlockNetworkerManager = GAuth.MakeConstructor (self)

function self:ctor ()
	self.StringTable = GAuth.Net.StringTable ()
	self.SystemNetworkers = {}
end

function self:GetNetworker (systemId)
	local systemName = self.StringTable:StringFromHash (systemId)
	local networker = self.SystemNetworkers [systemName]
	if not networker then
		GAuth.Error ("PermissionBlockNetworkerManager:GetNetworker : " .. tostring (systemId) .. " not found.")
	end
	return networker
end

function self:GetSystemId (systemName)
	return self.StringTable:HashFromString (systemName)
end

function self:Register (permissionBlockNetworker)
	self.StringTable:Add (permissionBlockNetworker:GetSystemName ())
	self.SystemNetworkers [permissionBlockNetworker:GetSystemName ()] = permissionBlockNetworker
end

GAuth.PermissionBlockNetworkerManager = GAuth.PermissionBlockNetworkerManager ()