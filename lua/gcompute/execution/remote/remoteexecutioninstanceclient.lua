local self = {}
GCompute.Execution.RemoteExecutionInstanceClient = GCompute.MakeConstructor (self, GLib.Networking.SingleEndpointNetworkable, GCompute.Execution.IExecutionInstance)

--[[
	Events:
		CanStartExecution ()
			Fired when this instance is about to start execution.
		StateChanged (state)
			Fired when this instance's state has changed.
]]

function self:ctor (remoteExecutionContextClient, inBuffer)
	self.ExecutionContext = remoteExecutionContextClient
	
	self.InstanceOptions = GCompute.Execution.ExecutionInstanceOptions.None
	
	-- IO
	self.StdIn  = GCompute.Pipe ()
	self.StdOut = GCompute.Pipe ()
	self.StdErr = GCompute.Pipe ()
	self.CompilerStdOut = GCompute.Pipe ()
	self.CompilerStdErr = GCompute.Pipe ()
	
	-- State
	self.State = GCompute.Execution.ExecutionInstanceState.Uncompiled
	
	GCompute.Debug ("RemoteExecutionInstanceClient:ctor ()")
	
	self:Deserialize (inBuffer)
end

function self:dtor ()
	if not self.NetworkableHost then return end
	
	GCompute.Debug ("RemoteExecutionInstanceClient:dtor ()")
	
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (0)
	outBuffer:StringN8 ("")
	self:DispatchPacket (self:GetRemoteId (), outBuffer)
	
	self.NetworkableHost:UnregisterNetworkable (self)
end

-- Networkable
function self:HandlePacket (sourceId, inBuffer)
	self:HandleConnectionlessPacket (inBuffer)
end

-- IExecutionInstance
function self:GetExecutionContext ()
	return self.ExecutionContext
end

function self:GetHostId ()
	return self.ExecutionContext:GetHostId()
end

function self:GetOwnerId ()
	return self.ExecutionContext:GetOwnerId()
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

-- Control
function self:Compile ()
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (0)
	outBuffer:StringN16 ("Compile")
	self:DispatchPacket (self:GetRemoteId (), outBuffer)
end

function self:Start ()
	-- CanStartExecution event
	if not self:DispatchEvent ("CanStartExecution") == false then return end
	
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (0)
	outBuffer:StringN16 ("Start")
	self:DispatchPacket (self:GetRemoteId (), outBuffer)
end

function self:Terminate ()
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (0)
	outBuffer:StringN16 ("Terminate")
	self:DispatchPacket (self:GetRemoteId (), outBuffer)
end

-- State
function self:GetState ()
	return self.State
end

-- RemoteExecutionInstanceClient
function self:Deserialize (inBuffer)
	self.InstanceOptions = inBuffer:UInt32 ()
	self.State = inBuffer:UInt8 ()
	
	return self
end

-- Internal, do not call
function self:HandleConnectionlessPacket (inBuffer)
	local packetType = inBuffer:StringN8 ()
	if packetType == "" then
		self:dtor ()
	elseif packetType == "State" then
		self:SetState (inBuffer:UInt8 ())
	elseif packetType == "StdOut" then self:HandlePipePacket (self:GetStdOut (), inBuffer)
	elseif packetType == "StdErr" then self:HandlePipePacket (self:GetStdErr (), inBuffer)
	elseif packetType == "CompilerStdOut" then self:HandlePipePacket (self:GetCompilerStdOut (), inBuffer)
	elseif packetType == "CompilerStdErr" then self:HandlePipePacket (self:GetCompilerStdErr (), inBuffer)
	end
end

function self:HandlePipePacket (pipe, inBuffer)
	local text = inBuffer:StringN32 ()
	local colorType = inBuffer:UInt8 ()
	local color = nil
	
	if     colorType == 0 then color = nil
	elseif colorType == 1 then color = inBuffer:UInt32 ()
	elseif colorType == 2 then color = GLib.Color.FromArgb (inBuffer:UInt32 ()) end
	
	pipe:WriteColor (text, color)
end

function self:HandleUnknownRequest (connection, inBuffer)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt8 (GCompute.ReturnCode.NotSupported)
	connection:Write (outBuffer)
	connection:Close ()
end

function self:SetState (state)
	if self.State == state then return self end
	
	self.State = state
	self:DispatchEvent ("StateChanged", self.State)
	
	return self
end