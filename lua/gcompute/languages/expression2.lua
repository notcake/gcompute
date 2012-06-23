local LANGUAGE = GCompute.Languages.Create ("Expression 2")

-- Tokenizer
LANGUAGE:AddCustomSymbols ({"\"", "'"}, GCompute.TokenType.String, function (code)
	local i = 2
	local escaped = false
	while true do
		local c = code:sub (i, i)
		if c == "" then
			return code:sub (1, i) .. code:sub (1, 1), i
		else
			if escaped then
				escaped = false
			else
				if c == "\\" then
					escaped = true
				elseif c == code:sub (1, 1) then
					return code:sub (1, i), i
				end
			end
		end
		i = i + 1
	end
end)
LANGUAGE:AddCustomSymbol ("/*", GCompute.TokenType.Comment, function (code)
	local i = 3
	while true do
		local c = code:sub (i, i + 1)
		if c == "" then
			return code:sub (1, i), i
		elseif c == "*/" then
			return code:sub (1, i + 1), i + 1
		end
		i = i + 1
	end
	return nil, 0
end)
LANGUAGE:AddSymbol ("#[^\n\r]*", GCompute.TokenType.Comment)
LANGUAGE:AddSymbol ("[a-zA-Z_][a-zA-Z0-9_]*", GCompute.TokenType.Identifier)
LANGUAGE:AddSymbol ("0b[01]+", GCompute.TokenType.Number)
LANGUAGE:AddSymbol ("0x[0-9a-fA-F]+", GCompute.TokenType.Number)
LANGUAGE:AddSymbol ("[0-9]+%.[0-9]*e[+\\-]?[0-9]+", GCompute.TokenType.Number)
LANGUAGE:AddSymbol ("[0-9]+%.[0-9]*", GCompute.TokenType.Number)
LANGUAGE:AddSymbol ("[0-9]+e[+\\-]?[0-9]+", GCompute.TokenType.Number)
LANGUAGE:AddSymbol ("[0-9]+", GCompute.TokenType.Number)
LANGUAGE:AddSymbols ({"##", "++", "--", "==", "!=", "<=", ">=", "<<=", ">>=", "+=", "-=", "*=", "/=", "^=", "||", "&&", "^^", ">>", "<<"}, GCompute.TokenType.Operator, false)
LANGUAGE:AddSymbols ({"#", "@", "!", "~", "+", "-", "^", "&", "|", "*", "/", "=", "<", ">", "(", ")", "{", "}", "[", "]", "%", "?", ":", ".", ","}, GCompute.TokenType.Operator, false)
LANGUAGE:AddSymbol (";", GCompute.TokenType.StatementTerminator, false)
LANGUAGE:AddSymbols ({"\r\n", "\n\r", "\r", "\n"}, GCompute.TokenType.Newline, false)
LANGUAGE:AddSymbol ("[ \t]+", GCompute.TokenType.Whitespace)

LANGUAGE:AddKeywords ({"if", "else", "elseif", "while", "for", "do", "break", "switch"}, GCompute.KeywordTypes.Control)
LANGUAGE:AddKeywords ({"namespace", "struct", "class", "enum", "using", "function"}, GCompute.KeywordTypes.DataType)
LANGUAGE:AddKeywords ({"true", "false", "null"}, GCompute.KeywordTypes.Constants)

LANGUAGE:LoadParser ("expression2_parser.lua")
LANGUAGE:LoadPass ("expression2_implicitvariabledeclaration.lua", GCompute.CompilerPassType.PostNamespaceBuilder)