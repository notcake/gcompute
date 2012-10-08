local self = {}

--[[
	Events
		SelectedContentsChanged (Tab oldSelectedTab, Panel oldSelectedContents, Tab selectedTab, Panel selectedContents)
			Fired when the active tab has changed or the active tab's contents have changed.
]]

function self:Init ()
	self:SetTitle ("Editor (WIP, not working)")

	self:SetSize (ScrW () * 0.85, ScrH () * 0.85)
	self:Center ()
	self:SetDeleteOnClose (false)
	self:MakePopup ()
	
	self.Toolbar = GCompute.Editor.Toolbar (self)
	
	self.TabControl = vgui.Create ("GTabControl", self)
	self.TabControl:AddEventListener ("SelectedContentsChanged",
		function (_, oldSelectedTab, oldSelectedContents, selectedTab, selectedContents)
			if selectedContents then selectedContents:RequestFocus () end
			if selectedTab and selectedTab.HasUndoRedoStack then
				self.UndoRedoController:SetUndoRedoStack (selectedContents and selectedContents:GetUndoRedoStack () or nil)
			else
				self.UndoRedoController:SetUndoRedoStack (nil)
			end
			if selectedTab and selectedTab.HasSelection then
				self.ClipboardController:SetControl (selectedContents)
			else
				self.ClipboardController:SetControl (nil)
			end
			
			if oldSelectedTab and oldSelectedTab.ContentType == "CodeEditor" then
				self:UnhookSelectedCodeEditor (oldSelectedTab, oldSelectedContents)
			end
			if selectedTab and selectedTab.ContentType == "CodeEditor" then
				self:HookSelectedCodeEditor (selectedTab, selectedContents)
			end
			
			self:UpdateCaretPositionText ()
			self:UpdateLanguageText ()
			self:UpdateProgressBar ()
			
			self:DispatchEvent ("SelectedContentsChanged", oldSelectedTab, oldSelectedContents, selectedTab, selectedContents)
		end
	)
	self.TabControl:AddEventListener ("TabAdded",
		function (_, tab)
			local contents = tab:GetContents ()
			
			tab:SetContextMenu (self.TabContextMenu)
			
			self:HookTabContents (tab, contents)
			if tab.HasFile and contents then
				self:RegisterTabPath (tab, contents:GetFile (), contents:GetFile () and contents:GetFile ():GetPath () or nil)
			end
			
			self:InvalidateSavedTabs ()
		end
	)
	self.TabControl:AddEventListener ("TabCloseRequested",
		function (_, tab)
			self:CloseTab (tab)
		end
	)
	self.TabControl:AddEventListener ("TabContentsChanged",
		function (_, tab, oldContents, contents)
			if tab.HasFile then
				if oldContents then
					self:UnregisterTabPath (tab, oldContents:GetFile (), oldContents:GetFile () and oldContents:GetFile ():GetPath ())
				end
				if contents then
					self:RegisterTabPath (tab, contents:GetFile (), contents:GetFile () and contents:GetFile ():GetPath () or nil)
				end
			end
			self:UnhookTabContents (tab, oldContents)
			self:HookTabContents (tab, contents)
		end
	)
	self.TabControl:AddEventListener ("TabRemoved",
		function (_, tab)
			local contents = tab:GetContents ()
			self:UnhookTabContents (tab, contents)
			
			if tab.HasFile and contents then
				self:UnregisterTabPath (tab, contents:GetFile (), contents:GetFile () and contents:GetFile ():GetPath () or nil)
			end
			
			self:InvalidateSavedTabs ()
		end
	)
	
	self.TabContextMenu = GCompute.Editor.TabContextMenu (self)
	self.CodeEditorContextMenu = GCompute.Editor.CodeEditorContextMenu (self)
	
	self.StatusBar = vgui.Create ("GStatusBar", self)
	self.LanguagePanel      = self.StatusBar:AddTextPanel ("Unknown language")
	self.ProfilerPanel      = self.StatusBar:AddTextPanel ("0.000 ms, 0 %")
	self.ProgressPanel      = self.StatusBar:AddProgressPanel ()
	self.ProgressPanel:SetFixedWidth (128)
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
	
	self.OutputPane = vgui.Create ("GComputeCodeEditor", self)
	self.OutputPane:SetCompilationEnabled (false)
	self.OutputPane:SetLineNumbersVisible (false)
	self.OutputPane:SetReadOnly (true)
	
	self.SplitContainer = vgui.Create ("GSplitContainer", self)
	self.SplitContainer:SetFixedPanel (2)
	self.SplitContainer:SetOrientation (Gooey.Orientation.Horizontal)
	self.SplitContainer:SetPanel1 (self.TabControl)
	self.SplitContainer:SetPanel2 (self.OutputPane)
	self:PerformLayout ()
	self.SplitContainer:SetSplitterFraction (0.75)
	
	self:SetKeyboardMap (GCompute.Editor.EditorKeyboardMap)
	
	self.NextNewId = 1
	
	self.OpenPaths = {} -- map of paths to tabs
	
	-- Namespace browser
	self.RootNamespaceBrowserTab = nil
	
	self:InvalidateLayout ()
	
	-- Plugin loading
	GCompute.Editor.Plugins:Initialize (self)
	
	-- Tab saving
	self.TabSavingEnabled = true
	self.TabsUnsaved = false
	
	self:SetCanSaveTabs (false)
	self:LoadTabs (
		function ()
			self:SetCanSaveTabs (true)
			if self.TabControl:GetTabCount () == 0 then
				self:CreateEmptyCodeTab ()
			end
		end
	)
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
	if self.SplitContainer then
		self.SplitContainer:SetPos (2, 23 + self.Toolbar:GetTall ())
		self.SplitContainer:SetSize (self:GetWide () - 4, self:GetTall () - 23 - self.Toolbar:GetTall () - 4 - self.StatusBar:GetTall ())
	end
