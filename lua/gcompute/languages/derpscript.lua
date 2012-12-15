local LANGUAGE = GCompute.Languages.Create ("Derpscript")

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
			local endOffset = string.find (code, "*/", offset + 2, true)
			if endOffset then
				return string.sub (code, offset, endOffset + 1), endOffset - offset + 2
			end
			return string.sub (code, offset), code:len () - offset + 1
		end
	)
	:AddPatternSymbol (GCompute.TokenType.Comment,              "//[^\n\r]*")
	:AddPatternSymbol (GCompute.TokenType.Identifier,           "[a-zA-Z_][a-zA-Z0-9_]*")
	:AddPatternSymbol (GCompute.TokenType.Number,               "0b[01]+")
	:AddPatternSymbol (GCompute.TokenType.Number,               "0x[0-9a-fA-F]+")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[-+]?[0-9]+%.[0-9]*e[-+]?[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[-+]?[0-9]+%.[0-9]*e[-+]?[0-9]+")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[-+]?[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[-+]?[0-9]+e[-+]?[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[-+]?[0-9]+e[-+]?[0-9]+")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[-+]?[0-9]+")
	:AddPlainSymbols  (GCompute.TokenType.Operator,            {"##", "++", "--", "::", "->", "==", "!=", ">=", "<=", "+=", "-=", "*=", "/=", "^=", "||", "&&"})
	:AddPlainSymbols  (GCompute.TokenType.Operator,            {"#", "@", "!", "~", "+", "-", "^", "&", "|", "*", "/", "=", "<", ">", "(", ")", "{", "}", "[", "]", "%", "?", ":", ".", ","})
	:AddPlainSymbol   (GCompute.TokenType.StatementTerminator,  ";")
	:AddPlainSymbols  (GCompute.TokenType.Newline,             {"\r\n", "\r", "\n"})
	:AddPatternSymbol (GCompute.TokenType.Whitespace,           "[ \t]+")

LANGUAGE:AddKeywords (GCompute.KeywordType.Control,  {"if", "else", "while", "for", "do", "break", "switch", "new"})
LANGUAGE:AddKeywords (GCompute.KeywordType.Modifier, {"public", "private", "protected", "friend", "static", "const"})
LANGUAGE:AddKeywords (GCompute.KeywordType.DataType, {"namespace", "struct", "class", "enum", "using"})
LANGUAGE:AddKeywords (GCompute.KeywordType.Constant, {"true", "false", "null"})

LANGUAGE:LoadParser ("derpscript_parser.lua")