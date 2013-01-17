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
	
	self.Toolbar = GCompute.IDE.Toolbar (self)
	
	self.DockContainer = vgui.Create ("GComputeDockContainer", self)
	self.DockContainer:SetContainerType (GCompute.DockContainerType.SplitContainer)
	self.DockContainer:SetOrientation (Gooey.Orientation.Horizontal)
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
			
			self.Toolbar:GetItemById ("Run Code"):SetEnabled (self:GetActiveCodeEditor () ~= nil)
			
			self:DispatchEvent ("ActiveViewChanged", oldView, view)
		end
	)
	self.DockContainer:AddEventListener ("ContainerSplit",
		function (_, splitDockContainer, container, emptyContainer)
			emptyContainer:SetContainerType (GCompute.DockContainerType.TabControl)
		end
	)
	self.DockContainer:AddEventListener ("ViewCloseRequested",
		function (_, view)
			self:CloseView (view)
		end
	)
	self.DockContainer:AddEventListener ("ViewMoved",
		function (_, view)
			if view:GetContainer ():GetTab () then
				view:GetContainer ():GetTab ():SetContextMenu (self.TabContextMenu)
			end
		end
	)
	self.DockContainer:AddEventListener ("ViewRegistered",
		function (_, view)
			self:HookView (view)
			
			view:SetDocumentManager (self.DocumentManager)
			self:RegisterDocument (view:GetDocument ())
			
			self:InvalidateSavedWorkspace ()
		end
	)
	self.DockContainer:AddEventListener ("ViewRemoved",
		function (_, container, view, viewRemovalReason)
			if viewRemovalReason == GCompute.ViewRemovalReason.Removal then
				self.DockContainer:UnregisterView (view)
			end
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
	self.DockContainer:AddEventListener ("ViewUnregistered",
		function (_, view)
			self:UnhookView (view)
			view:dtor ()
			
			self:InvalidateSavedWorkspace ()
		end
	)
	
	self.TabContextMenu = GCompute.IDE.TabContextMenu (self)
	self.CodeEditorContextMenu = GCompute.CodeEditor.CodeEditorContextMenu (self)
	
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
			local currentLanguage = codeEditor and codeEditor:GetLanguage ()
			for _, language in ipairs (languages) do
				local option = menu:AddOption (language:GetName ())
				option:AddEventListener ("Click",
					function ()
						local codeEditor = self:GetActiveCodeEditor ()
						if not codeEditor then return end
						codeEditor:SetLanguage (language)
						GCompute.LanguageDetector:SetDefaultLanguage (language)
					end
				)
				if language == currentLanguage then
					option:SetIcon ("icon16/bullet_black.png")
				end
			end
		end
	)
	
	self.ProgressPanel       = self.StatusBar:AddProgressPanel ()
	self.ProgressPanel:SetFixedWidth (128)
	self.MemoryProfilerPanel = self.StatusBar:AddTextPanel ("0.00 MiB")
	self.MemoryProfilerPanel:SetFixedWidth (128)
	self.ProfilerPanel       = self.StatusBar:AddTextPanel ("0.000 ms, 0 %")
	self.ProfilerPanel:SetFixedWidth (128)
	self.CaretPositionPanel  = self.StatusBar:AddTextPanel ("Line 1, col 1")
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
	
	-- We need to create our DocumentManager before any views are created
	-- so we can set their DocumentManager properly when they are registered
	self.DocumentManager = GCompute.IDE.DocumentManager ()
	
	local viewTypes =
	{
		"Output",
		"ProcessBrowser",
		"HookProfiler"
	}
	for _, viewType in ipairs (viewTypes) do
		local view = GCompute.IDE.ViewTypes:Create (viewType)
		view:SetId (viewType)
		view:SetCanClose (false)
		self [viewType .. "View"] = view
		self.DockContainer:RegisterView (view)
	end
	
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
	
	self:SetCanSaveWorkspace (false)
	self:LoadWorkspace (
		function ()
			if not self.OutputView:GetContainer ():GetDockContainer () then
				self.DockContainer:GetCreateSplit (GCompute.DockingSide.Bottom):AddView (self.OutputView)
			end
			for view in self.DockContainer:GetViewEnumerator () do
				if not view:GetContainer ():GetDockContainer () then
					if view:GetDocument () then
						self.DockContainer:GetLargestContainer ():AddView (view)
					else
						self.DockContainer:GetCreateSplit (GCompute.DockingSide.Bottom):AddView (view)
					end
				end
			end
			
			self:SetCanSaveWorkspace (true)
			if self.DocumentManager:GetDocumentCount () == 0 then
				self:CreateEmptyCodeView ()
			end
			self.DockContainer:GetLargestView ():Select ()
		end
	)
	end, GLib.Error)
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
	if self.DockContainer then
		self.DockContainer:SetPos (2, 23 + self.Toolbar:GetTall ())
		self.DockContainer:SetSize (self:GetWide () - 4, self:GetTall () - 23 - self.Toolbar:GetTall () - 4 - self.StatusBar:GetTall ())
	end
