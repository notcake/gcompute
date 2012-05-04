local self = {}
VFS.RealFileStream = VFS.MakeConstructor (self, VFS.IFileStream)

function self:ctor (file)
	self.File = file
	self.DisplayPath = self.File:GetDisplayPath ()
	self.Path = self.File:GetPath ()
	self.Length = self.File:GetSize ()
	
	self.Contents = nil
end

function self:GetDisplayPath ()
	return self.DisplayPath
end

function self:GetFile ()
	return self.File
end

function self:GetLength ()
	return self.Length
end

function self:GetPath ()
	return self.Path
end

function self:Read (size, callback)
	self.Contents = self.Contents or file.Read (self.Path, true) or ""
	local startPos = self:GetPos ()
	self:Seek (startPos + size)
	callback (VFS.ReturnCode.None, self.Contents:sub (startPos, startPos + size - 1))
end