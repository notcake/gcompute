local self = {}
GCompute.CodeEditor.TextSelection = GCompute.MakeConstructor (self)

--[[
	Events:
		SelectedChanged (LineColumnLocation selectionStart, LineColumnLocation selectionEnd)
			Fired when the selection has changed.
]]

function self:ctor (codeEditor)
	self.Editor = codeEditor
	
	self.SelectionMode  = GCompute.CodeEditor.SelectionMode.Regular
	self.SelectionStart = GCompute.CodeEditor.LineColumnLocation (0, 0)
	self.SelectionEnd   = GCompute.CodeEditor.LineColumnLocation (0, 0)
	
	GCompute.EventProvider (self)
end

function self:Clone (clone)
	clone = clone or self.__ictor ()
	
	clone:Copy (self)
	
	return clone
end

function self:Copy (source)
	self.Editor        = source.Editor
	self.SelectionMode = source:GetSelectionMode ()
	self.SelectionStart:Copy (source:GetSelectionStart ())
	self.SelectionEnd  :Copy (source:GetSelectionEnd   ())
	
	self:DispatchEvent ("SelectionChanged")
	
	return self
end

function self:Flatten ()
	if self:GetSelectionMode () == GCompute.CodeEditor.SelectionMode.Block then
		self:SetSelectionMode (GCompute.CodeEditor.SelectionMode.Regular)
		self:SetSelectionStart (
			GCompute.CodeEditor.LineColumnLocation (
				self.SelectionEnd:GetLine (),
				self.Editor:FixupColumn (self.SelectionEnd:GetLine (), self.SelectionStart:GetColumn ())
			)
		)
	end
end

function self:GetLineSpan ()
	if self.SelectionStart > self.SelectionEnd then
		return self.SelectionEnd:GetLine (), self.SelectionStart:GetLine ()
	end
	return self.SelectionStart:GetLine (), self.SelectionEnd:GetLine ()
end

function self:GetSpan (line)
	local spanLine, spanStart, spanEnd = self:GetSpanEnumerator (line) ()
	if spanLine ~= line then return nil, nil end
	return spanStart, spanEnd
end

function self:GetSpanEnumerator (line)
	local selectionStart, selectionEnd = self:GetSelectionEndPoints ()
	local startLine = selectionStart:GetLine ()
	local endLine   = selectionEnd:GetLine ()
	
	local i = (line or startLine) - 1
	if i < startLine - 1 then i = startLine - 1 end
	
	local document = self.Editor:GetDocument ()
	local textRenderer = self.Editor:GetTextRenderer ()
	
	if self.SelectionMode == GCompute.CodeEditor.SelectionMode.Regular then
		if startLine == endLine then
			return function ()
				i = i + 1
				if i ~= endLine then return nil, nil, nil end
				return i, selectionStart:GetColumn (), selectionEnd:GetColumn ()
			end
		end
		return function ()
			i = i + 1
			if i > endLine then return nil, nil, nil end
			if i == startLine then return i, selectionStart:GetColumn (), document:GetLine (startLine):GetColumnCount (textRenderer) + 1 end
			if i == endLine then return i, 0, selectionEnd:GetColumn () end
			return i, 0, document:GetLine (i):GetColumnCount (textRenderer) + 1
		end
	else
		local codeEditor  = self.Editor
		local startColumn = math.min (selectionStart:GetColumn (), selectionEnd:GetColumn ())
		local endColumn   = math.max (selectionStart:GetColumn (), selectionEnd:GetColumn ())
		return function ()
			i = i + 1
			if i > endLine then return nil, nil, nil end
			local columnCount = document:GetLine (i):GetColumnCount (textRenderer)
			return i,
			       startColumn < columnCount and codeEditor:FixupColumn (i, startColumn) or startColumn,
				   endColumn   < columnCount and codeEditor:FixupColumn (i, endColumn)   or endColumn
		end
	end
end

function self:GetSelectionEnd ()
	return self.SelectionEnd
end

function self:GetSelectionEndPoints ()
	if self.SelectionStart > self.SelectionEnd then
		return self.SelectionEnd, self.SelectionStart
	end
	return self.SelectionStart, self.SelectionEnd
end

function self:GetSelectionMode ()
	return self.SelectionMode
end

function self:GetSelectionStart ()
	return self.SelectionStart
end

function self:IsEmpty ()
	return self.SelectionStart == self.SelectionEnd
end

function self:IsInSelection (location)
	if self.SelectionMode == GCompute.CodeEditor.SelectionMode.Regular then
		local selectionStart, selectionEnd = self:GetSelectionEndPoints ()
		return selectionStart <= location and location <= selectionEnd
	elseif self.SelectionMode == GCompute.CodeEditor.SelectionMode.Block then
		local startLine = math.min (self.SelectionStart:GetLine (), self.SelectionEnd:GetLine ())
		local endLine   = math.max (self.SelectionStart:GetLine (), self.SelectionEnd:GetLine ())
		if location:GetLine () < startLine or location:GetLine () > endLine then return false end
		local startColumn = self.Editor:FixupColumn (location:GetLine (), math.min (self.SelectionStart:GetColumn (), self.SelectionEnd:GetColumn ()))
		local endColumn   = self.Editor:FixupColumn (location:GetLine (), math.max (self.SelectionStart:GetColumn (), self.SelectionEnd:GetColumn ()))
		if location:GetColumn () < startColumn or location:GetColumn () > endColumn then return false end
		return true
	else
		GCompute.Error ("TextSelection:IsInSelection : Not implemented for " .. GCompute.CodeEditor.SelectionMode [self.SelectionMode] .. " selection mode.")
	end
end

function self:IsMultiline ()
	return self.SelectionStart:GetLine () ~= self.SelectionEnd:GetLine ()
end

function self:IsSingleLine ()
	return self.SelectionStart:GetLine () == self.SelectionEnd:GetLine ()
end

function self:SetSelection (selectionStart, selectionEnd)
	selectionEnd = selectionEnd or selectionStart
	
	self.SelectionStart:Copy (selectionStart)
	self.SelectionEnd  :Copy (selectionEnd  )
	
	self:DispatchEvent ("SelectionChanged", self.SelectionStart, self.SelectionEnd)
end

function self:SetSelectionEnd (selectionEnd)
	self.SelectionEnd:Copy (selectionEnd)
	
	self:DispatchEvent ("SelectionChanged", self.SelectionStart, self.SelectionEnd)
end

function self:SetSelectionMode (selectionMode)
	if self.SelectionMode == selectionMode then return end
	
	self.SelectionMode = selectionMode
	self:DispatchEvent ("SelectionChanged", self.SelectionStart, self.SelectionEnd)
end

function self:SetSelectionStart (selectionStart)
	self.SelectionStart:Copy (selectionStart)
	
	self:DispatchEvent ("SelectionChanged", self.SelectionStart, self.SelectionEnd)
end