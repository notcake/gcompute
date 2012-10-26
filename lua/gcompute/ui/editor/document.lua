local self = {}
GCompute.Editor.Document = GCompute.MakeConstructor (self)

--[[
	Events:
		TextCleared ()
			Fired when this document has been cleared.
		TextDeleted (LineCharacterLocation deletionStartLocation, LineCharacterLocation deletionEndLocation)
			Fired when text has been deleted.
		TextInserted (LineCharacterLocation insertionLocation, text, LineCharacterLocation newLocation)
			Fired when text has been inserted.
]]

function self:ctor ()
	self.Lines = {}
	
	-- Reusable LineCharacterLocations for events
	self.InsertionNewLocation = GCompute.Editor.LineCharacterLocation ()
	
	GCompute.EventProvider (self)
	
	self:Clear ()
end

function self:CharacterToColumn (characterLocation, textRenderer)
	if not textRenderer then GCompute.Error ("Document:CharacterToColumn : You forgot to pass a text renderer.") end
	local columnLocation = GCompute.Editor.LineColumnLocation (characterLocation)
	local line = self:GetLine (characterLocation:GetLine ())
	if line then
		columnLocation:SetColumn (line:ColumnFromCharacter (characterLocation:GetCharacter (), textRenderer))
	else
		columnLocation:SetColumn (characterLocation:GetCharacter ())
	end
	return columnLocation
end

function self:ColumnToCharacter (columnLocation, textRenderer)
	if not textRenderer then GCompute.Error ("Document:ColumnToCharacter : You forgot to pass a text renderer.") end
	local characterLocation = GCompute.Editor.LineCharacterLocation (columnLocation)
	local line = self:GetLine (columnLocation:GetLine ())
	if line then
		characterLocation:SetCharacter (line:CharacterFromColumn (columnLocation:GetColumn (), textRenderer))
	else
		characterLocation:SetCharacter (columnLocation:GetColumn ())
	end
	return characterLocation
end

