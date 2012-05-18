local self = {}
VFS.Protocol.NodeUpdateNotification = VFS.MakeConstructor (self, VFS.Protocol.Session)
VFS.Protocol.RegisterNotification ("NodeUpdateNotification", VFS.Protocol.NodeUpdateNotification)

function self:ctor (node, updateFlags)
	self.Node = node
	self.Path = self.Node and self.Node:GetPath ()
	self.UpdateFlags = updateFlags
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.Path)
	outBuffer:UInt8 (self.UpdateFlags)
	if self.UpdateFlags & VFS.UpdateFlags.DisplayName then
		outBuffer:String (self.Node:GetDisplayName () or "")
	end
	if self.UpdateFlags & VFS.UpdateFlags.Size then
		local size = self.Node:IsFile () and self.Node:GetSize ()
		if size == -1 then size = 0xFFFFFFFF end
		outBuffer:UInt32 (size)
	end
	if self.UpdateFlags & VFS.UpdateFlags.ModificationTime then
		local modificationTime = self.Node:GetModificationTime ()
		if modificationTime == -1 then modificationTime = 0xFFFFFFFF end
		outBuffer:UInt32 (modificationTime)
	end
end

function self:HandleInitialPacket (inBuffer)
	self.Path = inBuffer:String ()
	self.UpdateFlags = inBuffer:UInt8 ()
	
	local node = self:GetRemoteEndPoint ():GetRoot ():GetChildSynchronous (self.Path)
	if not node then return end
	if not node:IsNetNode () then return end
	
	if self.UpdateFlags & VFS.UpdateFlags.DisplayName then
		local displayName = inBuffer:String ()
		if displayName == "" then displayName = nil end
		node:SetDisplayName (displayName)
	end
	
	if self.UpdateFlags & VFS.UpdateFlags.Size then
		local size = inBuffer:UInt32 ()
		if size == 0xFFFFFFFF then size = -1 end
		if node:IsFile () then node:SetSize (size) end
	end
	
	if self.UpdateFlags & VFS.UpdateFlags.ModificationTime then
		local modificationTime = inBuffer:UInt32 ()
		if modificationTime == 0xFFFFFFFF then modificationTime = -1 end
		node:SetModificationTime (modificationTime)
	end
end