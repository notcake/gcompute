local self = {}
VFS.VFile = VFS.MakeConstructor (self, VFS.IFile)

function self:ctor (name, parentFolder)
	self.Name = name
	self.DisplayName = self.Name
	self.ParentFolder = parentFolder
	
	self.OwnerId = GAuth.GetSystemId ()
end

function self:GetDisplayName ()
	return self.DisplayName
end

function self:GetName ()
	return self.Name
end

function self:GetParentFolder ()
	return self.ParentFolder
end

function self:GetOwner ()
	return self.OwnerId
end

function self:SetDisplayName (displayName)
	self.DisplayName = displayName
end

function self:SetOwner (authId, ownerId, callback)
	callback = callback or VFS.NullCallback
	self.Owner = ownerId
	callback (VFS.ReturnCode.None)
end