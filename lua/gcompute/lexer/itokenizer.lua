local self = {}
GCompute.Lexing.ITokenizer = GCompute.MakeConstructor (self, GCompute.Lexing.IKeywordClassifier)

function self:ctor ()
end

-- Returns rawTokenString, tokenCharacterCount, tokenType
function self:MatchSymbol (code, offset)
	GCompute.Error ("ITokenizer:MatchSymbol : Not implemented.")
end