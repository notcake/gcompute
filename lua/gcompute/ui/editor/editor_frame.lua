local self = {}

function self:Init ()
	self:SetTitle ("Editor (WIP, not working)")

	self:SetSize (ScrW () * 0.75, ScrH () * 0.75)
	self:Center ()
	self:SetDeleteOnClose (false)
	self:MakePopup ()
	
	self.Toolbar = GCompute.Editor.Toolbar (self)
	
	self.TabControl = vgui.Create ("GTabControl", self)
	self.TabControl:AddEventListener ("SelectedContentsChanged",
		function (_, oldSelectedTab, oldSelectedContents, selectedTab, selectedContents)
			local undoRedoStack = selectedContents and selectedContents:GetUndoRedoStack () or nil
			if selectedContents then selectedContents:RequestFocus () end
			self.UndoRedoController:SetUndoRedoStack (undoRedoStack)
			self.ClipboardController:SetControl (selectedContents)
			
			self:UnhookSelectedTabContents (oldSelectedTab, oldSelectedContents)
			self:HookSelectedTabContents (selectedTab, selectedContents)
			
			self:UpdateCaretPositionText ()
			self:UpdateLanguageText ()
		end
	)
	self.TabControl:AddEventListener ("TabAdded",
		function (_, tab)
			local contents = tab:GetContents ()
			
			tab:SetContextMenu (self.TabContextMenu)
			
			self:HookTabContents (tab, contents)
			if contents then
				self:RegisterTabPath (tab, contents:GetFile (), contents:GetFile () and contents:GetFile ():GetPath () or nil)
			end
		end
	)
	self.TabControl:AddEventListener ("TabCloseRequested",
		function (_, tab)
			self:CloseTab (tab)
		end
	)
	self.TabControl:AddEventListener ("TabContentsChanged",
		function (_, tab, oldContents, contents)
			if oldContents then
				self:UnregisterTabPath (tab, oldContents:GetFile (), oldContents:GetFile () and oldContents:GetFile ():GetPath ())
			end
			if contents then
				self:RegisterTabPath (tab, contents:GetFile (), contents:GetFile () and contents:GetFile ():GetPath () or nil)
			end
			self:UnhookTabContents (tab, oldContents)
			self:HookTabContents (tab, contents)
		end
	)
	self.TabControl:AddEventListener ("TabRemoved",
		function (_, tab)
			local contents = tab:GetContents ()
			self:UnhookTabContents (tab, contents)
			
			if contents then
				self:UnregisterTabPath (tab, contents:GetFile (), contents:GetFile () and contents:GetFile ():GetPath () or nil)
			end
		end
	)
	
	self.TabContextMenu = GCompute.Editor.TabContextMenu (self)
	self.CodeEditorContextMenu = GCompute.Editor.CodeEditorContextMenu (self)
	
	self.StatusBar = vgui.Create ("GStatusBar", self)
	self.LanguagePanel      = self.StatusBar:AddTextPanel ("Unknown language")
	self.CaretPositionPanel = self.StatusBar:AddTextPanel ("Line 1, col 1")
	self.CaretPositionPanel:SetFixedWidth (96)
	
	self.ClipboardController = Gooey.ClipboardController ()
	self.ClipboardController:AddCopyButton  (self.Toolbar:GetItemById ("Copy"))
	self.ClipboardController:AddCopyButton  (self.CodeEditorContextMenu:GetItemById ("Copy"))
	self.ClipboardController:AddCutButton   (self.Toolbar:GetItemById ("Cut"))
	self.ClipboardController:AddCutButton  (self.CodeEditorContextMenu:GetItemById ("Cut"))
	self.ClipboardController:AddPasteButton (self.Toolbar:GetItemById ("Paste"))
	self.ClipboardController:AddPasteButton  (self.CodeEditorContextMenu:GetItemById ("Paste"))
	
	self.UndoRedoController = Gooey.UndoRedoController ()
	self.UndoRedoController:AddSaveButton   (self.Toolbar:GetItemById ("Save"))
	self.UndoRedoController:AddUndoButton   (self.Toolbar:GetItemById ("Undo"))
	self.UndoRedoController:AddUndoButton   (self.CodeEditorContextMenu:GetItemById ("Undo"))
	self.UndoRedoController:AddRedoButton   (self.Toolbar:GetItemById ("Redo"))
	self.UndoRedoController:AddRedoButton   (self.CodeEditorContextMenu:GetItemById ("Redo"))
	
	self:SetKeyboardMap (GCompute.Editor.EditorKeyboardMap)
	
	self.NextNewId = 1
	
	self.OpenPaths = {} -- map of paths to 
	
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
	codeEditor:SetContextMenu (self.CodeEditorContextMenu)
	
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

