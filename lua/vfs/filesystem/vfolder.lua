local self = {}
VFS.VFolder = VFS.MakeConstructor (self, VFS.IFolder, VFS.VNode)

function self:ctor (name, parentFolder)	
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
		callback (VFS.ReturnCode.Success, folder)
	else
		folder:CreateFolder (authId, path, callback)
	end
end

function self:DeleteDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback

	if not self.Children [name] then
		callback (VFS.ReturnCode.Success)
		return
	end
	
	self.Children [name] = nil
	callback (VFS.ReturnCode.Success)
end

function self:EnumerateChildren (authId, callback)
	for _, node in pairs (self.Children) do
		callback (VFS.ReturnCode.Success, node)
	end
	callback (VFS.ReturnCode.Finished)
end

function self:GetDirectChild (authId, name, callback)
	if self.Children [name] then
		callback (VFS.ReturnCode.Success, self.Children [name])
	else
		callback (VFS.ReturnCode.NotFound)
	end
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