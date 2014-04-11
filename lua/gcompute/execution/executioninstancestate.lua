GCompute.Execution.ExecutionInstanceState = GLib.Enum (
	{
		Uncompiled = 1,
		Compiling  = 2,
		Compiled   = 3,
		Unstarted  = 3,
		Running    = 4,
		Waiting    = 5,
		Sleeping   = 6,
		Terminated = 7
	}
)