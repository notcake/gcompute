local PANEL = {}
surface.CreateFont ("Courier New", 16, 400, false, false, "GComputeMonospace")

--[[
	Events:
		CaretMoved (LineColumnLocation caretLocation)
			Fired when the caret has moved.
		FileChanged (oldFile, newFile)
			Fired when this document's file has changed.
		LexerFinished (Lexer lexer)
			Fired when the lexing process for this document has finished.
		LexerProgress (Lexer lexer, bytesProcessed, totalBytes)
			Fired when the lexer has processed some data.
		LexerStarted (Lexer lexer)
			Fired when the lexing process for this document has started.
		PathChanged (oldPath, path)
			Fired when this document's path has changed.
		SelectionChanged (LineColumnLocation selectionStart, LineColumnLocation selectionEnd)
			Fired when the selection has changed.
		SourceFileChanged (SourceFile oldSourceFile, SourceFile sourceFile)
			Fired when this doumcent's SourceFile has changed.
]]

function PANEL:Init ()
	-- Controls
	self.TextEntry = vgui.Create ("DTextEntry", self)
	self.TextEntry:SetMultiline (true)
	self.TextEntry:SetAllowNonAsciiCharacters (true)
	self.TextEntry.OnKeyCodeTyped = function (_, keyCode)
		self:OnKeyCodeTyped (keyCode)
	end
	self.TextEntry.OnTextChanged = function (textEntry)
		local text = self.TextEntry:GetValue ()
		if text == "" then return end
		
		if self:IsSelectionEmpty () then
			self:InsertText (text)
		else
			self:ReplaceSelectionText (text)
		end
		self.TextEntry:SetText ("")
		
		self:ScrollToCaret ()
	end
	
	self.VScroll = vgui.Create ("GVScrollBar", self)
	self.VScroll:AddEventListener ("EnabledChanged", function () self:InvalidateLayout () end)
	self.HScroll = vgui.Create ("GHScrollBar", self)
	self.HScroll:AddEventListener ("EnabledChanged", function () self:InvalidateLayout () end)
	self.ScrollCorner = vgui.Create ("GScrollBarCorner", self)
	
	self.ContextMenu = nil
	
	-- Data
	self.DefaultContents = false
	self.File = nil
	self.Path = ""
	
	self.Document = GCompute.Editor.Document ()
	self.Document:AddEventListener ("TextCleared",
		function (_)
			self:SetMaximumColumnCount (1)
			
			self:InvalidateSourceFile ()
			self:UpdateLineNumberWidth ()
			self:ResetCaretBlinkTime ()
			self:UpdateScrollBars ()
		end
	)
	self.Document:AddEventListener ("TextDeleted",
		function (_, startLocation, endLocation)
			self:UpdateMaximumColumnCount (self.Document:GetLine (startLocation:GetLine ()):GetColumnCount (self.TextRenderer) + 1)
			
			self:InvalidateSourceFile ()
			self:UpdateLineNumberWidth ()
			self:ResetCaretBlinkTime ()
			self:UpdateScrollBars ()
		end
	)
	self.Document:AddEventListener ("TextInserted",
		function (_, location, text, newLocation)
			local maximumColumnCount = 1
			for i = location:GetLine (), newLocation:GetLine () do
				maximumColumnCount = math.max (maximumColumnCount, self.Document:GetLine (i):GetColumnCount (self.TextRenderer) + 1)
			end
			self:UpdateMaximumColumnCount (maximumColumnCount)
			
			self:InvalidateSourceFile ()
			self:UpdateLineNumberWidth ()
			self:ResetCaretBlinkTime ()
			self:UpdateScrollBars ()
		end
	)
	
	-- Caret
	self.CaretLocation = GCompute.Editor.LineColumnLocation ()
	self.PreferredCaretLocation = GCompute.Editor.LineColumnLocation ()
	self.CaretBlinkTime = SysTime ()
	
	-- Selection
	self.Selecting = false
	self.SelectionStartLocation = GCompute.Editor.LineColumnLocation ()
	self.SelectionEndLocation   = GCompute.Editor.LineColumnLocation ()
	
	-- Settings
	self.TextRenderer = GCompute.Editor.TextRenderer ()
	
	self.Settings = {}
	
	surface.SetFont ("GComputeMonospace")
	self.Settings.CharacterWidth, self.Settings.FontHeight = surface.GetTextSize ("W")
	self.Settings.LineHeight = self.Settings.FontHeight + 2
	self.Settings.LineNumberWidth = self.Settings.CharacterWidth * 4 + 16
	
	-- View
	self.ViewLineCount = 0
	self.ViewColumnCount = 0
	self.MaximumColumnCount = 1
	self.ViewLocation = GCompute.Editor.LineColumnLocation ()
	
	-- Editing
	self.UndoRedoStack = GCompute.UndoRedoStack ()
	
	-- Compiler
	self.SourceFile = nil
	self.CompilationUnit = nil
	self.LastSourceFileUpdateTime = 0
	self.SourceFileOutdated = true
	
	self.TokenApplicationQueue = GCompute.Containers.Queue ()
	
	self:SetSourceFile (GCompute.SourceFileCache:CreateAnonymousSourceFile ())
	
	self:SetKeyboardMap (GCompute.Editor.CodeEditorKeyboardMap)
end

-- Control
function PANEL:GetContextMenu ()
	return self.ContextMenu
end

function PANEL:HasFocus ()
	return self.TextEntry:HasFocus ()
end

