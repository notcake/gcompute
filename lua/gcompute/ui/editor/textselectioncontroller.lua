local self = {}
GCompute.Editor.TextSelectionController = GCompute.MakeConstructor (self)

function self:ctor (codeEditor, textSelection)
	self.Editor    = codeEditor
	self.Selection = textSelection
	
	self.InSelection = false
	self.InWordSelection = false
	self.InLineSelection = false
	
	self.InitialSelectionStart = GCompute.Editor.LineColumnLocation ()
	self.InitialSelectionEnd   = GCompute.Editor.LineColumnLocation ()
	
	self.LastLeftMouseDownTime = 0
	self.LastDoubleLeftMouseDownTime = 0
	codeEditor:AddEventListener ("MouseDown", "TextSelectionController",
		function (_, mouseCode, x, y)
			local control = input.IsKeyDown (KEY_LCONTROL) or input.IsKeyDown (KEY_RCONTROL)
			local shift   = input.IsKeyDown (KEY_LSHIFT)   or input.IsKeyDown (KEY_RSHIFT)
			local alt     = input.IsKeyDown (KEY_LALT)     or input.IsKeyDown (KEY_RALT)
			
			local rawLineColumnLocation = self.Editor:PointToRawLocationClamp (x, y)
			local lineColumnLocation = self.Editor:PointToLocation (x, y)
			if mouseCode == MOUSE_LEFT then
				local clickedOnLineNumbers = self.Editor:AreLineNumbersVisible () and x <= self.Editor.Settings.LineNumberWidth
				if clickedOnLineNumbers then
					self:CopyInitialSelection ()
					self:ConvertToRegularSelection (lineColumnLocation:GetLine ())
					
					self.Selection:SetSelectionMode (GCompute.Editor.SelectionMode.Regular)
					self:SelectLine (lineColumnLocation:GetLine (), shift)
					self.Editor:SetRawCaretPos (self.Selection:GetSelectionEnd ())
					
					self.InLineSelection = true
				else
					if SysTime () - self.LastDoubleLeftMouseDownTime < 0.4 then
						self:ConvertToRegularSelection (lineColumnLocation:GetLine ())
						self.Selection:SetSelectionMode (GCompute.Editor.SelectionMode.Regular)
						self:SelectLine (lineColumnLocation:GetLine (), shift)
						self.Editor:SetRawCaretPos (self.Selection:GetSelectionEnd ())
						
						self.InLineSelection = true
						self.LastDoubleLeftMouseDownTime = 0
					elseif SysTime () - self.LastLeftMouseDownTime < 0.4 then
						self:ConvertToRegularSelection (lineColumnLocation:GetLine ())
						self.Selection:SetSelectionMode (GCompute.Editor.SelectionMode.Regular)
						self:SelectWord (rawLineColumnLocation, shift)
						self.Editor:SetRawCaretPos (self.Selection:GetSelectionEnd ())
						
						self.InWordSelection = true
						self.LastDoubleLeftMouseDownTime = SysTime ()
						self.LastLeftMouseDownTime = 0
					else
						self:CopyInitialSelection ()
						
						if not shift or alt then
							self.Selection:SetSelectionMode (alt and GCompute.Editor.SelectionMode.Block or GCompute.Editor.SelectionMode.Regular)
							lineColumnLocation = self.Editor:PointToLocation (x, y)
						end
						self.Editor:SetRawCaretPos (lineColumnLocation)
						self:SelectLocation (self.Editor:GetCaretPos (), shift)
						
						self.InSelection = true
						self.LastLeftMouseDownTime = SysTime ()
					end
				end
				
				if not shift then
					self:CopyInitialSelection ()
				end
				self.Editor:MouseCapture (true)
			elseif mouseCode == MOUSE_RIGHT then
				if not self.Selection:IsInSelection (lineColumnLocation) then
					self.Editor:SetRawCaretPos (lineColumnLocation)
					self:SelectLocation (self.Editor:GetCaretPos ())
				end
			end
		end
	)
	codeEditor:AddEventListener ("MouseMove", "TextSelectionController",
		function (_, mouseCode, x, y)
			if self.InSelection then
				self.Editor:SetRawCaretPos (self.Editor:PointToLocation (x, y))
				
				self:SelectLocation (self.Editor:GetCaretPos (), true)
			elseif self.InWordSelection then
				self:SelectWord (self.Editor:PointToRawLocationClamp (x, y), true)
				self.Editor:SetRawCaretPos (self.Selection:GetSelectionEnd ())
			elseif self.InLineSelection then
				self:SelectLine (self.Editor:PointToLocation (x, y):GetLine (), true)
				self.Editor:SetRawCaretPos (self.Selection:GetSelectionEnd ())
			elseif self.Editor:AreLineNumbersVisible () and x <= self.Editor.Settings.LineNumberWidth then
				self.Editor:SetCursor ("arrow")
			else
				self.Editor:SetCursor ("beam")
			end
		end
	)
	codeEditor:AddEventListener ("MouseUp", "TextSelectionController",
		function (_, mouseCode, x, y)
			self.InSelection = false
			self.InWordSelection = false
			self.InLineSelection = false
			
			self.Editor:MouseCapture (false)
		end
	)
end

