local self = {}
GAuth.PermissionBlock = GAuth.MakeConstructor (self)

--[[
	Events:
		NotifyGroupEntryAdded (groupId)
			Fire this when a group entry is added to the host PermissionBlock
		NotifyGroupEntryRemoved (groupId)
			Fire this when a group entry is removed form the host PermissionBlock
		NotifyGroupEntryPermissionChanged (groupId, actionId, access)
			Fire this when a group entry permission is changed on the host PermissionBlock
		NotifyInheritOwnerChanged (inheritOwner)
			Fire this when owner inheritance has changed on the host PermissionBlock
		NotifyInheritPermissionsChanged (inheritPermissions)
			Fire this when permission inheritance has changed on the host PermissionBlock
		NotifyOwnerChanged (ownerId)
			Fire this when the owner of the host PermissionBlock is changed
	
		RequestAddGroupEntry (authId, groupId, callback)
			Return true to stop AddGroupEntry from running locally
		RequestRemoveGroupEntry (authId, groupId, callback)
			Return true to stop RemoveGroupEntry from running locally
		RequestSetGroupPermission (authId, groupId, actionId, access, callback)
			Return true to stop SetGroupPermission from running locally
		RequestSetInheritOwner (authId, inheritOwner, callback)
			Return true to stop SetInheritOwner from running locally
		RequestSetInheritPermissions (authId, inheritPermissions, callback)
			Return true to stop SetInheritPermissions from running locally
		RequestSetOwner (authId, ownerId, callback)
			Return true to stop SetOwner from running locally
	
		GroupEntryAdded (groupId)
			Fired when a group entry has been added
		GroupEntryRemoved (groupId)
			Fired when a group entry has been removed
		GroupPermissionChanged (groupId, actionId, access)
			Fired when a group entry permission has been changed
		InheritOwnerChanged (inheritOwner)
			Fired when owner inheritance has been changed
		InheritPermissionsChanged (inheritPermissions)
			Fired when permission inheritance has been changed
		OwnerChanged (ownerId)
			Fired when the owner has been changed
]]

function self:ctor ()
	self.PermissionDictionary = nil

	self.OwnerId = GAuth.GetSystemId ()
	self.GroupEntries = {}
	
	self.InheritOwner = true
	self.InheritPermissions = true
	
	self.Parent = nil
	self.ParentFunction = nil
	
	self.Name = "Unknown"
	self.NameFunction = nil
	self.DisplayName = "Unknown"
	self.DisplayNameFunction = nil
	
	GAuth.EventProvider (self)
	
	self:AddEventListener ("NotifyGroupEntryAdded", function (_, groupId)
		self.GroupEntries [groupId] = self.GroupEntries [groupId] or {}
		self:DispatchEvent ("GroupEntryAdded", groupId)
	end)
	
	self:AddEventListener ("NotifyGroupEntryRemoved", function (_, groupId)
		self.GroupEntries [groupId] = nil
		self:DispatchEvent ("GroupEntryRemoved", groupId)
	end)
	
	self:AddEventListener ("NotifyGroupPermissionChanged", function (_, groupId, actionId, access)
		self.GroupEntries [groupId] = self.GroupEntries [groupId] or {}
		self.GroupEntries [groupId] [actionId] = access
		self:DispatchEvent ("GroupPermissionChanged", groupId, actionId, access)
	end)
	
	self:AddEventListener ("NotifyInheritOwnerChanged", function (_, inheritOwner)
		self.InheritOwner = inheritOwner
		self:DispatchEvent ("InheritOwnerChanged", inheritOwner)
	end)
	
	self:AddEventListener ("NotifyInheritPermissionsChanged", function (_, inheritPermissions)
		self.InheritPermissions = inheritPermissions
		self:DispatchEvent ("InheritPermissionsChanged", inheritPermissions)
	end)
	
	self:AddEventListener ("NotifyOwnerChanged", function (_, ownerId)
		self.OwnerId = ownerId
		self:DispatchEvent ("OwnerChanged", ownerId)
	end)
end

