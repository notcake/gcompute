local self = {}
GCompute.Lexing.LexerTokenStream = GCompute.MakeConstructor (self, GCompute.Lexing.LinkedListTokenStream)

local string_find                         = string.find
local string_sub                          = string.sub

local GLib_UTF8_Length                    = GLib.UTF8.Length

local GCompute_Lexing_KeywordType_Unknown = GCompute.Lexing.KeywordType.Unknown
local GCompute_Lexing_TokenType_EndOfFile = GCompute.Lexing.TokenType.EndOfFile
local GCompute_Lexing_TokenType_Keyword   = GCompute.Lexing.TokenType.Keyword
local GCompute_Lexing_TokenType_Unknown   = GCompute.Lexing.TokenType.Unknown

function self:ctor (tokenizer, keywordClassifier, code)
	self.Tokenizer         = tokenizer
	self.KeywordClassifier = keywordClassifier
	
	self.Code              = code
	
	self.Offset            = 1
	self.Line              = 0
	self.Character         = 0
end

function self:GenerateNextToken ()
	-- Check for end of file
	if self.Offset > #self.Code then
		self:EmitEof ()
		return
	end
	
	local match, matchLength, tokenType = self.Tokenizer:MatchSymbol (self.Code, self.Offset)
	
	-- Count line breaks
	local lineCount = 0
	local lineStartOffset = self.Offset
	local lastNewlineEnd = 1
	local matchEnd = self.Offset + matchLength - 1
	while lineStartOffset <= matchEnd do
		if crOffset and crOffset < lineStartOffset then crOffset = string_find (code, "\r", lineStartOffset, true) end
		if lfOffset and lfOffset < lineStartOffset then lfOffset = string_find (code, "\n", lineStartOffset, true) end
		local newlineOffset = crOffset or lfOffset
		if lfOffset and lfOffset < newlineOffset then newlineOffset = lfOffset end
		if newlineOffset then
			if newlineOffset > matchEnd then break end
			if string_sub (code, newlineOffset, newlineOffset + 1) == "\r\n" then
				lineStartOffset = newlineOffset + 2
				lineCount = lineCount + 1
			else
				lineStartOffset = newlineOffset + 1
				lineCount = lineCount + 1
			end
			lastNewlineEnd = lineStartOffset
		else
			-- End of file, no newline found
			break
		end
	end
	
	-- Check for tokenizer bugs
	if match == "" then
		ErrorNoHalt ("Lexer: Matched a zero-length string! (" .. GCompute.Lexing.TokenType [tokenType] .. ")\n")
		match = nil
	end
	
	-- Build up the token
	local token = self:AddToken (match)
	
	-- Check if the token is a key word that has been classed as an identifier
	if self.KeywordClassifier:GetKeywordType (match) ~= GCompute_Lexing_KeywordType_Unknown then
		tokenType = GCompute_Lexing_TokenType_Keyword
	end
	
	token.TokenType    = tokenType
	token.Line         = self.Line
	token.Character    = self.Character
	token.EndLine      = self.Line + lineCount
	if lineCount > 0 then
		self.Character = GLib_UTF8_Length (string_sub (self.Code, lastNewlineEnd, self.Offset + matchLength - 1))
	else
		self.Character = self.Character + GLib_UTF8_Length (match)
	end
	token.EndCharacter = self.Character
	
	-- Advance position in the input string
	self.Offset = self.Offset + matchLength
	self.Line   = self.Line   + lineCount
end

-- Internal
function self:EmitEof ()
	local token        = self:AddToken ("<eof>")
	token.TokenType    = GCompute_Lexing_TokenType_EndOfFile
	token.Line         = self.Line
	token.Character    = self.Character
	token.EndLine      = self.Line
	token.EndCharacter = self.Character
	
	self:FinalizeTokens ()
end