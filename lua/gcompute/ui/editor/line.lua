local self = {}
GCompute.Editor.Line = GCompute.MakeConstructor (self)

function self:ctor (document, text)
	self.Document = document
	self.Text = text or ""
	
	self.CachedLength = 0
	self.CachedLengthValid = false
	
	self.CachedRealLength = 0
	self.CachedRealLengthValid = false
	
	self.CachedRenderInstructions = {}
	self.CachedRenderInstructionsTabWidth = 0
	self.CachedRenderInstructionsValid = false
	
	self.CachedWidth = 0
	self.CachedWidthTabWidth = 0
	self.CachedWidthValid = false
	
	self.StartToken = nil
end

function self:CharacterFromColumn (column, tabWidth)
	tabWidth = tabWidth or 4
	
	local columnWidth = 0
	local characterWidth = 0
	local character = 0
	for offset, char in GLib.UTF8.Iterator (self.Text) do
		if columnWidth == column then
			return character, columnWidth
		end
		
		if char == "\t" then
			characterWidth = tabWidth
		elseif char ~= "\r" and char ~= "\n" then
			characterWidth = 1
		else
			characterWidth = 0
		end
		
		if columnWidth + characterWidth > column then
			return character, columnWidth
		end
		
		character   = character   + 1
		columnWidth = columnWidth + characterWidth
	end
	return character, columnWidth
end

function self:ColumnFromCharacter (character, tabWidth)
	tabWidth = tabWidth or 4
	
	local lastColumnWidth = 0
	local columnWidth = 0
	local currentCharacter = 0
	for offset, char in GLib.UTF8.Iterator (self.Text) do		
		if currentCharacter >= character then
			return columnWidth
		end
		
		lastColumnWidth = columnWidth
		if char == "\t" then
			columnWidth = columnWidth + tabWidth
		elseif char ~= "\r" and char ~= "\n" then
			columnWidth = columnWidth + 1
		end
		
		currentCharacter = currentCharacter + 1
	end
	return columnWidth
end

function self:GetByteCount ()
	return self.Text:len ()
end

function self:GetCharacterWidth (character, tabWidth)
	tabWidth = tabWidth or 4
	
	if character == "" then return 0 end
	if character == "\t" then return tabWidth end
	return 1
end

--- Returns the line number of this Line. Runs in linear time.
-- @return This Line's line number
function self:GetLineNumber ()
	return self.Document:GetLineNumber (self)
end

function self:GetRenderInstructions (tabWidth)
	if not self.CachedRenderInstructionsValid or self.CachedRenderInstructionsTabWidth ~= tabWidth then
		self.CachedRenderInstructions = {}
		
		if self:GetStartToken () then
			GCompute.Editor.TokenizedLineColorer:ColorLine (self, tabWidth)
		else
			GCompute.Editor.DefaultLineColorer:ColorLine (self, tabWidth)
		end
		
		self.CachedRenderInstructionsTabWidth = tabWidth
		self.CachedRenderInstructionsValid = true
	end
	return self.CachedRenderInstructions
end

function self:GetStartToken ()
	return self.StartToken
end

function self:GetText ()
	return self.Text
end

function self:GetWidth (tabWidth)
	tabWidth = tabWidth or 4
	
	if not self.CachedWidthValid or self.CachedWidthTabSize ~= tabWidth then
		self.CachedWidth = self:ColumnFromCharacter (self.Text:len () + 1, tabWidth)
		
		self.CachedWidthValid = true
		self.CachedWidthTabSize = tabWidth
	end
	return self.CachedWidth
end

function self:InvalidateColoring ()
	self.CachedRenderInstructionsValid = false
end

function self:Length ()
	if not self.CachedLengthValid then
		self.CachedLength = self:RealLength ()
		if self.Text:sub (-1, -1) == "\n" then
			self.CachedLength = self.CachedLength - 1
			if self.Text:sub (-2, -2) == "\r" then
				self.CachedLength = self.CachedLength - 1
			end
		elseif self.Text:sub (-1, -1) == "\r" then
			self.CachedLength = self.CachedLength - 1
		end
		self.CachedLengthValid = true
	end
	return self.CachedLength
end

function self:OffsetFromColumn (column, tabWidth)
	tabWidth = tabWidth or 4
	
	local columnWidth = 0
	local characterWidth = 0
	for offset, char in GLib.UTF8.Iterator (self.Text) do
		if columnWidth == column then
			return offset, columnWidth
		end
		
		if char == "\t" then
			characterWidth = tabWidth
		elseif char ~= "\r" and char ~= "\n" then
			characterWidth = 1
		else
			characterWidth = 0
		end
		
		if columnWidth + characterWidth > column then
			return offset, columnWidth
		end
		
		columnWidth = columnWidth + characterWidth
	end
	return self.Text:len () + 1, columnWidth
end

function self:RealLength ()
	if not self.CachedRealLengthValid then
		self.CachedRealLength = GLib.UTF8.Length (self.Text)
	end
	return self.CachedRealLength
end

function self:SetText (text)
	text = text or ""
	if self.Text == text then return end
	
	self.Text = text
	
	self.CachedLengthValid = false
	self.CachedRealLengthValid = false
	self.CachedRenderInstructionsValid = false
	self.CachedWidthValid = false
end

function self:SetStartToken (startToken)
	if self.StartToken == startToken then return end
	self.StartToken = startToken
	
	self.CachedRenderInstructionsValid = false
end

function self:Sub (startCharacter, endCharacter)
	return GLib.UTF8.Sub (self.Text, startCharacter, endCharacter)
end