GCompute.IDE.KeyboardMap:Register ({ KEY_N, KEY_T },
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		if shift or alt then return end
		
		self:CreateEmptyCodeView ():Select ()
	end
)

GCompute.IDE.KeyboardMap:Register (KEY_O,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		if shift or alt then return end
		
		self.Toolbar:GetItemById ("Open"):DispatchEvent ("Click")
	end
)

GCompute.IDE.KeyboardMap:Register (KEY_S,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		if shift or alt then return end
		
		self:SaveView (self:GetActiveView ())
	end
)