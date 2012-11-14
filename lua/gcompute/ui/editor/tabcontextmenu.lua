function GCompute.Editor.TabContextMenu (self)
	local menu = vgui.Create ("GMenu")
	menu:AddEventListener ("MenuOpening",
		function (_, tab)
			local tabControl = tab and tab:GetTabControl ()
			local contents = tab and tab:GetContents ()
			local view = tab.View
			
			self.TabContextMenu:GetItemById ("Close")                 :SetEnabled (self:CanCloseView (view))
			self.TabContextMenu:GetItemById ("Close all others")      :SetEnabled (tabControl and tabControl:GetTabCount () > 1)
			
			self.TabContextMenu:GetItemById ("Separator1")            :SetVisible (view:GetType () == "Code")
			self.TabContextMenu:GetItemById ("Save")                  :SetVisible (view:GetType () == "Code")
			self.TabContextMenu:GetItemById ("Save as...")            :SetVisible (view:GetType () == "Code")
			self.TabContextMenu:GetItemById ("Rename")                :SetVisible (view:GetType () == "Code")
			self.TabContextMenu:GetItemById ("Delete")                :SetVisible (view:GetType () == "Code")
			self.TabContextMenu:GetItemById ("Separator2")            :SetVisible (view:GetType () == "Code")
			self.TabContextMenu:GetItemById ("Copy path to clipboard"):SetVisible (view:GetType () == "Code")
			
			if view:GetType () == "Code" then
				self.TabContextMenu:GetItemById ("Save")                  :SetEnabled (view:GetSavable () and view:GetSavable ():CanSave ())
				self.TabContextMenu:GetItemById ("Save as...")            :SetEnabled (view:GetSavable () and true or false)
				self.TabContextMenu:GetItemById ("Rename")                :SetEnabled (view:GetSavable () and view:GetSavable ():HasPath ())
				self.TabContextMenu:GetItemById ("Delete")                :SetEnabled (view:GetSavable () and view:GetSavable ():HasPath ())
				self.TabContextMenu:GetItemById ("Copy path to clipboard"):SetEnabled (view:GetSavable () and view:GetSavable ():HasPath ())
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
		
	return menu
end