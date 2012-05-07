local self = {}
GAuth.Protocol.PermissionBlockNotification = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlockNotification", GAuth.Protocol.PermissionBlockNotification)

function self:ctor (permissionBlock, permissionBlockNotification)
	self.PermissionBlock = permissionBlock
	self.Session = permissionBlockNotification
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:UInt32 (self.Session:GetTypeId ())
	self.Session:GenerateInitialPacket (outBuffer)
end

function self:HandleInitialPacket (inBuffer)
	local typeId = inBuffer:UInt32 ()
	local packetType = GAuth.Protocol.StringTable:StringFromHash (typeId)
	
	local ctor = GAuth.Protocol.ResponseTable [packetType]
	if not ctor then
		ErrorNoHalt ("PermissionBlockNotification:HandleInitialPacket : No handler for " .. tostring (packetType) .. " is registered!")
		return
	end
	self.Session = ctor (self.PermissionBlock)
	self.Session:SetRemoteEndPoint (self:GetRemoteEndPoint ())
	self.Session:HandleInitialPacket (inBuffer)
end

function self:ToString ()
	return self.Session and self.Session:ToString () or "none"
end