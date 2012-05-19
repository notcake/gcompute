local self = {}
GLib.Net.ConCommandInBuffer = GLib.MakeConstructor (self)

local unescapeTable =
{
	["\\"] = "\\",
	["0"]  = "\0",
	["t"]  = "\t",
	["r"]  = "\r",
	["n"]  = "\n",
	["q"]  = "\""
}

function self:ctor (data)
	self.Data = data:gsub ("\\(.)", unescapeTable)
	self.Position = 1
end

function self:UInt8 ()
	local n = string.byte (self.Data:sub (self.Position, self.Position)) or 0
	self.Position = self.Position + 1
	return n
end

function self:UInt16 ()
	local n = string.byte (self.Data:sub (self.Position, self.Position)) or 0
	n = n + (string.byte (self.Data:sub (self.Position + 1, self.Position + 1)) or 0) * 256
	self.Position = self.Position + 2
	return n
end

function self:UInt32 ()
	local n = string.byte (self.Data:sub (self.Position, self.Position)) or 0
	n = n + (string.byte (self.Data:sub (self.Position + 1, self.Position + 1)) or 0) * 256
	n = n + (string.byte (self.Data:sub (self.Position + 2, self.Position + 2)) or 0) * 65536
	n = n + (string.byte (self.Data:sub (self.Position + 3, self.Position + 3)) or 0) * 16777216
	self.Position = self.Position + 4
	return n
end

function self:UInt64 ()
	local n = string.byte (self.Data:sub (self.Position, self.Position))
	n = n + (string.byte (self.Data:sub (self.Position + 1, self.Position + 1)) or 0) * 256
	n = n + (string.byte (self.Data:sub (self.Position + 2, self.Position + 2)) or 0) * 65536
	n = n + (string.byte (self.Data:sub (self.Position + 3, self.Position + 3)) or 0) * 16777216
	n = n + (string.byte (self.Data:sub (self.Position + 4, self.Position + 4)) or 0) * 4294967296
	n = n + (string.byte (self.Data:sub (self.Position + 5, self.Position + 5)) or 0) * 1099511627776
	n = n + (string.byte (self.Data:sub (self.Position + 6, self.Position + 6)) or 0) * 281474976710656
	n = n + (string.byte (self.Data:sub (self.Position + 7, self.Position + 7)) or 0) * 72057594037927936
	self.Position = self.Position + 8
	return n
end

function self:Int8 ()
	return self:UInt8 () - 128
end

function self:Int16 ()
	return self:UInt16 () - 32768
end

function self:Int32 ()
	return self:UInt32 () - 2147483648
end

function self:Int64 ()
	return self:UInt64 () - 2305843009213693952
end

function self:String ()
	local length = self:UInt16 ()
	local str = self.Data:sub (self.Position, self.Position + length - 1)
	self.Position = self.Position + length
	return str
end

function self:Boolean ()
	return self:UInt8 () == 2
end