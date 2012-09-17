local self = {}
GCompute.Editor.LineCharacterLocation = GCompute.MakeConstructor (self)

function self:ctor (line, character)
	self.Line = 0
	self.Character = 0
	
	if type (line) == "table" then
		self:CopyFrom (line)
	else
		self:SetLine (line or self.Line)
		self:SetCharacter (character or self.Character)
	end
end

function self:AddCharacters (characters)
	local lineCharacterLocation     = GCompute.Editor.lineCharacterLocation ()
	lineCharacterLocation.Line      = self.Line
	lineCharacterLocation.Character = math.max (0, self.Character + characters)
	
	return lineCharacterLocation
end

function self:Clone ()
	return GCompute.Editor.LineCharacterLocation (self.Line, self.Character)
end

function self:CopyFrom (lineCharacterLocation)
	self.Line      = lineCharacterLocation.Line      or 0
	self.Character = lineCharacterLocation.Character or 0
end

function self:Equals (lineCharacterLocation)
	return self.Line      == lineCharacterLocation.Line and
	       self.Character == lineCharacterLocation.Character
end

function self:GetCharacter ()
	return self.Character
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

function self:IsEqualOrAfter (lineCharacterLocation)
	if self.Line < lineCharacterLocation.Line then return false end
	if self.Line > lineCharacterLocation.Line then return true end
	if self.Character >= lineCharacterLocation.Character then return true end
	return false
end

function self:IsEqualOrBefore (lineCharacterLocation)
	if self.Line < lineCharacterLocation.Line then return true end
	if self.Line > lineCharacterLocation.Line then return false end
	if self.Character <= lineCharacterLocation.Character then return true end
	return false
end

function self:SetCharacter (character)
	self.Character = character
end

function self:SetLine (line)
	self.Line = line
end

function self:ToString ()
	return "Line " .. tostring (self.Line) .. ", char " .. tostring (self.Character)
end