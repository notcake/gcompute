GCompute.TokenType = GCompute.Enum (
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
)