function GCompute.Editor.TabContextMenu (self)
	local menu = vgui.Create ("GMenu")
	menu:AddEventListener ("MenuOpening",
		function (_, tab)
			local contents = tab and tab:GetContents ()
			
			self.TabContextMenu:GetItemById ("Close")                 :SetEnabled (self:CanCloseTab (tab))
			self.TabContextMenu:GetItemById ("Close all others")      :SetEnabled (self.TabControl:GetTabCount () > 1)
			
			self.TabContextMenu:GetItemById ("Separator1")            :SetVisible (tab.View:GetType () == "Code")
			self.TabContextMenu:GetItemById ("Save")                  :SetVisible (tab.View:GetType () == "Code")
			self.TabContextMenu:GetItemById ("Save as...")            :SetVisible (tab.View:GetType () == "Code")
			self.TabContextMenu:GetItemById ("Rename")                :SetVisible (tab.View:GetType () == "Code")
			self.TabContextMenu:GetItemById ("Delete")                :SetVisible (tab.View:GetType () == "Code")
			self.TabContextMenu:GetItemById ("Separator2")            :SetVisible (tab.View:GetType () == "Code")
			self.TabContextMenu:GetItemById ("Copy path to clipboard"):SetVisible (tab.View:GetType () == "Code")
			
			if tab.View:GetType () == "Code" then
				self.TabContextMenu:GetItemById ("Save")                  :SetEnabled (tab.View:GetSavable () and tab.View:GetSavable ():CanSave ())
				self.TabContextMenu:GetItemById ("Save as...")            :SetEnabled (tab.View:GetSavable () and true or false)
				self.TabContextMenu:GetItemById ("Rename")                :SetEnabled (tab.View:GetSavable () and tab.View:GetSavable ():HasPath ())
				self.TabContextMenu:GetItemById ("Delete")                :SetEnabled (tab.View:GetSavable () and tab.View:GetSavable ():HasPath ())
				self.TabContextMenu:GetItemById ("Copy path to clipboard"):SetEnabled (tab.View:GetSavable () and tab.View:GetSavable ():HasPath ())
			end
		end
	)
	
	menu:AddOption ("Close")
		:SetIcon ("icon16/tab_delete.png")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				self:CloseTab (tab)
			end
		)
	menu:AddOption ("Close all others")
		:SetIcon ("icon16/tab_delete.png")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				local tabs = {}
				for i = 1, self.TabControl:GetTabCount () do
					if self.TabControl:GetTab (i) ~= tab then
						tabs [#tabs + 1] = self.TabControl:GetTab (i)
					end
				end
				
				local closeIterator
				local i = 0
				function closeIterator (success)
					i = i + 1
					if not self or not self:IsValid () then return end
					if not tabs [i] then return end
					if not success then return end
					self:CloseTab (tabs [i], closeIterator)
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