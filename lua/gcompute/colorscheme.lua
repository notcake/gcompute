local self = {}
GCompute.ColorScheme = GCompute.MakeConstructor (self, GLib.Serialization.ISerializable)

--[[
	Events:
		Changed ()
			Fired when the color scheme has been changed.
		ColorChanged (id, Color color)
			Fired when a color has been changed.
]]

function self:ctor ()
	self.Colors = {}
	
	GCompute.EventProvider (self)
end

-- ISerializable
function self:Serialize (outBuffer)
	outBuffer:StringZ (self:ToString ())
	
	return outBuffer
end

function self:Deserialize (inBuffer)
	local str = inBuffer:StringZ ()
	
	for line in GLib.String.LineIterator (str) do
		local left, right = string.match (line, "([a-zA-Z_][a-zA-Z_0-9]*)[ \t]*=[ \t]*(.-)[ \t]*$")
		
		if left then
			local r, g, b, a = string.match (right, "Color[ \t]*%([ \t]*([0-9]+),[ \t]*([0-9]+),[ \t]*([0-9]+),[ \t]*([0-9]+)%)")
			if not r then
				r, g, b = string.match (right, "Color[ \t]*%([ \t]*([0-9]+),[ \t]*([0-9]+),[ \t]*([0-9]+)%)")
			end
			
			if r then
				a = a or 255
				self:SetColor (left, Color (r, g, b, a))
			else
				local name = string.match (right, "[a-zA-Z_][a-zA-Z0-9]*")
				local color = GLib.Color.FromName (name)
				if color then
					self:SetColor (left, color)
				end
			end
		end
	end
	
	return self
end

-- ColorScheme
function self:Clone (clone)
	clone = clone or self.__ictor ()
	
	clone:Copy (self)
	
	return clone
end

function self:Copy (source)
	for id, color in source:GetColorEnumerator () do
		self:SetColor (id, color)
	end
	
	return self
end

function self:GetColor (id)
	return self.Colors [id]
end

function self:GetColorEnumerator ()
	return GLib.KeyValueEnumerator (self.Colors)
end

function self:SetColor (id, color)
	self.Colors [id] = color
	
	if id ~= "Colors" and
	   not self.__base [id] and
	   not isfunction (self [id]) then
		self [id] = color
	end
	
	self:DispatchEvent ("ColorChanged", id, self.Colors [id])
	self:DispatchEvent ("Changed")
	return self
end

function self:ToString ()
	local colorScheme = "{\n"
	
	local sortedKeys = {}
	local maxKeyLength = 0
	for id, _ in pairs (self.Colors) do
		sortedKeys [#sortedKeys + 1] = id
		maxKeyLength = math.max (maxKeyLength, #id)
	end
	table.sort (sortedKeys)
	
	for i = 1, #sortedKeys do
		local id    = sortedKeys [i]
		local color = self.Colors [id]
		
		local colorString = GLib.Color.GetName (color) or string.format ("Color (%3d, %3d, %3d, %3d)", color.r, color.g, color.b, color.a)
		colorScheme = colorScheme .. "\t" .. id .. string.rep (" ", maxKeyLength - #id) .. " = " .. colorString .. ",\n"
	end
	
	colorScheme = colorScheme .. "}"
	
	return colorScheme
end