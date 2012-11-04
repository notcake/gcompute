local self = {}
GCompute.Editor.BlockReplacementAction = GCompute.MakeConstructor (self, GCompute.UndoRedoItem)

function self:ctor (codeEditor, selectionSnapshot, text)
	self.CodeEditor = codeEditor
	self.SelectionSnapshot = selectionSnapshot
	
	self.OriginalTexts         = {}
	self.SpanStartCharacters   = {}
	self.OriginalEndCharacters = {}
	self.FinalEndCharacters    = {}
	self.Text = text
end

function self:Redo ()
	local deletionStart = GCompute.Editor.LineCharacterLocation ()
	local deletionEnd   = GCompute.Editor.LineCharacterLocation ()
	
	local text = {}
	if self.Text:find ("\n") then
		local lines = self.Text:Split ("\n")
		local startLine, endLine = self.SelectionSnapshot:GetSelectionLineSpan ()
		for i = startLine, endLine do
			text [i] = lines [i - startLine + 1] and lines [i - startLine + 1]:gsub ("\r", "") or ""
		end
	end
	
	local line
	local startCharacter
	local endCharacter
	for lineNumber, startColumn, endColumn in self.SelectionSnapshot:GetSelectionEnumerator () do
		line = self.CodeEditor.Document:GetLine (lineNumber)
		startCharacter = line:ColumnToCharacter (startColumn, self.CodeEditor:GetTextRenderer ())
		endCharacter   = line:ColumnToCharacter (endColumn,   self.CodeEditor:GetTextRenderer ())
		self.SpanStartCharacters [lineNumber]   = startCharacter
		self.OriginalEndCharacters [lineNumber] = endCharacter
		
		deletionStart:SetLine (lineNumber)
		deletionStart:SetCharacter (startCharacter)
		
		self.OriginalTexts [lineNumber] = line:Sub (self.SpanStartCharacters [lineNumber] + 1, self.OriginalEndCharacters [lineNumber])
		if self.OriginalTexts [lineNumber] ~= "" then
			deletionEnd:SetLine (lineNumber)
			deletionEnd:SetCharacter (endCharacter)
			self.CodeEditor.Document:DeleteWithinLine (deletionStart, deletionEnd)
		else
			self.OriginalTexts [lineNumber] = nil
		end
		
		endCharacter = self.CodeEditor.Document:InsertWithinLine (deletionStart, text [lineNumber] or self.Text):GetCharacter ()
		self.FinalEndCharacters [lineNumber] = endCharacter
	end
	
	self.CodeEditor:SetSelectionMode (self.SelectionSnapshot:GetSelectionMode ())
	self.CodeEditor:SetSelectionStart (
		GCompute.Editor.LineColumnLocation (
			self.SelectionSnapshot:GetSelectionStart ():GetLine (),
			line:CharacterToColumn (endCharacter, self.CodeEditor:GetTextRenderer ())
		)
	)
	self.CodeEditor:SetSelectionEnd (
		GCompute.Editor.LineColumnLocation (
			self.SelectionSnapshot:GetSelectionEnd ():GetLine (),
			line:CharacterToColumn (endCharacter, self.CodeEditor:GetTextRenderer ())
		)
	)
	self.CodeEditor:SetRawCaretPos (self.CodeEditor:GetSelectionEnd ())
	
	self:UpdateDescription ()
end

function self:Undo ()
	local selectionStart, selectionEnd = self.SelectionSnapshot:GetSelectionEndPoints ()
	
	local deletionStart = GCompute.Editor.LineCharacterLocation ()
	local deletionEnd   = GCompute.Editor.LineCharacterLocation ()
	
	for i = selectionStart:GetLine (), selectionEnd:GetLine () do
		deletionStart:SetLine (i)
		deletionStart:SetCharacter (self.SpanStartCharacters [i])
		deletionEnd:SetLine (i)
		deletionEnd:SetCharacter (self.FinalEndCharacters [i])
		self.CodeEditor.Document:DeleteWithinLine (deletionStart, deletionEnd)
		
		if self.OriginalTexts [i] then
			self.CodeEditor.Document:InsertWithinLine (deletionStart, self.OriginalTexts [i])
		end
	end
	
	self.CodeEditor:RestoreSelectionSnapshot (self.SelectionSnapshot)
end

function self:UpdateDescription ()
	local verb = next (self.OriginalTexts) and "block replace with" or "block insert"
	
	self:SetDescription (verb .. " \"" .. GLib.String.Escape (GLib.UTF8.Sub (self.Text, 1, 16)) .. "\"")
end