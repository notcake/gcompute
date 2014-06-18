GCompute.Lexing.TokenType = GCompute.Enum (
	{
		Unknown             =  0,
		Whitespace          =  1,
		Newline             =  2,
		Preprocessor        =  3,
		Comment             =  4,
		Number              =  5,
		String              =  6,
		Keyword             =  7,
		Identifier          =  8,
		Operator            =  9,
		MemberIndexer       = 10,
		StatementTerminator = 11,
		EndOfFile           = 12,
		AST                 = 13  -- Blob of already-parsed data
	}
)