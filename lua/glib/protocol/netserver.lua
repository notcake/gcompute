local self = {}
GLib.Protocol.NetServer = GLib.MakeConstructor (self)

function self:ctor (systemName, clientConstructor)
	self.SystemName = systemName
	self.ClientConstructor = clientConstructor
	self.Clients = {}
end

function self:AddClient (clientId)
	if not self.Clients [clientId] then
		self.Clients [clientId] = self:CreateClient (clientId)
	end
	
	return self.Clients [clientId]
end

--[[
	NetServer:CreateClient (clientId)
		Returns NetServerClient clientForClientId
]]
function self:CreateClient (clientId)
	return self:GetClientConstructor () (self, clientId, self:GetSystemName ())
end

function self:GetClient (clientId)
	if not self.Clients [clientId] then
		self.Clients [clientId] = self:CreateClient (clientId)
	end
	
	return self.Clients [clientId]
end

function self:GetClientConstructor ()
	return self.ClientConstructor
end

function self:GetSystemName ()
	return self.SystemName
end