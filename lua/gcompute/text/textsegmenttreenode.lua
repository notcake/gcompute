local self = {}
GCompute.TextSegmentTreeNode = GCompute.MakeConstructor (self, GCompute.Containers.BinaryTreeNode)

function self:ctor (text)
	self.BinaryTreeNode = GCompute.TextSegmentTreeNode
	
	self.CharacterCount                        = 0
	self.CharacterCountExcludingLineBreak      = 0
	self.LastLineCharacterCount                = 0
	self.LineBreakCount                        = 0
	self.CharacterCountsValid                  = false
	
	self.TotalCharacterCount                   = 0
	self.TotalCharacterCountExcludingLineBreak = 0
	self.TotalLastLineCharacterCount           = 0
	self.TotalLineBreakCount                   = 0
	self.TotalCharacterCountsValid             = false
	
	self.Text = ""
	
	if text and text ~= "" then
		self:SetText (text)
	end
end

function self:AppendText (text)
	self.Text = self.Text .. text
	
	self:InvalidateCacheUpwards ()
end

function self:CalculateCharacterCounts ()
	if self.CharacterCountsValid then return end
	
	self.CharacterCount = GLib.UTF8.Length (self.Text)
	self.CharacterCountExcludingLineBreak = self.CharacterCount
	
	local char, offset = GLib.UTF8.PreviousChar (self.Text)
	while char == "\r" or char == "\n" do
		self.CharacterCountExcludingLineBreak = self.CharacterCountExcludingLineBreak - 1
		char, offset = GLib.UTF8.PreviousChar (self.Text, offset)
	end
	
	self.LineBreakCount = 0
	
	local offset = 1
	while offset <= self.Text:len () + 1 do
		local crOffset = self.Text:find ("\r", offset, true)
		local lfOffset = self.Text:find ("\n", offset, true)
		local newlineOffset = crOffset or lfOffset
		if crOffset and crOffset < newlineOffset then newlineOffset = crOffset end
		if lfOffset and lfOffset < newlineOffset then newlineOffset = lfOffset end
		if newlineOffset then
			if self.Text:sub (newlineOffset, newlineOffset + 1) == "\r\n" then
				self.LineBreakCount = self.LineBreakCount + 1
				offset = newlineOffset + 2
			else
				self.LineBreakCount = self.LineBreakCount + 1
				offset = newlineOffset + 1
			end
		else
			-- End of text, no more line breaks found
			self.LastLineCharacterCount = GLib.UTF8.Length (self.Text:sub (offset))
			break
		end
	end
	
	self.CharacterCountsValid = true
end

function self:CalculateTotalCharacterCounts ()
	if self.TotalCharacterCountsValid then return end
	
	self.TotalCharacterCount                   = 0
	self.TotalCharacterCountExcludingLineBreak = 0
	self.TotalLineBreakCount                   = 0
	self.TotalLastLineCharacterCount           = 0
	
	-- Left
	if self.Left then
		self.Left:CalculateTotalCharacterCounts ()
		self.TotalCharacterCount = self.Left.TotalCharacterCount
		self.TotalCharacterCountExcludingLineBreak = self.TotalCharacterCount
		if self.Left.TotalLineBreakCount == 0 then
			self.TotalLastLineCharacterCount = self.Left.TotalLastLineCharacterCount
		else
			self.TotalLineBreakCount = self.Left.TotalLineBreakCount
			self.TotalLastLineCharacterCount = self.Left.TotalLastLineCharacterCount
		end
	end
	
	-- This
	self:CalculateCharacterCounts ()
	self.TotalCharacterCount = self.TotalCharacterCount + self.CharacterCount
	if self.LineBreakCount == 0 then
		self.TotalLastLineCharacterCount = self.TotalLastLineCharacterCount + self.LastLineCharacterCount
	else
		self.TotalLineBreakCount = self.TotalLineBreakCount + self.LineBreakCount
		self.TotalLastLineCharacterCount = self.LastLineCharacterCount
	end
	
	-- Right
	if self.Right then
		self.Right:CalculateTotalCharacterCounts ()
		self.TotalCharacterCount = self.TotalCharacterCount + self.Right.TotalCharacterCount
		self.TotalCharacterCountExcludingLineBreak = self.TotalCharacterCountExcludingLineBreak + self.CharacterCount + self.Right.TotalCharacterCountExcludingLineBreak
		if self.Right.TotalLineBreakCount == 0 then
			self.TotalLastLineCharacterCount = self.TotalLastLineCharacterCount + self.Right.TotalLastLineCharacterCount
		else
			self.TotalLineBreakCount = self.TotalLineBreakCount + self.Right.TotalLineBreakCount
			self.TotalLastLineCharacterCount = self.Right.TotalLastLineCharacterCount
		end
	else
		self.TotalCharacterCountExcludingLineBreak = self.TotalCharacterCountExcludingLineBreak + self.CharacterCountExcludingLineBreak
	end
	
	self.TotalCharacterCountsValid = true
end

function self:DeleteAfterCharacter (character)
	if character >= self:GetCharacterCount () then return end
	self:SetText (GLib.UTF8.Sub (self.Text, 1, character))
end

function self:DeleteBeforeCharacter (character)
	if character <= 0 then return end
	
	self:SetText (GLib.UTF8.Sub (self.Text, character + 1))
end