function PANEL:PerformLayout ()
	if self.TextEntry then
		self.TextEntry:SetPos (0, 0)
		self.TextEntry:SetSize (0, 0)
	end
	if self.VScroll and self.HScroll then
		local w, h = self:GetSize ()
		w = w - self.Settings.LineNumberWidth
		self.ViewLineCount = math.floor (h / self.Settings.LineHeight)
		self.ViewColumnCount = math.floor (w / self.Settings.CharacterWidth)
		
		local horizontalScrollNeeded = self.ViewColumnCount < self.MaximumColumnCount
		if horizontalScrollNeeded then
			h = h - self.HScroll:GetTall ()
			self.ViewLineCount = math.floor (h / self.Settings.LineHeight)
		end
		local verticalScrollNeeded = self.ViewLineCount < self.Document:GetLineCount ()
		if verticalScrollNeeded then
			w = w - self.VScroll:GetWide ()
			self.ViewColumnCount = math.floor (w / self.Settings.CharacterWidth)
			if not horizontalScrollNeeded and self.ViewColumnCount < self.MaximumColumnCount then
				h = h - self.HScroll:GetTall ()
				self.ViewLineCount = math.floor (h / self.Settings.LineHeight)
			end
		end
		
		self:UpdateScrollBars ()
	end
	if self.VScroll then
		self.VScroll:SetVisible (self.VScroll:IsEnabled ())
		self.VScroll:SetPos (self:GetWide () - 16, 0)
		self.VScroll:SetSize (16, self:GetTall ())
	end
	if self.HScroll then
		self.HScroll:SetVisible (self.HScroll:IsEnabled ())
		self.HScroll:SetPos (0, self:GetTall () - 16)
		self.HScroll:SetSize (self:GetWide (), 16)
	end
	if self.VScroll:IsVisible () and self.HScroll:IsVisible () then
		self.VScroll:SetTall (self:GetTall () - self.HScroll:GetTall ())
		self.HScroll:SetWide (self:GetWide () - self.VScroll:GetWide ())
		self.ScrollCorner:SetPos (self:GetWide () - self.VScroll:GetWide (), self:GetTall () - self.HScroll:GetTall ())
		self.ScrollCorner:SetSize (self.VScroll:GetWide (), self.HScroll:GetTall ())
		self.ScrollCorner:SetVisible (true)
	else
		self.ScrollCorner:SetVisible (false)
	end
end

function PANEL:RequestFocus ()
	self.TextEntry:RequestFocus ()
end

function PANEL:Remove ()
	self:SetSourceFile (nil)
	self:SetCompilationUnit (nil)

	_R.Panel.Remove (self)
end

function PANEL:SetContextMenu (contextMenu)
	self.ContextMenu = contextMenu
end

-- Rendering
function PANEL:DrawCaret ()
	if not self:HasFocus () then return end
	
	local caretX = self.Settings.LineNumberWidth + (self.CaretLocation:GetColumn () - self.ViewLocation:GetColumn ()) * self.Settings.CharacterWidth
	local caretY = (self.CaretLocation:GetLine () - self.ViewLocation:GetLine ()) * self.Settings.LineHeight
	if (SysTime () - self.CaretBlinkTime) % 1 < 0.5 then
		surface.SetDrawColor (GLib.Colors.Gray)
		surface.DrawLine (caretX, caretY, caretX, caretY + self.Settings.LineHeight)
	end
end

function PANEL:DrawCaretLineHightlighting ()
	local caretY = (self.CaretLocation:GetLine () - self.ViewLocation:GetLine ()) * self.Settings.LineHeight
	surface.SetDrawColor (Color (32, 32, 64, 255))
	surface.DrawRect (self.Settings.LineNumberWidth, caretY, self:GetWide () - self.Settings.LineNumberWidth, self.Settings.LineHeight)
end

function PANEL:DrawLine (lineOffset)
	local lineNumber = self.ViewLocation:GetLine () + lineOffset
	local line = self.Document:GetLine (lineNumber)
	if not line then return end
	
	local y = lineOffset * self.Settings.LineHeight + 0.5 * (self.Settings.LineHeight - self.Settings.FontHeight)
	local x = self.Settings.LineNumberWidth
	local w = self:GetWide ()
	
	surface.SetFont ("GComputeMonospace")
	
	-- Localize values used in loop
	local surface              = surface
	local surface_SetTextColor = surface.SetTextColor
	local surface_SetTextPos   = surface.SetTextPos
	local surface_DrawText     = surface.DrawText
	local defaultColor         = GLib.Colors.White
	local viewColumnCount      = self.ViewColumnCount
	local viewLocationColumn   = self.ViewLocation:GetColumn ()
	local characterWidth       = self.Settings.CharacterWidth
	local lineNumberWidth      = self.Settings.LineNumberWidth
	
	local node, currentColumn = line.TextStorage:NodeFromColumn (viewLocationColumn, self.TextRenderer)
	local columnCount
	x = x - currentColumn * characterWidth
	currentColumn = viewLocationColumn - currentColumn
	while node and x <= w do
		surface_SetTextColor (node.Color)
		surface_SetTextPos (x, y)
		surface_DrawText (node.Text)
		
		columnCount = node:GetColumnCount (self.TextRenderer)
		currentColumn = currentColumn + columnCount
		x = x + columnCount * characterWidth
		node = node.Next
	end
end

