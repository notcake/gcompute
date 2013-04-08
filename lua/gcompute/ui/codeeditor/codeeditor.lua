local PANEL = {}
surface.CreateFont (
	"GComputeMonospace",
	{
		font   = "Courier New",
		size   = 16,
		weight = 400
	}
)
surface.CreateFont (
	"GComputeMonospaceBold",
	{
		font   = "Courier New",
		size   = 16,
		weight = 1000
	}
)

--[[
	Events:
		CaretMoved (LineColumnLocation caretLocation)
			Fired when the caret has moved.
		DocumentChanged (Document oldDocument, Document newDocument)
			Fired when this editor's document has changed.
		IdentifierHighlighterChanged (IdentifierHighlighter oldIdentifierHighlighter, IdentifierHighlighter identifierHighlighter)
			Fired when the identifier highlighter has changed.
		ItemRedone (UndoRedoItem undoRedoItem)
			Fired when an UndoRedoItem has been redone.
		ItemUndone (UndoRedoItem undoRedoItem)
			Fired when an UndoRedoItem has been undone.
		LanguageChanged (Language oldLanguage, Language language)
			Fired when the document's language has changed.
		SelectionChanged (LineColumnLocation selectionStart, LineColumnLocation selectionEnd)
			Fired when the selection has changed.
		SyntaxHighlighterChanged (SyntaxHighlighter oldSyntaxHighlighter, SyntaxHighlighter syntaxHighlighter)
			Fired when the syntax highlighter has changed.
		TextChanged ()
			Fired when this document's text has changed.
		ViewLocationChanged (LineColumnLocation viewLocation)
			Fired when the editor's view location has changed.
]]

function PANEL:Init ()
	self:SetActionMap (GCompute.CodeEditor.ActionMap)
	
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
			if ctrl and text == " " then return end
			if text == "\r" or text == "\n" then return end
		end
		
		if not self:IsReadOnly () then
			-- Autocompletion
			local suppressText = self.CodeCompletionProvider:HandleText (text, pasted)
			
			if not suppressText then
				self:ReplaceSelectionText (text, pasted)
			end
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
	self.Multiline = true
	self.ReadOnly = false
	self.Document = nil
	self.DocumentChangeUnhandled = false
	self.DocumentLinesUnchecked = {}
	
	-- Caret
	self.CaretLocation = GCompute.CodeEditor.LineColumnLocation ()
	self.PreferredCaretLocation = GCompute.CodeEditor.LineColumnLocation ()
	self.CaretBlinkTime = SysTime ()
	
	-- Selection
	self.Selecting = false
	self.Selection = GCompute.CodeEditor.TextSelection (self)
	self.SelectionController = GCompute.CodeEditor.TextSelectionController (self, self.Selection)
	self.Selection:AddEventListener ("SelectionChanged",
		function (_, selectionStart, selectionEnd)
			self:DispatchEvent ("SelectionChanged", selectionStart, selectionEnd)
		end
	)
	
	-- Bracket Highlighting
	self.BracketHighlighter = GCompute.CodeEditor.BracketHighlighter (self)
	
	-- Settings
	self.TextRenderer = GCompute.CodeEditor.TextRenderer ()
	
	self.Settings = {}
	
	surface.SetFont ("GComputeMonospace")
	self.Settings.Font = "GComputeMonospace"
	self.Settings.CharacterWidth, self.Settings.FontHeight = surface.GetTextSize ("W")
	self.Settings.LineHeight = self.Settings.FontHeight + 2
	
	-- View
	self.ViewLineCount = 0
	self.ViewColumnCount = 0
	self.MaximumColumnCount = 1
	self.ViewLocation = GCompute.CodeEditor.LineColumnLocation ()
	
	self.LineNumbersVisible = true
	
	-- Compiler
	self.CompilationEnabled = true
	self.EditorHelper = GCompute.IEditorHelper ()
	
	-- Autocomplete
	self.CodeCompletionProvider = GCompute.CodeEditor.CodeCompletion.CodeCompletionProvider (self)
	
	self.ToolTipController = Gooey.ToolTipController (self)
	self.ToolTipController:SetManual (true)
	
	self.HoveredToken = nil
	self.HoverStartTime = 0
	
	-- Profiling
	self.LastRenderTime = 0
	
	self:SetKeyboardMap (GCompute.CodeEditor.KeyboardMap)
	
	-- Final initialization
	self:SetDocument (GCompute.IDE.DocumentTypes:Create ("CodeDocument"))
end

-- Control
function PANEL:Focus ()
	self.TextEntry:RequestFocus ()
end

function PANEL:GetContextMenu ()
	return self.ContextMenu
end

function PANEL:GetLineHeight ()
	return self.Settings.LineHeight
end

function PANEL:IsFocused ()
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
		self.VScroll:SetPos (self:GetWide () - self.VScroll:GetWide (), 0)
		self.VScroll:SetTall (self:GetTall ())
	end
	if self.HScroll then
		self.HScroll:SetVisible (self.HScroll:IsEnabled ())
		self.HScroll:SetPos (0, self:GetTall () - self.HScroll:GetTall ())
		self.HScroll:SetWide (self:GetWide ())
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

function PANEL:SetContextMenu (contextMenu)
	self.ContextMenu = contextMenu
end

-- Rendering
function PANEL:DrawCaret ()
	if not self:ContainsFocus () then return end
	
	if self:GetSelectionMode () == GCompute.CodeEditor.SelectionMode.Regular then
		self:DrawCaretRegular ()
	elseif self:GetSelectionMode () == GCompute.CodeEditor.SelectionMode.Block then
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
	
	local selectionStart, selectionEnd = self.Selection:GetSelectionEndPoints ()
	
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

