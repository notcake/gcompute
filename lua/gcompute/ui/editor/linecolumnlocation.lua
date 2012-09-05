local self = {}
GCompute.Editor.LineColumnLocation = GCompute.MakeConstructor (self)

function self:ctor (line, column)
	self.FilePath = ""
	self.Line = 0
	self.Column = 0
	
	if type (line) == "table" then
		self:CopyFrom (line)
	else
		self:SetLine (line or self.Line)
		self:SetColumn (column or self.Column)
	end
end

function self:CopyFrom (lineColumnLocation)
	self.FilePath = lineColumnLocation.FilePath or ""
	self.Line     = lineColumnLocation.Line     or 0
	self.Column   = lineColumnLocation.Column   or 0
end

function self:Equals (lineColumnLocation)
	return self.FilePath == lineColumnLocation.FilePath and
	       self.Line     == lineColumnLocation.Line     and
	       self.Column   == lineColumnLocation.Column
end

function self:GetColumn ()
	return self.Column
end

function self:GetFilePath ()
	return self.FilePath
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

function self:SetColumn (column)
	if column < 0 then column = 0 end
	self.Column = column
end

function self:SetFilePath (filePath)
	self.FilePath = filePath
end

function self:SetLine (line)
	if line < 0 then line = 0 end
	self.Line = line
end