function self:ConvertToRegularSelection (preferredLine)
	if self.Selection:GetSelectionMode () == GCompute.Editor.SelectionMode.Block then
		self.Selection:SetSelectionMode (GCompute.Editor.SelectionMode.Regular)
		
		preferredLine = math.Clamp (
			preferredLine or self.InitialSelectionEnd:GetLine (),
			math.min (self.InitialSelectionStart:GetLine (), self.InitialSelectionEnd:GetLine ()),
			math.max (self.InitialSelectionStart:GetLine (), self.InitialSelectionEnd:GetLine ())
		)
		self.InitialSelectionStart:SetLine (preferredLine)
		self.InitialSelectionEnd:SetLine (preferredLine)
		self.InitialSelectionStart:SetColumn (self.Editor:FixupColumn (preferredLine, self.InitialSelectionStart:GetColumn ()))
		self.InitialSelectionEnd:SetColumn (self.Editor:FixupColumn (preferredLine, self.InitialSelectionEnd:GetColumn ()))
		
		self.Selection:SetSelectionStart (self.InitialSelectionStart)
		self.Selection:SetSelectionEnd (self.InitialSelectionEnd)
	end
end

function self:CopyInitialSelection ()
	self.InitialSelectionStart:CopyFrom (self.Selection:GetSelectionStart ())
	self.InitialSelectionEnd:CopyFrom (self.Selection:GetSelectionEnd ())
end

function self:SelectLocation (lineColumnLocation, modifySelection)
	if modifySelection then
		self.Selection:SetSelectionEnd (lineColumnLocation)
	else
		self.Selection:SetSelection (lineColumnLocation)
	end
end

function self:SelectLine (line, modifySelection)
	local spanStart = GCompute.Editor.LineColumnLocation (line, 0)
	local spanEnd
	if self.Editor.Document:GetLine (line + 1) then
		spanEnd = GCompute.Editor.LineColumnLocation (line + 1, 0)
	else
		spanEnd = GCompute.Editor.LineColumnLocation (line, self.Editor.Document:GetLine (line):GetColumnCount (self.Editor:GetTextRenderer ()))
	end
	
	self:SelectSpan (spanStart, spanEnd, modifySelection)
	if true then return end
end

function self:SelectSpan (spanStart, spanEnd, modifySelection)
	if modifySelection then
		local mergedSpanStart = spanStart
		local mergedSpanEnd   = spanEnd
		local mergedStart = false
		local mergedEnd   = false
		if self.InitialSelectionStart < mergedSpanStart then mergedSpanStart = self.InitialSelectionStart end
		if self.InitialSelectionEnd   < mergedSpanStart then mergedSpanStart = self.InitialSelectionEnd   end
		if self.InitialSelectionStart > mergedSpanEnd   then mergedSpanEnd   = self.InitialSelectionStart end
		if self.InitialSelectionEnd   > mergedSpanEnd   then mergedSpanEnd   = self.InitialSelectionEnd   end
		
		if spanStart < self.InitialSelectionStart and spanStart < self.InitialSelectionEnd then
			mergedStart = true
		end
		if spanEnd > self.InitialSelectionStart and spanEnd > self.InitialSelectionEnd then
			mergedEnd = true
		end
		if (mergedStart and not mergedEnd) or
		   (not mergedStart and not mergedEnd and self.InitialSelectionStart > self.InitialSelectionEnd) then
			local temp = mergedSpanStart
			mergedSpanStart = mergedSpanEnd
			mergedSpanEnd = temp
		end
		self.Selection:SetSelection (mergedSpanStart, mergedSpanEnd)
	else
		self.Selection:SetSelection (spanStart, spanEnd)
	end
end

function self:SelectWord (lineColumnLocation, modifySelection)
	local line = self.Editor:GetDocument ():GetLine (lineColumnLocation:GetLine ())
	local location
	if lineColumnLocation:GetColumn () > 0 and lineColumnLocation:GetColumn () >= line:GetColumnCount (self.Editor.TextRenderer) then
		location = self.Editor:GetDocument ():ColumnToCharacter (GCompute.Editor.LineColumnLocation (lineColumnLocation:GetLine (), line:GetColumnCount (self.Editor.TextRenderer) - 1), self.Editor:GetTextRenderer ())
	else
		location = self.Editor:GetDocument ():ColumnToCharacter (lineColumnLocation, self.Editor:GetTextRenderer ())
	end
	local text = line:GetText ()
	local offset = GLib.UTF8.CharacterToOffset (text, location:GetCharacter () + 1)
	local previousWordBoundary = GLib.UTF8.PreviousWordBoundary (text, offset + string.len (GLib.UTF8.NextChar (text, offset))) or 1
	local nextWordBoundary = GLib.UTF8.NextWordBoundary (text, offset)
	local leftCharacter = location:GetCharacter () - GLib.UTF8.Length (string.sub (text, previousWordBoundary, offset - 1))
	local rightCharacter = location:GetCharacter () + GLib.UTF8.Length (string.sub (text, offset, nextWordBoundary - 1))
	
	self:SelectSpan (
		GCompute.Editor.LineColumnLocation (location:GetLine (), line:CharacterToColumn (leftCharacter,  self.Editor:GetTextRenderer ())),
		GCompute.Editor.LineColumnLocation (location:GetLine (), line:CharacterToColumn (rightCharacter, self.Editor:GetTextRenderer ())),
		modifySelection
	)
end