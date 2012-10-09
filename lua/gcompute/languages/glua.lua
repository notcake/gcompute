local LANGUAGE = GCompute.Languages.Create ("GLua")
GCompute.LanguageDetector:AddPathPattern (LANGUAGE, "%.lua$")
GCompute.LanguageDetector:AddPathPattern (LANGUAGE, "/luapad/")
GCompute.LanguageDetector:AddPathPattern (LANGUAGE, "/starfall/")

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
	:AddCustomSymbol (GCompute.TokenType.String, "[[",
		function (code, offset)
			local i = offset + 2
			while true do
				local c = code:sub (i, i + 1)
				if c == "" then
					return code:sub (offset, i), i
				elseif c == "]]" then
					return code:sub (offset, i + 1), i - offset + 2
				end
				i = i + 1
			end
			return nil, 0
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
	:AddCustomSymbol (GCompute.TokenType.Comment, "--[[",
		function (code, offset)
			local i = offset + 4
			while true do
				local c = code:sub (i, i + 1)
				if c == "" then
					return code:sub (offset, i), i
				elseif c == "]]" then
					return code:sub (offset, i + 1), i - offset + 2
				end
				i = i + 1
			end
			return nil, 0
		end
	)
	:AddPatternSymbol (GCompute.TokenType.Comment,              "//[^\n\r]*")
	:AddPatternSymbol (GCompute.TokenType.Comment,              "%-%-[^\n\r]*")
	:AddPatternSymbol (GCompute.TokenType.Identifier,           "[a-zA-Z_][a-zA-Z0-9_]*")
	:AddPatternSymbol (GCompute.TokenType.Number,               "0b[01]+")
	:AddPatternSymbol (GCompute.TokenType.Number,               "0x[0-9a-fA-F]+")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[-+]?[0-9]+%.[0-9]*e[-+]?[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[-+]?[0-9]+%.[0-9]*e[-+]?[0-9]+")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[-+]?[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[-+]?[0-9]+e[-+]?[0-9]+%.[0-9]*")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[-+]?[0-9]+e[-+]?[0-9]+")
	:AddPatternSymbol (GCompute.TokenType.Number,               "[-+]?[0-9]+")
	:AddPlainSymbols  (GCompute.TokenType.Operator,            {"==", "~="})
	:AddPlainSymbols  (GCompute.TokenType.Operator,            {"!=", "||", "&&", ">>", "<<"})
	:AddPlainSymbols  (GCompute.TokenType.Operator,            {"#", "+", "-", "^", "*", "/", "=", "<", ">", "(", ")", "{", "}", "[", "]", "%", ":", ".", ","})
	:AddPlainSymbols  (GCompute.TokenType.Operator,            {"!", "~", "&", "|"})
	:AddPlainSymbols  (GCompute.TokenType.Operator,            {"and", "or"})
	:AddPlainSymbols  (GCompute.TokenType.Newline,             {"\r\n", "\r", "\n"})
	:AddPatternSymbol (GCompute.TokenType.Whitespace,           "[ \t]+")

LANGUAGE:AddKeywords (GCompute.KeywordType.Modifier, {"function", "local"})
LANGUAGE:AddKeywords (GCompute.KeywordType.Control,  {"if", "then", "else", "elseif", "end", "while", "for", "in", "do", "break", "repeat", "until", "return"})
LANGUAGE:AddKeyword  (GCompute.KeywordType.Control,   "continue")
LANGUAGE:AddKeywords (GCompute.KeywordType.Operator, {"not", "and", "or"})
LANGUAGE:AddKeywords (GCompute.KeywordType.Constant, {"true", "false", "nil"})

LANGUAGE:LoadEditorHelper ("glua_editorhelper.lua")