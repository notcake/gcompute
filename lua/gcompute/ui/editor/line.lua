local self = {}
GCompute.Editor.Line = GCompute.MakeConstructor (self)

function self:ctor (document, text)
	self.Document = document

	self.TextStorage = GCompute.Editor.ArrayTextStorage ()
	
	self:SetText (text)
end

function self:CharacterFromColumn (column, textRenderer)
	return self.TextStorage:CharacterFromColumn (column, textRenderer)
end

function self:ColumnFromCharacter (character, textRenderer)
	return self.TextStorage:ColumnFromCharacter (character, textRenderer)
end

-- Should only be called by Document member functions
function self:Delete (startCharacter, endCharacter)
	self.TextStorage:Delete (startCharacter, endCharacter)
end

function self:GetByteCount ()
	return self.TextStorage:GetText ():len ()
end

function self:GetCharacter (character)
	return self.TextStorage:GetCharacter (character)
end

--- Returns the line number of this Line. Runs in linear time.
-- @return This Line's line number
function self:GetLineNumber ()
	return self.Document:GetLineNumber (self)
end

function self:GetText ()
	return self.TextStorage:GetText ()
end

function self:GetColumnCount (textRenderer)
	return self.TextStorage:GetColumnCount (textRenderer)
end

-- Should only be called by Document member functions
function self:Insert (character, text)
	self.TextStorage:Insert (character, text)
end

function self:LengthIncludingLineBreak ()
	return self.TextStorage:GetLengthIncludingLineBreak ()
end

function self:LengthExcludingLineBreak ()
	return self.TextStorage:GetLengthExcludingLineBreak ()
end

-- The given line should be discarded after MergeAppend is called
-- Should only be called by Document member functions
function self:MergeAppend (line)
	if not line then return end
	self.TextStorage:Append (line.TextStorage)
end

-- Should only be called by Document member functions
function self:SetColor (color, startCharacter, endCharacter)
	self.TextStorage:SetColor (color, startCharacter, endCharacter)
end

-- Should only be called by Document member functions
function self:SetText (text)
	local startTime = SysTime ()
	self.TextStorage:Clear ()
	self.TextStorage:Insert (0, text)
end

-- Should only be called by Document member functions
function self:Split (character)
	local nextLine = GCompute.Editor.Line (self.Document)
	nextLine.TextStorage = self.TextStorage:Split (character)
	return nextLine
end

function self:Sub (startCharacter, endCharacter)
	return self.TextStorage:Sub (startCharacter, endCharacter)
end