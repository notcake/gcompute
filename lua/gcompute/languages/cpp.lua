local LANGUAGE = GCompute.Languages.Create ("C++")
GCompute.LanguageDetector:AddExtension (LANGUAGE, "cpp")
GCompute.LanguageDetector:AddExtension (LANGUAGE, "h")

-- Lexer
LANGUAGE:GetTokenizer ()
	:AddCustomSymbols (GCompute.TokenType.String, {"\"", "'"},
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
	:AddCustomSymbol (GCompute.TokenType.Comment, "/*",
		function (code, offset)
			local endOffset = string.find (code, "*/", offset + 2, true)
			if endOffset then
				return string.sub (code, offset, endOffset + 1), endOffset - offset + 2
			end
			return string.sub (code, offset), string.len (code) - offset + 1
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
	:AddPlainSymbols  (GCompute.TokenType.Operator,            {"##", "++", "--", "==", "!=", "<=", ">=", "<<=", ">>=", "+=", "-=", "*=", "/=", "^=", "||", "&&", "^^", ">>", "<<"})
	:AddPlainSymbols  (GCompute.TokenType.Operator,            {"#", "!", "~", "+", "-", "^", "&", "|", "*", "/", "=", "<", ">", "(", ")", "{", "}", "[", "]", "%", "?", ":", ".", ","})
	:AddPlainSymbols  (GCompute.TokenType.Operator,            {"new", "delete"})
	:AddPlainSymbol   (GCompute.TokenType.StatementTerminator,  ";")
	:AddPlainSymbols  (GCompute.TokenType.Newline,             {"\r\n", "\r", "\n"})
	:AddPatternSymbol (GCompute.TokenType.Whitespace,           "[ \t]+")

LANGUAGE:AddKeywords (GCompute.KeywordType.Control,  {"if", "else", "while", "for", "do", "break", "switch", "return", "continue"})
LANGUAGE:AddKeywords (GCompute.KeywordType.DataType, {"namespace", "struct", "class", "enum", "union", "using"})
LANGUAGE:AddKeywords (GCompute.KeywordType.DataType, {"typedef", "static", "public", "private", "protected", "virtual"})
LANGUAGE:AddKeywords (GCompute.KeywordType.DataType, {"unsigned", "signed"})
LANGUAGE:AddKeywords (GCompute.KeywordType.DataType, {"void", "bool", "char", "short", "int", "long", "float", "double"})
LANGUAGE:AddKeywords (GCompute.KeywordType.Constant, {"true", "false", "this", "NULL"})

LANGUAGE:SetDirectiveCaseSensitivity (false)