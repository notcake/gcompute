local self = {}
VFS.RealNode = VFS.MakeConstructor (self, VFS.INode)

function self:ctor (path, name, parentFolder)
	self.Name = name
	self.ParentFolder = parentFolder
	self.Path = path
end

function self:GetName ()
	return self.Name
end

function self:GetParentFolder ()
	return self.ParentFolder
end

function self:GetPermissionBlock ()
	return nil
end