end

--- Returns false if the view is the last remaining document view and contains the unchanged default text
function self:CanCloseView (view)
	if not view then return true end
	
	-- No special checks for views that do not host documents
	if not view:GetDocument () then
		return view:CanClose ()
	end
	
	if self.DocumentManager:GetDocumentCount () == 1 and
	   view:GetDocument ():GetViewCount () == 1 and
	   view:GetType () == "Code" and
	   not view:GetSavable ():HasPath () and
	   not view:GetSavable ():IsUnsaved () then
		return false
	end
	
	return view:CanClose ()
end

--- Closes a view
-- @param callback function (success)
function self:CloseView (view, callback)
	callback = callback or GCompute.NullCallback
	
	if not view then callback (true) return end
	if not view:CanClose () then callback (false) return end

	-- Don't close the last tab if it contains the default text
	if not self:CanCloseView (view) then
		callback (false)
		return
	end
	
	if view:GetSavable () and view:GetSavable ():IsUnsaved () and view:GetDocument ():GetViewCount () <= 1 then
		Gooey.YesNoDialog ()
			:SetTitle ("Save")
			:SetText ("Save \"" .. view:GetTitle () .. "\"?")
			:SetCallback (
				function (result)
					if result == "Yes" then
						self:SaveView (view,
							function (saved)
								if saved then
									self:CloseView (view, callback)
								else
									callback (false)
								end
							end
						)
					elseif result == "No" then
						view:dtor ()
						callback (true)
						
						-- Avoid having no views open
						if self.DocumentManager:GetDocumentCount () == 0 then
							self:CreateEmptyCodeView ()
						end
					else
						callback (false)
					end
				end
			)
	else
		view:dtor ()
		callback (true)
		
		-- Avoid having no views open
		if self.DocumentManager:GetDocumentCount () == 0 then
			self:CreateEmptyCodeView ()
		end
	end
end

function self:CreateView (className, id)
	local view = GCompute.IDE.ViewTypes:Create (className)
	if not view then return nil end
	view:SetId (id)
	self.DockContainer:RegisterView (view)
	
	return view
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

function self:LoadWorkspace (callback)
	local inBuffer = GLib.StringInBuffer (file.Read ("data/gcompute_editor_tabs.txt", "GAME") or "")
	inBuffer:String () -- Discard comment
	self.DocumentManager:LoadSession (GLib.StringInBuffer (inBuffer:LongString ()))
	inBuffer:Char ()   -- Discard newline
	inBuffer:String () -- Discard comment
	
	local id = inBuffer:String ()
	while id ~= "" do
		local viewType = inBuffer:String ()
		local subInBuffer = GLib.StringInBuffer (inBuffer:String ())
		local view = self.DockContainer:GetViewById (id)
		if not view then
			view = self:CreateView (viewType, id)
		end
		if view then
			view:LoadSession (subInBuffer)
		end
		
		inBuffer:Char () -- Discard newline
		id = inBuffer:String ()
	end
	
	inBuffer:Char ()   -- Discard newline
	inBuffer:String () -- Discard comment
	
	-- Check for orphaned documents
	for document in self.DocumentManager:GetEnumerator () do
		if document:GetViewCount () == 0 then
			local view = self:CreateView ("Code")
			view:SetDocument (document)
		end
	end
	
	self.DockContainer:LoadSession (GLib.StringInBuffer (inBuffer:String ()))
	
	callback ()
end

