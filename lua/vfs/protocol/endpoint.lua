local self = {}
VFS.Protocol.EndPoint = VFS.MakeConstructor (self, GLib.Protocol.EndPoint)

function self:ctor (remoteId, systemName)
	self.Root = VFS.NetFolder (self, "")
	self.HookedNodes = VFS.WeakKeyTable ()
	
	self.DataChannel = "vfs_session_data"
	self.NewSessionChannel = "vfs_new_session"
	self.NotificationChannel = "vfs_notification"
	
	self.NodeCreated = function (folder, childNode)
		if not folder:GetPermissionBlock ():IsAuthorized (self:GetRemoteId (), "View Folder") then return end
	
		self:SendNotification (VFS.Protocol.NodeCreationNotification (folder, childNode))
	end
	
	self.NodeDeleted = function (folder, childNode)
		if not folder:GetPermissionBlock ():IsAuthorized (self:GetRemoteId (), "View Folder") then return end
	
		self:UnhookNode (childNode)
		self:SendNotification (VFS.Protocol.NodeDeletionNotification (folder, childNode))
	end
	
	self.NodeRenamed = function (folder, childNode, oldName, newName)
		if not folder:GetPermissionBlock ():IsAuthorized (self:GetRemoteId (), "View Folder") then return end
	
		self:SendNotification (VFS.Protocol.NodeRenameNotification (folder, oldName, newName))
	end
	
	self.NodeUpdated = function (folder, childNode, updateFlags)
		if not folder:GetPermissionBlock ():IsAuthorized (self:GetRemoteId (), "View Folder") then return end
	
		self:SendNotification (VFS.Protocol.NodeUpdateNotification (childNode, updateFlags))
	end
end

function self:dtor ()
	for node, _ in pairs (self.HookedNodes) do
		self:UnhookNode (node)
	end
end

function self:GetRoot ()
	return self.Root
end

function self:HookNode (node)
	if self.HookedNodes [node] then return end
	self.HookedNodes [node] = true
	
	node:AddEventListener ("NodeCreated", tostring (self), self.NodeCreated)
	node:AddEventListener ("NodeDeleted", tostring (self), self.NodeDeleted)
	node:AddEventListener ("NodeRenamed", tostring (self), self.NodeRenamed)
	node:AddEventListener ("NodeUpdated", tostring (self), self.NodeUpdated)
	
	VFS.Debug ("VFS.EndPoint:HookNode : " .. node:GetPath ())
end

function self:IsNodeHooked (node)
	if self.HookedNodes [node] then return true end
	if node:GetParentFolder () and self.HookedNodes [node:GetParentFolder ()] then return true end
	return false
end

function self:UnhookNode (node)
	node:RemoveEventListener ("NodeCreated", tostring (self))
	node:RemoveEventListener ("NodeDeleted", tostring (self))
	node:RemoveEventListener ("NodeRenamed", tostring (self))
	node:RemoveEventListener ("NodeUpdated", tostring (self))
	
	VFS.Debug ("VFS.EndPoint:UnhookNode : " .. node:GetPath ())
end

self.NodeCreated = VFS.NullCallback
self.NodeDeleted = VFS.NullCallback
self.NodeRenamed = VFS.NullCallback
self.NodeUpdated = VFS.NullCallback