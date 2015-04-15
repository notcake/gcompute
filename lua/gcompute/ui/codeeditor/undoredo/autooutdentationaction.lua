local self = {}
GCompute.CodeEditor.AutoOutdentationAction = GCompute.MakeConstructor (self, Gooey.UndoRedoItem)

function self:ctor (codeEditor, selectionSnapshot)
	self.CodeEditor   = codeEditor
	self.TextRenderer = self.CodeEditor:GetTextRenderer ():Clone ()
	
	self.PreSelectionSnapshot  = selectionSnapshot
	self.PostSelectionSnapshot = selectionSnapshot
	self.TabWidth = self.TextRenderer:GetTabWidth ()
	
	self.Lines = {}
	self.LineSet = {}
	self.Indentations = {}
	
	self:SetDescription ("auto-outdent " .. #self.Lines .. " line" .. (lineCount == 1 and "" or "s"))
end

function self:AddLine (line)
	if self.LineSet [line] then return end
	
	self.LineSet [line] = true
	self.Lines [#self.Lines + 1] = line
	
	self:SetDescription ("auto-outdent " .. #self.Lines .. " line" .. (lineCount == 1 and "" or "s"))
end

function self:GetLineIndentation (line)
	return self.Indentations [line]
end

function self:SetPreSelectionSnapshot (selectionSnapshot)
	self.PreSelectionSnapshot = selectionSnapshot
	return self
end

function self:SetPostSelectionSnapshot (selectionSnapshot)
	self.PostSelectionSnapshot = selectionSnapshot
	return self
end

function self:Redo ()
	print ("REDO")
	local line
	local indentation
	local character
	
	local deletionStart = GCompute.CodeEditor.LineCharacterLocation ()
	local deletionEnd   = GCompute.CodeEditor.LineCharacterLocation ()
	deletionStart:SetCharacter (0)
	
	for _, lineNumber in ipairs (self.Lines) do
		line = self.CodeEditor.Document:GetLine (lineNumber)
		indentation = string.match (line:GetText (), "^[ \t]*")
		character = self.TextRenderer:CharacterFromColumn (indentation, self.TabWidth)
		self.Indentations [lineNumber] = line:Sub (1, character)
		
		deletionStart:SetLine (lineNumber)
		deletionEnd:SetLine (lineNumber)
		deletionEnd:SetCharacter (character)
		self.CodeEditor.Document:DeleteWithinLine (deletionStart, deletionEnd)
	end
	
	self.CodeEditor:RestoreSelectionSnapshot (self.PostSelectionSnapshot)
end

function self:Undo ()
	print ("UNDO")
	local insertionLocation = GCompute.CodeEditor.LineCharacterLocation ()
	insertionLocation:SetCharacter (0)
	
	for i = #self.Lines, 1, -1 do
		insertionLocation:SetLine (self.Lines [i])
		
		self.CodeEditor.Document:InsertWithinLine (insertionLocation, self.Indentations [self.Lines [i]])
	end
	
	self.CodeEditor:RestoreSelectionSnapshot (self.PreSelectionSnapshot)
end