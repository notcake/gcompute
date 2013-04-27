local self = {}
GCompute.LuaSession = GCompute.MakeConstructor (self)

function self:ctor ()
	self.OwnerId = GLib.GetSystemId ()
end

function self:dtor ()
end

function self:EvaluateExpression (sourceId, upvalues, expression, luaOutputSink)
end

function self:Execute (sourceId, upvalues, code, luaOutputSink)
end

function self:GetOwnerId ()
	return self.OwnerId
end

function self:SetOwnerId (ownerId)
	if self.OwnerId == ownerId then return self end
	self.OwnerId = ownerId
	return self
end