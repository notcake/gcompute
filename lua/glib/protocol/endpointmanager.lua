local self = {}
GLib.Protocol.EndPointManager = GLib.MakeConstructor (self)

function self:ctor (systemName, endPointConstructor)
	self.SystemName = systemName
	self.EndPointConstructor = endPointConstructor or GLib.Protocol.EndPoint
	self.EndPoints = {}
end

function self:AddEndPoint (remoteId)
	if not self.EndPoints [remoteId] then
		self.EndPoints [remoteId] = self:CreateEndPoint (remoteId)
	end
	return self.EndPoints [remoteId]
end

--[[
	EndPointManager:CreateEndPoint (remoteId)
		Returns: EndPoint endPointForRemoteId
]]
function self:CreateEndPoint (remoteId)
	return self:GetEndPointConstructor () (remoteId, self:GetSystemName ())
end

function self:GetEndPoint (remoteId)
	if not self.EndPoints [remoteId] then
		self.EndPoints [remoteId] = self:CreateEndPoint (remoteId)
	end
	return self.EndPoints [remoteId]
end

function self:GetEndPointEnumerator ()
	local next, tbl, key = pairs (self.EndPoints)
	return function ()
		key = next (tbl, key)
		return key, tbl [key]
	end
end

function self:GetEndPointConstructor ()
	return self.EndPointConstructor
end

function self:GetSystemName ()
	return self.SystemName
end

function self:RemoveEndPoint (endPointOrRemoteId)
	if type (endPointOrRemoteId) == "string" then
		endPointOrRemoteId = self.EndPoints [endPointOrRemoteId]
	end
	if not endPointOrRemoteId then return end
	endPointOrRemoteId:dtor ()
	self.EndPoints [endPointOrRemoteId:GetRemoteId ()] = nil
end