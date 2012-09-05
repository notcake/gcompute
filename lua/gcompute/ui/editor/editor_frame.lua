local self = {}

function self:Init ()
	self:SetTitle ("Editor (WIP, not working)")

	self:SetSize (ScrW () * 0.75, ScrH () * 0.75)
	self:Center ()
	self:SetDeleteOnClose (false)
	self:MakePopup ()
	
	self.Toolbar = vgui.Create ("GToolbar", self)
	self.Toolbar:AddButton ("New")
		:SetIcon ("gui/g_silkicons/page_white_add")
		:AddEventListener ("Click",
			function ()
				self:CreateEmptyCodeTab ():Select ()
			end
		)
	self.Toolbar:AddButton ("Open")
		:SetIcon ("gui/g_silkicons/folder_page")
		:AddEventListener ("Click",
			function ()
				VFS.OpenOpenFileDialog (
					function (path)
						if not path then return end
						if not self or not self:IsValid () then return end
						
						self:LoadFile (path,
							function (file, tab)
								if not tab then return end
								tab:Select ()
							end
						)
					end
				)
			end
		)
	self.Toolbar:AddButton ("Save")
		:SetIcon ("gui/g_silkicons/disk")
		:AddEventListener ("Click",
			function ()
				self:SaveTab (self:GetSelectedTab ())
			end
		)
	self.Toolbar:AddButton ("Save All")
		:SetIcon ("gui/g_silkicons/disk_multiple")
		:AddEventListener ("Click",
			function ()
				local unsaved = {}
				for i = 1, self.TabControl:GetTabCount () do
					local contents = self.TabControl:GetTab (i):GetContents ()
					if contents then
						if contents:IsUnsaved () then
							unsaved [#unsaved + 1] = self.TabControl:GetTab (i)
						end
					end
				end
				
				if #unsaved == 0 then return end
				
				local saveIterator
				local i = 0
				function saveIterator (success)
					i = i + 1
					if not self or not self:IsValid () then return end
					if not unsaved [i] then return end
					if not success then return end
					self:SaveTab (unsaved [i], saveIterator)
				end
				saveIterator (true)
			end
		)
	self.Toolbar:AddSeparator ()
	self.Toolbar:AddButton ("Cut")
		:SetIcon ("gui/g_silkicons/cut")
		:SetEnabled (false)
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:CutSelection ()
			end
		)
	self.Toolbar:AddButton ("Copy")
		:SetIcon ("gui/g_silkicons/page_white_copy")
		:SetEnabled (false)
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:CopySelection ()
			end
		)
	self.Toolbar:AddButton ("Paste")
		:SetIcon ("gui/g_silkicons/paste_plain")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:Paste ()
			end
		)
	self.Toolbar:AddSeparator ()
	
	-- Don't register click handlers for undo / redo.
	-- Our UndoRedoController does it for us.
	self.Toolbar:AddButton ("Undo")
		:SetIcon ("gui/g_silkicons/arrow_undo")
	self.Toolbar:AddButton ("Redo")
		:SetIcon ("gui/g_silkicons/arrow_redo")
	self.Toolbar:AddSeparator ()
	self.Toolbar:AddButton ("Run Code")
		:SetIcon ("gui/g_silkicons/resultset_next")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				RunString (codeEditor:GetText ())
			end
		)
	self.Toolbar:AddSeparator ()
	
	self.TabControl = vgui.Create ("GTabControl", self)
	self.TabControl:AddEventListener ("SelectedTabChanged",
		function (_, oldSelectedTab, selectedTab)
			local oldContents = oldSelectedTab and oldSelectedTab:GetContents () or nil
			local contents = selectedTab and selectedTab:GetContents () or nil
			local undoRedoStack = contents and contents:GetUndoRedoStack () or nil
			if contents then contents:RequestFocus () end
			self.UndoRedoController:SetUndoRedoStack (undoRedoStack)
			self.ClipboardController:SetControl (contents)
			
			if oldContents then
				self:UnhookSelectedTabContents (oldSelectedTab, oldContents)
			end
			if contents then
				self:HookSelectedTabContents (selectedTab, contents)
			end
		end
	)
	self.TabControl:AddEventListener ("TabAdded",
		function (_, tab)
			tab:SetContextMenu (self.TabContextMenu)
			self:HookTabContents (tab, tab:GetContents ())
		end
	)
	self.TabControl:AddEventListener ("TabCloseRequested",
		function (_, tab)
			self:CloseTab (tab)
		end
	)
	self.TabControl:AddEventListener ("TabContentsChanged",
		function (_, tab, contents)
			self:HookTabContents (tab, contents)
			
			if not tab:IsSelected () then return end
			local contents = tab and tab:GetContents () or nil
			self:HookSelectedTabContents (tab, contents)
			
			if contents then
				contents:RequestFocus ()
			end
			
			local undoRedoStack = contents and contents:GetUndoRedoStack () or nil
			self.UndoRedoController:SetUndoRedoStack (undoRedoStack)
			self.ClipboardController:SetControl (contents)
		end
	)
	self.TabControl:AddEventListener ("TabRemoved",
		function (_, tab)
			self:UnhookTabContents (tab, tab:GetContents ())
		end
	)
	
	self.TabContextMenu = vgui.Create ("GMenu")
	self.TabContextMenu:AddEventListener ("MenuOpening",
		function (_, tab)
			local contents = tab and tab:GetContents ()
			
			self.TabContextMenu:FindItem ("Close")                 :SetEnabled (self:CanCloseTab (tab))
			self.TabContextMenu:FindItem ("Close all others")      :SetEnabled (self.TabControl:GetTabCount () > 1)
			self.TabContextMenu:FindItem ("Save")                  :SetEnabled (contents and contents:CanSave ())
			self.TabContextMenu:FindItem ("Rename")                :SetEnabled (contents and contents:HasFilePath ())
			self.TabContextMenu:FindItem ("Delete")                :SetEnabled (contents and contents:HasFilePath ())
			self.TabContextMenu:FindItem ("Copy path to clipboard"):SetEnabled (contents and contents:HasFilePath ())
		end
	)
	
	self.TabContextMenu:AddOption ("Close")
		:SetIcon ("gui/g_silkicons/tab_delete")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				self:CloseTab (tab)
			end
		)
	self.TabContextMenu:AddOption ("Close all others")
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
	self.TabContextMenu:AddSeparator ()
	self.TabContextMenu:AddOption ("Save")
		:SetIcon ("gui/g_silkicons/disk")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				self:SaveTab (tab)
			end
		)
	self.TabContextMenu:AddOption ("Save as...")
		:SetIcon ("gui/g_silkicons/disk")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				self:SaveAsTab (tab)
			end
		)
	self.TabContextMenu:AddOption ("Rename")
		:SetIcon ("gui/g_silkicons/page_edit")
	self.TabContextMenu:AddOption ("Delete")
		:SetIcon ("gui/g_silkicons/cross")
	self.TabContextMenu:AddSeparator ()
	self.TabContextMenu:AddOption ("Copy path to clipboard")
		:SetIcon ("gui/g_silkicons/page_white_copy")
		:AddEventListener ("Click",
			function (_, tab)
				if not tab then return end
				if not tab:GetContents () then return end
				if not tab:GetContents ():HasFilePath () then return end
				SetClipboardText (tab:GetContents ():GetFilePath ())
			end
		)
	
	self.StatusBar = vgui.Create ("GStatusBar", self)
	
	self.ClipboardController = Gooey.ClipboardController ()
	self.ClipboardController:AddCopyButton  (self.Toolbar:GetItemById ("Copy"))
	self.ClipboardController:AddCutButton   (self.Toolbar:GetItemById ("Cut"))
	self.ClipboardController:AddPasteButton (self.Toolbar:GetItemById ("Paste"))
	
	self.UndoRedoController = Gooey.UndoRedoController ()
	self.UndoRedoController:AddSaveButton   (self.Toolbar:GetItemById ("Save"))
	self.UndoRedoController:AddUndoButton   (self.Toolbar:GetItemById ("Undo"))
	self.UndoRedoController:AddRedoButton   (self.Toolbar:GetItemById ("Redo"))
	
	self:SetKeyboardMap (GCompute.Editor.EditorKeyboardMap)
	
	self.NextNewId = 1
	
	self:InvalidateLayout ()
	
	self:CreateEmptyCodeTab ()