--- Opens a new tab for the IFile. Use OpenPath instead if you have a path only.
-- @param file The IFile to be opened.
-- @param callback A callback function (success, IFile file, Tab tab)
function self:OpenFile (file, callback)
	if not file then return end
	
	if self:IsPathOpen (file:GetPath ()) then
		local tabs = self:GetPathTabs (file:GetPath ())
		callback (true, file, tabs [1])
		return
	end
	
	file:Open (GAuth.GetLocalId (), VFS.OpenFlags.Read,
		function (returnCode, fileStream)
			if returnCode == VFS.ReturnCode.Success then
				fileStream:Read (fileStream:GetLength (),
					function (returnCode, data)
						if returnCode == VFS.ReturnCode.Progress then return end
						
						local file = fileStream:GetFile ()
						local tab = self:CreateCodeTab ()
						tab:SetText (file:GetDisplayName ())
						tab:GetContents ():SetFile (file)
						tab:GetContents ():SetText (data)
						fileStream:Close ()
						
						callback (true, file, tab)
					end
				)
			else
				callback (false, file)
			end
		end
	)
end

--- Opens a new tab for the given path. Use OpenFile instead if you have an IFile.
-- @param path The path of the file to be opened
-- @param callback A callback function (success, IFile file, Tab tab)
function self:OpenPath (path, callback)
	callback = callback or GCompute.NullCallback
	
	if self:IsPathOpen (path) then
		local tabs = self:GetPathTabs (path)
		callback (true, self:GetPathFile (path), tabs [1])
		return
	end
	
	VFS.Root:GetChild (GAuth.GetLocalId (), path,
		function (returnCode, file)
			if not self or not self:IsValid () then return end
			if not file then callback (false) return end
			self:OpenFile (file, callback)
		end
	)
end

--- Prompts for a file to which to save, then saves a tab's contents.
-- @param tab The tab whose contents are to be saved
-- @pram callback A callback function (success, IFile file)
function self:SaveAsTab (tab, callback)
	callback = callback or GCompute.NullCallback
	
	local contents = tab and tab:GetContents ()
	if not contents then callback (true) end
	
	VFS.OpenSaveFileDialog (
		function (path, file)
			if not path then callback (false) return end
			if not contents or not contents:IsValid () then callback (false) return end
			self:SaveTab (tab, path,
				function (success, file)
					callback (success, file)
					
					if not contents or not contents:IsValid () then return end
					if file then contents:SetFile (file) end
				end
			)
		end
	)
end