function PANEL:DrawSelection ()
	local selectionStart = self.SelectionStartLocation
	local selectionEnd = self.SelectionEndLocation
	
	if selectionStart:Equals (selectionEnd) then return end
	
	if selectionStart:IsAfter (selectionEnd) then
		selectionStart = self.SelectionEndLocation
		selectionEnd = self.SelectionStartLocation
	end
	
	local roundTopLeft = true
	local roundTopRight = true
	local leftColumn = 0
	local rightColumn = 0
	local nextLeftColumn = 0
	local nextRightColumn = 0
	
	local nextLine = self.Document:GetLine (selectionStart:GetLine ())
	
	leftColumn = selectionStart:GetColumn () - self.ViewLocation:GetColumn ()
	rightColumn = nextLine:GetColumnCount (self.TextRenderer) + 1 - self.ViewLocation:GetColumn ()
	
	for i = math.max (selectionStart:GetLine (), self.ViewLocation:GetLine () - 2), selectionEnd:GetLine () - 1 do
		-- Don't bother drawing selection highlighting for lines out of view
		if i > self.ViewLocation:GetLine () + self.ViewLineCount + 2 then break end
	
		nextLine = self.Document:GetLine (i + 1)
	
		nextLeftColumn = -self.ViewLocation:GetColumn ()
		nextRightColumn = nextLine:GetColumnCount (self.TextRenderer) + 1 - self.ViewLocation:GetColumn ()
		if i == selectionEnd:GetLine () - 1 then
			nextRightColumn = selectionEnd:GetColumn () - self.ViewLocation:GetColumn ()
		end
		
		if leftColumn ~= rightColumn then
			draw.RoundedBoxEx (
				4,
				self.Settings.LineNumberWidth + leftColumn * self.Settings.CharacterWidth,
				(i - self.ViewLocation:GetLine ()) * self.Settings.LineHeight,
				(rightColumn - leftColumn) * self.Settings.CharacterWidth,
				self.Settings.LineHeight,
				GLib.Colors.SteelBlue,
				roundTopLeft, roundTopRight,
				nextLeftColumn > leftColumn or nextRightColumn <= leftColumn, nextRightColumn < rightColumn
			)
		end
		
		roundTopLeft = nextLeftColumn < leftColumn
		roundTopRight = nextRightColumn > rightColumn or nextRightColumn <= leftColumn
		
		leftColumn  = nextLeftColumn
		rightColumn = nextRightColumn
	end
	
	nextRightColumn = selectionEnd:GetColumn () - self.ViewLocation:GetColumn ()
	rightColumn = nextRightColumn
	
	if leftColumn ~= rightColumn then
		draw.RoundedBoxEx (
			4,
			self.Settings.LineNumberWidth + leftColumn * self.Settings.CharacterWidth,
			(selectionEnd:GetLine () - self.ViewLocation:GetLine ()) * self.Settings.LineHeight,
			(rightColumn - leftColumn) * self.Settings.CharacterWidth,
			self.Settings.LineHeight,
			GLib.Colors.SteelBlue,
			roundTopLeft, roundTopRight,
			true, true
		)
	end
end

function PANEL:Paint ()
	-- Draw background
	surface.SetDrawColor (32, 32, 32, 255)
	surface.DrawRect (self.Settings.LineNumberWidth, 0, self:GetWide () - self.Settings.LineNumberWidth, self:GetTall ())
	
	self:DrawCaretLineHightlighting ()
	self:DrawSelection ()
	self:DrawCaret ()
	
	-- Draw ViewLineCount lines and then the one that's partially out of view.
	for i = 0, self.ViewLineCount do
		self:DrawLine (i)
	end
	
	-- Draw line numbers
	surface.SetDrawColor (GLib.Colors.Gray)
	surface.DrawRect (0, 0, self.Settings.LineNumberWidth, self:GetTall ())
	for i = 0, math.min (self.ViewLineCount, self.Document:GetLineCount () - self.ViewLocation:GetLine () - 1) do
		draw.SimpleText (tostring (self.ViewLocation:GetLine () + i + 1), "GComputeMonospace", self.Settings.LineNumberWidth - 16, i * self.Settings.LineHeight + 0.5 * (self.Settings.LineHeight - self.Settings.FontHeight), GLib.Colors.White, TEXT_ALIGN_RIGHT)
	end
end

-- Data
function PANEL:GetDocument ()
	return self.Document
end

function PANEL:GetFile ()
	return self.File
end

function PANEL:GetPath ()
	return self.Path
end

function PANEL:HasFile ()
	return self.File and true or false
end

function PANEL:HasPath ()
	return self.Path and self.Path ~= "" or false
end

function PANEL:IsDefaultContents ()
	return self.DefaultContents
end

function PANEL:SetDefaultContents (defaultContents)
	self.DefaultContents = defaultContents
	self.UndoRedoStack:SetSavableAtStart (defaultContents)
end

function PANEL:SetFile (file)
	if self.File == file then return end
	
	local oldFile = self.File
	local oldPath = self.Path
	self.File = file
	self.Path = file and file:GetPath () or ""
	
	if self.Path == "" then
		-- If our source file is not an unnamed one, create a new unnamed SourceFile
		if self.SourceFile:HasPath () then
			self:SetSourceFile (GCompute.SourceFileCache:CreateAnonymousSourceFile ())
		end
	else
		self:SetSourceFile (GCompute.SourceFileCache:CreateSourceFileFromPath (self.Path))
		self:SetDefaultContents (false)
	end
	
	self:DispatchEvent ("FileChanged", oldFile, self.File)
	self:DispatchEvent ("PathChanged", oldPath, self.Path)
end

-- Undo / redo
function PANEL:CanSave ()
	return self.UndoRedoStack:CanSave ()
end