end

--- Returns false if the tab is the last remaining tab and contains the unchanged default text
function self:CanCloseTab (tab)
	if not tab then return false end
	
	local contents = tab:GetContents ()
	if not contents then return true end -- Broken tab
	
	if tab.ContentType ~= "CodeEditor" then return true end -- Can always close non-editor tabs.
	
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
	
	if tab.Savable and contents and contents:IsUnsaved () then
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
	
	tab.ContentType = "CodeEditor"
	tab.HasSelection = true
	tab.HasFile = true
	tab.HasUndoRedoStack = true
	tab.Savable = true
	tab:SetContents (codeEditor)
	
	return tab
end

function self:CreateNamespaceBrowserTab (namespaceDefinition)
	local tab = self.TabControl:AddTab ("Namespace Browser")
	tab:SetIcon ("gui/g_silkicons/application_side_list")
	tab:SetCloseButtonVisible (true)
	
	local namespaceBrowser = vgui.Create ("GComputeNamespaceTreeView")
	namespaceBrowser:SetNamespaceDefinition (namespaceDefinition or GCompute.GlobalNamespace)
	
	tab.ContentType = "NamespaceBrowser"
	tab.HasSelection = false
	tab.HasFile = false
	tab.HasUndoRedoStack = false
	tab.Savable = false
	tab:SetContents (namespaceBrowser)
	
	return tab
end

function self:CreateEmptyCodeTab ()
	local tab = self:CreateCodeTab ("new " .. tostring (self.NextNewId))
	self.NextNewId = self.NextNewId + 1
	
	tab:GetContents ():SetDefaultContents (true)
	tab:GetContents ():SetText (
[[
	local a = systime ();

	function number sum (a, b)
	{
		local result = 0;
		for (local i = a, b)
		{
			result += i;
		}
		return result;
	}
	
	function number factorial (n)
	{
		if (n <= 1) { return 1; }
		return factorial (n - 1) * n;
	}
	
	local n = 5;
	print ("sum is " + sum (1000, 2000));
	print ("factorial(" + n + ") is " + factorial (n));
	print ("execution took " + ((systime () - a) * 1000) + " ms.");
	print (n:GetHashCode ());
]]
	)
	
	return tab
end

