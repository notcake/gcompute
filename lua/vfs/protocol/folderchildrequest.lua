local self = {}
VFS.Protocol.Register ("FolderChild", self)
VFS.Protocol.FolderChildRequest = VFS.MakeConstructor (self, VFS.Protocol.Session)

function self:ctor (folder, childName, callback)
	self.Callback = callback or VFS.NullCallback
	self.Folder = folder
	self.ChildName = childName
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.Folder:GetPath ())
	outBuffer:String (self.ChildName)
end

function self:HandlePacket (inBuffer)
	local returnCode = inBuffer:UInt8 ()
	if returnCode == VFS.ReturnCode.Success then
		local nodeType = inBuffer:UInt8 ()
		local name = inBuffer:String ()
		local displayName = inBuffer:String ()
		if displayName == "" then displayName = nil end
		ErrorNoHalt ("RECV " .. name .. "\n")
		self.Callback (returnCode, nodeType, name, displayName, inBuffer)
	else
		self.Callback (returnCode)
	end
	self:Close ()
end