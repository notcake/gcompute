local self = {}
VFS.Protocol.Register ("FileOpen", self)
VFS.Protocol.FileOpenRequest = VFS.MakeConstructor (self, VFS.Protocol.Session)

VFS.Protocol.FileStreamAction =
{
	Close   = 0,
	Read    = 1,
	Write   = 2
}

function self:ctor (file, openFlags, callback)
	self.Callback = callback or VFS.NullCallback
	self.File = file
	self.OpenFlags = openFlags
	self.FileStream = nil
	
	self.NextSubRequestId = 0
	self.SubRequestCallbacks = {}
	self.SubRequestTypes = {}
end

function self:CloseStream ()
	self.SubRequestCallbacks [self.NextSubRequestId] = VFS.NullCallback
	self.SubRequestTypes [self.NextSubRequestId] = VFS.Protocol.FileStreamAction.Close
	
	local outBuffer = self:CreatePacket ()
	outBuffer:UInt32 (self.NextSubRequestId)
	outBuffer:UInt8 (VFS.Protocol.FileStreamAction.Close)
	self:QueuePacket (outBuffer)
	
	self.NextSubRequestId = self.NextSubRequestId + 1
	self:Close ()
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.File:GetPath ())
	outBuffer:UInt8 (self.OpenFlags)
end

function self:HandlePacket (inBuffer)
	if not self.FileStream then
		local returnCode = inBuffer:UInt8 ()
		if returnCode == VFS.ReturnCode.Success then
			local length = inBuffer:UInt32 ()
			self.FileStream = VFS.NetFileStream (self, self.File, length)
			self.Callback (returnCode, self.FileStream)
			ErrorNoHalt ("Opened netfile " .. self.File:GetPath () .. "\n")

			function self:HasTimedOut ()
				return false
			end
		else
			self.Callback (returnCode)
			self:Close ()
		end
	else
		local subRequestId = inBuffer:UInt32 ()
		local returnCode = inBuffer:UInt8 ()
		local callback = self.SubRequestCallbacks [subRequestId]
		local subRequestType = self.SubRequestTypes [subRequestId]
		self.SubRequestCallbacks [subRequestId] = nil
		self.SubRequestTypes [subRequestId] = nil
		if not subRequestType then return end
		if subRequestType == VFS.Protocol.FileStreamAction.Read then
			local data = inBuffer:String ()
			callback (returnCode, data)
		else
			callback (returnCode)
		end
	end
end

function self:Read (pos, size, callback)
	self.SubRequestCallbacks [self.NextSubRequestId] = callback
	self.SubRequestTypes [self.NextSubRequestId] = VFS.Protocol.FileStreamAction.Read
	
	local outBuffer = self:CreatePacket ()
	outBuffer:UInt32 (self.NextSubRequestId)
	outBuffer:UInt8 (VFS.Protocol.FileStreamAction.Read)
	outBuffer:UInt32 (pos)
	outBuffer:UInt32 (size)
	self:QueuePacket (outBuffer)
	
	self.NextSubRequestId = self.NextSubRequestId + 1
end