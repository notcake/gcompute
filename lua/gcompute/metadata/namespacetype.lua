GCompute.NamespaceType = GCompute.Enum (
	{
		Unknown      = 0,
		Global       = 1, -- Global namespace
		Local        = 2, -- Local scope
		Type         = 3, -- Class namespace
		FunctionRoot = 4  -- Root scope of a function declaration
	}
)