VFS.ReturnCode =
{
	None			= 0,
	EndOfBurst		= 1,
	Finished		= 2,
	TimedOut		= 3,
	AccessDenied	= 4,
	NotFound		= 5,
	NotAFolder		= 6
}
VFS.InvertTable (VFS.ReturnCode)