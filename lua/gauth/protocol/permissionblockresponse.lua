local self = {}
GAuth.Protocol.RegisterResponse ("PermissionBlock", GAuth.MakeConstructor (self, GAuth.Protocol.Session))

function self:ctor (permissionBlock)
	self.PermissionBlock = permissionBlock
end

function self:DequeuePacket ()
	local outBuffer = self.Session:DequeuePacket ()
	if outBuffer then
		self:ResetTimeout ()
	end
	return outBuffer
end

function self:HandleInitialPacket (inBuffer)
	local typeId = inBuffer:UInt32 ()
	local packetType = GAuth.Protocol.StringTable:StringFromHash (typeId)
	
	local ctor = GAuth.Protocol.ResponseTable [packetType]
	if not ctor then
		ErrorNoHalt ("PermissionBlockResponse:HandleInitialPacket : No handler for " .. tostring (packetType) .. " is registered!")
		return
	end
	self.Session = ctor (self.PermissionBlock)
	self.Session:SetRemoteEndPoint (self:GetRemoteEndPoint ())
	self.Session:HandleInitialPacket (inBuffer)
end

function self:HandlePacket (inBuffer)
	self.Session:HandlePacket (inBuffer)
end

function self:HandleTimeOut ()
	self.Session:HandleTimeOut ()
end

function self:HasQueuedPackets ()
	return self.Session:HasQueuedPackets ()
end

function self:ResetTimeout ()
	self.Session:ResetTimeout ()
end

function self:ToString ()
	return self.Session and self.Session:ToString () or "none"
end