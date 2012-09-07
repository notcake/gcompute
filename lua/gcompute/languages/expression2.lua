local LANGUAGE = GCompute.Languages.Create ("Expression 2")
GCompute.LanguageDetector:AddPathPattern (LANGUAGE, "/expression2/.*")

-- Lexer
LANGUAGE:GetTokenizer ()
	:AddCustomSymbols (GCompute.TokenType.String, {"\"", "'"},
		function (code, offset)
			local quotationMark = code:sub (offset, offset)
			local i = offset + 1
			local escaped = false
			while true do
				local c = code:sub (i, i)
				if c == "" then
					return code:sub (offset, i) .. quotationMark, i
				else
					if escaped then
						escaped = false
					else
						if c == "\\" then
							escaped = true
						elseif c == quotationMark then
							return code:sub (offset, i), i - offset + 1
						end
					end
				end
				i = i + 1
			end
		end
	)
	:AddCustomSymbol (GCompute.TokenType.Comment, "/*",
		function (code, offset)
			local i = offset + 2
			while true do
				local c = code:sub (i, i + 1)
				if c == "" then
					return code:sub (offset, i), i
				elseif c == "*/" then
					return code:sub (offset, i + 1), i - offset + 2
				end
				i = i + 1
			end
			return nil, 0
		end
	)
	:AddPatternSymbol (GCompute.TokenType.Comment,              "#[^\n\r]*")
	:AddPatternSymbol (GCompute.TokenType.Identifier,           "[a-zA-Z_][a-zA-Z0-9_]*")
	:AddPatternSymbol (GCompute.TokenType.Number,               "0b[01]+")
	:AddPatternSymbol (GCompute.TokenType.Number,               "0x[0-9a-fA-F]+")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[0-9]+%.[0-9]*e[+\\-]?[0-9]+")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[0-9]+e[+\\-]?[0-9]+")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[0-9]+")
	:AddPlainSymbols  (GCompute.TokenType.Operator,            {"##", "++", "--", "==", "!=", "<=", ">=", "<<=", ">>=", "+=", "-=", "*=", "/=", "^=", "||", "&&", "^^", ">>", "<<"})
	:AddPlainSymbols  (GCompute.TokenType.Operator,            {"@", "!", "~", "+", "-", "^", "&", "|", "*", "/", "=", "<", ">", "(", ")", "{", "}", "[", "]", "%", "?", ":", ".", ","})
	:AddPlainSymbol   (GCompute.TokenType.StatementTerminator,  ";")
	:AddPlainSymbols  (GCompute.TokenType.Newline,             {"\r\n", "\r", "\n"})
	:AddPatternSymbol (GCompute.TokenType.Whitespace,           "[ \t]+")

LANGUAGE:AddKeywords ({"if", "else", "elseif", "while", "for", "do", "break", "switch", "return", "continue"}, GCompute.KeywordType.Control)
LANGUAGE:AddKeywords ({"namespace", "struct", "class", "enum", "using", "function"}, GCompute.KeywordType.DataType)
LANGUAGE:AddKeywords ({"true", "false", "null"}, GCompute.KeywordType.Constant)

LANGUAGE:SetDirectiveCaseSensitivity (false)

local function parseVariables (compilationUnit, directive, directiveParser)
	directiveParser:GetNextToken () -- @
	directiveParser:GetNextToken () -- directive name
	directiveParser:AcceptWhitespace ()
	
	local variables = compilationUnit:GetExtraData (directive) or {}
	while directiveParser:AcceptType (GCompute.TokenType.Identifier) do
		local variable = directiveParser:GetLastToken ().Value
		local typeExpression = nil
		directiveParser:AcceptWhitespace ()
		if directiveParser:Accept (":") then
			directiveParser:AcceptWhitespace ()
			if directiveParser:PeekType () == GCompute.TokenType.Identifier then
				typeExpression = LANGUAGE:GetParserMetatable ().Type (directiveParser)
			else
				compilationUnit:Error ("Expected <type> after ':'.", directiveParser.TokenNode.Line, directiveParser.TokenNode.Character)
			end
		end
		
		variables [#variables + 1] =
		{
			Name = variable,
			Type = GCompute.DeferredNameResolution (typeExpression or "Expression2.number")
		}
		variables [#variables].Type:SetErrorReporter (compilationUnit)
		
		directiveParser:AcceptWhitespace ()
	end
	compilationUnit:SetExtraData (directive, variables)
end

LANGUAGE:AddDirective ("inputs", parseVariables)
LANGUAGE:AddDirective ("outputs", parseVariables)
LANGUAGE:AddDirective ("persist", parseVariables)

LANGUAGE:LoadParser ("expression2_parser.lua")
LANGUAGE:LoadPass ("expression2_iopvariables.lua", GCompute.CompilerPassType.PostParser)
LANGUAGE:LoadPass ("expression2_typefixer.lua", GCompute.CompilerPassType.PostParser)
LANGUAGE:LoadPass ("expression2_implicitvariabledeclaration.lua", GCompute.CompilerPassType.PostNamespaceBuilder)