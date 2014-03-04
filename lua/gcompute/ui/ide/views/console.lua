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
			local lineColumnLocation = self.Output:PointToLocation (x, y)
			local line = self.Output:GetDocument ():GetLine (lineColumnLocation:GetLine ())
			if not line then return end
			local lineText = line:GetText ()
			local sourceDocumentId = line:GetAttribute ("SourceDocumentId", 0)
			local sourceDocumentUri = line:GetAttribute ("SourceDocumentUri", 0)
			
			-- Attempt to get line, char information
			-- line %d, char %d
			
			local lowercaseLineText = lineText:lower ()
			local pathMatch = nil
			local lineMatch, charMatch = lowercaseLineText:match ("line[ \t]*([0-9]+),?[ \t]*char[ \t]*([0-9]+)")
			if not lineMatch then
				lineMatch, charMatch = lowercaseLineText:match ("line[ \t]*([0-9]+),?[ \t]*character[ \t]*([0-9]+)")
			end
			if not lineMatch then
				lineMatch = lowercaseLineText:match ("line[ \t]*([0-9]+)")
			end
			if not lineMatch then
				-- debug.Trace style stack trace
				pathMatch, lineMatch = lowercaseLineText:match ("lua/(.*):([0-9]+): ")
			end
			if not lineMatch then
				-- GLib style stack trace
				pathMatch, lineMatch = lowercaseLineText:match ("lua/(.*): ([0-9]+)[%)%]]")
			end
			if not lineMatch then
				lineMatch = lowercaseLineText:match (":([0-9]+): ")
			end
			
			local line = tonumber (lineMatch)
			local char = tonumber (charMatch)
			if not line then return end
			
			if pathMatch then
				sourceDocumentId = nil
				sourceDocumentUri = "luacl/" .. pathMatch
			end
			
			local document = self:GetDocumentManager ():GetDocumentById (sourceDocumentId)
			local view = nil
			if not document then
				document = self:GetDocumentManager ():GetDocumentByUri (sourceDocumentUri)
			end
			if not document and sourceDocumentUri and sourceDocumentUri ~= nil then
				self:GetIDE ():OpenUri (sourceDocumentUri,
					function (success, resource, view)
						self:BringUpView (view, line, char)
					end
				)
				return
			elseif document then
				view = document:GetView (1)
			end
			
			if not view then return end
			self:BringUpView (view, line, char)
		end
	)
	
	self.ClipboardTarget = GCompute.CodeEditor.EditorClipboardTarget (self.Output)
	
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
					self:Append ("\t" .. string.gsub (message, "\n", "\n\t") .. "\n\t" .. string.gsub (stackTrace, "\n", "\n\t"), GLib.Colors.IndianRed, sourceId)
				end
			)
			luaOutputSink:AddEventListener ("Output",
				function (_, sourceId, userId, message, color)
					self:Append (string.gsub (message, "\n", "\n\t"), color or GLib.Colors.White, sourceId)
				end
			)
			
			local code = self.Input:GetText ()
			luaOutputSink:AddEventListener ("SyntaxError",
				function (_, sourceId, message)
					self:Append ("\t" .. string.gsub (message, "\n", "\n\t") .. "\n", GLib.Colors.IndianRed, sourceId)
				end
			)
			
			self:Append (code .. "\n", GLib.Colors.White, sourceId)
			local ret = luaSession:Execute ("@repl", nil, "return " .. code, luaOutputSink)
			if not ret.Success then
				ret = luaSession:Execute ("@repl", nil, code, luaOutputSink)
			end
			if ret.Success then
				self:Append ("\t" .. string.gsub (GLib.Lua.ToLuaString (ret [1]), "\n", "\n\t") .. "\n", GLib.Colors.White, sourceId)
			end
			
			self.Input:SetText ("")
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
	self:GetEditor ():Clear ()
end

function self:Flush ()
	if #self.BufferText > 0 then
		local codeEditor = self:GetEditor ()
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
function self:BringUpView (view, line, char)
	if not view then return end
	view:Select ()
	
	if view:GetType () ~= "Code" then return end
	
	local location = GCompute.CodeEditor.LineCharacterLocation (line - 1, char and (char - 1) or 0)
	location = view:GetEditor ():GetDocument ():CharacterToColumn (location, view:GetEditor ():GetTextRenderer ())
	view:GetEditor ():SetCaretPos (location)
	view:GetEditor ():SetSelection (view:GetEditor ():GetCaretPos ())
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