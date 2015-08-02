local self = {}
GCompute.Lexing.KeywordClassifier = GCompute.MakeConstructor (self, GCompute.Lexing.IKeywordClassifier)

function self:ctor ()
	self.Keywords = {}
end

-- IKeywordClassifier
-- Returns () -> (string, KeywordType)
function self:GetKeywordEnumerator ()
	return GLib.KeyValueEnumerator (self.Keywords)
end

function self:GetKeywordType (keyword)
	return self.Keywords [keyword] or GCompute.Lexing.KeywordType.Unknown
end

function self:IsKeyword (tokenString)
	return self.Keywords [tokenString] == true
end

-- KeywordClassifier
-- Copying
function self:Clone (clone)
	clone = clone or self.__ictor ()
	
	clone:Copy (self)
	
	return clone
end

function self:Copy (source)
	for keyword, keywordType in source:GetEnumerator () do
		self:AddKeyword (keywordType, keyword)
	end
	
	return self
end

-- Keywords
function self:AddKeyword (keywordType, keyword)
	self.Keywords [keyword] = keywordType
	
	return self
end

function self:AddKeywords (keywordType, keywords)
	for _, keyword in ipairs (keywords) do
		self:AddKeyword (keywordType, keyword)
	end
	
	return self
end

function self:ClearKeywords ()
	self.Keywords = {}
end

function self:RemoveKeyword (keyword)
	self.Keywords [keyword] = nil
end

function self:__call ()
	return self:Clone ()
end