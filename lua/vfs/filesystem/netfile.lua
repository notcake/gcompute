local self = {}
VFS.NetFile = VFS.MakeConstructor (self, VFS.IFile, VFS.NetNode)

function self:ctor (endPoint, path, name, parentFolder)
end

function self:Open (authId, openFlags, callback)
	callback = callback or VFS.NullCallback
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, "Read") then callback (VFS.ReturnCode.AccessDenied) return end
	
	self.EndPoint:StartSession (VFS.Protocol.FileOpenRequest (self, openFlags, callback))
end