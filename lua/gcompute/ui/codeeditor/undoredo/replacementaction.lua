local self = {}
GCompute.CodeEditor.ReplacementAction = GCompute.MakeConstructor (self, Gooey.UndoRedoItem)

function self:ctor (codeEditor, selectionStartLocation, selectionEndLocation, originalText, finalText)
	self.CodeEditor = codeEditor
	self.SelectionSnapshot = self.CodeEditor:CreateSelectionSnapshot ()
	
	self.SelectionStartLocation = GCompute.CodeEditor.LineCharacterLocation (selectionStartLocation)
	self.SelectionEndLocation   = GCompute.CodeEditor.LineCharacterLocation (selectionEndLocation)
	
	self.InsertionLocation      = GCompute.CodeEditor.LineCharacterLocation (self.SelectionStartLocation)
	self.FinalLocation          = GCompute.CodeEditor.LineCharacterLocation (self.SelectionStartLocation)
	
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
	
	self.CodeEditor:RestoreSelectionSnapshot (self.SelectionSnapshot)
end