function self:Clear ()
	self.Lines = {}
	self.Lines [#self.Lines + 1] = GCompute.Editor.Line (self)
	
	self:DispatchEvent ("TextCleared")
end

function self:Delete (startLocation, endLocation)
	if startLocation > endLocation then
		local temp = endLocation
		endLocation = startLocation
		startLocation = temp
	end
	
	local endLine = endLocation:GetLine ()
	local endCharacter = endLocation:GetCharacter ()
	
	-- Check if the deletion span's last line's line break is to be deleted
	-- and adjust endLine and endCharacter if necessary.
	if endCharacter ~= 0 then
		local after = self:GetLine (endLine):Sub (endCharacter, endCharacter + 1)
		local lastRemovedChar = GLib.UTF8.NextChar (after)
		after = GLib.UTF8.Sub (after, 2)
		if after == "" or lastRemovedChar == "\r" or lastRemovedChar == "\n" then
			if self:GetLine (endLine + 1) then
				endLine = endLine + 1
				endCharacter = 0
				
				endLocation = GCompute.Editor.LineCharacterLocation (endLine, endCharacter)
			end
		end
	end
	
	if startLocation:GetLine () == endLine then
		-- Deletion span lies entirely within a single line
		local line = self:GetLine (startLocation:GetLine ())
		line:Delete (startLocation:GetCharacter (), endLocation:GetCharacter ())
	else
		-- Deletion span contains line breaks
		local initialLine = self:GetLine (startLocation:GetLine ())
		initialLine:Delete (startLocation:GetCharacter ())
		
		local finalLine = self:GetLine (endLine)
		finalLine:Delete (0, endCharacter)
		
		initialLine:MergeAppend (finalLine)
		
		-- Delete middle lines
		for i = endLine, startLocation:GetLine () + 1, -1 do
			table.remove (self.Lines, i + 1)
		end
	end
	
	self:DispatchEvent ("TextDeleted", startLocation, endLocation)
	
	return startLocation
end

function self:DeleteWithinLine (startLocation, endLocation)
	if startLocation:GetLine () ~= endLocation:GetLine () then GCompute.Error ("Document:DeleteWithinLine : startLocation and endLocation must be on the same line.") return end
	
	local line = self:GetLine (startLocation:GetLine ())
	if not line then return end
	
	if startLocation > endLocation then
		local temp = endLocation
		endLocation = startLocation
		startLocation = temp
	end
	
	line:Delete (startLocation:GetCharacter (), endLocation:GetCharacter ())
	
	self:DispatchEvent ("TextDeleted", startLocation, endLocation)
end

function self:GetEnd ()
	local endLocation = GCompute.Editor.LineCharacterLocation ()
	endLocation:SetLine (self:GetLineCount () - 1)
	endLocation:SetCharacter (self:GetLine (self:GetLineCount () - 1):LengthIncludingLineBreak ())
	return endLocation
end

function self:GetEnumerator ()
	local i = -1
	return function ()
		i = i + 1
		return self.Lines [i]
	end
end

function self:GetLine (line)
	return self.Lines [line + 1]
end

function self:GetLineCount ()
	return #self.Lines
end

--- Returns the line number of a given Line. Runs in linear time.
-- @param line The line whose line number is to be obtained
-- @return The line number of the line
function self:GetLineNumber (line)
	for i = 1, #self.Lines do
		if self.Lines [i] == line then return i - 1 end
	end
	return nil
end

function self:GetStart ()
	return GCompute.Editor.LineCharacterLocation (0, 0)
end

function self:GetText (startLocation, endLocation)
	if not startLocation then startLocation = self:GetStart () end
	if not endLocation   then endLocation   = self:GetEnd ()   end
	if startLocation > endLocation then
		local temp = endLocation
		endLocation = startLocation
		startLocation = temp
	end
	
	-- Clamp locations
	local documentStartLocation = self:GetStart ()
	local documentEndLocation   = self:GetEnd ()
	if endLocation   < documentStartLocation then endLocation   = documentStartLocation end
	if startLocation < documentStartLocation then startLocation = documentStartLocation end
	if endLocation   > documentEndLocation   then endLocation   = documentEndLocation   end
	if startLocation > documentEndLocation   then startLocation = documentEndLocation   end
	
	local text = ""
	if startLocation:GetLine () == endLocation:GetLine () then
		-- Single line section
		text = self:GetLine (startLocation:GetLine ()):Sub (startLocation:GetCharacter () + 1, endLocation:GetCharacter ())
	else
		-- Multiple line section
		local lines = {}
		lines [#lines + 1] = self:GetLine (startLocation:GetLine ()):Sub (startLocation:GetCharacter () + 1)
		
		for i = startLocation:GetLine () + 1, endLocation:GetLine () - 1 do
			lines [#lines + 1] = self:GetLine (i):GetText ()
		end
		
		lines [#lines + 1] = self:GetLine (endLocation:GetLine ()):Sub (1, endLocation:GetCharacter ())
		text = table.concat (lines)
	end
	return text
end

function self:Insert (location, text)
	text = text or ""
	if text == "" then return location end

	local lines = {}
	-- If there are one or more line breaks in the text to be inserted,
	-- the last entry in the lines array will be text prepended to the
	-- last line that will be changed as a result of the insertion
	
	local startTime = SysTime ()
	local offset = 1
	local crOffset = 0
	local lfOffset = 0
	while offset <= text:len () + 1 do
		if crOffset and crOffset < offset then crOffset = string.find (text, "\r", offset, true) end
		if lfOffset and lfOffset < offset then lfOffset = string.find (text, "\n", offset, true) end
		local newlineOffset = crOffset or lfOffset
		if lfOffset and lfOffset < newlineOffset then newlineOffset = lfOffset end
		if newlineOffset then
			if string.sub (text, newlineOffset, newlineOffset + 1) == "\r\n" then
				lines [#lines + 1] = string.sub (text, offset, newlineOffset + 1)
				offset = newlineOffset + 2
			else
				lines [#lines + 1] = string.sub (text, offset, newlineOffset)
				offset = newlineOffset + 1
			end
		else
			-- End of text to be inserted, no more line breaks found
			lines [#lines + 1] = string.sub (text, offset)
			break
		end
	end
	
	if #self.Lines == 0 then
		self.Lines [#self.Lines + 1] = GCompute.Editor.Line (self)
	end
	
	local insertionLine = self.Lines [location:GetLine () + 1]
	
	local newLocation = GCompute.Editor.LineCharacterLocation (location:GetLine ())
	
	if #lines == 1 then
		-- Single line insertion
		-- No new lines created
		insertionLine:Insert (location:GetCharacter (), lines [1])
		
		newLocation:SetLine (location:GetLine ())
		newLocation:SetCharacter (location:GetCharacter () + GLib.UTF8.Length (lines [1]))
	else
		-- Multiple line insertion
		
		-- Split first line
		local finalLine = insertionLine:Split (location:GetCharacter ())
		insertionLine:Insert (location:GetCharacter (), lines [1])
		
		-- Insert middle lines
		local nextInsertionIndex = location:GetLine () + 2
		for i = 2, #lines - 1 do
			table.insert (self.Lines, nextInsertionIndex, GCompute.Editor.Line (self, lines [i]))
			nextInsertionIndex = nextInsertionIndex + 1
		end
		
		-- Insert final line and prepend it
		table.insert (self.Lines, nextInsertionIndex, finalLine)
		finalLine:Insert (0, lines [#lines])
		
		newLocation:SetLine (nextInsertionIndex - 1)
		newLocation:SetCharacter (GLib.UTF8.Length (lines [#lines]))
	end
	
	self:DispatchEvent ("TextInserted", location, text, newLocation)
	
	return newLocation
end

function self:InsertWithinLine (location, text)
	local line = self:GetLine (location:GetLine ())
	if not line then return end
	
	line:Insert (location:GetCharacter (), text)
	
	self.InsertionNewLocation:SetLine (location:GetLine ())
	self.InsertionNewLocation:SetCharacter (location:GetCharacter () + GLib.UTF8.Length (text))
	self:DispatchEvent ("TextInserted", location, text, self.InsertionNewLocation)
end

function self:SetColor (color, startLocation, endLocation)
	if not startLocation then startLocation = self:GetStart () end
	if not endLocation   then endLocation   = self:GetEnd ()   end
	if startLocation > endLocation then
		local temp = endLocation
		endLocation = startLocation
		startLocation = temp
	end
	
	-- Clamp locations
	local documentStartLocation = self:GetStart ()
	local documentEndLocation   = self:GetEnd ()
	if endLocation   < documentStartLocation then endLocation   = documentStartLocation end
	if startLocation < documentStartLocation then startLocation = documentStartLocation end
	if endLocation   > documentEndLocation   then endLocation   = documentEndLocation   end
	if startLocation > documentEndLocation   then startLocation = documentEndLocation   end
	
	if startLocation:GetLine () == endLocation:GetLine () then
		-- Single line section
		self:GetLine (startLocation:GetLine ()):SetColor (color, startLocation:GetCharacter (), endLocation:GetCharacter ())
	else
		-- Multiple line section
		self:GetLine (startLocation:GetLine ()):SetColor (color, startLocation:GetCharacter ())
		
		for i = startLocation:GetLine () + 1, endLocation:GetLine () - 1 do
			self:GetLine (i):SetColor (color)
		end
		
		self:GetLine (endLocation:GetLine ()):SetColor (color, nil, endLocation:GetCharacter ())
	end
end

function self:SetText (text)
	self:Clear ()
	self:Insert (GCompute.Editor.LineCharacterLocation (0, 0), text)
end