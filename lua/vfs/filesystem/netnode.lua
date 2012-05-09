local self = {}
VFS.NetNode = VFS.MakeConstructor (self, VFS.INode)

function self:ctor (endPoint, path, name, parentFolder)
	self.EndPoint = endPoint
	self.Path = path
	
	self.Name = name
	self.DisplayName = self.Name
	self.ParentFolder = parentFolder
	
	self.PermissionBlock = GAuth.PermissionBlock ()
	self.PermissionBlock:SetParentFunction (
		function ()
			if not self:GetParentFolder () then return end
			return self:GetParentFolder ():GetPermissionBlock ()
		end
	)
	self.PermissionBlock:SetDisplayNameFunction (function () return self:GetDisplayPath () end)
	self.PermissionBlock:SetNameFunction (function () return self:GetPath () end)
	self.PermissionBlock:AddEventListener ("PermissionsChanged", tostring (self), function () self:DispatchEvent ("PermissionsChanged") end)
	
	VFS.PermissionBlockNetworker:HookRemoteBlock (self.PermissionBlock)
	
	self:AddEventListener ("Deleted", function () self:UnhookPermissionBlock () end)
end

function self:GetDisplayName ()
	return self.DisplayName
end

function self:GetName ()
	return self.Name
end

function self:GetParentFolder ()
	return self.ParentFolder
end

function self:GetPermissionBlock ()
	return self.PermissionBlock
end

function self:SetDisplayName (displayName)
	self.DisplayName = displayName
end