local LANGUAGE = GCompute.Languages.Create ("Expression 2")

-- Tokenizer
LANGUAGE:AddCustomSymbols ({"\"", "'"}, GCompute.TokenType.String,
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
LANGUAGE:AddCustomSymbol ("/*", GCompute.TokenType.Comment,
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
LANGUAGE:AddSymbol ("#[^\n\r]*", GCompute.TokenType.Comment)
LANGUAGE:AddSymbol ("[a-zA-Z_][a-zA-Z0-9_]*", GCompute.TokenType.Identifier)
LANGUAGE:AddSymbol ("0b[01]+", GCompute.TokenType.Number)
LANGUAGE:AddSymbol ("0x[0-9a-fA-F]+", GCompute.TokenType.Number)
LANGUAGE:AddSymbol ("[0-9]+%.[0-9]*e[+\\-]?[0-9]+", GCompute.TokenType.Number)
LANGUAGE:AddSymbol ("[0-9]+%.[0-9]*", GCompute.TokenType.Number)
LANGUAGE:AddSymbol ("[0-9]+e[+\\-]?[0-9]+", GCompute.TokenType.Number)
LANGUAGE:AddSymbol ("[0-9]+", GCompute.TokenType.Number)
LANGUAGE:AddSymbols ({"##", "++", "--", "==", "!=", "<=", ">=", "<<=", ">>=", "+=", "-=", "*=", "/=", "^=", "||", "&&", "^^", ">>", "<<"}, GCompute.TokenType.Operator, false)
LANGUAGE:AddSymbols ({"@", "!", "~", "+", "-", "^", "&", "|", "*", "/", "=", "<", ">", "(", ")", "{", "}", "[", "]", "%", "?", ":", ".", ","}, GCompute.TokenType.Operator, false)
LANGUAGE:AddSymbol (";", GCompute.TokenType.StatementTerminator, false)
LANGUAGE:AddSymbols ({"\r\n", "\n\r", "\r", "\n"}, GCompute.TokenType.Newline, false)
LANGUAGE:AddSymbol ("[ \t]+", GCompute.TokenType.Whitespace)

LANGUAGE:AddKeywords ({"if", "else", "elseif", "while", "for", "do", "break", "switch"}, GCompute.KeywordTypes.Control)
LANGUAGE:AddKeywords ({"namespace", "struct", "class", "enum", "using", "function"}, GCompute.KeywordTypes.DataType)
LANGUAGE:AddKeywords ({"true", "false", "null"}, GCompute.KeywordTypes.Constants)

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