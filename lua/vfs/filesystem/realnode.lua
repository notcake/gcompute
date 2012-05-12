local self = {}
VFS.RealNode = VFS.MakeConstructor (self, VFS.INode)

function self:ctor (path, name, parentFolder)
	self.Type = "Real" .. (self:IsFolder () and "Folder" or "File")
	self.Name = name
	self.ParentFolder = parentFolder
end

function self:GetName ()
	return self.Name
end

function self:GetModificationTime ()
	if self:GetPath ():lower ():sub (1, 5) == "data/" then
		return file.Time (self:GetPath ():sub (6))
	end
	return -1
end

function self:GetParentFolder ()
	return self.ParentFolder
end

function self:GetPermissionBlock ()
	return nil
end

function self:Rename (authId, name, callback)
	callback = callback or VFS.NullCallback
	if self:GetName () == name then callback (VFS.ReturnCode.Success) return end
	if not self:GetParentFolder () then callback (VFS.ReturnCode.AccessDenied) return end

	if self:IsFolder () then callback (VFS.ReturnCode.AccessDenied) return end
	if self:GetPath ():lower ():sub (1, 5) ~= "data/" then callback (VFS.ReturnCode.AccessDenied) return end
	name = VFS.SanifyNodeName (name)
	if not name then callback (VFS.ReturnCode.AccessDenied) return end
	if name:sub (-4, -1) ~= ".txt" then name = name .. ".txt" end
	
	local oldName = self:GetName ()
	local newPath = self:GetParentFolder ().FolderPath .. name
	if file.Exists (newPath, true) then callback (VFS.ReturnCode.AlreadyExists) return end
	file.Write (newPath:sub (6), file.Read (self:GetPath (), true))
	if not file.Exists (newPath, true) then callback (VFS.ReturnCode.AccessDenied) return end
	file.Delete (self:GetPath ():sub (6))
	self.Name = name
	
	self:GetParentFolder ():RenameChild (authId, oldName, name)
	self:DispatchEvent ("Renamed", oldName, name)
	callback (VFS.ReturnCode.Success)
end