function self:GetActiveCodeEditor ()
	local selectedTab = self:GetSelectedTab ()
	if not selectedTab then return nil end
	if selectedTab.ContentType ~= "CodeEditor" then return nil end
	return selectedTab:GetContents ()
end

function self:GetActiveContents ()
	local selectedTab = self:GetSelectedTab ()
	if not selectedTab then return nil end
	return selectedTab:GetContents ()
end

function self:GetActiveUndoRedoStack ()
	return self.UndoRedoController:GetUndoRedoStack ()
end

function self:GetSelectedTab ()
	return self.TabControl:GetSelectedTab ()
end

-- Tab saving
function self:AreTabsUnsaved ()
	return self.TabsUnsaved
end

function self:CanSaveTabs ()
	return self.TabSavingEnabled
end

function self:InvalidateSavedTabs ()
	self.TabsUnsaved = true
end

function self:LoadTabs (callback)
	local tabs = string.Split (file.Read ("gcompute_editor_tabs.txt") or "", "\n")
	local finishedTabs = 0
	local tabCount = 0
	local loopDone = false
	for _, tabData in ipairs (tabs) do
		tabData = string.Split (tabData, ";")
		local contentType = tabData [1]
		if contentType == "CodeEditor" then
			tabCount = tabCount + 1
			self:OpenPath (tabData [2],
				function ()
					finishedTabs = finishedTabs + 1
					if loopDone and finishedTabs == tabCount then
						callback ()
					end
				end
			)
		elseif contentType == "NamespaceBrowser" then
			self:CreateNamespaceBrowserTab ()
			finishedTabs = finishedTabs + 1
			tabCount = tabCount + 1
		end
	end
	loopDone = true
	if finishedTabs == tabCount then
		callback ()
	end
end