function self:AddGroupEntry (authId, groupId, callback)
	callback = callback or GAuth.NullCallback

	if self.GroupEntries [groupId] then callback (GAuth.ReturnCode.Success) return end
	if not self:IsAuthorized (authId, "Modify Permissions") then callback (GAuth.ReturnCode.AccessDenied) return end
	
	if self:DispatchEvent ("RequestAddGroupEntry", authId, groupId, callback) then return end
	
	self.GroupEntries [groupId] = {}
	self:DispatchEvent ("GroupEntryAdded", groupId)
	
	callback (GAuth.ReturnCode.Success)
end

function self:GetAccess (authId, actionId, permissionBlock)
	if authId == GAuth.GetSystemId () or
		authId == GAuth.GetServerId () then
		return GAuth.Access.Allow
	end

	local parentAccess = GAuth.Access.None
	if self.InheritPermissions and self:GetParent () then
		parentAccess = self:GetParent ():GetAccess (authId, actionId, permissionBlock or self)
	end
	
	if parentAccess == GAuth.Access.Deny then return GAuth.Access.Deny end
	
	local thisAccess = GAuth.Access.None
	for groupId, groupEntry in pairs (self.GroupEntries) do
		if GAuth.IsUserInGroup (groupId, authId, permissionBlock) then
			if groupEntry [actionId] == GAuth.Access.Allow then
				thisAccess = GAuth.Access.Allow
			elseif groupEntry [actionId] == GAuth.Access.Deny then
				return GAuth.Access.Deny
			end
		end
	end
	
	if parentAccess == GAuth.Access.Allow or
		thisAccess == GAuth.Access.Allow then
		return GAuth.Access.Allow
	end
	
	return GAuth.Access.None
end

function self:GetGroupAccess (groupId, actionId, permissionBlock)
	local parentAccess = GAuth.Access.None
	if self.InheritPermissions and self:GetParent () then
		parentAccess = self:GetParent ():GetGroupAccess (groupId, actionId, permissionBlock or self)
	end
	
	if parentAccess == GAuth.Access.Deny then return GAuth.Access.Deny end
	
	local thisAccess = GAuth.Access.None
	local groupEntry = self.GroupEntries [groupId]
	if not groupEntry then return parentAccess end
	
	if groupEntry [actionId] == GAuth.Access.Allow then
		thisAccess = GAuth.Access.Allow
	elseif groupEntry [actionId] == GAuth.Access.Deny then
		return GAuth.Access.Deny
	end
	
	if parentAccess == GAuth.Access.Allow or
		thisAccess == GAuth.Access.Allow then
		return GAuth.Access.Allow
	end
	
	return GAuth.Access.None
end

function self:GetGroupEntryEnumerator ()
	local next, tbl, key = pairs (self.GroupEntries)
	return function ()
		key = next (tbl, key)
		return key
	end
end

function self:GetGroupPermission (groupId, actionId, permissionBlock)
	if not self.GroupEntries [groupId] then return GAuth.Access.None end
	return self.GroupEntries [groupId] [actionId] or GAuth.Access.None
end

function self:GetDisplayName ()
	if self.DisplayNameFunction then return self.DisplayNameFunction (self) end
	return self.DisplayName
end

function self:GetName ()
	if self.NameFunction then return self.NameFunction (self) end
	return self.Name
end

function self:GetOwner ()
	if self.InheritOwner and self:GetParent () then
		return self:GetParent ():GetOwner ()
	end

	return self.OwnerId
end

function self:GetParent ()
	if self.ParentFunction then
		return self:ParentFunction ()
	end
	
	return self.Parent
end

function self:GetPermissionDictionary ()
	if self.PermissionDictionary then return self.PermissionDictionary end
	if self:GetParent () then return self:GetParent ():GetPermissionDictionary () end
	return nil
end

function self:InheritsOwner ()
	return self.InheritOwner
end

function self:InheritsPermissions ()
	return self.InheritPermissions
end

function self:IsAuthorized (authId, actionId, permissionBlock)
	local authorized = self:GetAccess (authId, actionId, permissionBlock or self) == GAuth.Access.Allow
	if authorized then
		print (authId .. " is permitted to " .. actionId .. " on " .. self:GetName ())
	else
		print (authId .. " is NOT permitted to " .. actionId .. " on " .. self:GetName ())
	end
	return authorized
end

