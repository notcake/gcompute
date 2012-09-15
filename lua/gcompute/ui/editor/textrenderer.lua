local self = {}
GCompute.Editor.TextRenderer = GCompute.MakeConstructor (self)

local string_len = string.len

function self:ctor ()
	self.NextHashId = 0
	self.StateHash = ""
	self:UpdateStateHash ()
	
	self.TabWidth = 4
end

function self:CharacterFromColumn (text, column)
	local currentColumn = 0
	local character = 0
	for char, _ in GLib.UTF8.Iterator (text) do
		local nextCharacterColumnCount = self:GetCharacterColumnCount (char)
		if currentColumn == column or currentColumn + nextCharacterColumnCount > column then
			return character, currentColumn
		end
		currentColumn = currentColumn + nextCharacterColumnCount
		character = character + 1
	end
	return character, currentColumn
end

function self:ColumnFromCharacter (text, character)
	return self:GetStringColumnCount (GLib.UTF8.Sub (text, 1, character))
end

function self:Clone ()
	local textRenderer = GCompute.Editor.TextRenderer ()
	textRenderer.NextHashId = self.NextHashId
	textRenderer.StateHash  = self.StateHash
	textRenderer.TabWidth   = self.TabWidth
	return textRenderer
end

function self:GetCharacterColumnCount (character)
	if character == "" then return 0 end
	if character == "\t" then return self.TabWidth end
	if character == "\r" or character == "\n" then return 0 end
	if string_len (character) > 1 then return 2 end
	return 1
end

function self:GetStringColumnCount (text)
	local columnWidth = 0
	for character, _ in GLib.UTF8.Iterator (text) do
		columnWidth = columnWidth + self:GetCharacterColumnCount (character)
	end
	return columnWidth
end

function self:GetStateHash ()
	return self.StateHash
end

function self:GetTabWidth ()
	return self.TabWidth
end

function self:SetTabWidth (tabWidth)
	if self.TabWidth == tabWidth then return end
	self.TabWidth = tabWidth
	
	self:UpdateStateHash ()
end

function self:UpdateStateHash ()
	self.StateHash = tostring (self) .. tostring (self.NextHashId)
	self.NextHashId = self.NextHashId + 1
end