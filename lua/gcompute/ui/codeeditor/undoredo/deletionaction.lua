local self = {}
GCompute.CodeEditor.DeletionAction = GCompute.MakeConstructor (self, GCompute.UndoRedoItem)

function self:ctor (codeEditor, selectionStartLocation, selectionEndLocation, deletionStartLocation, deletionEndLocation, text)
	self.CodeEditor = codeEditor
	
	self.SelectionStartLocation = GCompute.CodeEditor.LineCharacterLocation (selectionStartLocation)
	self.SelectionEndLocation   = GCompute.CodeEditor.LineCharacterLocation (selectionEndLocation)
	self.DeletionStartLocation  = GCompute.CodeEditor.LineCharacterLocation (deletionStartLocation)
	self.DeletionEndLocation    = GCompute.CodeEditor.LineCharacterLocation (deletionEndLocation)
	self.Text = text
	
	self.PostDeletionLocation = nil
	
	self:SetVerb ("delete")
end

function self:Redo ()
	self.PostDeletionLocation = self.CodeEditor.Document:Delete (self.DeletionStartLocation, self.DeletionEndLocation)
	self.CodeEditor:SetRawCaretPos (self.CodeEditor.Document:CharacterToColumn (self.PostDeletionLocation, self.CodeEditor.TextRenderer))
	self.CodeEditor:SetSelection (self.CodeEditor.CaretLocation, self.CodeEditor.CaretLocation)
	
	self.CodeEditor:ScrollToCaret ()
end

function self:SetVerb (verb)
	verb = verb or "delete"
	
	self:SetDescription (verb .. " \"" .. GLib.String.Escape (GLib.UTF8.Sub (self.Text, 1, 32)) .. "\"")
end

function self:Undo ()
	self.CodeEditor.Document:Insert (self.PostDeletionLocation, self.Text)
	
	self.CodeEditor:SetRawCaretPos (self.CodeEditor.Document:CharacterToColumn (self.SelectionEndLocation, self.CodeEditor.TextRenderer))
	self.CodeEditor:SetSelection (self.CodeEditor.Document:CharacterToColumn (self.SelectionStartLocation, self.CodeEditor.TextRenderer), self.CodeEditor.CaretLocation)
	
	self.CodeEditor:ScrollToCaret ()
end