function self:RemoveGroupEntry (authId, groupId, callback)
	callback = callback or GAuth.NullCallback

	if not self.GroupEntries [groupId] then callback (GAuth.ReturnCode.Success) return end
	if not self:IsAuthorized (authId, "Modify Permissions") then callback (GAuth.ReturnCode.AccessDenied) return end

	if self:DispatchEvent ("RequestRemoveGroupEntry", authId, groupId, callback) then return end
	
	self.GroupEntries [groupId] = nil
	self:DispatchEvent ("GroupEntryRemoved", groupId)
	
	callback (GAuth.ReturnCode.Success)
end

function self:SetGroupPermission (authId, groupId, actionId, access, callback)
	callback = callback or GAuth.NullCallback

	if not self:IsAuthorized (authId, "Modify Permissions") then callback (GAuth.ReturnCode.AccessDenied) return end

	if self:DispatchEvent ("RequestSetGroupPermission", authId, groupId, actionId, access, callback) then return end
	
	if self.GroupEntries [groupId] then
		if self.GroupEntries [groupId] [actionId] ~= access then
			self.GroupEntries [groupId] [actionId] = access
			self:DispatchEvent ("GroupPermissionChanged", groupId, actionId, access)
		end
		
		callback (GAuth.ReturnCode.Success)
	else
		self:AddGroupEntry (authId, groupId,
			function (returnCode)
				if returnCode ~= GAuth.ReturnCode.Success then callback (returnCode) return end
				
				self.GroupEntries [groupId] [actionId] = access
				self:DispatchEvent ("GroupPermissionChanged", groupId, actionId, access)
				
				callback (GAuth.ReturnCode.Success)
			end
		)
	end
end

function self:SetInheritOwner (authId, inheritOwner, callback)
	callback = callback or GAuth.NullCallback

	if self.InheritOwner == inheritOwner then callback (GAuth.ReturnCode.Success) return end
	if not self:IsAuthorized (authId, "Set Owner") then callback (GAuth.ReturnCode.AccessDenied) return end
	
	if self:DispatchEvent ("RequestSetInheritOwner", authId, inheritOwner, callback) then return end
	
	self.InheritOwner = inheritOwner
	self:DispatchEvent ("InheritOwnerChanged", inheritOwner)
	
	callback (GAuth.ReturnCode.Success)
end

function self:SetInheritPermissions (authId, inheritPermissions, callback)
	callback = callback or GAuth.NullCallback

	if self.InheritPermissions == inheritPermissions then callback (GAuth.ReturnCode.Success) return end
	if not self:IsAuthorized (authId, "Modify Permissions") then callback (GAuth.ReturnCode.AccessDenied) return end

	if self:DispatchEvent ("RequestSetInheritPermissions", authId, inheritPermissions, callback) then return end
	
	self.InheritPermissions = inheritPermissions
	self:DispatchEvent ("InheritPermissionsChanged", inheritPermissions)
	
	callback (GAuth.ReturnCode.Success)
end

function self:SetDisplayName (displayName)
	return self.DisplayName
end

function self:SetDisplayNameFunction (displayNameFunction)
	self.DisplayNameFunction = displayNameFunction
end

function self:SetName (name)
	return self.Name
end

function self:SetNameFunction (nameFunction)
	self.NameFunction = nameFunction
end

function self:SetOwner (authId, ownerId, callback)
	callback = callback or GAuth.NullCallback

	if self.OwnerId == ownerId then callback (GAuth.ReturnCode.Success) return end
	if not self:IsAuthorized (authId, "Set Owner") then callback (GAuth.ReturnCode.AccessDenied) return end

	if self:DispatchEvent ("RequestSetOwner", authId, ownerId, callback) then return end
	
	self.OwnerId = ownerId
	self:DispatchEvent ("OwnerChanged", ownerId)
	
	-- Turn off owner inheritance. This line shouldn't be in the notification
	-- reception code, since the InheritOwnerChanged notification should 
	-- get sent separately
	if self.InheritOwner then self:SetInheritOwner (authId, false) end
	
	callback (GAuth.ReturnCode.Success)
end

function self:SetParent (parent)
	self.Parent = parent
end

function self:SetParentFunction (parentFunction)
	self.ParentFunction = parentFunction
end

function self:SetPermissionDictionary (permissionDictionary)
	self.PermissionDictionary = permissionDictionary
end