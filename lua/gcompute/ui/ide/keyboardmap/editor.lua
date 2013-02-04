GCompute.IDE.KeyboardMap:Register (KEY_Q,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		
		self:GetActionMap ():Execute ("Exit")
	end
)

GCompute.IDE.KeyboardMap:Register (KEY_W,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		
		self:GetActionMap ():Execute ("Close")
	end
)