--- Saves a tab's contents.
-- @param tab The tab whose contents are to be saved
-- @param pathOrCallback Optional path to which to save
-- @param callback A callback function (success, IFile file)
function self:SaveTab (tab, pathOrCallback, callback)
	if type (pathOrCallback) == "function" then
		callback = pathOrCallback
		pathOrCallback = nil
	end
	callback = callback or GCompute.NullCallback
	
	local contents = tab and tab:GetContents ()
	if not contents then callback (false) end
	
	-- Determine save path
	local path = pathOrCallback
	if not path and contents:HasPath () then
		path = contents:GetPath ()
	end
	
	-- If the tab has no path, invoke the save as dialog.
	if not path then
		self:SaveAsTab (tab, callback)
		return
	end
	
	VFS.Root:OpenFile (GAuth.GetLocalId (), path, VFS.OpenFlags.Write + VFS.OpenFlags.Overwrite,
		function (returnCode, fileStream)
			if returnCode == VFS.ReturnCode.Success then
				if not contents or not contents:IsValid () then fileStream:Close () callback (false) return end
				local text = contents:GetText ()
				fileStream:Write (text:len (), text,
					function (returnCode)
						local displayPath = fileStream:GetDisplayPath ()
						fileStream:Close ()
						if returnCode == VFS.ReturnCode.Success then
							if contents and contents:IsValid () then
								contents:MarkSaved ()
							end
							callback (true, fileStream:GetFile ())
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
function self:GetPathFile (path)
	if not path then return nil end
	path = path:lower ()
	
	if not self.OpenPaths [path] then return nil end
	return self.OpenPaths [path].File
end

function self:GetPathTabs (path)
	if not path then return {} end
	path = path:lower ()
	
	if not self.OpenPaths [path] then return {} end
	
	local tabs = {}
	for tab, _ in pairs (self.OpenPaths [path].Tabs) do
		tabs [#tabs + 1] = tab
	end
	return tabs
end

function self:IsPathOpen (path)
	if not path then return false end
	path = path:lower ()
	return self.OpenPaths [path] and true or false
end

function self:RegisterTabPath (tab, file, path)
	if not path then return end
	path = path:lower ()
	
	if not self.OpenPaths [path] then
		self.OpenPaths [path] =
		{
			Tabs = {},
			File = file,
			Path = path
		}
	end
	
	self.OpenPaths [path].Tabs [tab] = true
end

function self:UnregisterTabPath (tab, file, path)
	if not path then return end
	path = path:lower ()
	
	if not self.OpenPaths [path] then return end
	self.OpenPaths [path].Tabs [tab] = nil
	if not next (self.OpenPaths [path].Tabs) then
		self.OpenPaths [path] = nil
	end
end

function self:UpdateCaretPositionText ()
	local codeEditor = self:GetActiveCodeEditor ()
	local caretLocation = codeEditor and codeEditor:GetCaretPos () or nil
	if caretLocation then
		self.CaretPositionPanel:SetText ("Line " .. tostring (caretLocation:GetLine () + 1) .. ", col " .. tostring (caretLocation:GetColumn () + 1))
	else
		self.CaretPositionPanel:SetText ("Line --, col --")
	end
end

function self:UpdateLanguageText ()
	local codeEditor = self:GetActiveCodeEditor ()
	local compilationUnit = codeEditor and codeEditor:GetCompilationUnit ()
	local language = compilationUnit and compilationUnit:GetLanguage ()
	if language then
		self.LanguagePanel:SetText (language:GetName () .. " code")
	else
		self.LanguagePanel:SetText ("Unknown language")
	end
end

-- Event hooking
function self:HookSelectedSourceFile (sourceFile)
	sourceFile:GetCompilationUnit ():AddEventListener ("LanguageChanged", tostring (self:GetTable ()),
		function (_, language)
			self:UpdateLanguageText ()
		end
	)
end

function self:UnhookSelectedSourceFile (sourceFile)
	sourceFile:GetCompilationUnit ():RemoveEventListener ("LanguageChanged", tostring (self:GetTable ()))
end

function self:HookSelectedTabContents (tab, contents)
	if not contents then return end
	contents:AddEventListener ("CaretMoved", tostring (self:GetTable ()),
		function (_, caretLocation)
			self:UpdateCaretPositionText ()
		end
	)
	contents:AddEventListener ("SourceFileChanged", tostring (self:GetTable ()),
		function (_, oldSourceFile, sourceFile)
			self:UnhookSelectedSourceFile (oldSourceFile)
			self:HookSelectedSourceFile (sourceFile)
			self:UpdateLanguageText ()
		end
	)
	self:HookSelectedSourceFile (contents:GetSourceFile ())
end

function self:UnhookSelectedTabContents (tab, contents)
	if not contents then return end
	contents:RemoveEventListener ("CaretMoved",        tostring (self:GetTable ()))
	contents:RemoveEventListener ("SourceFileChanged", tostring (self:GetTable ()))
	self:UnhookSelectedSourceFile (contents:GetSourceFile ())
end

function self:HookTabContents (tab, contents)
	if not contents then return end
	contents:AddEventListener ("PathChanged", tostring (self:GetTable ()),
		function (_, oldPath, path)
			self:UnregisterTabPath (tab, contents:GetFile (), oldPath)
			self:RegisterTabPath (tab, contents:GetFile (), path)
			tab:SetText (contents:GetFile ():GetDisplayName ())
		end
	)
	contents:GetUndoRedoStack ():AddEventListener ("CanSaveChanged", tostring (self:GetTable ()),
		function (_, canSave)
			tab:SetIcon (contents:GetUndoRedoStack ():IsUnsaved () and "gui/g_silkicons/page_red" or "gui/g_silkicons/page")
			
			local canSaveAll = false
			for tab in self.TabControl:GetEnumerator () do
				if tab:GetContents () and tab:GetContents ():GetUndoRedoStack ():IsUnsaved () then
					canSaveAll = true
					break
				end
			end
			
			self.Toolbar:GetItemById ("Save All"):SetEnabled (canSaveAll)
		end
	)
end

function self:UnhookTabContents (tab, contents)
	if not contents then return end
	contents:RemoveEventListener ("PathChanged",        tostring (self:GetTable ()))
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