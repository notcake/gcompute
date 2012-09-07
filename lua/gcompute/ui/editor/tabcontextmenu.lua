function GCompute.Editor.TabContextMenu (self)
	local menu = vgui.Create ("GMenu")
	menu:AddEventListener ("MenuOpening",
		function (_, tab)
			local contents = tab and tab:GetContents ()
			
			self.TabContextMenu:GetItemById ("Close")                 :SetEnabled (self:CanCloseTab (tab))
			self.TabContextMenu:GetItemById ("Close all others")      :SetEnabled (self.TabControl:GetTabCount () > 1)
			self.TabContextMenu:GetItemById ("Save")                  :SetEnabled (contents and contents:CanSave ())
			self.TabContextMenu:GetItemById ("Rename")                :SetEnabled (contents and contents:HasPath ())
			self.TabContextMenu:GetItemById ("Delete")                :SetEnabled (contents and contents:HasPath ())
			self.TabContextMenu:GetItemById ("Copy path to clipboard"):SetEnabled (contents and contents:HasPath ())
		end
	)
	
	menu:AddOption ("Close")
		:SetIcon ("gui/g_silkicons/tab_delete")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				self:CloseTab (tab)
			end
		)
	menu:AddOption ("Close all others")
		:SetIcon ("gui/g_silkicons/tab_delete")
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
	menu:AddSeparator ()
	menu:AddOption ("Save")
		:SetIcon ("gui/g_silkicons/disk")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				self:SaveTab (tab)
			end
		)
	menu:AddOption ("Save as...")
		:SetIcon ("gui/g_silkicons/disk")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				self:SaveAsTab (tab)
			end
		)
	menu:AddOption ("Rename")
		:SetIcon ("gui/g_silkicons/page_edit")
		:SetVisible (false)
	menu:AddOption ("Delete")
		:SetIcon ("gui/g_silkicons/cross")
		:SetVisible (false)
	menu:AddSeparator ()
	menu:AddOption ("Copy path to clipboard")
		:SetIcon ("gui/g_silkicons/page_white_copy")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				if not tab:GetContents () then return end
				if not tab:GetContents ():HasPath () then return end
				SetClipboardText (tab:GetContents ():GetPath ())
			end
		)
		
	return menu
end