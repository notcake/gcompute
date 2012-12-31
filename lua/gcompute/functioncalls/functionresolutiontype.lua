GCompute.FunctionResolutionType = GCompute.Enum (
	{
		Static   = 1, -- A () or A.B.C ()
		Member   = 2, -- A:B ()
		Operator = 3  -- A + B or A [B] or A ()
	}
)