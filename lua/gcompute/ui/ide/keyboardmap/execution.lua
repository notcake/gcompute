GCompute.IDE.KeyboardMap:Register ({ KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12 },
	function (self, key, ctrl, shift, alt)
		self:DispatchAction ("Run Code")
	end
)