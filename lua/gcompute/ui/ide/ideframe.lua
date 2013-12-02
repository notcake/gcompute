local self = {}

--[[
	Events
		ActiveViewChanged (View oldView, View view)
			Fired when the active view has changed.
]]

function self:Init ()
	xpcall (function ()
	self:SetTitle ("IDE")

	self:SetSize (ScrW () * 0.85, ScrH () * 0.85)
	self:Center ()
	self:SetDeleteOnClose (false)
	self:MakePopup ()
	
	self.IDE = nil
	
	self:SetActionMap (GCompute.IDE.ActionMap)
	
	self.MenuStrip = GCompute.IDE.MenuStrip (self)
	self.Toolbar = GCompute.IDE.Toolbar (self)
	
	self.LoadingLayout = false
	self.DockContainer = vgui.Create ("GComputeDockContainer", self)
	self.DockContainer:SetContainerType (GCompute.DockContainer.DockContainerType.TabControl)
	self.DockContainer:AddEventListener ("ActiveViewChanged",
		function (_, oldView, view)
			if view then view:Select () end
			
			self:InvalidateSavedWorkspace ()
			
			if view then
				self.ClipboardController:SetClipboardTarget (view:GetClipboardTarget ())
				self.SaveController:SetSavable (view:GetSavable ())
				self.UndoRedoController:SetUndoRedoStack (view:GetUndoRedoStack ())
			end
			
			if oldView and oldView:GetType () == "Code" then
				self:UnhookSelectedCodeEditor (oldView:GetEditor ())
			end
			if view and view:GetType () == "Code" then
				view:GetEditor ():SetContextMenu (self.CodeEditorContextMenu)
				self:HookSelectedCodeEditor (view:GetEditor ())
			end
			
			self:UpdateCaretPositionText ()
			self:UpdateLanguageText ()
			self:UpdateProgressBar ()
			
			self:GetActionMap ():GetAction ("Run Code"):SetEnabled (self:GetActiveCodeEditor () ~= nil)
			self.Toolbar:GetItemById ("Run Code"):SetEnabled (self:GetActiveCodeEditor () ~= nil)
			
			if view then
				local actionMap, control = view:GetActionMap ()
				self:GetActionMap ():SetChainedActionMap (actionMap, control or view)
			else
				self:GetActionMap ():SetChainedActionMap (nil, nil)
			end
			
			self:DispatchEvent ("ActiveViewChanged", oldView, view)
		end
	)
	self.DockContainer:AddEventListener ("ContainerSplit",
		function (_, splitDockContainer, container, emptyContainer)
			if container:GetContainerType () == GCompute.DockContainer.DockContainerType.None then
				container:SetContainerType (GCompute.DockContainer.DockContainerType.TabControl)
			end
			emptyContainer:SetContainerType (GCompute.DockContainer.DockContainerType.TabControl)
		end
	)
	self.DockContainer:AddEventListener ("ViewCloseRequested",
		function (_, view)
			self:GetIDE ():CloseView (view)
		end
	)
	self.DockContainer:AddEventListener ("ViewMoved",
		function (_, view)
			if view:GetContainer ():GetTab () then
				view:GetContainer ():GetTab ():SetContextMenu (self.TabContextMenu)
			end
		end
	)
	self.DockContainer:AddEventListener ("ViewRemoved",
		function (_, container, view, viewRemovalReason)
			if self.LoadingLayout then return end
			
			if viewRemovalReason == GCompute.ViewRemovalReason.Removal then
				self:GetViewManager ():RemoveView (view)
				
				-- Avoid having no views open
				if self:GetDocumentManager ():GetDocumentCount () == 0 then
					self:CreateEmptyCodeView ():Select ()
				end
			end
			
			-- Kill empty containers
			if viewRemovalReason == GCompute.ViewRemovalReason.Removal or
			   viewRemovalReason == GCompute.ViewRemovalReason.Rearrangement then
				if container:GetLocalViewCount () == 0 and not container:IsRootDockContainer () then
					if container:IsPanel1 () then
						container:GetParentDockContainer ():Merge (container:GetParentDockContainer ():GetPanel2 ())
					else
						container:GetParentDockContainer ():Merge (container:GetParentDockContainer ():GetPanel1 ())
					end
				end
			end
		end
	)
	
	self.TabContextMenu = GCompute.IDE.TabContextMenu (self)
	self.CodeEditorContextMenu = GCompute.CodeEditor.CodeEditorContextMenu (self)
	
	self.StatusBar = vgui.Create ("GStatusBar", self)
	self.LanguagePanel = self.StatusBar:AddComboBoxPanel ("Unknown language")
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
			local currentLanguage = codeEditor and codeEditor:GetLanguage ()
			for _, language in ipairs (languages) do
				local menuItem = menu:AddItem (language:GetName ())
				menuItem:AddEventListener ("Click",
					function ()
						local codeEditor = self:GetActiveCodeEditor ()
						if not codeEditor then return end
						codeEditor:SetLanguage (language)
						GCompute.LanguageDetector:SetDefaultLanguage (language)
					end
				)
				if language == currentLanguage then
					menuItem:SetIcon ("icon16/bullet_black.png")
				end
			end
		end
	)
	
	self.ProgressPanel = self.StatusBar:AddProgressPanel ()
	self.ProgressPanel:SetFixedWidth (128)
	self.MemoryProfilerPanel = self.StatusBar:AddTextPanel ("0.00 MiB")
	self.MemoryProfilerPanel:SetFixedWidth (128)
	self.ProfilerPanel = self.StatusBar:AddTextPanel ("0.000 ms, 0 %")
	self.ProfilerPanel:SetFixedWidth (128)
	self.CaretPositionPanel = self.StatusBar:AddTextPanel ("Line 1, col 1")
	self.CaretPositionPanel:SetFixedWidth (96)
	
	self.ClipboardController = Gooey.ClipboardController ()
	self.ClipboardController:AddCopyAction  (self:GetActionMap ():GetAction ("Copy"))
	self.ClipboardController:AddCopyButton  (self.Toolbar:GetItemById ("Copy"))
	self.ClipboardController:AddCopyButton  (self.CodeEditorContextMenu:GetItemById ("Copy"))
	self.ClipboardController:AddCutAction   (self:GetActionMap ():GetAction ("Cut"))
	self.ClipboardController:AddCutButton   (self.Toolbar:GetItemById ("Cut"))
	self.ClipboardController:AddCutButton   (self.CodeEditorContextMenu:GetItemById ("Cut"))
	self.ClipboardController:AddPasteAction (self:GetActionMap ():GetAction ("Paste"))
	self.ClipboardController:AddPasteButton (self.Toolbar:GetItemById ("Paste"))
	self.ClipboardController:AddPasteButton (self.CodeEditorContextMenu:GetItemById ("Paste"))
	
	self.SaveController = Gooey.SaveController ()
	self.SaveController:AddSaveAction       (self:GetActionMap ():GetAction ("Save"))
	self.SaveController:AddSaveButton       (self.MenuStrip:GetItemById ("File"):GetItemById ("Save"))
	self.SaveController:AddSaveButton       (self.Toolbar:GetItemById ("Save"))
	
	self.UndoRedoController = Gooey.UndoRedoController ()
	self.UndoRedoController:AddUndoButton   (self.MenuStrip:GetItemById ("Edit"):GetItemById ("Undo"))
	self.UndoRedoController:AddUndoButton   (self.Toolbar:GetItemById ("Undo"))
	self.UndoRedoController:AddUndoButton   (self.CodeEditorContextMenu:GetItemById ("Undo"))
	self.UndoRedoController:AddRedoButton   (self.MenuStrip:GetItemById ("Edit"):GetItemById ("Redo"))
	self.UndoRedoController:AddRedoButton   (self.Toolbar:GetItemById ("Redo"))
	self.UndoRedoController:AddRedoButton   (self.CodeEditorContextMenu:GetItemById ("Redo"))
	
	self:SetKeyboardMap (GCompute.IDE.KeyboardMap)
	
	self.NextNewId = 1
	
	-- Namespace browser
	self.RootNamespaceBrowserTab = nil
	
	self:InvalidateLayout ()
	
	-- Plugin loading
	GCompute.IDE.Plugins:Initialize (self)
	
	-- Workspace saving
	self.LastWorkspaceSaveTime = SysTime ()
	self.WorkspaceSavingEnabled = true
	self.WorkspaceUnsaved = false
	
	self:UpdateLanguageText ()
	
	end, GLib.Error)
