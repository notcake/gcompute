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
		:SetIcon ("gui/g_silkicons/arrow_undo")
	menu:AddOption ("Redo")
		:SetIcon ("gui/g_silkicons/arrow_redo")
	menu:AddSeparator ()
	menu:AddOption ("Cut")
		:SetIcon ("gui/g_silkicons/cut")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:CutSelection ()
			end
		)
	menu:AddOption ("Copy")
		:SetIcon ("gui/g_silkicons/page_white_copy")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:CopySelection ()
			end
		)
	menu:AddOption ("Paste")
		:SetIcon ("gui/g_silkicons/paste_plain")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:Paste ()
			end
		)
	menu:AddOption ("Delete")
		:SetIcon ("gui/g_silkicons/cross")
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