local self = {}
GLib.Protocol.Response = GLib.MakeConstructor (self, GLib.Protocol.Session)

function self:ctor ()
end

function self:HandleInitialPacket (inBuffer)
end