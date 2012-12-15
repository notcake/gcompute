local LANGUAGE = GCompute.Languages.Create ("Brainfuck")

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
	:AddPatternSymbol (GCompute.TokenType.Comment,   "//[^\n\r]*")
	:AddPatternSymbol (GCompute.TokenType.Operator,  "[<>+\\-]+")
	:AddPlainSymbols  (GCompute.TokenType.Operator, {"[", "]"})

LANGUAGE:LoadParser ("brainfuck_parser.lua")