function self:SaveTabs ()
	if not self:CanSaveTabs () then return end
	if not self:AreTabsUnsaved () then return end
	self.TabsUnsaved = false
	
	local data = {}
	for tab in self.TabControl:GetEnumerator () do
		if tab:GetContents () then
			local contentType = tab.ContentType
			if contentType == "CodeEditor" then
				local file = tab:GetContents ():GetFile ()
				if file then
					data [#data + 1] = "CodeEditor;" .. file:GetPath ()
				end
			elseif contentType == "NamespaceBrowser" then
				data [#data + 1] = "NamespaceBrowser;"
			end
		end
	end
	file.Write ("gcompute_editor_tabs.txt", table.concat (data, "\n"))
end

function self:SetCanSaveTabs (canSaveTabs)
	self.TabSavingEnabled = canSaveTabs
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
						tab:GetContents ():SetText (data)
						tab:GetContents ():SetFile (file)
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
	
	self:InvalidateSavedTabs ()
end

function self:UnregisterTabPath (tab, file, path)
	if not path then return end
	path = path:lower ()
	
	if not self.OpenPaths [path] then return end
	self.OpenPaths [path].Tabs [tab] = nil
	if not next (self.OpenPaths [path].Tabs) then
		self.OpenPaths [path] = nil
	end
	
	self:InvalidateSavedTabs ()
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
	elseif codeEditor then
		self.LanguagePanel:SetText ("Unknown language")
	else
		self.LanguagePanel:SetText ("")
	end
end

function self:UpdateProgressBar ()
	local codeEditor = self:GetActiveCodeEditor ()
	local compilationUnit = codeEditor and codeEditor:GetCompilationUnit ()
	if compilationUnit then
		if compilationUnit:IsLexing () then
			self.ProgressPanel:SetProgress (compilationUnit:GetLexer ():GetProgress () * 100)
			self.ProgressPanel:CancelFade ()
			self.ProgressPanel:SetAlpha (255)
			self.ProgressPanel:SetVisible (true)
		else
			self.ProgressPanel:FadeOut (false)
		end
	else
		self.ProgressPanel:FadeOut (false)
	end
end

-- Event hooking
function self:HookSelectedSourceFile (sourceFile)
	if not sourceFile then return end
	
	sourceFile:GetCompilationUnit ():AddEventListener ("LanguageChanged", tostring (self:GetTable ()),
		function (_, language)
			self:UpdateLanguageText ()
		end
	)
end

function self:UnhookSelectedSourceFile (sourceFile)
	if not sourceFile then return end
	
	sourceFile:GetCompilationUnit ():RemoveEventListener ("LanguageChanged", tostring (self:GetTable ()))
end

function self:HookSelectedCodeEditor (tab, codeEditor)
	if not codeEditor then return end
	
	codeEditor:AddEventListener ("CaretMoved", tostring (self:GetTable ()),
		function (_, caretLocation)
			self:UpdateCaretPositionText ()
		end
	)
	codeEditor:AddEventListener ("LexerFinished", tostring (self:GetTable ()),
		function (_, lexer)
			self:UpdateProgressBar ()
		end
	)
	codeEditor:AddEventListener ("LexerProgress", tostring (self:GetTable ()),
		function (_, lexer, bytesProcessed, totalBytes)
			self:UpdateProgressBar ()
		end
	)
	codeEditor:AddEventListener ("LexerStarted", tostring (self:GetTable ()),
		function (_, lexer)
			self:UpdateProgressBar ()
		end
	)
	codeEditor:AddEventListener ("SourceFileChanged", tostring (self:GetTable ()),
		function (_, oldSourceFile, sourceFile)
			self:UnhookSelectedSourceFile (oldSourceFile)
			self:HookSelectedSourceFile (sourceFile)
			self:UpdateLanguageText ()
		end
	)
	
	self:HookSelectedSourceFile (codeEditor:GetSourceFile ())
end

function self:UnhookSelectedCodeEditor (tab, codeEditor)
	if not codeEditor then return end
	codeEditor:RemoveEventListener ("CaretMoved",        tostring (self:GetTable ()))
	codeEditor:RemoveEventListener ("LexerFinished",     tostring (self:GetTable ()))
	codeEditor:RemoveEventListener ("LexerStarted",      tostring (self:GetTable ()))
	codeEditor:RemoveEventListener ("SourceFileChanged", tostring (self:GetTable ()))
	self:UnhookSelectedSourceFile (codeEditor:GetSourceFile ())
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
	if tab.HasUndoRedoStack then
		contents:GetUndoRedoStack ():AddEventListener ("CanSaveChanged", tostring (self:GetTable ()),
			function (_, canSave)
				tab:SetIcon (contents:GetUndoRedoStack ():IsUnsaved () and "gui/g_silkicons/page_red" or "gui/g_silkicons/page")
				
				local canSaveAll = false
				for tab in self.TabControl:GetEnumerator () do
					if tab.HasUndoRedoStack and tab:GetContents () and tab:GetContents ():GetUndoRedoStack ():IsUnsaved () then
						canSaveAll = true
						break
					end
				end
				
				self.Toolbar:GetItemById ("Save All"):SetEnabled (canSaveAll)
			end
		)
	end
end

function self:UnhookTabContents (tab, contents)
	if not contents then return end
	contents:RemoveEventListener ("PathChanged", tostring (self:GetTable ()))
	if tab.HasUndoRedoStack then
		contents:GetUndoRedoStack ():RemoveEventListener ("CanSaveChanged", tostring (self:GetTable ()))
	end
end

-- Event handlers
function self:OnRemoved ()
	self:SetCanSaveTabs (false)
	self.TabControl:Clear ()
	
	GCompute.Editor.Plugins:Uninitialize ()
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
	
	-- Clamp position within screen bounds
	local x, y = self:GetPos ()
	local newX = math.max (0, x)
	local newY = math.max (0, y)
	if newX ~= x or newY ~= y then
		self:SetPos (newX, newY)
	end
	
	-- Tab saving
	if self:AreTabsUnsaved () and self:CanSaveTabs () then
		self:SaveTabs ()
	end
	
	-- Profiler
	local tabContents = self.TabControl:GetSelectedContents ()
	local lastRenderTime = tabContents and tabContents.LastRenderTime or 0
	self.ProfilerPanel:SetText (string.format ("%.3f ms, %.2f %%", lastRenderTime * 1000, lastRenderTime / FrameTime () * 100))
end

vgui.Register ("GComputeEditorFrame", self, "GFrame")