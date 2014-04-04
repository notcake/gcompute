local self = {}
GCompute.Services.RemoteServiceManager = GCompute.MakeConstructor (self)

function self:ctor (remoteId, singleEndpointChannel)
	self.RemoteId = remoteId
	self.Channel = singleEndpointChannel
	
	self.NetworkableHost = GLib.Networking.NetworkableHost ()
	self.NetworkableHost:SetChannel (self.Channel)
end

function self:dtor ()
	self.NetworkableHost:dtor ()
end

-- Identity
function self:GetRemoteId ()
	return self.RemoteId
end