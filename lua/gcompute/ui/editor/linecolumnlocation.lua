local self = {}
GCompute.Editor.LineColumnLocation = GCompute.MakeConstructor (self)

function self:ctor (line, column)
	self.Line = 0
	self.Column = 0
	
	if type (line) == "table" then
		self:CopyFrom (line)
	else
		self:SetLine (line or self.Line)
		self:SetColumn (column or self.Column)
	end
end

function self:AddColumns (columns)
	local lineColumnLocation    = GCompute.Editor.LineColumnLocation ()
	lineColumnLocation.Line     = self.Line
	lineColumnLocation.Column   = math.max (0, self.Column + columns)
	
	return lineColumnLocation
end

function self:Clone ()
	return GCompute.Editor.LineColumnLocation (self.Line, self.Column)
end

function self:CopyFrom (lineColumnLocation)
	self.Line     = lineColumnLocation.Line     or 0
	self.Column   = lineColumnLocation.Column   or 0
end

function self:Equals (lineColumnLocation)
	return self.Line     == lineColumnLocation.Line     and
	       self.Column   == lineColumnLocation.Column
end

function self:GetColumn ()
	return self.Column
end

function self:GetLine ()
	return self.Line
end

function self:IsAfter (lineColumnLocation)
	if self.Line < lineColumnLocation.Line then return false end
	if self.Line > lineColumnLocation.Line then return true end
	if self.Column > lineColumnLocation.Column then return true end
	return false
end

function self:IsBefore (lineColumnLocation)
	if self.Line < lineColumnLocation.Line then return true end
	if self.Line > lineColumnLocation.Line then return false end
	if self.Column < lineColumnLocation.Column then return true end
	return false
end

function self:IsEqualOrAfter (lineColumnLocation)
	if self.Line < lineColumnLocation.Line then return false end
	if self.Line > lineColumnLocation.Line then return true end
	if self.Column >= lineColumnLocation.Column then return true end
	return false
end

function self:IsEqualOrBefore (lineColumnLocation)
	if self.Line < lineColumnLocation.Line then return true end
	if self.Line > lineColumnLocation.Line then return false end
	if self.Column <= lineColumnLocation.Column then return true end
	return false
end

function self:SetColumn (column)
	if column < 0 then GCompute.PrintStackTrace () column = 0 end
	self.Column = column
end

function self:SetLine (line)
	if line < 0 then GCompute.PrintStackTrace () line = 0 end
	self.Line = line
end

function self:ToString ()
	return "Line " .. tostring (self.Line) .. ", col " .. tostring (self.Column)
end