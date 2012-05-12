local self = {}
VFS.RealFile = VFS.MakeConstructor (self, VFS.IFile, VFS.RealNode)

function self:ctor (path, name, parentFolder)
end

function self:GetSize ()
	if self:GetPath ():lower ():sub (1, 5) == "data/" then
		return file.Size (self:GetPath ():sub (6))
	end
	return -1
end

function self:Open (authId, openFlags, callback)
	callback (VFS.ReturnCode.Success, VFS.RealFileStream (self, openFlags))
end