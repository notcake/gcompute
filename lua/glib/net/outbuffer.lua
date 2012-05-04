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