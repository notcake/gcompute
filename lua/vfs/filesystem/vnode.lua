local self = {}
VFS.VNode = VFS.MakeConstructor (self, VFS.INode)

function self:ctor (name, parentFolder)
	self.Type = "V" .. (self:IsFolder () and "Folder" or "File")
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
	
	VFS.PermissionBlockNetworker:HookBlock (self.PermissionBlock)
	
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

function self:Rename (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	name = VFS.SanifyNodeName (name)
	if not name then callback (VFS.ReturnCode.AccessDenied) return end
	
	local oldName = self:GetName ()
	if oldName == name then callback (VFS.ReturnCode.Success) return end
	if not self:GetPermissionBlock ():IsAuthorized (authId, "Rename") then callback (VFS.ReturnCode.AccessDenied) return end
	
	self.Name = name
	if self:GetParentFolder () then self:GetParentFolder ():RenameChild (authId, oldName, name) end
	self:DispatchEvent ("Renamed", oldName, name)
end

function self:SetDisplayName (displayName)
	if self.DisplayName == displayName then return end
	self.DisplayName = displayName
	
	self:DispatchEvent ("Updated")
	if self:GetParentFolder () then self:GetParentFolder ():DispatchEvent ("NodeUpdated", self) end
end