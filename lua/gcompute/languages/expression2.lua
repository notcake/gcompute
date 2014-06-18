--[[
	Expression 2
	
	Credit goes to Syranide, Divran, Colonel Thirty Two / initrd.gz,
	TomyLobo, Rusketh &c
]]

local LANGUAGE = GCompute.Languages.Create ("Expression 2")
GCompute.LanguageDetector:AddPathPattern (LANGUAGE, "/expression2/.*")

-- Usings
LANGUAGE:AddIntrinsicUsing ("Expression2")
LANGUAGE:AddIntrinsicUsing ("Expression2.math")

-- Lexer
LANGUAGE:GetTokenizer ()
	:AddCustomSymbols (GCompute.Lexing.TokenType.String, {"\"", "'"},
		function (code, offset)
			local quotationMark = string.sub (code, offset, offset)
			local searchStartOffset = offset + 1
			local backslashOffset = 0
			local quotationMarkOffset = 0
			while true do
				if backslashOffset and backslashOffset < searchStartOffset then
					backslashOffset = string.find (code, "\\", searchStartOffset, true)
				end
				if quotationMarkOffset and quotationMarkOffset < searchStartOffset then
					quotationMarkOffset = string.find (code, quotationMark, searchStartOffset, true)
				end
				
				if backslashOffset and quotationMarkOffset and backslashOffset > quotationMarkOffset then backslashOffset = nil end
				if not backslashOffset then
					if quotationMarkOffset then
						return string.sub (code, offset, quotationMarkOffset), quotationMarkOffset - offset + 1
					else
						return string.sub (code, offset), string.len (code) - offset + 1
					end
				end
				searchStartOffset = backslashOffset + 2
			end
		end
	)
	:AddCustomSymbol (GCompute.Lexing.TokenType.Comment, "/*",
		function (code, offset)
			local endOffset = string.find (code, "*/", offset + 2, true)
			if endOffset then
				return string.sub (code, offset, endOffset + 1), endOffset - offset + 2
			end
			return string.sub (code, offset), string.len (code) - offset + 1
		end
	)
	:AddCustomSymbol (GCompute.Lexing.TokenType.Comment, "#[",
		function (code, offset)
			local endOffset = string.find (code, "]#", offset + 2, true)
			if endOffset then
				return string.sub (code, offset, endOffset + 1), endOffset - offset + 2
			end
			return string.sub (code, offset), string.len (code) - offset + 1
		end
	)
	:AddPatternSymbol (GCompute.Lexing.TokenType.Comment,              "#[^\n\r]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Identifier,           "[a-zA-Z_][a-zA-Z0-9_]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "0b[01]+")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "0x[0-9a-fA-F]+")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+%.[0-9]*e[-+]?[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+%.[0-9]*e[-+]?[0-9]+")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+e[-+]?[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+e[-+]?[0-9]+")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+")
	:AddPlainSymbols  (GCompute.Lexing.TokenType.Operator,            {"##", "++", "--", "==", "!=", "<=", ">=", "<<=", ">>=", "+=", "-=", "*=", "/=", "^=", "||", "&&", "^^", ">>", "<<"})
	:AddPlainSymbols  (GCompute.Lexing.TokenType.MemberIndexer,       {".", ":"})
	:AddPlainSymbols  (GCompute.Lexing.TokenType.Operator,            {"!", "~", "+", "-", "^", "&", "|", "*", "/", "=", "<", ">", "(", ")", "{", "}", "[", "]", "%", "?", ","})
	:AddPlainSymbol   (GCompute.Lexing.TokenType.Preprocessor,         "@")
	:AddPlainSymbol   (GCompute.Lexing.TokenType.StatementTerminator,  ";")
	:AddPlainSymbols  (GCompute.Lexing.TokenType.Newline,             {"\r\n", "\r", "\n"})
	:AddPatternSymbol (GCompute.Lexing.TokenType.Whitespace,           "[ \t]+")

LANGUAGE:GetKeywordClassifier ()
	:AddKeywords (GCompute.Lexing.KeywordType.Control,  {"if", "else", "elseif", "while", "for", "foreach", "do", "break", "switch", "case", "return", "continue"})
	:AddKeywords (GCompute.Lexing.KeywordType.DataType, {"namespace", "struct", "class", "enum", "using", "function", "local"})
	:AddKeywords (GCompute.Lexing.KeywordType.Constant, {"true", "false", "null"})

LANGUAGE:SetDirectiveCaseSensitivity (false)

local function parseVariables (compilationUnit, directive, directiveParser)
	directiveParser:AdvanceToken () -- @
	directiveParser:AdvanceToken () -- directive name
	directiveParser:AcceptWhitespace ()
	
	local variables = compilationUnit:GetExtraData (directive) or {}
	while directiveParser:AcceptType (GCompute.Lexing.TokenType.Identifier) do
		local variable = directiveParser:GetLastToken ().Value
		local typeExpression = nil
		directiveParser:AcceptWhitespace ()
		if directiveParser:Accept (":") then
			directiveParser:AcceptWhitespace ()
			if directiveParser:PeekType () == GCompute.Lexing.TokenType.Identifier then
				typeExpression = LANGUAGE:GetParserMetatable ().Type (directiveParser)
			else
				compilationUnit:Error ("Expected <type> after ':'.", directiveParser.CurrentToken.Line, directiveParser.CurrentToken.Character)
			end
		end
		
		if typeExpression and typeExpression:Is ("Identifier") then
			if typeExpression:GetName () == "number" or
			   typeExpression:GetName () == "string" then
				local nameIndex = GCompute.AST.NameIndex ()
				nameIndex:SetLeftExpression (GCompute.AST.Identifier ("Expression2"))
				nameIndex:SetIdentifier (typeExpression)
				typeExpression = nameIndex
			end
		end
		
		variables [#variables + 1] =
		{
			Name = variable,
			Type = GCompute.DeferredObjectResolution (typeExpression or "Expression2.number", GCompute.ResolutionObjectType.Type)
		}
		
		directiveParser:AcceptWhitespace ()
	end
	compilationUnit:SetExtraData (directive, variables)
end

LANGUAGE:AddDirective ("inputs", parseVariables)
LANGUAGE:AddDirective ("outputs", parseVariables)
LANGUAGE:AddDirective ("persist", parseVariables)

LANGUAGE:LoadEditorHelper ("expression2_editorhelper.lua")
LANGUAGE:LoadParser ("expression2_parser.lua")
LANGUAGE:LoadPass ("expression2_postparser.lua", GCompute.CompilerPassType.PostParser)
LANGUAGE:LoadPass ("expression2_iopvariables.lua", GCompute.CompilerPassType.PostParser)
LANGUAGE:LoadPass ("expression2_typefixer.lua", GCompute.CompilerPassType.PostParser)
LANGUAGE:LoadPass ("expression2_implicitvariabledeclaration.lua", GCompute.CompilerPassType.PostNamespaceBuilder)
LANGUAGE:LoadPass ("expression2_typefixer2.lua", GCompute.CompilerPassType.PreNameResolution)