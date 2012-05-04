local self = {}
VFS.RealFile = VFS.MakeConstructor (self, VFS.IFile)

function self:ctor (path, name, parentFolder)
	self.Name = name
	self.ParentFolder = parentFolder
	self.Path = path
end

function self:GetSize ()
	return (file.Read (self.Path, true) or ""):len ()
end

function self:GetName ()
	return self.Name
end

function self:GetParentFolder ()
	return self.ParentFolder
end

function self:Open (authId, openFlags, callback)
	callback (VFS.ReturnCode.None, VFS.RealFileStream (self))
end