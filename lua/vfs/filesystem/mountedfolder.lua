local self = {}
VFS.MountedFolder = VFS.MakeConstructor (self, VFS.IFolder, VFS.MountedNode)

function self:ctor (nameOverride, mountedNode, parentFolder)
	self.Children = {}
end

function self:EnumerateChildren (authId, callback)
	callback = callback or VFS.NullCallback
	
	self.MountedNode:EnumerateChildren (authId,
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.Success then
				if not self.Children [node:GetName ()] then
					if node:IsFolder () then
						self.Children [node:GetName ()] = VFS.MountedFolder (nil, node, self)
					else
						self.Children [node:GetName ()] = VFS.MountedFile (nil, node, self)
					end
				end
				callback (returnCode, self.Children [node:GetName ()])
			else
				callback (returnCode, node)
			end
		end
	)
end

function self:GetDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	self.MountedNode:GetDirectChild (authId, name,
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.Success then
				if not self.Children [node:GetName ()] then
					if node:IsFolder () then
						self.Children [node:GetName ()] = VFS.MountedFolder (nil, node, self)
					else
						self.Children [node:GetName ()] = VFS.MountedFile (nil, node, self)
					end
				end
				callback (returnCode, self.Children [node:GetName ()])
			else
				callback (returnCode, node)
			end
		end
	)
end