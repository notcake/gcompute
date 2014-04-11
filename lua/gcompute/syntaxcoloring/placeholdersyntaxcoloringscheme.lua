local self = {}
GCompute.SyntaxColoring.PlaceholderSyntaxColoringScheme = GCompute.MakeConstructor (self, GCompute.SyntaxColoring.SyntaxColoringScheme)

function self:ctor ()
	self.CRCsToNames = {}
	
	for id, _ in pairs (self.Colors) do
		local crc = tonumber (util.CRC (id))
		self.CRCsToNames [crc] = id
		self:SetColor (id, GLib.Color.FromArgb (crc))
	end
end

function self:GetIdFromColor (color)
	if not isnumber (color) then
		color = GLib.Color.ToArgb (color)
	end
	
	return self.CRCsToNames [color]
end

function self:__call ()
	return self:Clone (GCompute.SyntaxColoring.PlaceholderSyntaxColoringScheme ())
end

GCompute.SyntaxColoring.PlaceholderSyntaxColoringScheme = GCompute.SyntaxColoring.PlaceholderSyntaxColoringScheme ()