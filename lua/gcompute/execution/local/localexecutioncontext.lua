local self = {}
GCompute.Execution.LocalExecutionContext = GCompute.MakeConstructor (self, GCompute.Execution.ExecutionContext)

function self:ctor (ownerId, languageName, contextOptions)
	self.HostId         = GLib.GetLocalId ()
	self.OwnerId        = ownerId
	
	self.LanguageName   = languageName
	
	self.ContextOptions = contextOptions
end