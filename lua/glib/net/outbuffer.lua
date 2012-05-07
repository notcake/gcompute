local self = {}
GLib.Net.OutBuffer = GLib.MakeConstructor (self)

function self:ctor ()
	self.Data = {}
	self.Types = {}
	
	self.NextDataId = 1
	self.Size = 0
end

for typeName, enumValue in pairs (GLib.Net.DataType) do
	self [typeName] = function (self, n)
		self.Data [self.NextDataId] = n
		self.Types [self.NextDataId] = enumValue
		self.NextDataId = self.NextDataId + 1
		
		local typeSize = GLib.Net.DataTypeSizes [typeName]
		if type (typeSize) == "number" then
			self.Size = self.Size + typeSize
		else
			self.Size = self.Size + typeSize (n)
		end
	end
end

function self:GetSize ()
	return self.Size
end

--[[
	OutBuffer:OutBuffer (OutBuffer outBuffer)
	
		Appends the contents of outBuffer to this OutBuffer
]]
function self:OutBuffer (outBuffer)
	for i = 1, #outBuffer.Data do
		self.Data [self.NextDataId] = outBuffer.Data [i]
		self.Types [self.NextDataId] = outBuffer.Types [i]
		self.NextDataId = self.NextDataId + 1
	end
	
	self.Size = self.Size + outBuffer:GetSize ()
end