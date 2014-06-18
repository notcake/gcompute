local self = {}
GCompute.Lexing.ITokenizer = GCompute.MakeConstructor (self)

function self:ctor ()
end

-- Returns rawTokenString, tokenCharacterCount, tokenType
function self:MatchSymbol (code, offset)
	GCompute.Error ("ITokenizer:MatchSymbol : Not implemented.")
end

function self:ToLexer ()
	return GCompute.Lexing.Lexer (self)
end