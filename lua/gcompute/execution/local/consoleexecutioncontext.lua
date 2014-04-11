local self = {}
GCompute.Execution.ConsoleExecutionContext = GCompute.MakeConstructor (self, GCompute.Execution.LocalExecutionContext)

function self:ctor (ownerId, contextOptions)
end

-- Internal, do not call
function self:GetExecutionInstanceConstructor  ()
	return GCompute.Execution.ConsoleExecutionInstance
end