local self = {}
GAuth.PermissionBlockNetworker = GAuth.MakeConstructor (self)

--[[
	Events:
		Notification (PermissionBlock permissionBlock, PermissionBlockNotification permissionBlockNotification)
			Fired when a notification needs to be sent out.
		Request (PermissionBlock permissionBlock, PermissionBlockRequest permissionBlockRequest)
			Fired when a request needs to be sent out.
			Return true if this is a remote request.
]]

function self:ctor ()
	GAuth.EventProvider (self)
	
	self.GroupEntryAdded = function (permissionBlock, groupId)
		local session = GAuth.Protocol.PermissionBlock.GroupEntryAdditionNotification (permissionBlock, groupId)
		self:DispatchEvent ("Notification", permissionBlock, GAuth.Protocol.PermissionBlockNotification (permissionBlock, session))
	end
	
	self.GroupEntryRemoved = function (permissionBlock, groupId)
		local session = GAuth.Protocol.PermissionBlock.GroupEntryRemovalNotification (permissionBlock, groupId)
		self:DispatchEvent ("Notification", permissionBlock, GAuth.Protocol.PermissionBlockNotification (permissionBlock, session))
	end
	
	self.GroupPermissionChanged = function (permissionBlock, groupId, actionId, access)
		local session = GAuth.Protocol.PermissionBlock.GroupPermissionChangeNotification (permissionBlock, groupId, actionId, access)
		self:DispatchEvent ("Notification", permissionBlock, GAuth.Protocol.PermissionBlockNotification (permissionBlock, session))
	end
	
	self.InheritOwnerChanged = function (permissionBlock, inheritOwner)
		local session = GAuth.Protocol.PermissionBlock.InheritOwnerChangeNotification (permissionBlock, inheritOwner)
		self:DispatchEvent ("Notification", permissionBlock, GAuth.Protocol.PermissionBlockNotification (permissionBlock, session))
	end
	
	self.InheritPermissionsChanged = function (permissionBlock, inheritPermissions)
		local session = GAuth.Protocol.PermissionBlock.InheritPermissionsChangeNotification (permissionBlock, inheritPermissions)
		self:DispatchEvent ("Notification", permissionBlock, GAuth.Protocol.PermissionBlockNotification (permissionBlock, session))
	end
	
	self.OwnerChanged = function (permissionBlock, ownerId)
		local session = GAuth.Protocol.PermissionBlock.OwnerChangeNotification (permissionBlock, ownerId)
		self:DispatchEvent ("Notification", permissionBlock, GAuth.Protocol.PermissionBlockNotification (permissionBlock, session))
	end
	
	self.RequestAddGroupEntry = function (permissionBlock, authId, groupId, callback)
		local session = GAuth.Protocol.PermissionBlock.GroupEntryAdditionRequest (permissionBlock, authId, groupId, callback)
		return self:DispatchEvent ("Request", permissionBlock, GAuth.Protocol.PermissionBlockRequest (permissionBlock, session))
	end
	
	self.RequestRemoveGroupEntry = function (permissionBlock, authId, groupId, callback)
		local session = GAuth.Protocol.PermissionBlock.GroupEntryRemovalRequest (permissionBlock, authId, groupId, callback)
		return self:DispatchEvent ("Request", permissionBlock, GAuth.Protocol.PermissionBlockRequest (permissionBlock, session))
	end
	
	self.RequestSetGroupPermission = function (permissionBlock, authId, groupId, actionId, access, callback)
		local session = GAuth.Protocol.PermissionBlock.GroupPermissionChangeRequest (permissionBlock, authId, groupId, actionId, access, callback)
		return self:DispatchEvent ("Request", permissionBlock, GAuth.Protocol.PermissionBlockRequest (permissionBlock, session))
	end
	
	self.RequestSetInheritOwner = function (permissionBlock, authId, inheritOwner, callback)
		local session = GAuth.Protocol.PermissionBlock.InheritOwnerChangeRequest (permissionBlock, authId, inheritOwner, callback)
		return self:DispatchEvent ("Request", permissionBlock, GAuth.Protocol.PermissionBlockRequest (permissionBlock, session))
	end
	
	self.RequestSetInheritPermissions = function (permissionBlock, authId, inheritPermissions, callback)
		local session = GAuth.Protocol.PermissionBlock.InheritPermissionsChangeRequest (permissionBlock, authId, inheritPermissions, callback)
		return self:DispatchEvent ("Request", permissionBlock, GAuth.Protocol.PermissionBlockRequest (permissionBlock, session))
	end
	
	self.RequestSetOwner = function (permissionBlock, authId, ownerId, callback)
		local session = GAuth.Protocol.PermissionBlock.OwnerChangeRequest (permissionBlock, authId, ownerId, callback)
		return self:DispatchEvent ("Request", permissionBlock, GAuth.Protocol.PermissionBlockRequest (permissionBlock, session))
	end
end

function self:HookBlock (permissionBlock)
	ErrorNoHalt ("PermissionBlockNetworker:HookBlock : " .. permissionBlock:GetName () .. "\n")

	permissionBlock:AddEventListener ("GroupEntryAdded",           tostring (self), self.GroupEntryAdded)
	permissionBlock:AddEventListener ("GroupEntryRemoved",         tostring (self), self.GroupEntryRemoved)
	permissionBlock:AddEventListener ("GroupPermissionChanged",    tostring (self), self.GroupPermissionChanged)
	permissionBlock:AddEventListener ("InheritOwnerChanged",       tostring (self), self.InheritOwnerChanged)
	permissionBlock:AddEventListener ("InheritPermissionsChanged", tostring (self), self.InheritPermissionsChanged)
	permissionBlock:AddEventListener ("OwnerChanged",              tostring (self), self.OwnerChanged)
