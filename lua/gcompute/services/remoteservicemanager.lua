local self = {}
GCompute.Services.RemoteServiceManager = GCompute.MakeConstructor (self)

function self:ctor (remoteId, singleEndpointChannel)
	-- Identity
	self.RemoteId = remoteId
	
	-- Services
	self.ServiceHosts = {}
	self.ServiceClients = {}
	self.UnavailableServiceClients = {}
	
	-- Networking
	self.SingleEndpointChannel = singleEndpointChannel
	self.Channel = GLib.Net.SingleEndpointChannelToChannelAdapter (self.SingleEndpointChannel)
	self.ConnectionRunner = GCompute.Services.ConnectionRunner
	
	self.NetworkableHost = GLib.Networking.NetworkableHost ()
	self.NetworkableHost:SetChannel (self.Channel)
	self.NetworkableHost:SetConnectionRunner (self.ConnectionRunner)
	
	self.NetworkableHost:AddEventListener ("CustomPacketReceived",
		function (_, sourceId, inBuffer)
			local connectionId = inBuffer:UInt32 ()
			
			if connectionId == 0 then
				self:Reset ()
				return
			end
			
			local connection = self.NetworkableHost:CreateConnection (sourceId, GLib.Net.ConnectionEndpoint.Remote, connectionId)
			
			inBuffer:String () -- " つ ◕_◕ ༽つ VOLVO PLS GIFF"
			local serviceName = inBuffer:String ()
			
			-- Create service host
			if not self.ServiceHosts [serviceName] then
				local serviceHost = GCompute.Services.RemoteServiceRegistry:CreateServiceHost (serviceName)
				
				if serviceHost then
					self.ServiceHosts [serviceName] = serviceHost
					
					if serviceHost.SetRemoteId then
						serviceHost:SetRemoteId (sourceId)
					end
					
					self.NetworkableHost:RegisterNetworkable (serviceHost)
				end
			end
			
			-- Dispatch response
			local outBuffer = GLib.Net.OutBuffer ()
			local serviceHost = self.ServiceHosts [serviceName]
			if serviceHost then
				outBuffer:Boolean (true)
				outBuffer:UInt32 (self.NetworkableHost:GetNetworkableId (serviceHost))
			else
				outBuffer:Boolean (false)
			end
			
			connection:Write (outBuffer)
			connection:Close ()
		end
	)
end

function self:dtor ()
	self:DispatchResetPacket ()
	
	for networkable in self.NetworkableHost:GetNetworkableEnumerator () do
		networkable:dtor ()
	end
	
	self.NetworkableHost:dtor ()
end

-- Identity
function self:GetRemoteId ()
	return self.RemoteId
end

-- Services
function self:GetRemoteService (serviceName, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	-- Check cache
	if self.UnavailableServiceClients [serviceName] then
		return nil, GCompute.ReturnCode.NotSupported
	end
	
	if self.ServiceClients [serviceName] then
		return self.ServiceClients [serviceName]
	end
	
	-- Check that the service exissts
	if not GCompute.Services.RemoteServiceRegistry:CanCreateServiceClient (serviceName) then
		return nil, GCompute.ReturnCode.NotSupported
	end
	
	-- Create request session
	local connection = self.NetworkableHost:CreateConnection (self:GetRemoteId (), GLib.Net.ConnectionEndpoint.Local)
	
	-- Create request
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (connection:GetId ())
	outBuffer:String (" つ ◕_◕ ༽つ VOLVO PLS GIFF")
	outBuffer:String (serviceName)
	
	-- Dispatch request
	self.NetworkableHost:DispatchCustomPacket (self:GetRemoteId (), outBuffer)
	
	-- Wait for response
	local inBuffer = connection:Read ()
	connection:Close ()
	
	if not inBuffer then return nil, GCompute.ReturnCode.Timeout end
	
	if not self.ServiceClients [serviceName] then
		-- Process response
		local success = inBuffer:Boolean ()
		
		if not success then
			self.UnavailableServiceClients [serviceName] = true
			return nil, GCompute.ReturnCode.NotSupported
		end
		
		local networkableId = inBuffer:UInt32 ()
		local serviceClient = GCompute.Services.RemoteServiceRegistry:CreateServiceClient (serviceName)
		
		-- serviceClient should not be nil, since we checked that the service client can be created earlier	
		self.ServiceClients [serviceName] = serviceClient
		
		if serviceClient.SetRemoteId then
			serviceClient:SetRemoteId (self:GetRemoteId ())
		end
		
		self.NetworkableHost:RegisterNetworkable (serviceClient, networkableId)
	end
	
	return self.ServiceClients [serviceName]
end

-- Internal, do not call
function self:DispatchResetPacket ()
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (0)
	self.NetworkableHost:DispatchCustomPacket (self:GetRemoteId (), outBuffer)
	
	GCompute.Debug ("RemoteServiceManager:DispatchResetPacket ()")
end

function self:Reset ()
	GCompute.Debug ("RemoteServiceManager:Reset ()")
	
	if self.NetworkableHost:GetNetworkableCount () == 0 and
	   not next (self.ServiceClients) and
	   not next (self.ServiceHosts) then
		return
	end
	
	for networkable in self.NetworkableHost:GetNetworkableEnumerator () do
		networkable:dtor ()
	end
	
	self.NetworkableHost:ClearNetworkables ()
	
	self.ServiceClients = {}
	self.ServiceHosts   = {}
	
	self:DispatchResetPacket ()
end