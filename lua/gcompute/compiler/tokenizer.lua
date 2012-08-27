local self = {}
GCompute.Tokenizer = GCompute.MakeConstructor (self)

GCompute.TokenType =
{
	Unknown             =  0,
	Whitespace          =  1,
	Newline             =  2,
	Preprocessor        =  3,
	Number              =  4,
	Operator            =  5,
	Identifier          =  6,
	Keyword             =  7,
	String              =  8,
	Comment             =  9,
	StatementTerminator = 10,
	EndOfFile           = 11,
	AST                 = 12  -- Blob of already-parsed data
}
GCompute.InvertTable (GCompute.TokenType)
local TokenType = GCompute.TokenType

GCompute.KeywordTypes =
{
	Unknown		= 0,
	Control		= 1,
	Modifier	= 2,
	DataType	= 3,
	Constants	= 4
}
local KeywordTypes = GCompute.KeywordTypes
GCompute.InvertTable (KeywordTypes)

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	
	self.Code = nil
	self.Language = nil
	
	self.Callback = nil
	
	self.Tokens = nil
	self.Offset = 1
	self.Line = 1
	self.Character = 1
end

function self:Process (code, language, callback)
	self.Code = code
	self.Language = language
	self.Callback = callback or GCompute.NullCallback
	
	self.Tokens = GCompute.Containers.LinkedList ()
	self.Offset = 1
	self.Line = 1
	self.Character = 1
	
	self.TickStartTime = SysTime ()
	self:ProcessSome ()
end

function self:ProcessSome ()
	local tokensProcessed = 1
	
	local code       = self.Code
	local codeLength = self.Code:len ()
	local language   = self.Language
	local tokens     = self.Tokens
	local offset     = self.Offset
	local line       = self.Line
	local character  = self.Character
	
	while SysTime () - self.TickStartTime < 0.015 and offset <= codeLength do
		while tokensProcessed < 100 and offset <= codeLength do
			tokensProcessed = tokensProcessed + 1
		
			local startOffset = offset
			local match, matchLength, tokenType = language:MatchSymbol (code, offset)
			local original = code:sub (offset, offset + matchLength - 1)
			local originalLen = original:len ()
			
			local lineCount = 0
			
			-- Count newlines
			local i = 1
			while i <= originalLen do				
				-- Count \r\n and \n\r as 1 newline
				local c = original:sub (i, i)
				if c == "\r" or c == "\n" then
					local nextc = original:sub (i + 1, i + 1)
					lineCount = lineCount + 1
					if nextc == "\r" or nextc == "\n" then
						if c ~= nextc then
							i = i + 1
						end
					end
				end
				i = i + 1
			end
			
			if match then
				-- Symbol successfully matched
				local token = tokens:AddLast (match)
				
				-- Check if the token is a key word that has been classed as an identifier
				if language:GetKeywordType (match) ~= KeywordTypes.Unknown then
					tokenType = TokenType.Keyword
				end
				
				token.TokenType = tokenType
				token.Line      = line
				token.Character = character
				
				offset = offset + matchLength
			else
				-- Unable to match symbol, take one character and mark it as an identifier
				local token     = tokens:AddLast (code:sub (offset, offset))
				token.TokenType = TokenType.Identifier
				token.Line      = line
				token.Character = character
				
				offset = offset + 1
			end
			
			if lineCount > 0 then
				line = line + lineCount
				character = 1
			else
				character = character + matchLength
			end
		end
	end
	
	self.Offset    = offset
	self.Line      = line
	self.Character = character
	
	self.CompilationUnit:Debug ("Tokenizer tick took " .. ((SysTime () - self.TickStartTime) * 1000) .. " ms, now at " .. ((self.Offset / (self.Code:len () + 1)) * 100) .. "%.")
	if self.Offset <= self.Code:len () then
		timer.Simple (0,
			function ()
				self.TickStartTime = SysTime ()
				self:ProcessSome ()
			end
		)
	else
		local token     = self.Tokens:AddLast ("<eof>")
		token.TokenType = TokenType.EndOfFile
		token.Line      = self.Line
		token.Character = self.Character
		
		self.Callback (self.Tokens)
	end
end