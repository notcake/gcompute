local self = {}
VFS.VFolder = VFS.MakeConstructor (self, VFS.IFolder, VFS.VNode)

function self:ctor (name, parentFolder)	
	self.Children = {}
end

function self:CreateDirectNode (authId, name, isFolder, callback)
	callback = callback or VFS.NullCallback

	if self.Children [name] then
		if self.Children [name]:IsFolder () == isFolder then callback (VFS.ReturnCode.Success, self.Children [name])
		elseif isFolder then callback (VFS.ReturnCode.NotAFolder)
		else callback (VFS.ReturnCode.NotAFile) end
		return
	end
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, "Create " .. (isFolder and "Folder" or "File")) then callback (VFS.ReturnCode.AccessDenied) return end
	
	self.Children [name] = (isFolder and VFS.VFolder or VFS.VFile) (name, self)
	self:DispatchEvent ("NodeCreated", self.Children [name])
	
	callback (VFS.ReturnCode.Success, self.Children [name])
end

function self:DeleteDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	local node = self.Children [name]
	if not node then callback (VFS.ReturnCode.Success) return end
	if not node:GetPermissionBlock ():IsAuthorized (authId, "Delete") then callback (VFS.ReturnCode.AccessDenied) return end
	
	self.Children [name] = nil
	self:DispatchEvent ("NodeDeleted", node)
	node:DispatchEvent ("Deleted")
	
	callback (VFS.ReturnCode.Success)
end

function self:EnumerateChildren (authId, callback)
	callback = callback or VFS.NullCallback
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, "View Folder") then callback (VFS.ReturnCode.AccessDenied) return end
	
	for _, node in pairs (self.Children) do
		callback (VFS.ReturnCode.Success, node)
	end
	callback (VFS.ReturnCode.Finished)
end

function self:GetDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, "View Folder") then callback (VFS.ReturnCode.AccessDenied) return end
	
	if self.Children [name] then
		callback (VFS.ReturnCode.Success, self.Children [name])
	else
		callback (VFS.ReturnCode.NotFound)
	end
end

function self:GetDirectChildSynchronous (name)
	return self.Children [name]
end

function self:Mount (name, node, displayName)
	if not node then return end
	
	if node:IsFolder () then
		self.Children [name] = VFS.MountedFolder (name, node, self)
	else
		self.Children [name] = VFS.MountedFile (name, node, self)
	end
	self.Children [name]:SetDisplayName (displayName)
	self:DispatchEvent ("NodeCreated", self.Children [name])
	
	return self.Children [name]
end

function self:RenameChild (authId, name, newName, callback)
	callback = callback or VFS.NullCallback
	
	local node = self.Children [name]
	if not node then callback (VFS.ReturnCode.NotFound) return end
	
	if not node:GetPermissionBlock ():IsAuthorized (authId, "Rename") then callback (VFS.ReturnCode.AccessDenied) return end
	
	if self.Children [newName] then callback (VFS.ReturnCode.AlreadyExists) return end
	self.Children [newName] = self.Children [name]
	self.Children [name] = nil
	node:Rename (authId, newName)
	self:DispatchEvent ("NodeRenamed", node, name, newName)
end

function self:UnhookPermissionBlock ()
	VFS.PermissionBlockNetworker:UnhookBlock (self:GetPermissionBlock ())
	for _, node in pairs (self.Children) do
		node:UnhookPermissionBlock ()
	end
end