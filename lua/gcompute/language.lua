local self = {}
GCompute.Languages.Language = GCompute.MakeConstructor (self)

local SymbolMatchType =
{
	Regex	= 1,
	Plain	= 2,
	Custom	= 3
}
local KeywordTypes = GCompute.KeywordTypes

function self:ctor (name)
	self.Name = name
	self.Symbols = {}
	self.SymbolMatchType = {}
	self.SymbolTokenType = {}
	self.Keywords = {}
	
	self.ParserTable = {}
	self.ParserConstructor = GCompute.MakeConstructor (self.ParserTable, GCompute.Parser)
	self.ASTBuilderTable = {}
	self.ASTBuilderConstructor = GCompute.MakeConstructor (self.ASTBuilderTable, GCompute.ASTBuilder)
end

function self:Parser (compilationUnit)
	return self.ParserConstructor (compilationUnit)
end

function self:ASTBuilder (compilationUnit)
	return self.ASTBuilderConstructor (compilationUnit)
end

function self:AddCustomSymbol (pattern, tokenType, matchFunction)
	self.Symbols [#self.Symbols + 1] = pattern
	self.SymbolMatchType [#self.SymbolMatchType + 1] = matchFunction
	self.SymbolTokenType [#self.SymbolTokenType + 1] = tokenType
end

function self:AddCustomSymbols (patterns, tokenType, matchFunction)
	for _, pattern in ipairs (patterns) do
		self.Symbols [#self.Symbols + 1] = pattern
		self.SymbolMatchType [#self.SymbolMatchType + 1] = matchFunction
		self.SymbolTokenType [#self.SymbolTokenType + 1] = tokenType
	end
end

function self:AddKeyword (keyword, keywordType)
	if not keywordType then
		keywordType = GCompute.KeywordTypes.Unknown
	end
	self.Keywords [keyword] = keywordType
end

function self:AddKeywords (keywords, keywordType)
	if not keywordType then
		keywordType = GCompute.KeywordTypes.Unknown
	end
	for _, keyword in ipairs (keywords) do
		self.Keywords [keyword] = keywordType
	end
end

function self:AddSymbol (pattern, tokenType, isRegex)
	if isRegex == nil then
		isRegex = true
	end
	if isRegex then
		self.Symbols [#self.Symbols + 1] = "^" .. pattern
	else
		self.Symbols [#self.Symbols + 1] = pattern
	end
	self.SymbolMatchType [#self.SymbolMatchType + 1] = isRegex and SymbolMatchType.Regex or SymbolMatchType.Plain
	self.SymbolTokenType [#self.SymbolTokenType + 1] = tokenType
end

function self:AddSymbols (patterns, tokenType, isRegex)
	if isRegex == nil then
		isRegex = true
	end
	for _, pattern in ipairs (patterns) do
		if isRegex then
			self.Symbols [#self.Symbols + 1] = "^" .. pattern
		else
			self.Symbols [#self.Symbols + 1] = pattern
		end
		self.SymbolMatchType [#self.SymbolMatchType + 1] = isRegex and SymbolMatchType.Regex or SymbolMatchType.Plain
		self.SymbolTokenType [#self.SymbolTokenType + 1] = tokenType
	end
end

function self:GetKeywordType (token)
	return self.Keywords [token] or KeywordTypes.Unknown
end

function self:GetSymbols ()
	return self.Symbols
end

function self:IsKeyword (token)
	return self.Keywords [token] == true
end

function self:LoadParser (file)
	if not file then
		file = self.Name .. "_parser.lua"
	end
	local parser = _G.Parser
	_G.Parser = self.ParserTable
	include (file)
	_G.Parser = parser
end

function self:LoadASTBuilder (file)
	if not file then
		file = self.Name .. "_astbuilder.lua"
	end
	local astBuilder = _G.ASTBuilder
	_G.ASTBuilder = self.ASTBuilderTable
	include (file)
	_G.ASTBuilder = astBuilder
end

function self:MatchSymbol (code)
	for index, symbol in ipairs (self.Symbols) do
		local match = nil
		local matchLength = 0
		if self.SymbolMatchType [index] == SymbolMatchType.Regex then
			match = code:match (symbol) 
			if match then
				matchLength = match:len ()
			end
		elseif self.SymbolMatchType [index] == SymbolMatchType.Plain then
			if code:sub (1, symbol:len ()) == symbol then
				match = symbol
				matchLength = match:len ()
			end
		else
			if code:sub (1, symbol:len ()) == symbol then
				match, matchLength = self.SymbolMatchType [index] (code)
			end
		end
		if match then
			return match, matchLength, self.SymbolTokenType [index]
		end
	end
	return nil, 0
end