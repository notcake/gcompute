local LANGUAGE = GCompute.Languages.Create ("GLua")
GCompute.LanguageDetector:AddExtension   (LANGUAGE, "lua")
GCompute.LanguageDetector:AddPathPattern (LANGUAGE, "%.lua$")
GCompute.LanguageDetector:AddPathPattern (LANGUAGE, "/luapad/")

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
	:AddCustomSymbol (GCompute.Lexing.TokenType.String, "[[",
		function (code, offset)
			local endOffset = string.find (code, "]]", offset + 2, true)
			if endOffset then
				return string.sub (code, offset, endOffset + 1), endOffset - offset + 2
			end
			return string.sub (code, offset), code:len () - offset + 1
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
	:AddCustomSymbol (GCompute.Lexing.TokenType.Comment, "--[[",
		function (code, offset)
			local endOffset = string.find (code, "]]", offset + 4, true)
			if endOffset then
				return string.sub (code, offset, endOffset + 1), endOffset - offset + 2
			end
			return string.sub (code, offset), code:len () - offset + 1
		end
	)
	:AddPatternSymbol (GCompute.Lexing.TokenType.Comment,              "//[^\n\r]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Comment,              "%-%-[^\n\r]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Identifier,           "[a-zA-Z_][a-zA-Z0-9_]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "0b[01]+")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "0x[0-9a-fA-F]+")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+%.[0-9]*e[-+]?[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+%.[0-9]*e[-+]?[0-9]+")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+e[-+]?[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+e[-+]?[0-9]+")
	:AddPatternSymbol (GCompute.Lexing.TokenType.Number,               "[0-9]+")
	:AddPlainSymbols  (GCompute.Lexing.TokenType.Operator,            {"==", "~=", "<=", ">="})
	:AddPlainSymbols  (GCompute.Lexing.TokenType.Operator,            {"!=", "||", "&&", ">>", "<<"})
	:AddPlainSymbol   (GCompute.Lexing.TokenType.Operator,             "..")
	:AddPlainSymbols  (GCompute.Lexing.TokenType.MemberIndexer,       {".", ":"})
	:AddPlainSymbols  (GCompute.Lexing.TokenType.Operator,            {"#", "+", "-", "^", "*", "/", "=", "<", ">", "(", ")", "{", "}", "[", "]", "%", ","})
	:AddPlainSymbols  (GCompute.Lexing.TokenType.Operator,            {"!", "~", "&", "|"})
	:AddPlainSymbols  (GCompute.Lexing.TokenType.Operator,            {"not", "and", "or"})
	:AddPlainSymbol   (GCompute.Lexing.TokenType.StatementTerminator,  ";")
	:AddPlainSymbols  (GCompute.Lexing.TokenType.Newline,             {"\r\n", "\r", "\n"})
	:AddPatternSymbol (GCompute.Lexing.TokenType.Whitespace,           "[ \t]+")

LANGUAGE:AddKeywords (GCompute.Lexing.KeywordType.Modifier, {"function", "local"})
LANGUAGE:AddKeywords (GCompute.Lexing.KeywordType.Control,  {"if", "then", "else", "elseif", "end", "while", "for", "in", "do", "break", "repeat", "until", "return"})
LANGUAGE:AddKeyword  (GCompute.Lexing.KeywordType.Control,   "continue")
LANGUAGE:AddKeywords (GCompute.Lexing.KeywordType.Operator, {"not", "and", "or"})
LANGUAGE:AddKeywords (GCompute.Lexing.KeywordType.Constant, {"true", "false", "nil"})

LANGUAGE:LoadEditorHelper ("glua_editorhelper.lua")
LANGUAGE:LoadParser ("glua_parser.lua")