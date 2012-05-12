local self = {}
GLib.Net.UsermessageDispatcher = GLib.MakeConstructor (self)

function self:ctor ()
end

function self:Dispatch (ply, channelName, packet)
	umsg.Start (channelName, ply)
		for i = 1, #packet.Data do
			local data = packet.Data [i]
			local typeId = packet.Types [i]
			
			self [GLib.Net.DataType [typeId]] (self, data)
		end
	umsg.End ()
end

function self:UInt8 (n)
	umsg.Char (n - 128)
end

function self:UInt16 (n)
	umsg.Short (n - 32768)
end

function self:UInt32 (n)
	umsg.Long (n - 2147483648)
end

function self:UInt64 (n)
	umsg.Long ((n % 4294967296) - 2147483648)
	umsg.Long (math.floor (n / 4294967296) - 2147483648)
end

function self:Int8 (n)
	umsg.Char (n)
end

function self:Int16 (n)
	umsg.Short (n)
end

function self:Int32 (n)
	umsg.Long (n)
end

function self:String (data)
	umsg.String (data)
end

function self:Boolean (b)
	umsg.Char (b and 1 or 0)
end

GLib.Net.UsermessageDispatcher = GLib.Net.UsermessageDispatcher ()