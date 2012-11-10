GCompute.Editor.CodeEditorKeyboardMap:Register (KEY_G,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return false end
		
		GCompute.OpenGoToDialog (
			function (line)
				line = line - 1
				if line < 0 then line = 0 end
				if line >= self:GetDocument ():GetLineCount () then line = self:GetDocument ():GetLineCount () - 1 end
				self:SetCaretPos (GCompute.Editor.LineColumnLocation (line, 0))
			end
		)
	end
)