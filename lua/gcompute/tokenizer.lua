local self = {}
GCompute.Tokenizer = GCompute.MakeConstructor (self)

GCompute.TokenType =
{
	Unknown				= 0,
	Whitespace			= 1,
	Newline				= 2,
	Preprocessor		= 3,
	Number				= 4,
	Operator			= 5,
	Identifier			= 6,
	Keyword				= 7,
	String				= 8,
	Comment				= 9,
	StatementTerminator	= 10
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

function self:ctor ()
end

function self:Process (compilationUnit)
	local code = compilationUnit:GetCode ()
	local language = compilationUnit:GetLanguage ()
	
	local tokens = GCompute.Containers.LinkedList ()
	local offset = 1
	local line = 1
	local character = 1
	while offset <= code:len () do
		local startOffset = offset
		local match, matchLength, tokenType = language:MatchSymbol (code:sub (offset))
		local original = code:sub (offset, offset + matchLength - 1)
		local _, lineCount = original:gsub ("(\r\n|\n\r|\n|\r)", "")
		if lineCount > 0 then
			line = line + lineCount
			character = 1
		else
			character = character + original:len ()
		end
		if match then
			local token = tokens:AddLast (match)
			if language:GetKeywordType (Match) ~= KeywordTypes.Unknown then
				tokenType = TokenType.Keyword
			end
			token.TokenType = tokenType
			token.Line = line
			token.Character = character
			offset = offset + matchLength
		else
			local token = Tokens:AddLast (code:sub (offset, offset))
			token.TokenType = TokenTypes.Identifier
			token.Line = line
			token.Character = character
			offset = offset + 1
		end
	end
	
	return tokens
end

GCompute.Tokenizer = GCompute.Tokenizer ()