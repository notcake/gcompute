local self = {}
GCompute.Execution.IExecutionInstance = GCompute.MakeConstructor (self, GLib.IDisposable)

--[[
	Events:
		CanStartExecution ()
			Fired when this instance is about to start execution.
		StateChanged (state)
			Fired when this instance's state has changed.
]]

function self:ctor ()
end

function self:GetExecutionContext ()
	GCompute.Error ("IExecutionInstance:GetExecutionContext : Not implemented.")
end

function self:GetHostId ()
	GCompute.Error ("IExecutionInstance:GetHostId : Not implemented.")
end

function self:GetOwnerId ()
	GCompute.Error ("IExecutionInstance:GetOwnerId : Not implemented.")
end

function self:GetInstanceOptions ()
	GCompute.Error ("IExecutionIstance:GetInstanceOptions : Not implemented.")
end

function self:HasInstanceOption (instanceOption)
	return bit.band (self:GetInstanceOptions (), instanceOption) == instanceOption
end

function self:CapturesOutput ()
	return bit.band (self:GetInstanceOptions (), GCompute.Execution.ExecutionInstanceOptions.CaptureOutput) ~= 0
end

function self:SuppressesHostOutput ()
	return bit.band (self:GetInstanceOptions (), GCompute.Execution.ExecutionInstanceOptions.SuppressHostOutput) ~= 0
end

-- IO
function self:GetStdIn ()
	GCompute.Error ("IExecutionInstance:GetStdIn : Not implemented.")
end

function self:GetStdOut ()
	GCompute.Error ("IExecutionInstance:GetStdOut : Not implemented.")
end

function self:GetStdErr ()
	GCompute.Error ("IExecutionInstance:GetStdErr : Not implemented.")
end

function self:GetCompilerStdOut ()
	GCompute.Error ("IExecutionInstance:GetCompilerStdOut : Not implemented.")
end

function self:GetCompilerStdErr ()
	GCompute.Error ("IExecutionInstance:GetCompilerStdErr : Not implemented.")
end

-- State
function self:GetState ()
	GCompute.Error ("IExecutionInstance:GetState : Not implemented.")
end

function self:IsCompiling ()
	return self:GetState () == GCompute.Execution.ExecutionInstanceState.Compiling
end

function self:IsCompiled ()
	return self:GetState () >= GCompute.Execution.ExecutionInstanceState.Compiled
end

function self:IsStarted ()
	return self:GetState () >= GCompute.Execution.ExecutionInstanceState.Running
end

function self:IsTerminated ()
	return self:GetState () == GCompute.Execution.ExecutionInstanceState.Terminated
end

-- Compilation
function self:AddSourceFile (code, sourceId)
	GCompute.Error ("IExecutionInstance:AddSourceFile : Not implemented.")
end

-- Control
function self:Compile ()
	GCompute.Error ("IExecutionInstance:Compile : Not implemented.")
end

function self:Start ()
	GCompute.Error ("IExecutionInstance:Start : Not implemented.")
end

function self:Terminate ()
	GCompute.Error ("IExecutionInstance:Terminate : Not implemented.")
end