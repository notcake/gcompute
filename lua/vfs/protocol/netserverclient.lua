local self = {}
VFS.Protocol.NetServerClient = VFS.MakeConstructor (self, GLib.Protocol.NetServerClient)

function self:ctor (server, clientId)	
	self.Responses = {}
	
	timer.Create ("VFS.NetServerClient." .. self.ClientId, 0.1, 0, function ()
		self:ProcessResponses ()
	end)
end

function self:dtor ()
	timer.Destroy ("VFS.NetServerClient." .. self.ClientId)
end

function self:CloseResponse (response)
	if not self.Responses [response:GetId ()] then return end
	
	if not response:HasQueuedPackets () then
		ErrorNoHalt ("VFS: Response " .. response:GetId () .. " (" .. response:GetType () .. ") closed.\n")
		self.Responses [response:GetId ()] = nil
	end
	response:Close ()
end

function self:HandleNewRequest (response, inBuffer)
	self.Responses [response:GetId ()] = response
	response:HandleInitialPacket (inBuffer)
end

function self:ProcessResponses ()
	local timedOut = {}
	local closed = {}
	for _, response in pairs (self.Responses) do
		local outBuffer = response:DequeuePacket ()
		if outBuffer then
			VFS.Net.DispatchPacket (self.ClientId, "vfs_response_data", outBuffer)
		end
		
		if response:HasTimedOut () then
			timedOut [response] = true
		end
		
		if response:IsClosing () and not response:HasQueuedPackets () then
			closed [response] = true
		end
	end
	
	for response, _ in pairs (timedOut) do
		ErrorNoHalt ("VFS: Response timed out (" .. response:GetType () .. ").\n")
		response:HandleTimeOut ()
		response:Close ()
	end
	
	for response, _ in pairs (closed) do
		self:CloseResponse (response)
	end
end