function PANEL:GetUndoRedoStack ()
	return self.UndoRedoStack
end

function PANEL:IsUnsaved ()
	return self.UndoRedoStack:IsUnsaved ()
end

function PANEL:MarkSaved ()
	self.UndoRedoStack:MarkSaved ()
end

function PANEL:Redo ()
	self.UndoRedoStack:Redo ()
end

function PANEL:Undo ()
	self.UndoRedoStack:Undo ()
end

-- Editing
function PANEL:GetText ()
	return self.Document:GetText ()
end

function PANEL:InsertText (text)
	local insertionLocation = self.Document:ColumnToCharacter (self.CaretLocation, self.TextRenderer)
	local insertionAction = GCompute.Editor.InsertionAction (self, insertionLocation, text)
	insertionAction:Redo ()
	self.UndoRedoStack:Push (insertionAction)
end

function PANEL:ReplaceSelectionText (text)
	local selectionStartLocation = self.Document:ColumnToCharacter (self.SelectionStartLocation, self.TextRenderer)
	local selectionEndLocation   = self.Document:ColumnToCharacter (self.SelectionEndLocation, self.TextRenderer)
	local originalText = self.Document:GetText (selectionStartLocation, selectionEndLocation)
	
	local replacementAction = GCompute.Editor.ReplacementAction (self, selectionStartLocation, selectionEndLocation, originalText, text)
	replacementAction:Redo ()
	self.UndoRedoStack:Push (replacementAction)
end

function PANEL:SetText (text)

	local startTime = SysTime ()
	self.Document:SetText (text)
	self:UpdateScrollBars ()
	
	if SysTime () - startTime > 0 then
		ErrorNoHalt (string.format ("CodeEditor:SetText took %.5f ms.\n", (SysTime () - startTime) * 1000))
	end
end

-- Caret
function PANEL:FixupColumn (columnLocation)
	-- Round to nearest column
	local line = self.Document:GetLine (columnLocation:GetLine ())
	local column = columnLocation:GetColumn ()
	local character, leftColumn = line:CharacterFromColumn (column, self.TextRenderer)
	local rightColumn = leftColumn + self.TextRenderer:GetCharacterColumnCount (line:GetCharacter (character))
	
	if column - leftColumn < rightColumn - column then
		column = leftColumn
	else
		column = rightColumn
	end

	return GCompute.Editor.LineColumnLocation (columnLocation:GetLine (), column)
end

function PANEL:GetCaretPos ()
	return self.CaretLocation
end

function PANEL:MoveCaretLeft (overrideSelectionStart)
	if self.CaretLocation:GetColumn () == 0 then
		if self.CaretLocation:GetLine () == 0 then return end
		
		self:SetRawCaretPos (GCompute.Editor.LineColumnLocation (
			self.CaretLocation:GetLine () - 1,
			self.Document:GetLine (self.CaretLocation:GetLine () - 1):GetColumnCount (self.TextRenderer)
		))
	else
		local line = self.Document:GetLine (self.CaretLocation:GetLine ())
		local column = self.CaretLocation:GetColumn ()
		
		local character = line:CharacterFromColumn (column, self.TextRenderer)
		column = column - self.TextRenderer:GetCharacterColumnCount (line:GetCharacter (character - 1))
		
		self:SetRawCaretPos (GCompute.Editor.LineColumnLocation (
			self.CaretLocation:GetLine (),
			column
		))
	end
	
	if overrideSelectionStart then
		self:SetSelection (self.CaretLocation, self.CaretLocation)
	else
		self:SetSelectionEnd (self.CaretLocation)
	end
end

function PANEL:MoveCaretRight (overrideSelectionStart)
	if self.CaretLocation:GetColumn () == self.Document:GetLine (self.CaretLocation:GetLine ()):GetColumnCount (self.TextRenderer) then
		if self.CaretLocation:GetLine () + 1 == self.Document:GetLineCount () then return end
		
		self:SetRawCaretPos (GCompute.Editor.LineColumnLocation (
			self.CaretLocation:GetLine () + 1,
			0
		))
	else
		local line = self.Document:GetLine (self.CaretLocation:GetLine ())
		local column = self.CaretLocation:GetColumn ()
		
		local character = line:CharacterFromColumn (column, self.TextRenderer)
		column = column + self.TextRenderer:GetCharacterColumnCount (line:GetCharacter (character))
		
		self:SetRawCaretPos (GCompute.Editor.LineColumnLocation (
			self.CaretLocation:GetLine (),
			column
		))
	end
	
	if overrideSelectionStart then
		self:SetSelection (self.CaretLocation, self.CaretLocation)
	else
		self:SetSelectionEnd (self.CaretLocation)
	end
end

function PANEL:MoveCaretUp (overrideSelectionStart)
	if self.CaretLocation:GetLine () == 0 then
		self:SetRawCaretPos (GCompute.Editor.LineColumnLocation (0, 0))
	else
		self:SetPreferredCaretPos (GCompute.Editor.LineColumnLocation (
			self.PreferredCaretLocation:GetLine () - 1,
			self.PreferredCaretLocation:GetColumn ()
		))
	end
	
	if overrideSelectionStart then
		self:SetSelection (self.CaretLocation, self.CaretLocation)
	else
		self:SetSelectionEnd (self.CaretLocation)
	end
end

