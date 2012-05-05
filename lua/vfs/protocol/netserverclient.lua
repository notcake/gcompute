local self = {}
VFS.Protocol.NetServerClient = VFS.MakeConstructor (self, GLib.Protocol.EndPoint)

function self:ctor (remoteId, systemName)
	self.DataChannel = "vfs_response_data"
	self.NewSessionChannel = "vfs_new_request"
	self.NotificationChannel = "vfs_notification"
end