end

function self:PerformLayout ()
	DFrame.PerformLayout (self)
	
	local y = 21
	if self.MenuStrip then
		self.MenuStrip:SetPos (2, y)
		self.MenuStrip:SetWide (self:GetWide () - 4)
		y = y + self.MenuStrip:GetTall ()
	end
	if self.Toolbar then
		self.Toolbar:SetPos (2, y)
		self.Toolbar:SetSize (self:GetWide () - 4, self.Toolbar:GetTall ())
		y = y + self.Toolbar:GetTall () + 2
	end
	if self.StatusBar then
		self.StatusBar:PerformLayout ()
	end
	if self.DockContainer then
		self.DockContainer:SetPos (2, y)
		self.DockContainer:SetSize (self:GetWide () - 4, self:GetTall () - 4 - self.StatusBar:GetTall () - y)
	end
end

-- IDE
function self:GetDocumentManager ()
	if not self.IDE then return nil end
	return self.IDE:GetDocumentManager ()
end

function self:GetDocumentTypes ()
	if not self.IDE then return nil end
	return self.IDE:GetDocumentTypes ()
end

function self:GetIDE ()
	return self.IDE
end

function self:GetSerializerRegistry ()
	if not self.IDE then return nil end
	return self.IDE:GetSerializerRegistry ()
