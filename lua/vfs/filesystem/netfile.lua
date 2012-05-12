local self = {}
VFS.NetFile = VFS.MakeConstructor (self, VFS.IFile, VFS.NetNode)

function self:ctor (endPoint, path, name, parentFolder)
	self.Size = -1
end

function self:GetSize ()
	return self.Size
end

function self:Open (authId, openFlags, callback)
	callback = callback or VFS.NullCallback
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, "Read") then callback (VFS.ReturnCode.AccessDenied) return end
	
	self.EndPoint:StartSession (VFS.Protocol.FileOpenRequest (self, openFlags, callback))
end

-- Internal, do not call
function self:SetSize (size)
	if self.Size == size then return end
	self.Size = size
	
	self:DispatchEvent ("Updated")
	if self:GetParentFolder () then self:GetParentFolder ():DispatchEvent ("NodeUpdated", self) end
end