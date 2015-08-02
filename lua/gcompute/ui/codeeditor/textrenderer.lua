local self = {}
GCompute.CodeEditor.TextRenderer = GCompute.MakeConstructor (self)

function self:ctor ()
	self.NextHashId = 0
	self.StateHash = ""
	self:UpdateStateHash ()
	
	self.TabWidth = 4
end

function self:Clone (clone)
	clone = clone or self.__ictor ()
	
	clone:Copy (self)
	
	return clone
end

function self:Copy (source)
	self.NextHashId = source.NextHashId
	self.StateHash  = source.StateHash
	self.TabWidth   = source.TabWidth
	
	return self
end

function self:CharacterFromColumn (text, column, currentColumn)
	currentColumn = currentColumn or 0
	local relativeCurrentColumn = 0
	local character = 0
	for char, _ in GLib.UTF8.Iterator (text) do
		local nextCharacterColumnCount = self:GetCharacterColumnCount (char, currentColumn + relativeCurrentColumn)
		if relativeCurrentColumn == column or relativeCurrentColumn + nextCharacterColumnCount > column then
			return character, relativeCurrentColumn
		end
		relativeCurrentColumn = relativeCurrentColumn + nextCharacterColumnCount
		character = character + 1
	end
	return character, relativeCurrentColumn
end

function self:ColumnFromCharacter (text, character)
	return self:GetStringColumnCount (GLib.UTF8.Sub (text, 1, character), 0)
end

function self:GetCharacterColumnCount (character, currentColumn)
	if character == "" then return 0 end
	if character == "\t" then return self.TabWidth - currentColumn % self.TabWidth end
	if character == "\r" or character == "\n" then return 0 end
	if #character <= 1 then return 1 end
	
	local codePoint = GLib.UTF8.Byte (character)
	if codePoint <= 0xFF then return 1 end
	return 2
end

function self:GetStringColumnCount (text, currentColumn)
	currentColumn = currentColumn or 0
	local columnCount = 0
	for character, _ in GLib.UTF8.Iterator (text) do
		columnCount = columnCount + self:GetCharacterColumnCount (character, currentColumn + columnCount)
	end
	return columnCount
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
	self.StateHash = self:GetHashCode () .. tostring (self.NextHashId)
	self.NextHashId = self.NextHashId + 1
end

-- Workaround for LuaJIT bugs
jit.off (self.GetStringColumnCount)