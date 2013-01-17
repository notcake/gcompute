GCompute.CodeEditor.KeyboardMap:Register (KEY_Y,
	function (self, key, ctrl, shift, alt)
		if self:IsReadOnly () then return end
		if not ctrl then return end
		
		self:GetUndoRedoStack ():Redo ()
	end
)

GCompute.CodeEditor.KeyboardMap:Register (KEY_Z,
	function (self, key, ctrl, shift, alt)
		if self:IsReadOnly () then return end
		if not ctrl then return end
		
		self:GetUndoRedoStack ():Undo ()
	end
)