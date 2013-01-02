--[[
	Lemon Gate
	
	Credit goes to Rusketh and Okar94
]]

local LANGUAGE = GCompute.Languages.Create ("Lemon Gate")
GCompute.LanguageDetector:AddPathPattern (LANGUAGE, "/lemongate/.*")

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
	:AddCustomSymbol (GCompute.TokenType.Comment, "#[",
		function (code, offset)
			local endOffset = string.find (code, "]#", offset + 2, true)
			if endOffset then
				return string.sub (code, offset, endOffset + 1), endOffset - offset + 2
			end
			return string.sub (code, offset), string.len (code) - offset + 1
		end
	)
	:AddPatternSymbol (GCompute.TokenType.Comment,              "#[^\n\r]*")
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
	:AddPlainSymbols  (GCompute.TokenType.MemberIndexer,       {".", ":"})
	:AddPlainSymbols  (GCompute.TokenType.Operator,            {"!", "~", "+", "-", "^", "&", "|", "*", "/", "=", "<", ">", "(", ")", "{", "}", "[", "]", "%", "?", ","})
	:AddPlainSymbol   (GCompute.TokenType.Preprocessor,         "@")
	:AddPlainSymbol   (GCompute.TokenType.StatementTerminator,  ";")
	:AddPlainSymbols  (GCompute.TokenType.Newline,             {"\r\n", "\r", "\n"})
	:AddPatternSymbol (GCompute.TokenType.Whitespace,           "[ \t]+")

LANGUAGE:AddKeywords (GCompute.KeywordType.Control,  {"if", "else", "elseif", "while", "for", "foreach", "do", "try", "catch", "finally"})
LANGUAGE:AddKeywords (GCompute.KeywordType.Control,  {"break", "switch", "return", "continue", "throw"})
LANGUAGE:AddKeywords (GCompute.KeywordType.DataType, {"function", "event"})
LANGUAGE:AddKeywords (GCompute.KeywordType.Constant, {"true", "false", "null"})

LANGUAGE:SetDirectiveCaseSensitivity (false)

LANGUAGE:LoadEditorHelper ("lemongate_editorhelper.lua")

LANGUAGE.WaitingNamespaces = GCompute.WeakKeyTable ()

function LANGUAGE:IsDataAvailable ()
	if not LemonGate then return false end
	
	if not LemonGate.TypeTable     then return false end
	if not LemonGate.FunctionTable then return false end
	if not LemonGate.OperatorTable then return false end
	if not LemonGate.EventsTable   then return false end
	return true
end

function LANGUAGE:RequestData (lemonGateNamespace)
	if self:IsDataAvailable () then return end
	if not LemonGate then return end
	
	if lemonGateNamespace then
		self.WaitingNamespaces [lemonGateNamespace] = true
	end
	
	RunConsoleCommand ("lemon_sync")
	
	timer.Create ("GCompute.LemonGate.DataCheck", 1, 0,
		function ()
			if not self:IsDataAvailable () then return end
			
			for lemonGateNamespace, _ in pairs (self.WaitingNamespaces) do
				lemonGateNamespace:ImportData ()
			end
			
			self:DispatchEvent ("NamespaceChanged")
			
			timer.Destroy ("GCompute.LemonGate.DataCheck")
		end
	)
	
	GCompute:AddEventListener ("Unloaded",
		function ()
			timer.Destroy ("GCompute.LemonGate.DataCheck")
		end
	)
end