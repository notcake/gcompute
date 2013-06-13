function GCompute.IDE.TabContextMenu (self)
	local menu = Gooey.Menu ()
	menu:AddEventListener ("MenuOpening",
		function (_, tab)
			local tabControl = tab and tab:GetTabControl ()
			local contents = tab and tab:GetContents ()
			local view = tab.View
			
			local hasDocument = view and view:GetDocument () and true or false
			local hasSavable  = view and view:GetSavable () and true or false
			
			self.TabContextMenu:GetItemById ("Close")                 :SetEnabled (self:GetIDE ():CanCloseView (view) or view:CanHide ())
			
			local canCloseOtherTabs = false
			if tabControl then
				for tab in tabControl:GetEnumerator () do
					if tab.View and tab.View ~= view and tab.View:CanClose () then
						canCloseOtherTabs = true
						break
					end
				end
			end
			self.TabContextMenu:GetItemById ("Close all others")      :SetEnabled (canCloseOtherTabs)
			
			self.TabContextMenu:GetItemById ("Separator1")            :SetVisible (hasSavable)
			self.TabContextMenu:GetItemById ("Save")                  :SetVisible (hasSavable)
			self.TabContextMenu:GetItemById ("Save as...")            :SetVisible (hasSavable)
			self.TabContextMenu:GetItemById ("Rename")                :SetVisible (hasSavable)
			self.TabContextMenu:GetItemById ("Delete")                :SetVisible (hasSavable)
			self.TabContextMenu:GetItemById ("Separator2")            :SetVisible (hasSavable)
			self.TabContextMenu:GetItemById ("Copy path to clipboard"):SetVisible (hasSavable)
			self.TabContextMenu:GetItemById ("Separator3")            :SetVisible (hasDocument)
			self.TabContextMenu:GetItemById ("Move to other view")    :SetVisible (hasDocument)
			self.TabContextMenu:GetItemById ("Clone to other view")   :SetVisible (hasDocument)
			
			if view:GetType () == "Code" then
				self.TabContextMenu:GetItemById ("Save")                  :SetEnabled (hasSavable and view:GetSavable ():CanSave ())
				self.TabContextMenu:GetItemById ("Save as...")            :SetEnabled (hasSavable and true or false)
				self.TabContextMenu:GetItemById ("Rename")                :SetEnabled (hasSavable)
				self.TabContextMenu:GetItemById ("Delete")                :SetEnabled (hasSavable and view:GetSavable ():HasUri ())
				self.TabContextMenu:GetItemById ("Copy path to clipboard"):SetEnabled (hasSavable and view:GetSavable ():HasUri ())
			end
		end
	)
	
	menu:AddItem ("Close")
		:SetIcon ("icon16/tab_delete.png")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				self:GetIDE ():CloseView (tab.View)
			end
		)
	menu:AddItem ("Close all others")
		:SetIcon ("icon16/tab_delete.png")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				local tabControl = tab:GetTabControl ()
				
				local tabs = {}
				for i = 1, tabControl:GetTabCount () do
					if tabControl:GetTab (i) ~= tab then
						tabs [#tabs + 1] = tabControl:GetTab (i)
					end
				end
				
				local closeIterator
				local i = 0
				function closeIterator (success)
					i = i + 1
					if not self or not self:IsValid () then return end
					if not tabs [i] then return end
					if not success then return end
					
					if tabs [i].View:CanClose () then
						self:GetIDE ():CloseView (tabs [i].View, closeIterator)
					else
						closeIterator (true)
					end
				end
				closeIterator (true)
			end
		)
	menu:AddSeparator ("Separator1")
	menu:AddItem ("Save")
		:SetIcon ("icon16/disk.png")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				self:GetIDE ():SaveView (tab.View)
			end
		)
	menu:AddItem ("Save as...")
		:SetIcon ("icon16/disk.png")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				self:GetIDE ():SaveAsView (tab.View)
			end
		)
	menu:AddItem ("Rename")
		:SetIcon ("icon16/page_edit.png")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				if not tab.View:GetSavable () then return end
				
				if tab.View:GetSavable ():HasUri () then
				else
					Derma_StringRequest ("Rename " .. tab.View:GetTitle () .. "...", "Enter " .. tab.View:GetTitle () .. "'s new name:", tab.View:GetTitle (),
						function (name)
							tab.View:SetTitle (name)
						end
					)
				end
			end
		)
	menu:AddItem ("Delete")
		:SetIcon ("icon16/cross.png")
	menu:AddSeparator ("Separator2")
	menu:AddItem ("Copy path to clipboard")
		:SetIcon ("icon16/page_white_copy.png")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				if not tab.View:GetSavable () then return end
				if not tab.View:GetSavable ():HasUri () then return end
				Gooey.Clipboard:SetText (tab.View:GetSavable ():GetUri ())
			end
		)
	menu:AddSeparator ("Separator3")
	menu:AddItem ("Move to other view")
		:SetIcon ("icon16/shape_square_go.png")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				local view = tab.View
				if not view then return end
				if not view:GetDocument () then return end
				
				local viewActive = tab:IsSelected ()
				local dockContainer = view:GetContainer ():GetDockContainer ()
				local destinationDockContainer = nil
				if not dockContainer:IsRootDockContainer () then
					local otherDockContainer = dockContainer:GetParentDockContainer ():GetOtherPanel (dockContainer)
					if otherDockContainer:GetLargestView () and otherDockContainer:GetLargestView ():GetDocument () then
						destinationDockContainer = otherDockContainer:GetLargestContainer ()
					end
				end
				if not destinationDockContainer then
					destinationDockContainer = dockContainer:Split (GCompute.DockContainer.DockingSide.Right, 0.5)
				end
				
				for existingView in destinationDockContainer:GetLocalViewEnumerator () do
					if existingView:GetDocument () == view:GetDocument () then
						view:dtor ()
						view = existingView
						break
					end
				end
				destinationDockContainer:AddView (view)
				if viewActive then
					view:GetContainer ():Select ()
					view:GetContainer ():Focus ()
				end
			end
		)
	menu:AddItem ("Clone to other view")
		:SetIcon ("icon16/shape_square_add.png")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				local view = tab.View
				if not view then return end
				if not view:GetDocument () then return end
				
				local viewActive = tab:IsSelected ()
				local dockContainer = view:GetContainer ():GetDockContainer ()
				local destinationDockContainer = nil
				if not dockContainer:IsRootDockContainer () then
					local otherDockContainer = dockContainer:GetParentDockContainer ():GetOtherPanel (dockContainer)
					if otherDockContainer:GetLargestView () and otherDockContainer:GetLargestView ():GetDocument () then
						destinationDockContainer = otherDockContainer:GetLargestContainer ()
					end
				end
				if not destinationDockContainer then
					destinationDockContainer = dockContainer:Split (GCompute.DockContainer.DockingSide.Right, 0.5)
				end
				
				local newView = nil
				for existingView in destinationDockContainer:GetLocalViewEnumerator () do
					if existingView:GetDocument () == view:GetDocument () then
						newView = existingView
						viewActive = true
						break
					end
				end
				if not newView then
					newView = self:CreateView (view:GetType ())
					newView:SetDocument (view:GetDocument ())
					newView:SetTitle (view:GetTitle ())
					destinationDockContainer:AddView (newView)
				end
				if viewActive then
					newView:GetContainer ():Select ()
					newView:GetContainer ():Focus ()
				end
			end
		)
		
	return menu
end