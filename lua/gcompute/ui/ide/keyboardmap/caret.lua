GCompute.IDE.CodeEditorKeyboardMap:Register (KEY_LEFT,
	function (self, key, ctrl, shift, alt)
		self:MoveCaretLeft (ctrl, not shift)
		self:SetSelectionMode (alt and GCompute.IDE.SelectionMode.Block or GCompute.IDE.SelectionMode.Regular)
	end
)

GCompute.IDE.CodeEditorKeyboardMap:Register (KEY_RIGHT,
	function (self, key, ctrl, shift, alt)
		self:MoveCaretRight (ctrl, not shift)
		self:SetSelectionMode (alt and GCompute.IDE.SelectionMode.Block or GCompute.IDE.SelectionMode.Regular)
	end
)

GCompute.IDE.CodeEditorKeyboardMap:Register (KEY_UP,
	function (self, key, ctrl, shift, alt)
		if ctrl then
			if shift then return false end
			self:ScrollRelative (-1)
		else
			self:MoveCaretUp (not shift)
			self:SetSelectionMode (alt and GCompute.IDE.SelectionMode.Block or GCompute.IDE.SelectionMode.Regular)
		end
	end
)

GCompute.IDE.CodeEditorKeyboardMap:Register (KEY_DOWN,
	function (self, key, ctrl, shift, alt)
		if ctrl then
			if shift then return false end
			self:ScrollRelative (1)
		else
			self:MoveCaretDown (not shift)
			self:SetSelectionMode (alt and GCompute.IDE.SelectionMode.Block or GCompute.IDE.SelectionMode.Regular)
		end
	end
)

GCompute.IDE.CodeEditorKeyboardMap:Register (KEY_HOME,
	function (self, key, ctrl, shift, alt)
		local line = self.Document:GetLine (self.CaretLocation:GetLine ())
		local text = line:GetText ()
		local homeColumn = self.TextRenderer:GetStringColumnCount (string.match (text, "^[ \t]*"), 0)
		local offset = 1
		local char = ""
		
		self:SetRawCaretPos (GCompute.IDE.LineColumnLocation (
			self.CaretLocation:GetLine (),
			self.CaretLocation:GetColumn () == homeColumn and 0 or homeColumn
		))
		
		if shift then
			self:SetSelectionEnd (self.CaretLocation)
			self:SetSelectionMode (alt and GCompute.IDE.SelectionMode.Block or GCompute.IDE.SelectionMode.Regular)
		else
			self:SetSelection (self.CaretLocation, self.CaretLocation)
		end
	end
)

GCompute.IDE.CodeEditorKeyboardMap:Register (KEY_END,
	function (self, key, ctrl, shift, alt)
		self:SetRawCaretPos (GCompute.IDE.LineColumnLocation (
			self.CaretLocation:GetLine (),
			self.Document:GetLine (self.CaretLocation:GetLine ()):GetColumnCount (self.TextRenderer)
		))
		
		if shift then
			self:SetSelectionEnd (self.CaretLocation)
			self:SetSelectionMode (alt and GCompute.IDE.SelectionMode.Block or GCompute.IDE.SelectionMode.Regular)
		else
			self:SetSelection (self.CaretLocation, self.CaretLocation)
		end
	end
)

GCompute.IDE.CodeEditorKeyboardMap:Register (KEY_PAGEUP,
	function (self, key, ctrl, shift, alt)
		local caretLocation = GCompute.IDE.LineColumnLocation (self.PreferredCaretLocation)
		local line = caretLocation:GetLine () - self.ViewLineCount
		if line < 0 then line = 0 end
		caretLocation:SetLine (line)
		
		self:SetPreferredCaretPos (caretLocation, false)
		self:ScrollRelative (-self.ViewLineCount)
		
		if shift then
			self:SetSelectionEnd (self.CaretLocation)
			self:SetSelectionMode (alt and GCompute.IDE.SelectionMode.Block or GCompute.IDE.SelectionMode.Regular)
		else
			self:SetSelection (self.CaretLocation, self.CaretLocation)
		end
	end
)

GCompute.IDE.CodeEditorKeyboardMap:Register (KEY_PAGEDOWN,
	function (self, key, ctrl, shift, alt)
		local caretLocation = GCompute.IDE.LineColumnLocation (self.PreferredCaretLocation)
		local line = caretLocation:GetLine () + self.ViewLineCount
		if line >= self.Document:GetLineCount () then line = self.Document:GetLineCount () - 1 end
		caretLocation:SetLine (line)
		
		self:SetPreferredCaretPos (caretLocation, false)
		self:ScrollRelative (self.ViewLineCount)
		
		if shift then
			self:SetSelectionEnd (self.CaretLocation)
			self:SetSelectionMode (alt and GCompute.IDE.SelectionMode.Block or GCompute.IDE.SelectionMode.Regular)
		else
			self:SetSelection (self.CaretLocation, self.CaretLocation)
		end
	end
)