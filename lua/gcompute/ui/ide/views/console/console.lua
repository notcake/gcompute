local self, info = GCompute.IDE.ViewTypes:CreateType ("Console")
info:SetAutoCreate (true)
info:SetDefaultLocation ("Bottom")
self.Title    = "Console"
self.Icon     = "icon16/application_xp_terminal.png"
self.Hideable = true

function self:ctor (container)
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
				luaPath, startLineMatch, endLineMatch = string.match (lowercaseLineText, "lua/(.*): ?([0-9]+)%-([0-9]+)")
			end
			if not startLineMatch then
				luaPath, startLineMatch = string.match (lowercaseLineText, "lua/(.*): ?([0-9]+)")
			end
			if not startLineMatch then
				luaPath, startLineMatch, endLineMatch = string.match (lowercaseLineText, "gamemodes/(.*): ?([0-9]+)%-([0-9]+)")
			end
			if not startLineMatch then
				luaPath, startLineMatch = string.match (lowercaseLineText, "gamemodes/(.*): ?([0-9]+)")
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
	
	self.NextInputId = 0
	self.InputHistory = {}
	self.InputHistoryPosition = 1
	
	self.Input = vgui.Create ("GComputeCodeEditor", container)
	self.Input:SetMultiline (false)
	self.Input:SetLineNumbersVisible (false)
	
	self.Input:SetKeyboardMap (self.Input:GetKeyboardMap ():Clone ())
	self.Input:GetKeyboardMap ():Register (KEY_ENTER,
		function (_, key, ctrl, shift, alt)
			local luaSession = GCompute.LocalLuaSession ()
			local luaOutputSink = GCompute.LuaOutputSink ()
			luaOutputSink:AddEventListener ("Error",
				function (_, sourceId, userId, message, stackTrace)
					local stackTraceString = stackTrace:ToString ()
					self:Append ("\t" .. string.gsub (message, "\n", "\n\t") .. "\n\t" .. string.gsub (stackTraceString, "\n", "\n\t") .. "\n", GLib.Colors.IndianRed, sourceId)
				end
			)
			
			local firstOutput = true
			luaOutputSink:AddEventListener ("Output",
				function (_, sourceId, userId, message, color)
					if firstOutput then
						self:Append ("\t", GLib.Colors.White, sourceId)
						firstOutput = false
					end
					self:Append (string.gsub (message, "\n", "\n\t"), color or GLib.Colors.White, sourceId)
				end
			)
			
			local code = self.Input:GetText ()
			
			-- Input history
			self.InputHistory [#self.InputHistory + 1] = self.Input:GetText ()
			self.InputHistoryPosition = #self.InputHistory + 1
			
			local syntaxError = false
			luaOutputSink:AddEventListener ("SyntaxError",
				function (_, sourceId, message)
					syntaxError = true
					self:Append ("\t" .. string.gsub (message, "\n", "\n\t") .. "\n", GLib.Colors.IndianRed, sourceId)
					firstOutput = true
				end
			)
			
			self:Append (code .. "\n", GLib.Colors.White, sourceId)
			
			-- Input Id
			local inputId = "@repl_" .. tostring (self.NextInputId)
			self.NextInputId = self.NextInputId + 1
			
			local ret = luaSession:Execute (inputId, nil, "return " .. code, luaOutputSink)
			if syntaxError then
				ret = luaSession:Execute (inputId, nil, code, luaOutputSink)
			end
			if ret.Success then
				local pipe = GCompute.Pipe ()
				pipe:AddEventListener ("Data",
					function (_, data, color)
						if firstOutput then
							self:Append ("\t", GLib.Colors.White, sourceId)
							firstOutput = false
						end
						self:Append (string.gsub (data, "\n", "\n\t"), color, sourceId)
					end
				)
				
				GCompute.IDE.Console.Printer (pipe):Print (ret [1])
				self:Append ("\n", GLib.Colors.White, sourceId)
				firstOutput = true
				
				for i = 2, table.maxn (ret) do
					GCompute.IDE.Console.Printer (pipe):Print (ret [i])
					self:Append ("\n", GLib.Colors.White, sourceId)
					firstOutput = true
				end
			end
			
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
	
	-- Buffering
	self.BufferText        = {}
	self.BufferColor       = nil
	self.BufferDocumentId  = nil
	self.BufferDocumentUri = nil
end

function self:dtor ()
	self.ContextMenu:dtor ()
end

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
end

function self:Clear ()
	self:Flush ()
	self.Output:Clear ()
end

function self:Focus ()
	self.Input:Focus ()
end

function self:Flush ()
	if #self.BufferText > 0 then
		local codeEditor = self.Output
		local document = codeEditor:GetDocument ()
		local startPos = document:GetEnd ()
		codeEditor:Append (table.concat (self.BufferText))
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

function self:GetEditor ()
	if self.Input:ContainsFocus () then return self.Input end
	return self.Output
end

-- Components
function self:GetClipboardTarget ()
	return self.ClipboardTarget
end

-- Event handlers
function self:PerformLayout (w, h)
	self.Input:SetSize (w, self.Input:GetLineHeight ())
	self.Input:SetPos (0, h - self.Input:GetTall ())
	self.Output:SetSize (w, h - self.Input:GetTall () - 4)
	self.Output:SetPos (0, 0)
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