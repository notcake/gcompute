local PANEL = {}
surface.CreateFont ("Courier New", 16, 400, false, false, "GComputeMonospace")

--[[
	Events:
		CaretMoved (LineColumnLocation caretLocation)
			Fired when the caret has moved.
		FileChanged (oldFile, newFile)
			Fired when this document's file has changed.
		LanguageChanged (Language oldLanguage, Language newLanguage)
			Fired when this document's language has changed.
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
		local ctrl    = input.IsKeyDown (KEY_LCONTROL) or input.IsKeyDown (KEY_RCONTROL)
		local shift   = input.IsKeyDown (KEY_LSHIFT)   or input.IsKeyDown (KEY_RSHIFT)
		local alt     = input.IsKeyDown (KEY_LALT)     or input.IsKeyDown (KEY_RALT)
	
		local pasted = ctrl and input.IsKeyDown (KEY_V)
		
		local text = self.TextEntry:GetValue ()
		self.TextEntry:SetText ("")
		if text == "" then return end
		if not pasted then
			if text == "\r" or text == "\n" then return end
		end
		
		if not self:IsReadOnly () then
			self:ReplaceSelectionText (text)
			self:ScrollToCaret ()
		end
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
	
	self.ReadOnly = false
	self.Document = GCompute.Editor.Document ()
	self.Document:AddEventListener ("TextCleared",
		function (_)
			self:SetMaximumColumnCount (1)
			
			self.DocumentChangeUnhandled = true
			self.DocumentLinesUnchecked = {}
			self:UpdateVerticalScrollBar ()
		end
	)
	self.Document:AddEventListener ("TextDeleted",
		function (_, startLocation, endLocation)
			self.DocumentChangeUnhandled = true
			
			local deletionStartLine = startLocation:GetLine ()
			local deletionEndLine = endLocation:GetLine ()
			if deletionStartLine ~= deletionEndLine then
				local maximumColumnCount = 0
				while next (self.DocumentLinesUnchecked) do
					local line = next (self.DocumentLinesUnchecked)
					self.DocumentLinesUnchecked [line] = nil
					
					if line < deletionStartLine or line > deletionEndLine then
						if line > deletionEndLine then line = line - deletionEndLine + deletionStartLine end
						
						if self.Document:GetLine (line) then
							maximumColumnCount = math.max (maximumColumnCount, self.Document:GetLine (line):GetColumnCount (self.TextRenderer) + 1)
						end
					end
				end
				self:UpdateMaximumColumnCount (maximumColumnCount)
			end
			
			self.DocumentLinesUnchecked [startLocation:GetLine ()] = true
			self:UpdateMaximumColumnCount (self.Document:GetLine (startLocation:GetLine ()):GetColumnCount (self.TextRenderer) + 1)
			self:UpdateVerticalScrollBar ()
		end
	)
	self.Document:AddEventListener ("TextInserted",
		function (_, location, text, newLocation)
			self.DocumentChangeUnhandled = true
			
			local startTime = SysTime ()
			for i = location:GetLine (), newLocation:GetLine () do
				self.DocumentLinesUnchecked [i] = true
			end
			if SysTime () - startTime > 0 then
				ErrorNoHalt (string.format ("CodeEditor:UpdateMaximumColumnCount took %.5f ms.\n", (SysTime () - startTime) * 1000))
			end
			self:UpdateVerticalScrollBar ()
		end
	)
	
	self.DocumentChangeUnhandled = false
	self.DocumentLinesUnchecked = {}
	
	-- Caret
	self.CaretLocation = GCompute.Editor.LineColumnLocation ()
	self.PreferredCaretLocation = GCompute.Editor.LineColumnLocation ()
	self.CaretBlinkTime = SysTime ()
	
	-- Selection
	self.Selecting = false
	self.SelectionMode = GCompute.Editor.SelectionMode.Regular
	self.SelectionStartLocation = GCompute.Editor.LineColumnLocation ()
	self.SelectionEndLocation   = GCompute.Editor.LineColumnLocation ()
	
	-- Settings
	self.TextRenderer = GCompute.Editor.TextRenderer ()
	
	self.Settings = {}
	
	surface.SetFont ("GComputeMonospace")
	self.Settings.CharacterWidth, self.Settings.FontHeight = surface.GetTextSize ("W")
	self.Settings.LineHeight = self.Settings.FontHeight + 2
	self:UpdateLineNumberWidth ()
	
	-- View
	self.ViewLineCount = 0
	self.ViewColumnCount = 0
	self.MaximumColumnCount = 1
	self.ViewLocation = GCompute.Editor.LineColumnLocation ()
	
	self.LineNumbersVisible = true
	
	-- Editing
	self.UndoRedoStack = GCompute.UndoRedoStack ()
	
	-- Compiler
	self.CompilationEnabled = true
	
	self.SourceFile = nil
	self.CompilationUnit = nil
	self.Language = nil
	self.EditorHelper = GCompute.IEditorHelper ()
	self.LastSourceFileUpdateTime = 0
	self.SourceFileOutdated = true
	
	-- Autocomplete
	self.HoveredToken = nil
	self.HoverStartTime = 0
	self.HoverActionPerformed = false
	
	self.TokenApplicationQueue = GCompute.Containers.Queue ()
	
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
		if self:AreLineNumbersVisible () then w = w - self.Settings.LineNumberWidth end
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
	
	if self:GetSelectionMode () == GCompute.Editor.SelectionMode.Regular then
		self:DrawCaretRegular ()
	elseif self:GetSelectionMode () == GCompute.Editor.SelectionMode.Block then
		self:DrawCaretBlock ()
	end
end

function PANEL:DrawCaretRegular ()
	if (SysTime () - self.CaretBlinkTime) % 1 >= 0.5 then return end
	
	local caretX = (self.CaretLocation:GetColumn () - self.ViewLocation:GetColumn ()) * self.Settings.CharacterWidth
	if self:AreLineNumbersVisible () then caretX = caretX + self.Settings.LineNumberWidth end
	local caretY = (self.CaretLocation:GetLine () - self.ViewLocation:GetLine ()) * self.Settings.LineHeight
	
	surface.SetDrawColor (GLib.Colors.Gray)
	surface.DrawLine (caretX, caretY, caretX, caretY + self.Settings.LineHeight)
end

function PANEL:DrawCaretBlock ()
	if (SysTime () - self.CaretBlinkTime) % 1 >= 0.5 then return end
	
	local selectionStart = self.SelectionStartLocation
	local selectionEnd = self.SelectionEndLocation
	
	if selectionStart:IsAfter (selectionEnd) then
		selectionStart = self.SelectionEndLocation
		selectionEnd = self.SelectionStartLocation
	end
	
	local startLine = math.max (selectionStart:GetLine (), self.ViewLocation:GetLine ())
	local endLine   = math.min (selectionEnd:GetLine (), self.ViewLocation:GetLine () + self.ViewLineCount + 1)
	
	surface.SetDrawColor (GLib.Colors.Gray)
	
	local caretX
	local caretY
	for i = startLine, endLine do
		caretX = (self:GetCaretColumn (i) - self.ViewLocation:GetColumn ()) * self.Settings.CharacterWidth
		if self:AreLineNumbersVisible () then caretX = caretX + self.Settings.LineNumberWidth end
		caretY = (i - self.ViewLocation:GetLine ()) * self.Settings.LineHeight
		surface.DrawLine (caretX, caretY, caretX, caretY + self.Settings.LineHeight)
	end
end

local caretLineHighlightColor = Color (32, 32, 64, 255)
function PANEL:DrawCaretLineHightlighting ()
	local caretY = (self.CaretLocation:GetLine () - self.ViewLocation:GetLine ()) * self.Settings.LineHeight
	surface.SetDrawColor (caretLineHighlightColor)
	if self:AreLineNumbersVisible () then
		surface.DrawRect (self.Settings.LineNumberWidth, caretY, self:GetWide () - self.Settings.LineNumberWidth, self.Settings.LineHeight)
	else
		surface.DrawRect (0, caretY, self:GetWide (), self.Settings.LineHeight)
	end
end

function PANEL:DrawLine (lineOffset)
	local lineNumber = self.ViewLocation:GetLine () + lineOffset
	local line = self.Document:GetLine (lineNumber)
	if not line then return end
	
	local y = lineOffset * self.Settings.LineHeight + 0.5 * (self.Settings.LineHeight - self.Settings.FontHeight)
	local x = self:AreLineNumbersVisible () and self.Settings.LineNumberWidth or 0
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
	
	local index, currentColumn = line:GetTextStorage ():SegmentIndexFromColumn (viewLocationColumn, self.TextRenderer)
	local columnCount
	x = x - currentColumn * characterWidth
	currentColumn = viewLocationColumn - currentColumn
	local segment = line.TextStorage:GetSegment (index)
	while segment and x <= w do
		surface_SetTextColor (segment.Color)
		surface_SetTextPos (x, y)
		surface_DrawText (segment.Text)
		
		columnCount = line.TextStorage:GetSegmentColumnCount (segment, self.TextRenderer)
		currentColumn = currentColumn + columnCount
		x = x + columnCount * characterWidth
		
		index = index + 1
		segment = line.TextStorage:GetSegment (index)
	end
end

function PANEL:DrawSelection ()
	if self:IsSelectionEmpty () then return end
	
	if self:GetSelectionMode () == GCompute.Editor.SelectionMode.Regular then
		self:DrawSelectionRegular ()
	elseif self:GetSelectionMode () == GCompute.Editor.SelectionMode.Block then
		self:DrawSelectionBlock ()
	end
end

function PANEL:DrawSelectionRegular ()
	local lineNumberWidth = self:AreLineNumbersVisible () and self.Settings.LineNumberWidth or 0
	
	local selectionStart = self.SelectionStartLocation
	local selectionEnd = self.SelectionEndLocation
	
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
	
	-- Don't bother drawing selection highlighting for lines out of view
	local startLine = math.max (selectionStart:GetLine (), self.ViewLocation:GetLine () - 2)
	local endLine   = math.min (selectionEnd:GetLine () - 1, self.ViewLocation:GetLine () + self.ViewLineCount + 2)
	local nextLine  = self.Document:GetLine (startLine)
	
	leftColumn  = selectionStart:GetColumn () - self.ViewLocation:GetColumn ()
	rightColumn = nextLine:GetColumnCount (self.TextRenderer) + 1 - self.ViewLocation:GetColumn ()
	
	for i = startLine, endLine do
		nextLine = self.Document:GetLine (i + 1)
	
		nextLeftColumn  = -self.ViewLocation:GetColumn ()
		nextRightColumn = nextLine:GetColumnCount (self.TextRenderer) + 1 - self.ViewLocation:GetColumn ()
		if i == selectionEnd:GetLine () - 1 then
			nextRightColumn = selectionEnd:GetColumn () - self.ViewLocation:GetColumn ()
		end
		
		if leftColumn ~= rightColumn then
			draw.RoundedBoxEx (
				4,
				lineNumberWidth + leftColumn * self.Settings.CharacterWidth,
				(i - self.ViewLocation:GetLine ()) * self.Settings.LineHeight,
				(rightColumn - leftColumn) * self.Settings.CharacterWidth,
				self.Settings.LineHeight,
				GLib.Colors.SteelBlue,
				roundTopLeft, roundTopRight,
				nextLeftColumn > leftColumn or nextRightColumn <= leftColumn, nextRightColumn < rightColumn or nextLeftColumn >= rightColumn
			)
		end
		
		roundTopLeft = nextLeftColumn < leftColumn or nextLeftColumn >= rightColumn
		roundTopRight = nextRightColumn > rightColumn or nextRightColumn <= leftColumn
		
		leftColumn  = nextLeftColumn
		rightColumn = nextRightColumn
	end
	
	nextRightColumn = selectionEnd:GetColumn () - self.ViewLocation:GetColumn ()
	rightColumn = nextRightColumn
	
	if leftColumn ~= rightColumn then
		draw.RoundedBoxEx (
			4,
			lineNumberWidth + leftColumn * self.Settings.CharacterWidth,
			(selectionEnd:GetLine () - self.ViewLocation:GetLine ()) * self.Settings.LineHeight,
			(rightColumn - leftColumn) * self.Settings.CharacterWidth,
			self.Settings.LineHeight,
			GLib.Colors.SteelBlue,
			roundTopLeft, roundTopRight,
			true, true
		)
	end
end

function PANEL:DrawSelectionBlock ()
	local lineNumberWidth = self:AreLineNumbersVisible () and self.Settings.LineNumberWidth or 0
	
	local selectionStart = self.SelectionStartLocation
	local selectionEnd = self.SelectionEndLocation
	
	if selectionStart:IsAfter (selectionEnd) then
		selectionStart = self.SelectionEndLocation
		selectionEnd = self.SelectionStartLocation
	end
	
	if selectionStart:GetColumn () == selectionEnd:GetColumn () then return end
	
	local startColumn = math.min (selectionStart:GetColumn (), selectionEnd:GetColumn ())
	local endColumn   = math.max (selectionStart:GetColumn (), selectionEnd:GetColumn ())
	
	local roundTopLeft = true
	local roundTopRight = true
	local leftColumn = 0
	local rightColumn = 0
	local nextLeftColumn = 0
	local nextRightColumn = 0
	
	-- Don't bother drawing selection highlighting for lines out of view
	local startLine = math.max (selectionStart:GetLine (), self.ViewLocation:GetLine () - 2)
	local endLine   = math.min (selectionEnd:GetLine () - 1, self.ViewLocation:GetLine () + self.ViewLineCount + 2)
	local nextLine  = self.Document:GetLine (startLine)
	
	leftColumn  = startColumn < nextLine:GetColumnCount (self.TextRenderer) and self:FixupColumn (startLine, startColumn) or startColumn
	rightColumn = endColumn   < nextLine:GetColumnCount (self.TextRenderer) and self:FixupColumn (startLine, endColumn)   or endColumn
	leftColumn  = leftColumn  - self.ViewLocation:GetColumn ()
	rightColumn = rightColumn - self.ViewLocation:GetColumn ()
	
	for i = startLine, endLine do
		nextLine = self.Document:GetLine (i + 1)
	
		nextLeftColumn  = startColumn < nextLine:GetColumnCount (self.TextRenderer) and self:FixupColumn (i + 1, startColumn) or startColumn
		nextRightColumn = endColumn   < nextLine:GetColumnCount (self.TextRenderer) and self:FixupColumn (i + 1, endColumn)   or endColumn
		nextLeftColumn  = nextLeftColumn  - self.ViewLocation:GetColumn ()
		nextRightColumn = nextRightColumn - self.ViewLocation:GetColumn ()
		
		if leftColumn ~= rightColumn then
			draw.RoundedBoxEx (
				4,
				lineNumberWidth + leftColumn * self.Settings.CharacterWidth,
				(i - self.ViewLocation:GetLine ()) * self.Settings.LineHeight,
				(rightColumn - leftColumn) * self.Settings.CharacterWidth,
				self.Settings.LineHeight,
				GLib.Colors.SteelBlue,
				roundTopLeft, roundTopRight,
				nextLeftColumn > leftColumn or nextRightColumn <= leftColumn, nextRightColumn < rightColumn or nextLeftColumn >= rightColumn
			)
		end
		
		roundTopLeft = nextLeftColumn < leftColumn or nextLeftColumn >= rightColumn
		roundTopRight = nextRightColumn > rightColumn or nextRightColumn <= leftColumn
		
		leftColumn  = nextLeftColumn
		rightColumn = nextRightColumn
	end
	
	if leftColumn ~= rightColumn then
		draw.RoundedBoxEx (
			4,
			lineNumberWidth + leftColumn * self.Settings.CharacterWidth,
			(selectionEnd:GetLine () - self.ViewLocation:GetLine ()) * self.Settings.LineHeight,
			(rightColumn - leftColumn) * self.Settings.CharacterWidth,
			self.Settings.LineHeight,
			GLib.Colors.SteelBlue,
			roundTopLeft, roundTopRight,
			true, true
		)
	end
end

function PANEL:GetTextRenderer ()
	return self.TextRenderer
end

function PANEL:Paint ()
	local lineNumberWidth = self:AreLineNumbersVisible () and self.Settings.LineNumberWidth or 0
	
	-- Draw background
	surface.SetDrawColor (32, 32, 32, 255)
	surface.DrawRect (lineNumberWidth, 0, self:GetWide () - lineNumberWidth, self:GetTall ())
	
	self:DrawCaretLineHightlighting ()
	self:DrawSelection ()
	self:DrawCaret ()
	
	-- Draw ViewLineCount lines and then the one that's partially out of view.
	for i = 0, self.ViewLineCount do
		self:DrawLine (i)
	end
	
	-- Draw line numbers
	if self:AreLineNumbersVisible () then
		surface.SetDrawColor (GLib.Colors.Gray)
		surface.DrawRect (0, 0, self.Settings.LineNumberWidth, self:GetTall ())
		for i = 0, math.min (self.ViewLineCount, self.Document:GetLineCount () - self.ViewLocation:GetLine () - 1) do
			draw.SimpleText (tostring (self.ViewLocation:GetLine () + i + 1), "GComputeMonospace", self.Settings.LineNumberWidth - 16, i * self.Settings.LineHeight + 0.5 * (self.Settings.LineHeight - self.Settings.FontHeight), GLib.Colors.White, TEXT_ALIGN_RIGHT)
		end
	end
end

-- Data
function PANEL:Append (text)
	local autoscroll = self:IsLineVisible (self:GetDocument ():GetLineCount () - 1)
	
	self:GetDocument ():Insert (self:GetDocument ():GetEnd (), text)
	
	if autoscroll then
		self:SetVerticalScrollPos (self:GetDocument ():GetLineCount () - self.ViewLineCount)
	end
end

function PANEL:Clear ()
	self.Document:Clear ()
	self:SetCaretPos (GCompute.Editor.LineColumnLocation (0, 0))
	self:SetSelection (GCompute.Editor.LineColumnLocation (0, 0), GCompute.Editor.LineColumnLocation (0, 0))
end

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

function PANEL:IsReadOnly ()
	return self.ReadOnly
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

function PANEL:SetReadOnly (readOnly)
	self.ReadOnly = readOnly
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
function PANEL:DeleteSelection ()
	if self.SelectionStartLocation:Equals (self.SelectionEndLocation) then return end
	
	local selectionStartLocation = self.Document:ColumnToCharacter (self.SelectionStartLocation, self.TextRenderer)
	local selectionEndLocation   = self.Document:ColumnToCharacter (self.SelectionEndLocation, self.TextRenderer)
	local text = self.Document:GetText (selectionStartLocation, selectionEndLocation)
	
	local deletionAction = GCompute.Editor.DeletionAction (self, selectionStartLocation, selectionEndLocation, selectionStartLocation, selectionEndLocation, text)
	deletionAction:Redo ()
	self.UndoRedoStack:Push (deletionAction)
end

function PANEL:GetText ()
	return self.Document:GetText ()
end

function PANEL:IndentSelection ()
	local indentationAction = GCompute.Editor.IndentationAction (self, self:CreateSelectionSnapshot ())
	indentationAction:Redo ()
	self.UndoRedoStack:Push (indentationAction)
end

function PANEL:OutdentSelection ()
	local outdentationAction = GCompute.Editor.OutdentationAction (self, self:CreateSelectionSnapshot ())
	outdentationAction:Redo ()
	self.UndoRedoStack:Push (outdentationAction)
end

function PANEL:ReplaceSelectionText (text)
	if self:IsSelectionEmpty () then
		local insertionLocation = self.Document:ColumnToCharacter (self.CaretLocation, self.TextRenderer)
		local insertionAction = GCompute.Editor.InsertionAction (self, insertionLocation, text)
		insertionAction:Redo ()
		self.UndoRedoStack:Push (insertionAction)
	else
		local selectionStartLocation = self.Document:ColumnToCharacter (self.SelectionStartLocation, self.TextRenderer)
		local selectionEndLocation   = self.Document:ColumnToCharacter (self.SelectionEndLocation, self.TextRenderer)
		local originalText = self.Document:GetText (selectionStartLocation, selectionEndLocation)
		
		local replacementAction = GCompute.Editor.ReplacementAction (self, selectionStartLocation, selectionEndLocation, originalText, text)
		replacementAction:Redo ()
		self.UndoRedoStack:Push (replacementAction)
	end
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
function PANEL:FixupColumn (line, column)
	-- Round to nearest column
	local line = self.Document:GetLine (line)
	local character, leftColumn = line:CharacterFromColumn (column, self.TextRenderer)
	local rightColumn = leftColumn + self.TextRenderer:GetCharacterColumnCount (line:GetCharacter (character))
	
	if column - leftColumn < rightColumn - column then
		column = leftColumn
	else
		column = rightColumn
	end
	
	return column
end

function PANEL:GetCaretColumn (line)
	local caretColumn = self.CaretLocation:GetColumn ()
	local pastEndOfLine = caretColumn > self.Document:GetLine (line):GetColumnCount (self.TextRenderer)
	local column = pastEndOfLine and caretColumn or self:FixupColumn (line, caretColumn)
	return column, pastEndOfLine
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
	caretLocation = GCompute.Editor.LineColumnLocation (caretLocation:GetLine (), self:FixupColumn (caretLocation:GetLine (), caretLocation:GetColumn ()))
	self:SetRawCaretPos (caretLocation, scrollToCaret)
end

--- Sets the preferred caret location. The actual caret location is adjusted to the nearest available column.
-- @param preferredCaretLocation The new preferred caret location
-- @param scrollToCaret Whether the view should be scrolled to make the caret visible
function PANEL:SetPreferredCaretPos (preferredCaretLocation, scrollToCaret)
	if scrollToCaret == nil then scrollToCaret = true end
	if self.PreferredCaretLocation:Equals (preferredCaretLocation) then return end
	
	self.PreferredCaretLocation:CopyFrom (preferredCaretLocation)
	preferredCaretLocation = GCompute.Editor.LineColumnLocation (preferredCaretLocation:GetLine (), self:FixupColumn (preferredCaretLocation:GetLine (), preferredCaretLocation:GetColumn ()))
	self.CaretLocation:CopyFrom (preferredCaretLocation)
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
function PANEL:CreateSelectionSnapshot ()
	local selectionSnapshot = GCompute.Editor.SelectionSnapshot ()
	selectionSnapshot:SetSelectionMode (self.SelectionMode)
	selectionSnapshot:SetSelectionStart (self.SelectionStartLocation)
	selectionSnapshot:SetSelectionEnd (self.SelectionEndLocation)
	selectionSnapshot:SetCaretPosition (self.CaretLocation)
	selectionSnapshot:SetPreferredCaretPosition (self.PreferredCaretLocation)
	return selectionSnapshot
end

function PANEL:GetSelectionEnd ()
	return self.SelectionEndLocation
end

function PANEL:GetSelectionMode ()
	return self.SelectionMode
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

function PANEL:IsSelectionMultiline ()
	return self.SelectionStartLocation:GetLine () ~= self.SelectionEndLocation:GetLine ()
end

function PANEL:RestoreSelectionSnapshot (selectionSnapshot)
	self.SelectionMode = selectionSnapshot:GetSelectionMode ()
	self.SelectionStartLocation:CopyFrom (selectionSnapshot:GetSelectionStart ())
	self.SelectionEndLocation:CopyFrom (selectionSnapshot:GetSelectionEnd ())
	self.CaretLocation:CopyFrom (selectionSnapshot:GetCaretPosition ())
	self.PreferredCaretLocation:CopyFrom (selectionSnapshot:GetPreferredCaretPosition ())
end

function PANEL:SelectAll ()
	self:SetSelectionMode (GCompute.Editor.SelectionMode.Regular)
	self:SetSelection (
		self.Document:CharacterToColumn (self.Document:GetStart (), self.TextRenderer),
		self.Document:CharacterToColumn (self.Document:GetEnd (), self.TextRenderer)
	)
end

function PANEL:SetSelection (selectionStart, selectionEnd)
	selectionEnd = selectionEnd or selectionStart
	
	self.SelectionStartLocation:CopyFrom (selectionStart)
	self.SelectionEndLocation:CopyFrom (selectionEnd)
	
	self:DispatchEvent ("SelectionChanged", self.SelectionStartLocation, self.SelectionEndLocation)
end

function PANEL:SetSelectionEnd (selectionEnd)
	self.SelectionEndLocation:CopyFrom (selectionEnd)
	
	self:DispatchEvent ("SelectionChanged", self.SelectionStartLocation, self.SelectionEndLocation)
end

function PANEL:SetSelectionMode (selectionMode)
	if self.SelectionMode == selectionMode then return end
	
	self.SelectionMode = selectionMode
	self:DispatchEvent ("SelectionChanged", self.SelectionStartLocation, self.SelectionEndLocation)
end

function PANEL:SetSelectionStart (selectionStart)
	self.SelectionStartLocation:CopyFrom (selectionStart)
	
	self:DispatchEvent ("SelectionChanged", self.SelectionStartLocation, self.SelectionEndLocation)
end

-- View
function PANEL:AreLineNumbersVisible ()
	return self.LineNumbersVisible
end

function PANEL:IsLineFullyVisible (line)
	return line >= self.ViewLocation:GetLine () and line <= self.ViewLocation:GetLine () + self.ViewLineCount + 1
end

function PANEL:IsLineVisible (line)
	return line >= self.ViewLocation:GetLine () and line <= self.ViewLocation:GetLine () + self.ViewLineCount
end

--- Converts a position in the editor control to a line-column location.
-- If a block selection is in progress, the returned location is not clamped to the end of its line.
-- @param x The x coordinate of the position in the editor control
-- @param y The y coordinate of the position in the editor control
-- @return The line, column location corresponding to the given coordinates
function PANEL:PointToLocation (x, y)
	local line = self.ViewLocation:GetLine () + math.floor (y / self.Settings.LineHeight)
	local column = self.ViewLocation:GetColumn ()
	
	if self:AreLineNumbersVisible () then x = x - self.Settings.LineNumberWidth end
	column = column + x / self.Settings.CharacterWidth
	
	-- Clamp line
	if line < 0 then line = 0 end
	if line >= self.Document:GetLineCount () then
		line = self.Document:GetLineCount () - 1
	end
	
	local lineWidth = self.Document:GetLine (line):GetColumnCount (self.TextRenderer)
	if column < 0 then
		column = 0
	elseif column > lineWidth then
		if self:GetSelectionMode () == GCompute.Editor.SelectionMode.Block then
			column = math.floor (column + 0.5)
		else
			column = lineWidth
		end
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

function PANEL:PointToRawLocation (x, y)
	local line = self.ViewLocation:GetLine () + math.floor (y / self.Settings.LineHeight)
	local column = self.ViewLocation:GetColumn ()
	
	if self:AreLineNumbersVisible () then x = x - self.Settings.LineNumberWidth end
	column = column + x / self.Settings.CharacterWidth
	
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

function PANEL:SetLineNumbersVisible (lineNumbersVisible)
	if self.LineNumbersVisible == lineNumbersVisible then return end
	
	self.LineNumbersVisible = lineNumbersVisible
	self:InvalidateLayout ()
end

function PANEL:SetVerticalScrollPos (topLine)
	if topLine < 0 then topLine = 0 end
	self.VScroll:SetViewOffset (topLine)
end

function PANEL:UpdateLineNumberWidth ()
	local maxDisplayedLineNumber = tostring (self.Document:GetLineCount ())
	local lineNumberWidth = self.Settings.CharacterWidth * (string.len (maxDisplayedLineNumber) + 1) + 16
	if self.Settings.LineNumberWidth == lineNumberWidth then return end
	
	self.Settings.LineNumberWidth = lineNumberWidth
	self:InvalidateLayout ()
end

function PANEL:UpdateScrollBars ()
	self:UpdateVerticalScrollBar ()
	self.HScroll:SetViewSize (self.ViewColumnCount)
	self.HScroll:SetContentSize (self.MaximumColumnCount)
end

function PANEL:UpdateVerticalScrollBar ()
	self.VScroll:SetViewSize (self.ViewLineCount)
	self.VScroll:SetContentSize (self.Document:GetLineCount ())
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

function PANEL:GetEditorHelper ()
	return self.EditorHelper
end

function PANEL:GetSourceFile ()
	return self.SourceFile
end

function PANEL:InvalidateSourceFile ()
	self.SourceFileOutdated = true
end

function PANEL:IsCompilationEnabled ()
	return self.CompilationEnabled
end

function PANEL:IsSourceFileOutdated ()
	return self.SourceFileOutdated
end

function PANEL:SetCompilationEnabled (compilationEnabled)
	self.CompilationEnabled = compilationEnabled
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
		self:SetLanguage (self.CompilationUnit:GetLanguage ())
	else
		self:ClearTokenization ()
		self:SetLanguage (nil)
	end
end

-- Internal function, do not call
function PANEL:SetLanguage (language)
	if self.Language == language then return end
	
	local oldLanguage = self.Language
	self.Language = language
	
	if self.Language then
		self.EditorHelper = self.Language:GetEditorHelper ()
	else
		self.EditorHelper = GCompute.IEditorHelper ()
	end
	
	self:DispatchEvent ("LanguageChanged", oldLanguage, self.Language)
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

-- Syntax highlighting
-- Internal, do not call
function PANEL:ApplyToken (token)
	if not token then return end
	local tokenStartLine = token.Line
	local tokenEndLine = token.EndLine
	
	local color = self:GetTokenColor (token)
	local startLine = self.Document:GetLine (tokenStartLine)
	if not startLine then return end
	
	if tokenStartLine == tokenEndLine then
		startLine:SetObject (token, token.Character, token.EndCharacter)
		startLine:SetColor (color, token.Character, token.EndCharacter)
	else
		startLine:SetObject (token, token.Character, nil)
		startLine:SetColor (color, token.Character, nil)
		if self.Document:GetLine (tokenEndLine) then
			self.Document:GetLine (tokenEndLine):SetObject (token, 0, token.EndCharacter)
			self.Document:GetLine (tokenEndLine):SetColor (color, 0, token.EndCharacter)
		end
		
		for i = tokenStartLine + 1, tokenEndLine - 1 do
			if not self.Document:GetLine (i) then break end
			self.Document:GetLine (i):SetObject (token)
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

function PANEL:TokenFromLocation (lineColumnLocation)
	local lineCharacterLocation = self.Document:ColumnToCharacter (lineColumnLocation, self.TextRenderer)
	local line = self.Document:GetLine (lineCharacterLocation:GetLine ())
	if not line then return nil end
	
	return line:GetCharacterObject (lineCharacterLocation:GetCharacter ())
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

-- Autocomplete
function PANEL:GetHoveredToken ()
	return self.HoveredToken
end

function PANEL:SetHoveredToken (token)
	if self.HoveredToken == token then return end
	
	self.HoveredToken = token
	self.HoverStartTime = SysTime ()
	self.HoverActionPerformed = false
end

-- Internal, do not call
function PANEL:HookCompilationUnit (compilationUnit)
	if not compilationUnit then return end
	
	compilationUnit:AddEventListener ("LanguageChanged", tostring (self:GetTable ()),
		function (_, language)
			self:SetLanguage (language)
		end
	)
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
	
	compilationUnit:RemoveEventListener ("LanguageChanged",   tostring (self:GetTable ()))
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
		if not self:IsReadOnly () then
			if shift then
				self:OutdentSelection ()
			else
				if self:IsSelectionMultiline () then
					self:IndentSelection ()
				else
					self:ReplaceSelectionText ("\t")
				end
			end
		end
	elseif keyCode == KEY_ENTER then
		if not self:IsReadOnly () then
			local location = self.SelectionStartLocation
			if self.SelectionEndLocation:IsBefore (location) then
				location = self.SelectionEndLocation
			end
			location = self.Document:ColumnToCharacter (location, self.TextRenderer)
			self:ReplaceSelectionText ("\n" .. self.EditorHelper:GetNewLineIndentation (self, location))
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
		if self:AreLineNumbersVisible () and x <= self.Settings.LineNumberWidth then
		else
			self.Selecting = true
			self:SetSelectionMode (alt and GCompute.Editor.SelectionMode.Block or GCompute.Editor.SelectionMode.Regular)
			self:SetRawCaretPos (self:PointToLocation (self:CursorPos ()))
			if shift then
				self:SetSelectionEnd (self.CaretLocation)
			else
				self:SetSelection (self.CaretLocation, self.CaretLocation)
			end
			
			self:MouseCapture (true)
		end
	elseif mouseCode == MOUSE_RIGHT then
		if self:AreLineNumbersVisible () and x <= self.Settings.LineNumberWidth then
		else
			local caretLocation = self:PointToLocation (self:CursorPos ())
			if not self:IsInSelection (caretLocation) then
				self:SetRawCaretPos (caretLocation)
				self:SetSelection (self.CaretLocation, self.CaretLocation)
			end
		end
	end
end

function PANEL:OnMouseLeave ()
	self:SetHoveredToken (nil)
end

function PANEL:OnMouseMove (mouseCode, x, y)
	if self.Selecting then
		self:SetRawCaretPos (self:PointToLocation (x, y))
		
		self:SetSelectionEnd (self.CaretLocation)
	else
		if self:AreLineNumbersVisible () and x <= self.Settings.LineNumberWidth then
			self:SetCursor ("arrow")
		else
			self:SetCursor ("beam")
		end
	end
	
	self:SetHoveredToken (self:TokenFromLocation (self:PointToRawLocation (x, y)))
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
	if self:IsCompilationEnabled () and self.SourceFileOutdated then
		if not self:GetSourceFile () then
			self:SetSourceFile (GCompute.SourceFileCache:CreateAnonymousSourceFile ())
			self:SetCompilationUnit (self:GetSourceFile ():GetCompilationUnit ())
		end
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
	
	self:DocumentUpdateThink ()
	self:HoverThink ()
	self:TokenApplicationThink ()
end

function PANEL:DocumentUpdateThink ()
	if self.DocumentChangeUnhandled then
		self:InvalidateSourceFile ()
		self:UpdateLineNumberWidth ()
		self:ResetCaretBlinkTime ()
		self:UpdateScrollBars ()
		
		self.DocumentChangeUnhandled = false
	end
	
	if next (self.DocumentLinesUnchecked) then
		local startTime = SysTime ()
		local maximumColumnCount = 0
		while SysTime () - startTime < 0.010 do
			local line = next (self.DocumentLinesUnchecked)
			if not line then break end
			
			self.DocumentLinesUnchecked [line] = nil
			maximumColumnCount = math.max (maximumColumnCount, self.Document:GetLine (line):GetColumnCount (self.TextRenderer) + 1)
		end
		self:UpdateMaximumColumnCount (maximumColumnCount)
	end
end

function PANEL:HoverThink ()
	if not self.HoveredToken then return end
	if self.HoverActionPerformed then return end
	
	if SysTime () - self.HoverStartTime > 0.5 then
		self.HoverActionPerformed = true
		ErrorNoHalt (self.HoveredToken:ToString () .. "\n")
	end
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