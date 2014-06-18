local LANGUAGE = GCompute.Languages.Create ("Derpscript")

-- Lexer
LANGUAGE:GetTokenizer ()
	:AddCustomSymbols (GCompute.Lexing.TokenType.String, {"\"", "'"},
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
	:AddCustomSymbol (GCompute.Lexing.TokenType.Comment, "/*",
		function (code, offset)
			local endOffset = string.find (code, "*/", offset + 2, true)
			if endOffset then
				return string.sub (code, offset, endOffset + 1), endOffset - offset + 2
			end
			return string.sub (code, offset), code:len () - offset + 1
		end
	)
	:AddPatternSymbol (GCompute.Lexing.TokenType.Comment,              "//[^\n\r]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Identifier,           "[a-zA-Z_][a-zA-Z0-9_]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "0b[01]+")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "0x[0-9a-fA-F]+")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+%.[0-9]*e[-+]?[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+%.[0-9]*e[-+]?[0-9]+")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+e[-+]?[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+e[-+]?[0-9]+")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+")
	:AddPlainSymbols  (GCompute.Lexing.TokenType.Operator,            {"##", "++", "--", "->", "==", "!=", ">=", "<=", "+=", "-=", "*=", "/=", "^=", "||", "&&"})
	:AddPlainSymbols  (GCompute.Lexing.TokenType.MemberIndexer,       {".", "::", ":"})
	:AddPlainSymbols  (GCompute.Lexing.TokenType.Operator,            {"#", "@", "!", "~", "+", "-", "^", "&", "|", "*", "/", "=", "<", ">", "(", ")", "{", "}", "[", "]", "%", "?", ","})
	:AddPlainSymbol   (GCompute.Lexing.TokenType.StatementTerminator,  ";")
	:AddPlainSymbols  (GCompute.Lexing.TokenType.Newline,             {"\r\n", "\r", "\n"})
	:AddPatternSymbol (GCompute.Lexing.TokenType.Whitespace,           "[ \t]+")

LANGUAGE:AddKeywords (GCompute.Lexing.KeywordType.Control,  {"if", "else", "while", "for", "do", "break", "switch", "new"})
LANGUAGE:AddKeywords (GCompute.Lexing.KeywordType.Modifier, {"public", "private", "protected", "friend", "static", "const"})
LANGUAGE:AddKeywords (GCompute.Lexing.KeywordType.DataType, {"namespace", "struct", "class", "enum", "using"})
LANGUAGE:AddKeywords (GCompute.Lexing.KeywordType.Constant, {"true", "false", "null"})

LANGUAGE:LoadParser ("derpscript_parser.lua")