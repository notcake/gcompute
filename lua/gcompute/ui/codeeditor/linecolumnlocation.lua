local self = {}
GCompute.CodeEditor.LineColumnLocation = GCompute.MakeConstructor (self)

function self:ctor (line, column)
	self.Line   = 0
	self.Column = 0
	
	if type (line) == "table" then
		self:Copy (line)
	else
		self:SetLine (line or self.Line)
		self:SetColumn (column or self.Column)
	end
end

function self:Clone (clone)
	clone = clone or self.__ictor ()
	
	clone:Copy (self)
	
	return clone
end

function self:Copy (source)
	self.Line     = source:GetLine ()    or 0
	self.Column   = source:GetColumn ()  or 0
	
	return self
end

function self:AddColumns (columns)
	local lineColumnLocation    = GCompute.CodeEditor.LineColumnLocation ()
	lineColumnLocation.Line     = self.Line
	lineColumnLocation.Column   = math.max (0, self.Column + columns)
	
	return lineColumnLocation
end

function self:GetColumn ()
	return self.Column
end

function self:GetLine ()
	return self.Line
end

function self:IsLineCharacterLocation ()
	return false
end

function self:IsLineColumnLocation ()
	return true
end

function self:SetColumn (column)
	self.Column = column
end

function self:SetLine (line)
	self.Line = line
end

function self:ToString ()
	return "Line " .. tostring (self.Line) .. ", col " .. tostring (self.Column)
end

function self:__eq (lineColumnLocation)
	return self.Line     == lineColumnLocation.Line     and
	       self.Column   == lineColumnLocation.Column
end

function self:__le (lineColumnLocation)
	if self.Line < lineColumnLocation.Line then return true end
	if self.Line > lineColumnLocation.Line then return false end
	if self.Column <= lineColumnLocation.Column then return true end
	return false
end

function self:__lt (lineColumnLocation)
	if self.Line < lineColumnLocation.Line then return true end
	if self.Line > lineColumnLocation.Line then return false end
	if self.Column < lineColumnLocation.Column then return true end
	return false
end

function self:__add (lineColumnLocation)
	return GCompute.CodeEditor.LineColumnLocation (
		self.Line   + lineColumnLocation.Line,
		self.Column + lineColumnLocation.Column
	)
end

function self:__sub (lineColumnLocation)
	return GCompute.CodeEditor.LineColumnLocation (
		self.Line   - lineColumnLocation.Line,
		self.Column - lineColumnLocation.Column
	)
end