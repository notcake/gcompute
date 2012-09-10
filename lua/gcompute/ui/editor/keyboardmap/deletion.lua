GCompute.Editor.CodeEditorKeyboardMap:Register ({ KEY_BACKSPACE, KEY_DELETE },
	function (self, key, ctrl, shift, alt)
		local deletionStart = nil
		local deletionEnd = nil
		
		if key == KEY_BACKSPACE then
			if not self.SelectionStartLocation:Equals (self.SelectionEndLocation) then
				-- Selection deletion
				deletionStart = self.Document:ColumnToCharacter (self.SelectionStartLocation, self.TextRenderer)
				deletionEnd   = self.Document:ColumnToCharacter (self.SelectionEndLocation, self.TextRenderer)
			elseif self.CaretLocation:GetColumn () == 0 then
				if self.CaretLocation:GetLine () == 0 then return end
				
				-- Erase the previous line's newline and
				-- merge the current line with the previous one
				deletionStart = GCompute.Editor.LineCharacterLocation ()
				deletionStart:SetLine (self.CaretLocation:GetLine () - 1)
				deletionStart:SetCharacter (self.Document:GetLine (deletionStart:GetLine ()):LengthExcludingLineBreak ())
				deletionEnd = GCompute.Editor.LineCharacterLocation (deletionStart)
				deletionEnd:SetCharacter (deletionEnd:GetCharacter () + 1)
			else
				-- Erase the previous character
				deletionStart = self.Document:ColumnToCharacter (self.CaretLocation, self.TextRenderer)
				deletionEnd   = GCompute.Editor.LineCharacterLocation (deletionStart)
				deletionStart:SetCharacter (deletionStart:GetCharacter () - 1)
			end
		elseif key == KEY_DELETE then
			if not self.SelectionStartLocation:Equals (self.SelectionEndLocation) then
				-- Selection deletion
				deletionStart = self.Document:ColumnToCharacter (self.SelectionStartLocation, self.TextRenderer)
				deletionEnd   = self.Document:ColumnToCharacter (self.SelectionEndLocation, self.TextRenderer)
			else
				-- Erase the next character
				deletionStart = self.Document:ColumnToCharacter (self.CaretLocation, self.TextRenderer)
				deletionEnd   = GCompute.Editor.LineCharacterLocation (deletionStart)
				deletionEnd:SetCharacter (deletionEnd:GetCharacter () + 1)
				
				if deletionStart:Equals (self.Document:GetEnd ()) then return end
			end
		end
		
		local selectionStartLocation = self.Document:ColumnToCharacter (self.SelectionStartLocation, self.TextRenderer)
		local selectionEndLocation   = self.Document:ColumnToCharacter (self.SelectionEndLocation, self.TextRenderer)
		local text = self.Document:GetText (deletionStart, deletionEnd)
		
		local deletionAction = GCompute.Editor.DeletionAction (self, selectionStartLocation, selectionEndLocation, deletionStart, deletionEnd, text)
		deletionAction:Redo ()
		self.UndoRedoStack:Push (deletionAction)
	end
)