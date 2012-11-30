local self = {}
GCompute.CompilerMessage = GCompute.MakeConstructor (self)

function self:ctor (messageType, text)
	self.MessageType = messageType or GCompute.CompilerMessageType.Warning
	self.Text = text or ""
	
	self.StartFile      = ""
	self.StartLine      = 0
	self.StartCharacter = 0
	self.EndFile        = ""
	self.EndLine        = 0
	self.EndCharacter   = 0
end

function self:GetFullLocation ()
	return self.StartFile, self.StartLine, self.StartCharacter, self.EndFile, self.EndLine, self.EndCharacter
end

function self:GetLocation ()
	return self.StartLine, self.StartCharacter, self.EndLine, self.EndCharacter
end

function self:GetEndCharacter ()
	return self.EndCharacter
end

function self:GetEndFile ()
	return self.EndFile
end

function self:GetEndLine ()
	return self.EndLine
end

function self:GetMessageType ()
	return self.MessageType
end

function self:GetStartCharacter ()
	return self.StartCharacter
end

function self:GetStartFile ()
	return self.StartFile
end

function self:GetStartLine ()
	return self.StartLine
end

function self:GetText ()
	return self.Text
end

function self:SetEndCharacter (character)
	self.EndCharacter = character
	return self
end

function self:SetEndFile (file)
	self.EndFile = file
	return self
end

function self:SetEndLine (line)
	self.EndLine = line
	return self
end

function self:SetEndToken (endToken)
	if not endToken then return self end
	
	self.EndLine      = endToken.EndLine
	self.EndCharacter = endToken.EndCharacter
	
	return self
end

function self:SetMessageType (compilerMessageType)
	self.MessageType = compilerMessageType
	return self
end

function self:SetStartCharacter (character)
	self.StartCharacter = character
	return self
end

function self:SetStartFile (file)
	self.StartFile = file
	return self
end

function self:SetStartLine (line)
	self.StartLine = line
	return self
end

function self:SetStartToken (startToken)
	if not startToken then return self end
	
	self.StartLine      = startToken.Line
	self.StartCharacter = startToken.Character
	
	return self
end

function self:SetText (text)
	self.Text = text
	return self
end

function self:ToString ()
	return (self.StartFile or "") .. ":" .. (self.StartLine + 1) .. ":" .. (self.StartCharacter + 1) .. ": " .. GCompute.CompilerMessageType [self.MessageType] .. ": " .. self.Text
end