end

function self:GetViewManager ()
	if not self.IDE then return nil end
	return self.IDE:GetViewManager ()
end

function self:GetViewTypes ()
	if not self.IDE then return nil end
	return self.IDE:GetViewTypes ()
end

function self:SetIDE (ide)
	self:UnhookDocumentManager (self:GetDocumentManager ())
	self:UnhookViewManager (self:GetViewManager ())
	
	self.IDE = ide
	
	self:HookDocumentManager (self:GetDocumentManager ())
	self:HookViewManager (self:GetViewManager ())
	
	if not self.IDE then return end
	
	for viewType in self:GetViewTypes ():GetEnumerator () do
		if viewType:ShouldAutoCreate () then
			local view = self:GetViewManager ():CreateView (viewType:GetName (), viewType:GetName ())
			if view then
				self:GetActionMap ():RegisterToggle (viewType:GetName (), Gooey.VisibilityController (view))
					:SetIcon (view:GetIcon ())
				view:SetCanClose (false)
				self [viewType:GetName () .. "View"] = view
			end
		end
	end
end

-- Views
function self:CreateView (viewType, viewId)
	return self:GetViewManager ():CreateView (viewType, viewId)
end

function self:CreateCodeView (title)
	local view = self:CreateView ("Code")
	view:SetTitle (title)
	
	self.DockContainer:GetLargestContainer ():AddView (view)
	return view
end

function self:CreateNamespaceBrowserView (namespaceDefinition)
	local view = self:CreateView ("NamespaceBrowser")
	view:SetNamespaceDefinition (namespaceDefinition or GCompute.GlobalNamespace)
	
	local activeView = self:GetActiveView ()
	local dockContainer = activeView and activeView:GetContainer ():GetDockContainer () or self.DockContainer:GetLargestContainer ()
	dockContainer:AddView (view)
	return view
end

function self:CreateEmptyCodeView ()
	local view = self:CreateCodeView ("new " .. tostring (self.NextNewId))
	self.NextNewId = self.NextNewId + 1
	
	view:SetCode ("")
	
	return view
end

function self:GetActiveClipboardTarget ()
	return self.ClipboardController:GetClipboardTarget ()
end

