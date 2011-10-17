local LANGUAGE = GCompute.Languages.Create ("Derpscript")

-- Tokenizer
LANGUAGE:AddCustomSymbols ({"\"", "'"}, GCompute.TokenTypes.String, function (Code)
	local i = 2
	local Escaped = false
	while true do
		local c = Code:sub (i, i)
		if c == "" then
			return Code:sub (1, i) .. Code:sub (1, 1), i
		else
			if Escaped then
				Escaped = false
			else
				if c == "\\" then
					Escaped = true
				elseif c == Code:sub (1, 1) then
					return Code:sub (1, i), i
				end
			end
		end
		i = i + 1
	end
end)
LANGUAGE:AddCustomSymbol ("/*", GCompute.TokenTypes.Comment, function (Code)
	local i = 3
	while true do
		local c = Code:sub (i, i + 1)
		if c == "" then
			return Code:sub (1, i), i
		elseif c == "*/" then
			return Code:sub (1, i + 1), i + 1
		end
		i = i + 1
	end
	return nil, 0
end)
LANGUAGE:AddSymbol ("//[^\n\r]*", GCompute.TokenTypes.Comment)
LANGUAGE:AddSymbol ("[a-zA-Z_][a-zA-Z0-9_]*", GCompute.TokenTypes.Identifier)
LANGUAGE:AddSymbol ("0x[0-9a-fA-F]+", GCompute.TokenTypes.Number)
LANGUAGE:AddSymbol ("[0-9]+%.[0-9]*e[+\\-]?[0-9]+", GCompute.TokenTypes.Number)
LANGUAGE:AddSymbol ("[0-9]+%.[0-9]*", GCompute.TokenTypes.Number)
LANGUAGE:AddSymbol ("[0-9]+e[+\\-]?[0-9]+", GCompute.TokenTypes.Number)
LANGUAGE:AddSymbol ("[0-9]+", GCompute.TokenTypes.Number)
LANGUAGE:AddSymbols ({"##", "++", "--", "::", "->", "==", "!=", ">=", "<=", "+=", "-=", "*=", "/=", "^=", "||", "&&"}, GCompute.TokenTypes.Operator, false)
LANGUAGE:AddSymbols ({"#", "@", "!", "~", "+", "-", "^", "&", "|", "*", "/", "=", "<", ">", "(", ")", "{", "}", "[", "]", "%", "?", ":", ".", ","}, GCompute.TokenTypes.Operator, false)
LANGUAGE:AddSymbol (";", GCompute.TokenTypes.StatementTerminator, false)
LANGUAGE:AddSymbols ({"\r\n", "\n\r", "\r", "\n"}, GCompute.TokenTypes.Newline, false)
LANGUAGE:AddSymbol ("[ \t]+", GCompute.TokenTypes.Whitespace)

LANGUAGE:AddKeywords ({"if", "else", "while", "for", "do", "break", "switch", "new"}, GCompute.KeywordTypes.Control)
LANGUAGE:AddKeywords ({"public", "private", "protected", "friend", "static", "const"}, GCompute.KeywordTypes.Modifier)
LANGUAGE:AddKeywords ({"namespace", "struct", "class", "enum"}, GCompute.KeywordTypes.DataType)
LANGUAGE:AddKeywords ({"true", "false", "null"}, GCompute.KeywordTypes.Constants)

LANGUAGE:LoadParser ()