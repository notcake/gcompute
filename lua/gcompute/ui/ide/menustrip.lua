function GCompute.IDE.MenuStrip (self)
	local menuStrip = vgui.Create ("GMenuStrip", self)
	
	local fileMenu = menuStrip:AddMenu ("File")
	fileMenu:AddItem ("New")
		:SetAction ("New")
	fileMenu:AddItem ("Open")
		:SetAction ("Open")
	fileMenu:AddItem ("Save")
		:SetAction ("Save")
	fileMenu:AddItem ("Save As...")
		:SetAction ("Save As")
	fileMenu:AddItem ("Save All")
		:SetAction ("Save All")
	fileMenu:AddItem ("Close")
		:SetAction ("Close")
	fileMenu:AddSeparator ()
	fileMenu:AddItem ("Exit")
		:SetAction ("Exit")
	
	local editMenu = menuStrip:AddMenu ("Edit")
	editMenu:AddItem ("Undo")
		:SetIcon ("icon16/arrow_undo.png")
	editMenu:AddItem ("Redo")
		:SetIcon ("icon16/arrow_redo.png")
	editMenu:AddSeparator ()
	editMenu:AddItem ("Cut")
		:SetAction ("Cut")
	editMenu:AddItem ("Copy")
		:SetAction ("Copy")
	editMenu:AddItem ("Paste")
		:SetAction ("Paste")
	editMenu:AddItem ("Select All")
		:SetAction ("Select All")
	
	local toolsMenu = menuStrip:AddMenu ("View")
	local toolsMenuPopulated = false
	toolsMenu:AddEventListener ("MenuOpening",
		function ()
			if toolsMenuPopulated then return end
			
			local autoCreatedViews = {}
			for view in self:GetViewManager ():GetEnumerator () do
				local viewType = self:GetViewTypes ():GetType (view:GetType ())
				if viewType:ShouldAutoCreate () then
					autoCreatedViews [#autoCreatedViews + 1] = view
				end
			end
			
			table.sort (autoCreatedViews,
				function (a, b)
					return a:GetTitle () < b:GetTitle ()
				end
			)
			
			for _, view in ipairs (autoCreatedViews) do
				toolsMenu:AddItem (view:GetTitle ())
					:SetAction (view:GetId ())
			end
		end
	)
	
	local toolsMenu = menuStrip:AddMenu ("Tools")
	toolsMenu:AddItem ("Settings")
		:SetAction ("Open Settings")
	
	local helpMenu = menuStrip:AddMenu ("Help")
	helpMenu:AddItem ("About")
		:SetAction ("Open About")
	
	return menuStrip
end