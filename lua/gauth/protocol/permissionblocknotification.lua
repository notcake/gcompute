local self = {}
GAuth.Protocol.PermissionBlockNotification = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlockNotification", GAuth.Protocol.PermissionBlockNotification)

function self:ctor (systemName, permissionBlock, permissionBlockNotification)
	self.SystemName = systemName
	self.PermissionBlock = permissionBlock
	self.Session = permissionBlockNotification
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:UInt32 (GAuth.PermissionBlockNetworkerManager:GetSystemId (self.SystemName))
	outBuffer:String (self.PermissionBlock:GetName ())
	outBuffer:UInt32 (self.Session:GetTypeId ())
	self.Session:GenerateInitialPacket (outBuffer)
end

function self:HandleInitialPacket (inBuffer)
	local systemId = inBuffer:UInt32 ()
	local permissionBlockId = inBuffer:String ()
	local networker = GAuth.PermissionBlockNetworkerManager:GetNetworker (systemId)
	self.Session = networker:HandleNotification (self:GetRemoteEndPoint (), permissionBlockId, inBuffer)
end

function self:ToString ()
	return self.SystemName .. ".PermissionBlock:" .. (self.Session and self.Session:ToString () or "none")
end