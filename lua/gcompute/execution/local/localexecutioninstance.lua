local self = {}
GCompute.Execution.LocalExecutionInstance = GCompute.MakeConstructor (self, GCompute.Execution.IExecutionInstance)

--[[
	Events:
		CanStartExecution ()
			Fired when this instance is about to start execution.
		StateChanged (state)
			Fired when this instance's state has changed.
]]

function self:ctor (executionContext, instanceOptions)
	self.ExecutionContext = executionContext
	self.InstanceOptions  = instanceOptions
	
	self.State = GCompute.Execution.ExecutionInstanceState.Uncompiled
	
	-- IO
	self.StdIn  = GCompute.Pipe ()
	self.StdOut = GCompute.Pipe ()
	self.StdErr = GCompute.Pipe ()
	self.CompilerStdOut = GCompute.Pipe ()
	self.CompilerStdErr = GCompute.Pipe ()
	
	-- Compilation
	self.SourceFileCount = 0
	self.SourceFiles = {}
	self.SourceIds   = {}
	
	GCompute.EventProvider (self)
end

function self:GetExecutionContext ()
	return self.ExecutionContext
end

function self:GetHostId ()
	return self.ExecutionContext:GetHostId ()
end

function self:GetOwnerId ()
	return self.ExecutionContext:GetOwnerId ()
end

function self:GetInstanceOptions ()
	return self.InstanceOptions
end

-- IO
function self:GetStdIn ()
	return self.StdIn
end

function self:GetStdOut ()
	return self.StdOut
end

function self:GetStdErr ()
	return self.StdErr
end

function self:GetCompilerStdOut ()
	return self.CompilerStdOut
end

function self:GetCompilerStdErr ()
	return self.CompilerStdErr
end

-- State
function self:GetState ()
	return self.State
end

function self:SetState (state)
	if self.State == state then return self end
	
	self.State = state
	self:DispatchEvent ("StateChanged", self.State)
	
	return self
end

-- Compilation
function self:AddSourceFile (code, sourceId)
	if not code then return end
	
	if not sourceId then
		ownerName = GCompute.PlayerMonitor:GetUserName (self:GetOwnerId ())
		ownerName = ownerName or ""
		sourceId = "[" .. self:GetOwnerId () .. "]" .. ownerName
	end
	self.SourceFileCount = self.SourceFileCount + 1
	self.SourceFiles [self.SourceFileCount] = code
	self.SourceIds   [self.SourceFileCount] = sourceId
end

function self:GetSourceFileEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.SourceIds [i], self.SourceFiles [i]
	end
end

-- Control