function self:DeleteCharacterRange (startCharacter, endCharacter)
	if not endCharacter then self:DeleteAfterCharacter (startCharacter) return end
	if startCharacter == endCharacter then return end
	
	self:SetText (GLib.UTF8.Sub (self.Text, 1, startCharacter) .. GLib.UTF8.Sub (self.Text, endCharacter + 1))
end

function self:GetCharacterCount ()
	if not self.CharacterCountsValid then
		self:CalculateCharacterCounts ()
	end
	return self.CharacterCount
end

function self:GetCharacterCountExcludingLineBreak ()
	if not self.CharacterCountsValid then
		self:CalculateCharacterCounts ()
	end
	return self.CharacterCountExcludingLineBreak
end

function self:GetColor ()
	return self.Color
end

function self:GetLastLineCharacterCount ()
	if not self.CharacterCountsValid then
		self:CalculateCharacterCounts ()
	end
	return self.LastLineCharacterCount
end

function self:GetLineBreakCount ()
	if not self.CharacterCountsValid then
		self:CalculateCharacterCounts ()
	end
	return self.LineBreakCount
end

function self:GetText ()
	return self.Text
end

function self:GetTotalCharacterCount ()
	if not self.TotalCharacterCountsValid then
		self:CalculateTotalCharacterCounts ()
	end
	return self.TotalCharacterCount
end

function self:GetTotalCharacterCountExcludingLineBreak ()
	if not self.TotalCharacterCountsValid then
		self:CalculateTotalCharacterCounts ()
	end
	return self.TotalCharacterCountExcludingLineBreak
end

function self:GetTotalLastLineCharacterCount ()
	if not self.TotalCharacterCountsValid then
		self:CalculateTotalCharacterCounts ()
	end
	return self.TotalLastLineCharacterCount
end

function self:GetTotalLineBreakCount ()
	if not self.TotalCharacterCountsValid then
		self:CalculateTotalCharacterCounts ()
	end
	return self.TotalLineBreakCount
end

function self:InsertAtCharacter (character, text)
	text = text or ""
	if not text then return end
	
	if character <= 0 then
		self.Text = text .. self.Text
	elseif character >= self:GetCharacterCount () then
		self.Text = self.Text .. text
	else
		self.Text = GLib.UTF8.Sub (self.Text, 1, character) .. text .. GLib.UTF8.Sub (self.Text, character + 1)
	end
	
	self:InvalidateCacheUpwards ()
end

function self:InsertNodeAtCharacter (character, node)
	if not node then return end
	
	if character <= 0 then
		self:InsertBefore (node)
	elseif character >= self:GetCharacterCount () then
		self:InsertAfter (node)
	else
		self:SplitAtCharacter (character)
		self:InsertAfter (node)
	end
end

function self:InvalidateAggregateCache ()
	self.TotalCharacterCountsValid = false
end

function self:InvalidateCache ()
	self.CharacterCountsValid = false
end

--- Returns the node which starts at the given character, or contains it.
-- @param textRenderer If given, this node is assumed to be an Editor.TextSegmentTreeNode and the number of columns to the left of the specified character is returned
function self:NodeFromCharacter (character, textRenderer)
	local columnCount = 0
	if self.Left then
		local leftCharacterCount = self.Left:GetTotalCharacterCount ()
		if character == 0 or character < leftCharacterCount then
			return self.Left:NodeFromCharacter (character, textRenderer)
		end
		character = character - leftCharacterCount
		if textRenderer then
			columnCount = self.Left:GetTotalColumnCount (textRenderer)
		end
	end
	
	if character == 0 or character < self:GetCharacterCount () then
		if textRenderer then
			columnCount = columnCount + textRenderer:GetStringColumnCount (GLib.UTF8.Sub (self.Text, 1, character))
		end
		return self, character, columnCount
	end
	character = character - self.CharacterCount
	if textRenderer then
		columnCount = columnCount + self:GetColumnCount (textRenderer)
	end
	
	if self.Right then
		local rightCharacterCount = self.Right:GetTotalCharacterCount ()
		if character == 0 or character < rightCharacterCount then
			local node, character, rightColumnCount = self.Right:NodeFromCharacter (character, textRenderer)
			return node, character, columnCount + rightColumnCount
		end
		character = character - rightCharacterCount
	end
	
	-- Fail
	if textRenderer then
		return nil, character, self:GetTotalColumnCount (textRenderer)
	end
	return nil, character, nil
end

function self:SetColor (color)
	color = color or GLib.Colors.White
	self.Color = color
end

function self:SetText (text)
	if self.Text == text then return end
	
	self.Text = text
	
	self:InvalidateCacheUpwards ()
end

function self:SplitAtCharacter (character)
	if character <= 0 then return self end
	if character >= self:GetCharacterCount () then return self:GetNext () end
	
	local before, after = GLib.UTF8.SplitAt (self.Text, character + 1)
	self.Text = before
	self:InvalidateCache ()
	
	local node = self.BinaryTreeNode (after)
	self:InsertAfter (node)
	
	return node
end

function self:Sub (startCharacter, endCharacter)
	return GLib.UTF8.Sub (self.Text, startCharacter, endCharacter)
end

function self:ToString ()
	return "[" .. tostring (self:GetCharacterCount ()) .. "] \"" .. GLib.String.Escape (self.Text) .. "\""
end