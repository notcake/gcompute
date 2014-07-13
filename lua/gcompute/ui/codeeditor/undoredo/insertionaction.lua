local self = {}
GCompute.CodeEditor.InsertionAction = GCompute.MakeConstructor (self, Gooey.UndoRedoItem)

function self:ctor (codeEditor, insertionLocation, text)
	self.CodeEditor = codeEditor
	self.Document = self.CodeEditor:GetDocument ()
	
	self.Verb = nil
	
	self.InsertionLocation = GCompute.CodeEditor.LineCharacterLocation (insertionLocation)
	self.Text = text
	
	self.FinalLocation = GCompute.CodeEditor.LineCharacterLocation (self.InsertionLocation)
	
	self:SetVerb ("insert")
end

function self:Redo ()
	self.FinalLocation:CopyFrom (self.Document:Insert (self.InsertionLocation, self.Text))
	
	self.CodeEditor:SetRawCaretPos (self.Document:CharacterToColumn (self.FinalLocation, self.CodeEditor.TextRenderer))
	self.CodeEditor:SetSelection (self.CodeEditor.CaretLocation, self.CodeEditor.CaretLocation)
	
	self.CodeEditor:ScrollToCaret ()
end

function self:GetInsertionLocation ()
	return self.InsertionLocation
end

function self:GetFinalLocation ()
	return self.FinalLocation
end

function self:GetText ()
	return self.Text
end

function self:SetFinalLocation (finalLocation)
	self.FinalLocation:CopyFrom (finalLocation)
end

function self:SetText (text)
	if self.Text == text then return self end
	
	self.Text = text
	
	self:SetDescription (self.Verb .. " \"" .. GLib.String.Escape (GLib.UTF8.Sub (self.Text, 1, 32)) .. "\"")
	
	return self
end

function self:SetVerb (verb)
	verb = verb or "insert"
	
	if self.Verb == verb then return self end
	
	self.Verb = verb
	
	self:SetDescription (self.Verb .. " \"" .. GLib.String.Escape (GLib.UTF8.Sub (self.Text, 1, 32)) .. "\"")
	
	return self
end

function self:Undo ()
	self.Document:Delete (self.InsertionLocation, self.FinalLocation)
	
	self.CodeEditor:SetRawCaretPos (self.Document:CharacterToColumn (self.InsertionLocation, self.CodeEditor.TextRenderer))
	self.CodeEditor:SetSelection (self.CodeEditor.CaretLocation, self.CodeEditor.CaretLocation)
	
	self.CodeEditor:ScrollToCaret ()
end