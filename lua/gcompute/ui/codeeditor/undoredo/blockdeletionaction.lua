local self = {}
GCompute.CodeEditor.BlockDeletionAction = GCompute.MakeConstructor (self, Gooey.UndoRedoItem)

function self:ctor (codeEditor, selectionSnapshot, mode)
	self.CodeEditor = codeEditor
	self.SelectionSnapshot = selectionSnapshot
	
	self.Mode = mode
	self.OriginalTexts         = {}
	self.SpanStartCharacters   = {}
	self.SpanEndCharacters     = {}
	self.Text = text
	
	self:SetDescription ("block deletion")
end

function self:Redo ()
	local deletionStart = GCompute.CodeEditor.LineCharacterLocation ()
	local deletionEnd   = GCompute.CodeEditor.LineCharacterLocation ()
	
	local line
	local startCharacter
	local endCharacter
	for lineNumber, startColumn, endColumn in self.SelectionSnapshot:GetSelectionEnumerator () do
		line = self.CodeEditor.Document:GetLine (lineNumber)
		startCharacter = line:ColumnToCharacter (startColumn, self.CodeEditor:GetTextRenderer ())
		endCharacter   = line:ColumnToCharacter (endColumn,   self.CodeEditor:GetTextRenderer ())
		
		if startCharacter < line:GetLengthExcludingLineBreak () or startColumn == endColumn then
			if self.Mode == "selection" then
			elseif self.Mode == "previouschar" then
				startCharacter = startCharacter - 1
			elseif self.Mode == "previousword" then
				local wordBoundary = self.CodeEditor.Document:GetPreviousWordBoundary (GCompute.CodeEditor.LineCharacterLocation (lineNumber, startCharacter))
				if wordBoundary:GetLine () ~= lineNumber then
					startCharacter = 0
				else
					startCharacter = wordBoundary:GetCharacter ()
				end
			elseif self.Mode == "nextchar" then
				endCharacter = endCharacter + 1
			elseif self.Mode == "nextword" then
				local wordBoundary = self.CodeEditor.Document:GetNextWordBoundary (GCompute.CodeEditor.LineCharacterLocation (lineNumber, startCharacter))
				if wordBoundary:GetLine () ~= lineNumber then
					endCharacter = line:GetLengthExcludingLineBreak ()
				else
					endCharacter = wordBoundary:GetCharacter ()
				end
			end
			self.SpanStartCharacters [lineNumber] = startCharacter
			self.SpanEndCharacters [lineNumber]   = endCharacter
			
			deletionStart:SetLine (lineNumber)
			deletionStart:SetCharacter (startCharacter)
			
			self.OriginalTexts [lineNumber] = line:Sub (self.SpanStartCharacters [lineNumber] + 1, self.SpanEndCharacters [lineNumber])
			if self.OriginalTexts [lineNumber] ~= "" then
				deletionEnd:SetLine (lineNumber)
				deletionEnd:SetCharacter (endCharacter)
				self.CodeEditor.Document:DeleteWithinLine (deletionStart, deletionEnd)
			else
				self.OriginalTexts [lineNumber] = nil
			end
		end
	end
	
	self.CodeEditor:SetSelectionMode (self.SelectionSnapshot:GetSelectionMode ())
	self.CodeEditor:SetSelectionStart (
		GCompute.CodeEditor.LineColumnLocation (
			self.SelectionSnapshot:GetSelectionStart ():GetLine (),
			line:CharacterToColumn (startCharacter, self.CodeEditor:GetTextRenderer ())
		)
	)
	self.CodeEditor:SetSelectionEnd (
		GCompute.CodeEditor.LineColumnLocation (
			self.SelectionSnapshot:GetSelectionEnd ():GetLine (),
			line:CharacterToColumn (startCharacter, self.CodeEditor:GetTextRenderer ())
		)
	)
	self.CodeEditor:SetRawCaretPos (self.CodeEditor:GetSelectionEnd ())
end

function self:Undo ()
	local selectionStart, selectionEnd = self.SelectionSnapshot:GetSelectionEndPoints ()
	
	local deletionStart = GCompute.CodeEditor.LineCharacterLocation ()
	
	for i = selectionStart:GetLine (), selectionEnd:GetLine () do
		deletionStart:SetLine (i)
		deletionStart:SetCharacter (self.SpanStartCharacters [i])
		
		if self.OriginalTexts [i] then
			self.CodeEditor.Document:InsertWithinLine (deletionStart, self.OriginalTexts [i])
		end
	end
	
	self.CodeEditor:RestoreSelectionSnapshot (self.SelectionSnapshot)
end

function self:IsIdentityDeletion ()
	return next (self.OriginalTexts) == nil
end