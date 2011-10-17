local SymbolMatchType = {
	Regex = 1,
	Plain = 2,
	Custom = 3
}
local KeywordTypes = GCompute.KeywordTypes

local Language = {}
Language.__index = Language

function GCompute.Languages.Language (Name)
	local Object = {}
	setmetatable (Object, Language)
	Object:ctor ()
	Object.Name = Name
	
	GCompute.Languages.Languages [Name] = Object
	return Object
end

function Language:ctor ()
	self.Name = ""
	self.Symbols = {}
	self.SymbolMatchType = {}
	self.SymbolTokenType = {}
	self.Keywords = {}
	
	self._Parser = {}
	self._Parser.__index = self._Parser
	setmetatable (self._Parser, GCompute._Parser)
	function self._Parser.ctor ()
	end
end

function Language:Parser ()
	local Object = {}
	setmetatable (Object, self._Parser)
	GCompute._Parser.ctor (Object)
	Object:ctor ()
	return Object
end

function Language:AddCustomSymbol (Pattern, TokenType, MatchFunction)
	self.Symbols [#self.Symbols + 1] = Pattern
	self.SymbolMatchType [#self.SymbolMatchType + 1] = MatchFunction
	self.SymbolTokenType [#self.SymbolTokenType + 1] = TokenType
end

function Language:AddCustomSymbols (Patterns, TokenType, MatchFunction)
	for _, Pattern in ipairs (Patterns) do
		self.Symbols [#self.Symbols + 1] = Pattern
		self.SymbolMatchType [#self.SymbolMatchType + 1] = MatchFunction
		self.SymbolTokenType [#self.SymbolTokenType + 1] = TokenType
	end
end

function Language:AddKeyword (Keyword, KeywordType)
	if not KeywordType then
		KeywordType = GCompute.KeywordTypes.Unknown
	end
	self.Keywords [Keyword] = KeywordType
end

function Language:AddKeywords (Keywords, KeywordType)
	if not KeywordType then
		KeywordType = GCompute.KeywordTypes.Unknown
	end
	for _, Keyword in ipairs (Keywords) do
		self.Keywords [Keyword] = KeywordType
	end
end

function Language:AddSymbol (Pattern, TokenType, IsRegex)
	if IsRegex == nil then
		IsRegex = true
	end
	if IsRegex then
		self.Symbols [#self.Symbols + 1] = "^" .. Pattern
	else
		self.Symbols [#self.Symbols + 1] = Pattern
	end
	if IsRegex then
		self.SymbolMatchType [#self.SymbolMatchType + 1] = SymbolMatchType.Regex
	else
		self.SymbolMatchType [#self.SymbolMatchType + 1] = SymbolMatchType.Plain
	end
	self.SymbolTokenType [#self.SymbolTokenType + 1] = TokenType
end

function Language:AddSymbols (Patterns, TokenType, IsRegex)
	if IsRegex == nil then
		IsRegex = true
	end
	if IsRegex then
		IsRegex = SymbolMatchType.Regex
	else
		IsRegex = SymbolMatchType.Plain
	end
	for _, Pattern in ipairs (Patterns) do
		if IsRegex == SymbolMatchType.Regex then
			self.Symbols [#self.Symbols + 1] = "^" .. Pattern
		else
			self.Symbols [#self.Symbols + 1] = Pattern
		end
		self.SymbolMatchType [#self.SymbolMatchType + 1] = IsRegex
		self.SymbolTokenType [#self.SymbolTokenType + 1] = TokenType
	end
end

function Language:GetKeywordType (Token)
	return self.Keywords [Token] or KeywordTypes.Unknown
end

function Language:GetSymbols ()
	return self.Symbols
end

function Language:IsKeyword (Token)
	return self.Keywords [Token] == true
end

function Language:LoadParser (File)
	if not File then
		File = self.Name .. "_parser.lua"
	end
	local Parser = _G.Parser
	_G.Parser = self._Parser
	include (File)
	_G.Parser = Parser
end

function Language:MatchSymbol (Code)
	for Index, Symbol in ipairs (self.Symbols) do
		local Match = nil
		local MatchLength = 0
		if self.SymbolMatchType [Index] == SymbolMatchType.Regex then
			Match = Code:match (Symbol) 
			if Match then
				MatchLength = Match:len ()
			end
		elseif self.SymbolMatchType [Index] == SymbolMatchType.Plain then
			if Code:sub (1, Symbol:len ()) == Symbol then
				Match = Symbol
				MatchLength = Match:len ()
			end
		else
			if Code:sub (1, Symbol:len ()) == Symbol then
				Match, MatchLength = self.SymbolMatchType [Index] (Code)
			end
		end
		if Match then
			return Match, MatchLength, self.SymbolTokenType [Index]
		end
	end
	return nil, 0
end