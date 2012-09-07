local self = {}
GCompute.Lexer = GCompute.MakeConstructor (self)

--[[
	Events:
		RangeAdded (Token startToken, Token endToken)
			Fired when a range of tokens has been inserted.
		RangeRemoved (Token startToken, Token endToken)
			Fired when a range of tokens has been removed.
]]

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
	local tokensProcessed = 1
	
	local code       = self.Code
	local codeLength = string.len (self.Code)
	local language   = self.Language
	local tokenizer  = language:GetTokenizer ()
	local tokens     = self.Tokens
	local offset     = self.Offset
	local line       = self.Line
	local character  = self.Character
	
	local startToken = tokens.Last
	
	local tickStartTime = self.TickStartTime
	while SysTime () - tickStartTime < 0.015 and offset <= codeLength do
		while tokensProcessed < 50 and offset <= codeLength do
			tokensProcessed = tokensProcessed + 1
		
			local startOffset = offset
			local match, matchLength, tokenType = tokenizer:MatchSymbol (code, offset)
			
			local lineCount = 0
			
			-- Count line breaks
			local lineStartOffset = offset
			local lastNewlineEnd = 1
			local matchEnd = offset + matchLength - 1
			while lineStartOffset <= matchEnd do
				local crOffset = string.find (code, "\r", lineStartOffset, true)
				local lfOffset = string.find (code, "\n", lineStartOffset, true)
				local newlineOffset = crOffset or lfOffset
				if crOffset and crOffset < newlineOffset then newlineOffset = crOffset end
				if lfOffset and lfOffset < newlineOffset then newlineOffset = lfOffset end
				if newlineOffset then
					if newlineOffset > matchEnd then break end
					if string.sub (code, newlineOffset, newlineOffset + 1) == "\r\n" then
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
			
			if match == "" then
				ErrorNoHalt ("Lexer: Matched a zero-length string! (" .. GCompute.TokenTypes [tokenType] .. ")\n")
				match = nil
			end
			
			if match then
				-- Symbol successfully matched
				local token = tokens:AddLast (match)
				
				-- Check if the token is a key word that has been classed as an identifier
				if language:GetKeywordType (match) ~= GCompute.KeywordType.Unknown then
					tokenType = GCompute.TokenType.Keyword
				end
				
				token.TokenType    = tokenType
				token.Line         = line
				token.Character    = character
				token.EndLine      = line + lineCount
				if lineCount > 0 then
					character = GLib.UTF8.Length (string.sub (code, lastNewlineEnd, offset + matchLength - 1))
				else
					character = character + matchLength
				end
				token.EndCharacter = character
			else
				-- Unable to match symbol, take one character and mark it as unknown
				local token        = tokens:AddLast (string.sub (code, offset, offset))
				token.TokenType    = GCompute.TokenType.Unknown
				token.Line         = line
				token.Character    = character
				token.EndLine      = line
				if token.Value == "\r" or token.Value == "\n" then
					token.EndLine      = token.EndLine + 1
					lineCount = 1
					character = 0
				else
					character = character + 1
				end
				token.EndCharacter = character
				matchLength = 1
			end
			
			offset = offset + matchLength
			
			-- print ("\"" .. GLib.String.Escape (string.sub (code, offset - matchLength, offset - 1)) .. "\" " .. tostring (lineCount) .. "\n(" .. self.Tokens.Last.Line .. ", " .. self.Tokens.Last.Character .. ") -> (" .. self.Tokens.Last.EndLine .. ", " .. self.Tokens.Last.EndCharacter .. ")")
			
			line = line + lineCount
		end
	end
	
	self.Offset    = offset
	self.Line      = line
	self.Character = character
	
	print ("Lexer tick took " .. ((SysTime () - self.TickStartTime) * 1000) .. " ms, now at " .. ((self.Offset / (string.len (self.Code) + 1)) * 100) .. "%.")
	self.CompilationUnit:Debug ("Lexer tick took " .. ((SysTime () - self.TickStartTime) * 1000) .. " ms, now at " .. ((self.Offset / (string.len (self.Code) + 1)) * 100) .. "%.")
	if self.Offset <= string.len (self.Code) then
		timer.Simple (0,
			function ()
				self.TickStartTime = SysTime ()
				self:ProcessSome ()
			end
		)
	else
		local token        = self.Tokens:AddLast ("<eof>")
		token.TokenType    = GCompute.TokenType.EndOfFile
		token.Line         = self.Line
		token.Character    = self.Character
		token.EndLine      = self.Line
		token.EndCharacter = self.Character
		
		ErrorNoHalt ("Lexer took " .. ((SysTime () - self.StartTime) * 1000) .. " ms\n")
		self.Callback (self.Tokens)
	end
	
	if startToken == nil then startToken = tokens.First end
	local endToken = tokens.Last
	self:DispatchEvent ("RangeAdded", startToken, endToken)
end