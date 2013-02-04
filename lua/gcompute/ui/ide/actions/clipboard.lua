GCompute.IDE.ActionMap:Register ("Cut",
	function (self)
		local clipboardTarget = self:GetActiveClipboardTarget ()
		if not clipboardTarget then return end
		clipboardTarget:Cut ()
	end
)

GCompute.IDE.ActionMap:Register ("Copy",
	function (self)
		local clipboardTarget = self:GetActiveClipboardTarget ()
		if not clipboardTarget then return end
		clipboardTarget:Copy ()
	end
)

GCompute.IDE.ActionMap:Register ("Paste",
	function (self)
		local clipboardTarget = self:GetActiveClipboardTarget ()
		if not clipboardTarget then return end
		clipboardTarget:Paste ()
	end
)