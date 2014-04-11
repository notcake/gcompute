local self = {}
GCompute.Execution.LocalExecutionContext = GCompute.MakeConstructor (self, GCompute.Execution.ExecutionContext)

function self:ctor (ownerId, contextOptions)
	self.HostId  = GLib.GetLocalId ()
	self.OwnerId = ownerId
	
	self.ContextOptions = contextOptions
end