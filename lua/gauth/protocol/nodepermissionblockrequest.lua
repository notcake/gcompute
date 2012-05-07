local self = {}
GAuth.Protocol.Register ("NodePermissionBlock", self)
GAuth.Protocol.NodePermissionBlockRequest = GAuth.MakeConstructor (self, GAuth.Protocol.Session)

function self:ctor (groupTreeNode, request)
	self.GroupId = groupTreeNode and groupTreeNode:GetFullName ()
	self.Session = request
end

function self:Close ()
	if self.Session then self.Session:Close () return end
	if self.Closing then return end
	self.Closing = true
end

function self:DequeuePacket ()
	local outBuffer = self.Session:DequeuePacket ()
	if outBuffer then
		self:ResetTimeout ()
	end
	return outBuffer
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.GroupId)
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

function self:IsClosing ()
	return self.Closing or self.Session:IsClosing ()
end

function self:ResetTimeout ()
	self.Session:ResetTimeout ()
end

function self:ToString ()
	return self:GetType () .. ":" .. self:GetId () .. " {" .. (self.Session and self.Session:ToString () or "none") .. "}"
end