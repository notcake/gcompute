local self = {}
GCompute.Editor.Line = GCompute.MakeConstructor (self)

function self:ctor (document, text)
	self.Document = document
	
	self.Text = nil -- text with which to initialize the text storage
	self.TextStorage = nil
	
	self:SetText (text)
end

function self:CharacterFromColumn (column, textRenderer)
	return self:GetTextStorage ():CharacterFromColumn (column, textRenderer)
end

function self:CharacterToColumn (character, textRenderer)
	return self:GetTextStorage ():ColumnFromCharacter (character, textRenderer)
end

function self:ColumnFromCharacter (character, textRenderer)
	return self:GetTextStorage ():ColumnFromCharacter (character, textRenderer)
end

function self:ColumnToCharacter (column, textRenderer)
	return self:GetTextStorage ():CharacterFromColumn (column, textRenderer)
end

-- Should only be called by Document member functions
function self:Delete (startCharacter, endCharacter)
	self:GetTextStorage ():Delete (startCharacter, endCharacter)
end

function self:GetCharacter (character)
	return self:GetTextStorage ():GetCharacter (character)
end

function self:GetCharacterColor (character)
	return self:GetTextStorage ():GetCharacterColor (character)
end

function self:GetCharacterObject (character)
	return self:GetTextStorage ():GetCharacterObject (character)
end

function self:GetColumnCount (textRenderer)
	return self:GetTextStorage ():GetColumnCount (textRenderer)
end

function self:GetLengthIncludingLineBreak ()
	return self:GetTextStorage ():GetLengthIncludingLineBreak ()
end

function self:GetLengthExcludingLineBreak ()
	return self:GetTextStorage ():GetLengthExcludingLineBreak ()
end

--- Returns the line number of this Line. Runs in linear time.
-- @return This Line's line number
function self:GetLineNumber ()
	return self.Document:GetLineNumber (self)
end

function self:GetText ()
	return self.Text or self.TextStorage:GetText ()
end

function self:GetTextStorage ()
	if not self.TextStorage then self:InitializeTextStorage () end
	return self.TextStorage
end

function self:InitializeTextStorage ()
	self.TextStorage = GCompute.Editor.ArrayTextStorage ()
	self.TextStorage:Insert (0, self.Text)
	self.Text = nil
end

-- Should only be called by Document member functions
function self:Insert (character, text)
	self:GetTextStorage ():Insert (character, text)
end

-- The given line should be discarded after MergeAppend is called
-- Should only be called by Document member functions
function self:MergeAppend (line)
	if not line then return end
	self:GetTextStorage ():Append (line.TextStorage)
end

function self:SetColor (color, startCharacter, endCharacter)
	self:GetTextStorage ():SetColor (color, startCharacter, endCharacter)
end

function self:SetObject (object, startCharacter, endCharacter)
	self:GetTextStorage ():SetObject (object, startCharacter, endCharacter)
end

-- Should only be called by Document member functions
function self:SetText (text)
	text = text or ""
	if self.TextStorage then
		self.TextStorage:Clear ()
		self.TextStorage:Insert (0, text)
	else
		self.Text = text
	end
end

-- Should only be called by Document member functions
function self:Split (character)
	local nextLine = GCompute.Editor.Line (self.Document)
	nextLine.TextStorage = self:GetTextStorage ():Split (character)
	nextLine.Text = nil
	return nextLine
end

function self:Sub (startCharacter, endCharacter)
	return self:GetTextStorage ():Sub (startCharacter, endCharacter)
end