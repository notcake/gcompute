local self, info = GCompute.IDE.ViewTypes:CreateType ("Profiler")
info:SetAutoCreate (true)
info:SetDefaultLocation ("Bottom")
self.Title    = "Profiler"
self.Icon     = "icon16/clock.png"
self.Hideable = true
self.Visible  = false

function self:ctor (container)
	self.Toolbar = vgui.Create ("GToolbar", container)
	self.Toolbar:AddButton ("Start")
		:SetIcon ("icon16/control_play.png")
		:AddEventListener ("Click",
			function ()
				self:Start ()
				self.Toolbar:GetItemById ("Start"):SetEnabled (false)
				self.Toolbar:GetItemById ("Stop") :SetEnabled (true)
			end
		)
	self.Toolbar:AddButton ("Stop")
		:SetIcon ("icon16/control_stop.png")
		:SetEnabled (false)
		:AddEventListener ("Click",
			function ()
				self:Stop ()
				self.Toolbar:GetItemById ("Start"):SetEnabled (true)
				self.Toolbar:GetItemById ("Stop") :SetEnabled (false)
			end
		)
	self.Toolbar:AddSeparator ()
	
	-- Navigation controls
	self.Toolbar:AddButton ("Back")
		:SetIcon ("icon16/resultset_previous.png")
	self.Toolbar:AddButton ("Forwards")
		:SetIcon ("icon16/resultset_next.png")
	self.ComboBox = self.Toolbar:AddComboBox ()
	self.ComboBox:SetWidth (128)
	
	-- Navigation history
	self.HistoryStack = Gooey.HistoryStack ()
	self.HistoryStack:AddEventListener ("CurrentItemChanged",
		function (_, historyItem)
			if not historyItem then return end
			
			self:SetActiveSubView (historyItem:GetSubViewId ())
			local activeSubView = self:GetActiveSubView ()
			if activeSubView then
				activeSubView:RestoreHistoryItem (historyItem)
			end
		end
	)
	
	self.HistoryController = Gooey.HistoryController (self.HistoryStack)
	self.HistoryController:AddMoveForwardButton (self.Toolbar:GetItemById ("Forwards"))
	self.HistoryController:AddMoveBackButton (self.Toolbar:GetItemById ("Back"))
	
	-- Profiling
	self.Profiler = nil
	self.ProfilingResultSet = nil
	
	-- Subviews
	self.SubViewContainer = vgui.Create ("GPanel", container)
	self.ActiveSubView = nil
	
	self.FunctionEntryMenu = Gooey.Menu ()
	self.FunctionEntryMenu:AddItem ("View Source")
		:SetIcon ("icon16/page_code.png")
		:AddEventListener ("Click",
			function (_, functionEntry)
				self:ShowFunctionCode (functionEntry)
			end
		)
	self.FunctionEntryMenu:AddItem ("View Annotated Source")
		:SetIcon ("icon16/page_code.png")
		:AddEventListener ("Click",
			function (_, functionEntry)
				self:ShowAnnotatedFunctionCode (functionEntry)
			end
		)
	self.FunctionEntryMenu:AddSeparator ()
	self.FunctionEntryMenu:AddItem ("Show Function Details")
		:SetIcon ("icon16/magnifier.png")
		:AddEventListener ("Click",
			function (_, functionEntry)
				self:NavigateToFunctionDetailsView (functionEntry)
			end
		)
	
	self.SubViews = {}
	self.SubViews [#self.SubViews + 1] = GCompute.IDE.Profiler.SubViews.Functions (self, self.SubViewContainer)
	self.SubViews [#self.SubViews + 1] = GCompute.IDE.Profiler.SubViews.FunctionDetails (self, self.SubViewContainer)
	
	for _, subView in ipairs (self.SubViews) do
		self.SubViews [subView:GetId ()] = subView
		
		local comboBoxItem = self.ComboBox:AddItem (subView:GetName (), subView:GetId ())
		comboBoxItem:AddEventListener ("Selected",
			function ()
				self:NavigateToSubView (subView)
			end
		)
		
		subView.ComboBoxItem = comboBoxItem
	end
	
	self:AddEventListener ("ActiveSubViewChanged",
		function (_, subView)
			if not subView then return end
			
			subView.ComboBoxItem:Select ()
		end
	)
	
	-- Initialize
	self:SetProfiler (GCompute.Profiling.Profiler)
	self:SetProfilingResultSet (GCompute.Profiling.ProfilingResultSet ())
	
	self:NavigateToSubView (self.SubViews.Functions)
end

function self:dtor ()
	self:Stop ()
	
	self:SetProfiler (nil)
	self:SetProfilingResultSet (nil)
	
	for _, subView in ipairs (self.SubViews) do
		subView:dtor ()
	end
	
	self.FunctionEntryMenu:dtor ()
end

-- Persistance
function self:LoadSession (inBuffer)
end

function self:SaveSession (outBuffer)
end

-- Sub views
function self:GetActiveSubView ()
	return self.ActiveSubView
end

function self:GetActiveSubViewId ()
	if not self.ActiveSubView then return nil end
	return self.ActiveSubView:GetId ()
end

function self:GetSubView (id)
	return self.SubViews [id]
end

function self:SetActiveSubView (subView)
	if type (subView) == "string" then
		subView = self.SubViews [subView]
	end
	
	if self.ActiveSubView == subView then return end
	
	if self.ActiveSubView then
		self.ActiveSubView:SetVisible (false)
	end
	
	self.ActiveSubView = subView
	
	if self.ActiveSubView then
		self.ActiveSubView:SetVisible (true)
		self.ComboBox:SetSelectedItem (self.ActiveSubView:GetId ())
	end
end

-- Menus
function self:GetFunctionEntryMenu ()
	return self.FunctionEntryMenu
end

-- Navigation
function self:CreateHistoryItem ()
	local activeSubView = self:GetActiveSubView ()
	local historyItem = activeSubView and activeSubView:CreateHistoryItem () or GCompute.IDE.Profiler.HistoryItem ()
	historyItem:SetView (self)
	historyItem:SetSubViewId (self:GetActiveSubViewId ())
	
	return historyItem
end

function self:NavigateToSubView (subView)
	if subView == self:GetActiveSubView () then
		return nil
	end
	
	-- Open up the view
	self:SetActiveSubView (subView)
	
	-- Stick an entry in our history
	local historyItem = self:CreateHistoryItem ()
	self.HistoryStack:Push (historyItem)
	
	return historyItem
end

function self:NavigateToFunctionDetailsView (functionEntry)
	local subView = self:GetSubView ("Function Details")
	
	-- Open up the function details view
	self:SetActiveSubView (subView)
	subView:SetFunctionEntry (functionEntry)
	
	-- Stick an entry in our history
	local historyItem = self:CreateHistoryItem ()
	self.HistoryStack:Push (historyItem)
	
	return historyItem
end

function self:ShowAnnotatedFunctionCode (functionEntry)
	self:GetFunctionCode (functionEntry,
		function (success, code)
			if not success then return false end
			
			-- Annotate code
			local lines = string.Split (code, "\n")
			
			local startLine = functionEntry:GetFunction ():GetStartLine ()
			local endLine = functionEntry:GetFunction ():GetEndLine ()
			endLine = math.min (endLine, #lines)
			for i = startLine, endLine do
				local lineCount = functionEntry:GetLineCount (i)
				if lineCount == 0 then
					lines [i] = "--[[          ]] " .. lines [i]
				else
					local fraction = lineCount / self:GetProfilingResultSet ():GetSampleCount ()
					local percentage = string.format ("%.2f", fraction * 100)
					percentage = string.rep (" ", string.len ("100.00") - #percentage) .. percentage
					lines [i] = "--[[ " .. percentage .. " % ]] " .. lines [i]
				end
			end
			code = table.concat (lines, "\n")
			
			local codeView = self:GetIDE ():CreateView ("Code")
			codeView:SetCode (code)
			codeView:SetTitle (functionEntry:GetFunctionName ())
			codeView:Select ()
			
			self:ShowCodeViewLines (codeView, startLine, endLine)
		end
	)
end

function self:ShowFunctionCode (functionEntry)
	local uri = functionEntry:GetFunction ():GetFilePath ()
	local luaPath = string.match (uri, "lua/(.*)") or string.match (uri, "gamemodes/(.*)")
	if luaPath then
		local function showFunctionDefinition (view)
			view:Select ()
			
			if view:GetType () ~= "Code" then return end
			
			local startLine = functionEntry:GetFunction ():GetStartLine ()
			local endLine = functionEntry:GetFunction ():GetEndLine ()
			self:ShowCodeViewLines (view, startLine, endLine)
		end
		
		local client = false
		if file.Exists (luaPath, "LCL") then
			uri = "luacl/" .. luaPath
			client = true
		else
			uri = "luasv/" .. luaPath
		end
		
		self:GetIDE ():OpenUri (uri,
			function (success, resource, view)
				if not view then
					if not client then return end
					
					uri = "luasv/" .. luaPath
					self:GetIDE ():OpenUri (uri,
						function (success, resource, view)
							if not view then return end
							
							showFunctionDefinition (view)
						end
					)
					return
				end
				
				showFunctionDefinition (view)
			end
		)
	end
end

function self:ShowCodeViewLines (codeView, startLine, endLine)
	codeView:Select ()
	
	if codeView:GetType () ~= "Code" then return end
	
	local location1 = GCompute.CodeEditor.LineCharacterLocation (startLine - 1, char and (char - 1) or 0)
	local location2 = GCompute.CodeEditor.LineCharacterLocation (endLine   - 1, char and (char - 1) or 0)
	location1 = codeView:GetEditor ():GetDocument ():CharacterToColumn (location1, codeView:GetEditor ():GetTextRenderer ())
	location2 = codeView:GetEditor ():GetDocument ():CharacterToColumn (location2, codeView:GetEditor ():GetTextRenderer ())
	codeView:GetEditor ():SetCaretPos (location2)
	GLib.CallDelayed (
		function ()
			codeView:GetEditor ():ScrollToCaret ()
			codeView:GetEditor ():SetCaretPos (location1)
			codeView:GetEditor ():SetSelection (codeView:GetEditor ():GetCaretPos ())
			codeView:GetEditor ():ScrollToCaret ()
		end
	)
end

function self:GetFunctionCode (functionEntry, callback)
	local uri = functionEntry:GetFunction ():GetFilePath ()
	
	local luaPath = string.match (uri, "lua/(.*)") or string.match (uri, "gamemodes/(.*)")
	if not luaPath then callback (false, nil) return end
	
	if file.Exists (luaPath, "LCL") then
		uri = "luacl/" .. luaPath
		client = true
	else
		uri = "luasv/" .. luaPath
	end
	
	local function handleFileStream (fileStream)
		fileStream:Read (fileStream:GetLength (),
			function (returnCode, data)
				if returnCode == VFS.ReturnCode.Progress then return end
				
				fileStream:Close ()
				
				if returnCode ~= VFS.ReturnCode.Success then
					callback (false, nil)
				else
					callback (true, data)
				end
			end
		)
	end
	
	VFS.Root:OpenFile (GLib.GetLocalId (), uri, VFS.OpenFlags.Read,
		function (returnCode, fileStream)
			if returnCode ~= VFS.ReturnCode.Success then
				if not client then callback (false, nil) return end
				
				uri = "luasv/" .. luaPath
				VFS.Root:OpenFile (GLib.GetLocalId (), uri, VFS.OpenFlags.Read,
					function (returnCode, fileStream)
						if returnCode ~= VFS.ReturnCode.Success then callback (false, nil) return end
						
						handleFileStream (fileStream)
					end
				)
				return
			end
			
			handleFileStream (fileStream)
		end
	)
end

-- Profiling
function self:GetProfiler ()
	return self.Profiler
end

function self:GetProfilingResultSet ()
	return self.ProfilingResultSet
end

function self:SetProfiler (profiler)
	if self.Profiler == profiler then return self end
	
	self.Profiler = profiler
	
	for _, subView in ipairs (self.SubViews) do
		subView:SetProfiler (profiler)
	end
	
	return self
end

function self:SetProfilingResultSet (profilingResultSet)
	if self.ProfilingResultSet == profilingResultSet then return self end
	
	self.ProfilingResultSet = profilingResultSet
	
	for _, subView in ipairs (self.SubViews) do
		subView:SetProfilingResultSet (profilingResultSet)
	end
	
	return self
end

function self:Clear ()
	if self.Profiler then
		self.Profiler:Clear ()
	end
	
	if self.ProfilingResultSet then
		self.ProfilingResultSet:Clear ()
	end
	
	-- Clear the history
	self.HistoryStack:Clear ()
	
	-- The history needs to have at least one item in it
	local historyItem = self:CreateHistoryItem ()
	self.HistoryStack:Push (historyItem)
end

function self:Start ()
	if not self.Profiler then return end
	
	self.Profiler:SetProfilingResultSet (self.ProfilingResultSet)
	
	for _, subView in ipairs (self.SubViews) do
		subView:SetProfiler (self.Profiler)
		subView:SetProfilingResultSet (self.ProfilingResultSet)
	end
	
	self:Clear ()
	self.Profiler:Start ()
end

function self:Stop ()
	if not self.Profiler then return end
	
	self.Profiler:Stop ()
end

-- Event handlers
function self:PerformLayout (w, h)
	self.Toolbar:SetWide (w)
	self.SubViewContainer:SetPos (0, self.Toolbar:GetTall ())
	self.SubViewContainer:SetSize (w, h - self.Toolbar:GetTall ())
end

function self:Think ()
	if self.ActiveSubView then
		self.ActiveSubView:Think ()
	end
end