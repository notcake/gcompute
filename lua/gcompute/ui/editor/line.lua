local self = {}
GCompute.Editor.Line = GCompute.MakeConstructor (self)

function self:ctor (document, text)
	self.Document = document
	
	self.Text = nil -- text with which to initialize the text storage
	self.TextStorage = nil
	
	self:SetText (text)
end

function self:CharacterFromColumn (column, textRenderer)
	if not self.TextStorage then self:InitializeTextStorage () end
	return self.TextStorage:CharacterFromColumn (column, textRenderer)
end

function self:ColumnFromCharacter (character, textRenderer)
	if not self.TextStorage then self:InitializeTextStorage () end
	return self.TextStorage:ColumnFromCharacter (character, textRenderer)
end

-- Should only be called by Document member functions
function self:Delete (startCharacter, endCharacter)
	if not self.TextStorage then self:InitializeTextStorage () end
	self.TextStorage:Delete (startCharacter, endCharacter)
end

function self:GetCharacter (character)
	if not self.TextStorage then self:InitializeTextStorage () end
	return self.TextStorage:GetCharacter (character)
end

function self:GetCharacterColor (character)
	if not self.TextStorage then self:InitializeTextStorage () end
	return self.TextStorage:GetCharacterColor (character)
end

function self:GetCharacterObject (character)
	if not self.TextStorage then self:InitializeTextStorage () end
	return self.TextStorage:GetCharacterObject (character)
end

function self:GetColumnCount (textRenderer)
	if not self.TextStorage then self:InitializeTextStorage () end
	return self.TextStorage:GetColumnCount (textRenderer)
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
	if not self.TextStorage then self:InitializeTextStorage () end
	self.TextStorage:Insert (character, text)
end

function self:LengthIncludingLineBreak ()
	if not self.TextStorage then self:InitializeTextStorage () end
	return self.TextStorage:GetLengthIncludingLineBreak ()
end

function self:LengthExcludingLineBreak ()
	if not self.TextStorage then self:InitializeTextStorage () end
	return self.TextStorage:GetLengthExcludingLineBreak ()
end

-- The given line should be discarded after MergeAppend is called
-- Should only be called by Document member functions
function self:MergeAppend (line)
	if not line then return end
	if not self.TextStorage then self:InitializeTextStorage () end
	self.TextStorage:Append (line.TextStorage)
end

function self:SetColor (color, startCharacter, endCharacter)
	if not self.TextStorage then self:InitializeTextStorage () end
	self.TextStorage:SetColor (color, startCharacter, endCharacter)
end

function self:SetObject (object, startCharacter, endCharacter)
	if not self.TextStorage then self:InitializeTextStorage () end
	self.TextStorage:SetObject (object, startCharacter, endCharacter)
end

-- Should only be called by Document member functions
function self:SetText (text)
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
	if not self.TextStorage then self:InitializeTextStorage () end
	nextLine.TextStorage = self.TextStorage:Split (character)
	return nextLine
end

function self:Sub (startCharacter, endCharacter)
	if not self.TextStorage then self:InitializeTextStorage () end
	return self.TextStorage:Sub (startCharacter, endCharacter)
end