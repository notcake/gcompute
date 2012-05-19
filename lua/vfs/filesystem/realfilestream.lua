local self = {}
VFS.RealFileStream = VFS.MakeConstructor (self, VFS.IFileStream)

function self:ctor (realFile, openFlags)
	self.File = realFile
	self.OpenFlags = openFlags
	if self.OpenFlags & VFS.OpenFlags.Overwrite ~= 0 then
		self.Length = 0
		self.Contents = ""
	else
		self.Contents = file.Read (self:GetPath (), true) or ""
		self.Length = self.Contents:len ()
	end
	
	self.ContentsChanged = false
end

function self:CanWrite ()
	return self.OpenFlags & VFS.OpenFlags.Write ~= 0
end

function self:Close ()
	self:Flush ()
end

function self:Flush ()
	if not self.ContentsChanged then return end
	if self.File:GetPath ():lower ():sub (1, 5) == "data/" then
		file.Write (self.File:GetPath ():sub (6), self.Contents)
		self.ContentsChanged = false
		
		self.File:DispatchEvent ("Updated", VFS.UpdateFlags.Size | VFS.UpdateFlags.ModificationTime)
		if self.File:GetParentFolder () then
			self.File:GetParentFolder ():DispatchEvent ("NodeUpdated", self.File, VFS.UpdateFlags.Size | VFS.UpdateFlags.ModificationTime)
		end
	end
end

function self:GetDisplayPath ()
	return self.File:GetDisplayPath ()
end

function self:GetFile ()
	return self.File
end

function self:GetLength ()
	return self.Length
end

function self:GetPath ()
	return self.File:GetPath ()
end

function self:Read (size, callback)
	self.Contents = self.Contents or file.Read (self.File:GetPath (), true) or ""
	local startPos = self:GetPos ()
	self:Seek (startPos + size)
	callback (VFS.ReturnCode.Success, self.Contents:sub (startPos + 1, startPos + size))
end

function self:Write (size, data, callback)
	if not self:CanWrite () then callback (VFS.ReturnCode.AccessDenied) return end
	if size == 0 then callback (VFS.ReturnCode.Success) return end
	
	self.Contents = self.Contents or file.Read (self.File:GetPath (), true) or ""
	if data:len () < size then data = data .. string.rep ("\0", size - data:len ()) end
	if data:len () > size then data = data:sub (1, size) end
	self.Contents = self.Contents:sub (1, self:GetPos ()) .. data .. self.Contents:sub (self:GetPos () + size + 1)
	if self:GetPos () + size > self.Length then self.Length = self:GetPos () + size end
	self:Seek (self:GetPos () + size)
	self.ContentsChanged = true
	callback (VFS.ReturnCode.Success)
end