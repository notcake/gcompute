local self = {}
GCompute.Editor.TextSegmentTreeNode = GCompute.MakeConstructor (self, GCompute.TextSegmentTreeNode)
local base = GCompute.GetMetaTable (GCompute.TextSegmentTreeNode)

function self:ctor ()
	self.BinaryTreeNode = GCompute.Editor.TextSegmentTreeNode
	
	self.ColumnCount = 0
	self.LastLineColumnCount = 0
	self.ColumnCountsValid = false
	self.ColumnCountsValidityHash = ""
	
	self.TotalColumnCount = 0
	self.TotalLastLineColumnCount = 0
	self.TotalColumnCountsValid = false
	self.TotalColumnCountsValidityHash = ""
	
	self.Color = GLib.Colors.White
end

function self:CalculateColumnCounts (textRenderer)
	if self.ColumnCountsValid and self.ColumnCountsValidityHash == textRenderer:GetStateHash () then return end
	
	self.ColumnCount = textRenderer:GetStringColumnCount (self.Text)
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
			self.LastLineColumnCount = textRenderer:GetStringColumnCount (self.Text:sub (offset))
			break
		end
	end
	
	self.ColumnCountsValid = true
	self.ColumnCountsValidityHash = textRenderer:GetStateHash ()
end

function self:CalculateTotalColumnCounts (textRenderer)
	if self.TotalColumnCountsValid and self.TotalColumnCountsValidityHash == textRenderer:GetStateHash () then return end
	
	self.TotalColumnCount         = 0
	self.TotalLineBreakCount      = 0
	self.TotalLastLineColumnCount = 0
	
	-- Left
	if self.Left then
		self.Left:CalculateTotalColumnCounts (textRenderer)
		self.TotalColumnCount = self.Left.TotalColumnCount
		if self.Left.TotalLineBreakCount == 0 then
			self.TotalLastLineColumnCount = self.Left.TotalLastLineColumnCount
		else
			self.TotalLineBreakCount = self.Left.TotalLineBreakCount
			self.TotalLastLineColumnCount = self.Left.TotalLastLineColumnCount
		end
	end
	
	-- This
	self:CalculateColumnCounts (textRenderer)
	self.TotalColumnCount = self.TotalColumnCount + self.ColumnCount
	if self.LineBreakCount == 0 then
		self.TotalLastLineColumnCount = self.TotalLastLineColumnCount + self.LastLineColumnCount
	else
		self.TotalLineBreakCount = self.TotalLineBreakCount + self.LineBreakCount
		self.TotalLastLineColumnCount = self.LastLineColumnCount
	end
	
	-- Right
	if self.Right then
		self.Right:CalculateTotalColumnCounts (textRenderer)
		self.TotalColumnCount = self.TotalColumnCount + self.Right.TotalColumnCount
		if self.Right.TotalLineBreakCount == 0 then
			self.TotalLastLineColumnCount = self.TotalLastLineColumnCount + self.Right.TotalLastLineColumnCount
		else
			self.TotalLineBreakCount = self.TotalLineBreakCount + self.Right.TotalLineBreakCount
			self.TotalLastLineColumnCount = self.Right.TotalLastLineColumnCount
		end
	end
	
	self.TotalColumnCountsValid = true
	self.TotalColumnCountsValidityHash = textRenderer:GetStateHash ()
end

function self:CanMergeWith (node)
	return self.Color.r == node.Color.r and
	       self.Color.g == node.Color.g and
		   self.Color.b == node.Color.b and
		   self.Color.a == node.Color.a
end

function self:GetColumnCount (textRenderer)
	if not self.ColumnCountsValid or self.ColumnCountsValidityHash ~= textRenderer:GetStateHash () then
		self:CalculateColumnCounts (textRenderer)
	end
	return self.ColumnCount
end

function self:GetLastLineColumnCount (textRenderer)
	if not self.ColumnCountsValid or self.ColumnCountsValidityHash ~= textRenderer:GetStateHash () then
		self:CalculateColumnCounts (textRenderer)
	end
	return self.LastLineColumnCount
end

function self:GetTotalColumnCount (textRenderer)
	if not self.TotalColumnCountsValid or self.TotalColumnCountsValidityHash ~= textRenderer:GetStateHash () then
		self:CalculateTotalColumnCounts (textRenderer)
	end
	return self.TotalColumnCount
end

function self:GetTotalLastLineColumnCount (textRenderer)
	if not self.TotalColumnCountsValid or self.TotalColumnCountsValidityHash ~= textRenderer:GetStateHash () then
		self:CalculateTotalColumnCounts (textRenderer)
	end
	return self.TotalLastLineColumnCount
end

function self:InvalidateAggregateCache ()
	base.InvalidateAggregateCache (self)
	
	self.TotalColumnCountsValid = false
end

function self:InvalidateCache ()
	base.InvalidateCache (self)
	
	self.ColumnCountsValid = false
end

--- Returns the node which starts at the given column, or contains it.
-- @param column The column
-- @param textRenderer The text renderer to be used
-- @param reportCharacterCount If true, the number of characters to the left of the column is returned, excluding any characters spanning the column
function self:NodeFromColumn (column, textRenderer, reportCharacterCount)
	local characterCount = 0
	if self.Left then
		local leftColumnCount = self.Left:GetTotalColumnCount (textRenderer)
		if column == 0 or column < leftColumnCount then
			return self.Left:NodeFromColumn (column, textRenderer, reportCharacterCount)
		end
		column = column - leftColumnCount
		if reportCharacterCount then
			characterCount = characterCount + self.Left:GetTotalCharacterCount ()
		end
	end
	
	if column == 0 or column < self:GetColumnCount (textRenderer) then
		local actualCharacterColumn = 0
		if reportCharacterCount then
			local columnCount = 0
			for character, _ in GLib.UTF8.Iterator (self.Text) do
				columnCount = textRenderer:GetCharacterColumnCount (character)
				if actualCharacterColumn == column or actualCharacterColumn + columnCount > column then
					break
				end
				actualCharacterColumn = actualCharacterColumn + columnCount
				characterCount = characterCount + 1
			end
		end
		return self, column, characterCount, actualCharacterColumn
	end
	column = column - self.ColumnCount
	if reportCharacterCount then
		characterCount = characterCount + self:GetCharacterCount ()
	end
	
	if self.Right then
		local rightColumnCount = self.Right:GetTotalColumnCount (textRenderer)
		if column == 0 or column < rightColumnCount then
			local node, column, rightCharacterCount, actualCharacterColumn = self.Right:NodeFromColumn (column, textRenderer, reportCharacterCount)
			return node, column, characterCount + rightCharacterCount, actualCharacterColumn
		end
		column = column - rightColumnCount
	end
	
	-- Fail
	if reportCharacterCount then
		return nil, column, self:GetTotalCharacterCount (), 0
	end
	return nil, column, nil, nil
end

function self:SplitAtCharacter (character)
	local ret = base.SplitAtCharacter (self, character)
	
	ret.Color = self.Color
	return ret
end

function self:ToString ()
	return string.format ("[%d, %d, %d, %d] [%d | %s] \"%s\"", self.Color.r, self.Color.g, self.Color.b, self.Color.a, self:GetCharacterCount (), self.ColumnCountsValid and tostring (self.ColumnCount) or "?", GLib.String.Escape (self.Text))
end