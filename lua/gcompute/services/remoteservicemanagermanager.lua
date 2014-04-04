local self = {}
GCompute.Services.RemoteServiceManagerManager = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Endpoints = {}
	
	-- Networking
	self.Channel = GLib.Net.Layer5.RegisterOrderedChannel ("gcompute")
	self.EndpointChannelMultiplexer = GLib.Net.EndpointChannelMultiplexer (self.Channel)
	
	self.EndpointChannelMultiplexer:AddEventListener ("SingleEndpointChannelCreated",
		function (_, singleEndpointChannel)
			local remoteId = singleEndpointChannel:GetRemoteId ()
			self.Endpoints [remoteId] = GCompute.Services.RemoteServiceManager (remoteId, singleEndpointChannel)
		end
	)
	
	GCompute.PlayerMonitor:AddEventListener ("PlayerDisconnected", "GCompute.RemoteServiceManagerManager",
		function (_, ply, userId)
			if not self.Endpoints [userId] then return end
			
			self.Endpoints [userId]:dtor ()
			self.Endpoints [userId] = nil
			
			self.EndpointChannelMultiplexer:DestroySingleEndpointChannel (userId)
		end
	)
	
	GCompute:AddEventListener ("Unloaded", "GCompute.RemoteServiceManagerManager",
		function ()
			self:dtor ()
		end
	)
end

function self:dtor ()
	GCompute.PlayerMonitor:RemoveEventListener ("PlayerDisconnected", "GCompute.RemoteServiceManagerManager")
	
	self.EndpointChannelMultiplexer:dtor ()
	self.Channel:dtor ()
	
	GCompute:RemoveEventListener ("Unloaded", "GCompute.RemoteServiceManagerManager")
end

GCompute.Services.RemoteServiceManagerManager = GCompute.Services.RemoteServiceManagerManager ()