local self = {}
GCompute.CodeEditor.IndentationAction = GCompute.MakeConstructor (self, GCompute.UndoRedoItem)

function self:ctor (codeEditor, selectionSnapshot)
	self.CodeEditor = codeEditor
	self.SelectionSnapshot = selectionSnapshot
	self.TabWidth = codeEditor:GetTextRenderer ():GetTabWidth ()
	
	local startLine = math.min (self.SelectionSnapshot:GetSelectionStart ():GetLine (), self.SelectionSnapshot:GetSelectionEnd ():GetLine ())
	local endLine   = math.max (self.SelectionSnapshot:GetSelectionStart ():GetLine (), self.SelectionSnapshot:GetSelectionEnd ():GetLine ())
	local lineCount = endLine - startLine + 1
	self:SetDescription ("indent " .. lineCount .. " line" .. (lineCount == 1 and "" or "s"))
end

function self:Redo ()
	local startLine = math.min (self.SelectionSnapshot:GetSelectionStart ():GetLine (), self.SelectionSnapshot:GetSelectionEnd ():GetLine ())
	local endLine   = math.max (self.SelectionSnapshot:GetSelectionStart ():GetLine (), self.SelectionSnapshot:GetSelectionEnd ():GetLine ())
	
	local insertionLocation = GCompute.CodeEditor.LineCharacterLocation ()
	insertionLocation:SetCharacter (0)
	
	for i = startLine, endLine do
		insertionLocation:SetLine (i)
		self.CodeEditor.Document:InsertWithinLine (insertionLocation, "\t")
	end
	
	self.CodeEditor:SetSelectionStart (self.SelectionSnapshot:GetSelectionStart ():AddColumns (self.TabWidth))
	self.CodeEditor:SetSelectionEnd (self.SelectionSnapshot:GetSelectionEnd ():AddColumns (self.TabWidth))
	self.CodeEditor:SetCaretPos (self.SelectionSnapshot:GetCaretPosition ():AddColumns (self.TabWidth))
end

function self:Undo ()
	local startLine = math.min (self.SelectionSnapshot:GetSelectionStart ():GetLine (), self.SelectionSnapshot:GetSelectionEnd ():GetLine ())
	local endLine   = math.max (self.SelectionSnapshot:GetSelectionStart ():GetLine (), self.SelectionSnapshot:GetSelectionEnd ():GetLine ())
	
	local deletionStart = GCompute.CodeEditor.LineCharacterLocation ()
	local deletionEnd = GCompute.CodeEditor.LineCharacterLocation ()
	deletionStart:SetCharacter (0)
	deletionEnd:SetCharacter (1)
	
	for i = startLine, endLine do
		deletionStart:SetLine (i)
		deletionEnd:SetLine (i)
		self.CodeEditor.Document:DeleteWithinLine (deletionStart, deletionEnd)
	end
	
	self.CodeEditor:RestoreSelectionSnapshot (self.SelectionSnapshot)
end