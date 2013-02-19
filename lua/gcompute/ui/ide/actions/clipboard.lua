GCompute.IDE.ActionMap:Register ("Cut",
	function (self)
		local clipboardTarget = self:GetActiveClipboardTarget ()
		if not clipboardTarget then return end
		clipboardTarget:Cut ()
	end
):SetIcon ("icon16/cut.png")

GCompute.IDE.ActionMap:Register ("Copy",
	function (self)
		local clipboardTarget = self:GetActiveClipboardTarget ()
		if not clipboardTarget then return end
		clipboardTarget:Copy ()
	end
):SetIcon ("icon16/page_white_copy.png")

GCompute.IDE.ActionMap:Register ("Paste",
	function (self)
		local clipboardTarget = self:GetActiveClipboardTarget ()
		if not clipboardTarget then return end
		clipboardTarget:Paste ()
	end
):SetIcon ("icon16/paste_plain.png")