function PANEL:MoveCaretDown (overrideSelectionStart)
	if self.CaretLocation:GetLine () + 1 == self.Document:GetLineCount () then
		self:SetRawCaretPos (GCompute.Editor.LineColumnLocation (
			self.CaretLocation:GetLine (),
			self.Document:GetLine (self.CaretLocation:GetLine ()):GetColumnCount (self.TextRenderer)
		))
	else
		self:SetPreferredCaretPos (GCompute.Editor.LineColumnLocation (
			self.PreferredCaretLocation:GetLine () + 1,
			self.PreferredCaretLocation:GetColumn ()
		))
	end
	
	if overrideSelectionStart then
		self:SetSelection (self.CaretLocation, self.CaretLocation)
	else
		self:SetSelectionEnd (self.CaretLocation)
	end
end

--- Makes the caret visible for another caret blink interval
function PANEL:ResetCaretBlinkTime ()
	self.CaretBlinkTime = SysTime ()
end

function PANEL:ScrollToCaret ()
	self:ScrollToCaretLine ()
	self:ScrollToCaretColumn ()
end

function PANEL:ScrollToCaretColumn ()
	local caretColumn = self.CaretLocation:GetColumn ()
	local leftViewColumn = self.ViewLocation:GetColumn ()
	local rightViewColumn = leftViewColumn + self.ViewColumnCount - 1
	
	if leftViewColumn <= caretColumn and caretColumn <= rightViewColumn then return end
	if caretColumn < leftViewColumn then
		self:SetHorizontalScrollPos (caretColumn)
	else
		self:SetHorizontalScrollPos (caretColumn - self.ViewColumnCount + 1)
	end
end

function PANEL:ScrollToCaretLine ()
	local caretLine = self.CaretLocation:GetLine ()
	local topViewLine = self.ViewLocation:GetLine ()
	local bottomViewLine = topViewLine + self.ViewLineCount - 1
	
	if topViewLine <= caretLine and caretLine <= bottomViewLine then return end
	if caretLine < topViewLine then
		self:SetVerticalScrollPos (caretLine)
	else
		self:SetVerticalScrollPos (caretLine - self.ViewLineCount + 1)
	end
end

--- Sets the caret location, adjusting to the nearest available column. Also sets the preferred caret location to the rounded caret location.
-- @param caretLocation The new caret location
-- @param scrollToCaret Whether the view should be scrolled to make the caret visible
function PANEL:SetCaretPos (caretLocation, scrollToCaret)
	self:SetRawCaretPos (self:FixupColumn (caretLocation), scrollToCaret)
end

--- Sets the preferred caret location. The actual caret location is adjusted to the nearest available column.
-- @param preferredCaretLocation The new preferred caret location
-- @param scrollToCaret Whether the view should be scrolled to make the caret visible
function PANEL:SetPreferredCaretPos (preferredCaretLocation, scrollToCaret)
	if scrollToCaret == nil then scrollToCaret = true end
	if self.PreferredCaretLocation:Equals (preferredCaretLocation) then return end
	
	self.CaretLocation:CopyFrom (self:FixupColumn (preferredCaretLocation))
	self.PreferredCaretLocation:CopyFrom (preferredCaretLocation)
	self:DispatchEvent ("CaretMoved", self.CaretLocation)
	
	self:ResetCaretBlinkTime ()
	if scrollToCaret then
		self:ScrollToCaret ()
	end
end

--- Sets the caret location and preferred caret location. No adjustments are made.
-- @param caretLocation The new caret location
-- @param scrollToCaret Whether the view should be scrolled to make the caret visible
function PANEL:SetRawCaretPos (caretLocation, scrollToCaret)
	if scrollToCaret == nil then scrollToCaret = true end
	if self.CaretLocation:Equals (caretLocation) then return end
	
	self.CaretLocation:CopyFrom (caretLocation)
	self.PreferredCaretLocation:CopyFrom (caretLocation)
	self:DispatchEvent ("CaretMoved", self.CaretLocation)
	
	self:ResetCaretBlinkTime ()
	if scrollToCaret then
		self:ScrollToCaret ()
	end
end

-- Selection
function PANEL:DeleteSelection ()
	if self.SelectionStartLocation:Equals (self.SelectionEndLocation) then return end
	
	local selectionStartLocation = self.Document:ColumnToCharacter (self.SelectionStartLocation, self.TextRenderer)
	local selectionEndLocation   = self.Document:ColumnToCharacter (self.SelectionEndLocation, self.TextRenderer)
	local text = self.Document:GetText (selectionStartLocation, selectionEndLocation)
	
	local deletionAction = GCompute.Editor.DeletionAction (self, selectionStartLocation, selectionEndLocation, selectionStartLocation, selectionEndLocation, text)
	deletionAction:Redo ()
	self.UndoRedoStack:Push (deletionAction)
end

function PANEL:GetSelectionEnd ()
	return self.SelectionEndLocation
end

function PANEL:GetSelectionStart ()
	return self.SelectionStartLocation
end

function PANEL:IsInSelection (location)
	local selectionStart = self.SelectionStartLocation
	local selectionEnd   = self.SelectionEndLocation
	if self.SelectionStartLocation:IsAfter (self.SelectionEndLocation) then
		selectionStart = self.SelectionEndLocation
		selectionEnd   = self.SelectionStartLocation
	end
	return selectionStart:IsEqualOrBefore (location) and selectionEnd:IsEqualOrAfter (location)
end

function PANEL:IsSelectionEmpty ()
	return self.SelectionStartLocation:Equals (self.SelectionEndLocation)
end

function PANEL:SelectAll ()
	self:SetSelection (
		self.Document:CharacterToColumn (self.Document:GetStart (), self.TextRenderer),
		self.Document:CharacterToColumn (self.Document:GetEnd (), self.TextRenderer)
	)
