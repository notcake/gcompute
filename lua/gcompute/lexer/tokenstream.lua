local self = {}
GCompute.Lexing.TokenStream = GCompute.MakeConstructor (self, GCompute.Lexing.ITokenStream)

function self:ctor ()
end

function self:GetEnumerator ()
	self:SeekAbsolute (nil)
	return function ()
		return self:Read ()
	end
end

function self:Print (coloredTextSink, syntaxColoringScheme)
	local characterCount = 0
	
	syntaxColoringScheme = syntaxColoringScheme or GCompute.SyntaxColoring.DefaultSyntaxColoringScheme
	
	for token in self:GetEnumerator () do
		if token.TokenType == GCompute.Lexing.TokenType.EndOfFile then break end
		
		characterCount = characterCount + coloredTextSink:WriteColor (token.Value, syntaxColoringScheme:GetTokenColor (token.TokenType))
	end
	
	return characterCount
end