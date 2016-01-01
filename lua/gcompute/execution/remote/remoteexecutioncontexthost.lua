local self = {}
GCompute.Execution.RemoteExecutionContextHost = GCompute.MakeConstructor (self, GLib.Networking.SingleEndpointNetworkable)

function self:ctor (remoteExecutionServiceHost, executionContext)
	GCompute.Debug ("RemoteExecutionContextHost:ctor ()")
	self.ExecutionContext = executionContext
end

function self:dtor ()
	if self.ExecutionContext then
		self.ExecutionContext:dtor ()
		self.ExecutionContext = nil
	end
	
	if not self.NetworkableHost then return end
	
	GCompute.Debug ("RemoteExecutionContextHost:dtor ()")
	
	self.NetworkableHost:UnregisterNetworkable (self)
end

-- Networkable
function self:HandlePacket (sourceId, inBuffer)
	local connectionId = inBuffer:UInt32 ()
	
	if connectionId == 0 then
		self:dtor ()
		return
	end
	
	local connection = self.NetworkableHost:CreateConnection (sourceId, GLib.Net.ConnectionEndpoint.Remote, connectionId)
	
	local requestType = inBuffer:StringN8 ()
	
	if requestType == "CreateExecutionInstance" then
		return self:HandleExecutionInstanceCreationRequest (connection, inBuffer:Pin ())
	else
		return self:HandleUnknownRequest (connection, inBuffer)
	end
end

function self:IsHosting ()
	return true
end

-- RemoteExecutionContextHost
function self:GetExecutionContext ()
	return self.ExecutionContext
end

function self:Serialize (outBuffer)
	outBuffer:StringN16 (self.ExecutionContext:GetOwnerId ())
	
	local hostId = self.ExecutionContext:GetHostId ()
	if istable (hostId) then
		outBuffer:UInt16 (#hostId)
		for _, hostId in ipairs (hostId) do
			outBuffer:StringN16 (hostId)
		end
	else
		outBuffer:UInt16 (1)
		outBuffer:StringN16 (hostId)
	end
	
	outBuffer:StringN16 (self.ExecutionContext:GetLanguageName ())
	outBuffer:UInt32 (self.ExecutionContext:GetContextOptions ())
	
	return outBuffer
end

-- Internal, do not call
function self:HandleExecutionInstanceCreationRequest (connection, inBuffer)
	if GLib.CallSelfInThread () then return end
	
	-- Deserialize arguments
	local callType = inBuffer:UInt8 ()
	if callType == 0 then
		self:HandleExecutionInstanceCreationRequest0 (connection, inBuffer)
	else
		self:HandleUnknownRequest (connection, inBuffer)
	end
end

function self:HandleExecutionInstanceCreationRequest0 (connection, inBuffer)
	if GLib.CallSelfInThread () then return end
	
	-- Deserialize arguments
	local instanceOptions = inBuffer:UInt32 ()
	local sourceId = inBuffer:StringN16 ()
	if sourceId == "" then sourceId = nil end
	local code = util.Decompress (inBuffer:StringN32 ()) or ""
	
	-- Create the execution instance
	local executionInstance, returnCode = self.ExecutionContext:CreateExecutionInstance (code, sourceId, instanceOptions)
	if executionInstance then
		returnCode = GCompute.ReturnCode.Success
	else
		returnCode = returnCode or GCompute.ReturnCode.AccessDenied
	end
	
	-- Create response
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt8 (returnCode)
	
	if executionInstance then
		executionInstance = GCompute.Execution.RemoteExecutionInstanceHost (self, executionInstance)
		executionInstance:SetRemoteId (self:GetRemoteId ())
		self.NetworkableHost:RegisterWeakNetworkable (executionInstance)
		outBuffer:UInt32 (self.NetworkableHost:GetNetworkableId (executionInstance))
		
		executionInstance:Serialize (outBuffer)
	end
	
	connection:Write (outBuffer)
	connection:Close ()
	
	-- Flush to ensure that the reply gets sent before any execution instance data
	connection:Flush ()
	
	if executionInstance then
		executionInstance:HookExecutionInstance (executionInstance:GetExecutionInstance ())
	end
end

function self:HandleUnknownRequest (connection, inBuffer)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt8 (GCompute.ReturnCode.NotSupported)
	connection:Write (outBuffer)
	connection:Close ()
end