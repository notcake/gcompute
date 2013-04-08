GCompute.IDE.KeyboardMap:Register (KEY_ESCAPE, "Exit")

GCompute.IDE.KeyboardMap:Register ({ KEY_ESCAPE, KEY_Q },
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		
		self:DispatchAction ("Exit")
	end
)

GCompute.IDE.KeyboardMap:Register (KEY_W,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		
		self:DispatchAction ("Close")
	end
)