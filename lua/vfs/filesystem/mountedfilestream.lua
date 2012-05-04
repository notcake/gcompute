local self = {}
VFS.MountedFileStream = VFS.MakeConstructor (self, VFS.IFileStream)

function self:ctor (mountedFile, fileStream)
	self.File = mountedFile
	self.DisplayPath = self.File:GetDisplayPath ()
	self.Path = self.File:GetPath ()
	self.FileStream = fileStream
end

function self:GetFile ()
	return self.File
end

function self:GetLength ()
	return self.FileStream:GetLength ()
end

function self:GetDisplayPath ()
	return self.DisplayPath
end

function self:GetPath ()
	return self.Path
end

function self:GetPos ()
	return self.FileStream:GetPos ()
end

function self:Read (size, callback)
	return self.FileStream:Read (size, callback)
end

function self:Seek (pos)
	self.FileStream:Seek (pos)
end