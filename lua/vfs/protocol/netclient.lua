local self = {}
VFS.Protocol.NetClient = VFS.MakeConstructor (self, GLib.Protocol.EndPoint)

function self:ctor (remoteId, systemName)
	self.Root = VFS.NetFolder (self, "", "")
	self.Root:FlagAsPredicted()
	
	self.DataChannel = "vfs_request_data"
	self.NewSessionChannel = "vfs_new_request"
	self.NotificationChannel = "vfs_notification"
end

function self:GetRoot ()
	return self.Root
end