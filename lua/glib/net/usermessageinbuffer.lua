local self = {}
GLib.Net.UsermessageInBuffer = GLib.MakeConstructor (self)

function self:ctor (umsg)
	self.Usermessage = umsg
end

function self:UInt8 ()
	return self.Usermessage:ReadChar () + 128
end

function self:UInt16 ()
	return self.Usermessage:ReadShort () + 32768
end

function self:UInt32 ()
	return self.Usermessage:ReadLong () + 2147483648
end

function self:Int8 ()
	return self.Usermessage:ReadChar ()
end

function self:Int16 ()
	return self.Usermessage:ReadShort ()
end

function self:Int32 ()
	return self.Usermessage:ReadLong ()
end

function self:String ()
	return self.Usermessage:ReadString ()
end

function self:Boolean ()
	return self.Usermessage:ReadChar () ~= 0
end