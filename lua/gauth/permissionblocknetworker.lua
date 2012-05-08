local self = {}
GAuth.PermissionBlockNetworker = GAuth.MakeConstructor (self)

--[[
	PermissionBlockNetworker
	
		Use this to network permission blocks.
		
		3 functions need to be passed to this class:
			Resolver (permissionBlockId)
				Returns: PermissionBlock permissionBlock
			
			NotificationFilter (remoteId, permissionBlockId, permissionBlock)
				Returns: boolean sendNotification
				
			RequestFilter (permissionBlock)
				Returns boolean isNetworked, string destUserId
]]

function self:ctor (systemName)
	self.SystemName = systemName
	GAuth.PermissionBlockNetworkerManager:Register (self)
	
	self.ResolverFunction = GAuth.NullCallback
	self.NotificationFilter = function ()
		GLib.Error ("PermissionBlockNetworker : No notification filter set!")
		self.NotificationFilter = function () return true end
		return true
	end
	self.RequestFilter = function ()
		GLib.Error ("PermissionBlockNetworker : No request filter set!")
		self.NotificationFilter = function () return true end
		return true
	end
	
	GAuth.EventProvider (self)
	
	self.GroupEntryAdded = function (permissionBlock, groupId)
		local session = GAuth.Protocol.PermissionBlock.GroupEntryAdditionNotification (permissionBlock, groupId)
		GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.PermissionBlockNotification (self:GetSystemName (), permissionBlock, session))
	end
	
	self.GroupEntryRemoved = function (permissionBlock, groupId)
		local session = GAuth.Protocol.PermissionBlock.GroupEntryRemovalNotification (permissionBlock, groupId)
		GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.PermissionBlockNotification (self:GetSystemName (), permissionBlock, session))
	end
	
	self.GroupPermissionChanged = function (permissionBlock, groupId, actionId, access)
		local session = GAuth.Protocol.PermissionBlock.GroupPermissionChangeNotification (permissionBlock, groupId, actionId, access)
		GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.PermissionBlockNotification (self:GetSystemName (), permissionBlock, session))
	end
	
	self.InheritOwnerChanged = function (permissionBlock, inheritOwner)
		local session = GAuth.Protocol.PermissionBlock.InheritOwnerChangeNotification (permissionBlock, inheritOwner)
		GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.PermissionBlockNotification (self:GetSystemName (), permissionBlock, session))
	end
	
	self.InheritPermissionsChanged = function (permissionBlock, inheritPermissions)
		local session = GAuth.Protocol.PermissionBlock.InheritPermissionsChangeNotification (permissionBlock, inheritPermissions)
		GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.PermissionBlockNotification (self:GetSystemName (), permissionBlock, session))
	end
	
	self.OwnerChanged = function (permissionBlock, ownerId)
		local session = GAuth.Protocol.PermissionBlock.OwnerChangeNotification (permissionBlock, ownerId)
		GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.PermissionBlockNotification (self:GetSystemName (), permissionBlock, session))
	end
	
	self.RequestAddGroupEntry = function (permissionBlock, authId, groupId, callback)
		local sendRequest, hostId = self:ShouldSendRequest (permissionBlock)
		if not sendRequest then return end
		local session = GAuth.Protocol.PermissionBlock.GroupEntryAdditionRequest (permissionBlock, authId, groupId, callback)
		GAuth.EndPointManager:GetEndPoint (hostId):StartSession (GAuth.Protocol.PermissionBlockRequest (self:GetSystemName (), permissionBlock, session))
		return sendRequest
	end
	
	self.RequestRemoveGroupEntry = function (permissionBlock, authId, groupId, callback)
		local sendRequest, hostId = self:ShouldSendRequest (permissionBlock)
		if not sendRequest then return end
		local session = GAuth.Protocol.PermissionBlock.GroupEntryRemovalRequest (permissionBlock, authId, groupId, callback)
		GAuth.EndPointManager:GetEndPoint (hostId):StartSession (GAuth.Protocol.PermissionBlockRequest (self:GetSystemName (), permissionBlock, session))
		return sendRequest
	end
	
	self.RequestSetGroupPermission = function (permissionBlock, authId, groupId, actionId, access, callback)
		local sendRequest, hostId = self:ShouldSendRequest (permissionBlock)
		if not sendRequest then return end
		local session = GAuth.Protocol.PermissionBlock.GroupPermissionChangeRequest (permissionBlock, authId, groupId, actionId, access, callback)
		GAuth.EndPointManager:GetEndPoint (hostId):StartSession (GAuth.Protocol.PermissionBlockRequest (self:GetSystemName (), permissionBlock, session))
		return sendRequest
	end
	
	self.RequestSetInheritOwner = function (permissionBlock, authId, inheritOwner, callback)
		local sendRequest, hostId = self:ShouldSendRequest (permissionBlock)
		if not sendRequest then return end
		local session = GAuth.Protocol.PermissionBlock.InheritOwnerChangeRequest (permissionBlock, authId, inheritOwner, callback)
		GAuth.EndPointManager:GetEndPoint (hostId):StartSession (GAuth.Protocol.PermissionBlockRequest (self:GetSystemName (), permissionBlock, session))
		return sendRequest
	end
	
	self.RequestSetInheritPermissions = function (permissionBlock, authId, inheritPermissions, callback)
		local sendRequest, hostId = self:ShouldSendRequest (permissionBlock)
		if not sendRequest then return end
		local session = GAuth.Protocol.PermissionBlock.InheritPermissionsChangeRequest (permissionBlock, authId, inheritPermissions, callback)
		GAuth.EndPointManager:GetEndPoint (hostId):StartSession (GAuth.Protocol.PermissionBlockRequest (self:GetSystemName (), permissionBlock, session))
		return sendRequest
	end
	
	self.RequestSetOwner = function (permissionBlock, authId, ownerId, callback)
		local sendRequest, hostId = self:ShouldSendRequest (permissionBlock)
		if not sendRequest then return end
		local session = GAuth.Protocol.PermissionBlock.OwnerChangeRequest (permissionBlock, authId, ownerId, callback)
		GAuth.EndPointManager:GetEndPoint (hostId):StartSession (GAuth.Protocol.PermissionBlockRequest (self:GetSystemName (), permissionBlock, session))
		return sendRequest
	end
