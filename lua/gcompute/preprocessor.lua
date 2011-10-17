if not GCompute.Preprocessor then
	GCompute.Preprocessor = {}
end
local Preprocessor = GCompute.Preprocessor
Preprocessor.__index = Preprocessor

function Preprocessor.Process (CompilerContext, Tokens)
	local TokenNode = Tokens.First
	--[[
		- Remove whitespace (done)
		- Remove comments (done)
		- Process escaped characters in strings (done)
		- Process (string) joins (done)
		- Collapse adjacent newlines
		
		- Read preprocessor directives
	]]
	while TokenNode do
		local NextTokenNode = TokenNode.Next
		if (TokenNode.Value == "@" or
			TokenNode.Value == "#") and
			(not TokenNode.Previous or
			TokenNode.Previous.TokenType == GCompute.TokenTypes.Newline) then
			-- Preprocessor directive
			local Removed = Preprocessor.ProcessDirective (CompilerContext, TokenNode) + 1
			for i = 1, Removed do
				Tokens:Remove (TokenNode)
				TokenNode = NextTokenNode
				NextTokenNode = TokenNode.Next
			end
			NextTokenNode = TokenNode
		elseif TokenNode.TokenType == GCompute.TokenTypes.Whitespace or
		   TokenNode.TokenType == GCompute.TokenTypes.Comment then
			Tokens:Remove (TokenNode)
		elseif TokenNode.TokenType == GCompute.TokenTypes.String then
			local QuoteType = TokenNode.Value:sub (1, 1)
			TokenNode.Value = Preprocessor.UnescapeString (CompilerContext, TokenNode.Value)
		
			-- Merge adjacent double-quoted strings
			if QuoteType == "\"" and
				TokenNode.Previous and
				TokenNode.Previous.TokenType == GCompute.TokenTypes.String then
				TokenNode.Previous.Value = TokenNode.Previous.Value .. TokenNode.Value
				Tokens:Remove (TokenNode)
			end
		elseif TokenNode.TokenType == GCompute.TokenTypes.Newline and
				TokenNode.Previous and
				TokenNode.Previous.TokenType == GCompute.TokenTypes.Newline then
			Tokens:Remove (TokenNode)
		elseif TokenNode.Value == "##" then
			-- Here be dragons
			-- Join the previous and next symbols
			if not TokenNode.Previous or
				not TokenNode.Next or
				TokenNode.Next.TokenType == GCompute.TokenTypes.Newline then
			else
				NextTokenNode = NextTokenNode.Next
				
				TokenNode.Previous.Value = TokenNode.Previous.Value .. TokenNode.Next.Value
				
				Tokens:Remove (TokenNode.Next)
				Tokens:Remove (TokenNode)
			end
		end
		TokenNode = NextTokenNode
	end
end

function Preprocessor.ProcessDirective (CompilerContext, TokenNode)
	local Length = 0
	local InitialTokenNode = TokenNode
	while TokenNode.TokenType ~= GCompute.TokenTypes.Newline do
		Length = Length + 1
		TokenNode = TokenNode.Next
	end
	TokenNode = InitialTokenNode
	if Length == 1 then
		CompilerContext:PrintErrorMessage ("Preprocessor directive is missing.")
		return Length
	end
	local Directive = TokenNode.Next.Value
	CompilerContext:PrintDebugMessage ("Found preprocessor directive \"" .. Directive .. "\".")
	return Length
end

function Preprocessor.UnescapeString (CompilerContext, String)
	String = String:sub (2, -2)
	return String:Replace ("\\\r", "\r")
			:Replace ("\\n", "\n")
			:Replace ("\\t", "\t")
			:Replace ("\\\"", "\"")
			:Replace ("\\\'", "\'")
			:Replace ("\\\\", "\\")
end