end

function self:PerformLayout ()
	DFrame.PerformLayout (self)
	if self.Toolbar then
		self.Toolbar:SetPos (2, 21)
		self.Toolbar:SetSize (self:GetWide () - 4, self.Toolbar:GetTall ())
	end
	if self.StatusBar then
		self.StatusBar:PerformLayout ()
	end
	if self.TabControl then
		self.TabControl:SetPos (2, 23 + self.Toolbar:GetTall ())
		self.TabControl:SetSize (self:GetWide () - 4, self:GetTall () - 23 - self.Toolbar:GetTall () - 4 - self.StatusBar:GetTall ())
	end
end

--- Returns false if the tab is the last remaining tab and contains the unchanged default text
function self:CanCloseTab (tab)
	if not tab then return false end
	
	local contents = tab:GetContents ()
	if not contents then return true end -- Broken tab
	
	if self.TabControl:GetTabCount () == 1 and
	   contents:IsDefaultContents () and
	   not contents:IsUnsaved () then
		return false
	end
	return true
end

--- Closes a tab
-- @param callback function (success)
function self:CloseTab (tab, callback)
	callback = callback or GCompute.NullCallback
	
	if not tab then callback (true) return end
	local contents = tab:GetContents ()

	-- Don't close the last tab if it contains the default text
	if not self:CanCloseTab (tab) then
		callback (false)
		return
	end
	
	if contents and contents:IsUnsaved () then
		Gooey.YesNoDialog ()
			:SetTitle ("Save")
			:SetText ("Save \"" .. tab:GetText () .. "\"?")
			:SetCallback (
				function (result)
					if result == "Yes" then
						self:SaveTab (tab,
							function (saved)
								if saved then
									self:CloseTab (tab, callback)
								else
									callback (false)
								end
							end
						)
					elseif result == "No" then
						tab:Remove ()
						callback (true)
						
						-- Avoid having no tabs open
						if self.TabControl:GetTabCount () == 0 then
							self:CreateEmptyCodeTab ()
						end
					else
						callback (false)
					end
				end
			)
	else
		tab:Remove ()
		callback (true)
						
		-- Avoid having no tabs open
		if self.TabControl:GetTabCount () == 0 then
			self:CreateEmptyCodeTab ()
		end
	end
