local self = {}
VFS.MountedNode = VFS.MakeConstructor (self, VFS.INode)

function self:ctor (nameOverride, mountedNode, parentFolder)
	self.NameOverride = nameOverride
	self.DisplayNameOverride = nil
	self.MountedNode = mountedNode
	self.ParentFolder = parentFolder
	
	self.PermissionBlock = self.MountedNode:GetPermissionBlock ()
	if not self.PermissionBlock then
		self.PermissionBlock = GAuth.PermissionBlock ()
		self.PermissionBlock:SetParentFunction (
			function ()
				if not self:GetParentFolder () then return end
				return self:GetParentFolder ():GetPermissionBlock ()
			end
		)
		self.PermissionBlock:SetDisplayNameFunction (function () return self:GetDisplayPath () end)
		self.PermissionBlock:SetNameFunction (function () return self:GetPath () end)
	end
end

function self:GetDisplayName ()
	return self.DisplayNameOverride or self.MountedNode:GetDisplayName ()
end

function self:GetName ()
	return self.NameOverride or self.MountedNode:GetName ()
end

function self:GetParentFolder ()
	return self.ParentFolder
end

function self:GetPermissionBlock ()
	return self.PermissionBlock
end

function self:SetDisplayName (displayName)
	self.DisplayNameOverride = displayName
end