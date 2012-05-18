local self = {}
GLib.Net.DatastreamInBuffer = GLib.MakeConstructor (self)

function self:ctor (data)
	self.Data = data
	self.NextReadIndex = 1
end

function self:UInt8 ()
	self.NextReadIndex = self.NextReadIndex + 1
	return tonumber (self.Data [self.NextReadIndex - 1]) or 0
end

function self:UInt16 ()
	self.NextReadIndex = self.NextReadIndex + 1
	return tonumber (self.Data [self.NextReadIndex - 1]) or 0
end

function self:UInt32 ()
	self.NextReadIndex = self.NextReadIndex + 1
	return tonumber (self.Data [self.NextReadIndex - 1]) or 0
end

function self:Int8 ()
	self.NextReadIndex = self.NextReadIndex + 1
	return tonumber (self.Data [self.NextReadIndex - 1]) or 0
end

function self:Int16 ()
	self.NextReadIndex = self.NextReadIndex + 1
	return tonumber (self.Data [self.NextReadIndex - 1]) or 0
end

function self:Int32 ()
	self.NextReadIndex = self.NextReadIndex + 1
	return tonumber (self.Data [self.NextReadIndex - 1]) or 0
end

function self:String ()
	self.NextReadIndex = self.NextReadIndex + 1
	return tostring (self.Data [self.NextReadIndex - 1])
end

function self:Boolean ()
	self.NextReadIndex = self.NextReadIndex + 1
	return self.Data [self.NextReadIndex - 1] and true or false
end