function self:SaveWorkspace ()
	if not self:CanSaveWorkspace () then return end
	if not self:IsWorkspaceUnsaved () then return end
	self.LastWorkspaceSaveTime = SysTime ()
	self.WorkspaceUnsaved = false
	
	local outBuffer = GLib.StringOutBuffer ()
	outBuffer:String ("\n=== Documents ===\n")
	
	local subOutBuffer = GLib.StringOutBuffer ()
	self.DocumentManager:SaveSession (subOutBuffer)
	outBuffer:LongString (subOutBuffer:GetString ())
	outBuffer:Char ("\n")
	outBuffer:String ("\n=== Views ===\n")
	
	for view in self.DockContainer:GetViewEnumerator () do
		local viewType = view:GetType ()
		outBuffer:String (view:GetId ())
		outBuffer:String (viewType)
		subOutBuffer:Clear ()
		view:SaveSession (subOutBuffer)
		outBuffer:String (subOutBuffer:GetString ())
		outBuffer:Char ("\n")
	end
	outBuffer:String ("")
	outBuffer:Char ("\n")
	outBuffer:String ("\n=== Workspace ===\n")
	subOutBuffer:Clear ()
	self.DockContainer:SaveSession (subOutBuffer)
	outBuffer:String (subOutBuffer:GetString ())
	file.Write ("gcompute_editor_tabs.txt", outBuffer:GetString ())
end

