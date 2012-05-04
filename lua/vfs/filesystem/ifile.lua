local self = {}
VFS.IFile = VFS.MakeConstructor (self, VFS.INode)

function self:ctor ()
end

function self:GetName ()
	VFS.Error ("IFile:GetName : Not implemented")
	return "[File]"
end

function self:GetNodeType ()
	return VFS.NodeType.File
end

--[[
	IFile:Open (authId, OpenFlags, function (ReturnCode, IFileStream))
]]
function self:Open (authId, openFlags, callback)
	VFS.Error ("IFile:Open : Not implemented")
	return callback (VFS.ReturnCode.AccessDenied)
end