local self = {}
GCompute.Editor.Document = GCompute.MakeConstructor (self)

--[[
	Events:
		TextCleared ()
			Fired when this document has been cleared.
		TextDeleted (deletionStartLocation, deletionEndLocation)
			Fired when text has been deleted.
		TextInserted (insertionLocation, text)
			Fired when text has been inserted.
]]

function self:ctor ()
	self.Lines = {}
	
	GCompute.EventProvider (self)
	
	self:Clear ()
end

function self:CharacterToColumn (characterLocation, tabWidth)
	local columnLocation = GCompute.Editor.LineColumnLocation (characterLocation)
	columnLocation:SetColumn (self:GetLine (characterLocation:GetLine ()):ColumnFromCharacter (characterLocation:GetCharacter (), tabWidth))
	return columnLocation
end

function self:ColumnToCharacter (columnLocation, tabWidth)
	local characterLocation = GCompute.Editor.LineCharacterLocation (columnLocation)
	characterLocation:SetCharacter (self:GetLine (columnLocation:GetLine ()):CharacterFromColumn (columnLocation:GetColumn (), tabWidth))
	return characterLocation
end

function self:Clear ()
	self.Lines = {}
	self.Lines [#self.Lines + 1] = GCompute.Editor.Line (self)
	
	self:DispatchEvent ("TextCleared")
end

function self:Delete (startLocation, endLocation)
	if startLocation:IsAfter (endLocation) then
		local temp = endLocation
		endLocation = startLocation
		startLocation = temp
	end
	
	local after = self:GetLine (endLocation:GetLine ()):Sub (endLocation:GetCharacter ())
	local lastRemovedChar = GLib.UTF8.Sub (after, 1, 1)
	after = GLib.UTF8.Sub (after, 2)
	if after == "" or lastRemovedChar == "\r" or lastRemovedChar == "\n" then
		-- The last line's newline will be deleted.
		local nextLine = self:GetLine (endLocation:GetLine () + 1)
		if nextLine then
			after = nextLine:GetText ()
			table.remove (self.Lines, endLocation:GetLine () + 2)
		else
			after = ""
		end
	end
	
	if startLocation:GetLine () == endLocation:GetLine () then
		-- Single line deletion
		local line = self:GetLine (startLocation:GetLine ())
		line:SetText (line:Sub (1, startLocation:GetCharacter ()) .. after)
	else
		-- Multiple line deletion
		
		-- Delete middle lines
		for i = endLocation:GetLine (), startLocation:GetLine () + 1, -1 do
			table.remove (self.Lines, i + 1)
		end
		
		local line = self:GetLine (startLocation:GetLine ())
		line:SetText (line:Sub (1, startLocation:GetCharacter ()) .. after)
	end
	
	self:DispatchEvent ("TextDeleted", startLocation, endLocation)
	
	return startLocation
end

function self:GetEnd ()
	local endLocation = GCompute.Editor.LineCharacterLocation ()
	endLocation:SetLine (self:GetLineCount () - 1)
	endLocation:SetCharacter (self:GetLine (self:GetLineCount () - 1):RealLength ())
	return endLocation
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
	if startLocation:IsAfter (endLocation) then
		local temp = endLocation
		endLocation = startLocation
		startLocation = temp
	end
	
	-- Clamp locations to end of document
	local documentEndLocation = self:GetEnd ()
	if endLocation:IsAfter (documentEndLocation) then
		endLocation = documentEndLocation
	end
	if startLocation:IsAfter (documentEndLocation) then
		endLocation = documentEndLocation
	end
	
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
	
	local newlineTerminated = true
	local offset = 1
	while offset <= text:len () do
		local crOffset = text:find ("\r", offset, true)
		local lfOffset = text:find ("\n", offset, true)
		local newlineOffset = crOffset or lfOffset
		if crOffset and crOffset < newlineOffset then newlineOffset = crOffset end
		if lfOffset and lfOffset < newlineOffset then newlineOffset = lfOffset end
		if newlineOffset then
			if text:sub (newlineOffset, newlineOffset + 1) == "\r\n" then
				lines [#lines + 1] = text:sub (offset, newlineOffset + 1)
				offset = newlineOffset + 2
			else
				lines [#lines + 1] = text:sub (offset, newlineOffset)
				offset = newlineOffset + 1
			end
		else
			-- End of text to be inserted, no newline found
			lines [#lines + 1] = text:sub (offset)
			newlineTerminated = false
			break
		end
	end
	
	if #self.Lines == 0 then
		self.Lines [#self.Lines + 1] = GCompute.Editor.Line (self)
	end
	
	local insertionLine = self.Lines [location:GetLine () + 1]
	local beforeString = insertionLine:Sub (1, location:GetCharacter ())
	local afterString = insertionLine:Sub (location:GetCharacter () + 1)
	
	local newLocation = GCompute.Editor.LineCharacterLocation (location:GetLine ())
	
	if #lines == 1 then
		-- Single line insertion
		
		if newlineTerminated then
			-- One new line created
			insertionLine:SetText (beforeString .. lines [1])
			table.insert (self.Lines, location:GetLine () + 2, GCompute.Editor.Line (self, afterString))
			
			newLocation:SetLine (location:GetLine () + 1)
			newLocation:SetCharacter (0)
		else
			-- No new lines created
			insertionLine:SetText (beforeString .. lines [1] .. afterString)
			
			newLocation:SetLine (location:GetLine ())
			newLocation:SetCharacter (GLib.UTF8.Length (beforeString .. lines [1]))
		end
	else
		-- Multiple line insertion
		
		-- Append first line
		insertionLine:SetText (beforeString .. lines [1])
		
		-- Insert middle lines
		local nextInsertionLine = location:GetLine () + 2
		for i = 2, #lines - 1 do
			table.insert (self.Lines, nextInsertionLine, GCompute.Editor.Line (self, lines [i]))
			nextInsertionLine = nextInsertionLine + 1
		end
		
		-- Prepend or insert final line
		if newlineTerminated then
			table.insert (self.Lines, nextInsertionLine, GCompute.Editor.Line (self, lines [#lines]))
			table.insert (self.Lines, nextInsertionLine + 1, GCompute.Editor.Line (self, afterString))
			
			newLocation:SetLine (nextInsertionLine)
			newLocation:SetCharacter (0)
		else
			table.insert (self.Lines, nextInsertionLine, GCompute.Editor.Line (self, lines [#lines] .. afterString))
			
			newLocation:SetLine (nextInsertionLine - 1)
			newLocation:SetCharacter (GLib.UTF8.Length (lines [#lines]))
		end
	end
	
	self:DispatchEvent ("TextInserted", location, text)
	
	return newLocation
end

function self:SetText (text)
	self:Clear ()
	self:Insert (GCompute.Editor.LineCharacterLocation (0, 0), text)
end