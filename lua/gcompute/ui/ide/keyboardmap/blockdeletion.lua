GCompute.IDE.CodeEditorKeyboardMap:Register ({ KEY_BACKSPACE, KEY_DELETE },
	function (self, key, ctrl, shift, alt)
		if self:IsReadOnly () then return end
		if self:GetSelection ():GetSelectionMode () ~= GCompute.IDE.SelectionMode.Block then return false end
		
		local deletionAction
		
		if self:GetSelection ():GetSelectionStart ():GetColumn () ~= self:GetSelection ():GetSelectionEnd ():GetColumn () then
			deletionAction = GCompute.IDE.BlockDeletionAction (self, self:CreateSelectionSnapshot (), "selection")
		elseif key == KEY_BACKSPACE then
			if self.CaretLocation:GetColumn () == 0 then
				return
			elseif ctrl then
				-- Erase the previous word
				deletionAction = GCompute.IDE.BlockDeletionAction (self, self:CreateSelectionSnapshot (), "previousword")
			else
				-- Erase the previous character
				deletionAction = GCompute.IDE.BlockDeletionAction (self, self:CreateSelectionSnapshot (), "previouschar")
			end
		elseif key == KEY_DELETE then
			if ctrl then
				-- Erase the next word
				deletionAction = GCompute.IDE.BlockDeletionAction (self, self:CreateSelectionSnapshot (), "nextword")
			else
				-- Erase the next character
				deletionAction = GCompute.IDE.BlockDeletionAction (self, self:CreateSelectionSnapshot (), "nextchar")
			end
		end
		
		deletionAction:Redo ()
		if not deletionAction:IsIdentityDeletion () then
			self:GetUndoRedoStack ():Push (deletionAction)
		end
	end
)