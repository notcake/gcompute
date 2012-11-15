function GCompute.Editor.TabContextMenu (self)
	local menu = vgui.Create ("GMenu")
	menu:AddEventListener ("MenuOpening",
		function (_, tab)
			local tabControl = tab and tab:GetTabControl ()
			local contents = tab and tab:GetContents ()
			local view = tab.View
			
			local hasDocument = view and view:GetDocument () and true or false
			local hasSavable  = view and view:GetSavable () and true or false
			
			self.TabContextMenu:GetItemById ("Close")                 :SetEnabled (self:CanCloseView (view))
			self.TabContextMenu:GetItemById ("Close all others")      :SetEnabled (tabControl and tabControl:GetTabCount () > 1)
			
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
				self.TabContextMenu:GetItemById ("Rename")                :SetEnabled (hasSavable and view:GetSavable ():HasPath ())
				self.TabContextMenu:GetItemById ("Delete")                :SetEnabled (hasSavable and view:GetSavable ():HasPath ())
				self.TabContextMenu:GetItemById ("Copy path to clipboard"):SetEnabled (hasSavable and view:GetSavable ():HasPath ())
			end
		end
	)
	
	menu:AddOption ("Close")
		:SetIcon ("icon16/tab_delete.png")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				self:CloseView (tab.View)
			end
		)
	menu:AddOption ("Close all others")
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
					self:CloseView (tabs [i].View, closeIterator)
				end
				closeIterator (true)
			end
		)
	menu:AddSeparator ("Separator1")
	menu:AddOption ("Save")
		:SetIcon ("icon16/disk.png")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				self:SaveView (tab.View)
			end
		)
	menu:AddOption ("Save as...")
		:SetIcon ("icon16/disk.png")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				self:SaveAsView (tab.View)
			end
		)
	menu:AddOption ("Rename")
		:SetIcon ("icon16/page_edit.png")
		:SetVisible (false)
	menu:AddOption ("Delete")
		:SetIcon ("icon16/cross.png")
		:SetVisible (false)
	menu:AddSeparator ("Separator2")
	menu:AddOption ("Copy path to clipboard")
		:SetIcon ("icon16/page_white_copy.png")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				if not tab.View:GetSavable () then return end
				if not tab.View:GetSavable ():HasPath () then return end
				Gooey.Clipboard:SetText (tab.View:GetSavable ():GetPath ())
			end
		)
	menu:AddSeparator ("Separator3")
	menu:AddOption ("Move to other view")
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
					destinationDockContainer = dockContainer:Split (GCompute.DockingSide.Right, 0.5)
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
					view:GetContainer ():RequestFocus ()
				end
			end
		)
	menu:AddOption ("Clone to other view")
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
					destinationDockContainer = dockContainer:Split (GCompute.DockingSide.Right, 0.5)
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
					destinationDockContainer:AddView (newView)
				end
				if viewActive then
					newView:GetContainer ():Select ()
					newView:GetContainer ():RequestFocus ()
				end
			end
		)
		
	return menu
end