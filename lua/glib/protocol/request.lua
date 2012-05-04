local self = {}
GLib.Protocol.Request = GLib.MakeConstructor (self, GLib.Protocol.Session)

function self:ctor ()
	self.NetClient = nil	-- NetClient
end

function self:GenerateInitialPacket (outBuffer)
end

function self:GetNetClient ()
	return self.NetClient
end

-- overrideable
function self:HandleResponse (inBuffer)
end

function self:SetNetClient (netClient)
	self.NetClient = netClient
end