function self:SetCanSaveWorkspace (canSaveWorkspace)
	self.WorkspaceSavingEnabled = canSaveWorkspace
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
	
	local extension = file:GetExtension () or ""
	extension = string.lower (extension)
	
	local imageExtensions =
	{
		["bmp"] = true,
		["gif"] = true,
		["jpg"] = true,
		["png"] = true
	}
	
	if imageExtensions [extension] then
		local view = self:CreateView ("Image")
		view:SetTitle (file:GetDisplayName ())
		view:SetFile (file)
		self.DockContainer:GetLargestContainer ():AddView (view)
		
		callback (true, file, view)
	else
		file:Open (GLib.GetLocalId (), VFS.OpenFlags.Read,
			function (returnCode, fileStream)
				if returnCode == VFS.ReturnCode.Success then
					fileStream:Read (fileStream:GetLength (),
						function (returnCode, data)
							if returnCode == VFS.ReturnCode.Progress then return end
							
							local file = fileStream:GetFile ()
							local view = self:CreateCodeView ()
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
end

--- Opens a new tab for the given path. Use OpenFile instead if you have an IFile.
-- @param path The path of the file to be opened
-- @param callback A callback function (success, IFile file, IView view)
function self:OpenPath (path, callback)
	callback = callback or GCompute.NullCallback
	
	local document = self.DocumentManager:GetDocumentByPath (path)
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

--- Prompts for a file to which to save, then saves a view's contents.
-- @param view The view whose contents are to be saved
-- @param callback A callback function (success, IFile file)
function self:SaveAsView (view, callback)
	callback = callback or GCompute.NullCallback
	if not view               then callback (true) return end
	if not view:GetSavable () then callback (true) return end
	
	VFS.OpenSaveFileDialog ("GCompute.IDE",
		function (path, file)
			if not path then callback (false) return end
			if not self or not self:IsValid () then callback (false) return end
			
			view:GetSavable ():SetPath (path)
			self:SaveView (view, path, callback)
		end
	)
end

--- Saves a view's contents.
-- @param view The view whose contents are to be saved
-- @param pathOrCallback Optional path to which to save
-- @param callback A callback function (success, IFile file)
function self:SaveView (view, pathOrCallback, callback)
	if type (pathOrCallback) == "function" then
		callback = pathOrCallback
		pathOrCallback = nil
	end
	callback = callback or GCompute.NullCallback
	
	if not view               then callback (true) return end
	if not view:GetSavable () then callback (true) return end
	
	-- Determine save path
	local path = pathOrCallback
	if not path and view:GetSavable ():HasPath () then
		path = view:GetSavable ():GetPath ()
		view:GetSavable ():SetPath (path)
	end
	
	-- If the view has no path, invoke the save as dialog.
	if not path then
		self:SaveAsView (view, callback)
		return
	end
	
	view:GetSavable ():Save (callback)
end

-- Internal, do not call
function self:RegisterDocument (document)
	if not document then return end
	
	self.DocumentManager:AddDocument (document)
	self:HookDocument (document)
	
	self:InvalidateSavedWorkspace ()
end

function self:UnregisterDocument (document)
	if not document then return end
	
	self.DocumentManager:RemoveDocument (document)
	self:UnhookDocument (document)
	
	self:InvalidateSavedWorkspace ()
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
function self:HookDocument (document)
	if not document then return end
	
	document:AddEventListener ("LanguageChanged", tostring (self:GetTable ()),
		function (_)
			self:UpdateLanguageText ()
		end
	)
	document:AddEventListener ("ViewRemoved", tostring (self:GetTable ()),
		function (_)
			if document:GetViewCount () == 0 then
				self:UnregisterDocument (document)
			end
		end
	)
end

function self:UnhookDocument (document)
	if not document then return end
	
	document:RemoveEventListener ("LanguageChanged", tostring (self:GetTable ()))
	document:RemoveEventListener ("ViewRemoved",     tostring (self:GetTable ()))
end

function self:HookSelectedCodeEditor (codeEditor)
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

function self:UnhookSelectedCodeEditor (codeEditor)
	if not codeEditor then return end
	codeEditor:RemoveEventListener ("CaretMoved",               tostring (self:GetTable ()))
	codeEditor:RemoveEventListener ("SyntaxHighlighterChanged", tostring (self:GetTable ()))
	self:UnhookSyntaxHighlighter (codeEditor:GetSyntaxHighlighter ())
end

function self:HookSyntaxHighlighter (syntaxHighlighter)
	if not syntaxHighlighter then return end
	
	syntaxHighlighter:AddEventListener ("HighlightingFinished", tostring (self:GetTable ()),
		function (_)
			self:UpdateProgressBar ()
		end
	)
	syntaxHighlighter:AddEventListener ("HighlightingProgress", tostring (self:GetTable ()),
		function (_, linesProcessed, totalLines)
			self:UpdateProgressBar ()
		end
	)
	syntaxHighlighter:AddEventListener ("HighlightingStarted", tostring (self:GetTable ()),
		function (_)
			self:UpdateProgressBar ()
		end
	)
end

function self:UnhookSyntaxHighlighter (syntaxHighlighter)
	if not syntaxHighlighter then return end
	syntaxHighlighter:RemoveEventListener ("HighlightingFinished", tostring (self:GetTable ()))
	syntaxHighlighter:RemoveEventListener ("HighlightingProgress", tostring (self:GetTable ()))
	syntaxHighlighter:RemoveEventListener ("HighlightingStarted",  tostring (self:GetTable ()))
end

function self:HookTabContents (tab, contents)
	if not tab.View then return end
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
end

function self:UnhookTabContents (tab, contents)
	if not tab.View then return end
	tab.View:RemoveEventListener ("IconChanged",        tostring (self:GetTable ()))
	tab.View:RemoveEventListener ("TitleChanged",       tostring (self:GetTable ()))
	tab.View:RemoveEventListener ("ToolTipTextChanged", tostring (self:GetTable ()))
end

function self:HookView (view)
	if not view then return end
	
	view:AddEventListener ("DocumentChanged", tostring (self:GetTable ()),
		function (_, oldDocument, newDocument)
			self:UnregisterDocument (oldDocument)
			self:RegisterDocument (newDocument)
		end
	)
	
	if view:GetSavable () then
		local savable = view:GetSavable ()
		savable:AddEventListener ("CanSaveChanged", tostring (self:GetTable ()),
			function (_, canSave)
				local canSaveAll = false
				for view in self.DockContainer:GetViewEnumerator () do
					if view:GetSavable () and view:GetSavable ():IsUnsaved () then
						canSaveAll = true
						break
					end
				end
				
				self.Toolbar:GetItemById ("Save All"):SetEnabled (canSaveAll)
			end
		)
	end
end

function self:UnhookView (view)
	if not view then return end
	view:RemoveEventListener ("DocumentChanged", tostring (self:GetTable ()))
	if view:GetSavable () then
		view:GetSavable ():RemoveEventListener ("CanSaveChanged", tostring (self:GetTable ()))
	end
end

-- Event handlers
function self:OnRemoved ()
	self:InvalidateSavedWorkspace ()
	self:SaveWorkspace ()
	self:SetCanSaveWorkspace (false)
	
	self.ClipboardController:dtor ()
	self.CodeEditorContextMenu:Remove ()
	self.TabContextMenu:Remove ()
	
	GCompute.IDE.Plugins:Uninitialize ()
end

-- Event handlers
function self:Think ()
	DFrame.Think (self)
	
	if self:HasFocus () and not Gooey.IsMenuOpen () then
		if self:GetActiveView () and
		   not self:GetActiveView ():GetContainer ():HasHierarchicalFocus () then
			self:GetActiveView ():GetContainer ():RequestFocus ()
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