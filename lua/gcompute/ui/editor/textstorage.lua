local self = {}
GCompute.Editor.TextStorage = GCompute.MakeConstructor (self)

function self:ctor ()
	self.LinkedList = GCompute.Containers.LinkedList ()
	self.LinkedList.LinkedListNode = GCompute.Editor.TextStorageNode
	
	self.Text = ""
	self.LengthExcludingLineBreak = 0
	self.LengthExcludingLineBreakValid = false
	self.LengthIncludingLineBreak = 0
	self.LengthIncludingLineBreakValid = false
	
	self.ColumnCount = 0
	self.ColumnCountValid = false
	self.ColumnCountValidityHash = ""
end

function self:Append (textStorage)
	if not textStorage then return end
	self.LinkedList:Append (textStorage.LinkedList)
	
	self.Text = self.Text .. textStorage.Text
	self:InvalidateCache ()
	
	textStorage.Text = ""
	textStorage:InvalidateCache ()
end

function self:CheckMerge (node, nextNode)
	if not node then return nextNode end
	if not nextNode then return nextNode end
	
	if node:CanMerge (nextNode) then
		node:Merge (nextNode)
		return node
	end
	return nextNode
end

function self:Clear ()
	self.LinkedList:Clear ()
	self.Text = ""
	self:InvalidateCache ()
end

function self:CharacterFromColumn (column, textRenderer)
	if column >= self:GetColumnCount (textRenderer) then return self:GetLengthExcludingLineBreak (), self:GetColumnCount (textRenderer) end
	local character = 0
	local actualColumn = 0
	local node = self.LinkedList.First
	while column > node:GetColumnCount (textRenderer) do
		column = column - node:GetColumnCount (textRenderer)
		character = character + node:GetLength ()
		actualColumn = actualColumn + node:GetColumnCount (textRenderer)
		node = node.Next
	end
	
	local relativeCharacter, relativeActualColumn = node:CharacterFromColumn (column, textRenderer)
	return character + relativeCharacter, actualColumn + relativeActualColumn
end

function self:ColumnFromCharacter (character, textRenderer)
	if character >= self:GetLengthIncludingLineBreak () then return self:GetColumnCount (textRenderer) end
	local column = 0
	local node = self.LinkedList.First
	while character > node:GetLength () do
		character = character - node:GetLength ()
		column = column + node:GetColumnCount (textRenderer)
		node = node.Next
	end
	
	return column + node:ColumnFromCharacter (character, textRenderer)
end

function self:Delete (startCharacter, endCharacter)
	endCharacter = endCharacter or self:GetLengthIncludingLineBreak ()
	
	local startNode = self:SplitNode (startCharacter)
	local endNode = self:SplitNode (endCharacter)
	
	while startNode ~= endNode do
		local next = startNode.Next
		startNode:Remove ()
		startNode = next
	end
	
	if endNode then
		self:CheckMerge (endNode.Previous, endNode)
	end
	
	self.Text = GLib.UTF8.Sub (self.Text, 1, startCharacter) .. GLib.UTF8.Sub (self.Text, endCharacter + 1)
	self:InvalidateCache ()
end

function self:GetCharacter (character)
	return GLib.UTF8.Sub (self.Text, character + 1, character + 1)
end

function self:GetColumnCount (textRenderer)
	if not self.ColumnCountValid or self.ColumnCountValidityHash ~= textRenderer:GetStateHash () then
		self.ColumnCount = textRenderer:GetStringColumnCount (self.Text)
		
		self.ColumnCountValid = true
		self.ColumnCountValidityHash = textRenderer:GetStateHash ()
	end
	
	return self.ColumnCount
end

function self:GetLengthExcludingLineBreak ()
	if not self.LengthExcludingLineBreakValid then
		self.LengthExcludingLineBreak = self:GetLengthIncludingLineBreak ()
		local i = self.Text:len ()
		local c = self.Text:sub (i, i)
		while c == "\r" or c == "\n" do
			self.LengthExcludingLineBreak = self.LengthExcludingLineBreak - 1
			i = i - 1
			c = self.Text:sub (i, i)
		end
		self.LengthExcludingLineBreakValid = true
	end
	return self.LengthExcludingLineBreak
end

function self:GetLengthIncludingLineBreak ()
	if not self.LengthIncludingLineBreakValid then
		self.LengthIncludingLineBreak = GLib.UTF8.Length (self.Text)
		self.LengthIncludingLineBreakValid = true
	end
	return self.LengthIncludingLineBreak
end

function self:GetText ()
	return self.Text
