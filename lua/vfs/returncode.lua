VFS.ReturnCode =
{
	Success         = 0,
	AccessDenied    = 1,
	TimedOut        = 2,
	EndOfBurst		= 3,
	Finished		= 4,
	NotFound		= 5,
	NotAFolder		= 6
}
VFS.InvertTable (VFS.ReturnCode)