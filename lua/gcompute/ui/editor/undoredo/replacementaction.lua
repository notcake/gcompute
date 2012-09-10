local self = {}
GCompute.Editor.ReplacementAction = GCompute.MakeConstructor (self, GCompute.UndoRedoItem)

function self:ctor (codeEditor, selectionStartLocation, selectionEndLocation, originalText, finalText)
	self.CodeEditor = codeEditor
	
	self.SelectionStartLocation = GCompute.Editor.LineCharacterLocation (selectionStartLocation)
	self.SelectionEndLocation   = GCompute.Editor.LineCharacterLocation (selectionEndLocation)
	
	self.InsertionLocation      = GCompute.Editor.LineCharacterLocation (self.SelectionStartLocation)
	self.FinalLocation          = GCompute.Editor.LineCharacterLocation (self.SelectionStartLocation)
	
	self.OriginalText = originalText
	self.FinalText = finalText
	
	self:SetVerb ("replace")
end

function self:Redo ()
	self.InsertionLocation = self.CodeEditor.Document:Delete (self.SelectionStartLocation, self.SelectionEndLocation)
	self.FinalLocation = self.CodeEditor.Document:Insert (self.InsertionLocation, self.FinalText)
	self.CodeEditor:SetRawCaretPos (self.CodeEditor.Document:CharacterToColumn (self.FinalLocation, self.CodeEditor.TextRenderer))
	self.CodeEditor:SetSelection (self.CodeEditor.CaretLocation, self.CodeEditor.CaretLocation)
	
	self.CodeEditor:ScrollToCaret ()
end

function self:SetVerb (verb)
	verb = verb or "replace"
	
	self:SetDescription (verb .. " \"" .. GLib.String.Escape (GLib.UTF8.Sub (self.OriginalText, 1, 16)) .. "\" with \"" .. GLib.String.Escape (GLib.UTF8.Sub (self.FinalText, 1, 16)) .. "\"")
end

function self:Undo ()
	self.CodeEditor.Document:Delete (self.InsertionLocation, self.FinalLocation)
	self.CodeEditor.Document:Insert (self.InsertionLocation, self.OriginalText)
	
	self.CodeEditor:SetRawCaretPos (self.CodeEditor.Document:CharacterToColumn (self.SelectionEndLocation, self.CodeEditor.TextRenderer))
	self.CodeEditor:SetSelection (self.CodeEditor.Document:CharacterToColumn (self.SelectionStartLocation, self.CodeEditor.TextRenderer), self.CodeEditor.CaretLocation)
	
	self.CodeEditor:ScrollToCaret ()
end