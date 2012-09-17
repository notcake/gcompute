local self = {}
GCompute.Editor.ArrayTextStorage = GCompute.MakeConstructor (self)

local string_len   = string.len
local string_match = string.match
local table_insert = table.insert

function self:ctor ()
	self.Segments = {}
	
	self.Text = ""
	self.LengthExcludingLineBreak = 0
	self.LengthExcludingLineBreakValid = false
	self.LengthIncludingLineBreak = 0
	self.LengthIncludingLineBreakValid = false
	
	self.ColumnCount = 0
	self.ColumnCountValid = false
	self.ColumnCountValidityHash = ""
end

function self:Append (textStorage)
	if not textStorage then return end
	
	self.Text = self.Text .. textStorage.Text
	for i = 1, #textStorage.Segments do
		self.Segments [#self.Segments + 1] = textStorage.Segments [i]
	end
	
	self:InvalidateCache ()
	
	textStorage.Text = ""
	textStorage.Segments = {}
	textStorage:InvalidateCache ()
end

function self:CharacterFromColumn (column, textRenderer)
	if column >= self:GetColumnCount (textRenderer) then return self:GetLengthExcludingLineBreak (), self:GetColumnCount (textRenderer) end
	local character = 0
	local actualColumn = 0
	local segment
	for i = 1, #self.Segments do
		segment = self.Segments [i]
		if column <= self:GetSegmentColumnCount (segment, textRenderer) then break end
		column = column - self:GetSegmentColumnCount (segment, textRenderer)
		character = character + segment.Length
		actualColumn = actualColumn + self:GetSegmentColumnCount (segment, textRenderer)
	end
	
	local relativeCharacter, relativeActualColumn = self:SegmentCharacterFromColumn (segment, column, textRenderer)
	return character + relativeCharacter, actualColumn + relativeActualColumn
end

function self:CheckMerge (index)
	if index > #self.Segments then return end
	if index <= 0 then return index + 1 end
	
	local firstSegment = self.Segments [index]
	local secondSegment = self.Segments [index + 1]
	if self:CanMergeSegments (firstSegment, secondSegment) then
		firstSegment.Text = firstSegment.Text .. secondSegment.Text
		firstSegment.Length = firstSegment.Length + secondSegment.Length
		firstSegment.ColumnCountValid = false
		
		table.remove (self.Segments, index + 1)
		return index
	else
		return index + 1
	end
end

function self:Clear ()
	self.Text = ""
	self.Segments = {}
	self:InvalidateCache ()
end

function self:ColumnFromCharacter (character, textRenderer)
	if character >= self:GetLengthIncludingLineBreak () then return self:GetColumnCount (textRenderer) end
	local column = 0
	local segment
	for i = 1, #self.Segments do
		segment = self.Segments [i]
		if character <= segment.Length then break end
		character = character - segment.Length
		column = column + self:GetSegmentColumnCount (segment, textRenderer)
	end
	
	return column + textRenderer:GetStringColumnCount (GLib.UTF8.Sub (segment.Text, 1, character))
end

function self:Delete (startCharacter, endCharacter)
	endCharacter = endCharacter or self:GetLengthIncludingLineBreak ()
	if startCharacter > endCharacter then
		local temp = endCharacter
		endCharacter = startCharacter
		startCharacter = temp
	end
	
	local startIndex = self:SplitSegment (startCharacter)
	local endIndex = self:SplitSegment (endCharacter)
	
	for i = endIndex - 1, startIndex, -1 do
		table.remove (self.Segments, i)
	end
	
	self:CheckMerge (startIndex - 1)
	
	self.Text = GLib.UTF8.Sub (self.Text, 1, startCharacter) .. GLib.UTF8.Sub (self.Text, endCharacter + 1)
	self:InvalidateCache ()
end

function self:GetCharacter (character)
	return GLib.UTF8.Sub (self.Text, character + 1, character + 1)
end

function self:GetCharacterColor (character)
	local segment = self.Segments [self:SegmentIndexFromCharacter (character)]
	return segment and segment.Object or nil
end

function self:GetCharacterObject (character)
	local segment = self.Segments [self:SegmentIndexFromCharacter (character)]
	return segment and segment.Object or nil
end

function self:GetColumnCount (textRenderer)
	if not self.ColumnCountValid or self.ColumnCountValidityHash ~= textRenderer:GetStateHash () then
		self.ColumnCount = textRenderer:GetStringColumnCount (self.Text)
		
		self.ColumnCountValid = true
		self.ColumnCountValidityHash = textRenderer:GetStateHash ()
	end
	
	return self.ColumnCount
end

function self:GetLengthExcludingLineBreak ()
	if not self.LengthExcludingLineBreakValid then
		self.LengthExcludingLineBreak = self:GetLengthIncludingLineBreak ()
		local i = self.Text:len ()
		local c = self.Text:sub (i, i)
		while c == "\r" or c == "\n" do
			self.LengthExcludingLineBreak = self.LengthExcludingLineBreak - 1
			i = i - 1
			c = self.Text:sub (i, i)
		end
		self.LengthExcludingLineBreakValid = true
	end
	return self.LengthExcludingLineBreak
end

function self:GetLengthIncludingLineBreak ()
	if not self.LengthIncludingLineBreakValid then
		self.LengthIncludingLineBreak = GLib.UTF8.Length (self.Text)
		self.LengthIncludingLineBreakValid = true
	end
	return self.LengthIncludingLineBreak
end

function self:GetSegment (index)
	return self.Segments [index]
end

function self:GetSegmentCount ()
	return #self.Segments
end

function self:GetText ()
	return self.Text
end

function self:Insert (character, text)
	if not text or text == "" then return end
	
	local firstInsertionIndex = self:SplitSegment (character)
	local insertionIndex = firstInsertionIndex
	
	local textLength = string_len (text)
	
	local segment
	local offset = 1
	local match = nil
	local textType = nil
	while offset <= textLength do
		match = string_match (text, "^[ \t]+", offset)
		textType = "whitespace"
		if not match then
			match = string_match (text, "^[\r\n]+", offset)
			textType = "linebreak"
		end
		if not match then
			match = string_match (text, "^[%z\1-\8\11\12\14-\31\33-\127]+", offset)
			textType = "regular"
		end
		if match then
			segment = GCompute.Editor.TextSegment (match)
			segment.TextType = textType
			self:CopySegmentFormatting (segment, self.Segments [firstInsertionIndex - 1])
			table_insert (self.Segments, insertionIndex, segment)
			insertionIndex = insertionIndex + 1
		else
			match = string_match (text, "^[\128-\255]+", offset)
			textType = "utf8"
			
			for char, _ in GLib.UTF8.Iterator (match) do
				segment = GCompute.Editor.TextSegment (char)
				segment.TextType = textType
				self:CopySegmentFormatting (segment, self.Segments [firstInsertionIndex - 1])
				table_insert (self.Segments, insertionIndex, segment)
				insertionIndex = insertionIndex + 1
			end
		end
		offset = offset + string_len (match)
	end
	
	self:CheckMerge (firstInsertionIndex - 1)
	self:CheckMerge (insertionIndex - 1)
	
	local before, after = GLib.UTF8.SplitAt (self.Text, character + 1)
	self.Text = before .. text .. after
	self:InvalidateCache ()
end

function self:InvalidateCache ()
	self.LengthExcludingLineBreakValid = false
	self.LengthIncludingLineBreakValid = false
	self.ColumnCountValid = false
end

function self:SegmentIndexFromCharacter (character)
	if character >= self:GetLengthIncludingLineBreak () then return #self.Segments + 1, character - self:GetLengthIncludingLineBreak () end
	
	local i = 1
	local segment = self.Segments [i]
	while character > segment.Length do
		character = character - segment.Length
		i = i + 1
		segment = self.Segments [i]
	end
	
	return i, character
end

function self:SegmentIndexFromColumn (column, textRenderer)
	if column >= self:GetColumnCount (textRenderer) then return #self.Segments + 1, column - self:GetColumnCount (textRenderer) end
	
	local i = 1
	local segment = self.Segments [i]
	while column > self:GetSegmentColumnCount (segment, textRenderer) do
		column = column - self:GetSegmentColumnCount (segment, textRenderer)
		i = i + 1
		segment = self.Segments [i]
	end
	
	return i, column
end

function self:SetColor (color, startCharacter, endCharacter)
	color = color or GLib.Colors.White
	startCharacter = startCharacter or 0
	if endCharacter and endCharacter < startCharacter then
		local temp = startCharacter
		startCharacter = endCharacter
		endCharacter = temp
	end
	
	local startIndex = self:SplitSegment (startCharacter)
	local afterEndIndex = endCharacter and self:SplitSegment (endCharacter) or #self.Segments + 1
	
	if startIndex > #self.Segments then return end
	
	for i = startIndex, afterEndIndex - 1 do
		self.Segments [i].Color = color
	end
	
	for i = afterEndIndex - 1, startIndex - 1, -1 do
		self:CheckMerge (i)
	end
end

function self:SetObject (object, startCharacter, endCharacter)
	startCharacter = startCharacter or 0
	if endCharacter and endCharacter < startCharacter then
		local temp = startCharacter
		startCharacter = endCharacter
		endCharacter = temp
	end
	
	local startIndex = self:SplitSegment (startCharacter)
	local afterEndIndex = endCharacter and self:SplitSegment (endCharacter) or #self.Segments + 1
	
	if startIndex > #self.Segments then return end
	
	for i = startIndex, afterEndIndex - 1 do
		self.Segments [i].Object = object
	end
	
	for i = afterEndIndex - 1, startIndex - 1, -1 do
		self:CheckMerge (i)
	end
end

function self:Split (character)
	local before, after = GLib.UTF8.SplitAt (self.Text, character + 1)
	
	local splitIndex = self:SplitSegment (character)
	local textStorage = GCompute.Editor.ArrayTextStorage ()
	
	self.Text = before
	self:InvalidateCache ()
	
	for i = splitIndex, #self.Segments do
		textStorage.Segments [#textStorage.Segments + 1] = self.Segments [i]
		self.Segments [i] = nil
	end
	
	textStorage.Text = after
	textStorage:InvalidateCache ()
	
	return textStorage
end

function self:SplitSegment (character)
	if character >= self:GetLengthIncludingLineBreak () then return #self.Segments + 1 end
	local i = 1
	while character >= self.Segments [i].Length do
		character = character - self.Segments [i].Length
		i = i + 1
	end
	
	if character <= 0 then return i end
	
	local segmentToSplit = self.Segments [i]
	local before, after = GLib.UTF8.SplitAt (segmentToSplit.Text, character + 1)
	
	segmentToSplit.Text = before
	segmentToSplit.Length = character
	segmentToSplit.ColumnCountValid = false
	
	local newSegment = GCompute.Editor.TextSegment (after)
	self:CopySegmentFormatting (newSegment, segmentToSplit)
	self:CopySegmentMetadata (newSegment, segmentToSplit)
	
	table.insert (self.Segments, i + 1, newSegment)
	return i + 1
end

function self:Sub (startCharacter, endCharacter)
	return GLib.UTF8.Sub (self.Text, startCharacter, endCharacter)
end

function self:ToString ()
	local textStorage = "{\n"
	textStorage = textStorage .. "\t\"" .. GLib.String.Escape (self.Text) .. "\"\n"
	
	local segments = {}
	for i = 1, #self.Segments do
		segments [#segments + 1] = self.Segments [i]:ToString ()
	end
	
	textStorage = textStorage .. "\t" .. table.concat (segments, ", ") .. "\n"
	textStorage = textStorage .. "}"
	return textStorage
end

-- Internal, do not call
function self:CanMergeSegments (segment1, segment2)
	if not segment2 then return false end
	
	if segment1.TextType ~= segment2.TextType then return false end
	if segment1.TextType == "utf8" then return false end
	if segment1.Object ~= segment2.Object then return false end
	if segment1.Color.r ~= segment2.Color.r then return false end
	if segment1.Color.g ~= segment2.Color.g then return false end
	if segment1.Color.b ~= segment2.Color.b then return false end
	if segment1.Color.a ~= segment2.Color.a then return false end
	
	return true
end

function self:CopySegmentFormatting (destinationSegment, sourceSegment)
	if not sourceSegment then return end
	
	destinationSegment.Color = sourceSegment.Color
end

function self:CopySegmentMetadata (destinationSegment, sourceSegment)
	if not sourceSegment then return end
	
	destinationSegment.TextType = sourceSegment.TextType
end

function self:GetSegmentColumnCount (segment, textRenderer)
	if not segment.ColumnCountValid or segment.ColumnCountValidityHash ~= textRenderer:GetStateHash () then
		segment.ColumnCount = textRenderer:GetStringColumnCount (segment.Text)
		
		segment.ColumnCountValid = true
		segment.ColumnCountValidityHash = textRenderer:GetStateHash ()
	end
	
	return segment.ColumnCount
end

function self:SegmentCharacterFromColumn (segment, column, textRenderer)
	if column == 0 then return 0, 0 end
	
	local currentColumn = 0
	local character = 0
	for char, _ in GLib.UTF8.Iterator (segment.Text) do
		local nextCharacterColumnCount = textRenderer:GetCharacterColumnCount (char)
		if currentColumn == column or currentColumn + nextCharacterColumnCount > column then
			return character, currentColumn
		end
		currentColumn = currentColumn + nextCharacterColumnCount
		character = character + 1
	end
	
	return character, currentColumn
end