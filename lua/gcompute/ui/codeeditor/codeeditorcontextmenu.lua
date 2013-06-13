function GCompute.CodeEditor.CodeEditorContextMenu (self)
	local menu = Gooey.Menu ()
	menu:AddEventListener ("MenuOpening",
		function ()
			local codeEditor = self:GetActiveCodeEditor ()
			if not codeEditor then return end
			
			menu:GetItemById ("Delete"):SetEnabled (not codeEditor:IsSelectionEmpty ())
		end
	)
	menu:AddItem ("Undo")
		:SetIcon ("icon16/arrow_undo.png")
	menu:AddItem ("Redo")
		:SetIcon ("icon16/arrow_redo.png")
	menu:AddSeparator ()
	menu:AddItem ("Cut")
		:SetIcon ("icon16/cut.png")
		:AddEventListener ("Click",
			function ()
				local clipboardTarget = self:GetActiveClipboardTarget ()
				if not clipboardTarget then return end
				clipboardTarget:Cut ()
			end
		)
	menu:AddItem ("Copy")
		:SetIcon ("icon16/page_white_copy.png")
		:AddEventListener ("Click",
			function ()
				local clipboardTarget = self:GetActiveClipboardTarget ()
				if not clipboardTarget then return end
				clipboardTarget:Copy ()
			end
		)
	menu:AddItem ("Paste")
		:SetIcon ("icon16/paste_plain.png")
		:AddEventListener ("Click",
			function ()
				local clipboardTarget = self:GetActiveClipboardTarget ()
				if not clipboardTarget then return end
				clipboardTarget:Paste ()
			end
		)
	menu:AddItem ("Delete")
		:SetIcon ("icon16/cross.png")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:DeleteSelection ()
			end
		)
	menu:AddSeparator ()
	menu:AddItem ("Select All")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:SelectAll ()
			end
		)
	menu:AddSeparator ()
	menu:AddItem ("Indent")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:IndentSelection ()
			end
		)
	menu:AddItem ("Outdent")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:OutdentSelection ()
			end
		)
	return menu
end