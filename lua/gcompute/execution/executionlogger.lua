local self = {}
GCompute.Execution.ExecutionLogger = GCompute.MakeConstructor (self)

function self:ctor ()
	-- ExecutionFilterables
	self.ExecutionFilterableSet = {}
	
	-- Output
	self.OutputPipe = GCompute.Pipe ()
	self.OutputTextSinkSet = {}
end

function self:dtor ()
	self:ClearExecutionFilterables ()
	self:ClearOutputTextSinks ()
end

-- ExecutionFilterables
function self:AddExecutionFilterable (executionFilterable)
	if self.ExecutionFilterableSet [executionFilterable] then return end
	
	self.ExecutionFilterableSet [executionFilterable] = true
	self:HookExecutionFilterable (executionFilterable)
end

function self:ClearExecutionFilterables ()
	for executionFilterable, _ in pairs (self.ExecutionFilterableSet) do
		self:RemoveExecutionFilterable (executionFilterable)
	end
	
	self.ExecutionFilterables = {}
end

function self:RemoveExecutionFilterable (executionFilterable)
	if not self.ExecutionFilterableSet [executionFilterable] then return end
	
	self.ExecutionFilterableSet [executionFilterable] = nil
	self:UnhookExecutionFilterable (executionFilterable)
end

-- Output
function self:AddOutputTextSink (textSink)
	if self.OutputTextSinkSet [textSink] then return end
	
	self.OutputTextSinkSet [textSink] = true
	self.OutputPipe:ChainTo (textSink)
end

function self:ClearOutputTextSink ()
	for textSink, _ in pairs (self.OutputTextSinkSet) do
		self:RemoveOutputTextSink (textSink)
	end
	
	self.OutputTextSinkSet = {}
end

function self:RemoveOutputTextSink (textSink)
	if not self.OutputTextSinkSet [textSink] then return end
	
	self.OutputTextSinkSet [textSink] = nil
	self.OutputPipe:UnchainTo (textSink)
end

-- Internal, do not call
function self:FormatUserId (userId)
	if istable (userId) then
		local userIds = {}
		for _, userId in ipairs (userId) do
			userIds [#userIds + 1] = self:FormatUserId (userId)
		end
		
		return table.concat (userIds, ", ")
	else
		local userName = GCompute.PlayerMonitor:GetUserName (userId)
		if userName == userId then userName = nil end
		
		if userName then
			return userId .. " (" .. userName .. ")"
		else
			return userId
		end
	end
end

function self:HookExecutionFilterable (executionFilterable)
	if not executionFilterable then return end
	
	executionFilterable:AddEventListener ("ExecutionInstanceCreated", "GCompute.ExecutionLogger." .. self:GetHashCode (),
		function (_, executionContext, executionInstance)
			self.OutputPipe:WriteColor ("[GCompute " .. executionContext:GetLanguageName () .. " " .. self:FormatUserId (executionContext:GetOwnerId ()) .. " -> " .. self:FormatUserId (executionContext:GetHostId ()) .. "]\n", GLib.Colors.Orange)
		end
	)
end

function self:UnhookExecutionFilterable (executionFilterable)
	if not executionFilterable then return end
	
	executionFilterable:RemoveEventListener ("ExecutionInstanceCreated", "GCompute.ExecutionLogger." .. self:GetHashCode ())
end