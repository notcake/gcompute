GCompute.Editor.EditorKeyboardMap:Register (KEY_F5,
	function (self, key, ctrl, shift, alt)
		self.Toolbar:GetItemById ("Run Code"):DispatchEvent ("Click")
	end
)