function self:GetActiveCodeEditor ()
	local view = self:GetActiveView ()
	if not view then return nil end
	if view:GetType () ~= "Code" then return nil end
	return view:GetEditor ()
end

function self:GetActiveUndoRedoStack ()
	return self.UndoRedoController:GetUndoRedoStack ()
end

function self:GetActiveView ()
	return self.DockContainer:GetActiveView ()
end

-- Tab saving
function self:IsWorkspaceUnsaved ()
	return self.WorkspaceUnsaved
end

function self:CanSaveWorkspace ()
	return self.WorkspaceSavingEnabled
end

function self:InvalidateSavedWorkspace ()
	self.WorkspaceUnsaved = true
end

function self:LoadWorkspace ()
	self:SetCanSaveWorkspace (false)
	
	-- Deserialize
	local inBuffer = GLib.StringInBuffer (file.Read ("data/gcompute_ide_tabs.txt", "GAME") or "")
	inBuffer:String () -- Discard comment
	self:GetDocumentManager ():LoadSession (GLib.StringInBuffer (inBuffer:LongString ()), self:GetSerializerRegistry ())
	inBuffer:Char ()   -- Discard newline
	inBuffer:String () -- Discard comment
	
	self:GetViewManager ():LoadSession (inBuffer)
	
	inBuffer:String () -- Discard comment
	
	-- Check for orphaned documents
	for document in self:GetDocumentManager ():GetEnumerator () do
		if document:GetViewCount () == 0 then
			local view = self:CreateView (self:GetDocumentTypes ():GetType (document:GetType ()):GetViewType ())
			view:SetDocument (document)
		end
	end
	
	self.LoadingLayout = true
	self.DockContainer:LoadSession (GLib.StringInBuffer (inBuffer:String ()), self:GetViewManager ())
	self.LoadingLayout = false
	
	-- Ensure all views have a location
	for view in self:GetViewManager ():GetEnumerator () do
		if not view:GetContainer ():GetDockContainer () then
			if view:GetDocument () then
				self.DockContainer:GetLargestContainer ():AddView (view)
			else
				local viewType = self:GetViewTypes ():GetType (view:GetType ())
				local defaultLocation = viewType:GetDefaultLocation ()
				local defaultLocationParts = defaultLocation:Split ("/")
				
				local dockContainer = self.DockContainer
				for _, locationPart in ipairs (defaultLocationParts) do
					dockContainer = dockContainer:GetCreateSplit (GCompute.DockContainer.DockingSide [locationPart])
				end
				dockContainer:AddView (view)
			end
		end
	end
	
	self:SetCanSaveWorkspace (true)
	
	-- Ensure that at least one view is present
	if self:GetDocumentManager ():GetDocumentCount () == 0 then
		self:CreateEmptyCodeView ()
	end
	
	GLib.CallDelayed (
		function ()
			if not self or not self:IsValid () then return end
			if not self.DockContainer or not self.DockContainer:IsValid () then return end
			if not self.DockContainer:GetLargestView () then return end
			
			self.DockContainer:GetLargestView ():Select ()
		end
	)
end

function self:SaveWorkspace ()
	if not self:CanSaveWorkspace () then return end
	if not self:IsWorkspaceUnsaved () then return end
	self.LastWorkspaceSaveTime = SysTime ()
	self.WorkspaceUnsaved = false
	
	local outBuffer = GLib.StringOutBuffer ()
	outBuffer:String ("\n=== Documents ===\n")
	
	local subOutBuffer = GLib.StringOutBuffer ()
	self:GetDocumentManager ():SaveSession (subOutBuffer, self:GetSerializerRegistry ())
	outBuffer:LongString (subOutBuffer:GetString ())
	outBuffer:Char ("\n")
	outBuffer:String ("\n=== Views ===\n")
	
	self:GetViewManager ():SaveSession (outBuffer)
	
	outBuffer:String ("\n=== Workspace ===\n")
	subOutBuffer:Clear ()
	self.DockContainer:SaveSession (subOutBuffer)
	outBuffer:String (subOutBuffer:GetString ())
	file.Write ("gcompute_ide_tabs.txt", outBuffer:GetString ())
