local self = {}
VFS.Protocol.EndPoint = VFS.MakeConstructor (self, GLib.Protocol.EndPoint)

function self:ctor (remoteId, systemName)
	self.Root = VFS.NetFolder (self, "")
	self.HookedNodes = VFS.WeakKeyTable ()
	
	self.DataChannel = "vfs_session_data"
	self.NewSessionChannel = "vfs_new_session"
	self.NotificationChannel = "vfs_notification"
end

function self:GetRoot ()
	return self.Root
end

function self:HookNode (node)
	if self.HookedNodes [node] then return end
	self.HookedNodes [node] = true
end

function self:IsNodeHooked (node)
	if self.HookedNodes [node] then return true end
	if node:GetParentFolder () and self.HookedNodes [node:GetParentFolder ()] then return true end
	return node
end

function self:UnhookNode (node)
	node:RemoveEventListener ("NodeCreated", tostring (self))
	node:RemoveEventListener ("NodeDeleted", tostring (self))
	node:RemoveEventListener ("NodeRenamed", tostring (self))
	node:RemoveEventListener ("NodeUpdated", tostring (self))
end