local indentationGuideColor = Color (128, 128, 128, 16)
function PANEL:DrawLine (lineOffset)
	local lineNumber = self.ViewLocation:GetLine () + lineOffset
	local line = self.Document:GetLine (lineNumber)
	if not line then return end
	
	local y = lineOffset * self.Settings.LineHeight + 0.5 * (self.Settings.LineHeight - self.Settings.FontHeight)
	local x = self:AreLineNumbersVisible () and self.Settings.LineNumberWidth or 0
	local w = self:GetWide ()
	
	-- Localize values used in loop
	local surface              = surface
	local surface_SetDrawColor = surface.SetDrawColor
	local surface_DrawLine     = surface.DrawLine
	local viewLocationColumn   = self.ViewLocation:GetColumn ()
	local characterWidth       = self.Settings.CharacterWidth
	
	-- Bracket highlighting
	local openLine,  openColumn  = self.BracketHighlighter:GetOpenLineColumn  (self.TextRenderer)
	local closeLine, closeColumn = self.BracketHighlighter:GetCloseLineColumn (self.TextRenderer)
	local bracketColumn = math.min (openColumn or math.huge, closeColumn or math.huge)
	
	-- Do not render identation highlighting outside of the bracket range.
	-- If no brackets are found, bracketColumn would be math.huge anyway.
	if lineNumber < (openLine or 0) or lineNumber > (closeLine or self.Document:GetLineCount ()) then bracketColumn = math.huge end
	
	-- Draw indentation guides
	local preceedingWhitespaceColumnCount = self.TextRenderer:GetStringColumnCount (line:GetText ():match ("^[ \t]*"), 0)
	for i = self.TextRenderer:GetTabWidth (), preceedingWhitespaceColumnCount - 1, self.TextRenderer:GetTabWidth () do
		surface_SetDrawColor (i == bracketColumn and GLib.Colors.Red or indentationGuideColor)
		surface_DrawLine (x + (i - viewLocationColumn) * characterWidth, lineOffset * self.Settings.LineHeight, x + (i - viewLocationColumn) * characterWidth, (lineOffset + 1) * self.Settings.LineHeight)
	end
	
	-- Localize values used in loop
	local surface_DrawText     = surface.DrawText
	local surface_SetFont      = surface.SetFont
	local surface_SetTextColor = surface.SetTextColor
	local surface_SetTextPos   = surface.SetTextPos
	local defaultColor         = GLib.Colors.White
	local viewColumnCount      = self.ViewColumnCount
	local textStorage          = line:GetTextStorage ()
	
	-- Bracket highlighting
	local openSegmentIndex      = nil
	local openSegmentCharacter  = nil
	local closeSegmentIndex     = nil
	local closeSegmentCharacter = nil
	local bracketLine, bracketCharacter = self.BracketHighlighter:GetOpenLocation ()
	if bracketLine == lineNumber then
		openSegmentIndex, openSegmentCharacter = textStorage:SegmentIndexFromCharacter (bracketCharacter)
	end
	bracketLine, bracketCharacter = self.BracketHighlighter:GetCloseLocation ()
	if bracketLine == lineNumber then
		closeSegmentIndex, closeSegmentCharacter = textStorage:SegmentIndexFromCharacter (bracketCharacter)
	end
	
	-- Draw text
	surface_SetFont ("GComputeMonospace")
	
	local segmentIndex, currentColumn = textStorage:SegmentIndexFromColumn (viewLocationColumn, self.TextRenderer)
	local columnCount
	x = x - currentColumn * characterWidth
	currentColumn = viewLocationColumn - currentColumn
	local segment = textStorage:GetSegment (segmentIndex)
	while segment and x <= w do
		-- Draw segment text
		surface_SetTextColor (segment.Color)
		surface_SetTextPos (x, y)
		
		if segmentIndex == openSegmentIndex or
		   segmentIndex == closeSegmentIndex then
			-- This segment has one or two highlighted characters
			local after
			local columnCount
			if openSegmentIndex == closeSegmentIndex then
				-- Two highlighted characters in the same segment
				local before, firstHighlighted, middle, secondHighlighted = GLib.UTF8.SplitAt (segment.Text, openSegmentCharacter + 1)
				firstHighlighted, middle = GLib.UTF8.SplitAt (firstHighlighted, 2)
				middle, secondHighlighted = GLib.UTF8.SplitAt (middle, closeSegmentCharacter - openSegmentCharacter)
				secondHighlighted, after = GLib.UTF8.SplitAt (secondHighlighted, 2)
				
				columnCount = self:DrawLineTextHighlighted (x, y, currentColumn, before, firstHighlighted)
				
				surface_SetTextColor (segment.Color)
				columnCount = columnCount + self:DrawLineTextHighlighted (x + columnCount * characterWidth, y, currentColumn + columnCount, middle, secondHighlighted)
			else
				-- Only 1 highlighted character
				local splitCharacter = segmentIndex == openSegmentIndex and openSegmentCharacter or closeSegmentCharacter
				local before, highlighted = GLib.UTF8.SplitAt (segment.Text, splitCharacter + 1)
				highlighted, after = GLib.UTF8.SplitAt (highlighted, 2)
				
				columnCount = self:DrawLineTextHighlighted (x, y, currentColumn, before, highlighted)
			end
			
			-- Draw after
			surface_SetFont ("GComputeMonospace")
			surface_SetTextColor (segment.Color)
			surface_SetTextPos (x + columnCount * characterWidth, y)
			surface_DrawText (after)
		else
			-- This segment has no highlighted characters
			surface_DrawText (segment.Text)
		end
		
		-- Update location
		columnCount = textStorage:GetSegmentColumnCount (segmentIndex, self.TextRenderer)
		currentColumn = currentColumn + columnCount
		x = x + columnCount * characterWidth
		
		segmentIndex = segmentIndex + 1
		segment = textStorage:GetSegment (segmentIndex)
	end
end

function PANEL:DrawLineTextHighlighted (x, y, currentColumn, first, second)
	surface.SetFont ("GComputeMonospace")
	surface.SetTextPos (x, y)
	surface.DrawText (first)
	local columnCount = self.TextRenderer:GetStringColumnCount (first, currentColumn)
	
	surface.SetFont ("GComputeMonospaceBold")
	surface.SetTextColor (GLib.Colors.Red)
	surface.SetTextPos (x + columnCount * self.Settings.CharacterWidth, y)
	surface.DrawText (second)
	columnCount = columnCount + self.TextRenderer:GetStringColumnCount (second, currentColumn + columnCount)
	return columnCount