end

function self:HookRemoteBlock (permissionBlock)
	ErrorNoHalt ("PermissionBlockNetworker:HookRemoteBlock : " .. permissionBlock:GetName () .. "\n")
	
	permissionBlock:AddEventListener ("RequestAddGroupEntry",         tostring (self), self.RequestAddGroupEntry)
	permissionBlock:AddEventListener ("RequestRemoveGroupEntry",      tostring (self), self.RequestRemoveGroupEntry)
	permissionBlock:AddEventListener ("RequestSetGroupPermission",    tostring (self), self.RequestSetGroupPermission)
	permissionBlock:AddEventListener ("RequestSetInheritOwner",       tostring (self), self.RequestSetInheritOwner)
	permissionBlock:AddEventListener ("RequestSetInheritPermissions", tostring (self), self.RequestSetInheritPermissions)
	permissionBlock:AddEventListener ("RequestSetOwner",              tostring (self), self.RequestSetOwner)
	
	if SERVER then self:HookBlock (permissionBlock) end
end

function self:UnhookBlock (permissionBlock)
	ErrorNoHalt ("PermissionBlockNetworker:UnhookBlock : " .. permissionBlock:GetName () .. "\n")
	
	permissionBlock:RemoveEventListener ("GroupEntryAdded",              tostring (self))
	permissionBlock:RemoveEventListener ("GroupEntryRemoved",            tostring (self))
	permissionBlock:RemoveEventListener ("GroupPermissionChanged",       tostring (self))
	permissionBlock:RemoveEventListener ("InheritOwnerChanged",          tostring (self))
	permissionBlock:RemoveEventListener ("InheritPermissionsChanged",    tostring (self))
	permissionBlock:RemoveEventListener ("OwnerChanged",                 tostring (self))
	
	permissionBlock:RemoveEventListener ("RequestAddGroupEntry",         tostring (self))
	permissionBlock:RemoveEventListener ("RequestRemoveGroupEntry",      tostring (self))
	permissionBlock:RemoveEventListener ("RequestSetGroupPermission",    tostring (self))
	permissionBlock:RemoveEventListener ("RequestSetInheritOwner",       tostring (self))
	permissionBlock:RemoveEventListener ("RequestSetInheritPermissions", tostring (self))
	permissionBlock:RemoveEventListener ("RequestSetOwner",              tostring (self))
end

--[[
	PermissionBlockNetworker:SerializeBlock (PermissionBlock permissionBlock)
		Returns: PermissionBlockNotification[] notifications
		
		Returns an array of notifications that will synchronize the state of a
		remote permission block to match the given local permission block.
]]
function self:SerializeBlock (permissionBlock)
	local notifications = {}
	notifications [#notifications + 1] = GAuth.Protocol.PermissionBlock.InheritOwnerChangeNotification (permissionBlock, permissionBlock:InheritsOwner ())
	notifications [#notifications + 1] = GAuth.Protocol.PermissionBlock.InheritPermissionsChangeNotification (permissionBlock, permissionBlock:InheritsPermissions ())
	if not permissionBlock:InheritsOwner () then
		notifications [#notifications + 1] = GAuth.Protocol.PermissionBlock.OwnerChangeNotification (permissionBlock, permissionBlock:GetOwner ())
	end
	
	for groupId in permissionBlock:GetGroupEntryEnumerator () do
		for actionId in permissionBlock:GetPermissionDictionary ():GetPermissionEnumerator () do
			local access = permissionBlock:GetGroupPermission (groupId, actionId)
			if access ~= GAuth.Access.None then
				notifications [#notifications + 1] = GAuth.Protocol.PermissionBlock.GroupPermissionChangeNotification (permissionBlock, groupId, actionId, access)
			end
		end
	end
	
	for k, notification in ipairs (notifications) do
		notifications [k] = GAuth.Protocol.PermissionBlockNotification (permissionBlock, notification)
	end
	return notifications
end

--[[
	PermissionBlockNetworker:HandleNotification (EndPoint remoteEndPoint, PermissionBlock permissionBlock, InBuffer inBuffer)
		Returns: PermissionBlockResponse response
]]
function self:HandleNotification (remoteEndPoint, permissionBlock, inBuffer)
	local typeId = inBuffer:UInt32 ()
	local packetType = GAuth.Protocol.StringTable:StringFromHash (typeId)
	
	local ctor = GAuth.Protocol.ResponseTable [packetType]
	if not ctor then
		ErrorNoHalt ("PermissionBlockNetworker:HandleNotification : No handler for " .. tostring (packetType) .. " is registered!")
		return
	end
	local session = ctor ()
	session:SetRemoteEndPoint (remoteEndPoint)
	session:HandleInitialPacket (inBuffer)
	return session
end

--[[
	PermissionBlockNetworker:HandleRequest (EndPoint remoteEndPoint, PermissionBlock permissionBlock, InBuffer inBuffer)
		Returns: PermissionBlockResponse response
]]
self.HandleRequest = self.HandleNotification

-- Events
self.GroupEntryAdded              = GAuth.NullCallback
self.GroupEntryRemoved            = GAuth.NullCallback
self.GroupPermissionChanged       = GAuth.NullCallback
self.InheritOwnerChanged          = GAuth.NullCallback
self.InheritPermissionsChanged    = GAuth.NullCallback
self.OwnerChanged                 = GAuth.NullCallback

self.RequestAddGroupEntry         = GAuth.NullCallback
self.RequestRemoveGroupEntry      = GAuth.NullCallback
self.RequestSetGroupPermission    = GAuth.NullCallback
self.RequestSetInheritOwner       = GAuth.NullCallback
self.RequestSetInheritPermissions = GAuth.NullCallback
self.RequestSetOwner              = GAuth.NullCallback