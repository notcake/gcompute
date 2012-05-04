local self = {}
GLib.Protocol.NetClientManager = GLib.MakeConstructor (self)

--[[
	NetClientManager
	
		Holds NetClients for interacting with remote NetServers.
]]

function self:ctor (systemName, clientConstructor)
	self.SystemName = systemName
	self.ClientConstructor = clientConstructor
	self.Clients = {}
end

--[[
	NetClientManager:CreateClient (serverId)
		Returns: NetClient clientForServerId
]]
function self:CreateClient (serverId)
	return self:GetClientConstructor () (serverId, self:GetSystemName ())
end

--[[
	NetClientManager:GetClient (serverId)
		Returns: NetClient clientForServerId
]]
function self:GetClient (serverId)
	if not self.Clients [serverId] then
		self.Clients [serverId] = self:CreateClient (serverId)
	end
	return self.Clients [serverId]
end

function self:GetClientConstructor ()
	return self.ClientConstructor or GLib.Protocol.NetClient
end

function self:GetSystemName ()
	return self.SystemName
end