end

function PANEL:SetSelection (selectionStart, selectionEnd)
	selectionEnd = selectionEnd or selectionStart
	
	self.SelectionStartLocation:CopyFrom (selectionStart)
	self.SelectionEndLocation:CopyFrom (selectionEnd)
	
	self:DispatchEvent ("SelectionChanged", self.SelectionStartLocation, self.CaretLocation)
end

function PANEL:SetSelectionEnd (selectionEnd)
	self.SelectionEndLocation:CopyFrom (selectionEnd)
	
	self:DispatchEvent ("SelectionChanged", self.SelectionStartLocation, self.CaretLocation)
end

function PANEL:SetSelectionStart (selectionStart)
	self.SelectionStartLocation:CopyFrom (selectionStart)
	
	self:DispatchEvent ("SelectionChanged", self.SelectionStartLocation, self.CaretLocation)
end

-- View
function PANEL:PointToLocation (x, y)
	local line = self.ViewLocation:GetLine () + math.floor (y / self.Settings.LineHeight)
	local column = self.ViewLocation:GetColumn ()
	
	column = column + (x - self.Settings.LineNumberWidth) / self.Settings.CharacterWidth
	
	-- Clamp line
	if line < 0 then line = 0 end
	if line >= self.Document:GetLineCount () then
		line = self.Document:GetLineCount () - 1
	end
	
	local lineWidth = self.Document:GetLine (line):GetColumnCount (self.TextRenderer)
	if column < 0 then
		column = 0
	elseif column > lineWidth then
		column = lineWidth
	else
		-- Snap to nearest column
		local line = self.Document:GetLine (line)
		local character, leftColumn = line:CharacterFromColumn (math.floor (column), self.TextRenderer)
		local rightColumn = leftColumn + self.TextRenderer:GetCharacterColumnCount (line:GetCharacter (character))
		
		if column - leftColumn < rightColumn - column then
			column = leftColumn
		else
			column = rightColumn
		end
	end
	return GCompute.Editor.LineColumnLocation (line, column)
end

function PANEL:ScrollRelative (deltaLines)
	local topLine = self.ViewLocation:GetLine () + deltaLines
	if topLine + self.ViewLineCount >= self.Document:GetLineCount () then
		topLine = self.Document:GetLineCount () - self.ViewLineCount
	end
	if topLine < 0 then topLine = 0 end
	self:SetVerticalScrollPos (topLine)
end

function PANEL:SetHorizontalScrollPos (leftColumn)
	if leftColumn < 0 then leftColumn = 0 end
	self.HScroll:SetViewOffset (leftColumn)
end

function PANEL:SetVerticalScrollPos (topLine)
	if topLine < 0 then topLine = 0 end
	self.VScroll:SetViewOffset (topLine)
end

function PANEL:UpdateLineNumberWidth ()
	local maxDisplayedLineNumber = tostring (self.Document:GetLineCount () + 1)
	local lineNumberWidth = self.Settings.CharacterWidth * (string.len (maxDisplayedLineNumber) + 1) + 16
	if self.Settings.LineNumberWidth == lineNumberWidth then return end
	
	self.Settings.LineNumberWidth = lineNumberWidth
	self:InvalidateLayout ()
end

function PANEL:UpdateScrollBars ()
	self.VScroll:SetViewSize (self.ViewLineCount)
	self.VScroll:SetContentSize (self.Document:GetLineCount ())
	self.HScroll:SetViewSize (self.ViewColumnCount)
	self.HScroll:SetContentSize (self.MaximumColumnCount)
end

-- Clipboard
function PANEL:CopySelection ()
	if self.SelectionStartLocation:Equals (self.SelectionEndLocation) then return end
	
	local selectionStart = self.Document:ColumnToCharacter (self.SelectionStartLocation, self.TextRenderer)
	local selectionEnd   = self.Document:ColumnToCharacter (self.SelectionEndLocation, self.TextRenderer)
	
	Gooey.Clipboard:SetText (self.Document:GetText (selectionStart, selectionEnd))
end

function PANEL:CutSelection ()
	if self.SelectionStartLocation:Equals (self.SelectionEndLocation) then return end
	
	local selectionStart = self.Document:ColumnToCharacter (self.SelectionStartLocation, self.TextRenderer)
	local selectionEnd   = self.Document:ColumnToCharacter (self.SelectionEndLocation, self.TextRenderer)
	
	local text = self.Document:GetText (selectionStart, selectionEnd)
	Gooey.Clipboard:SetText (text)
	
	local deletionAction = GCompute.Editor.DeletionAction (self, selectionStart, selectionEnd, selectionStart, selectionEnd, text)
	deletionAction:SetVerb ("cut")
	deletionAction:Redo ()
	self.UndoRedoStack:Push (deletionAction)
end

function PANEL:Paste ()
	self.TextEntry:PostMessage ("DoPaste", "", "")
end

-- Compiler
function PANEL:GetCompilationUnit ()
	return self.CompilationUnit
end

function PANEL:GetSourceFile ()
	return self.SourceFile
end

function PANEL:InvalidateSourceFile ()
	self.SourceFileOutdated = true
end

function PANEL:IsSourceFileOutdated ()
	return self.SourceFileOutdated
end

-- Internal function, do not call
function PANEL:SetCompilationUnit (compilationUnit)
	if self.CompilationUnit == compilationUnit then return end
	
	self:UnhookCompilationUnit (self.CompilationUnit)
	self.CompilationUnit = compilationUnit
	self:HookCompilationUnit (self.CompilationUnit)
	
	if self.CompilationUnit then
		local tokens = self.CompilationUnit:GetTokens ()
		if tokens then
			self:QueueTokenApplication (tokens.First, tokens.Last)
		else
			self:ClearTokenization ()
		end
	else
		self:ClearTokenization ()
	end
