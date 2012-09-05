local self = {}
GCompute.Editor.LineCharacterLocation = GCompute.MakeConstructor (self)

function self:ctor (line, character)
	self.FilePath = ""
	self.Line = 0
	self.Character = 0
	
	if type (line) == "table" then
		self:CopyFrom (line)
	else
		self:SetLine (line or self.Line)
		self:SetCharacter (character or self.Character)
	end
end

function self:CopyFrom (lineCharacterLocation)
	self.FilePath  = lineCharacterLocation.FilePath  or ""
	self.Line      = lineCharacterLocation.Line      or 0
	self.Character = lineCharacterLocation.Character or 0
end

function self:Equals (lineCharacterLocation)
	return self.FilePath  == lineCharacterLocation.FilePath and
	       self.Line      == lineCharacterLocation.Line     and
	       self.Character == lineCharacterLocation.Character
end

function self:GetCharacter ()
	return self.Character
end

function self:GetFilePath ()
	return self.FilePath
end

function self:GetLine ()
	return self.Line
end

function self:IsAfter (lineCharacterLocation)
	if self.Line < lineCharacterLocation.Line then return false end
	if self.Line > lineCharacterLocation.Line then return true end
	if self.Character > lineCharacterLocation.Character then return true end
	return false
end

function self:IsBefore (lineCharacterLocation)
	if self.Line < lineCharacterLocation.Line then return true end
	if self.Line > lineCharacterLocation.Line then return false end
	if self.Character < lineCharacterLocation.Character then return true end
	return false
end

function self:SetCharacter (character)
	if character < 0 then character = 0 end
	self.Character = character
end

function self:SetFilePath (filePath)
	self.FilePath = filePath
end

function self:SetLine (line)
	if line < 0 then line = 0 end
	self.Line = line
end