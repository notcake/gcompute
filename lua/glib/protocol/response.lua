local self = {}
GLib.Protocol.Response = GLib.MakeConstructor (self, GLib.Protocol.Session)

function self:ctor ()
	self.Server = nil	-- NetServer
	self.Client = nil	-- NetServerClient
end

--[[
	Response:GetClient ()
		Returns: NetServerClient netServerClient
]]
function self:GetClient ()
	return self.Client
end

--[[
	Response:GetClient ()
		Returns: NetServer netServer
]]
function self:GetServer ()
	return self.Server
end

function self:HandleInitialPacket (inBuffer)
end

--[[
	Response:SetClient (NetServerClient netServerClient)
]]
function self:SetClient (netServerClient)
	self.Client = netServerClient
end

--[[
	Response:SetServer (NetServer netServer)
]]
function self:SetServer (netServer)
	self.Server = netServer
end