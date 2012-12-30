GCompute.Editor.CodeEditorKeyboardMap:Register (KEY_SPACE,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		if not self:IsCompilationEnabled () then return end
		self:GetCodeCompletionProvider ():Trigger ()
	end
)