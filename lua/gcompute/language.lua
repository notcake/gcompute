local self = {}
GCompute.Languages.Language = GCompute.MakeConstructor (self)

--[[
	Events:
		NamespaceChanged ()
			Fired when the language's environment namespace has changed.
]]

function self:ctor (name)
	self.Name = name
	
	-- Editor
	self.EditorHelperTable = {}
	self.EditorHelper = nil
	
	-- Compilation
	self.KeywordClassifier = GCompute.Lexing.KeywordClassifier ()
	self.Tokenizer         = GCompute.Lexing.Tokenizer (self.Name)
	self.Keywords = {}
	
	-- Usings
	self.IntrinsicUsings = GCompute.UsingCollection ()
	
	self.DirectivesCaseSensitive = true
	self.Directives = {}
	
	self.ParserTable = {}
	
	self.Passes = {}
	
	GCompute.EventProvider (self)
end

function self:dtor ()
	if self.EditorHelper then
		self.EditorHelper:dtor ()
	end
end

function self:GetName ()
	return self.Name
end

-- Editor
function self:GetEditorHelper ()
	if not self.EditorHelper then
		self.EditorHelper = GCompute.MakeConstructor (self.EditorHelperTable, GCompute.IEditorHelper) (self)
	end
	return self.EditorHelper
end

function self:LoadEditorHelper (file)
	if not file then file = self.Name .. "_editorhelper.lua" end
	local editorHelper = _G.EditorHelper
	_G.EditorHelper = self.EditorHelperTable
	include (file)
	_G.EditorHelper = editorHelper
end

-- Compilation
-- Usings
function self:AddIntrinsicUsing (qualifiedName)
	self.IntrinsicUsings:AddUsing (qualifiedName)
end

function self:GetIntrinsicUsings ()
	return self.IntrinsicUsings
end

-- Lexing
function self:CreateLexer ()
	-- TODO: Fix the lexer mess.
	local lexer = GCompute.Lexing.Lexer ()
	lexer.Tokenizer         = self.Tokenizer
	lexer.KeywordClassifier = self.KeywordClassifier
	
	return lexer
end

function self:GetKeywordClassifier ()
	return self.KeywordClassifier
end

function self:GetTokenizer ()
	return self.Tokenizer
end

-- Convenience method, returns an ITokenStream
function self:Lex (code)
	return self:CreateLexer ():Lex (code)
end

-- Preprocessing
function self:AddDirective (directive, handler)
	if not self.DirectivesCaseSensitive then
		directive = directive:lower ()
	end
	self.Directives [directive] = handler
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

-- Parsing
function self:GetParserMetatable ()
	return self.ParserTable
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

function self:Parser (compilationUnit)
	return GCompute.MakeConstructor (self.ParserTable, GCompute.Parser) (compilationUnit)
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