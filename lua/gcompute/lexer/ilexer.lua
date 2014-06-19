local self = {}
GCompute.Lexing.ILexer = GCompute.MakeConstructor (self)

function self:ctor ()
end

-- Returns an ITokenStream
function self:Lex (code)
	GCompute.Error ("ILexer:Lex : Not implemented.")
end