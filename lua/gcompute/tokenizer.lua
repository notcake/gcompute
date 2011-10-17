if not GCompute.Tokenizer then
	GCompute.Tokenizer = {}
end
local Tokenizer = GCompute.Tokenizer
Tokenizer.__index = Tokenizer

GCompute.TokenTypes = {}
local TokenTypes = GCompute.TokenTypes
TokenTypes.Unknown = 0
TokenTypes.Whitespace = 1
TokenTypes.Newline = 2
TokenTypes.Preprocessor = 3
TokenTypes.Number = 4
TokenTypes.Operator = 5
TokenTypes.Identifier = 6
TokenTypes.Keyword = 7
TokenTypes.String = 8
TokenTypes.Comment = 9
TokenTypes.StatementTerminator = 10
GCompute.InvertTable (TokenTypes)

GCompute.KeywordTypes = {}
local KeywordTypes = GCompute.KeywordTypes
KeywordTypes.Unknown = 0
KeywordTypes.Control = 1
KeywordTypes.Modifier = 2
KeywordTypes.DataType = 3
KeywordTypes.Constants = 4
GCompute.InvertTable (KeywordTypes)

function Tokenizer.Process (CompilerContext)
	local Code = CompilerContext.Code
	local Tokens = GCompute.Containers.LinkedList ()
	local Offset = 1
	local Line = 1
	local Character = 1
	while Offset <= Code:len () do
		local StartOffset = Offset
		local Match, MatchLength, TokenType = CompilerContext.Language:MatchSymbol (Code:sub (Offset))
		local Original = Code:sub (Offset, Offset + MatchLength - 1)
		local _, LineCount = Original:gsub ("(\r\n|\n\r|\n|\r)", "")
		if LineCount > 0 then
			Line = Line + LineCount
			Character = 1
		else
			Character = Character + Original:len ()
		end
		if Match then
			local Token = Tokens:AddLast (Match)
			if CompilerContext.Language:GetKeywordType (Match) ~= KeywordTypes.Unknown then
				TokenType = TokenTypes.Keyword
			end
			Token.TokenType = TokenType
			Token.Line = Line
			Token.Character = Character
			Offset = Offset + MatchLength
		else
			local Token = Tokens:AddLast (Code:sub (Offset, Offset))
			Token.TokenType = TokenTypes.Identifier
			Token.Line = Line
			Token.Character = Character
			Offset = Offset + 1
		end
	end
	
	return Tokens
end