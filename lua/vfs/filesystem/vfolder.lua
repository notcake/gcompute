local self = {}
VFS.VFolder = VFS.MakeConstructor (self, VFS.IFolder)

function self:ctor (name, parentFolder)
	self.Name = name
	self.DisplayName = self.Name
	self.ParentFolder = parentFolder
	
	self.OwnerId = GAuth.GetSystemId ()
	
	self.Children = {}
end

function self:CreateFolder (authId, path, callback)
	callback = callback or VFS.NullCallback

	local path = VFS.Path (path)
	local folder = nil
	if self.Children [path:GetSegment (0)] then
		folder = self.Children [path:GetSegment (0)]
	else
		folder = VFS.VFolder (path:GetSegment (0), self)
		self.Children [path:GetSegment (0)] = folder
	end
	
	path:RemoveFirstSegment ()
	
	if path:IsEmpty () then
		callback (VFS.ReturnCode.None, folder)
	else
		folder:CreateFolder (authId, path, callback)
	end
end

function self:DeleteDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback

	if not self.Children [name] then
		callback (VFS.ReturnCode.None)
		return
	end
	
	self.Children [name] = nil
	callback (VFS.ReturnCode.None)
end

function self:EnumerateChildren (authId, callback)
	for _, node in pairs (self.Children) do
		callback (VFS.ReturnCode.None, node)
	end
	callback (VFS.ReturnCode.Finished)
end

function self:GetDirectChild (authId, name, callback)
	if self.Children [name] then
		callback (VFS.ReturnCode.None, self.Children [name])
	else
		callback (VFS.ReturnCode.NotFound)
	end
end

function self:GetDisplayName ()
	return self.DisplayName
end

function self:GetName ()
	return self.Name
end

function self:GetOwner ()
	return self.OwnerId
end

function self:GetParentFolder ()
	return self.ParentFolder
end

function self:Mount (name, node, displayName)
	if not node then return end
	
	if node:IsFolder () then
		self.Children [name] = VFS.MountedFolder (name, node, self)
		self.Children [name]:SetDisplayName (displayName)
	else
		self.Children [name] = VFS.MountedFile (name, node, self)
		self.Children [name]:SetDisplayName (displayName)
	end
end

function self:SetDisplayName (displayName)
	self.DisplayName = displayName
end

function self:SetOwner (authId, ownerId, callback)
	callback = callback or VFS.NullCallback
	self.Owner = ownerId
	callback (VFS.ReturnCode.None)
end