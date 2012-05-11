local self = {}
VFS.MountedNode = VFS.MakeConstructor (self, VFS.INode)

function self:ctor (nameOverride, mountedNode, parentFolder)
	self.NameOverride = nameOverride
	self.DisplayNameOverride = nil
	self.MountedNode = mountedNode
	self.ParentFolder = parentFolder
	
	self.MountedNode:AddEventListener ("Deleted", tostring (self), function (_) self:DispatchEvent ("Deleted") end)
	self.MountedNode:AddEventListener ("PermissionsChanged", function () self:DispatchEvent ("PermissionsChanged") end)
	self.MountedNode:AddEventListener ("Renamed", tostring (self),
		function (_, oldName, newName)
			if self.NameOverride then self.NameOverride = newName end
			self:DispatchEvent ("Renamed", oldName, newName)
			if self:GetParentFolder () then self:GetParentFolder ():RenameChild (authId, oldName, newName) end
		end
	)
	
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
	
		VFS.PermissionBlockNetworker:HookBlock (self.PermissionBlock)
	end
	
	self:AddEventListener ("Deleted", self.UnhookPermissionBlock)
end

function self:GetDisplayName ()
	return self.DisplayNameOverride or self.MountedNode:GetDisplayName ()
end

function self:GetInner ()
	return self.MountedNode:GetInner ()
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

function self:Rename (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	name = VFS.SanifyNodeName (name)
	if not name then callback (VFS.ReturnCode.AccessDenied) return end
	
	local oldName = self:GetName ()
	if oldName == name then callback (VFS.ReturnCode.Success) return end
	if not self:GetPermissionBlock ():IsAuthorized (authId, "Rename") then callback (VFS.ReturnCode.AccessDenied) return end
	
	if self.NameOverride then
		if self:GetParentFolder () then
			-- Temporarily set our name to the new one.
			self.NameOverride = name
			
			self:GetParentFolder ():RenameChild (authId, oldName, name,
				function (returnCode)
					if returnCode == VFS.ReturnCode.Success then
						self:GetParentFolder ():DispatchEvent ("NodeRenamed", self, oldName, name)
						self:DispatchEvent ("Renamed", oldName, name)
					else
						self.NameOverride = oldName
					end
					callback (returnCode)
				end
			)
		else
			-- No parent folder, so we're free to name ourselves whatever we want
			self.NameOverride = name
			self:DispatchEvent ("Renamed", oldName, name)
			callback (VFS.ReturnCode.Success)
		end
	else
		-- Check that our parent folder doesn't already have a node with the same name
		-- this check may be ineffective if the renaming operation of this node's mounted node
		-- or the parent folder is asynchronous
		if self:GetParentFolder () and self:GetParentFolder ():GetDirectChildSynchronous (name) then callback (VFS.ReturnCode.AlreadyExists) return end
		
		self.MountedNode:Rename (authId, name,
			function (returnCode)
				if returnCode == VFS.ReturnCode.Success then
					if self:GetParentFolder () then self:GetParentFolder ():RenameChild (authId, oldName, self.MountedNode:GetName ()) end
					
					self:DispatchEvent ("Renamed", oldName, self.MountedNode:GetName ())
				end
				callback (returnCode)
			end
		)
	end
end

function self:SetDisplayName (displayName)
	self.DisplayNameOverride = displayName
end