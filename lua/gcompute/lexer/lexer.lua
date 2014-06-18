local self = {}
GCompute.Lexing.Lexer = GCompute.MakeConstructor (self)

--[[
	Events:
		Progress (bytesProcessed, totalBytes)
			Fired when the lexer has processed some data.
		RangeAdded (Token startToken, Token endToken)
			Fired when a range of tokens has been inserted.
		RangeRemoved (Token startToken, Token endToken)
			Fired when a range of tokens has been removed.
]]

local string_find = string.find
local string_len  = string.len
local string_sub  = string.sub

local GLib_UTF8_Length   = GLib.UTF8.Length
local GLib_UTF8_NextChar = GLib.UTF8.NextChar

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	
	self.Code = nil
	self.Language = nil
	
	self.Callback = nil
	
	self.Tokens = compilationUnit:GetTokens ()
	self.Offset = 1
	self.Line = 0
	self.Character = 0
	
	GCompute.EventProvider (self)
end

function self:GetBytesProcessed ()
	return self.Offset - 1
end

function self:GetProgress ()
	if not self.Code then return 0 end
	return self:GetBytesProcessed () / self:GetTotalBytes ()
end

function self:GetTotalBytes ()
	if not self.Code then return 0 end
	return string.len (self.Code)
end

function self:Process (code, language, callback)
	self.Code = code
	self.Language = language
	self.Callback = callback or GCompute.NullCallback
	
	self.Offset = 1
	self.Line = 0
	self.Character = 0
	
	self.StartTime = SysTime ()
	self.TickStartTime = SysTime ()
	self:ProcessSome ()
end

function self:ProcessSome ()
	local GCompute_Lexing_KeywordType_Unknown = GCompute.Lexing.KeywordType.Unknown
	local GCompute_Lexing_TokenType_EndOfFile        = GCompute.Lexing.TokenType.EndOfFile
	local GCompute_Lexing_TokenType_Keyword          = GCompute.Lexing.TokenType.Keyword
	local GCompute_Lexing_TokenType_Unknown          = GCompute.Lexing.TokenType.Unknown
	
	local tokensProcessed
	
	local language          = self.Language
	local keywordClassifier = language:GetKeywordClassifier ()
	local tokenizer         = language:GetTokenizer ()
	
	local code              = self.Code
	local codeLength        = string_len (self.Code)
	local tokens            = self.Tokens
	local offset            = self.Offset
	local line              = self.Line
	local character         = self.Character
	
	local startToken = tokens.Last
	
	local tickStartTime = self.TickStartTime
	
	-- Line break counting
	local crOffset = 0
	local lfOffset = 0
	
	while SysTime () - tickStartTime < 0.010 and offset <= codeLength do
		tokensProcessed = 0
		while tokensProcessed < 10 and offset <= codeLength do
			tokensProcessed = tokensProcessed + 1
		
			local startOffset = offset
			local match, matchLength, tokenType = tokenizer:MatchSymbol (code, offset)
			
			local lineCount = 0
			
			-- Count line breaks
			local lineStartOffset = offset
			local lastNewlineEnd = 1
			local matchEnd = offset + matchLength - 1
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
			local token = tokens:AddLast (match)
			
			-- Check if the token is a key word that has been classed as an identifier
			if keywordClassifier:GetKeywordType (match) ~= GCompute_Lexing_KeywordType_Unknown then
				tokenType = GCompute_Lexing_TokenType_Keyword
			end
			
			token.TokenType    = tokenType
			token.Line         = line
			token.Character    = character
			token.EndLine      = line + lineCount
			if lineCount > 0 then
				character = GLib_UTF8_Length (string_sub (code, lastNewlineEnd, offset + matchLength - 1))
			else
				character = character + GLib_UTF8_Length (match)
			end
			token.EndCharacter = character
			
			-- Advance position in the input string
			offset = offset + matchLength
			line = line + lineCount
		end
	end
	
	self.Offset    = offset
	self.Line      = line
	self.Character = character
	
	self.CompilationUnit:Debug ("Lexer tick took " .. string.format ("%.3f", (SysTime () - self.TickStartTime) * 1000) .. " ms, now at " .. string.format ("%.2f", self:GetProgress () * 100) .. "%.")
	if self.Offset <= string_len (self.Code) then
		GLib.CallDelayed (
			function ()
				self.TickStartTime = SysTime ()
				self:ProcessSome ()
			end
		)
	else
		local token        = self.Tokens:AddLast ("<eof>")
		token.TokenType    = GCompute_Lexing_TokenType_EndOfFile
		token.Line         = self.Line
		token.Character    = self.Character
		token.EndLine      = self.Line
		token.EndCharacter = self.Character
	end
	
	if startToken == nil then startToken = tokens.First end
	local endToken = tokens.Last
	self:DispatchEvent ("LexerProgress", self:GetBytesProcessed (), self:GetTotalBytes ())
	self:DispatchEvent ("RangeAdded", startToken, endToken)
	
	if self:GetBytesProcessed () >= self:GetTotalBytes () then
		self.CompilationUnit:Debug ("Lexer took " .. ((SysTime () - self.StartTime) * 1000) .. " ms")
		self.Callback (self.Tokens)
	end
end