end

function self:SetCanSaveWorkspace (canSaveWorkspace)
	self.WorkspaceSavingEnabled = canSaveWorkspace
end

-- Internal, do not call
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
	local language = codeEditor and codeEditor:GetLanguage ()
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
	local progress = syntaxHighlighter and syntaxHighlighter:GetProgress ()
	if progress then
		self.ProgressPanel:SetProgress (progress * 100)
		
		if progress < 1 then
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
function self:HookDocumentManager (documentManager)
	if not documentManager then return end
	
	documentManager:AddEventListener ("DocumentAdded", self:GetHashCode (),
		function (_, document)
			self:HookDocument (document)
			self:InvalidateSavedWorkspace ()
		end
	)
	
	documentManager:AddEventListener ("DocumentRemoved", self:GetHashCode (),
		function (_, document)
			self:UnhookDocument (document)
			self:InvalidateSavedWorkspace ()
		end
	)
end

function self:UnhookDocumentManager (documentManager)
	if not documentManager then return end
	
	documentManager:RemoveEventListener ("DocumentAdded",   self:GetHashCode ())
	documentManager:RemoveEventListener ("DocumentRemoved", self:GetHashCode ())
end

function self:HookViewManager (viewManager)
	if not viewManager then return end
	
	viewManager:AddEventListener ("ViewAdded", self:GetHashCode (),
		function (_, view)
			self:HookView (view)
			self.DockContainer:GetLargestContainer ():AddView (view)
			self:InvalidateSavedWorkspace ()
		end
	)
	
	viewManager:AddEventListener ("ViewRemoved", self:GetHashCode (),
		function (_, view)
			self:UnhookView (view)
			self:InvalidateSavedWorkspace ()
		end
	)
end

function self:UnhookViewManager (viewManager)
	if not viewManager then return end
	
	viewManager:RemoveEventListener ("ViewAdded",   self:GetHashCode ())
	viewManager:RemoveEventListener ("ViewRemoved", self:GetHashCode ())
end

function self:HookDocument (document)
	if not document then return end
	
	document:AddEventListener ("LanguageChanged", self:GetHashCode (),
		function (_)
			self:UpdateLanguageText ()
		end
	)
end

function self:UnhookDocument (document)
	if not document then return end
	
	document:RemoveEventListener ("LanguageChanged", self:GetHashCode ())
end

function self:HookSelectedCodeEditor (codeEditor)
	if not codeEditor then return end
	
	codeEditor:AddEventListener ("CaretMoved", self:GetHashCode (),
		function (_, caretLocation)
			self:UpdateCaretPositionText ()
		end
	)
	
	codeEditor:AddEventListener ("SyntaxHighligherChanged", self:GetHashCode (),
		function (_, oldSyntaxHighlighter, syntaxHighlighter)
			self:UnhookSyntaxHighlighter (oldSyntaxHighlighter)
			self:HookSyntaxHighlighter (syntaxHighlighter)
		end
	)
	
	self:HookSyntaxHighlighter (codeEditor:GetSyntaxHighlighter ())
end

function self:UnhookSelectedCodeEditor (codeEditor)
	if not codeEditor then return end
	codeEditor:RemoveEventListener ("CaretMoved",               self:GetHashCode ())
	codeEditor:RemoveEventListener ("SyntaxHighlighterChanged", self:GetHashCode ())
	self:UnhookSyntaxHighlighter (codeEditor:GetSyntaxHighlighter ())
end

function self:HookSyntaxHighlighter (syntaxHighlighter)
	if not syntaxHighlighter then return end
	
	syntaxHighlighter:AddEventListener ("HighlightingFinished", self:GetHashCode (),
		function (_)
			self:UpdateProgressBar ()
		end
	)
	syntaxHighlighter:AddEventListener ("HighlightingProgress", self:GetHashCode (),
		function (_, linesProcessed, totalLines)
			self:UpdateProgressBar ()
		end
	)
	syntaxHighlighter:AddEventListener ("HighlightingStarted", self:GetHashCode (),
		function (_)
			self:UpdateProgressBar ()
		end
	)
