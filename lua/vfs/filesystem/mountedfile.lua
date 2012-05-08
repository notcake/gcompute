local self = {}
VFS.MountedFile = VFS.MakeConstructor (self, VFS.IFile, VFS.MountedNode)

function self:ctor (nameOverride, mountedNode, parentFolder)
end

function self:Open (authId, openFlags, callback)
	self.MountedNode:Open (authId, openFlags,
		function (returnCode, fileStream)
			if returnCode == VFS.ReturnCode.Success then
				callback (returnCode, VFS.MountedFileStream (self, fileStream))
			else
				callback (returnCode, fileStream)
			end
		end
	)
end