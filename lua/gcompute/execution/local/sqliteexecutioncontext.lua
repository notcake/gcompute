local self = {}
GCompute.Execution.SQLiteExecutionContext = GCompute.MakeConstructor (self, GCompute.Execution.LocalExecutionContext)

function self:ctor (ownerId, contextOptions)
end

-- ExecutionContext
function self:GetExecutionInstanceConstructor  ()
	return GCompute.Execution.SQLiteExecutionInstance
end