local self = {}
VFS.MountedFolder = VFS.MakeConstructor (self, VFS.IFolder)

function self:ctor (nameOverride, mountedFolder, parentFolder)
	self.NameOverride = nameOverride
	self.DisplayNameOverride = nil
	self.MountedFolder = mountedFolder
	self.ParentFolder = parentFolder
	
	self.Children = {}
end

function self:EnumerateChildren (authId, callback)
	callback = callback or VFS.NullCallback
	
	self.MountedFolder:EnumerateChildren (authId,
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.None then
				if not self.Children [node:GetName ()] then
					if node:IsFolder () then
						self.Children [node:GetName ()] = VFS.MountedFolder (nil, node, self)
					else
						self.Children [node:GetName ()] = VFS.MountedFile (nil, node, self)
					end
				end
				callback (returnCode, self.Children [node:GetName ()])
			else
				callback (returnCode, node)
			end
		end
	)
end

function self:GetDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	self.MountedFolder:GetDirectChild (authId, name,
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.None then
				if not self.Children [node:GetName ()] then
					if node:IsFolder () then
						self.Children [node:GetName ()] = VFS.MountedFolder (nil, node, self)
					else
						self.Children [node:GetName ()] = VFS.MountedFile (nil, node, self)
					end
				end
				callback (returnCode, self.Children [node:GetName ()])
			else
				callback (returnCode, node)
			end
		end
	)
end

function self:GetDisplayName ()
	return self.DisplayNameOverride or self.MountedFolder:GetDisplayName ()
end

function self:GetName ()
	return self.NameOverride or self.MountedFolder:GetName ()
end

function self:GetParentFolder ()
	return self.ParentFolder
end

function self:SetDisplayName (displayName)
	self.DisplayNameOverride = displayName
end