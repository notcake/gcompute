local self = {}
VFS.Protocol.Register ("FolderListing", self)
VFS.Protocol.FolderListingRequest = VFS.MakeConstructor (self, VFS.Protocol.Request)

function self:ctor (folder)
	self.Folder = folder
	self.Path = folder:GetPath ()
	
	local outBuffer = VFS.Net.OutBuffer ()
	outBuffer:String (self.Path)
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.Path)
end

function self:HandleResponse (inBuffer)
	local returnCode = inBuffer:UInt8 ()
	if returnCode == VFS.ReturnCode.None then
		local nodeType = inBuffer:UInt8 ()
		local name = inBuffer:String ()
		local displayName = inBuffer:String ()
		if displayName == "" then displayName = nil end
		self:DispatchEvent ("ReceivedNodeInfo", nodeType, name, displayName)
		self:DispatchEvent ("RunCallback", VFS.ReturnCode.EndOfBurst)
		ErrorNoHalt ("Received node " .. name .. "\n")
	elseif returnCode == VFS.ReturnCode.AccessDenied then
		self:DispatchEvent ("RunCallback", VFS.ReturnCode.AccessDenied)
		self:Close ()
	elseif returnCode == VFS.ReturnCode.Finished then
		self:DispatchEvent ("RunCallback", VFS.ReturnCode.Finished)
		self:Close ()
	end
end