end

function self:CreateCodeTab (...)
	local tab = self.TabControl:AddTab (...)
	tab:SetIcon ("gui/g_silkicons/page")
	tab:SetCloseButtonVisible (true)
	
	local codeEditor = vgui.Create ("GComputeCodeEditor")
	
	tab:SetContents (codeEditor)
	
	return tab
end

function self:CreateEmptyCodeTab ()
	local tab = self:CreateCodeTab ("new " .. tostring (self.NextNewId))
	self.NextNewId = self.NextNewId + 1
	
	tab:GetContents ():SetDefaultContents (true)
	tab:GetContents ():SetText (
[[
@name Example

print (1 + 2);
]]
	)
	
	return tab
end

function self:GetActiveCodeEditor ()
	local selectedTab = self:GetSelectedTab ()
	if not selectedTab then return nil end
	return selectedTab:GetContents ()
end

function self:GetSelectedTab ()
	return self.TabControl:GetSelectedTab ()
end

function self:LoadFile (fileOrFilePath, callback)
	callback = callback or GCompute.NullCallback
	
	if type (fileOrFilePath) == "string" then
		VFS.Root:GetChild (GAuth.GetLocalId (), fileOrFilePath,
			function (returnCode, file)
				if not self or not self:IsValid () then return end
				self:LoadFile (file, callback)
			end
		)
		return
	end
	fileOrFilePath:Open (GAuth.GetLocalId (), VFS.OpenFlags.Read,
		function (returnCode, fileStream)
			if returnCode == VFS.ReturnCode.Success then
				fileStream:Read (fileStream:GetLength (),
					function (returnCode, data)
						if returnCode == VFS.ReturnCode.Progress then return end
						
						local file = fileStream:GetFile ()
						local tab = self:CreateCodeTab ()
						tab:SetText (file:GetDisplayPath ())
						tab:GetContents ():SetFilePath (file:GetPath (), file:GetDisplayPath ())
						tab:GetContents ():SetText (data)
						tab:Select ()
						fileStream:Close ()
						
						callback (file, tab)
					end
				)
			else
				callback ()
			end
		end
	)
