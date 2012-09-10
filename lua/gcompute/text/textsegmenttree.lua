local self = {}
GCompute.TextSegmentTree = GCompute.MakeConstructor (self, GCompute.Containers.BinaryTree)

--[[
	TextSegmentTree
		Binary tree of bits of text. Binary tree nodes cannot contain 0-length strings.
]]

function self:ctor ()
	self.BinaryTree     = GCompute.TextSegmentTree
	self.BinaryTreeNode = GCompute.TextSegmentTreeNode
end

--- Splits the node containing the specified character at that character and returns a node starting at that character
-- @param character The character at which a node split is to occur
-- @return A node starting at character
function self:CreateInsertionPointAtCharacter (character)
	local node, character = self:NodeFromCharacter (character)
	if not node then return nil end
	if character <= 0 then return node end
	return node:SplitAtCharacter (character)
end

--- Deletes a range of characters
-- @param startCharacter The start of the range to be deleted
-- @param endCharacter The end of the range to be deleted
-- @return The node before the first deleted node and the node after the last deleted node. These nodes should be consecutive
function self:DeleteCharacterRange (startCharacter, endCharacter)
	if not self.Root then return nil, nil end
	if startCharacter == endCharacter then return nil, nil end
	if endCharacter and startCharacter > endCharacter then
		local temp = endCharacter
		endCharacter = startCharacter
		startCharacter = temp
	end
	
	local startNode, startNodeChar = self.Root:NodeFromCharacter (startCharacter)
	local endNode, endNodeChar = nil, nil
	if endCharacter then
		endNode, endNodeChar = self.Root:NodeFromCharacter (endCharacter)
	end
	
	-- If startNode is the leftmost node, then it's a discard of the left side of the tree
	-- If endNode is nil, then it's a discard of the right side of the tree
	if not startNode then return end
	
	local deletedRangeStart, deletedRangeEnd = nil, nil
	if startNode == endNode then
		startNode:DeleteCharacterRange (startNodeChar, endNodeChar)
		-- endNode cannot be the same as startNode if the deletion span is equal to the
		-- node's span, since endNode would be the node AFTER startNode instead.
	else
		deletedRangeStart = startNode
		startNode:DeleteAfterCharacter (startNodeChar)
		if endNode then
			deletedRangeEnd = endNode
			endNode:DeleteBeforeCharacter (endNodeChar)
		end
		
		-- Delete nodes in between startNode and endNode
		local current = startNode
		local next = startNode:GetNext ()
		while next ~= endNode do
			current = next
			next = next:GetNext ()
			
			current:Remove ()
		end
		
		if startNodeChar == 0 then
			deletedRangeStart = startNode:GetPrevious ()
			startNode:Remove ()
		end
	end
	
	ErrorNoHalt (self:ToString () .. "\n")
	return deletedRangeStart, deletedRangeEnd
end

--- Returns the character at the specified character position
-- @param character The character position at which a character is to be retrieved
-- @return The character at the specified character position
function self:GetCharacter (character)
	if not self.Root then return "" end
	
	local node, character = self.Root:NodeFromCharacter (character)
	if not node then return "" end
	
	return node:Sub (character + 1, character + 1)
end

function self:GetCharacterCount ()
	if not self.Root then return 0 end
	return self.Root:GetTotalCharacterCount ()
end

function self:GetCharacterCountExcludingLineBreak ()
	if not self.Root then return 0 end
	return self.Root:GetTotalCharacterCountExcludingLineBreak ()
end

--- Inserts text at the specified character position by making a new node
-- @param character The character at which text is to be inserted
-- @param text The text to be inserted
-- @return The newly inserted node
function self:InsertNodeAtCharacter (character, text)
	text = text or ""
	if not text then return end
	
	local node = self.BinaryTreeNode (text)
	if not self.Root then
		self:SetRoot (node)
	else
		local nodeToSplit, character = self.Root:NodeFromCharacter (character)
		if nodeToSplit then
			nodeToSplit:InsertNodeAtCharacter (character, node)
		else
			self.Root:InsertRightmost (node)
		end
	end
	
	ErrorNoHalt ("Insert node \"" .. GLib.String.Escape (text) .. "\" at " .. tostring (character) .. "\n")
	ErrorNoHalt (self:ToString () .. "\n")
	
	return node
end

--- Inserts text at the specified character position by modifying an existing node
-- @param character The character at which text is to be inserted
-- @param text The text to be inserted
-- @return The modified node
function self:InsertTextAtCharacter (character, text)
	text = text or ""
	if not text then return end
	
	local node = nil
	if not self.Root then
		node = self.BinaryTreeNode (text)
		self:SetRoot (node)
	else
		node, character = self.Root:NodeFromCharacter (character)
		if node then
			node:InsertAtCharacter (character, text)
		else
			self.Root:GetRightmost ():AppendText (text)
		end
	end
	
	ErrorNoHalt ("Insert text \"" .. GLib.String.Escape (text) .. "\" at " .. tostring (character) .. "\n")
	ErrorNoHalt (self:ToString () .. "\n")
	
	return node
end

--- Returns the node which starts at the specified character position or contains it as well as the character position relative to the start of the node
-- @param character The character position whose associated node is to be retrieved
-- @return The node starting or containing the specified character position or nil if the position is beyond the last node
-- @return The character position relative to the start of the node
function self:NodeFromCharacter (character)
	if not self.Root then return nil, character end
	
	if character < 0 then return self:GetLeftmost (), -character end
	
	local node = self.Root
	
	while true do
		while true do
			if node.Left then
				local leftCharacterCount = node.Left:GetTotalCharacterCount ()
				if character < leftCharacterCount then
					node = node.Left
					break
				end
				character = character - leftCharacterCount
			end
			
			if character < node:GetCharacterCount () then
				return node, character
			end
			character = character - node.CharacterCount
			
			if node.Right then
				local rightCharacterCount = node.Right:GetTotalCharacterCount ()
				if character < rightCharacterCount then
					node = node.Right
					break
				end
				character = character - rightCharacterCount
			end
			
			return nil, character
		end
	end
end