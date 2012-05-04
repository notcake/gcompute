local self = {}
VFS.MountedFile = VFS.MakeConstructor (self, VFS.IFile)

function self:ctor (nameOverride, mountedFile, parentFolder)
	self.NameOverride = nameOverride
	self.DisplayNameOverride = nil
	self.MountedFile = mountedFile
	self.ParentFolder = parentFolder
end

function self:GetDisplayName ()
	return self.DisplayNameOverride or self.MountedFile:GetDisplayName ()
end

function self:GetName ()
	return self.NameOverride or self.MountedFile:GetName ()
end

function self:GetParentFolder ()
	return self.ParentFolder
end

function self:Open (authId, openFlags, callback)
	self.MountedFile:Open (authId, openFlags,
		function (returnCode, fileStream)
			if returnCode == VFS.ReturnCode.None then
				callback (returnCode, VFS.MountedFileStream (self, fileStream))
			else
				callback (returnCode, fileStream)
			end
		end
	)
end

function self:SetDisplayName (displayName)
	self.DisplayNameOverride = displayName
end