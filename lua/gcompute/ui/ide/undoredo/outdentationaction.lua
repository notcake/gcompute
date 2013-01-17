local self = {}
GCompute.IDE.OutdentationAction = GCompute.MakeConstructor (self, GCompute.UndoRedoItem)

function self:ctor (codeEditor, selectionSnapshot)
	self.CodeEditor   = codeEditor
	self.TextRenderer = self.CodeEditor:GetTextRenderer ():Clone ()
	
	self.SelectionSnapshot = selectionSnapshot
	self.TabWidth = self.TextRenderer:GetTabWidth ()
	
	self.Indentations = {}
	
	local startLine = math.min (self.SelectionSnapshot:GetSelectionStart ():GetLine (), self.SelectionSnapshot:GetSelectionEnd ():GetLine ())
	local endLine   = math.max (self.SelectionSnapshot:GetSelectionStart ():GetLine (), self.SelectionSnapshot:GetSelectionEnd ():GetLine ())
	local lineCount = endLine - startLine + 1
	self:SetDescription ("outdent " .. lineCount .. " line" .. (lineCount == 1 and "" or "s"))
end

function self:GetLineIndentation (line)
	return self.Indentations [line]
end

function self:Redo ()
	local startLine = math.min (self.SelectionSnapshot:GetSelectionStart ():GetLine (), self.SelectionSnapshot:GetSelectionEnd ():GetLine ())
	local endLine   = math.max (self.SelectionSnapshot:GetSelectionStart ():GetLine (), self.SelectionSnapshot:GetSelectionEnd ():GetLine ())
	
	local line
	local indentation
	local character
	
	local deletionStart = GCompute.IDE.LineCharacterLocation ()
	local deletionEnd   = GCompute.IDE.LineCharacterLocation ()
	deletionStart:SetCharacter (0)
	
	for i = startLine, endLine do
		line = self.CodeEditor.Document:GetLine (i)
		indentation = string.match (line:GetText (), "^[ \t]*")
		character = self.TextRenderer:CharacterFromColumn (indentation, self.TabWidth)
		self.Indentations [i] = line:Sub (1, character)
		
		deletionStart:SetLine (i)
		deletionEnd:SetLine (i)
		deletionEnd:SetCharacter (character)
		self.CodeEditor.Document:DeleteWithinLine (deletionStart, deletionEnd)
	end
	
	self.CodeEditor:SetSelectionStart (self.SelectionSnapshot:GetSelectionStart ():AddColumns (-self.TabWidth))
	self.CodeEditor:SetSelectionEnd (self.SelectionSnapshot:GetSelectionEnd ():AddColumns (-self.TabWidth))
	self.CodeEditor:SetCaretPos (self.SelectionSnapshot:GetCaretPosition ():AddColumns (-self.TabWidth))
end

function self:Undo ()
	local startLine = math.min (self.SelectionSnapshot:GetSelectionStart ():GetLine (), self.SelectionSnapshot:GetSelectionEnd ():GetLine ())
	local endLine   = math.max (self.SelectionSnapshot:GetSelectionStart ():GetLine (), self.SelectionSnapshot:GetSelectionEnd ():GetLine ())
	
	local insertionLocation = GCompute.IDE.LineCharacterLocation ()
	insertionLocation:SetCharacter (0)
	
	for i = startLine, endLine do
		insertionLocation:SetLine (i)
		
		self.CodeEditor.Document:InsertWithinLine (insertionLocation, self.Indentations [i])
	end
	
	self.CodeEditor:RestoreSelectionSnapshot (self.SelectionSnapshot)
end