end

-- Permission block hooks
function self:HookBlock (permissionBlock)
	ErrorNoHalt (self.SystemName .. ".PermissionBlockNetworker:HookBlock : " .. permissionBlock:GetName () .. "\n")

	permissionBlock:AddEventListener ("GroupEntryAdded",           tostring (self), self.GroupEntryAdded)
	permissionBlock:AddEventListener ("GroupEntryRemoved",         tostring (self), self.GroupEntryRemoved)
	permissionBlock:AddEventListener ("GroupPermissionChanged",    tostring (self), self.GroupPermissionChanged)
	permissionBlock:AddEventListener ("InheritOwnerChanged",       tostring (self), self.InheritOwnerChanged)
	permissionBlock:AddEventListener ("InheritPermissionsChanged", tostring (self), self.InheritPermissionsChanged)
	permissionBlock:AddEventListener ("OwnerChanged",              tostring (self), self.OwnerChanged)
end

function self:HookRemoteBlock (permissionBlock)
	ErrorNoHalt (self.SystemName .. ".PermissionBlockNetworker:HookRemoteBlock : " .. permissionBlock:GetName () .. "\n")
	
	permissionBlock:AddEventListener ("RequestAddGroupEntry",         tostring (self), self.RequestAddGroupEntry)
	permissionBlock:AddEventListener ("RequestRemoveGroupEntry",      tostring (self), self.RequestRemoveGroupEntry)
	permissionBlock:AddEventListener ("RequestSetGroupPermission",    tostring (self), self.RequestSetGroupPermission)
	permissionBlock:AddEventListener ("RequestSetInheritOwner",       tostring (self), self.RequestSetInheritOwner)
	permissionBlock:AddEventListener ("RequestSetInheritPermissions", tostring (self), self.RequestSetInheritPermissions)
	permissionBlock:AddEventListener ("RequestSetOwner",              tostring (self), self.RequestSetOwner)
	
	if SERVER then self:HookBlock (permissionBlock) end
