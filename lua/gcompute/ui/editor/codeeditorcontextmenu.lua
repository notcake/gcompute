function GCompute.Editor.CodeEditorContextMenu (self)
	local menu = vgui.Create ("GMenu")
	menu:AddEventListener ("MenuOpening",
		function ()
			local codeEditor = self:GetActiveCodeEditor ()
			if not codeEditor then return end
			
			menu:GetItemById ("Delete"):SetEnabled (not codeEditor:IsSelectionEmpty ())
		end
	)
	menu:AddOption ("Undo")
		:SetIcon ("icon16/arrow_undo.png")
	menu:AddOption ("Redo")
		:SetIcon ("icon16/arrow_redo.png")
	menu:AddSeparator ()
	menu:AddOption ("Cut")
		:SetIcon ("icon16/cut.png")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:CutSelection ()
			end
		)
	menu:AddOption ("Copy")
		:SetIcon ("icon16/page_white_copy.png")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:CopySelection ()
			end
		)
	menu:AddOption ("Paste")
		:SetIcon ("icon16/paste_plain.png")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:Paste ()
			end
		)
	menu:AddOption ("Delete")
		:SetIcon ("icon16/cross.png")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:DeleteSelection ()
			end
		)
	menu:AddSeparator ()
	menu:AddOption ("Select All")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:SelectAll ()
			end
		)
	menu:AddSeparator ()
	menu:AddOption ("Indent")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:IndentSelection ()
			end
		)
	menu:AddOption ("Outdent")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:OutdentSelection ()
			end
		)
	return menu
end