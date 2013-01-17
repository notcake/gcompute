GCompute.IDE.CodeEditorKeyboardMap:Register (KEY_C,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		
		self:CopySelection ()
	end
)

GCompute.IDE.CodeEditorKeyboardMap:Register (KEY_X,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		
		self:CutSelection ()
	end
)