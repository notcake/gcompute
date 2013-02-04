GCompute.IDE.KeyboardMap:Register ({ KEY_N, KEY_T },
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		if shift or alt then return end
		
		self:GetActionMap ():Execute ("New")
	end
)

GCompute.IDE.KeyboardMap:Register (KEY_O,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		if shift or alt then return end
		
		self:GetActionMap ():Execute ("Open")
	end
)

GCompute.IDE.KeyboardMap:Register (KEY_S,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		if shift or alt then return end
		
		self:GetActionMap ():Execute ("Save")
	end
)