end

function self:Insert (character, text)
	if not text or text == "" then return end
	
	local bits = {}
	local bitTypes = {}
	local str = nil
	local lastType = nil
	local offset = 1
	local match = nil
	while offset <= string.len (text) do
		match = string.match (text, "^[ \t]+", offset)
		lastType = "whitespace"
		if not match then
			match = string.match (text, "^[\r\n]+", offset)
			lastType = "linebreak"
		end
		if not match then
			match = string.match (text, "^[\128-\255]+", offset)
			lastType = "utf8"
		end
		if not match then
			match = string.match (text, "^[%z\1-\8\11\12\14-\31\33-\127]+", offset)
			lastType = "regular"
		end
		bits [#bits + 1] = match
		bitTypes [#bitTypes + 1] = lastType
		offset = offset + string.len (match)
	end
	
	local nodeAfterInsertionPoint = self:SplitNode (character)
	local nodeBeforeInsertionPoint = nodeAfterInsertionPoint and nodeAfterInsertionPoint.Previous or self.LinkedList.Last
	for i = 1, #bits do
		local node = GCompute.Editor.TextStorageNode (bits [i])
		node:CopyFormatting (nodeBeforeInsertionPoint)
		node:SetTextType (bitTypes [i])
		self.LinkedList:InsertNodeBefore (nodeAfterInsertionPoint, node)
	end
	
	if nodeBeforeInsertionPoint then
		local node = self:CheckMerge (nodeBeforeInsertionPoint, nodeBeforeInsertionPoint.Next)
		if node then
			self:CheckMerge (node, node.Next)
		end
	end
	
	local before, after = GLib.UTF8.SplitAt (self.Text, character + 1)
	self.Text = before .. text .. after
	self:InvalidateCache ()
end

function self:InvalidateCache ()
	self.LengthExcludingLineBreakValid = false
	self.LengthIncludingLineBreakValid = false
	self.ColumnCountValid = false
end

function self:NodeFromCharacter (character)
	if character >= self:GetLengthIncludingLineBreak () then return nil, character end
	local node = self.LinkedList.First
	while character > node:GetLength () do
		character = character - node:GetLength ()
		node = node.Next
	end
	
	return node, character
end

function self:NodeFromColumn (column, textRenderer)
	if column >= self:GetColumnCount (textRenderer) then return nil, column end
	local node = self.LinkedList.First
	while column > node:GetColumnCount (textRenderer) do
		column = column - node:GetColumnCount (textRenderer)
		node = node.Next
	end
	
	return node, column
end

function self:SetColor (color, startCharacter, endCharacter)
	color = color or GLib.Colors.White
	startCharacter = startCharacter or 0
	if endCharacter and endCharacter < startCharacter then
		local temp = startCharacter
		startCharacter = endCharacter
		endCharacter = temp
	end
	
	local startNode = self:SplitNode (startCharacter)
	local afterEndNode = endCharacter and self:SplitNode (endCharacter) or nil
	
	if not startNode then return end
	
	local node = startNode
	while node ~= afterEndNode do
		node:SetColor (color)
		node = node.Next
	end
	
	node = startNode.Previous or startNode
	local afterAfterEndNode = afterEndNode and afterEndNode.Next or nil
	while node and node ~= afterEndNode and node ~= afterAfterEndNode do
		node = self:CheckMerge (node, node.Next)
	end
end

function self:Split (character)
	local before, after = GLib.UTF8.SplitAt (self.Text, character + 1)
	
	local node = self:SplitNode (character)
	local textStorage = GCompute.Editor.TextStorage ()
	
	self.Text = before
	self:InvalidateCache ()
	
	textStorage.LinkedList = self.LinkedList:Split (node)
	textStorage.Text = after
	textStorage:InvalidateCache ()
	
	return textStorage
end

function self:SplitNode (character)
	if character >= self:GetLengthIncludingLineBreak () then return nil end
	local node = self.LinkedList.First
	while character > node:GetLength () do
		character = character - node:GetLength ()
		node = node.Next
	end
	
	if character <= 0 then return node end
	return node:Split (character)
end

function self:Sub (startCharacter, endCharacter)
	return GLib.UTF8.Sub (self.Text, startCharacter, endCharacter)
end

function self:ToString ()
	local textStorage = "{\n"
	textStorage = textStorage .. "\t\"" .. GLib.String.Escape (self.Text) .. "\"\n"
	textStorage = textStorage .. "\t" .. self.LinkedList:ToString () .. "\n"
	textStorage = textStorage .. "}"
	return textStorage
end