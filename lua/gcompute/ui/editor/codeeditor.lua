local PANEL = {}
surface.CreateFont ("Courier New", 16, 400, false, false, "GComputeMonospace")

--[[
	Events:
		CaretMoved (LineColumnLocation caretLocation)
			Fired when the caret has moved.
		FileChanged (oldFile, newFile)
			Fired when this document's file has changed.
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
	
	self.VScroll = vgui.Create ("DVScrollBar", self)
	self.VScroll:SetUp (0, 0)
	
	self.ContextMenu = nil
	
	-- Data
	self.DefaultContents = false
	self.File = nil
	self.Path = ""
	
	self.Document = GCompute.Editor.Document ()
	self.Document:AddEventListener ("TextCleared",  function () self:InvalidateSourceFile () self:ResetCaretBlinkTime () self:UpdateScrollBar () end)
	self.Document:AddEventListener ("TextDeleted",  function () self:InvalidateSourceFile () self:ResetCaretBlinkTime () self:UpdateScrollBar () end)
	self.Document:AddEventListener ("TextInserted", function () self:InvalidateSourceFile () self:ResetCaretBlinkTime () self:UpdateScrollBar () end)
	
	-- Caret
	self.CaretLocation = GCompute.Editor.LineColumnLocation ()
	self.PreferredCaretLocation = GCompute.Editor.LineColumnLocation ()
	self.CaretBlinkTime = SysTime ()
	
	-- Selection
	self.Selecting = false
	self.SelectionStartLocation = GCompute.Editor.LineColumnLocation ()
	self.SelectionEndLocation   = GCompute.Editor.LineColumnLocation ()
	
	-- Settings
	self.Settings = {}
	self.Settings.TabWidth = 4
	
	surface.SetFont ("GComputeMonospace")
	self.Settings.CharacterWidth, self.Settings.FontHeight = surface.GetTextSize ("W")
	self.Settings.LineHeight = self.Settings.FontHeight + 2
	self.Settings.LineNumberWidth = self.Settings.CharacterWidth * 4 + 16
	
	-- View
	self.ViewLineCount = 0
	self.ViewColumnCount = 0
	self.ViewLocation = GCompute.Editor.LineColumnLocation ()
	
	-- Editing
	self.UndoRedoStack = GCompute.UndoRedoStack ()
	
	-- Compiler
	self.SourceFile = nil
	self.CompilationUnit = nil
	self.LastSourceFileUpdateTime = 0
	self.SourceFileOutdated = true
	
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
	self.ViewLineCount = math.floor (self:GetTall () / self.Settings.LineHeight)
	self.ViewColumnCount = math.floor ((self:GetWide () - self.Settings.LineNumberWidth) / self.Settings.CharacterWidth)
	if self.TextEntry then
		self.TextEntry:SetPos (0, 0)
		self.TextEntry:SetSize (0, 0)
	end
	if self.VScroll then
		self.VScroll:SetPos (self:GetWide () - 16, 0)
		self.VScroll:SetSize (16, self:GetTall ())
		self.VScroll:SetUp (self.ViewLineCount, self.Document:GetLineCount ())
	end
end

function PANEL:RequestFocus ()
	self.TextEntry:RequestFocus ()
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
	
	local character, column = line:CharacterFromColumn (self.ViewLocation:GetColumn ())
	x = x - (self.ViewLocation:GetColumn () - column) * self.Settings.CharacterWidth
	
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
	
	local renderInstructions = line:GetRenderInstructions (self.TabWidth) 
	local renderInstruction = nil
	for i = 1, #renderInstructions do
		renderInstruction = renderInstructions [i]
		if renderInstruction.StartColumn > viewLocationColumn + viewColumnCount then break end
		
		if renderInstruction.EndColumn > viewLocationColumn then
			surface_SetTextColor (renderInstruction.Color or defaultColor)
			surface_SetTextPos (lineNumberWidth + (renderInstruction.StartColumn - viewLocationColumn) * characterWidth, y)
			surface_DrawText (renderInstruction.String)
		end
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
	rightColumn = nextLine:GetWidth () + 1 - self.ViewLocation:GetColumn ()
	
	for i = math.max (selectionStart:GetLine (), self.ViewLocation:GetLine () - 2), selectionEnd:GetLine () - 1 do
		-- Don't bother drawing selection highlighting for lines out of view
		if i > self.ViewLocation:GetLine () + self.ViewLineCount + 2 then break end
	
		nextLine = self.Document:GetLine (i + 1)
	
		nextLeftColumn = -self.ViewLocation:GetColumn ()
		nextRightColumn = nextLine:GetWidth () + 1 - self.ViewLocation:GetColumn ()
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
	local insertionLocation = self.Document:ColumnToCharacter (self.CaretLocation)
	local insertionAction = GCompute.Editor.InsertionAction (self, insertionLocation, text)
	insertionAction:Redo ()
	self.UndoRedoStack:Push (insertionAction)
end

function PANEL:ReplaceSelectionText (text)
	local selectionStartLocation = self.Document:ColumnToCharacter (self.SelectionStartLocation)
	local selectionEndLocation   = self.Document:ColumnToCharacter (self.SelectionEndLocation)
	local originalText = self.Document:GetText (selectionStartLocation, selectionEndLocation)
	
	local replacementAction = GCompute.Editor.ReplacementAction (self, selectionStartLocation, selectionEndLocation, originalText, text)
	replacementAction:Redo ()
	self.UndoRedoStack:Push (replacementAction)
end

function PANEL:SetText (text)
	self.Document:SetText (text)
	self:UpdateScrollBar ()
end

-- Caret
function PANEL:FixupColumn (columnLocation)
	-- Round to nearest column
	local line = self.Document:GetLine (columnLocation:GetLine ())
	local column = columnLocation:GetColumn ()
	local offset, leftColumn = line:OffsetFromColumn (column, self.Settings.TabWidth)
	local rightColumn = leftColumn + line:GetCharacterWidth (GLib.UTF8.NextChar (line:GetText (), offset), self.Settings.TabWidth)
	
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
			self.Document:GetLine (self.CaretLocation:GetLine () - 1):GetWidth (self.Settings.TabWidth)
		))
	else
		local line = self.Document:GetLine (self.CaretLocation:GetLine ())
		local column = self.CaretLocation:GetColumn ()
		
		local characterStartOffset = GLib.UTF8.GetSequenceStart (line:GetText (), line:OffsetFromColumn (column - 1, self.Settings.TabWidth))
		column = column - line:GetCharacterWidth (GLib.UTF8.NextChar (line:GetText (), characterStartOffset), self.Settings.TabWidth)
		
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
	if self.CaretLocation:GetColumn () == self.Document:GetLine (self.CaretLocation:GetLine ()):GetWidth (self.Settings.TabWidth) then
		if self.CaretLocation:GetLine () + 1 == self.Document:GetLineCount () then return end
		
		self:SetRawCaretPos (GCompute.Editor.LineColumnLocation (
			self.CaretLocation:GetLine () + 1,
			0
		))
	else
		local line = self.Document:GetLine (self.CaretLocation:GetLine ())
		local column = self.CaretLocation:GetColumn ()
		
		column = column + line:GetCharacterWidth (GLib.UTF8.NextChar (line:GetText (), line:OffsetFromColumn (column, self.Settings.TabWidth)), self.Settings.TabWidth)
		
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
			self.Document:GetLine (self.CaretLocation:GetLine ()):GetWidth (self.Settings.TabWidth)
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
	
	local selectionStartLocation = self.Document:ColumnToCharacter (self.SelectionStartLocation)
	local selectionEndLocation   = self.Document:ColumnToCharacter (self.SelectionEndLocation)
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
		self.Document:CharacterToColumn (self.Document:GetStart ()),
		self.Document:CharacterToColumn (self.Document:GetEnd ())
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
function PANEL:PointToLocation (x, y, floorColumn)
	if floorColumn == nil then floorColumn = false end
	local line = self.ViewLocation:GetLine () + math.floor (y / self.Settings.LineHeight)
	local column = self.ViewLocation:GetColumn ()
	
	if floorColumn then
		-- floor column
		column = column + math.floor ((x - self.Settings.LineNumberWidth) / self.Settings.CharacterWidth)
	else
		-- round column
		column = column + math.floor ((x - self.Settings.LineNumberWidth) / self.Settings.CharacterWidth + 0.5)
	end
	
	-- Clamp line
	if line < 0 then line = 0 end
	if line >= self.Document:GetLineCount () then
		line = self.Document:GetLineCount () - 1
	end
	
	local lineWidth = self.Document:GetLine (line):GetWidth (self.Settings.TabWidth)
	if column > lineWidth then
		column = lineWidth
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

