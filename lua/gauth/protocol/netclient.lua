local self = {}
GAuth.Protocol.NetClient = GAuth.MakeConstructor (self, GLib.Protocol.NetClient)

function self:ctor (serverId, systemName)
	self.Requests = {}
	self.NextRequestId = 0
	
	timer.Create ("GAuth.NetClient." .. self.ServerId, 0.1, 0, function ()
		self:ProcessRequests ()
	end)
end

function self:dtor ()
	timer.Destroy ("GAuth.NetClient." .. self.ServerId)
end

function self:CloseRequest (request)
	if not self.Requests [request:GetId ()] then return end
	
	if not request:HasQueuedPackets () then
		ErrorNoHalt ("GAuth: Request " .. request:GetId () .. " (" .. request:GetType () .. ") closed.\n")
		self.Requests [request:GetId ()] = nil
	end
	request:Close ()
end

function self:HandleResponse (id, inBuffer)
	local request = self.Requests [id]
	if not request then
		ErrorNoHalt ("GAuth.NetClient:HandleResponse : No request corresponding to id " .. id .. " found!\n")
		return
	end
	
	request:ResetTimeout ()
	request:HandleResponse (inBuffer)
end

function self:StartRequest (request)
	request:SetNetClient (self)
	request:SetId (self.NextRequestId)
	self.NextRequestId = self.NextRequestId + 1
	
	ErrorNoHalt ("NetClient:StartRequest : New " .. request:GetType () .. " request with id " .. request:GetId () .. "\n")
	
	self.Requests [request:GetId ()] = request
	
	local outBuffer = GAuth.Net.OutBuffer ()
	outBuffer:UInt32 (request:GetId ())
	outBuffer:UInt32 (request:GetTypeId ())
	request:GenerateInitialPacket (outBuffer)
	
	GAuth.Net.DispatchPacket (self.ServerId, "gauth_new_request", outBuffer)
	request:ResetTimeout ()
end

function self:GetRoot ()
	return self.Root
end

function self:ProcessRequests ()
	local timedOut = {}
	local closed = {}
	for _, request in pairs (self.Requests) do
		local outBuffer = request:DequeuePacket ()
		if outBuffer then
			GAuth.Net.DispatchPacket (self.ServerId, "gauth_request_data", outBuffer)
		end
		
		if request:HasTimedOut () then
			timedOut [request] = true
		end
		
		if request:IsClosing () and not request:HasQueuedPackets () then
			closed [request] = true
		end
	end
	
	for request, _ in pairs (timedOut) do
		ErrorNoHalt ("GAuth: Request timed out (" .. request:GetType () .. ").\n")
		request:HandleTimeOut ()
		request:Close ()
	end
	
	for request, _ in pairs (closed) do
		self:CloseRequest (request)
	end
end