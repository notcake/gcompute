local self = {}
GCompute.Lexer = GCompute.MakeConstructor (self)

--[[
	Events:
		Progress (bytesProcessed, totalBytes)
			Fired when the lexer has processed some data.
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
	local tokensProcessed
	
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
	
	-- Line break counting
	local crOffset = 0
	local lfOffset = 0
			
	while SysTime () - tickStartTime < 0.010 * 10000 and offset <= codeLength do
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
				if crOffset and crOffset < lineStartOffset then crOffset = string.find (code, "\r", lineStartOffset, true) end
				if lfOffset and lfOffset < lineStartOffset then lfOffset = string.find (code, "\n", lineStartOffset, true) end
				local newlineOffset = crOffset or lfOffset
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
				ErrorNoHalt ("Lexer: Matched a zero-length string! (" .. GCompute.TokenType [tokenType] .. ")\n")
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
					character = character + GLib.UTF8.Length (match)
				end
				token.EndCharacter = character
			else
				-- Unable to match symbol, take one character and mark it as unknown
				local token        = tokens:AddLast (GLib.UTF8.NextChar (code, offset))
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
				matchLength = string.len (token.Value)
			end
			
			offset = offset + matchLength
			
			line = line + lineCount
		end
	end
	
	self.Offset    = offset
	self.Line      = line
	self.Character = character
	
	print ("Lexer tick took " .. ((SysTime () - self.TickStartTime) * 1000) .. " ms, now at " .. (self:GetProgress () * 100) .. "%.")
	self.CompilationUnit:Debug ("Lexer tick took " .. ((SysTime () - self.TickStartTime) * 1000) .. " ms, now at " .. (self:GetProgress () * 100) .. "%.")
	if self.Offset <= string.len (self.Code) then
		timer.Simple (0.001,
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
	end
	
	if startToken == nil then startToken = tokens.First end
	local endToken = tokens.Last
	self:DispatchEvent ("LexerProgress", self:GetBytesProcessed (), self:GetTotalBytes ())
	self:DispatchEvent ("RangeAdded", startToken, endToken)
	
	if self:GetBytesProcessed () >= self:GetTotalBytes () then
		ErrorNoHalt ("Lexer took " .. ((SysTime () - self.StartTime) * 1000) .. " ms\n")
		self.Callback (self.Tokens)
	end
end