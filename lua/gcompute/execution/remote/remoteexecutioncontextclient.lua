local self = {}
GCompute.Execution.RemoteExecutionContextClient = GCompute.MakeConstructor (self, GLib.Networking.SingleEndpointNetworkable, GCompute.Execution.IExecutionContext)

--[[
	Events:
		CanCreateExecutionInstance (code, sourceId, instanceOptions)
			Fired when an execution instance is about to be created.
		ExecutionInstanceCreated (IExecutionInstance executionInstance)
			Fired when an execution instance has been created.
			
]]

function self:ctor (remoteExecutionServiceClient, inBuffer)
	GCompute.Debug ("RemoteExecutionContextClient:ctor ()")
	
	self.HostId         = nil
	self.OwnerId        = nil
	self.LanguageName   = nil
	self.ContextOptions = GCompute.Execution.ExecutionContextOptions.None
	
	self:Deserialize (inBuffer)
end

function self:dtor ()
	if not self.NetworkableHost then return end
	
	GCompute.Debug ("RemoteExecutionContextClient:dtor ()")
	
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (0)
	self:DispatchPacket (self:GetRemoteId (), outBuffer)
	
	self.NetworkableHost:UnregisterNetworkable (self)
end

-- Networkable
function self:HandlePacket (sourceId, inBuffer)
end

-- IExecutionContext
function self:CanCreateExecutionInstance (code, sourceId, instanceOptions)
	-- CanCreateExecutionInstance event
	local allowed, denialReason = self:DispatchEvent ("CanCreateExecutionInstance", code, sourceId, instanceOptions)
	if allowed == false then return false, denialReason end
	
	return true
end

function self:CreateExecutionInstance (code, sourceId, instanceOptions, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	if self:IsDisposed () then return nil, GCompute.ReturnCode.NoCarrier end
	
	-- Check if creation is allowed
	local allowed, denialReason = self:CanCreateExecutionInstance (code, sourceId, instanceOptions)
	if not allowed then return nil, denialReason end
	
	-- Create request session
	local connection = self.NetworkableHost:CreateConnection (self:GetRemoteId (), GLib.Net.ConnectionEndpoint.Local)
	
	-- Create request
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (connection:GetId ())
	outBuffer:StringN8 ("CreateExecutionInstance")
	outBuffer:UInt8 (0)
	outBuffer:UInt32 (instanceOptions)
	outBuffer:StringN16 (sourceId or "")
	outBuffer:StringN32 (util.Compress (code) or "")
	
	-- Dispatch request
	self:DispatchPacket (self:GetRemoteId (), outBuffer)
	
	-- Wait for response
	local inBuffer = connection:Read ()
	connection:Close ()
	
	if not inBuffer then return nil, GCompute.ReturnCode.Timeout end
	
	local returnCode = inBuffer:UInt8 ()
	
	if returnCode ~= GCompute.ReturnCode.Success then
		return nil, returnCode
	end
	
	-- GOGOGO
	local networkableId = inBuffer:UInt32 ()
	local executionInstanceClient = GCompute.Execution.RemoteExecutionInstanceClient (self, inBuffer)
	executionInstanceClient:SetRemoteId (self:GetRemoteId ())
	
	self.NetworkableHost:RegisterStrongNetworkable (executionInstanceClient, networkableId)
	
	-- ExecutionInstanceCreated event
	self:DispatchEvent ("ExecutionInstanceCreated", executionInstanceClient)
	
	return executionInstanceClient
end

function self:GetHostId ()
	return self.HostId
end

function self:GetOwnerId ()
	return self.OwnerId
end

function self:GetLanguageName ()
	return self.LanguageName
end

function self:GetContextOptions ()
	return self.ContextOptions
end

-- RemoteExecutionContextClient
function self:Deserialize (inBuffer)
	self.OwnerId = inBuffer:StringN16 ()
	
	local hostIdCount = inBuffer:UInt16 ()
	if hostIdCount == 1 then
		self.HostId = inBuffer:StringN16 ()
	else
		self.HostId = {}
		for i = 1, hostIdCount do
			self.HostId [#self.HostId + 1] = inBuffer:StringN16 ()
		end
	end
	
	self.LanguageName   = inBuffer:StringN16 ()
	self.ContextOptions = inBuffer:UInt32 ()
	
	return self
end