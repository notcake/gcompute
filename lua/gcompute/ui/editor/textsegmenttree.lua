local self = {}
GCompute.Editor.TextSegmentTree = GCompute.MakeConstructor (self, GCompute.TextSegmentTree)
local base = GCompute.GetMetaTable (GCompute.TextSegmentTree)

function self:ctor ()
	self.BinaryTree     = GCompute.Editor.TextSegmentTree
	self.BinaryTreeNode = GCompute.Editor.TextSegmentTreeNode
end

function self:CharacterFromColumn (column, textRenderer)
	local node, columnOffset, character, actualCharacterColumn = self:NodeFromColumn (column, textRenderer, true)
	return character, column + actualCharacterColumn - columnOffset
end

function self:ColumnFromCharacter (character, textRenderer)
	if not self.Root then return 0 end
	
	local node, _, column = self.Root:NodeFromCharacter (character, textRenderer)
	if not node then
		return self.Root:GetTotalColumnCount (textRenderer)
	end
	return column
end

function self:DeleteCharacterRange (startCharacter, endCharacter)
	local deletedNodeStart, deletedNodeEnd = base.DeleteCharacterRange (self, startCharacter, endCharacter)
	
	if deletedNodeStart and deletedNodeEnd then
		if deletedNodeStart:CanMergeWith (deletedNodeEnd) then
			deletedNodeStart:SetText (deletedNodeStart:GetText () .. deletedNodeEnd:GetText ())
			deletedNodeEnd:Remove ()
			deletedNodeEnd = deletedNodeStart:GetNext ()
		end
	end
	
	return deletedNodeStart, deletedNodeEnd
end

function self:GetColumnCount (textRenderer)
	if not self.Root then return 0 end
	return self.Root:GetTotalColumnCount (textRenderer)
end

function self:InsertAtCharacter (character, text)
	local insertedNode = base.InsertTextAtCharacter (self, character, text)
	
	
	
	return insertedNode
end

-- Returns the node start at or containing the specified column
-- Returns the specified column position, relative to the node start
-- Returns the character start at or spanning the specified column position
-- Returns the start column of the character
function self:NodeFromColumn (column, textRenderer, reportCharacter)
	if not self.Root then return nil, column, 0, 0 end
	
	local node, columnOffset, character, actualCharacterColumn = self.Root:NodeFromColumn (column, textRenderer, reportCharacter)
	-- Correct for 0-width characters
	if not node or columnOffset == 0 then
		local previousNode
		if not node then
			-- column was past the end of the entire text
			character = self.Root:GetTotalCharacterCount ()
			previousNode = self:GetRightmost ()
			column = self.Root:GetTotalColumnCount (textRenderer)
		else
			previousNode = node:GetPrevious ()
		end
		if previousNode then
			local text = previousNode:GetText ()
			local char, offset = GLib.UTF8.PreviousChar (text)
			local columnCount = textRenderer:GetCharacterColumnCount (char)
			while char ~= "" and columnCount == 0 do
				character = character - 1
				char, offset = GLib.UTF8.PreviousChar (text, offset)
				columnCount = textRenderer:GetCharacterColumnCount (char)
			end
		end
	end
	return node, columnOffset, character, actualCharacterColumn
end

function self:SetColor (color, startCharacter, endCharacter)
	color = color or GLib.Colors.White
	startCharacter = startCharacter or 0
	if endCharacter and endCharacter < startCharacter then
		local temp = startCharacter
		startCharacter = endCharacter
		endCharacter = temp
	end
	
	local startNode = self:CreateInsertionPointAtCharacter (startCharacter)
	local afterEndNode = endCharacter and self:CreateInsertionPointAtCharacter (endCharacter) or nil
	
	if not startNode then return end
	
	while startNode ~= afterEndNode do
		startNode:SetColor (color)
		startNode = startNode:GetNext ()
	end
end