end

function self:UnhookSyntaxHighlighter (syntaxHighlighter)
	if not syntaxHighlighter then return end
	syntaxHighlighter:RemoveEventListener ("HighlightingFinished", self:GetHashCode ())
	syntaxHighlighter:RemoveEventListener ("HighlightingProgress", self:GetHashCode ())
	syntaxHighlighter:RemoveEventListener ("HighlightingStarted",  self:GetHashCode ())
end

function self:HookTabContents (tab, contents)
	if not tab.View then return end
	tab.View:AddEventListener ("IconChanged", self:GetHashCode (),
		function (_, icon)
			tab:SetIcon (icon)
		end
	)
	tab.View:AddEventListener ("TitleChanged", self:GetHashCode (),
		function (_, title)
			tab:SetText (title)
		end
	)
	tab.View:AddEventListener ("ToolTipTextChanged", self:GetHashCode (),
		function (_, toolTipText)
			tab:SetToolTipText (toolTipText)
		end
	)
	tab:SetIcon (tab.View:GetIcon ())
	tab:SetText (tab.View:GetTitle ())
	tab:SetToolTipText (tab.View:GetToolTipText ())
end

function self:UnhookTabContents (tab, contents)
	if not tab.View then return end
	tab.View:RemoveEventListener ("IconChanged",        self:GetHashCode ())
	tab.View:RemoveEventListener ("TitleChanged",       self:GetHashCode ())
	tab.View:RemoveEventListener ("ToolTipTextChanged", self:GetHashCode ())
end

function self:HookView (view)
	if not view then return end
	
	if view:GetSavable () then
		local savable = view:GetSavable ()
		savable:AddEventListener ("CanSaveChanged", self:GetHashCode (),
			function (_, canSave)
				local canSaveAll = false
				for view in self:GetViewManager ():GetEnumerator () do
					if view:GetSavable () and view:GetSavable ():IsUnsaved () then
						canSaveAll = true
						break
					end
				end
				
				self:GetActionMap ():GetAction ("Save All"):SetEnabled (canSaveAll)
				self.Toolbar:GetItemById ("Save All"):SetEnabled (canSaveAll)
			end
		)
	end
end

function self:UnhookView (view)
	if not view then return end
	
	if view:GetSavable () then
		view:GetSavable ():RemoveEventListener ("CanSaveChanged", self:GetHashCode ())
	end
end

-- Event handlers
function self:OnRemoved ()
	self:InvalidateSavedWorkspace ()
	self:SaveWorkspace ()
	self:SetCanSaveWorkspace (false)
	
	self.ClipboardController:dtor ()
	self.CodeEditorContextMenu:dtor ()
	self.TabContextMenu:dtor ()
	
	GCompute.IDE.Plugins:Uninitialize ()
end

function self:Think ()
	DFrame.Think (self)
	
	if self:IsFocused () and not Gooey.IsMenuOpen () then
		if self:GetActiveView () and
		   not self:GetActiveView ():GetContainer ():ContainsFocus () then
			self:GetActiveView ():GetContainer ():Focus ()
		end
	end
	
	-- Tab saving
	if self:IsWorkspaceUnsaved () and self:CanSaveWorkspace () and SysTime () - self.LastWorkspaceSaveTime > 5 then
		self:SaveWorkspace ()
	end
	
	-- Profiler
	self.MemoryProfilerPanel:SetText (GLib.FormatFileSize (collectgarbage ("count") * 1024))
	
	local view = self:GetActiveView ()
	local viewContainer = view and view:GetContainer () or nil
	local viewControl = viewContainer and viewContainer:GetContents () or nil
	local lastRenderTime = viewControl and viewControl.LastRenderTime or 0
	self.ProfilerPanel:SetText (string.format ("%.3f ms, %.2f %%", lastRenderTime * 1000, lastRenderTime / FrameTime () * 100))
end

vgui.Register ("GComputeIDEFrame", self, "GFrame")