end

function self:SaveAsTab (tab, callback)
	callback = callback or GCompute.NullCallback
	
	if not tab then callback (true) end
	local contents = tab:GetContents ()
	if not contents then callback (true) end
	
	VFS.OpenSaveFileDialog (
		function (path)
			if not path then callback (false) return end
			if not contents or not contents:IsValid () then callback (false) return end
			contents:SetFilePath (path)
			self:SaveTab (tab, callback)
		end
	)
end

--- Saves a tab's contents.
-- @param tab The tab whose contents are to be saved
-- @param callback function (success)
function self:SaveTab (tab, callback)
	callback = callback or GCompute.NullCallback
	
	if not tab then callback (true) end
	local contents = tab:GetContents ()
	if not contents then callback (true) end
	
	if not contents:HasFilePath () then
		VFS.OpenSaveFileDialog (
			function (path)
				if not path then callback (false) return end
				if not contents or not contents:IsValid () then callback (false) return end
				contents:SetFilePath (path)
				self:SaveTab (tab, callback)
			end
		)
		return
	end
	
	VFS.Root:OpenFile (GAuth.GetLocalId (), contents:GetFilePath (), VFS.OpenFlags.Write + VFS.OpenFlags.Overwrite,
		function (returnCode, fileStream)
			if returnCode == VFS.ReturnCode.Success then
				if not contents or not contents:IsValid () then fileStream:Close () callback (false) return end
				local text = contents:GetText ()
				fileStream:Write (text:len (), text,
					function (returnCode)
						local displayFilePath = fileStream:GetDisplayPath ()
						fileStream:Close ()
						if returnCode == VFS.ReturnCode.Success then
							if contents and contents:IsValid () then
								contents:MarkSaved ()
								contents:SetDisplayFilePath (displayFilePath)
							end
							callback (true)
						else
							callback (false)
						end
					end
				)
			else
				callback (false)
			end
		end
	)
end

-- Internal, do not call
function self:HookSelectedTabContents (tab, contents)
	if not contents then return end
	contents:AddEventListener ("CaretMoved", tostring (self:GetTable ()),
		function (_, caretLocation)
			self.StatusBar:SetText ("Line " .. tostring (caretLocation:GetLine () + 1) .. ", col " .. tostring (caretLocation:GetColumn () + 1))
		end
	)
end

function self:HookTabContents (tab, contents)
	if not contents then return end
	contents:AddEventListener ("DisplayFilePathChanged", tostring (self:GetTable ()),
		function (_, displayFilePath)
			tab:SetText (displayFilePath)
		end
	)
	contents:GetUndoRedoStack ():AddEventListener ("CanSaveChanged", tostring (self:GetTable ()),
		function (_, canSave)
			tab:SetIcon (contents:GetUndoRedoStack ():IsUnsaved () and "gui/g_silkicons/page_red" or "gui/g_silkicons/page")
		end
	)
end

function self:UnhookSelectedTabContents (tab, contents)
	if not contents then return end
	contents:RemoveEventListener ("CaretMoved", tostring (self:GetTable ()))
end

function self:UnhookTabContents (tab, contents)
	if not contents then return end
	contents:RemoveEventListener ("DisplayFilePathChanged", tostring (self:GetTable ()))
	contents:GetUndoRedoStack ():RemoveEventListener ("CanSaveChanged", tostring (self:GetTable ()))
end

-- Event handlers
function self:Think ()
	DFrame.Think (self)
	
	if self:HasFocus () and not Gooey.IsMenuOpen () then
		local selectedTab = self.TabControl:GetSelectedTab ()
		if selectedTab and selectedTab:GetContents () then
			selectedTab:GetContents ():RequestFocus ()
		end
	end
end

vgui.Register ("GComputeEditorFrame", self, "GFrame")