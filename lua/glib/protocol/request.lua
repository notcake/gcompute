local self = {}
GLib.Protocol.Request = GLib.MakeConstructor (self, GLib.Protocol.Session)

function self:ctor ()
end

function self:GenerateInitialPacket (outBuffer)
end

-- overrideable
function self:HandlePacket (inBuffer)
end