end

-- This function is unused.
function PANEL:DrawLineSection (lineNumber, startCharacter, endCharacter)
	local relativeLineNumber = lineNumber - self.ViewLocation:GetLine ()
	local line = self.Document:GetLine (lineNumber)
	if relativeLineNumber < 0 then return end
	if relativeLineNumber > self.ViewLineCount then return end
	
	local y = relativeLineNumber * self.Settings.LineHeight + 0.5 * (self.Settings.LineHeight - self.Settings.FontHeight)
	local x = self:AreLineNumbersVisible () and self.Settings.LineNumberWidth or 0
	local w = self:GetWide ()
	
	local characterCount = endCharacter - startCharacter
	local characterWidth = self.Settings.CharacterWidth
	
	-- Draw text
	local textStorage = line:GetTextStorage ()
	local startColumn = line:ColumnFromCharacter (startCharacter, self.TextRenderer)
	local index, segmentCharacter = textStorage:SegmentIndexFromCharacter (startCharacter, self.TextRenderer)
	
	x = x + characterWidth * (startColumn - self.ViewLocation:GetColumn ())
	
	local segment = textStorage:GetSegment (index)
	local currentColumn = startColumn
	local deltaColumn = 0
	while segment and x <= w and characterCount > 0 do
		surface.SetTextPos (x, y)
		local text = GLib.UTF8.Sub (segment.Text, 1 + segmentCharacter, segmentCharacter + characterCount)
		surface.DrawText (text)
		
		deltaColumn = self.TextRenderer:GetStringColumnCount (text, currentColumn)
		currentColumn = currentColumn + deltaColumn
		x = x + characterWidth * deltaColumn
		
		characterCount = characterCount - segment.Length + segmentCharacter
		
		index = index + 1
		segmentCharacter = 0
		segment = textStorage:GetSegment (index)
	end
end

function PANEL:DrawSelection ()
	if self:IsSelectionEmpty () then return end
	
	if self:GetSelectionMode () == GCompute.CodeEditor.SelectionMode.Regular then
		self:DrawSelectionSpans ()
	elseif self:GetSelectionMode () == GCompute.CodeEditor.SelectionMode.Block then
		self:DrawSelectionSpans ()
	end
end

