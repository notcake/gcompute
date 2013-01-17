local self = GCompute.IDE.DocumentTypes:CreateType ("CodeDocument")

--[[
	Events:
		LanguageChanged (oldLanguage, language)
			Fired when this document's language has been changed.
		LinesShifted (startLine, endLine, shift)
			Fired when lines of this document have been shifted up or down.
		TextChanged ()
			Fired when this document's text has changed.
		TextCleared ()
			Fired when this document has been cleared.
		TextDeleted (LineCharacterLocation deletionStartLocation, LineCharacterLocation deletionEndLocation)
			Fired when text has been deleted. deletionStartLocation will always be before deletionEndLocation.
		TextInserted (LineCharacterLocation insertionLocation, text, LineCharacterLocation newLocation)
			Fired when text has been inserted.
]]

function self:ctor ()
	self.Language = nil
	
	self.Lines = {}
	
	-- Reusable LineCharacterLocations for events
	self.InsertionNewLocation = GCompute.IDE.LineCharacterLocation ()
	
	self:Clear ()
	
	self:DetectLanguage ()
	self:AddEventListener ("PathChanged",
		function ()
			self:DetectLanguage ()
		end
	)
end

function self:CharacterToColumn (characterLocation, textRenderer)
	if not textRenderer then GCompute.Error ("Document:CharacterToColumn : You forgot to pass a text renderer.") end
	local columnLocation = GCompute.IDE.LineColumnLocation (characterLocation)
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
	local characterLocation = GCompute.IDE.LineCharacterLocation (columnLocation)
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
	self.Lines [#self.Lines + 1] = GCompute.IDE.Line (self)
	
	self:DispatchEvent ("TextCleared")
	self:DispatchEvent ("TextChanged")
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
				
				endLocation = GCompute.IDE.LineCharacterLocation (endLine, endCharacter)
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
	self:DispatchEvent ("TextChanged")
	
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
	self:DispatchEvent ("TextChanged")
end

function self:GetAttribute (attributeName, location)
	local line = self:GetLine (location:GetLine ())
	if not line then return nil end
	return line:GetAttribute (attributeName, location:GetCharacter ())
end

function self:GetColor (location)
	return self:GetAttribute ("Color", location) or GLib.Colors.White
end

function self:GetEnd ()
	local endLocation = GCompute.IDE.LineCharacterLocation ()
	endLocation:SetLine (self:GetLineCount () - 1)
	endLocation:SetCharacter (self:GetLine (self:GetLineCount () - 1):GetLengthIncludingLineBreak ())
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

function self:GetNextWordBoundary (lineCharacterLocation)
	local lineNumber = lineCharacterLocation:GetLine ()
	local character  = lineCharacterLocation:GetCharacter ()
	
	local text = self:GetLine (lineNumber):GetText ()
	local offset = GLib.UTF8.CharacterToOffset (text, character + 1)
	
	local wordBoundaryOffset = offset
	local leftWordType
	local rightWordType
	wordBoundaryOffset, leftWordType, rightWordType = GLib.UTF8.NextWordBoundary (text, wordBoundaryOffset)
	
	if leftWordType == GLib.WordType.None or leftWordType == GLib.WordType.LineBreak then
		if lineNumber + 1 < self:GetLineCount () then
			lineNumber = lineNumber + 1
			character = 0
		end
	else
		while rightWordType == GLib.WordType.Whitespace do
			wordBoundaryOffset, leftWordType, rightWordType = GLib.UTF8.NextWordBoundary (text, wordBoundaryOffset)
		end
		character = character + GLib.UTF8.Length (text:sub (offset, wordBoundaryOffset - 1))
	end
	
	return GCompute.IDE.LineCharacterLocation (lineNumber, character)
end

function self:GetPreviousWordBoundary (lineCharacterLocation)
	local lineNumber = lineCharacterLocation:GetLine ()
	local character  = lineCharacterLocation:GetCharacter ()
	
	local text = self:GetLine (lineNumber):GetText ()
	local offset = GLib.UTF8.CharacterToOffset (text, character + 1)
	
	local wordBoundaryOffset = offset
	local leftWordType
	local rightWordType
	wordBoundaryOffset, leftWordType, rightWordType = GLib.UTF8.PreviousWordBoundary (text, wordBoundaryOffset)
	
	if rightWordType == GLib.WordType.None then
		if lineNumber > 0 then
			lineNumber = lineNumber - 1
			character = self:GetLine (lineNumber):GetLengthExcludingLineBreak ()
		end
	else
		while rightWordType == GLib.WordType.Whitespace do
			if leftWordType == GLib.WordType.None then break end
			wordBoundaryOffset, leftWordType, rightWordType = GLib.UTF8.PreviousWordBoundary (text, wordBoundaryOffset)
		end
		
		if leftWordType == GLib.WordType.None and rightWordType == GLib.WordType.Whitespace then
			if lineNumber == 0 then
				character = 0
			else
				lineNumber = lineNumber - 1
				character = self:GetLine (lineNumber):GetLengthExcludingLineBreak ()
			end
		else
			character = character - GLib.UTF8.Length (text:sub (wordBoundaryOffset, offset - 1))
		end
	end
	
	return GCompute.IDE.LineCharacterLocation (lineNumber, character)
end

function self:GetStart ()
	return GCompute.IDE.LineCharacterLocation (0, 0)
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
		self.Lines [#self.Lines + 1] = GCompute.IDE.Line (self)
	end
	
	local insertionLine = self.Lines [location:GetLine () + 1]
	
	local newLocation = GCompute.IDE.LineCharacterLocation (location:GetLine ())
	
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
			table.insert (self.Lines, nextInsertionIndex, GCompute.IDE.Line (self, lines [i]))
			nextInsertionIndex = nextInsertionIndex + 1
		end
		
		-- Insert final line and prepend it
		table.insert (self.Lines, nextInsertionIndex, finalLine)
		finalLine:Insert (0, lines [#lines])
		
		newLocation:SetLine (nextInsertionIndex - 1)
		newLocation:SetCharacter (GLib.UTF8.Length (lines [#lines]))
	end
	
	self:DispatchEvent ("TextInserted", location, text, newLocation)
	self:DispatchEvent ("TextChanged")
	
	return newLocation
end

function self:InsertWithinLine (location, text)
	local line = self:GetLine (location:GetLine ())
	if not line then return end
	
	line:Insert (location:GetCharacter (), text)
	
	self.InsertionNewLocation:SetLine (location:GetLine ())
	self.InsertionNewLocation:SetCharacter (location:GetCharacter () + GLib.UTF8.Length (text))
	self:DispatchEvent ("TextInserted", location, text, self.InsertionNewLocation)
	self:DispatchEvent ("TextChanged")
	
	return self.InsertionNewLocation
end

function self:SetAttribute (attributeName, attributeValue, startLocation, endLocation)
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
		self:GetLine (startLocation:GetLine ()):SetAttribute (attributeName, attributeValue, startLocation:GetCharacter (), endLocation:GetCharacter ())
	else
		-- Multiple line section
		self:GetLine (startLocation:GetLine ()):SetAttribute (attributeName, attributeValue, startLocation:GetCharacter ())
		
		for i = startLocation:GetLine () + 1, endLocation:GetLine () - 1 do
			self:GetLine (i):SetAttribute (attributeName, attributeValue)
		end
		
		self:GetLine (endLocation:GetLine ()):SetAttribute (attributeName, attributeValue, nil, endLocation:GetCharacter ())
	end
end

function self:SetColor (color, startLocation, endLocation)
	self:SetAttribute ("Color", color, startLocation, endLocation)
end

function self:SetText (text)
	self:Clear ()
	self:Insert (GCompute.IDE.LineCharacterLocation (0, 0), text)
end

function self:ShiftLines (startLine, endLine, shift)
	if startLine > endLine then
		local temp = startLine
		startLine = endLine
		endLine = temp
	end
	
	if startLine < 0 then startLine = 0 end
	if endLine >= self:GetLineCount () then
		endLine = self:GetLineCount () - 1
	end
	if startLine + shift < 0 then shift = -startLine end
	if endLine + shift >= self:GetLineCount () then
		shift = self:GetLineCount () - endLine - 1
	end
	
	if shift == 0 then return end
	
	local lineCount = endLine - startLine + 1
	
	local lines = {}
	for i = 1, lineCount do
		lines [i] = self:GetLine (startLine + i - 1)
	end
	
	if shift < 0 then
		for i = 1, -shift do
			self.Lines [endLine - i + 2] = self.Lines [endLine - i + 2 - lineCount]
			
			if endLine - i + 2 == self:GetLineCount () then
				self.Lines [endLine - i + 2]:Delete (self.Lines [endLine - i + 2]:GetLengthExcludingLineBreak ())
				lines [i]:Insert (lines [i]:GetLengthExcludingLineBreak (), "\n")
			end
		end
	else
		for i = 1, shift do
			self.Lines [startLine + i] = self.Lines [startLine + i + lineCount]
			
			if startLine + i + lineCount == self:GetLineCount () then
				lines [i]:Delete (lines [i]:GetLengthExcludingLineBreak ())
				self.Lines [startLine + i]:Insert (self.Lines [startLine + i]:GetLengthExcludingLineBreak (), "\n")
			end
		end
	end
	
	for i = 1, lineCount do
		self.Lines [startLine + shift + i] = lines [i]
	end
	
	self:DispatchEvent ("LinesShifted", startLine, endLine, shift)
	self:DispatchEvent ("TextChanged")
end

-- Language
function self:DetectLanguage ()
	local language = nil
	if self:HasPath () then
		language = GCompute.LanguageDetector:DetectLanguageByPath (self:GetPath ())
	end
	if not language then
		language = GCompute.LanguageDetector:DetectLanguageByContents (self:GetText ())
	end
	if language then
		self:SetLanguage (language)
	end
end

function self:GetLanguage ()
	return self.Language
end

function self:SetLanguage (language)
	if self.Language == language then return end
	
	local oldLanguage = self.Language
	self.Language = language
	
	self:DispatchEvent ("LanguageChanged", oldLanguage, self.Language)
end

-- Persistance
function self:LoadSession (inBuffer)
	local hasPath = inBuffer:Boolean ()
	local languageName
	if hasPath then
		local path = inBuffer:String ()
		VFS.Root:OpenFile (GLib.GetLocalId (), path, VFS.OpenFlags.Read,
			function (returnCode, fileStream)
				if returnCode ~= VFS.ReturnCode.Success then
					self:SetPath (path)
					return
				end
				self:SetFile (fileStream:GetFile ())
				if GCompute.Languages.Get (languageName) then
					self:SetLanguage (GCompute.Languages.Get (languageName))
				end
				self:LoadFromStream (fileStream,
					function ()
						fileStream:Close ()
					end
				)
			end
		)
	else
		if inBuffer:Boolean () then
			self:MarkUnsaved ()
		end
		self:SetText (inBuffer:LongString ())
	end
	
	languageName = inBuffer:String ()
	if GCompute.Languages.Get (languageName) then
		self:SetLanguage (GCompute.Languages.Get (languageName))
	end
end

function self:SaveSession (outBuffer)
	outBuffer:Boolean (self:HasPath ())
	if self:HasPath () then
		outBuffer:String (self:GetPath ())
	else
		outBuffer:Boolean (self:IsUnsaved ())
		outBuffer:LongString (self:GetText ())
	end
	outBuffer:String (self:GetLanguage () and self:GetLanguage ():GetName () or "")
end

-- ISavable
function self:LoadFromStream (fileStream, callback)
	callback = callback or GCompute.NullCallback ()
	
	fileStream:Read (fileStream:GetLength (),
		function (returnCode, data)
			if returnCode == VFS.ReturnCode.Progress then return end
			
			if returnCode ~= VFS.ReturnCode.Success then
				callback ()
				GCompute.Error (VFS.ReturnCode [returnCode])
			end
			self:SetText (data)
			
			callback ()
		end
	)
end

function self:SaveToStream (fileStream, callback)
	callback = callback or GCompute.NullCallback ()
	
	local code = self:GetText ()
	fileStream:Write (#code, code, callback)
end