GCompute.Editor.CodeEditorKeyboardMap:Register (KEY_Y,
	function (self, key, ctrl, shift, alt)
		if self:IsReadOnly () then return end
		if not ctrl then return end
		
		self.UndoRedoStack:Redo ()
	end
)

GCompute.Editor.CodeEditorKeyboardMap:Register (KEY_Z,
	function (self, key, ctrl, shift, alt)
		if self:IsReadOnly () then return end
		if not ctrl then return end
		
		self.UndoRedoStack:Undo ()
	end
)