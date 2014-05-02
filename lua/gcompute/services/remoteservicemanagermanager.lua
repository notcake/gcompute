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
	for userId, remoteServiceManager in pairs (self.Endpoints) do
		remoteServiceManager:dtor ()
		self.Endpoints [userId] = nil
	end
	
	GCompute.PlayerMonitor:RemoveEventListener ("PlayerDisconnected", "GCompute.RemoteServiceManagerManager")
	
	self.EndpointChannelMultiplexer:dtor ()
	self.Channel:dtor ()
	
	GCompute:RemoveEventListener ("Unloaded", "GCompute.RemoteServiceManagerManager")
end

function self:GetRemoteService (remoteId, serviceName, callback)
	local remoteServiceManager = self:GetRemoteServiceManager (remoteId)
	
	if not remoteServiceManager then
		if callback then callback (nil, GCompute.ReturnCode.NoCarrier) end
		return nil, GCompute.ReturnCode.NoCarrier
	end
	
	return remoteServiceManager:GetRemoteService (serviceName, callback)
end

function self:GetRemoteServiceManager (remoteId)
	if not self.Endpoints [remoteId] then
		if not GCompute.PlayerMonitor:GetUserEntity (remoteId) and
		   remoteId ~= GLib.GetServerId () then
			GLib.Error ("RemoteServiceManagerManager:GetRemoteServiceManager : Remote endpoint " .. remoteId .. " is invalid!")
		end
		self.EndpointChannelMultiplexer:CreateSingleEndpointChannel (remoteId)
	end
	
	return self.Endpoints [remoteId]
end

function self:IsAvailable ()
	return self.Channel:IsOpen ()
end

GCompute.Services.RemoteServiceManagerManager = GCompute.Services.RemoteServiceManagerManager ()