end

function self:UnhookBlock (permissionBlock)
	ErrorNoHalt (self.SystemName .. ".PermissionBlockNetworker:UnhookBlock : " .. permissionBlock:GetName () .. "\n")
	
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
		
		Sends a series of notifications that will synchronize the state of a
		remote permission block to match the given local permission block.
]]
function self:SynchronizeBlock (destUserId, permissionBlock)
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
	
	for _, session in ipairs (notifications) do
		GAuth.EndPointManager:GetEndPoint (destUserId):SendNotification (GAuth.Protocol.PermissionBlockNotification (self:GetSystemName (), permissionBlock, session))
	end
end

function self:GetSystemName ()
	return self.SystemName
end

--[[
	PermissionBlockNetworker:HandleNotification (EndPoint remoteEndPoint, PermissionBlock permissionBlock, InBuffer inBuffer)
		Returns: PermissionBlockResponse response
]]
function self:HandleNotification (remoteEndPoint, permissionBlockId, inBuffer)
	local typeId = inBuffer:UInt32 ()
	local packetType = GAuth.Protocol.StringTable:StringFromHash (typeId)
	
	local permissionBlock = self:ResolvePermissionBlock (permissionBlockId)
	if not permissionBlock then return end
	if not self:ShouldProcessNotification (remoteEndPoint:GetRemoteId (), permissionBlockId, permissionBlock) then return end
	
	local ctor = GAuth.Protocol.ResponseTable [packetType]
	if not ctor then
		ErrorNoHalt (self:GetSystemName () .. ".PermissionBlockNetworker:HandleNotification : No handler for " .. tostring (packetType) .. " is registered!")
		return
	end
	
	local session = ctor (permissionBlock)
	session:SetRemoteEndPoint (remoteEndPoint)
	session:HandleInitialPacket (inBuffer)
	return session
end

--[[
	PermissionBlockNetworker:HandleRequest (EndPoint remoteEndPoint, PermissionBlock permissionBlock, InBuffer inBuffer)
		Returns: PermissionBlockResponse response
]]
function self:HandleRequest (permissionBlockResponse, permissionBlockId, inBuffer)
	local typeId = inBuffer:UInt32 ()
	local packetType = GAuth.Protocol.StringTable:StringFromHash (typeId)
	
	local permissionBlock = self:ResolvePermissionBlock (permissionBlockId)
	if not permissionBlock then return end
	
	local ctor = GAuth.Protocol.ResponseTable [packetType]
	if not ctor then
		ErrorNoHalt (self:GetSystemName () .. ".PermissionBlockNetworker:HandleRequest : No handler for " .. tostring (packetType) .. " is registered!")
		return
	end
	
	local session = ctor (permissionBlock)
	session:SetId (permissionBlockResponse:GetId ())
	session:SetRemoteEndPoint (permissionBlockResponse:GetRemoteEndPoint ())
	session:HandleInitialPacket (inBuffer)
	return session
end

function self:ResolvePermissionBlock (permissionBlockId)
	return self.ResolverFunction (permissionBlockId)
end

function self:ShouldProcessNotification (remoteId, permissionBlockId, permissionBlock)
	return self.NotificationFilter (remoteId, permissionBlockId, permissionBlock)
end

function self:ShouldSendRequest (permissionBlock)
	local sendRequest, destUserId = self.RequestFilter (permissionBlock)
	if sendRequest and not destUserId then
		GAuth.Error (self:GetSystemName () .. ".PermissionBlockNetworker : Request filter did not return a destination user id!")
		sendRequest = false
	end
	return sendRequest, destUserId
end

function self:SetNotificationFilter (notificationFilter)
	self.NotificationFilter = notificationFilter or function () return true end
end

function self:SetRequestFilter (requestFilter)
	self.RequestFilter = requestFilter or function () return false end
end

function self:SetResolver (resolver)
	self.ResolverFunction = resolver or GAuth.NullCallback
end

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