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
			
			self:InvalidateSavedTabs ()
			
			if selectedTab then
				self.ClipboardController:SetClipboardTarget (selectedTab.View:GetClipboardTarget ())
				self.SaveController:SetSavable (selectedTab.View:GetSavable ())
				self.UndoRedoController:SetUndoRedoStack (selectedTab.View:GetUndoRedoStack ())
			end
			
			if oldSelectedTab and oldSelectedTab.View:GetType () == "Code" then
				self:UnhookSelectedCodeEditor (oldSelectedTab, oldSelectedTab.View:GetEditor ())
			end
			if selectedTab and selectedTab.View:GetType () == "Code" then
				selectedTab.View:GetEditor ():SetContextMenu (self.CodeEditorContextMenu)
				self:HookSelectedCodeEditor (selectedTab, selectedTab.View:GetEditor ())
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
			if tab.View and tab.View:GetDocument () then
				self:RegisterTabDocument (tab, tab.View:GetDocument ())
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
			if tab.View:GetDocument () then
				self:RegisterTabDocument (tab, tab.View:GetDocument ())
			end
			self:UnhookTabContents (tab, oldContents)
			self:HookTabContents (tab, contents)
		end
	)
	self.TabControl:AddEventListener ("TabRemoved",
		function (_, tab)
			local contents = tab:GetContents ()
			self:UnhookTabContents (tab, contents)
			
			if tab.View:GetDocument () then
				self:UnregisterTabDocument (tab, tab.View:GetDocument ())
			end
			
			self:InvalidateSavedTabs ()
		end
	)
	
	self.TabContextMenu = GCompute.Editor.TabContextMenu (self)
	self.CodeEditorContextMenu = GCompute.Editor.CodeEditorContextMenu (self)
	
	self.StatusBar = vgui.Create ("GStatusBar", self)
	self.LanguagePanel      = self.StatusBar:AddComboBoxPanel ("Unknown language")
	self.LanguagePanel:AddEventListener ("MenuOpening",
		function (_, menu)
			menu:Clear ()
			local languages = {}
			for language in GCompute.Languages.GetEnumerator () do
				languages [#languages + 1] = language
			end
			table.sort (languages,
				function (a, b)
					return a:GetName ():lower () < b:GetName ():lower ()
				end
			)
			
			local codeEditor = self:GetActiveCodeEditor ()
			local syntaxHighlighter = codeEditor and codeEditor:GetSyntaxHighlighter ()
			local currentLanguage = syntaxHighlighter and syntaxHighlighter:GetLanguage ()
			for _, language in ipairs (languages) do
				local option = menu:AddOption (language:GetName ())
				option:AddEventListener ("Click",
					function ()
						local codeEditor = self:GetActiveCodeEditor ()
						local syntaxHighlighter = codeEditor and codeEditor:GetSyntaxHighlighter ()
						if not syntaxHighlighter then return end
						syntaxHighlighter:SetLanguage (language)
						GCompute.LanguageDetector:SetDefaultLanguage (language)
					end
				)
				if language == currentLanguage then
					option:SetIcon ("icon16/bullet_black.png")
				end
			end
		end
	)
	
	self.ProfilerPanel      = self.StatusBar:AddTextPanel ("0.000 ms, 0 %")
	self.ProgressPanel      = self.StatusBar:AddProgressPanel ()
	self.ProgressPanel:SetFixedWidth (128)
	self.CaretPositionPanel = self.StatusBar:AddTextPanel ("Line 1, col 1")
	self.CaretPositionPanel:SetFixedWidth (96)
	
	self.ClipboardController = Gooey.ClipboardController ()
	self.ClipboardController:AddCopyButton  (self.Toolbar:GetItemById ("Copy"))
	self.ClipboardController:AddCopyButton  (self.CodeEditorContextMenu:GetItemById ("Copy"))
	self.ClipboardController:AddCutButton   (self.Toolbar:GetItemById ("Cut"))
	self.ClipboardController:AddCutButton   (self.CodeEditorContextMenu:GetItemById ("Cut"))
	self.ClipboardController:AddPasteButton (self.Toolbar:GetItemById ("Paste"))
	self.ClipboardController:AddPasteButton (self.CodeEditorContextMenu:GetItemById ("Paste"))
	
	self.SaveController = Gooey.SaveController ()
	self.SaveController:AddSaveButton       (self.Toolbar:GetItemById ("Save"))
	
	self.UndoRedoController = Gooey.UndoRedoController ()
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
	
	self.DocumentManager = GCompute.Editor.DocumentManager ()
	
	-- Namespace browser
	self.RootNamespaceBrowserTab = nil
	
	self:InvalidateLayout ()
	
	-- Plugin loading
	GCompute.Editor.Plugins:Initialize (self)
	
	-- Tab saving
	self.LastTabSaveTime = SysTime ()
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
	if not tab      then return false end
	if not tab.View then return true  end -- Broken tab
	
	if tab.View:GetType () ~= "Code" then return true end -- Can always close non-editor tabs.
	
	if self.TabControl:GetTabCount () == 1 and
	   not tab.View:GetSavable ():HasPath () and
	   not tab.View:GetSavable ():IsUnsaved () then
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
	
	if tab.View:GetSavable () and tab.View:GetSavable ():IsUnsaved () then
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

function self:CreateTab (className)
	local container = vgui.Create ("GComputeViewContainer")
	container:SetDocumentManager (self.DocumentManager)
	
	local view = GCompute.Editor.ViewTypes:Create (className, container)
	if not view then return nil end
	
	local tab = self.TabControl:AddTab (className)
	tab.View = view
	tab:SetCloseButtonVisible (true)
	tab:SetIcon (view:GetIcon ())
	tab:SetContents (container)
	container:SetTab (tab)
	
	return view
end

function self:CreateCodeTab (title)
	local view = self:CreateTab ("Code")
	view:SetTitle (title)
	return view
end

function self:CreateNamespaceBrowserTab (namespaceDefinition)
	local view = self:CreateTab ("NamespaceBrowser")
	view:SetNamespaceDefinition (namespaceDefinition or GCompute.GlobalNamespace)
	return view
end

function self:CreateEmptyCodeTab ()
	local view = self:CreateCodeTab ("new " .. tostring (self.NextNewId))
	self.NextNewId = self.NextNewId + 1
	
	view:SetCode ("")
	
	return view
end

function self:GetActiveClipboardTarget ()
	return self.ClipboardController:GetClipboardTarget ()
end

function self:GetActiveCodeEditor ()
	local selectedTab = self:GetSelectedTab ()
	if not selectedTab then return nil end
	if selectedTab.View:GetType () ~= "Code" then return nil end
	return selectedTab.View:GetContainer ():GetContents ()
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
	local inBuffer = GLib.StringInBuffer (file.Read ("data/gcompute_editor_tabs.txt", "GAME") or "")
	inBuffer:String () -- Discard comment
	self.DocumentManager:LoadSession (GLib.StringInBuffer (inBuffer:String ()))
	inBuffer:Char ()   -- Discard newline
	inBuffer:String () -- Discard comment
	
	local activeView = nil
	local viewType = inBuffer:String ()
	while viewType ~= "" do
		local active = inBuffer:Boolean ()
		local subInBuffer = GLib.StringInBuffer (inBuffer:String ())
		local view = self:CreateTab (viewType)
		if view then
			view:LoadSession (subInBuffer)
		end
		if active then
			activeView = view
		end
		
		inBuffer:Char () -- Discard newline
		viewType = inBuffer:String ()
	end
	if activeView then
		activeView:Select ()
	end
	
	callback ()
end

function self:SaveTabs ()
	if not self:CanSaveTabs () then return end
	if not self:AreTabsUnsaved () then return end
	self.LastTabSaveTime = SysTime ()
	self.TabsUnsaved = false
	
	local outBuffer = GLib.StringOutBuffer ()
	outBuffer:String ("\n=== Documents ===\n")
	
	local subOutBuffer = GLib.StringOutBuffer ()
	self.DocumentManager:SaveSession (subOutBuffer)
	outBuffer:String (subOutBuffer:GetString ())
	outBuffer:Char ("\n")
	outBuffer:String ("\n=== Workspace ===\n")
	
	for tab in self.TabControl:GetEnumerator () do
		local viewType = tab.View:GetType ()
		outBuffer:String (viewType)
		outBuffer:Boolean (tab:IsSelected ())
		subOutBuffer:Clear ()
		tab.View:SaveSession (subOutBuffer)
		outBuffer:String (subOutBuffer:GetString ())
		outBuffer:Char ("\n")
	end
	outBuffer:String ("")
	file.Write ("gcompute_editor_tabs.txt", outBuffer:GetString ())
end

function self:SetCanSaveTabs (canSaveTabs)
	self.TabSavingEnabled = canSaveTabs
end

--- Opens a new tab for the IFile. Use OpenPath instead if you have a path only.
-- @param file The IFile to be opened.
-- @param callback A callback function (success, IFile file, IView view)
function self:OpenFile (file, callback)
	if not file then return end
	
	local document = self.DocumentManager:GetDocumentByPath (file:GetPath ())
	if document then
		callback (true, file, document:GetView (1))
		return
	end
	
	file:Open (GAuth.GetLocalId (), VFS.OpenFlags.Read,
		function (returnCode, fileStream)
			if returnCode == VFS.ReturnCode.Success then
				fileStream:Read (fileStream:GetLength (),
					function (returnCode, data)
						if returnCode == VFS.ReturnCode.Progress then return end
						
						local file = fileStream:GetFile ()
						local view = self:CreateCodeTab ()
						view:SetTitle (file:GetDisplayName ())
						view:SetCode (data)
						view:GetSavable ():SetFile (file)
						fileStream:Close ()
						
						callback (true, file, view)
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
-- @param callback A callback function (success, IFile file, IView view)
function self:OpenPath (path, callback)
	callback = callback or GCompute.NullCallback
	
	local document = self.DocumentManager:GetDocumentByPath (file:GetPath ())
	if document then
		callback (true, document:GetFile (), document:GetView (1))
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
	if not tab                    then callback (true) return end
	if not tab.View               then callback (true) return end
	if not tab.View:GetSavable () then callback (true) return end
	
	VFS.OpenSaveFileDialog ("GCompute.Editor",
		function (path, file)
			if not path then callback (false) return end
			if not self or not self:IsValid () then callback (false) return end
			
			tab.View:GetSavable ():SetPath (path)
			self:SaveTab (tab, path, callback)
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
	
	if not tab                    then callback (true) return end
	if not tab.View               then callback (true) return end
	if not tab.View:GetSavable () then callback (true) return end
	
	-- Determine save path
	local path = pathOrCallback
	if not path and tab.View:GetSavable ():HasPath () then
		path = tab.View:GetSavable ():GetPath ()
		tab.View:GetSavable ():SetPath (path)
	end
	
	-- If the tab has no path, invoke the save as dialog.
	if not path then
		self:SaveAsTab (tab, callback)
		return
	end
	
	tab.View:GetSavable ():Save (callback)
end

-- Internal, do not call
function self:RegisterTabDocument (tab, document)
	if not document then return end
	
	self.DocumentManager:AddDocument (document)
	self:InvalidateSavedTabs ()
end

function self:UnregisterTabDocument (tab, document)
	if not document then return end
	
	self.DocumentManager:RemoveDocument (document)
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
	local syntaxHighlighter = codeEditor and codeEditor:GetSyntaxHighlighter ()
	local language = syntaxHighlighter and syntaxHighlighter:GetLanguage ()
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
	local syntaxHighlighter = codeEditor and codeEditor:GetSyntaxHighlighter ()
	local compilationUnit = syntaxHighlighter and syntaxHighlighter:GetCompilationUnit ()
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
function self:HookSelectedCodeEditor (tab, codeEditor)
	if not codeEditor then return end
	
	codeEditor:AddEventListener ("CaretMoved", tostring (self:GetTable ()),
		function (_, caretLocation)
			self:UpdateCaretPositionText ()
		end
	)
	
	codeEditor:AddEventListener ("SyntaxHighligherChanged", tostring (self:GetTable ()),
		function (_, oldSyntaxHighlighter, syntaxHighlighter)
			self:UnhookSyntaxHighlighter (oldSyntaxHighlighter)
			self:HookSyntaxHighlighter (syntaxHighlighter)
		end
	)
	
	self:HookSyntaxHighlighter (codeEditor:GetSyntaxHighlighter ())
end

function self:UnhookSelectedCodeEditor (tab, codeEditor)
	if not codeEditor then return end
	codeEditor:RemoveEventListener ("CaretMoved",               tostring (self:GetTable ()))
	codeEditor:RemoveEventListener ("SyntaxHighlighterChanged", tostring (self:GetTable ()))
	self:UnhookSyntaxHighlighter (codeEditor:GetSyntaxHighlighter ())
end

function self:HookSyntaxHighlighter (syntaxHighlighter)
	if not syntaxHighlighter then return end
	
	syntaxHighlighter:AddEventListener ("LanguageChanged", tostring (self:GetTable ()),
		function (_, language)
			self:UpdateLanguageText ()
		end
	)
	syntaxHighlighter:AddEventListener ("LexerFinished", tostring (self:GetTable ()),
		function (_, lexer)
			self:UpdateProgressBar ()
		end
	)
	syntaxHighlighter:AddEventListener ("LexerProgress", tostring (self:GetTable ()),
		function (_, lexer, bytesProcessed, totalBytes)
			self:UpdateProgressBar ()
		end
	)
	syntaxHighlighter:AddEventListener ("LexerStarted", tostring (self:GetTable ()),
		function (_, lexer)
			self:UpdateProgressBar ()
		end
	)
end

function self:UnhookSyntaxHighlighter (syntaxHighlighter)
	if not syntaxHighlighter then return end
	syntaxHighlighter:RemoveEventListener ("LanguageChanged",   tostring (self:GetTable ()))
	syntaxHighlighter:RemoveEventListener ("LexerFinished",     tostring (self:GetTable ()))
	syntaxHighlighter:RemoveEventListener ("LexerStarted",      tostring (self:GetTable ()))
	syntaxHighlighter:RemoveEventListener ("SourceFileChanged", tostring (self:GetTable ()))
end

function self:HookTabContents (tab, contents)
	if not tab.View then return end
	tab.View:AddEventListener ("DocumentChanged", tostring (self:GetTable ()),
		function (_, oldDocument, newDocument)
			self:UnregisterTabDocument (tab, oldDocument)
			self:RegisterTabDocument (tab, document)
		end
	)
	tab.View:AddEventListener ("IconChanged", tostring (self:GetTable ()),
		function (_, icon)
			tab:SetIcon (icon)
		end
	)
	tab.View:AddEventListener ("TitleChanged", tostring (self:GetTable ()),
		function (_, title)
			tab:SetText (title)
		end
	)
	tab.View:AddEventListener ("ToolTipTextChanged", tostring (self:GetTable ()),
		function (_, toolTipText)
			tab:SetToolTipText (toolTipText)
		end
	)
	tab:SetIcon (tab.View:GetIcon ())
	tab:SetText (tab.View:GetTitle ())
	tab:SetToolTipText (tab.View:GetToolTipText ())
	
	self:RegisterTabDocument (tab.View:GetDocument ())
	
	if tab.View:GetSavable () then
		local savable = tab.View:GetSavable ()
		savable:AddEventListener ("CanSaveChanged", tostring (self:GetTable ()),
			function (_, canSave)
				local canSaveAll = false
				for tab in self.TabControl:GetEnumerator () do
					if tab.View:GetSavable () and tab.View:GetSavable ():IsUnsaved () then
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
	if not tab.View then return end
	tab.View:RemoveEventListener ("DocumentChanged",    tostring (self:GetTable ()))
	tab.View:RemoveEventListener ("IconChanged",        tostring (self:GetTable ()))
	tab.View:RemoveEventListener ("TitleChanged",       tostring (self:GetTable ()))
	tab.View:RemoveEventListener ("ToolTipTextChanged", tostring (self:GetTable ()))
	if tab.View:GetSavable () then
		tab.View:GetSavable ():RemoveEventListener ("CanSaveChanged", tostring (self:GetTable ()))
		tab.View:GetSavable ():RemoveEventListener ("PathChanged",    tostring (self:GetTable ()))
		tab.View:GetSavable ():RemoveEventListener ("UnsavedChanged", tostring (self:GetTable ()))
	end
end

-- Event handlers
function self:OnRemoved ()
	self:InvalidateSavedTabs ()
	self:SaveTabs ()
	self:SetCanSaveTabs (false)
	self.TabControl:Clear ()
	
	self.ClipboardController:dtor ()
	self.CodeEditorContextMenu:Remove ()
	self.TabContextMenu:Remove ()
	
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
	local w, h = self:GetSize ()
	local newX = math.max (0, x)
	local newY = math.max (0, y)
	
	if w <= ScrW () and x + w > ScrW () then
		newX = ScrW () - w
	end
	if h <= ScrH () and y + h > ScrH () then
		newY = ScrH () - h
	end
	
	if newX ~= x or newY ~= y then
		self:SetPos (newX, newY)
	end
	
	-- Tab saving
	if self:AreTabsUnsaved () and self:CanSaveTabs () and SysTime () - self.LastTabSaveTime > 5 then
		self:SaveTabs ()
	end
	
	-- Profiler
	local tabContents = self.TabControl:GetSelectedContents ()
	tabContents = tabContents and tabContents:GetContents () or nil
	local lastRenderTime = tabContents and tabContents.LastRenderTime or 0
	self.ProfilerPanel:SetText (string.format ("%.3f ms, %.2f %%", lastRenderTime * 1000, lastRenderTime / FrameTime () * 100))
end

vgui.Register ("GComputeEditorFrame", self, "GFrame")