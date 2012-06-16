local self = {}
GCompute.Preprocessor = GCompute.MakeConstructor (self)

function self:Process (compilationUnit, tokens)
	local token = tokens.First
	--[[
		- Remove whitespace (done)
		- Remove comments (done)
		- Process escaped characters in strings (done)
		- Process (string) joins (done)
		- Collapse adjacent newlines
		
		- Read preprocessor directives
	]]
	while token do
		local nextToken = token.Next
		if (token.Value == "@" or
			token.Value == "#") and
			(not token.Previous or
			token.Previous.TokenType == GCompute.TokenType.Newline) then
			-- Preprocessor directive
			local tokensToRemove = self:ProcessDirective (compilationUnit, token) + 1
			for i = 1, tokensToRemove do
				tokens:Remove (token)
				token = nextToken
				nextToken = token.Next
			end
			nextToken = token
		elseif token.TokenType == GCompute.TokenType.Whitespace or
		   token.TokenType == GCompute.TokenType.Comment then
			-- Remove whitespace and comments
			tokens:Remove (token)
		elseif token.TokenType == GCompute.TokenType.String then
			-- Unescape strings and merge adjacent double-quoted strings
			local quoteType = token.Value:sub (1, 1)
			token.Value = self:UnescapeString (compilationUnit, token.Value)
		
			if quoteType == "\"" and
				token.Previous and
				token.Previous.TokenType == GCompute.TokenType.String then
				token.Previous.Value = token.Previous.Value .. token.Value
				tokens:Remove (token)
			end
		elseif token.TokenType == GCompute.TokenType.Newline and
				token.Previous and
				token.Previous.TokenType == GCompute.TokenType.Newline then
			-- Collapse multiple newlines into one
			tokens:Remove (token)
		elseif token.Value == "##" then
			-- Here be dragons
			-- Join the previous and next symbols
			if not token.Previous or
				not token.Next or
				token.Next.TokenType == GCompute.TokenType.Newline then
			else
				nextToken = nextToken.Next
				
				token.Previous.Value = token.Previous.Value .. token.Next.Value
				
				tokens:Remove (token.Next)
				tokens:Remove (token)
			end
		end
		token = nextToken
	end
end

function self:ProcessDirective (compilationUnit, token)
	local length = 0
	local initialToken = token
	while token.TokenType ~= GCompute.TokenType.Newline do
		length = length + 1
		token = token.Next
	end
	token = initialToken
	if length == 1 then
		compilationUnit:Error ("Preprocessor directive is missing.", token.Line, token.Character)
		return length
	end
	local directive = token.Next.Value
	compilationUnit:Debug ("Found preprocessor directive \"" .. directive .. "\".", initialToken.Line, initialToken.Character)
	return length
end

function self:UnescapeString (compilationUnit, string)
	string = string:sub (2, -2)
	return string:Replace ("\\\r", "\r")
			:Replace ("\\n", "\n")
			:Replace ("\\t", "\t")
			:Replace ("\\\"", "\"")
			:Replace ("\\\'", "\'")
			:Replace ("\\\\", "\\")
end

GCompute.Preprocessor = GCompute.Preprocessor ()