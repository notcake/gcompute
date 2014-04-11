local self = {}
GCompute.Execution.RemoteExecutionServiceHost = GCompute.MakeConstructor (self, GLib.Networking.SingleEndpointNetworkable)
GCompute.Services.RemoteServiceRegistry:RegisterServiceHost ("ExecutionService", GCompute.Execution.RemoteExecutionServiceHost)

function self:ctor ()
	GCompute.Debug ("RemoteExecutionServiceHost:ctor ()")
end

function self:dtor ()
	if not self.NetworkableHost then return end
	
	GCompute.Debug ("RemoteExecutionServiceHost:dtor ()")
	
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
	
	if requestType == "CreateExecutionContext" then
		return self:HandleExecutionContextCreationRequest (connection, inBuffer:Pin ())
	else
		return self:HandleUnknownRequest (connection, inBuffer)
	end
end

function self:IsHosting ()
	return true
end

-- Internal, do not call
function self:HandleExecutionContextCreationRequest (connection, inBuffer)
	if GLib.CallSelfInThread () then return end
	
	-- Deserialize arguments
	local authId = inBuffer:StringN16 ()
	local hostIdCount = inBuffer:UInt16 ()
	local hostId
	if hostIdCount == 1 then
		hostId = inBuffer:StringN16 ()
	else
		hostId = {}
		for i = 1, hostIdCount do
			hostId [#hostId + 1] = inBuffer:StringN16 ()
		end
	end
	local languageName = inBuffer:StringN16 ()
	local contextOptions = inBuffer:UInt32 ()
	
	-- Check for impersonation
	if SERVER and authId ~= self:GetRemoteId () then
		-- Yeah... no.
		
		local outBuffer = GLib.Net.OutBuffer ()
		outBuffer:UInt8 (GCompute.ReturnCode.AccessDenied)
		connection:Write (outBuffer)
		connection:Close ()
		
		return
	end
	
	-- Create the execution context
	local executionContext, returnCode = GCompute.Execution.ExecutionService:CreateExecutionContext (authId, hostId, languageName, contextOptions)
	if executionContext then
		returnCode = GCompute.ReturnCode.Success
	else
		returnCode = returnCode or GCompute.ReturnCode.AccessDenied
	end
	
	-- Create response
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt8 (returnCode)
	
	if executionContext then
		executionContext = GCompute.Execution.RemoteExecutionContextHost (self, executionContext)
		executionContext:SetRemoteId (self:GetRemoteId ())
		self.NetworkableHost:RegisterStrongNetworkable (executionContext)
		outBuffer:UInt32 (self.NetworkableHost:GetNetworkableId (executionContext))
		
		executionContext:Serialize (outBuffer)
	end
	
	connection:Write (outBuffer)
	connection:Close ()
end

function self:HandleUnknownRequest (connection, inBuffer)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt8 (GCompute.ReturnCode.NotSupported)
	connection:Write (outBuffer)
	connection:Close ()
end