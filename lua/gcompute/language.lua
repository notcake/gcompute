local self = {}
GCompute.Languages.Language = GCompute.MakeConstructor (self)

function self:ctor (name)
	self.Name = name
	
	self.Tokenizer = GCompute.Tokenizer (self)
	self.Keywords = {}
	
	self.DirectivesCaseSensitive = true
	self.Directives = {}
	
	self.ParserTable = {}
	self.ParserConstructor = GCompute.MakeConstructor (self.ParserTable, GCompute.Parser)
	
	self.Passes = {}
end

function self:Parser (compilationUnit)
	return self.ParserConstructor (compilationUnit)
end

function self:GetTokenizer ()
	return self.Tokenizer
end

function self:AddDirective (directive, handler)
	if not self.DirectivesCaseSensitive then
		directive = directive:lower ()
	end
	self.Directives [directive] = handler
end

function self:AddKeyword (keywordType, keyword)
	self.Keywords [keyword] = keywordType
end

function self:AddKeywords (keywordType, keywords)
	for _, keyword in ipairs (keywords) do
		self:AddKeyword (keywordType, keyword)
	end
end

function self:GetKeywordType (token)
	return self.Keywords [token] or GCompute.KeywordType.Unknown
end

function self:GetName ()
	return self.Name
end

function self:GetParserMetatable ()
	return self.ParserTable
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

function self:LoadPass (file, when)
	local pass = _G.Pass
	_G.Pass = nil
	include (file)
	local passName = GCompute.CompilerPassType [when]
	self.Passes [passName] = self.Passes [passName] or {}
	self.Passes [passName] [#self.Passes [passName] + 1] = _G.Pass
	_G.Pass = pass
end

function self:ProcessDirective (compilationUnit, directive, startToken, endToken)
	if not self.DirectivesCaseSensitive then
		directive = directive:lower ()
	end
	if not self.Directives [directive] then
		compilationUnit:Error ("Unknown preprocessor directive " .. directive, startToken.Line, startToken.Character)
		return
	end
	
	local directiveParser = self:Parser (compilationUnit)
	directiveParser:Initialize (startToken.List, startToken, endToken)
	self.Directives [directive] (compilationUnit, directive, directiveParser)
end

function self:SetDirectiveCaseSensitivity (caseSensitive)
	self.DirectivesCaseSensitive = caseSensitive
end