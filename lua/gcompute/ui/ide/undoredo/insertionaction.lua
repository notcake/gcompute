local self = {}
GCompute.IDE.InsertionAction = GCompute.MakeConstructor (self, GCompute.UndoRedoItem)

function self:ctor (codeEditor, insertionLocation, text)
	self.CodeEditor = codeEditor
	self.Document = self.CodeEditor:GetDocument ()
	
	self.InsertionLocation = GCompute.IDE.LineCharacterLocation (insertionLocation)
	self.Text = text
	
	self.FinalLocation = GCompute.IDE.LineCharacterLocation (self.InsertionLocation)
	
	self:SetVerb ("insert")
end

function self:Redo ()
	self.FinalLocation:CopyFrom (self.Document:Insert (self.InsertionLocation, self.Text))
	
	self.CodeEditor:SetRawCaretPos (self.Document:CharacterToColumn (self.FinalLocation, self.CodeEditor.TextRenderer))
	self.CodeEditor:SetSelection (self.CodeEditor.CaretLocation, self.CodeEditor.CaretLocation)
	
	self.CodeEditor:ScrollToCaret ()
end

function self:SetFinalLocation (finalLocation)
	self.FinalLocation:CopyFrom (finalLocation)
end

function self:SetText (text)
	self.Text = text
	
	self:SetDescription (verb .. " \"" .. GLib.String.Escape (GLib.UTF8.Sub (self.Text, 1, 32)) .. "\"")
end

function self:SetVerb (verb)
	verb = verb or "insert"
	
	self:SetDescription (verb .. " \"" .. GLib.String.Escape (GLib.UTF8.Sub (self.Text, 1, 32)) .. "\"")
end

function self:Undo ()
	self.Document:Delete (self.InsertionLocation, self.FinalLocation)
	
	self.CodeEditor:SetRawCaretPos (self.Document:CharacterToColumn (self.InsertionLocation, self.CodeEditor.TextRenderer))
	self.CodeEditor:SetSelection (self.CodeEditor.CaretLocation, self.CodeEditor.CaretLocation)
	
	self.CodeEditor:ScrollToCaret ()
end