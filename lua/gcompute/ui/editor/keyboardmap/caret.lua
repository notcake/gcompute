GCompute.Editor.CodeEditorKeyboardMap:Register (KEY_LEFT,
	function (self, key, ctrl, shift, alt)
		self:MoveCaretLeft (not shift)
	end
)

GCompute.Editor.CodeEditorKeyboardMap:Register (KEY_RIGHT,
	function (self, key, ctrl, shift, alt)
		self:MoveCaretRight (not shift)
	end
)

GCompute.Editor.CodeEditorKeyboardMap:Register (KEY_UP,
	function (self, key, ctrl, shift, alt)
		self:MoveCaretUp (not shift)
	end
)

GCompute.Editor.CodeEditorKeyboardMap:Register (KEY_DOWN,
	function (self, key, ctrl, shift, alt)
		self:MoveCaretDown (not shift)
	end
)

GCompute.Editor.CodeEditorKeyboardMap:Register (KEY_HOME,
	function (self, key, ctrl, shift, alt)
		local homeColumn = 0
		local line = self.Document:GetLine (self.CaretLocation:GetLine ())
		local text = line:GetText ()
		local offset = 1
		local char = ""
		while true do
			char, offset = GLib.UTF8.NextChar (text, offset)
			if char == "\t" or char == " " then
				homeColumn = homeColumn + line:GetCharacterWidth (char)
			else
				break
			end
		end
		
		self:SetRawCaretPos (GCompute.Editor.LineColumnLocation (
			self.CaretLocation:GetLine (),
			self.CaretLocation:GetColumn () == homeColumn and 0 or homeColumn
		))
		
		if shift then
			self:SetSelectionEnd (self.CaretLocation)
		else
			self:SetSelection (self.CaretLocation, self.CaretLocation)
		end
	end
)

GCompute.Editor.CodeEditorKeyboardMap:Register (KEY_END,
	function (self, key, ctrl, shift, alt)
		self:SetRawCaretPos (GCompute.Editor.LineColumnLocation (
			self.CaretLocation:GetLine (),
			self.Document:GetLine (self.CaretLocation:GetLine ()):GetColumnCount (self.TextRenderer)
		))
		
		if shift then
			self:SetSelectionEnd (self.CaretLocation)
		else
			self:SetSelection (self.CaretLocation, self.CaretLocation)
		end
	end
)

GCompute.Editor.CodeEditorKeyboardMap:Register (KEY_PAGEUP,
	function (self, key, ctrl, shift, alt)
		local caretLocation = GCompute.Editor.LineColumnLocation (self.PreferredCaretLocation)
		local line = caretLocation:GetLine () - self.ViewLineCount
		if line < 0 then line = 0 end
		caretLocation:SetLine (line)
		
		self:SetPreferredCaretPos (caretLocation, false)
		self:ScrollRelative (-self.ViewLineCount)
		
		if shift then
			self:SetSelectionEnd (self.CaretLocation)
		else
			self:SetSelection (self.CaretLocation, self.CaretLocation)
		end
	end
)

GCompute.Editor.CodeEditorKeyboardMap:Register (KEY_PAGEDOWN,
	function (self, key, ctrl, shift, alt)
		local caretLocation = GCompute.Editor.LineColumnLocation (self.PreferredCaretLocation)
		local line = caretLocation:GetLine () + self.ViewLineCount
		if line >= self.Document:GetLineCount () then line = self.Document:GetLineCount () - 1 end
		caretLocation:SetLine (line)
		
		self:SetPreferredCaretPos (caretLocation, false)
		self:ScrollRelative (self.ViewLineCount)
		
		if shift then
			self:SetSelectionEnd (self.CaretLocation)
		else
			self:SetSelection (self.CaretLocation, self.CaretLocation)
		end
	end
)