GAuth.ReturnCode =
{
	Success				= 0,
	AccessDenied		= 1,
	TimedOut			= 2,
	NodeAlreadyExists	= 3,
	NodeNotFound		= 4
}
GAuth.InvertTable (GAuth.ReturnCode)