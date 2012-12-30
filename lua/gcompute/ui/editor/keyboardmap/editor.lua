GCompute.Editor.EditorKeyboardMap:Register (KEY_Q,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		self:SetVisible (false)
	end
)

GCompute.Editor.EditorKeyboardMap:Register (KEY_W,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		if not self:GetActiveView () then return end
		if not self:GetActiveView ():CanClose () then return end
		self:CloseView (self:GetActiveView ())
	end
)