local self = {}
GAuth.Protocol.NodePermissionBlockNotification = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("NodePermissionBlockNotification", GAuth.Protocol.NodePermissionBlockNotification)

function self:ctor (groupId, permissionBlockNotification)
	self.GroupId = groupId
	self.Session = permissionBlockNotification
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.GroupId)
	self.Session:GenerateInitialPacket (outBuffer)
end

function self:HandleInitialPacket (inBuffer)
	self.GroupId = inBuffer:String ()
	local typeId = inBuffer:UInt32 ()
	local packetType = GAuth.Protocol.StringTable:StringFromHash (typeId)
	
	local groupTreeNode = GAuth.ResolveGroupTreeNode (self.GroupId)
	if not groupTreeNode then return end
	if not self:ShouldProcessNotification (groupTreeNode) then return end
	
	local ctor = GAuth.Protocol.ResponseTable [packetType]
	if not ctor then
		ErrorNoHalt ("NodePermissionBlockNotification:HandleInitialPacket : No handler for " .. tostring (packetType) .. " is registered!")
		return
	end
	self.Session = ctor (groupTreeNode:GetPermissionBlock ())
	self.Session:SetRemoteEndPoint (self:GetRemoteEndPoint ())
	self.Session:HandleInitialPacket (inBuffer)
end

function self:ToString ()
	return self:GetType () .. " {" .. (self.Session and self.Session:ToString () or "none") .. "}"
end