function PANEL:SetVerticalScrollPos (topLine)
	if topLine < 0 then topLine = 0 end
	self.VScroll:SetScroll (topLine)
end

function PANEL:UpdateScrollBar ()
	self.VScroll:SetUp (self.ViewLineCount, self.Document:GetLineCount ())
end

-- Clipboard
function PANEL:CopySelection ()
	if self.SelectionStartLocation:Equals (self.SelectionEndLocation) then return end
	
	local selectionStart = self.Document:ColumnToCharacter (self.SelectionStartLocation)
	local selectionEnd   = self.Document:ColumnToCharacter (self.SelectionEndLocation)
	
	Gooey.Clipboard:SetText (self.Document:GetText (selectionStart, selectionEnd))
end

function PANEL:CutSelection ()
	if self.SelectionStartLocation:Equals (self.SelectionEndLocation) then return end
	
	local selectionStart = self.Document:ColumnToCharacter (self.SelectionStartLocation)
	local selectionEnd   = self.Document:ColumnToCharacter (self.SelectionEndLocation)
	
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
			self:ApplyTokens (tokens.First, tokens.Last)
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
function PANEL:ApplyTokenization ()
	if not self.SourceFile then return end
	
	local tokens = self:GetCompilationUnit ():GetTokens ()
	if not tokens then return end
	
	local token = tokens.First
	local expectingStartOfLine = 0
	while token do
		while token.EndLine >= expectingStartOfLine and (token.EndLine ~= expectingStartOfLine or token.EndCharacter ~= 0) do
			self.Document:GetLine (expectingStartOfLine):SetStartToken (token)
			expectingStartOfLine = expectingStartOfLine + 1
		end
		token = token.Next
	end
