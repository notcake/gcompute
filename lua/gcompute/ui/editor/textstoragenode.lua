local self = {}
GCompute.Editor.TextStorageNode = GCompute.MakeConstructor (self, GCompute.Containers.LinkedListNode)

function self:ctor (text)
	self.Text = ""
	self.TextType = "none"
	self.Length = 0
	
	self.Color = GLib.Colors.White
	
	self.ColumnCount = 0
	self.ColumnCountValid = true
	self.ColumnCountValidityHash = ""
	
	if text then self:SetText (text) end
end

function self:CanMerge (node)
	if self.TextType ~= node.TextType then return false end
	if self.TextType == "utf8" then return false end
	if self.Color.r ~= node.Color.r then return false end
	if self.Color.g ~= node.Color.g then return false end
	if self.Color.b ~= node.Color.b then return false end
	if self.Color.a ~= node.Color.a then return false end
	return true
end

function self:CharacterFromColumn (column, textRenderer)
	if column == 0 then return 0, 0 end
	
	local currentColumn = 0
	local character = 0
	for char, _ in GLib.UTF8.Iterator (self.Text) do
		local nextCharacterColumnCount = textRenderer:GetCharacterColumnCount (char)
		if currentColumn == column or currentColumn + nextCharacterColumnCount > column then
			return character, currentColumn
		end
		currentColumn = currentColumn + nextCharacterColumnCount
		character = character + 1
	end
	
	return character, currentColumn
end

function self:ColumnFromCharacter (character, textRenderer)
	return textRenderer:GetStringColumnCount (GLib.UTF8.Sub (self.Text, 1, character))
end

function self:CopyFormatting (node)
	if not node then return end
	
	self.Color = node.Color
end

function self:CopyMetadata (node)
	if not node then return end
	
	self.TextType = node.TextType
end

function self:GetColor ()
	return self.Color
end

function self:GetColumnCount (textRenderer)
	if not self.ColumnCountValid or self.ColumnCountValidityHash ~= textRenderer:GetStateHash () then
		self.ColumnCount = textRenderer:GetStringColumnCount (self.Text)
		
		self.ColumnCountValid = true
		self.ColumnCountValidityHash = textRenderer:GetStateHash ()
	end
	
	return self.ColumnCount
end

function self:GetText ()
	return self.Text
end

function self:GetTextType ()
	return self.TextType
end

function self:GetLength ()
	return self.Length
end

function self:Merge (node)
	if not node then return end
	
	self.Text = self.Text .. node:GetText ()
	self.Length = GLib.UTF8.Length (self.Text)
	self.ColumnCountValid = false
	
	self.List:Remove (node)
end

function self:SetColor (color)
	self.Color = color or GLib.Colors.White
end

function self:SetText (text)
	if self.Text == text then return end
	
	self.Text = text
	self.Length = GLib.UTF8.Length (self.Text)
	self.ColumnCountValid = false
end

function self:SetTextType (textType)
	self.TextType = textType
end

function self:Split (character)
	if character <= 0 then return self end
	if character >= self:GetLength () then return self.Next end
	
	local before, after = GLib.UTF8.SplitAt (self.Text, character + 1)
	self:SetText (before)
	
	local node = GCompute.Editor.TextStorageNode (after)
	node:CopyFormatting (self)
	node:CopyMetadata (self)
	self:InsertNext (node)
	return node
end

function self:ToString ()
	return string.format ("[%d, %d, %d, %d] \"%s\"", self.Color.r, self.Color.g, self.Color.b, self.Color.a, GLib.String.Escape (self.Text))
end