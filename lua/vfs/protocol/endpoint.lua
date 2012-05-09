local self = {}
VFS.Protocol.EndPoint = VFS.MakeConstructor (self, GLib.Protocol.EndPoint)

function self:ctor (remoteId, systemName)
	self.Root = VFS.NetFolder (self, "", "")
	
	self.DataChannel = "vfs_session_data"
	self.NewSessionChannel = "vfs_new_session"
	self.NotificationChannel = "vfs_notification"
end

function self:GetRoot ()
	return self.Root
end