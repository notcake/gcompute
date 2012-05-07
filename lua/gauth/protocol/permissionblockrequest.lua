local self = {}
GAuth.Protocol.Register ("PermissionBlock", self)
GAuth.Protocol.PermissionBlockRequest = GAuth.MakeConstructor (self, GAuth.Protocol.Session)

function self:ctor (permissionBlock, request)
	self.PermissionBlock = permissionBlock
	self.Session = request
end

function self:DequeuePacket ()
	local outBuffer = self.Session:DequeuePacket ()
	if outBuffer then
		self:ResetTimeout ()
	end
	return outBuffer
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:UInt32 (self.Session:GetTypeId ())
	self.Session:GenerateInitialPacket (outBuffer)
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