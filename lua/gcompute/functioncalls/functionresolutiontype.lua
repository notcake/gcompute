GCompute.FunctionResolutionType = GCompute.Enum (
	{
		Static,   -- A () or A.B.C ()
		Member,   -- A:B ()
		Operator  -- A + B or A [B] or A ()
	}
)