end

-- Internal function, do not call
function PANEL:SetSourceFile (sourceFile)
	if not sourceFile then return end
	if self.SourceFile == sourceFile then return end
	
	local oldSourceFile = self.SourceFile
	if self.SourceFile then
		self:UnhookSourceFile (self.SourceFile)
		self:SetCompilationUnit (nil)
	end
	
	self.SourceFile = sourceFile
	
	if self.SourceFile then
		self:HookSourceFile (self.SourceFile)
		if self.SourceFile:HasCompilationUnit () then
			self:SetCompilationUnit (self.SourceFile:GetCompilationUnit ())
		end
	end
	
	self:DispatchEvent ("SourceFileChanged", oldSourceFile, sourceFile)
end

-- Internal, do not call
function PANEL:ApplyToken (token)
	if not token then return end
	local startLine = token.Line
	local endLine = token.EndLine
	
	local color = self:GetTokenColor (token)
	if not self.Document:GetLine (startLine) then return end
	
	if startLine == endLine then
		self.Document:GetLine (startLine):SetColor (color, token.Character, token.EndCharacter)
	else
		self.Document:GetLine (startLine):SetColor (color, token.Character, nil)
		if self.Document:GetLine (endLine) then
			self.Document:GetLine (endLine):SetColor (color, 0, token.EndCharacter)
		end
		
		for i = startLine + 1, endLine - 1 do
			if not self.Document:GetLine (i) then break end
			self.Document:GetLine (i):SetColor (color)
		end
	end
end

function PANEL:ClearTokenization ()
	for line in self.Document:GetEnumerator () do
		line:SetColor (nil)
	end
	self.TokenApplicationQueue:Clear ()
end

function PANEL:GetTokenColor (token)
	local tokenType = token.TokenType
	if tokenType == GCompute.TokenType.String then
		return GLib.Colors.Gray
	elseif tokenType == GCompute.TokenType.Number then
		return GLib.Colors.SandyBrown
	elseif tokenType == GCompute.TokenType.Comment then
		return GLib.Colors.ForestGreen
	elseif tokenType == GCompute.TokenType.Keyword then
		return GLib.Colors.RoyalBlue
	elseif tokenType == GCompute.TokenType.Preprocessor then
		return GLib.Colors.Yellow
	elseif tokenType == GCompute.TokenType.Identifier then
		return GLib.Colors.LightSkyBlue
	elseif tokenType == GCompute.TokenType.Unknown then
		return GLib.Colors.Tomato
	end
	return GLib.Colors.White
end

function PANEL:QueueTokenApplication (startToken, endToken)
	self.TokenApplicationQueue:Enqueue ({ Start = startToken, End = endToken })
end

-- Internal, do not call
function PANEL:SetMaximumColumnCount (columnCount)
	if self.MaximumColumnCount == columnCount then return end
	self.MaximumColumnCount = columnCount
	self.HScroll:SetContentSize (columnCount)
end

function PANEL:UpdateMaximumColumnCount (columnCount)
	if self.MaximumColumnCount >= columnCount then return end
	self:SetMaximumColumnCount (columnCount)
end

-- Internal, do not call
function PANEL:HookCompilationUnit (compilationUnit)
	if not compilationUnit then return end
	
	compilationUnit:AddEventListener ("LexerFinished", tostring (self:GetTable ()),
		function (_, lexer)
			self:DispatchEvent ("LexerFinished", lexer)
		end
	)
	compilationUnit:AddEventListener ("LexerProgress", tostring (self:GetTable ()),
		function (_, lexer, bytesProcessed, totalBytes)
			self:DispatchEvent ("LexerProgress", lexer, bytesProcessed, totalBytes)
		end
	)
	compilationUnit:AddEventListener ("LexerStarted", tostring (self:GetTable ()),
		function (_, lexer)
			self:DispatchEvent ("LexerStarted", lexer)
		end
	)
	compilationUnit:AddEventListener ("TokenRangeAdded", tostring (self:GetTable ()),
		function (_, startToken, endToken)
			self:QueueTokenApplication (startToken, endToken)
			self:DispatchEvent ("LexerProgress", startToken, endToken)
		end
	)
end

function PANEL:UnhookCompilationUnit (compilationUnit)
	if not compilationUnit then return end
	
	compilationUnit:RemoveEventListener ("LexerFinished",     tostring (self:GetTable ()))
	compilationUnit:RemoveEventListener ("LexerProgress",     tostring (self:GetTable ()))
	compilationUnit:RemoveEventListener ("LexerStarted",      tostring (self:GetTable ()))
	compilationUnit:RemoveEventListener ("TokenRangeAdded",   tostring (self:GetTable ()))
	compilationUnit:RemoveEventListener ("TokenRangeRemoved", tostring (self:GetTable ()))
end

function PANEL:HookSourceFile (sourceFile)
	if not sourceFile then return end
	sourceFile:AddEventListener ("CompilationUnitCreated", tostring (self:GetTable ()),
		function (_, compilationUnit)
			self:SetCompilationUnit (compilationUnit)
		end
	)
end

function PANEL:UnhookSourceFile (sourceFile)
	if not sourceFile then return end
	sourceFile:RemoveEventListener ("CompilationUnitCreated", tostring (self:GetTable ()))
end