function PANEL:DrawSelectionSpans ()
	local lineNumberWidth = self:AreLineNumbersVisible () and self.Settings.LineNumberWidth or 0
	
	local roundTopLeft = true
	local roundTopRight = true
	local leftColumn = 0
	local rightColumn = 0
	local nextLeftColumn = 0
	local nextRightColumn = 0
	
	-- Don't bother drawing selection highlighting for lines out of view
	local startLine = self.ViewLocation:GetLine () - 2
	local endLine   = self.ViewLocation:GetLine () + self.ViewLineCount + 2
	local enumerator = self.Selection:GetSpanEnumerator (startLine)
	
	local line, leftColumn, rightColumn = enumerator ()
	if not line then return end
	
	local nextLine, nextLeftColumn, nextRightColumn
	leftColumn  = leftColumn  - self.ViewLocation:GetColumn ()
	rightColumn = rightColumn - self.ViewLocation:GetColumn ()
	
	while true do
		nextLine, nextLeftColumn, nextRightColumn = enumerator ()
		if not nextLine then break end
		if nextLine >= endLine then break end
		nextLeftColumn  = nextLeftColumn  - self.ViewLocation:GetColumn ()
		nextRightColumn = nextRightColumn - self.ViewLocation:GetColumn ()
		
		if leftColumn ~= rightColumn then
			draw.RoundedBoxEx (
				4,
				lineNumberWidth + leftColumn * self.Settings.CharacterWidth,
				(line - self.ViewLocation:GetLine ()) * self.Settings.LineHeight,
				(rightColumn - leftColumn) * self.Settings.CharacterWidth,
				self.Settings.LineHeight,
				GLib.Colors.SteelBlue,
				roundTopLeft, roundTopRight,
				nextLeftColumn > leftColumn or nextRightColumn <= leftColumn, nextRightColumn < rightColumn or nextLeftColumn >= rightColumn
			)
		end
		
		roundTopLeft = nextLeftColumn < leftColumn or nextLeftColumn >= rightColumn
		roundTopRight = nextRightColumn > rightColumn or nextRightColumn <= leftColumn
		
		line        = nextLine
		leftColumn  = nextLeftColumn
		rightColumn = nextRightColumn
	end
	
	if leftColumn ~= rightColumn then
		draw.RoundedBoxEx (
			4,
			lineNumberWidth + leftColumn * self.Settings.CharacterWidth,
			(line - self.ViewLocation:GetLine ()) * self.Settings.LineHeight,
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

function PANEL:Paint (w, h)
	local startTime = SysTime ()
	
	local lineNumberWidth = self:AreLineNumbersVisible () and self.Settings.LineNumberWidth or 0
	
	-- Draw background
	surface.SetDrawColor (32, 32, 32, 255)
	surface.DrawRect (lineNumberWidth, 0, self:GetWide () - lineNumberWidth, self:GetTall ())
	
	self:DrawCaretLineHightlighting ()
	self:DrawSelection ()
	
	if not self.Document then return end
	
	self.BracketHighlighter:Think ()
	
	-- Draw ViewLineCount lines and then the one that's partially out of view.
	for i = 0, self.ViewLineCount + 1 do
		self:DrawLine (i)
	end
	self:DrawCaret ()
	
	-- Draw line numbers
	if self:AreLineNumbersVisible () then
		surface.SetDrawColor (GLib.Colors.Gray)
		surface.DrawRect (0, 0, self.Settings.LineNumberWidth, self:GetTall ())
		for i = 0, math.min (self.ViewLineCount, self.Document:GetLineCount () - self.ViewLocation:GetLine () - 1) do
			draw.SimpleText (tostring (self.ViewLocation:GetLine () + i + 1), "GComputeMonospace", self.Settings.LineNumberWidth - 16, i * self.Settings.LineHeight + 0.5 * (self.Settings.LineHeight - self.Settings.FontHeight), GLib.Colors.White, TEXT_ALIGN_RIGHT)
		end
	end
	
	self.LastRenderTime = SysTime () - startTime
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
	self:SetCaretPos (GCompute.CodeEditor.LineColumnLocation (0, 0))
	self:SetSelection (GCompute.CodeEditor.LineColumnLocation (0, 0), GCompute.CodeEditor.LineColumnLocation (0, 0))
end

function PANEL:GetDocument ()
	return self.Document
end

function PANEL:IsMultiline ()
	return self.Multiline
end

function PANEL:IsReadOnly ()
	return self.ReadOnly
end

function PANEL:SetDocument (document)
	if self.Document == document then return end
	
	local oldDocument = self.Document
	local oldLanguage = self.Document and self.Document:GetLanguage ()
	self.Document = document
	
	self:UnhookDocument (oldDocument)
	
	self.EditorHelper = nil
	if self.Document then
		self.EditorHelper = self.Document:GetLanguage () and self.Document:GetLanguage ():GetEditorHelper ()
		if not self.Document.SyntaxHighlighter then
			self.Document.SyntaxHighlighter = GCompute.CodeEditor.SyntaxHighlighter (self.Document)
			self:GetSyntaxHighlighter ():SetEnabled (self:IsCompilationEnabled ())
		end
		if not self.Document.IdentifierHighlighter then
			self.Document.IdentifierHighlighter = GCompute.CodeEditor.IdentifierHighlighter (self.Document, self.Document.SyntaxHighlighter)
			self:GetIdentifierHighlighter ():SetEnabled (self:IsCompilationEnabled ())
		end
	end
	
	self:HookDocument (self.Document)
	self:UpdateLineNumberWidth ()
	
	self.DocumentChangeUnhandled = true
	self.DocumentLinesUnchecked = {}
	local lineCount = self.Document and self.Document:GetLineCount () or 0
	for i = 0, lineCount - 1 do
		self.DocumentLinesUnchecked [i] = true
	end
	
	if not self.EditorHelper then
		self.EditorHelper = GCompute.IEditorHelper ()
	end
	
	self:DispatchEvent ("DocumentChanged", oldDocument, self.Document)
	self:DispatchEvent ("LanguageChanged", oldLanguage, self:GetLanguage ())
	self:DispatchEvent ("SyntaxHighlighterChanged", oldDocument and oldDocument.SyntaxHighlighter, self.Document.SyntaxHighlighter)
	self:DispatchEvent ("IdentifierHighlighterChanged", oldDocument and oldDocument.IdentifierHighlighter, self.Document.IdentifierHighlighter)
end

function PANEL:SetMultiline (multiline)
	self.Multiline = multiline
	self.TextEntry:SetMultiline (self.Multiline)
end

function PANEL:SetReadOnly (readOnly)
	self.ReadOnly = readOnly
end

-- Undo / redo
function PANEL:GetUndoRedoStack ()
	return self.Document:GetUndoRedoStack ()
end

function PANEL:Redo ()
	self:GetUndoRedoStack ():Redo ()
end

function PANEL:Undo ()
	self:GetUndoRedoStack ():Undo ()
end

-- Editing
function PANEL:DeleteSelection ()
	if self.Selection:IsEmpty () then return end
	
	local selectionStart = self.Document:ColumnToCharacter (self.Selection:GetSelectionStart (), self.TextRenderer)
	local selectionEnd   = self.Document:ColumnToCharacter (self.Selection:GetSelectionEnd (),   self.TextRenderer)
	local text = self.Document:GetText (selectionStart, selectionEnd)
	
	local deletionAction = GCompute.CodeEditor.DeletionAction (self, selectionStartLocation, selectionEndLocation, selectionStart, selectionEnd, text)
	deletionAction:Redo ()
	self:GetUndoRedoStack ():Push (deletionAction)
end

function PANEL:GetText ()
	return self.Document:GetText ()
end

function PANEL:IndentSelection ()
	local indentationAction = GCompute.CodeEditor.IndentationAction (self, self:CreateSelectionSnapshot ())
	indentationAction:Redo ()
	self:GetUndoRedoStack ():Push (indentationAction)
end

function PANEL:OutdentSelection ()
	local outdentationAction = GCompute.CodeEditor.OutdentationAction (self, self:CreateSelectionSnapshot ())
	outdentationAction:Redo ()
	self:GetUndoRedoStack ():Push (outdentationAction)
end

function PANEL:ReplaceSelectionText (text, pasted)
	local undoRedoItem = nil
	
	if self.Selection:GetSelectionMode () == GCompute.CodeEditor.SelectionMode.Block and
	   self.Selection:IsMultiline () then
		undoRedoItem = GCompute.CodeEditor.BlockReplacementAction (self, self:CreateSelectionSnapshot (), text)
	elseif self.Selection:IsEmpty () then
		local insertionLocation = self.Document:ColumnToCharacter (self.CaretLocation, self.TextRenderer)
		undoRedoItem = GCompute.CodeEditor.InsertionAction (self, insertionLocation, text)
	else
		local selectionStart = self.Document:ColumnToCharacter (self.Selection:GetSelectionStart (), self.TextRenderer)
		local selectionEnd   = self.Document:ColumnToCharacter (self.Selection:GetSelectionEnd (),   self.TextRenderer)
		local originalText = self.Document:GetText (selectionStart, selectionEnd)
		
		undoRedoItem = GCompute.CodeEditor.ReplacementAction (self, selectionStart, selectionEnd, originalText, text)
	end
	undoRedoItem:Redo ()
	self:GetUndoRedoStack ():Push (undoRedoItem)
	
	if not pasted then
		-- Auto-outdentation
		local autoOutdentationAction
		if self:GetEditorHelper ():ShouldOutdent (self, self.Document:ColumnToCharacter (self:GetCaretPos (), self.TextRenderer)) then
			autoOutdentationAction = autoOutdentationAction or GCompute.CodeEditor.AutoOutdentationAction (self)
			autoOutdentationAction:AddLine (self:GetCaretPos ():GetLine ())
		end
		
		if autoOutdentationAction then
			autoOutdentationAction:Redo ()
			undoRedoItem:ChainItem (autoOutdentationAction)
			
			-- Update caret
			if self.Selection:GetSelectionMode () == GCompute.CodeEditor.SelectionMode.Regular then
				local deltaColumns = self.TextRenderer:GetStringColumnCount (autoOutdentationAction:GetLineIndentation (self.Selection:GetSelectionEnd ():GetLine ()), 0)
				self:SetRawCaretPos (GCompute.CodeEditor.LineColumnLocation (
					self.Selection:GetSelectionEnd ():GetLine (),
					self.Selection:GetSelectionEnd ():GetColumn () - deltaColumns
				))
				self.Selection:SetSelection (self:GetCaretPos ())
			end
		end
	end
	
	-- Autocomplete
	self.CodeCompletionProvider:Trigger ()
end

--- Replaces a range of text in the document
-- @param startLocation The LineCharacterLocation specifying the start of the text range to be replaced
-- @param endLocation The LineCharacterLocation specifying the end of the text range to be replaced
-- @param text The text with which to replace the specified text range
function PANEL:ReplaceText (startLocation, endLocation, text)
	local originalText = self.Document:GetText (startLocation, endLocation)
	local undoRedoItem = GCompute.CodeEditor.ReplacementAction (self, startLocation, endLocation, originalText, text)
	undoRedoItem:Redo ()
	self:GetUndoRedoStack ():Push (undoRedoItem)
end

function PANEL:SetText (text)
	local originalText = self.Document:GetText ()
	if originalText == text then return self end
	
	local undoRedoItem = GCompute.CodeEditor.ReplacementAction (self, self.Document:GetStart (), self.Document:GetEnd (), originalText, text)
	undoRedoItem:Redo ()
	self:GetUndoRedoStack ():Push (undoRedoItem)
	
	self:UpdateScrollBars ()
	
	return self
end

-- Caret
function PANEL:FixupColumn (line, column)
	-- Round to nearest column
	local line = self.Document:GetLine (line)
	
	if not line then
		return line, column
	end
	
	local character, leftColumn = line:CharacterFromColumn (column, self.TextRenderer)
	local rightColumn = leftColumn + self.TextRenderer:GetCharacterColumnCount (line:GetCharacter (character), leftColumn)
	
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

function PANEL:MoveCaretLeft (toWordBoundary, overrideSelectionStart)
	if self.CaretLocation:GetColumn () == 0 then
		if self.CaretLocation:GetLine () == 0 then return end
		
		self:SetRawCaretPos (GCompute.CodeEditor.LineColumnLocation (
			self.CaretLocation:GetLine () - 1,
			self.Document:GetLine (self.CaretLocation:GetLine () - 1):GetColumnCount (self.TextRenderer)
		))
	else
		local lineNumber = self.CaretLocation:GetLine ()
		local line = self.Document:GetLine (lineNumber)
		local column = self.CaretLocation:GetColumn ()
		
		local character = line:CharacterFromColumn (column, self.TextRenderer)
		
		if toWordBoundary then
			local newLocation = self.Document:CharacterToColumn (self.Document:GetPreviousWordBoundary (GCompute.CodeEditor.LineCharacterLocation (lineNumber, character)), self.TextRenderer)
			lineNumber = newLocation:GetLine ()
			column     = newLocation:GetColumn ()
		else
			column = self.TextRenderer:GetStringColumnCount (line:Sub (1, character - 1), 0)
		end
		
		self:SetRawCaretPos (GCompute.CodeEditor.LineColumnLocation (
			lineNumber,
			column
		))
	end
	
	if overrideSelectionStart then
		self:SetSelection (self.CaretLocation, self.CaretLocation)
	else
		self:SetSelectionEnd (self.CaretLocation)
	end
end

function PANEL:MoveCaretRight (toWordBoundary, overrideSelectionStart)
	if self.CaretLocation:GetColumn () == self.Document:GetLine (self.CaretLocation:GetLine ()):GetColumnCount (self.TextRenderer) then
		if self.CaretLocation:GetLine () + 1 == self.Document:GetLineCount () then return end
		
		self.SelectionController:SelectLocation (GCompute.CodeEditor.LineColumnLocation (
			self.CaretLocation:GetLine () + 1,
			0
		), not overrideSelectionStart)
	else
		local lineNumber = self.CaretLocation:GetLine ()
		local line = self.Document:GetLine (lineNumber)
		local column = self.CaretLocation:GetColumn ()
		
		local character = line:CharacterFromColumn (column, self.TextRenderer)
		
		if toWordBoundary then
			local newLocation = self.Document:CharacterToColumn (self.Document:GetNextWordBoundary (GCompute.CodeEditor.LineCharacterLocation (lineNumber, character)), self.TextRenderer)
			lineNumber = newLocation:GetLine ()
			column     = newLocation:GetColumn ()
		else
			column = column + self.TextRenderer:GetCharacterColumnCount (line:GetCharacter (character), column)
		end
		
		self.SelectionController:SelectLocation (GCompute.CodeEditor.LineColumnLocation (
			lineNumber,
			column
		), not overrideSelectionStart)
	end
	
	self:SetRawCaretPos (self.Selection:GetSelectionEnd ())
end

function PANEL:MoveCaretUp (overrideSelectionStart)
	if self.CaretLocation:GetLine () == 0 then
		self:SetRawCaretPos (GCompute.CodeEditor.LineColumnLocation (0, 0))
	else
		self:SetPreferredCaretPos (GCompute.CodeEditor.LineColumnLocation (
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
		self:SetRawCaretPos (GCompute.CodeEditor.LineColumnLocation (
			self.CaretLocation:GetLine (),
			self.Document:GetLine (self.CaretLocation:GetLine ()):GetColumnCount (self.TextRenderer)
		))
	else
		self:SetPreferredCaretPos (GCompute.CodeEditor.LineColumnLocation (
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
		-- Note: This must work even if the CodeEditor has 0 height.
		self:SetVerticalScrollPos (caretLine - math.max (self.ViewLineCount, 1) + 1)
	end
end

--- Sets the caret location, adjusting to the nearest available column. Also sets the preferred caret location to the rounded caret location.
-- @param caretLocation The new caret location
-- @param scrollToCaret Whether the view should be scrolled to make the caret visible
function PANEL:SetCaretPos (caretLocation, scrollToCaret)
	local line = caretLocation:GetLine ()
	line = math.max (line, 0)
	line = math.min (line, self:GetDocument ():GetLineCount () - 1)
	caretLocation = GCompute.CodeEditor.LineColumnLocation (line, self:FixupColumn (line, caretLocation:GetColumn ()))
	self:SetRawCaretPos (caretLocation, scrollToCaret)
end

--- Sets the preferred caret location. The actual caret location is adjusted to the nearest available column.
-- @param preferredCaretLocation The new preferred caret location
-- @param scrollToCaret Whether the view should be scrolled to make the caret visible
function PANEL:SetPreferredCaretPos (preferredCaretLocation, scrollToCaret)
	if scrollToCaret == nil then scrollToCaret = true end
	if self.PreferredCaretLocation == preferredCaretLocation then return end
	
	self.PreferredCaretLocation:CopyFrom (preferredCaretLocation)
	preferredCaretLocation = GCompute.CodeEditor.LineColumnLocation (preferredCaretLocation:GetLine (), self:FixupColumn (preferredCaretLocation:GetLine (), preferredCaretLocation:GetColumn ()))
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
	if self.CaretLocation == caretLocation then return end
	
	self.CaretLocation:CopyFrom (caretLocation)
	self.PreferredCaretLocation:CopyFrom (caretLocation)
	self:DispatchEvent ("CaretMoved", self.CaretLocation)
	
	self:ResetCaretBlinkTime ()
	if scrollToCaret then
		self:ScrollToCaret ()
	end
end

-- Selection
function PANEL:CreateSelectionSnapshot (selectionSnapshot)
	selectionSnapshot = selectionSnapshot or GCompute.CodeEditor.SelectionSnapshot ()
	selectionSnapshot:GetSelection ():CopyFrom (self.Selection)
	selectionSnapshot:SetCaretPosition (self.CaretLocation)
	selectionSnapshot:SetPreferredCaretPosition (self.PreferredCaretLocation)
	return selectionSnapshot
end

function PANEL:GetSelection ()
	return self.Selection
end

function PANEL:GetSelectionEnd ()
	return self.Selection:GetSelectionEnd ()
end

function PANEL:GetSelectionMode ()
	return self.Selection:GetSelectionMode ()
end

function PANEL:GetSelectionStart ()
	return self.Selection:GetSelectionStart ()
end

function PANEL:IsInSelection (location)
	return self.Selection:IsInSelection (location)
end

function PANEL:IsSelectionEmpty ()
	return self.Selection:IsEmpty ()
end

function PANEL:IsSelectionMultiline ()
	return self.Selection:IsMultiline ()
end

function PANEL:RestoreSelectionSnapshot (selectionSnapshot)
	self.Selection:CopyFrom (selectionSnapshot:GetSelection ())
	self.CaretLocation:CopyFrom (selectionSnapshot:GetCaretPosition ())
	self.PreferredCaretLocation:CopyFrom (selectionSnapshot:GetPreferredCaretPosition ())
	
	self:DispatchEvent ("CaretMoved", self.CaretLocation)
end

function PANEL:SelectAll ()
	self:SetSelectionMode (GCompute.CodeEditor.SelectionMode.Regular)
	self:SetSelection (
		self.Document:CharacterToColumn (self.Document:GetStart (), self.TextRenderer),
		self.Document:CharacterToColumn (self.Document:GetEnd (),   self.TextRenderer)
	)
end

function PANEL:SetSelection (selectionStart, selectionEnd)
	self.Selection:SetSelection (selectionStart, selectionEnd)
end

function PANEL:SetSelectionEnd (selectionEnd)
	self.Selection:SetSelectionEnd (selectionEnd)
end

function PANEL:SetSelectionMode (selectionMode)
	self.Selection:SetSelectionMode (selectionMode)
end

function PANEL:SetSelectionStart (selectionStart)
	self.Selection:SetSelectionStart (selectionStart)
end

-- View
function PANEL:AreLineNumbersVisible ()
	return self.LineNumbersVisible
end

function PANEL:IsCaretVisible ()
	return self:IsLocationVisible (self.CaretLocation:GetLine (), self.CaretLocation:GetColumn ())
end

function PANEL:IsLocationVisible (line, column)
	return line   >= self.ViewLocation:GetLine ()   and line   < self.ViewLocation:GetLine   () + self.ViewLineCount   and
	       column >= self.ViewLocation:GetColumn () and column < self.ViewLocation:GetColumn () + self.ViewColumnCount
end

function PANEL:IsLineFullyVisible (line)
	return line >= self.ViewLocation:GetLine () and line <= self.ViewLocation:GetLine () + self.ViewLineCount + 1
end

function PANEL:IsLineVisible (line)
	return line >= self.ViewLocation:GetLine () and line <= self.ViewLocation:GetLine () + self.ViewLineCount
end

function PANEL:LocationToPoint (line, column)
	line   = line   - self.ViewLocation:GetLine ()
	column = column - self.ViewLocation:GetColumn ()
	
	local x = column * self.Settings.CharacterWidth
	local y = line   * self.Settings.LineHeight
	if self:AreLineNumbersVisible () then
		x = x + self.Settings.LineNumberWidth
	end
	return x, y
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
		if self:GetSelectionMode () == GCompute.CodeEditor.SelectionMode.Block then
			column = math.floor (column + 0.5)
		else
			column = lineWidth
		end
	else
		-- Snap to nearest column
		local line = self.Document:GetLine (line)
		local character, leftColumn = line:CharacterFromColumn (math.floor (column), self.TextRenderer)
		local rightColumn = leftColumn + self.TextRenderer:GetCharacterColumnCount (line:GetCharacter (character), leftColumn)
		
		if column - leftColumn < rightColumn - column then
			column = leftColumn
		else
			column = rightColumn
		end
	end
	return GCompute.CodeEditor.LineColumnLocation (line, column)
end

function PANEL:PointToRawLocation (x, y, clamp)
	local line = self.ViewLocation:GetLine () + math.floor (y / self.Settings.LineHeight)
	local column = self.ViewLocation:GetColumn ()
	
	if self:AreLineNumbersVisible () then x = x - self.Settings.LineNumberWidth end
	column = column + x / self.Settings.CharacterWidth
	
	if clamp then
		-- Clamp line
		if line < 0 then line = 0 end
		if line >= self.Document:GetLineCount () then
			line = self.Document:GetLineCount () - 1
		end
		
		local lineWidth = self.Document:GetLine (line):GetColumnCount (self.TextRenderer)
		if column < 0 then
			column = 0
		elseif column > lineWidth then
			if self:GetSelectionMode () == GCompute.CodeEditor.SelectionMode.Block then
				column = math.floor (column + 0.5)
			else
				column = lineWidth
			end
		end
	end
	
	return GCompute.CodeEditor.LineColumnLocation (line, column)
end

function PANEL:PointToRawLocationClamp (x, y)
	return self:PointToRawLocation (x, y, true)
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
	local maxDisplayedLineNumber = tostring (self.Document and self.Document:GetLineCount () or 0)
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
	if self.Selection:IsEmpty () then return end
	
	local text
	if self.Selection:GetSelectionMode () == GCompute.CodeEditor.SelectionMode.Regular then
		local selectionStart = self.Document:ColumnToCharacter (self.Selection:GetSelectionStart (), self.TextRenderer)
		local selectionEnd   = self.Document:ColumnToCharacter (self.Selection:GetSelectionEnd (),   self.TextRenderer)
		
		text = self.Document:GetText (selectionStart, selectionEnd)
	else
		local lines = {}
		local line
		for lineNumber, startColumn, endColumn in self.Selection:GetSpanEnumerator () do
			line = self.Document:GetLine (lineNumber)
			lines [#lines + 1] = line:Sub (
				line:ColumnToCharacter (startColumn, self.TextRenderer) + 1,
				line:ColumnToCharacter (endColumn,   self.TextRenderer)
			)
		end
		text = table.concat (lines, "\n")
	end
	Gooey.Clipboard:SetText (text)
	
	return text
end

function PANEL:CutSelection ()
	if self.Selection:IsEmpty () then return end
	
	local text = self:CopySelection ()
	local deletionAction
	if self.Selection:GetSelectionMode () == GCompute.CodeEditor.SelectionMode.Regular then
		local selectionStart = self.Document:ColumnToCharacter (self.Selection:GetSelectionStart (), self.TextRenderer)
		local selectionEnd   = self.Document:ColumnToCharacter (self.Selection:GetSelectionEnd (),   self.TextRenderer)
		
		deletionAction = GCompute.CodeEditor.DeletionAction (self, selectionStart, selectionEnd, selectionStart, selectionEnd, text)
		deletionAction:SetVerb ("cut")
	else
		deletionAction = GCompute.CodeEditor.BlockDeletionAction (self, self:CreateSelectionSnapshot ())
		deletionAction:SetDescription ("block cut")
	end
	deletionAction:Redo ()
	self:GetUndoRedoStack ():Push (deletionAction)
end

function PANEL:Paste ()
	self.TextEntry:PostMessage ("DoPaste", "", "")
end

-- Compiler
function PANEL:GetCodeCompletionProvider ()
	return self.CodeCompletionProvider
end

function PANEL:GetEditorHelper ()
	return self.EditorHelper
end

function PANEL:GetIdentifierHighlighter ()
	if not self:GetDocument () then return nil end
	return self:GetDocument ().IdentifierHighlighter
end

function PANEL:GetLanguage ()
	if not self:GetDocument () then return nil end
	return self:GetDocument ():GetLanguage ()
end

function PANEL:GetSyntaxHighlighter ()
	if not self:GetDocument () then return nil end
	return self:GetDocument ().SyntaxHighlighter
end

function PANEL:IsCompilationEnabled ()
	return self.CompilationEnabled
end

function PANEL:SetCompilationEnabled (compilationEnabled)
	self.CompilationEnabled = compilationEnabled
	if self:GetSyntaxHighlighter () then
		self:GetSyntaxHighlighter ():SetEnabled (self.CompilationEnabled)
	end
	if self:GetIdentifierHighlighter () then
		self:GetIdentifierHighlighter ():SetEnabled (self.CompilationEnabled)
	end
end

function PANEL:SetLanguage (language)
	if not self:GetDocument () then return nil end
	self:GetDocument ():SetLanguage (language)
end

function PANEL:TokenFromLocation (lineColumnLocation)
	local lineCharacterLocation = self.Document:ColumnToCharacter (lineColumnLocation, self.TextRenderer)
	local line = self.Document:GetLine (lineCharacterLocation:GetLine ())
	if not line then return nil end
	
	return line:GetAttribute ("Token", lineCharacterLocation:GetCharacter ())
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
	
	self.ToolTipController:HideToolTip ()
end

function PANEL:HookDocument (document)
	if not document then return end
	
	document:GetUndoRedoStack ():AddEventListener ("ItemRedone", tostring (self:GetTable ()),
		function (_, undoRedoItem)
			self:DispatchEvent ("ItemRedone")
		end
	)
	document:GetUndoRedoStack ():AddEventListener ("ItemUndone", tostring (self:GetTable ()),
		function (_, undoRedoItem)
			self:DispatchEvent ("ItemUndone")
		end
	)
	
	document:AddEventListener ("LanguageChanged", tostring (self:GetTable ()),
		function (_, oldLanguage, language)
			self.EditorHelper = language and language:GetEditorHelper ()
			
			self:DispatchEvent ("LanguageChanged", oldLanguage, language)
		end
	)
	document:AddEventListener ("LinesShifted", tostring (self:GetTable ()),
		function (_, startLine, endLine, shift)
			self.DocumentChangeUnhandled = true
			
			local startLine = math.min (startLine, startLine + shift)
			local endLine   = math.max (endLine,   endLine   + shift)
			
			for i = startLine, endLine do
				if self.DocumentLinesUnchecked [i] then
					self.DocumentLinesUnchecked [i] = nil
					if self.Document:GetLine (i) then
						self:UpdateMaximumColumnCount (self.Document:GetLine (i):GetColumnCount (self.TextRenderer) + 1)
					end
				end
			end
		end
	)
	document:AddEventListener ("TextCleared", tostring (self:GetTable ()),
		function (_)
			self:SetCaretPos (GCompute.CodeEditor.LineColumnLocation (0, 0))
			self:SetSelection (self:GetCaretPos (), self:GetCaretPos ())
			
			self:SetMaximumColumnCount (1)
			
			self.DocumentChangeUnhandled = true
			self.DocumentLinesUnchecked = {}
			self:UpdateVerticalScrollBar ()
		end
	)
	document:AddEventListener ("TextChanged", tostring (self:GetTable ()),
		function (_)
			self:DispatchEvent ("TextChanged")
		end
	)
	document:AddEventListener ("TextDeleted", tostring (self:GetTable ()),
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
	document:AddEventListener ("TextInserted", tostring (self:GetTable ()),
		function (_, location, text, newLocation)
			self.DocumentChangeUnhandled = true
			
			for i = location:GetLine (), newLocation:GetLine () do
				self.DocumentLinesUnchecked [i] = true
			end
			self:UpdateVerticalScrollBar ()
		end
	)
end

function PANEL:UnhookDocument (document)
	if not document then return end
	
	document:GetUndoRedoStack ():RemoveEventListener ("ItemRedone", tostring (self:GetTable ()))
	document:GetUndoRedoStack ():RemoveEventListener ("ItemUndone", tostring (self:GetTable ()))
	document:RemoveEventListener ("LanguageChanged", tostring (self:GetTable ()))
	document:RemoveEventListener ("LinesShifted",    tostring (self:GetTable ()))
	document:RemoveEventListener ("TextCleared",     tostring (self:GetTable ()))
	document:RemoveEventListener ("TextChanged",     tostring (self:GetTable ()))
	document:RemoveEventListener ("TextDeleted",     tostring (self:GetTable ()))
	document:RemoveEventListener ("TextInserted",    tostring (self:GetTable ()))
end

-- Event handlers
function PANEL:OnGotFocus ()
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
	
	if self:GetCodeCompletionProvider () and
	   self:GetCodeCompletionProvider ():HandleKey (keyCode, ctrl, shift, alt) then
		return
	end
	
	if keyCode == KEY_TAB then
		if not ctrl and not self:IsReadOnly () then
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
		if self:IsMultiline () and not self:IsReadOnly () then
			-- Autocompletion
			local suppressText = self.CodeCompletionProvider:HandleText ("\n", false)
			
			if not suppressText then
				self.Selection:Flatten ()
				
				local replacementLocation = self.Selection:GetSelectionEndPoints ()
				replacementLocation = self.Document:ColumnToCharacter (replacementLocation, self.TextRenderer)
				self:ReplaceSelectionText ("\n" .. self.EditorHelper:GetNewLineIndentation (self, replacementLocation))
			end
		end
	elseif keyCode == KEY_A then
		if ctrl and not shift and not alt then
			self:SelectAll ()
		end
	end
	
	self:DispatchKeyboardAction (keyCode, ctrl, shift, alt)
	
	if self:GetCodeCompletionProvider () then
		self:GetCodeCompletionProvider ():HandlePostKey (keyCode, ctrl, shift, alt)
	end
end

function PANEL:OnMouseDown (mouseCode, x, y)
	self:Focus ()
end

function PANEL:OnMouseLeave ()
	self:SetHoveredToken (nil)
end

function PANEL:OnMouseMove (mouseCode, x, y)
	self:SetHoveredToken (self:TokenFromLocation (self:PointToRawLocationClamp (x, y)))
end

function PANEL:OnMouseUp (mouseCode, x, y)
	if mouseCode == MOUSE_RIGHT then
		if self.ContextMenu then
			self.ContextMenu:SetOwner (self)
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
	self:DispatchEvent ("ViewLocationChanged", self.ViewLocation)
end

function PANEL:OnRemoved ()
	self:UnhookDocument (self.Document)
	if self:GetDocument () then
		if self:GetDocument ():GetViewCount () == 0 then
			self:GetIdentifierHighlighter ():dtor ()
			self:GetSyntaxHighlighter ():dtor ()
		end
	end
	
	self.CodeCompletionProvider:dtor ()
	self.BracketHighlighter:dtor ()
end

function PANEL:OnVScroll (viewOffset)
	if self.ViewLineCount < self.Document:GetLineCount () then
		self.ViewLocation:SetLine (math.floor (viewOffset))
	else
		self.ViewLocation:SetLine (0)
	end
	self:DispatchEvent ("ViewLocationChanged", self.ViewLocation)
end

function PANEL:Think ()
	if not self.Document then return end
	
	if self:GetSyntaxHighlighter () then
		self:GetSyntaxHighlighter ():Think ()
	end
	if self:GetIdentifierHighlighter () then
		self:GetIdentifierHighlighter ():Think ()
	end
	
	self:DocumentUpdateThink ()
	self:HoverThink ()
end

function PANEL:DocumentUpdateThink ()
	if self.DocumentChangeUnhandled then
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
	if self.ToolTipController:IsToolTipVisible () then return end
	
	if SysTime () - self.HoverStartTime > 0.5 then
		-- self.ToolTipController:ShowToolTip ("\"" .. GLib.String.Escape (self.HoveredToken.Value) .. "\"")
	end
end

vgui.Register ("GComputeCodeEditor", PANEL, "GPanel")