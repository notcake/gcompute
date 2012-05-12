local self = {}
VFS.Protocol.Register ("FolderListing", self)
VFS.Protocol.FolderListingRequest = VFS.MakeConstructor (self, VFS.Protocol.Session)

function self:ctor (folder)
	self.Folder = folder
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.Folder:GetPath ())
end

function self:HandlePacket (inBuffer)
	local returnCode = inBuffer:UInt8 ()
	if returnCode == VFS.ReturnCode.Success then
		self:DispatchEvent ("ReceivedNodeInfo", inBuffer)
		self:DispatchEvent ("RunCallback", VFS.ReturnCode.EndOfBurst)
	elseif returnCode == VFS.ReturnCode.AccessDenied then
		self:DispatchEvent ("RunCallback", VFS.ReturnCode.AccessDenied)
	elseif returnCode == VFS.ReturnCode.Finished then
		self:DispatchEvent ("RunCallback", VFS.ReturnCode.Finished)
		self:Close ()
	end
end