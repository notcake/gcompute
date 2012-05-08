local self = {}
VFS.NetFile = VFS.MakeConstructor (self, VFS.IFile, VFS.NetNode)

function self:ctor (netClient, path, name, parentFolder)
end