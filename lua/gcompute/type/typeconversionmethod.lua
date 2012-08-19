GCompute.TypeConversionMethod = GCompute.Enum (
	{
		None               =  0,
		Identity           =  1,
		Downcast           =  2,
		Covariance         =  4,
		Constructor        =  8,
		ImplicitCast       = 16,
		ExplicitCast       = 32,
		
		ImplicitConversion = 31,
		ExplicitConversion = 63
	}
)