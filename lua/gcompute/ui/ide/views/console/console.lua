local self, info = GCompute.IDE.ViewTypes:CreateType ("Console")
info:SetAutoCreate (true)
info:SetAutoCreationCount (4)
info:SetDefaultLocation ("Bottom")
self.Title    = "Console"
self.Icon     = "icon16/application_xp_terminal.png"
self.Hideable = true

function self:ctor (container)
	-- Output
	self.Output = vgui.Create ("GComputeCodeEditor", container)
	self.Output:GetDocument ():AddView (self)
	self.Output:SetCompilationEnabled (false)
	self.Output:SetLineNumbersVisible (false)
	self.Output:SetReadOnly (true)
	
	self.ContextMenu = Gooey.Menu ()
	self.ContextMenu:AddEventListener ("MenuOpening",
		function ()
			self.ContextMenu:GetItemById ("Copy") :SetEnabled (not self.Output:IsSelectionEmpty ())
			self.ContextMenu:GetItemById ("Clear"):SetEnabled (self.Output:GetText () ~= "")
		end
	)
	self.ContextMenu:AddItem ("Copy")
		:SetIcon ("icon16/page_white_copy.png")
		:AddEventListener ("Click",
			function ()
				self.ClipboardTarget:Copy ()
			end
		)
	self.ContextMenu:AddSeparator ()
	self.ContextMenu:AddItem ("Select All")
		:AddEventListener ("Click",
			function ()
				self.Output:SelectAll ()
			end
		)
	self.ContextMenu:AddSeparator ()
	self.ContextMenu:AddItem ("Clear")
		:AddEventListener ("Click",
			function ()
				self.Output:Clear ()
				self.OutputEmpty = true
			end
		)
	self.Output:SetContextMenu (self.ContextMenu)
	
	self.Output:AddEventListener ("DoubleClick",
		function (_, x, y)
			if GLib.CallSelfInThread () then return end
			
			local lineColumnLocation = self.Output:PointToLocation (x, y)
			local line = self.Output:GetDocument ():GetLine (lineColumnLocation:GetLine ())
			if not line then return end
			local lineText = line:GetText ()
			local sourceDocumentId  = line:GetAttribute ("SourceDocumentId", 0)
			local sourceDocumentUri = line:GetAttribute ("SourceDocumentUri", 0)
			
			-- Attempt to get line, char information
			-- line %d, char %d
			
			local lowercaseLineText = string.lower (lineText)
			
			local luaPath        = nil
			local startLineMatch = nil
			local endLineMatch   = nil
			local charMatch      = nil
			
			startLineMatch, charMatch = string.match (lowercaseLineText, "line[ \t]*([0-9]+),?[ \t]*char[ \t]*([0-9]+)")
			if not startLineMatch then
				startLineMatch, charMatch = string.match (lowercaseLineText, "line[ \t]*([0-9]+),?[ \t]*character[ \t]*([0-9]+)")
			end
			startLineMatch = startLineMatch or string.match (lowercaseLineText, "line[ \t]*([0-9]+)")
			
			-- debug.Trace style stack traces
			-- GLib style stack traces
			if not startLineMatch then
				luaPath, startLineMatch, endLineMatch = string.match (lowercaseLineText, "lua/(.*) *: *([0-9]+)%- *([0-9]+)")
			end
			if not startLineMatch then
				luaPath, startLineMatch = string.match (lowercaseLineText, "lua/(.*) *: *([0-9]+)")
			end
			if not startLineMatch then
				luaPath, startLineMatch, endLineMatch = string.match (lowercaseLineText, "gamemodes/(.*) *: *([0-9]+)%- *([0-9]+)")
			end
			if not startLineMatch then
				luaPath, startLineMatch = string.match (lowercaseLineText, "gamemodes/(.*) *: *([0-9]+)")
			end
			
			-- Getting desperate
			luaPath = luaPath or string.match (lowercaseLineText, "lua/(.*%.lua)")
			luaPath = luaPath or string.match (lowercaseLineText, "gamemodes/(.*%.lua)")
			
			if not startLineMatch then
				startLineMatch = string.match (lowercaseLineText, ":([0-9]+): ")
			end
			
			local startLine = tonumber (startLineMatch)
			local endLine   = tonumber (endLineMatch)
			local char      = tonumber (charMatch)
			
			local client = false
			local uri = nil
			if luaPath then
				luaPath = string.Trim (luaPath)
				
				-- We found a match, disregard the source document information
				sourceDocumentId = nil
				
				if file.Exists (luaPath, "LCL") then
					uri = "luacl/" .. luaPath
					client = true
				else
					uri = "luasv/" .. luaPath
				end
			end
			uri = uri or sourceDocumentUri
			
			local document = self:GetDocumentManager ():GetDocumentById (sourceDocumentId)
			document = document or self:GetDocumentManager ():GetDocumentByUri (uri)
			
			if document then
				local view = document:GetView (1)
				if not view then return end
				
				self:BringUpView (view, startLine, char, endLine)
			elseif uri and uri ~= nil then
				local success, resource, view = self:GetIDE ():OpenUri (uri)
				
				if not view and client then
					uri = "luasv/" .. luaPath
					success, resource, view = self:GetIDE ():OpenUri (uri)
				end
				
				if not view then return end
				
				self:BringUpView (view, startLine, char, endLine)
			end
		end
	)
	
	self.ClipboardTarget = GCompute.CodeEditor.EditorClipboardTarget (self.Output)
	
	-- Input
	self.HostComboBox = vgui.Create ("GComboBox", container)
	self.HostComboBox:SetWidth (128)
	self.HostComboBox:AddItem ("Self"   ):SetIcon ("icon16/user_go.png")
	self.HostComboBox:AddItem ("Server" ):SetIcon ("icon16/server_go.png")
	self.HostComboBox:AddItem ("Client" ):SetIcon ("icon16/user_go.png")
	self.HostComboBox:AddItem ("Clients"):SetIcon ("icon16/group_go.png")
	self.HostComboBox:AddItem ("Shared" ):SetIcon ("icon16/world_go.png")
	
	self.HostComboBox:AddEventListener ("MenuOpening",
		function (_, menu)
			local menuItem = menu:GetItemById ("Client")
			if not menuItem then return end
			
			menuItem:GetEventProvider ():ClearEventListeners ("Click")
			menuItem:SetSubMenu (self.UserMenu)
			
			menu:GetItemById ("Self"   ):SetEnabled (GCompute.Execution.ExecutionService:CanCreateExecutionContext (GLib.GetLocalId (), "Self",    nil))
			menu:GetItemById ("Server" ):SetEnabled (GCompute.Execution.ExecutionService:CanCreateExecutionContext (GLib.GetLocalId (), "Server",  nil))
			menu:GetItemById ("Client" ):SetEnabled (GCompute.Execution.ExecutionService:CanCreateExecutionContext (GLib.GetLocalId (), "Clients", nil))
			menu:GetItemById ("Clients"):SetEnabled (GCompute.Execution.ExecutionService:CanCreateExecutionContext (GLib.GetLocalId (), "Clients", nil))
			menu:GetItemById ("Shared" ):SetEnabled (GCompute.Execution.ExecutionService:CanCreateExecutionContext (GLib.GetLocalId (), "Shared",  nil))
		end
	)
	
	self.HostComboBox:AddEventListener ("SelectedItemChanged",
		function (_, lastSelectedItem, selectedItem)
			self:SetHostId (selectedItem and selectedItem:GetId ())
		end
	)
	
	self.UserMenu = Gooey.Menu ()
	self.HostComboBox:AddEventListener ("MenuOpening",
		function (_)
			self.UserMenu:Clear ()
			
			local users = GLib.Enumerator.ToArray (GCompute.PlayerMonitor:GetUserEnumerator ())
			table.sort (users,
				function (a, b)
					return GLib.UTF8.ToLower (GCompute.PlayerMonitor:GetUserName (a)) < GLib.UTF8.ToLower (GCompute.PlayerMonitor:GetUserName (b))
				end
			)
			
			for _, userId in ipairs (users) do
				local ply = GCompute.PlayerMonitor:GetUserEntity (userId)
				local isAdmin = ply and ply:IsValid () and ply:IsAdmin ()
				self.UserMenu:AddItem (userId)
					:SetChecked (userId == self:GetHostId ())
					:SetText (GCompute.PlayerMonitor:GetUserName (userId))
					:SetIcon (isAdmin and "icon16/shield_go.png" or "icon16/user_go.png")
					:AddEventListener ("Click",
						function ()
							self:SetHostId (userId)
						end
					)
			end
		end
	)
	
	self.LanguageComboBox = vgui.Create ("GComboBox", container)
	
	self.LanguageComboBox:AddEventListener ("SelectedItemChanged",
		function (_, lastSelectedItem, selectedItem)
			self:SetLanguage (selectedItem and selectedItem:GetId ())
		end
	)
	
	local icons =
	{
		["Console"]           = "icon16/application_xp_terminal.png",
		["Terminal Emulator"] = "icon16/application_xp_terminal.png"
	}
	local lastLanguageExists = nil
	for language in GCompute.Execution.ExecutionService:GetLanguageEnumerator () do
		local languageExists = GCompute.Languages.Get (language) ~= nil
		if lastLanguageExists ~= nil and lastLanguageExists ~= languageExists then
			self.LanguageComboBox = self.LanguageComboBox
			self.LanguageComboBox:GetMenu ():AddSeparator ()
		end
		lastLanguageExists = languageExists
		
		local comboBoxItem = self.LanguageComboBox:AddItem (language)
		comboBoxItem:SetIcon (icons [language])
	end
	
	-- Input
	self.InputHistory = {}
	self.InputHistoryPosition = 1
	
	self.Input = vgui.Create ("GComputeCodeEditor", container)
	self.Input:SetMultiline (false)
	self.Input:SetLineNumbersVisible (false)
	self.Input:SetHorizontalScrollbarEnabled (false)
	
	self.Input:SetKeyboardMap (self.Input:GetKeyboardMap ():Clone ())
	self.Input:GetKeyboardMap ():Register (KEY_ENTER,
		function (_, key, ctrl, shift, alt)
			local code = self.Input:GetText ()
			
			if #code == 0 then return end
			
			-- Input history
			if self.InputHistory [#self.InputHistory] ~= code then
				self.InputHistory [#self.InputHistory + 1] = code
			end
			self.InputHistoryPosition = #self.InputHistory + 1
			
			-- Execute
			self:Execute (code)
			
			self.Input:SetText ("")
		end
	)
	self.Input:GetKeyboardMap ():UnregisterAll (KEY_UP)
	self.Input:GetKeyboardMap ():Register (KEY_UP,
		function (_, key, ctrl, shift, alt)
			if self.InputHistoryPosition == 1 then return false end
			
			self.InputHistoryPosition = self.InputHistoryPosition - 1
			self.Input:SetText (self.InputHistory [self.InputHistoryPosition])
		end
	)
	self.Input:GetKeyboardMap ():UnregisterAll (KEY_DOWN)
	self.Input:GetKeyboardMap ():Register (KEY_DOWN,
		function (_, key, ctrl, shift, alt)
			if self.InputHistoryPosition == #self.InputHistory + 1 then return false end
			
			self.InputHistoryPosition = self.InputHistoryPosition + 1
			self.Input:SetText (self.InputHistory [self.InputHistoryPosition] or "")
		end
	)
	
	-- Execution
	self.HostId = nil
	self.Language = nil
	self.ExecutionContext = nil
	self.NextExecutionId = 0
	
	self:SetHostId ("Self")
	self:SetLanguage ("GLua")
	
	-- Output formatting
	self.OutputEmpty = true
	self.LastOutputType = nil
	self.LastOutputId   = nil
	
	-- Buffering
	self.BufferText        = {}
	self.BufferColor       = nil
	self.BufferDocumentId  = nil
	self.BufferDocumentUri = nil
end

function self:dtor ()
	if self.ExecutionContext then
		self.ExecutionContext:dtor ()
		self.ExecutionContext = nil
	end
	
	self.ContextMenu:dtor ()
	self.UserMenu:dtor ()
end

function self:Clear ()
	self:Flush ()
	self.Output:Clear ()
	self.OutputEmpty = true
end

-- Persistance
function self:LoadSession (inBuffer)
	local hostId = inBuffer:StringN16 ()
	if hostId ~= "" then self:SetHostId (hostId) end
	
	local language = inBuffer:StringN16 ()
	if language ~= "" then self:SetLanguage (language) end
end

function self:SaveSession (outBuffer)
	outBuffer:StringN16 (self:GetHostId ())
	outBuffer:StringN16 (self:GetLanguage ())
end

-- Execution
function self:Execute (code)
	if GLib.CallSelfInThread () then return end
	
	local returnCode
	
	local executionId = self.NextExecutionId
	self.NextExecutionId = self.NextExecutionId + 1
	
	-- Check if the execution context is still valid
	if self.ExecutionContext and
	   self.ExecutionContext:IsDisposed () then
		self.ExecutionContext = nil
	end
	
	if not self.ExecutionContext then
		local executionContext, returnCode = GCompute.Execution.ExecutionService:CreateExecutionContext (GLib.GetLocalId (), self:GetHostId (), self:GetLanguage (), GCompute.Execution.ExecutionContextOptions.EasyContext + GCompute.Execution.ExecutionContextOptions.Repl)
		
		-- Two execution contexts might be created due to concurrent executions
		-- There can only be one.
		if executionContext then
			if self.ExecutionContext then
				executionContext:dtor ()
			else
				self.ExecutionContext = executionContext
			end
		end
		
		if not self.ExecutionContext then
			self:SetLastOutputType ("Error", executionId)
			if not self:IsOutputEmpty () then self:Append ("\n") end
			if returnCode == GCompute.ReturnCode.NoCarrier then
				self:Append ("NO CARRIER", GLib.Colors.IndianRed)
			else
				self:Append ("Failed to create the execution context (" .. (GCompute.ReturnCode [returnCode] or returnCode) .. ").", GLib.Colors.IndianRed)
			end
			return
		end
	end
	
	-- Code
	self:SetLastOutputType ("Code", executionId)
	if not self:IsOutputEmpty () then self:Append ("\n") end
	self:Append (code, GLib.Colors.White)
	
	local executionInstance, returnCode = self.ExecutionContext:CreateExecutionInstance (code, nil, GCompute.Execution.ExecutionInstanceOptions.CaptureOutput + GCompute.Execution.ExecutionInstanceOptions.ExecuteImmediately)
	if not executionInstance then
		if self:SetLastOutputType ("Error", executionId) then
			if not self:IsOutputEmpty () then self:Append ("\n") end
			self:Append ("\t")
		end
		if returnCode == GCompute.ReturnCode.NoCarrier then
			self:Append ("NO CARRIER", GLib.Colors.IndianRed)
		else
			self:Append ("Failed to create the execution instance (" .. (GCompute.ReturnCode [returnCode] or returnCode) .. ").", GLib.Colors.IndianRed)
		end
		return
	end
	
	-- Output
	executionInstance:GetStdOut ():AddEventListener ("Text",
		function (_, text, color)
			color = color or GLib.Colors.White
			
			-- Translate color
			local colorId = GCompute.SyntaxColoring.PlaceholderSyntaxColoringScheme:GetIdFromColor (color)
			if colorId then
				color = GCompute.SyntaxColoring.DefaultSyntaxColoringScheme:GetColor (colorId) or color
			end
			
			if self:SetLastOutputType ("StdOut", executionId) then
				if not self:IsOutputEmpty () then self:Append ("\n") end
				self:Append ("\t")
			end
			
			self:Append (string.gsub (string.gsub (text, "[\r\n]", "%1\t"), "\r\t\n", "\r\n"), color)
		end
	)
	
	executionInstance:GetStdErr ():AddEventListener ("Text",
		function (_, text, color)
			color = color or GLib.Colors.IndianRed
			
			if self:SetLastOutputType ("StdErr", executionId) then
				if not self:IsOutputEmpty () then self:Append ("\n") end
				self:Append ("\t")
			end
			
			self:Append (string.gsub (string.gsub (text, "[\r\n]", "%1\t"), "\r\t\n", "\r\n"), color)
		end
	)
	
	executionInstance:GetCompilerStdErr ():AddEventListener ("Text",
		function (_, text, color)
			color = color or GLib.Colors.IndianRed
			
			if self:SetLastOutputType ("CompilerStdErr", executionId) then
				if not self:IsOutputEmpty () then self:Append ("\n") end
				self:Append ("\t")
			end
			
			self:Append (string.gsub (string.gsub (text, "[\r\n]", "%1\t"), "\r\t\n", "\r\n"), color)
		end
	)
end

function self:GetHostId ()
	return self.HostId
end

function self:GetLanguage ()
	return self.Language
end

function self:SetHostId (hostId)
	if self.HostId == hostId then return self end
	
	self.HostComboBox:SetSelectedItem (hostId)
	self.HostId = hostId
	
	if self.ExecutionContext then
		self.ExecutionContext:dtor ()
		self.ExecutionContext = nil
	end
	
	if hostId and not self.HostComboBox:GetItemById (hostId) then
		local ply = GCompute.PlayerMonitor:GetUserEntity (hostId)
		local isAdmin = ply and ply:IsValid () and ply:IsAdmin ()
		local displayName = GCompute.PlayerMonitor:GetUserName (hostId)
		
		if ply then
			self.HostComboBox:SetText (displayName)
			self.HostComboBox:SetIcon (isAdmin and "icon16/shield_go.png" or "icon16/user_go.png")
		else
			self.HostComboBox:SetText (hostId)
			self.HostComboBox:SetIcon ("icon16/cross.png")
		end
	end
	
	return self
end

function self:SetLanguage (language)
	if self.Language == language then return self end
	
	self.LanguageComboBox:SetSelectedItem (language)
	self.Language = language
	
	if self.Input then
		self.Input:SetLanguage (GCompute.Languages.Get (language))
	end
	
	if self.ExecutionContext then
		self.ExecutionContext:dtor ()
		self.ExecutionContext = nil
	end
	
	return self
end

function self:Focus ()
	self.Input:Focus ()
end

function self:GetEditor ()
	if self.Input:ContainsFocus () then return self.Input end
	return self.Output
end

-- Output
function self:Append (text, color, sourceDocumentId, sourceDocumentUri)
	if not text then return end
	
	if self.BufferDocumentId ~= sourceDocumentId or
	   self.BufferDocumentUri ~= sourceDocumentUri or
	   not self:ColorEquals (self.BufferColor, color) then
		self:Flush ()
		
		self.BufferColor       = color
		self.BufferDocumentId  = sourceDocumentId
		self.BufferDocumentUri = sourceDocumentUri
	end
	
	self.BufferText [#self.BufferText + 1] = text
	
	self.OutputEmpty = false
end

function self:GetLastOutputType ()
	return self.LastOutputType
end

function self:Flush ()
	if #self.BufferText > 0 then
		local codeEditor = self.Output
		local document = codeEditor:GetDocument ()
		local startPos = document:GetEnd ()
		codeEditor:Append (table.concat (self.BufferText), true)
		local endPos = document:GetEnd ()
		if self.BufferColor then
			document:SetColor (self.BufferColor, startPos, endPos)
		end
		document:SetAttribute ("SourceDocumentId", self.BufferDocumentId, startPos, endPos)
		document:SetAttribute ("SourceDocumentUri", self.BufferDocumentUri, startPos, endPos)
	end
	
	self.BufferText        = {}
	self.BufferColor       = nil
	self.BufferDocumentId  = nil
	self.BufferDocumentUri = nil
end

function self:IsOutputEmpty ()
	return self.OutputEmpty
end

function self:SetLastOutputType (outputType, outputId)
	if self.LastOutputType == outputType and
	   self.LastOutputId   == outputId then
		return false
	end
	
	self.LastOutputType = outputType
	self.LastOutputId   = outputId
	
	return true
end

-- Components
function self:GetClipboardTarget ()
	return self.ClipboardTarget
end

-- Event handlers
function self:PerformLayout (w, h)
	local inputHeight = math.max (self.HostComboBox:GetHeight (), self.Input:GetLineHeight ())

	self.Output:SetSize (w, h - inputHeight - 4)
	self.Output:SetPos (0, 0)
	
	self.HostComboBox:SetWidth (128)
	self.HostComboBox:SetPos (0, h - inputHeight / 2 - self.HostComboBox:GetHeight () / 2)
	
	self.LanguageComboBox:SetWidth (128)
	self.LanguageComboBox:SetPos (self.HostComboBox:GetWidth () + 4, h - inputHeight / 2 - self.LanguageComboBox:GetHeight () / 2)
	
	self.Input:SetSize (w - self.HostComboBox:GetWidth () - 4 - self.LanguageComboBox:GetWidth () - 4, self.Input:GetLineHeight ())
	self.Input:SetPos (self.HostComboBox:GetWidth () + 4 + self.LanguageComboBox:GetWidth () + 4, h - inputHeight / 2 - self.Input:GetHeight () / 2)
end

function self:Think ()
	self:Flush ()
end

-- Internal, do not call
function self:BringUpView (view, startLine, char, endLine)
	if GLib.CallSelfInThread () then return end
	
	if not view then return end
	view:Select ()
	
	char = char or 1
	if not startLine then return end
	if view:GetType () ~= "Code" then return end
	
	if endLine then
		GLib.Yield ()
		local location = GCompute.CodeEditor.LineCharacterLocation (endLine - 1, char and (char - 1) or 0)
		location = view:GetEditor ():GetDocument ():CharacterToColumn (location, view:GetEditor ():GetTextRenderer ())
			
		view:GetEditor ():SetCaretPos (location)
		view:GetEditor ():SetSelection (view:GetEditor ():GetCaretPos ())
		view:GetEditor ():ScrollToCaret ()
	end
	
	GLib.Yield ()
	local location = GCompute.CodeEditor.LineCharacterLocation (startLine - 1, char and (char - 1) or 0)
	location = view:GetEditor ():GetDocument ():CharacterToColumn (location, view:GetEditor ():GetTextRenderer ())
		
	view:GetEditor ():SetCaretPos (location)
	view:GetEditor ():SetSelection (view:GetEditor ():GetCaretPos ())
	view:GetEditor ():ScrollToCaret ()
end

function self:ColorEquals (a, b)
	if a == nil and b == nil then return true end
	if     a and not b then return false end
	if not a and     b then return false end
	if a.r ~= b.r then return false end
	if a.g ~= b.g then return false end
	if a.b ~= b.b then return false end
	if a.a ~= b.a then return false end
	return true
end