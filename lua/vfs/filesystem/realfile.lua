local self = {}
VFS.RealFile = VFS.MakeConstructor (self, VFS.IFile, VFS.RealNode)

function self:ctor (path, name, parentFolder)
end

function self:GetSize ()
	return (file.Read (self.Path, true) or ""):len ()
end

function self:Open (authId, openFlags, callback)
	callback (VFS.ReturnCode.Success, VFS.RealFileStream (self))
end