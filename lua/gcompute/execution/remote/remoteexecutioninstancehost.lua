local self = {}
GCompute.Execution.RemoteExecutionInstanceHost = GCompute.MakeConstructor (self, GLib.Networking.SingleEndpointNetworkable)

function self:ctor (remoteExecutionContextHost, executionInstance)
	GCompute.Debug ("RemoteExecutionInstanceHost:ctor ()")
	self.ExecutionInstance = executionInstance
	
	-- Our RemoteExecutionContextHost will invoke HookExecutionInstance
	-- after we've been registered, to ensure that buffered output gets caught and networked
	-- self:HookExecutionInstance (self.ExecutionInstance)
end

function self:dtor ()
	if self.ExecutionInstance then
		self:UnhookExecutionInstance (self.ExecutionInstance)
		self.ExecutionInstance:dtor ()
		self.ExecutionInstance = nil
	end
	
	if not self.NetworkableHost then return end
	
	GCompute.Debug ("RemoteExecutionInstanceHost:dtor ()")
	
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:StringN8 ("")
	self:DispatchPacket (self:GetRemoteId (), outBuffer)
	
	self.NetworkableHost:UnregisterNetworkable (self)
end

-- Networkable
function self:HandlePacket (sourceId, inBuffer)
	local connectionId = inBuffer:UInt32 ()
	
	if connectionId == 0 then
		self:HandleConnectionlessPacket (inBuffer)
		return
	end
	
	local connection = self.NetworkableHost:CreateConnection (sourceId, GLib.Net.ConnectionEndpoint.Remote, connectionId)
	
	local requestType = inBuffer:StringN8 ()
	
	return self:HandleUnknownRequest (connection, inBuffer)
end

function self:IsHosting ()
	return true
end

-- RemoteExecutionInstanceHost
function self:GetExecutionInstance ()
	return self.ExecutionInstance
end

function self:Serialize (outBuffer)
	outBuffer:UInt32 (self.ExecutionInstance:GetInstanceOptions ())
	outBuffer:UInt32 (self.ExecutionInstance:GetState ())
	
	return outBuffer
end

-- Internal, do not call
function self:HandleConnectionlessPacket (inBuffer)
	local packetType = inBuffer:StringN8 ()
	if packetType == "" then
		self:dtor ()
	elseif packetType == "Compile" then
		self.ExecutionInstance:Compile ()
	elseif packetType == "Start" then
		self.ExecutionInstance:Start ()
	elseif packetType == "Terminate" then
		self.ExecutionInstance:Terminate ()
	end
end

function self:HandleUnknownRequest (connection, inBuffer)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt8 (GCompute.ReturnCode.NotSupported)
	connection:Write (outBuffer)
	connection:Close ()
end

function self:HookExecutionInstance (executionInstance)
	if not executionInstance then return end
	
	executionInstance:AddEventListener ("StateChanged", self:GetHashCode (),
		function (_, state)
			local outBuffer = GLib.Net.OutBuffer ()
			outBuffer:StringN8 ("State")
			outBuffer:UInt8 (state)
			self:DispatchPacket (self:GetRemoteId (), outBuffer)
		end
	)
	
	self:HookPipe (executionInstance:GetStdOut (), "StdOut")
	self:HookPipe (executionInstance:GetStdErr (), "StdErr")
	self:HookPipe (executionInstance:GetCompilerStdOut (), "CompilerStdOut")
	self:HookPipe (executionInstance:GetCompilerStdErr (), "CompilerStdErr")
end

function self:HookPipe (pipe, pipeName)
	if not pipe then return end
	
	pipe:AddEventListener ("Text", self:GetHashCode (),
		function (_, text, color)
			local chunkSize = 16 * 1024
			if #text > chunkSize then
				local parts = GLib.UTF8.ChunkSplit (text, chunkSize)
				
				for _, text in ipairs (parts) do
					self:DispatchPipeTextPacket (pipeName, text, color)
				end
			else
				self:DispatchPipeTextPacket (pipeName, text, color)
			end
		end
	)
end

function self:DispatchPipeTextPacket (pipeName, text, color)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:StringN8 (pipeName)
	outBuffer:StringN32 (text)
	
	if isnumber (color) then
		outBuffer:UInt8 (1)
		outBuffer:UInt32 (color)
	elseif istable (color) then
		outBuffer:UInt8 (2)
		outBuffer:UInt32 (GLib.Color.ToArgb (color))
	else
		outBuffer:UInt8 (0)
	end
	
	self:DispatchPacket (self:GetRemoteId (), outBuffer)
end

function self:UnhookExecutionInstance (executionInstance)
	if not executionInstance then return end
	
	executionInstance:RemoveEventListener ("StateChanged", self:GetHashCode ())
	executionInstance:GetStdOut ():RemoveEventListener ("Text", self:GetHashCode ())
	executionInstance:GetStdErr ():RemoveEventListener ("Text", self:GetHashCode ())
	executionInstance:GetCompilerStdOut ():RemoveEventListener ("Text", self:GetHashCode ())
	executionInstance:GetCompilerStdErr ():RemoveEventListener ("Text", self:GetHashCode ())
end