end

function PANEL:ClearTokenization ()
	for line in self.Document:GetEnumerator () do
		line:SetStartToken (nil)
	end
end

function PANEL:HasTokenization ()
	return self.Document:GetLine (0):GetStartToken () and true or false
end

-- Internal, do not call
function PANEL:HookCompilationUnit (compilationUnit)
	if not compilationUnit then return end
	
	compilationUnit:AddEventListener ("TokenRangeAdded", tostring (self:GetTable ()),
		function (_, startToken, endToken)
			self:ApplyTokens (startToken, endToken)
		end
	)
end

function PANEL:UnhookCompilationUnit (compilationUnit)
	if not compilationUnit then return end
	
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
			self:SetCaretPos (self:PointToLocation (self:CursorPos ()))
			
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
				self:SetCaretPos (caretLocation)
				self:SetSelection (self.CaretLocation, self.CaretLocation)
			end
		end
	end
end

function PANEL:OnMouseMove (mouseCode, x, y)
	if self.Selecting then
		self:SetCaretPos (self:PointToLocation (x, y))
		
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
	self.VScroll:OnMouseWheeled (delta * 0.08)
end

function PANEL:OnVScroll (offset)
	if self.ViewLineCount < self.Document:GetLineCount () then
		self.ViewLocation:SetLine (math.floor (-offset))
	else
		self.ViewLocation:SetLine (0)
	end
end

function PANEL:Think ()
	if self.SourceFileOutdated then
		if SysTime () - self.LastSourceFileUpdateTime > 0.2 then
			if self:GetCompilationUnit ():IsTokenizing () then return end
			
			self.SourceFileOutdated = false
			self.LastSourceFileUpdateTime = SysTime ()
			
			self.SourceFile:SetCode (self:GetText ())
			self:GetCompilationUnit ()
				:Tokenize (
					function ()
						if not self or not self:IsValid () then return end
						self:ApplyTokenization ()
					end
				)
			if not self:HasTokenization () then
				self:ApplyTokenization ()
			end
		end
	end
end

vgui.Register ("GComputeCodeEditor", PANEL, "GPanel")