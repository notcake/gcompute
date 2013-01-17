local self = {}
GCompute.CodeEditor.LineShiftAction = GCompute.MakeConstructor (self, GCompute.UndoRedoItem)

function self:ctor (codeEditor, selectionSnapshot, startLine, endLine, shift)
	self.CodeEditor   = codeEditor
	self.SelectionSnapshot = selectionSnapshot
	
	if startLine < 0 then startLine = 0 end
	if endLine >= self.CodeEditor:GetDocument ():GetLineCount () then
		endLine = self.CodeEditor:GetDocument ():GetLineCount () - 1
	end
	if startLine + shift < 0 then shift = -startLine end
	if endLine + shift >= self.CodeEditor:GetDocument ():GetLineCount () then
		shift = self.CodeEditor:GetDocument ():GetLineCount () - endLine - 1
	end
	
	self.StartLine = startLine
	self.EndLine   = endLine
	self.Shift     = shift
	
	local lineCount = endLine - startLine + 1
	self:SetDescription ("shift " .. lineCount .. " line" .. (lineCount == 1 and "" or "s") .. " " .. (shift > 0 and "down" or "up"))
end

function self:GetShift ()
	return self.Shift
end

function self:Redo ()
	self.CodeEditor:GetDocument ():ShiftLines (self.StartLine, self.EndLine, self.Shift)
	self.CodeEditor:SetSelectionMode (self.SelectionSnapshot:GetSelectionMode ())
	self.CodeEditor:SetSelectionStart (
		GCompute.CodeEditor.LineColumnLocation (
			self.SelectionSnapshot:GetSelectionStart ():GetLine () + self.Shift,
			self.SelectionSnapshot:GetSelectionStart ():GetColumn ()
		)
	)
	self.CodeEditor:SetSelectionEnd (
		GCompute.CodeEditor.LineColumnLocation (
			self.SelectionSnapshot:GetSelectionEnd ():GetLine () + self.Shift,
			self.SelectionSnapshot:GetSelectionEnd ():GetColumn ()
		)
	)
	self.CodeEditor:SetRawCaretPos (self.CodeEditor:GetSelectionEnd ())
end

function self:Undo ()
	self.CodeEditor:GetDocument ():ShiftLines (self.StartLine + self.Shift, self.EndLine + self.Shift, -self.Shift)
	self.CodeEditor:RestoreSelectionSnapshot (self.SelectionSnapshot)
end