-- Event handlers
function PANEL:OnGetFocus ()
	self.TextEntry:RequestFocus ()
end

function PANEL:OnKeyCodePressed (keyCode)
	-- Override and ignore, since we receive forwarded OnKeyCodeTyped events from our hidden TextEntry
	-- We don't received repeated keystrokes from keys being held down otherwise.
end

function PANEL:OnKeyCodeTyped (keyCode)
	local ctrl    = input.IsKeyDown (KEY_LCONTROL) or input.IsKeyDown (KEY_RCONTROL)
	local shift   = input.IsKeyDown (KEY_LSHIFT)   or input.IsKeyDown (KEY_RSHIFT)
	local alt     = input.IsKeyDown (KEY_LALT)     or input.IsKeyDown (KEY_RALT)
	
	if keyCode == KEY_TAB then
		if self:IsSelectionEmpty () then
			self:InsertText ("\t")
		else
			self:ReplaceSelectionText ("\t")
		end
	elseif keyCode == KEY_A then
		if ctrl then
			self:SelectAll ()
		end
	end
	
	self:GetKeyboardMap ():Execute (self, keyCode, ctrl, shift, alt)
end

function PANEL:OnMouseDown (mouseCode, x, y)
	local control = input.IsKeyDown (KEY_LCONTROL) or input.IsKeyDown (KEY_RCONTROL)
	local shift   = input.IsKeyDown (KEY_LSHIFT)   or input.IsKeyDown (KEY_RSHIFT)
	local alt     = input.IsKeyDown (KEY_LALT)     or input.IsKeyDown (KEY_RALT)
	
	self:RequestFocus ()
	
	if mouseCode == MOUSE_LEFT then
		if x <= self.Settings.LineNumberWidth then
		else
			self.Selecting = true
			self:SetRawCaretPos (self:PointToLocation (self:CursorPos ()))
			
			if shift then
				self:SetSelectionEnd (self.CaretLocation)
			else
				self:SetSelection (self.CaretLocation, self.CaretLocation)
			end
			
			self:MouseCapture (true)
		end
	elseif mouseCode == MOUSE_RIGHT then
		if x <= self.Settings.LineNumberWidth then
		else
			local caretLocation = self:PointToLocation (self:CursorPos ())
			if not self:IsInSelection (caretLocation) then
				self:SetRawCaretPos (caretLocation)
				self:SetSelection (self.CaretLocation, self.CaretLocation)
			end
		end
	end
end

function PANEL:OnMouseMove (mouseCode, x, y)
	if self.Selecting then
		self:SetRawCaretPos (self:PointToLocation (x, y))
		
		self:SetSelectionEnd (self.CaretLocation)
	else
		if x <= self.Settings.LineNumberWidth then
			self:SetCursor ("arrow")
		else
			self:SetCursor ("beam")
		end
	end
end

function PANEL:OnMouseUp (mouseCode, x, y)
	if mouseCode == MOUSE_LEFT then
		self.Selecting = false
		
		self:MouseCapture (false)
	elseif mouseCode == MOUSE_RIGHT then
		if self.ContextMenu then
			self.ContextMenu:Open ()
		end
	end
end

function PANEL:OnMouseWheel (delta)
	self.VScroll:OnMouseWheeled (delta)
end

function PANEL:OnHScroll (viewOffset)
	if self.ViewColumnCount < self.MaximumColumnCount then
		self.ViewLocation:SetColumn (math.floor (viewOffset))
	else
		self.ViewLocation:SetColumn (0)
	end
end

function PANEL:OnVScroll (viewOffset)
	if self.ViewLineCount < self.Document:GetLineCount () then
		self.ViewLocation:SetLine (math.floor (viewOffset))
	else
		self.ViewLocation:SetLine (0)
	end
end

function PANEL:Think ()
	if self.SourceFileOutdated then
		if SysTime () - self.LastSourceFileUpdateTime > 0.2 then
			if self:GetCompilationUnit ():IsLexing () then return end
			
			self.SourceFileOutdated = false
			self.LastSourceFileUpdateTime = SysTime ()
			
			self.SourceFile:SetCode (self:GetText ())
			self:GetCompilationUnit ():Lex (
				function ()
				end
			)
			
			if not self:GetCompilationUnit ():IsLexing () then
				local tokens = self:GetCompilationUnit ():GetTokens ()
				if tokens then
					self.TokenApplicationQueue:Clear ()
					self:QueueTokenApplication (tokens.First, tokens.Last)
				end
			end
		end
	end
	
	self:TokenApplicationThink ()
end

function PANEL:TokenApplicationThink ()
	if self.TokenApplicationQueue:IsEmpty () then return end
	
	local startTime = SysTime ()
	while SysTime () - startTime < 0.010 do
		local front = self.TokenApplicationQueue.Front
		if not front then break end
		
		local appliedTokenCount = 0
		while appliedTokenCount < 10 do
			self:ApplyToken (front.Start)
			if not self.Document:GetLine (front.Start.Line) then
				self.TokenApplicationQueue:Dequeue ()
				break
			end
			appliedTokenCount = appliedTokenCount + 1
			if front.Start == front.End then
				self.TokenApplicationQueue:Dequeue ()
				break
			end
			front.Start = front.Start.Next
		end
	end
	
	if SysTime () - startTime > 0 then
		ErrorNoHalt (string.format ("CodeEditor:TokenApplicationThink took %.5f ms.\n", (SysTime () - startTime) * 1000))
	end
end

vgui.Register ("GComputeCodeEditor", PANEL, "GPanel")